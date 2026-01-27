-----------------------------
-- 配置 & 全局变量
-----------------------------
local AddonName, private = ...
PhaseWatcher = PhaseWatcher or {}
PhaseWatcherDB = PhaseWatcherDB or {} 

-- 本地化引用（会在 Localization.lua 加载后可用）
local L

-- 默认配置
local DEFAULT_CONFIG = {
    showFrame      = true,
    frameX         = 0,
    frameY         = 0,
    autoUpdate     = true,
    updateInterval = 0.5,
    useHex         = false, -- 替代 displayFormat
    menuEnabled    = true,
}

-- 缓存变量
PhaseWatcher.cachedPhaseID = nil
PhaseWatcher.lastUpdateTime = 0
PhaseWatcher.timer = nil

-----------------------------
-- 工具函数
-----------------------------
function PhaseWatcher:LoadConfig()
    for k, v in pairs(DEFAULT_CONFIG) do
        if PhaseWatcherDB[k] == nil then
            PhaseWatcherDB[k] = v
        end
    end
    
    -- 迁移旧配置 (如果存在)
    if PhaseWatcherDB.displayFormat then
        PhaseWatcherDB.useHex = (PhaseWatcherDB.displayFormat == "Hexadecimal")
        PhaseWatcherDB.displayFormat = nil
    end
    
    self.db = PhaseWatcherDB
end

-- 计时器管理
function PhaseWatcher:UpdateTimer()
    if self.timer then
        self.timer:Cancel()
        self.timer = nil
    end
    
    if self.db.autoUpdate then
        self.timer = C_Timer.NewTicker(self.db.updateInterval, function()
            self:UpdatePhaseDisplay()
        end)
    end
end

-- 核心:从 GUID 解析位面/分片 ID
-- 12.0+ 在副本中 GUID 是 secret value，不能进行字符串操作
local function GetShardIDFromGUID(guid)
    if not guid then return nil end
    
    -- 使用 pcall 保护所有操作，因为 secret values 会导致错误
    local success, result = pcall(function()
        -- 尝试转换为字符串
        local guidStr = tostring(guid)
        
        -- 使用 pcall 保护 strsplit，因为 secret value 不允许字符串操作
        local splitSuccess, unitType, _, _, _, zoneUID = pcall(strsplit, "-", guidStr)
        
        if not splitSuccess then
            -- 如果 strsplit 失败，说明这是一个 secret value
            return nil
        end
        
        -- 检查单位类型
        if unitType == "Player" or unitType == "Pet" then 
            return nil 
        end
        
        -- 解析 zoneUID
        if zoneUID then
            local id = tonumber(zoneUID, 16)
            if id and id ~= 0 then 
                return id 
            end
        end
        
        return nil
    end)
    
    -- 如果任何操作失败（例如 secret value），返回 nil
    if success then
        return result
    else
        return nil
    end
end

-----------------------------
-- 主要逻辑:获取位面ID
-----------------------------
function PhaseWatcher:GetPhaseID()
    local phaseID
    
    local units = { "target", "mouseover", "focus", "softenemy", "vehicle" }
    for _, unit in ipairs(units) do
        if UnitExists(unit) then
            -- 用 pcall 保护 UnitGUID 调用，因为在副本中可能返回 secret value
            local success, guid = pcall(UnitGUID, unit)
            if success and guid then
                phaseID = GetShardIDFromGUID(guid)
                if phaseID then return phaseID end
            end
        end
    end

    -- Vignette 检查
    if C_VignetteInfo and C_VignetteInfo.GetVignettes then
        local vignetteGUIDs = C_VignetteInfo.GetVignettes()
        if vignetteGUIDs then
            for _, guid in ipairs(vignetteGUIDs) do
                local info = C_VignetteInfo.GetVignetteInfo(guid)
                if info and info.objectGUID then
                    phaseID = GetShardIDFromGUID(info.objectGUID)
                    if phaseID then return phaseID end
                end
            end
        end
    end

    -- Nameplate 检查
    if C_NamePlate and C_NamePlate.GetNamePlates then
        local nameplates = C_NamePlate.GetNamePlates()
        for _, plate in ipairs(nameplates) do
            if plate.namePlateUnitToken then
                local success, guid = pcall(UnitGUID, plate.namePlateUnitToken)
                if success and guid then
                    phaseID = GetShardIDFromGUID(guid)
                    if phaseID then return phaseID end
                end
            end
        end
    end

    return nil
