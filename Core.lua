-----------------------------
-- PhaseWatcher Core Module
-- Version 2.1.0
-- 功能：位面检测核心逻辑、数据库管理、事件处理、命令系统
-----------------------------

-- 获取插件标识和全局表
local AddonName, PW = ...
-- 本地化文本表（由 Localization.lua 填充）
local L = PhaseWatcher_Locale or {}

-- 创建主要命名空间，方便其他模块通过 _G["PhaseWatcher"] 访问
PhaseWatcher = PW

-- 版本和构建日期
PW.Version = "2.1.0"
PW.BuildDate = "2026-04-25"

-----------------------------
-- 数据库默认值
-- 这些值会在首次加载或版本升级时被合并到 PhaseWatcherDB 中
-----------------------------
local defaults = {
    profile = {
        -- 窗口显示控制
        showFrame = true,         -- 是否显示主窗口
        posX = nil,               -- 保存的 X 偏移（相对于 UIParent 中心）
        posY = nil,               -- 保存的 Y 偏移
        isLocked = false,         -- 是否锁定窗口位置

        -- 显示格式
        useHexadecimal = false,   -- 是否以十六进制显示 Phase ID
        showTooltip = true,       -- 是否在鼠标悬停时显示详细信息
        autoHideInCombat = false, -- 战斗中是否自动隐藏

        -- 外观设置（字体路径使用全局常量，确保客户端语言兼容）
        fontFace = STANDARD_TEXT_FONT,
        fontSize = 16,
        windowStyle = "Standard", -- 窗口风格: "Standard", "Tooltip", "Flat", "None"
        windowAlpha = 1.0,
        backgroundColor = {r = 0, g = 0, b = 0, a = 0.85},
        borderColor = {r = 0.4, g = 0.4, b = 0.4, a = 1},

        -- 更新间隔（秒）
        updateInterval = 0.5,

        -- 调试模式
        debug = false,

        -- 缓存的上一次有效结果，用于无目标时回退显示
        lastPhaseID = nil,
        lastPhaseSource = nil,
    }
}

-----------------------------
-- 核心运行时变量
-----------------------------
PW.db = nil               -- 引用 PhaseWatcherDB.profile（由 InitializeDB 设置）
PW.currentPhaseID = nil   -- 当前检测到的位面 ID
PW.currentPhaseSource = nil  -- 来源: "mouseover", "target", "player", "focus", "cached"
PW.isSecretValue = false  -- 当前是否处于 Secret Value 状态（副本/某些限制场景）
PW.lastUpdateTime = 0     -- 上次更新时间（GetTime()），用于扩展功能
PW.updateTimer = nil      -- C_Timer 定时器对象

-----------------------------
-- 工具函数
-----------------------------

-- 向默认聊天框发送插件消息，自动添加蓝色的 [PhaseWatcher] 前缀
local function Print(msg, ...)
    if msg then
        print(string.format("|cFF00BFFF[PhaseWatcher]|r " .. msg, ...))
    end
end
PW.Print = Print

-- 调试输出，仅在 PW.db.profile.debug 开启时生效
local function DebugPrint(msg, ...)
    if PW.db and PW.db.profile and PW.db.profile.debug then
        Print("|cFFFF6B6B[DEBUG]|r " .. msg, ...)
    end
end
PW.DebugPrint = DebugPrint

-- 将数字转换为十六进制字符串，格式为 "0x%X"
local function ToHex(num)
    if not num or num == 0 then
        return "0x0"
    end
    return string.format("0x%X", num)
end
PW.ToHex = ToHex

-- 根据设置格式化位面 ID，返回十进制或十六进制字符串
local function FormatPhaseID(phaseID, useHex)
    if not phaseID then
        return L["NOT_DETECTED"] or "Not Detected"
    end
    if useHex then
        return ToHex(phaseID)
    else
        return tostring(phaseID)
    end
end
PW.FormatPhaseID = FormatPhaseID

-----------------------------
-- GUID 解析函数
-- 从单位 GUID 中提取 ZoneUID（即位面 ID）
-- GUID 格式示例: Creature-0-2086-0-123-12345-0000000000
-- ZoneUID 位于最后一个字段，对于 NPC/Vehicle/GameObject 有效
-----------------------------

