-----------------------------
-- PhaseWatcher Core Module
-- Version 2.0.1
-----------------------------

local AddonName, PW = ...
local L = PhaseWatcher_Locale or {}

-- 创建主要命名空间
PhaseWatcher = PW

-- 版本信息
PW.Version = "2.0.1"
PW.BuildDate = "2026-02-05"

-----------------------------
-- 数据库默认值
-----------------------------
local defaults = {
    profile = {
        -- 窗口设置
        showFrame = true,
        posX = nil,
        posY = nil,
        isLocked = false,
        
        -- 显示设置
        useHexadecimal = false,
        showTooltip = true,
        autoHideInCombat = false,
        
        -- 外观设置
        fontFace = STANDARD_TEXT_FONT,
        fontSize = 16,
        windowStyle = "Standard",
        windowAlpha = 1.0,
        backgroundColor = {r = 0, g = 0, b = 0, a = 0.85},
        borderColor = {r = 0.4, g = 0.4, b = 0.4, a = 1},
        
        -- 更新设置
        updateInterval = 0.5,
        
        -- 缓存数据
        lastPhaseID = nil,
        lastPhaseSource = nil,
    }
}

-----------------------------
-- 核心变量
-----------------------------
PW.db = nil
PW.currentPhaseID = nil
PW.currentPhaseSource = nil
PW.isSecretValue = false
PW.lastUpdateTime = 0
PW.updateTimer = nil

-----------------------------
-- 工具函数
-----------------------------

-- 安全的打印函数
local function Print(msg, ...)
    if msg then
        DEFAULT_CHAT_FRAME:AddMessage(string.format("|cFF00BFFF[PhaseWatcher]|r " .. msg, ...))
    end
end
PW.Print = Print

-- 调试打印
local function DebugPrint(msg, ...)
    if PW.debug then
        Print("|cFFFF6B6B[DEBUG]|r " .. msg, ...)
    end
end
PW.DebugPrint = DebugPrint

-- 数字转十六进制
local function ToHex(num)
    if not num or num == 0 then
        return "0x0"
    end
    return string.format("0x%X", num)
end
PW.ToHex = ToHex

-- 格式化位面ID显示
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
-----------------------------

-- 从GUID中提取位面ID
-- GUID格式: Player-[server]-[player_id]-[phase_id] 或类似
-- 注意: 在某些情况下可能返回secret值
local function ExtractPhaseFromGUID(guid)
    -- 全局 pcall 保护：任何对 guid 的操作（包括比较、类型检查等）都在保护范围内
    -- 这是为了防止 Secret Value (userdata) 在任何看似无害的操作中触发错误
    -- 即使是 guid == "" 这样的比较，如果 guid 是 Secret Value 也会导致崩溃
    local success, phaseID = pcall(function()
        if not guid then return nil end
        
        -- 必须先检查类型。Secret Value 是 userdata。
        -- 虽然 type() 通常是安全的，但为了"最严格"的标准，我们在 pcall 内部处理
        if type(guid) ~= "string" then
            return nil
        end
        
        if guid == "" then return nil end
        
        local guidType, zero, serverID, instanceID, zoneUID = strsplit("-", guid)
        
        if not guidType then return nil end
        
        -- Player/Pet GUIDs don't contain phase info in the expected format
        if guidType == "Player" or guidType == "Pet" then
            return nil
        end
        
        -- NPC/Vehicle/GameObject GUIDs
        if guidType == "Creature" or guidType == "Vehicle" or guidType == "GameObject" then
            if zoneUID and zoneUID ~= "" and zoneUID ~= "0" then
                local id = tonumber(zoneUID)
                if id and id > 0 and id < 999999 then
                    return id
                end
            end
        end
        return nil
    end)
    
    if success and phaseID then
        return phaseID, "GUID_PARSE"
    else
        -- 如果 pcall 失败（捕获到错误），或者 pcall 成功但返回 nil
        -- 我们进一步检查是否是因为 Secret Value
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
-----------------------------