end

-----------------------------
-- UI 更新
-----------------------------
function PhaseWatcher:UpdatePhaseDisplay()
    if not self.MainFrame or not self.MainFrame.PhaseText then return end

    local phaseID = self:GetPhaseID()
    
    if phaseID then
        self.cachedPhaseID = phaseID
        self.lastUpdateTime = GetTime()
    end
    
    local textObj = self.MainFrame.PhaseText

    if self.cachedPhaseID then
        local formatStr
        if self.db.useHex then
            formatStr = string.format("0x%X", self.cachedPhaseID)
        else
            formatStr = string.format("%d", self.cachedPhaseID)
        end
        textObj:SetText(string.format(L["PHASE_ID"], formatStr))
        textObj:SetTextColor(0, 1, 0)
    else
        textObj:SetText(L["NOT_DETECTED"])
        textObj:SetTextColor(1, 0.8, 0)
    end
end

-----------------------------
-- 设置面板 UI
-----------------------------
local function CreateOptionsPanel()
    local panel = CreateFrame("Frame", "PhaseWatcherOptionsPanel", UIParent)
    panel.name = "PhaseWatcher"
    panel:Hide()

    -- 标题
    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("|cFF00BFFF" .. L["ADDON_NAME"])

    -- 版本信息
    local version = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    version:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    version:SetText(L["VERSION"])
    version:SetTextColor(0.7, 0.7, 0.7)

    -- 显示窗口复选框
    local showFrameCheck = CreateFrame("CheckButton", "PhaseWatcherShowFrameCheck", panel, "InterfaceOptionsCheckButtonTemplate")
    showFrameCheck:SetPoint("TOPLEFT", version, "BOTTOMLEFT", 0, -20)
    showFrameCheck.Text:SetText(L["SHOW_FRAME"])
    showFrameCheck:SetChecked(PhaseWatcher.db.showFrame)
    showFrameCheck:SetScript("OnClick", function(self)
        PhaseWatcher.db.showFrame = self:GetChecked()
        PhaseWatcher.MainFrame:SetShown(PhaseWatcher.db.showFrame)
    end)

    -- 16进制显示复选框 (替代 Dropdown)
    local hexCheck = CreateFrame("CheckButton", "PhaseWatcherHexCheck", panel, "InterfaceOptionsCheckButtonTemplate")
    hexCheck:SetPoint("TOPLEFT", showFrameCheck, "BOTTOMLEFT", 0, -10)
    hexCheck.Text:SetText(L["USE_HEXADECIMAL"])
    hexCheck:SetChecked(PhaseWatcher.db.useHex)
    hexCheck:SetScript("OnClick", function(self)
        PhaseWatcher.db.useHex = self:GetChecked()
        PhaseWatcher:UpdatePhaseDisplay()
    end)

    -- 更新间隔滑块
    local intervalSlider = CreateFrame("Slider", "PhaseWatcherIntervalSlider", panel, "OptionsSliderTemplate")
    intervalSlider:SetPoint("TOPLEFT", hexCheck, "BOTTOMLEFT", 0, -30)
    intervalSlider:SetMinMaxValues(0.1, 2.0)
    intervalSlider:SetValue(PhaseWatcher.db.updateInterval)
    intervalSlider:SetValueStep(0.1)
    intervalSlider:SetObeyStepOnDrag(true)
    intervalSlider:SetWidth(200)
    
    local sliderName = intervalSlider:GetName()
    _G[sliderName .. 'Low']:SetText(L["UPDATE_INTERVAL_LOW"])
    _G[sliderName .. 'High']:SetText(L["UPDATE_INTERVAL_HIGH"])
    _G[sliderName .. 'Text']:SetText(string.format(L["UPDATE_INTERVAL"], PhaseWatcher.db.updateInterval))
    
    intervalSlider:SetScript("OnValueChanged", function(self, value)
        value = math.floor(value * 10 + 0.5) / 10
        PhaseWatcher.db.updateInterval = value
        local sliderName = self:GetName()
        _G[sliderName .. 'Text']:SetText(string.format(L["UPDATE_INTERVAL"], value))
        -- 实时更新计时器
        PhaseWatcher:UpdateTimer()
    end)

    -- 重置窗口位置按钮
    local resetButton = CreateFrame("Button", "PhaseWatcherResetButton", panel, "UIPanelButtonTemplate")
    resetButton:SetPoint("TOPLEFT", intervalSlider, "BOTTOMLEFT", 0, -30)
    resetButton:SetSize(150, 25)
    resetButton:SetText(L["RESET_POSITION"])
    resetButton:SetScript("OnClick", function()
        PhaseWatcher.MainFrame:ClearAllPoints()
        PhaseWatcher.MainFrame:SetPoint("CENTER", 0, 0)
        PhaseWatcher.db.frameX = 0
        PhaseWatcher.db.frameY = 0
        print("|cFF00BFFFPhaseWatcher:|r " .. L["WINDOW_RESET"])
    end)

    -- 清除缓存按钮
    local clearButton = CreateFrame("Button", "PhaseWatcherClearButton", panel, "UIPanelButtonTemplate")
    clearButton:SetPoint("LEFT", resetButton, "RIGHT", 10, 0)
    clearButton:SetSize(150, 25)
    clearButton:SetText(L["CLEAR_CACHE"])
    clearButton:SetScript("OnClick", function()
        PhaseWatcher.cachedPhaseID = nil
        PhaseWatcher:UpdatePhaseDisplay()
        print("|cFF00BFFFPhaseWatcher:|r " .. L["CACHE_CLEARED"])
    end)

    -- 帮助文本
    local helpText = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    helpText:SetPoint("TOPLEFT", resetButton, "BOTTOMLEFT", 0, -30)
    helpText:SetJustifyH("LEFT")
    helpText:SetWidth(500)
    helpText:SetText("|cFFFFFF00" .. L["COMMANDS_TITLE"] .. "|r\n" ..
                     L["CMD_TOGGLE"] .. "\n" ..
                     L["CMD_RESET"] .. "\n" ..
                     L["CMD_CLEAR"] .. "\n" ..
                     L["CMD_HEX"] .. "\n" ..
                     L["CMD_DEC"] .. "\n" ..
                     L["CMD_CONFIG"] .. "\n\n" ..
                     "|cFFFF6666" .. L["NOTE_TITLE"] .. "|r " .. L["NOTE_INSTANCE"])

    -- 注册到暴雪设置界面
    if Settings and Settings.RegisterCanvasLayoutCategory then
        -- 11.0+ 新接口
        local category, layout = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
        Settings.RegisterAddOnCategory(category)
        panel.categoryID = category:GetID()
    elseif InterfaceOptions_AddCategory then
        -- 旧版接口
        InterfaceOptions_AddCategory(panel)
    end

    return panel