local function ExtractPhaseFromGUID(guid)
    -- 使用 pcall 保护，因为某些受限环境下 GUID 可能是 userdata (Secret Value)，
    -- 任何对其的操作（包括比较、类型检查）都可能引发错误
    local success, phaseID = pcall(function()
        if not guid then return nil end
        -- 类型必须是 string，否则（如 userdata）直接返回 nil
        if type(guid) ~= "string" then
            return nil
        end
        if guid == "" then return nil end

        -- 分割 GUID，提取类型和最后一个字段（ZoneUID）
        local guidType, _, _, _, zoneUID = strsplit("-", guid)
        if not guidType then return nil end

        -- 玩家和宠物的 GUID 不包含有效的位面信息
        if guidType == "Player" or guidType == "Pet" then
            return nil
        end

        -- 仅对 NPC、载具、游戏对象进行解析
        if guidType == "Creature" or guidType == "Vehicle" or guidType == "GameObject" then
            if zoneUID and zoneUID ~= "" and zoneUID ~= "0" then
                local id = tonumber(zoneUID)
                -- ZoneUID 必须为正数且小于合理上限（1亿），避免异常极大值
                if id and id > 0 and id < 1e8 then
                    return id
                end
            end
        end
        return nil
    end)

    -- 成功提取到 phaseID
    if success and phaseID then
        return phaseID, "GUID_PARSE"
    else
        -- 失败：可能是 Secret Value 或无效 GUID
        if not success or type(guid) == "userdata" then
            return nil, "SECRET_VALUE"
        end
        if not guid or guid == "" then
            return nil, "NO_GUID"
        end
        return nil, "NO_PHASE_IN_GUID"
    end
end
PW.ExtractPhaseFromGUID = ExtractPhaseFromGUID

-----------------------------
-- 位面检测函数
-- 从指定单位获取位面 ID，优先使用 GUID 解析，辅助使用 PhaseReason API
-----------------------------

local function GetPhaseFromUnit(unit)
    -- 单位不存在则直接返回
    if not unit or not UnitExists(unit) then
        return nil, "NO_UNIT"
    end

    -- 尝试通过 GUID 获取
    local guid = UnitGUID(unit)
    if guid then
        local phaseID, reason = ExtractPhaseFromGUID(guid)
        if phaseID then
            return phaseID, "GUID_" .. unit:upper()
        end
        if reason == "SECRET_VALUE" then
            return nil, "SECRET_VALUE"
        end
    end

    -- 辅助方法：检查位面差异原因（仅在非同一位面时返回 PhaseReason 枚举值）
    if C_PhaseInfo and C_PhaseInfo.GetPhaseReason then
        local phaseReason = C_PhaseInfo.GetPhaseReason(unit)
        if phaseReason and type(phaseReason) == "number" then
            DebugPrint("Phase reason for %s: %d", unit, phaseReason)
        end
    end

    return nil, "NO_PHASE_DATA"
end
PW.GetPhaseFromUnit = GetPhaseFromUnit

-- 主检测函数：按优先级依次检测多个单位，直到获取到有效位面 ID
local function DetectPhaseID()
    local phaseID, source, isSecret = nil, nil, false

    -- 优先级1: 鼠标指向的单位
    if UnitExists("mouseover") then
        phaseID, source = GetPhaseFromUnit("mouseover")
        if source == "SECRET_VALUE" then isSecret = true end
        if phaseID then source = "mouseover" end
    end

    -- 优先级2: 当前目标
    if not phaseID and UnitExists("target") then
        phaseID, source = GetPhaseFromUnit("target")
        if source == "SECRET_VALUE" then isSecret = true end
        if phaseID then source = "target" end
    end

    -- 优先级3: 玩家自己
    if not phaseID then
        phaseID, source = GetPhaseFromUnit("player")
        if source == "SECRET_VALUE" then isSecret = true end
        if phaseID then source = "player" end
    end

    -- 优先级4: 焦点目标
    if not phaseID and UnitExists("focus") then
        phaseID, source = GetPhaseFromUnit("focus")
        if source == "SECRET_VALUE" then isSecret = true end
        if phaseID then source = "focus" end
    end

    -- 优先级5: 使用上一次缓存的结果（避免频繁“未检测到”闪烁）
    if not phaseID and PW.db.profile.lastPhaseID then
        phaseID = PW.db.profile.lastPhaseID
        source = "cached"
    end

    return phaseID, source, isSecret