-- 尝试从单位获取位面信息
local function GetPhaseFromUnit(unit)
    if not unit or not UnitExists(unit) then
        return nil, "NO_UNIT"
    end
    
    -- 方法1: 尝试通过GUID获取
    local guid = UnitGUID(unit)
    if guid then
        local phaseID, reason = ExtractPhaseFromGUID(guid)
        if phaseID then
            return phaseID, "GUID_" .. unit:upper()
        end
        
        -- 如果是secret值,记录状态
        if reason == "SECRET_VALUE" then
            return nil, "SECRET_VALUE"
        end
    end
    
    -- 方法2: 检查位面差异 (UnitPhaseReason)
    -- 这个API在同位面时返回nil,不同位面时返回原因
    if C_PhaseInfo and C_PhaseInfo.GetPhaseReason then
        local phaseReason = C_PhaseInfo.GetPhaseReason(unit)
        if phaseReason then
            -- 存在位面差异,但这不能直接给我们位面ID
            -- 只能表明单位在不同位面
            DebugPrint("Phase reason for %s: %s", unit, tostring(phaseReason))
        end
    end
    
    return nil, "NO_PHASE_DATA"
end
PW.GetPhaseFromUnit = GetPhaseFromUnit

-- 主位面检测函数
local function DetectPhaseID()
    local phaseID = nil
    local source = nil
    local isSecret = false
    
    -- 优先级1: 检查鼠标指向的单位
    if UnitExists("mouseover") then
        phaseID, source = GetPhaseFromUnit("mouseover")
        if source == "SECRET_VALUE" then
            isSecret = true
        end
        if phaseID then
            source = "mouseover"
        end
    end
    
    -- 优先级2: 检查当前目标
    if not phaseID and UnitExists("target") then
        phaseID, source = GetPhaseFromUnit("target")
        if source == "SECRET_VALUE" then
            isSecret = true
        end
        if phaseID then
            source = "target"
        end
    end
    
    -- 优先级3: 检查玩家自己
    if not phaseID then
        phaseID, source = GetPhaseFromUnit("player")
        if source == "SECRET_VALUE" then
            isSecret = true
        end
        if phaseID then
            source = "player"
        end
    end
    
    -- 优先级4: 尝试从焦点目标获取
    if not phaseID and UnitExists("focus") then
        phaseID, source = GetPhaseFromUnit("focus")
        if source == "SECRET_VALUE" then
            isSecret = true
        end
        if phaseID then
            source = "focus"
        end
    end
    
    -- 优先级5: 使用缓存的值
    if not phaseID and PW.db.profile.lastPhaseID then
        phaseID = PW.db.profile.lastPhaseID
        source = "cached"
    end
    
    return phaseID, source, isSecret
end
PW.DetectPhaseID = DetectPhaseID

-- 更新位面ID
local function UpdatePhaseID()
    local phaseID, source, isSecret = DetectPhaseID()
    
    -- 更新全局状态
    PW.currentPhaseID = phaseID
    PW.currentPhaseSource = source
    PW.isSecretValue = isSecret
    
    -- 如果获取到有效ID,缓存它
    if phaseID and source ~= "cached" then
        PW.db.profile.lastPhaseID = phaseID
        PW.db.profile.lastPhaseSource = source
    end
    
    -- 触发UI更新事件
    if PW.UpdateUI then
        PW:UpdateUI()
    end
    
    return phaseID, source, isSecret
end
PW.UpdatePhaseID = UpdatePhaseID

-----------------------------
-- 定时器管理
-----------------------------

-- 启动更新定时器
local function StartUpdateTimer()
    if PW.updateTimer then
        PW.updateTimer:Cancel()
    end
    
    local interval = PW.db.profile.updateInterval or 0.5
    
    PW.updateTimer = C_Timer.NewTicker(interval, function()
        local now = GetTime()
        -- 防止更新过快
        if now - PW.lastUpdateTime >= interval then
            UpdatePhaseID()
            PW.lastUpdateTime = now
        end
    end)
end
PW.StartUpdateTimer = StartUpdateTimer

-- 停止更新定时器
local function StopUpdateTimer()
    if PW.updateTimer then
        PW.updateTimer:Cancel()
        PW.updateTimer = nil
    end
end
PW.StopUpdateTimer = StopUpdateTimer

-- 重启定时器 (更新间隔变化时使用)
local function RestartUpdateTimer()
    StopUpdateTimer()
    StartUpdateTimer()