end

-----------------------------
-- XML 调用的 OnLoad 函数
-----------------------------
function PhaseWatcher_OnLoad(self)
    -- 初始化本地化
    L = PhaseWatcher.L or PhaseWatcher_Locale
    
    PhaseWatcher.MainFrame = self
    
    local textName = self:GetName() .. "PhaseText"
    self.PhaseText = _G[textName]
    
    if not self.PhaseText then
        print("|cFFFF0000PhaseWatcher Error:|r " .. L["ERROR_NO_PHASETEXT"])
        return
    end

    PhaseWatcher:LoadConfig()

    self:RegisterForDrag("LeftButton")
    self:SetMovable(true)
    self:EnableMouse(true)
    
    self:RegisterEvent("PLAYER_ENTERING_WORLD")
    self:RegisterEvent("PLAYER_TARGET_CHANGED")
    self:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
    self:RegisterEvent("NAME_PLATE_UNIT_ADDED")
    self:RegisterEvent("VIGNETTE_MINIMAP_UPDATED")
    self:RegisterEvent("ZONE_CHANGED_NEW_AREA")

    self:SetScript("OnEvent", function(_, event)
        if event == "ZONE_CHANGED_NEW_AREA" or event == "PLAYER_ENTERING_WORLD" then
            PhaseWatcher.cachedPhaseID = nil
        end
        PhaseWatcher:UpdatePhaseDisplay()
    end)

    -- 启动计时器
    PhaseWatcher:UpdateTimer()
    
    self:ClearAllPoints()
    self:SetPoint("CENTER", UIParent, "CENTER", PhaseWatcher.db.frameX, PhaseWatcher.db.frameY)
    self:SetShown(PhaseWatcher.db.showFrame)

    -- 更新 XML 中的标题文本
    if self.Title then
        self.Title:SetText(L["PHASE_MONITORING"])
    end
    
    -- 设置初始文本
    if self.PhaseText then
        self.PhaseText:SetText(L["INITIALIZING"])
    end

    -- 创建设置面板
    PhaseWatcher.optionsPanel = CreateOptionsPanel()

    print("|cFF00BFFF" .. L["ADDON_NAME"] .. "|r v1.3 " .. 
          string.format(L["ADDON_LOADED"], "|cFF00FF00/pw config|r"))
    print("|cFFFFFF00" .. L["NOTE_TITLE"] .. "|r " .. L["NOTE_INSTANCE"])