end
PW.DetectPhaseID = DetectPhaseID

-- 更新当前位面状态并触发 UI 刷新
local function UpdatePhaseID()
    local phaseID, source, isSecret = DetectPhaseID()

    -- 更新全局状态
    PW.currentPhaseID = phaseID
    PW.currentPhaseSource = source
    PW.isSecretValue = isSecret

    -- 如果获取到有效且不是缓存的值，保存到数据库供下次使用
    if phaseID and source ~= "cached" then
        PW.db.profile.lastPhaseID = phaseID
        PW.db.profile.lastPhaseSource = source
    end

    -- 通知 UI 模块更新显示
    if PW.UpdateUI then
        PW:UpdateUI()
    end

    return phaseID, source, isSecret
end
PW.UpdatePhaseID = UpdatePhaseID

-----------------------------
-- 定时器管理
-- 使用 C_Timer.NewTicker 定时调用 UpdatePhaseID
-----------------------------

-- 启动（或重启）更新定时器
local function StartUpdateTimer()
    -- 先取消已有的定时器
    if PW.updateTimer then
        PW.updateTimer:Cancel()
    end

    local interval = PW.db.profile.updateInterval or 0.5
    PW.updateTimer = C_Timer.NewTicker(interval, function()
        local ok, err = pcall(UpdatePhaseID)
        if not ok then
            DebugPrint("Update error: %s", tostring(err))
        end
        PW.lastUpdateTime = GetTime()
    end)
end
PW.StartUpdateTimer = StartUpdateTimer

-- 停止定时器
local function StopUpdateTimer()
    if PW.updateTimer then
        PW.updateTimer:Cancel()
        PW.updateTimer = nil
    end
end
PW.StopUpdateTimer = StopUpdateTimer

-- 重启定时器（通常在更新间隔设置改变后调用）
local function RestartUpdateTimer()
    StopUpdateTimer()
    StartUpdateTimer()
end
PW.RestartUpdateTimer = RestartUpdateTimer

-----------------------------
-- 数据库管理
-- PhaseWatcherDB 是由 toc 文件指定的 SavedVariables
-----------------------------

local function InitializeDB()
    -- 如果数据库不存在则创建空表
    if not PhaseWatcherDB then
        PhaseWatcherDB = {}
    end

    -- 合并默认值到现有数据库，确保新选项被补全
    for key, value in pairs(defaults.profile) do
        if PhaseWatcherDB[key] == nil then
            PhaseWatcherDB[key] = value
        elseif type(value) == "table" then
            -- 对于表类型（如颜色设置），进一步合并内部键，避免缺失 alpha 等新字段
            for k, v in pairs(value) do
                if PhaseWatcherDB[key][k] == nil then
                    PhaseWatcherDB[key][k] = v
                end
            end
        end
    end

    -- 建立便捷引用，之后通过 PW.db.profile 访问所有设置
    PW.db = { profile = PhaseWatcherDB }
end
PW.InitializeDB = InitializeDB

-----------------------------
-- 公共方法（供 UI 或命令调用）
-----------------------------

-- 重置窗口位置：清除保存的坐标，并调用 UI 函数恢复到默认中心
function PW:ResetPosition()
    self.db.profile.posX = nil
    self.db.profile.posY = nil
    if self.UpdateFramePosition then
        self:UpdateFramePosition()
    end
    Print(L["WINDOW_RESET"] or "Window position has been reset")
end

-- 清除缓存的位面 ID，并立即重新检测
function PW:ClearCache()
    self.db.profile.lastPhaseID = nil
    self.db.profile.lastPhaseSource = nil
    self.currentPhaseID = nil
    self.currentPhaseSource = nil
    UpdatePhaseID()
    Print(L["CACHE_CLEARED"] or "Cached phase ID has been cleared")