end
PW.RestartUpdateTimer = RestartUpdateTimer

-----------------------------
-- 数据库管理
-----------------------------

-- 初始化数据库
local function InitializeDB()
    -- 如果没有保存的变量,使用默认值
    if not PhaseWatcherDB then
        PhaseWatcherDB = {}
    end
    
    -- 深度合并默认值
    for key, value in pairs(defaults.profile) do
        if PhaseWatcherDB[key] == nil then
            PhaseWatcherDB[key] = value
        end
    end
    
    -- 建立引用
    PW.db = { profile = PhaseWatcherDB }
end
PW.InitializeDB = InitializeDB

-- 重置位置
function PW:ResetPosition()
    self.db.profile.posX = nil
    self.db.profile.posY = nil
    
    if self.UpdateFramePosition then
        self:UpdateFramePosition()
    end
    
    Print(L["WINDOW_RESET"] or "Window position has been reset")
end

-- 清除缓存
function PW:ClearCache()
    self.db.profile.lastPhaseID = nil
    self.db.profile.lastPhaseSource = nil
    self.currentPhaseID = nil
    self.currentPhaseSource = nil
    
    UpdatePhaseID()
    Print(L["CACHE_CLEARED"] or "Cached phase ID has been cleared")
end

-- 切换显示格式
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

-- 切换窗口显示
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

-- 切换窗口锁定
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

-- 设置更新间隔
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
-----------------------------

local function HandleSlashCommand(msg)
    msg = string.lower(string.trim(msg or ""))
    
    if msg == "" or msg == "toggle" then
        PW:ToggleFrame()
    elseif msg == "show" then
        PW.db.profile.showFrame = true
        if PW.UpdateFrameVisibility then
            PW:UpdateFrameVisibility()
        end
        Print(L["WINDOW_SHOWN"] or "Window shown")
    elseif msg == "hide" then
        PW.db.profile.showFrame = false
        if PW.UpdateFrameVisibility then
            PW:UpdateFrameVisibility()
        end
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
        if PW.OpenConfig then
            PW:OpenConfig()
        else
            -- 备用: 打印设置信息
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
        PW.debug = not PW.debug
        Print("Debug mode: %s", PW.debug and "ON" or "OFF")
    else
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
-----------------------------

local eventFrame = CreateFrame("Frame")
PW.eventFrame = eventFrame

-- 事件处理函数
local function OnEvent(self, event, ...)
    if event == "ADDON_LOADED" or event == "PLAYER_LOGIN" then
        local addonName = ...
        if addonName == AddonName then
            -- 初始化插件
            InitializeDB()
            
            -- 直接初始化 UI (此时 UI.lua 已加载)
            if PW.InitializeUI then
                PW:InitializeUI()
            end
            
            -- 启动更新定时器
            StartUpdateTimer()
            
            -- 首次更新
            UpdatePhaseID()
            
            -- 打印加载消息
            local loadMsg = L["ADDON_LOADED"] or "loaded - Type %s to open settings"
            Print(loadMsg, "|cFFFFD700/pw|r")
        end
    elseif event == "PLAYER_ENTERING_WORLD" then
        -- 进入世界时更新
        UpdatePhaseID()
    elseif event == "PLAYER_TARGET_CHANGED" then
        -- 目标改变时立即更新
        UpdatePhaseID()
    elseif event == "UPDATE_MOUSEOVER_UNIT" then
        -- 鼠标指向改变时立即更新
        UpdatePhaseID()
    elseif event == "PLAYER_REGEN_DISABLED" then
        -- 进入战斗
        if PW.db.profile.autoHideInCombat and PW.UpdateFrameVisibility then
            PW:UpdateFrameVisibility()
        end
    elseif event == "PLAYER_REGEN_ENABLED" then
        -- 离开战斗
        if PW.db.profile.autoHideInCombat and PW.UpdateFrameVisibility then
            PW:UpdateFrameVisibility()
        end
    end
end

-- 注册事件
eventFrame:RegisterEvent("ADDON_LOADED") -- 用于初始化 DB
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
eventFrame:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
eventFrame:SetScript("OnEvent", OnEvent)

-----------------------------
-- 导出到全局
-----------------------------
_G["PhaseWatcher"] = PW