end

-----------------------------
-- 拖拽相关
-----------------------------
function PhaseWatcher_OnDragStart(self)
    if not PhaseWatcher.db then return end
    self:StartMoving()
end

function PhaseWatcher_OnDragStop(self)
    if not PhaseWatcher.db then return end
    self:StopMovingOrSizing()
    local point, _, relativePoint, xOfs, yOfs = self:GetPoint()
    PhaseWatcher.db.frameX = xOfs
    PhaseWatcher.db.frameY = yOfs
end

-----------------------------
-- Slash 命令
-----------------------------
SLASH_PHASEWATCHER1 = "/pw"
SlashCmdList["PHASEWATCHER"] = function(msg)
    L = PhaseWatcher.L or PhaseWatcher_Locale
    msg = string.lower(msg or "")
    
    if msg == "config" or msg == "settings" or msg == "set" then
        -- 打开设置面板
        if Settings and Settings.OpenToCategory then
            Settings.OpenToCategory(PhaseWatcher.optionsPanel.categoryID)
        elseif InterfaceOptionsFrame_OpenToCategory then
            InterfaceOptionsFrame_OpenToCategory(PhaseWatcher.optionsPanel)
            InterfaceOptionsFrame_OpenToCategory(PhaseWatcher.optionsPanel) -- 需要调用两次
        end
    elseif msg == "reset" then
        PhaseWatcher.MainFrame:ClearAllPoints()
        PhaseWatcher.MainFrame:SetPoint("CENTER", 0, 0)
        PhaseWatcher.db.frameX = 0
        PhaseWatcher.db.frameY = 0
        print("|cFF00BFFFPhaseWatcher:|r " .. L["WINDOW_RESET"])
    elseif msg == "clear" then
        PhaseWatcher.cachedPhaseID = nil
        PhaseWatcher:UpdatePhaseDisplay()
        print("|cFF00BFFFPhaseWatcher:|r " .. L["CACHE_CLEARED"])
    elseif msg == "hex" then
        PhaseWatcher.db.useHex = true
        PhaseWatcher:UpdatePhaseDisplay()
        print("|cFF00BFFFPhaseWatcher:|r " .. L["FORMAT_SWITCHED_HEX"])
    elseif msg == "dec" then
        PhaseWatcher.db.useHex = false
        PhaseWatcher:UpdatePhaseDisplay()
        print("|cFF00BFFFPhaseWatcher:|r " .. L["FORMAT_SWITCHED_DEC"])
    else
        PhaseWatcher.db.showFrame = not PhaseWatcher.db.showFrame
        PhaseWatcher.MainFrame:SetShown(PhaseWatcher.db.showFrame)
        local statusMsg = PhaseWatcher.db.showFrame and L["WINDOW_SHOWN"] or L["WINDOW_HIDDEN"]
        print("|cFF00BFFFPhaseWatcher:|r " .. statusMsg)
    end
end