end

-- 切换或强制设置十六进制显示格式
function PW:ToggleFormat(forceHex)
    if forceHex ~= nil then
        self.db.profile.useHexadecimal = forceHex
    else
        self.db.profile.useHexadecimal = not self.db.profile.useHexadecimal
    end

    if self.db.profile.useHexadecimal then
        Print(L["FORMAT_SWITCHED_HEX"] or "Switched to hexadecimal display")
    else
        Print(L["FORMAT_SWITCHED_DEC"] or "Switched to decimal display")
    end

    if self.UpdateUI then
        self:UpdateUI()
    end
end

-- 显示/隐藏主窗口
function PW:ToggleFrame()
    self.db.profile.showFrame = not self.db.profile.showFrame
    if self.UpdateFrameVisibility then
        self:UpdateFrameVisibility()
    end
    if self.db.profile.showFrame then
        Print(L["WINDOW_SHOWN"] or "Window shown")
    else
        Print(L["WINDOW_HIDDEN"] or "Window hidden")
    end
end

-- 切换窗口锁定状态
function PW:ToggleLock()
    self.db.profile.isLocked = not self.db.profile.isLocked
    if self.UpdateFrameLock then
        self:UpdateFrameLock()
    end
    if self.db.profile.isLocked then
        Print(L["WINDOW_LOCKED"] or "Window locked")
    else
        Print(L["WINDOW_UNLOCKED"] or "Window unlocked")
    end
end

-- 设置更新间隔（秒），范围 0.1 - 5.0
function PW:SetUpdateInterval(interval)
    interval = tonumber(interval)
    if not interval or interval < 0.1 or interval > 5.0 then
        Print("Invalid interval. Must be between 0.1 and 5.0 seconds.")
        return
    end
    self.db.profile.updateInterval = interval
    RestartUpdateTimer()
    Print("Update interval set to %.1f seconds", interval)
end

-----------------------------
-- 斜杠命令处理
-- 支持 /pw 和 /phasewatcher
-----------------------------

local function HandleSlashCommand(msg)
    -- 去除首尾空格并转为小写，使用暴雪提供的 strtrim 函数（注意不是 string.trim）
    msg = string.lower(strtrim(msg or ""))

    if msg == "" or msg == "toggle" then
        PW:ToggleFrame()
    elseif msg == "show" then
        PW.db.profile.showFrame = true
        if PW.UpdateFrameVisibility then PW:UpdateFrameVisibility() end
        Print(L["WINDOW_SHOWN"] or "Window shown")
    elseif msg == "hide" then
        PW.db.profile.showFrame = false
        if PW.UpdateFrameVisibility then PW:UpdateFrameVisibility() end
        Print(L["WINDOW_HIDDEN"] or "Window hidden")
    elseif msg == "reset" then
        PW:ResetPosition()
    elseif msg == "clear" then
        PW:ClearCache()
    elseif msg == "hex" then
        PW:ToggleFormat(true)
    elseif msg == "dec" then
        PW:ToggleFormat(false)
    elseif msg == "lock" then
        PW:ToggleLock()
    elseif msg == "config" or msg == "options" or msg == "settings" then
        -- 优先打开完整的设置面板（由 UI 模块提供）
        if PW.OpenConfig then
            PW:OpenConfig()
        else
            -- 后备：在聊天框打印命令列表
            Print(L["COMMANDS_TITLE"] or "Commands:")
            Print("  " .. (L["CMD_TOGGLE"] or "/pw - Toggle window"))
            Print("  " .. (L["CMD_SHOW"] or "/pw show - Show window"))
            Print("  " .. (L["CMD_HIDE"] or "/pw hide - Hide window"))
            Print("  " .. (L["CMD_RESET"] or "/pw reset - Reset position"))
            Print("  " .. (L["CMD_CLEAR"] or "/pw clear - Clear cache"))
            Print("  " .. (L["CMD_HEX"] or "/pw hex - Hexadecimal"))
            Print("  " .. (L["CMD_DEC"] or "/pw dec - Decimal"))
            Print("  " .. (L["CMD_LOCK"] or "/pw lock - Toggle lock"))
        end
    elseif msg == "debug" then
        -- 开启/关闭调试模式，开启后额外输出调试信息
        PW.db.profile.debug = not PW.db.profile.debug
        Print("Debug mode: %s", PW.db.profile.debug and "ON" or "OFF")
    else
        -- 未知或无效命令，显示帮助信息
        Print(L["COMMANDS_TITLE"] or "Commands:")
        Print("  " .. (L["CMD_TOGGLE"] or "/pw - Toggle window"))
        Print("  " .. (L["CMD_SHOW"] or "/pw show - Show window"))
        Print("  " .. (L["CMD_HIDE"] or "/pw hide - Hide window"))
        Print("  " .. (L["CMD_RESET"] or "/pw reset - Reset position"))
        Print("  " .. (L["CMD_CLEAR"] or "/pw clear - Clear cache"))
        Print("  " .. (L["CMD_HEX"] or "/pw hex - Hexadecimal"))
        Print("  " .. (L["CMD_DEC"] or "/pw dec - Decimal"))
        Print("  " .. (L["CMD_LOCK"] or "/pw lock - Toggle lock"))
        Print("  " .. (L["CMD_CONFIG"] or "/pw config - Open settings"))
    end
end

-- 注册斜杠命令
SLASH_PHASEWATCHER1 = "/phasewatcher"
SLASH_PHASEWATCHER2 = "/pw"
SlashCmdList["PHASEWATCHER"] = HandleSlashCommand

-----------------------------
-- 事件处理
-- 注册各种游戏事件，在合适时机更新位面状态或响应 UI 设置
-----------------------------

local eventFrame = CreateFrame("Frame")
PW.eventFrame = eventFrame

local function OnEvent(self, event, ...)
    if event == "ADDON_LOADED" then
        local addonName = ...
        -- 仅当本插件加载时执行初始化
        if addonName == AddonName then
            -- 数据库初始化
            InitializeDB()
            -- 初始化 UI（UI.lua 中的 InitializeUI）
            if PW.InitializeUI then
                PW:InitializeUI()
            end
            -- 启动定时更新
            StartUpdateTimer()
            -- 立即执行一次检测
            UpdatePhaseID()
            -- 输出加载成功信息
            local loadMsg = L["ADDON_LOADED"] or "loaded - Type %s to open settings"
            Print(loadMsg, "|cFFFFD700/pw|r")
        end
    elseif event == "PLAYER_ENTERING_WORLD" then
        -- 进入世界或切换场景时更新
        UpdatePhaseID()
    elseif event == "PLAYER_TARGET_CHANGED" then
        -- 目标改变立刻更新
        UpdatePhaseID()
    elseif event == "UPDATE_MOUSEOVER_UNIT" then
        -- 鼠标指向新单位立刻更新
        UpdatePhaseID()
    elseif event == "PLAYER_REGEN_DISABLED" then
        -- 进入战斗，如果开启了战斗中隐藏则刷新可见性
        if PW.db.profile.autoHideInCombat and PW.UpdateFrameVisibility then
            PW:UpdateFrameVisibility()
        end
    elseif event == "PLAYER_REGEN_ENABLED" then
        -- 脱离战斗，同样刷新可见性
        if PW.db.profile.autoHideInCombat and PW.UpdateFrameVisibility then
            PW:UpdateFrameVisibility()
        end
    end
end

-- 注册事件
eventFrame:RegisterEvent("ADDON_LOADED")       -- 插件加载完成
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD") -- 玩家进入世界
eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED") -- 目标改变
eventFrame:RegisterEvent("UPDATE_MOUSEOVER_UNIT") -- 鼠标指向单位改变
eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED") -- 进入战斗
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")  -- 脱离战斗
eventFrame:SetScript("OnEvent", OnEvent)

-----------------------------
-- 导出到全局环境，确保其他模块和脚本可访问
-----------------------------
_G["PhaseWatcher"] = PW