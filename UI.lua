-----------------------------
-- PhaseWatcher UI Module
-- Version 2.0
-----------------------------

local AddonName, PW = ...
local L = PhaseWatcher_Locale or {}

-----------------------------
-- UI 变量
-----------------------------
PW.mainFrame = nil
PW.phaseText = nil
PW.titleText = nil
PW.bgTexture = nil

-----------------------------
-- 创建主框架
-----------------------------

local function CreateMainFrame()
    -- 主框架
    -- 11.0+ 必须显式继承 BackdropTemplate
    local frame = CreateFrame("Frame", "PhaseWatcherFrame", UIParent, "BackdropTemplate") 
    frame:SetSize(220, 60)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    frame:SetFrameStrata("MEDIUM")
    frame:SetFrameLevel(10)
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:SetClampedToScreen(true)
    
    -- 背景
    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    frame:SetBackdropColor(0, 0, 0, 0.85)
    frame:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
    
    -- 标题文本
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    title:SetPoint("TOP", frame, "TOP", 0, -8)
    title:SetText(L["PHASE_MONITORING"] or "Phase Monitor")
    title:SetTextColor(0.8, 0.8, 1, 1)
    PW.titleText = title
    
    -- 位面ID显示文本
    local phaseText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    phaseText:SetPoint("CENTER", frame, "CENTER", 0, -2)
    phaseText:SetText(L["INITIALIZING"] or "Initializing...")
    phaseText:SetTextColor(0, 1, 0.5, 1)
    phaseText:SetJustifyH("CENTER")
    phaseText:SetWidth(200)
    PW.phaseText = phaseText
    
    -- 拖动提示文本
    local dragHint = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalTiny")
    dragHint:SetPoint("BOTTOM", frame, "BOTTOM", 0, 6)
    dragHint:SetText(L["DRAG_TO_MOVE"] or "Drag to move")
    dragHint:SetTextColor(0.5, 0.5, 0.5, 0.7)
    dragHint:SetAlpha(0)
    PW.dragHint = dragHint
    
    -- 鼠标悬停时显示拖动提示
    frame:SetScript("OnEnter", function(self)
        if not PW.db.profile.isLocked then
            dragHint:SetAlpha(1)
        end
        
        -- 显示工具提示
        if PW.db.profile.showTooltip then
            PW:ShowTooltip(self)
        end
    end)
    
    frame:SetScript("OnLeave", function(self)
        dragHint:SetAlpha(0)
        GameTooltip:Hide()
    end)
    
    -- 拖动功能
    frame:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" and not PW.db.profile.isLocked then
            self:StartMoving()
        elseif button == "RightButton" then
            PW:ShowContextMenu(self)
        end
    end)
    
    frame:SetScript("OnMouseUp", function(self, button)
        if button == "LeftButton" then
            self:StopMovingOrSizing()
            PW:SavePosition()
        end
    end)
    
    -- 点击复制到剪贴板
    phaseText:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" and PW.currentPhaseID then
            local formattedID = PW.FormatPhaseID(PW.currentPhaseID, PW.db.profile.useHexadecimal)
            -- 尝试复制到剪贴板
            if C_ChatInfo and C_ChatInfo.CopyToClipboard then
                C_ChatInfo.CopyToClipboard(formattedID)
                PW.Print(L["COPIED_TO_CLIPBOARD"] or "Phase ID copied to clipboard: %s", formattedID)
            end
        end
    end)
    
    PW.mainFrame = frame
    return frame
end

-----------------------------
-- UI 更新函数
-----------------------------

function PW:UpdateUI()
    if not self.phaseText then return end
    
    local phaseID = self.currentPhaseID
    local source = self.currentPhaseSource
    local isSecret = self.isSecretValue
    
    -- 确定显示文本和颜色
    local displayText = ""
    local r, g, b = 0, 1, 0.5  -- 默认绿色
    
    if isSecret then
        -- Secret Value情况
        displayText = L["SECRET_VALUE"] or "Hidden (Secret Value)"
        r, g, b = 1, 0.5, 0  -- 橙色
    elseif phaseID then
        -- 有效的位面ID
        local formattedID = self.FormatPhaseID(phaseID, self.db.profile.useHexadecimal)
        displayText = string.format(L["PHASE_ID"] or "Phase ID: %s", formattedID)
        
        -- 根据来源设置颜色
        if source == "cached" then
            r, g, b = 0.7, 0.7, 0.7  -- 灰色 (缓存)
        elseif source == "player" then
            r, g, b = 0.5, 1, 0.5  -- 浅绿 (玩家)
        else
            r, g, b = 0, 1, 0.5  -- 青绿 (目标/鼠标)
        end
    else
        -- 未检测到
        if IsInInstance() then
            displayText = L["INSTANCE_LIMITATION"] or "In instance, may not detect"
            r, g, b = 1, 1, 0  -- 黄色
        else
            displayText = L["NOT_DETECTED"] or "Not Detected (Need Target/NPC)"
            r, g, b = 1, 0.3, 0.3  -- 红色
        end
    end
    
    self.phaseText:SetText(displayText)
    self.phaseText:SetTextColor(r, g, b, 1)
end

function PW:UpdateFrameVisibility()
    if not self.mainFrame then return end
    
    local shouldShow = self.db.profile.showFrame
    
    -- 战斗自动隐藏
    if shouldShow and self.db.profile.autoHideInCombat and InCombatLockdown() then
        shouldShow = false
    end
    
    if shouldShow then
        self.mainFrame:Show()
    else
        self.mainFrame:Hide()
    end
end

function PW:UpdateFrameLock()
    if not self.mainFrame then return end
    
    if self.db.profile.isLocked then
        self.mainFrame:SetMovable(false)
        if self.dragHint then
            self.dragHint:Hide()
        end
    else
        self.mainFrame:SetMovable(true)
        if self.dragHint then
            self.dragHint:Show()
        end
    end
end

function PW:UpdateFramePosition()
    if not self.mainFrame then return end
    
    local posX = self.db.profile.posX
    local posY = self.db.profile.posY
    
    self.mainFrame:ClearAllPoints()
    
    if posX and posY then
        self.mainFrame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", posX, posY)
    else
        self.mainFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    end
end

function PW:SavePosition()
    if not self.mainFrame then return end
    
    local point, _, relativePoint, xOfs, yOfs = self.mainFrame:GetPoint()
    self.db.profile.posX = xOfs
    self.db.profile.posY = yOfs
end

-----------------------------
-- 工具提示
-----------------------------

function PW:ShowTooltip(frame)
    GameTooltip:SetOwner(frame, "ANCHOR_TOP")
    GameTooltip:ClearLines()
    
    GameTooltip:AddLine(L["PHASE_MONITORING"] or "Phase Monitor", 1, 1, 1)
    GameTooltip:AddLine(" ")
    
    if self.currentPhaseID then
        local formattedID = self.FormatPhaseID(self.currentPhaseID, self.db.profile.useHexadecimal)
        GameTooltip:AddDoubleLine(
            L["TOOLTIP_PHASE_ID"] or "Current Phase ID:",
            formattedID,
            0.7, 0.7, 1,
            0, 1, 0.5
        )
        
        -- 显示格式
        local formatType = self.db.profile.useHexadecimal and 
            (L["TOOLTIP_HEXADECIMAL"] or "Hexadecimal") or 
            (L["TOOLTIP_DECIMAL"] or "Decimal")
        GameTooltip:AddDoubleLine(
            L["TOOLTIP_FORMAT"] or "Format:",
            formatType,
            0.7, 0.7, 1,
            1, 1, 1
        )
        
        -- 显示来源
        if self.currentPhaseSource then
            local sourceText = L["TOOLTIP_SOURCE_" .. string.upper(self.currentPhaseSource)] or self.currentPhaseSource
            GameTooltip:AddDoubleLine(
                L["TOOLTIP_SOURCE"] or "Source:",
                sourceText,
                0.7, 0.7, 1,
                1, 1, 0.5
            )
        end
    elseif self.isSecretValue then
        GameTooltip:AddLine(L["ERROR_API_RESTRICTED"] or "API temporarily restricted (Secret Value)", 1, 0.5, 0)
    else
        GameTooltip:AddLine(L["NOT_DETECTED"] or "Not Detected", 1, 0.3, 0.3)
    end
    
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine(L["TOOLTIP_CLICK_TO_COPY"] or "Click to copy to clipboard", 0.5, 0.5, 0.5)
    GameTooltip:AddLine(L["TOOLTIP_RIGHT_CLICK"] or "Right-click for options", 0.5, 0.5, 0.5)
    
    GameTooltip:Show()
end

-----------------------------
-- 右键菜单
-----------------------------

function PW:ShowContextMenu(owner)
    -- 11.0+ 使用 MenuUtil 避免 Taint
    if not MenuUtil or not MenuUtil.CreateContextMenu then return end

    MenuUtil.CreateContextMenu(owner, function(owner, root)
        root:CreateTitle(L["PHASE_MONITORING"] or "Phase Monitor")
        root:CreateDivider()

        -- 16进制开关
        root:CreateCheckbox(
            L["USE_HEXADECIMAL"] or "Use Hexadecimal Format",
            function() return self.db.profile.useHexadecimal end,
            function() self:ToggleFormat() end
        )

        -- 锁定窗口
        root:CreateCheckbox(
            L["LOCK_WINDOW"] or "Lock Window Position",
            function() return self.db.profile.isLocked end,
            function() self:ToggleLock() end
        )

        -- 显示工具提示
        root:CreateCheckbox(
            L["SHOW_TOOLTIP"] or "Show Detailed Tooltip",
            function() return self.db.profile.showTooltip end,
            function() self.db.profile.showTooltip = not self.db.profile.showTooltip end
        )

        root:CreateDivider()

        -- 按钮
        root:CreateButton(L["CLEAR_CACHE"] or "Clear Cached ID", function() self:ClearCache() end)
        root:CreateButton(L["RESET_POSITION"] or "Reset Window Position", function() self:ResetPosition() end)
        root:CreateButton(L["CMD_CONFIG"] or "Open Settings", function() self:OpenConfig() end)
    end)
end

-----------------------------
-- 设置面板 (Interface Options)
-----------------------------

local function CreateSettingsPanel()
    local panel = CreateFrame("Frame", "PhaseWatcherSettingsPanel", UIParent)
    panel.name = "PhaseWatcher"
    
    -- 标题
    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText(L["SETTINGS_TITLE"] or "PhaseWatcher Settings")
    
    -- 版本信息
    local version = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    version:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    version:SetText(L["VERSION"] or "Version 2.0")
    version:SetTextColor(0.7, 0.7, 0.7, 1)
    
    -- 显示窗口复选框
    local showFrameCheck = CreateFrame("CheckButton", nil, panel, "InterfaceOptionsCheckButtonTemplate")
    showFrameCheck:SetPoint("TOPLEFT", version, "BOTTOMLEFT", 0, -20)
    showFrameCheck.Text:SetText(L["SHOW_FRAME"] or "Show Phase Monitor Window")
    showFrameCheck:SetChecked(PW.db.profile.showFrame)
    showFrameCheck:SetScript("OnClick", function(self)
        PW.db.profile.showFrame = self:GetChecked()
        PW:UpdateFrameVisibility()
    end)
    
    -- 十六进制复选框
    local hexCheck = CreateFrame("CheckButton", nil, panel, "InterfaceOptionsCheckButtonTemplate")
    hexCheck:SetPoint("TOPLEFT", showFrameCheck, "BOTTOMLEFT", 0, -8)
    hexCheck.Text:SetText(L["USE_HEXADECIMAL"] or "Use Hexadecimal Format")
    hexCheck:SetChecked(PW.db.profile.useHexadecimal)
    hexCheck:SetScript("OnClick", function(self)
        PW:ToggleFormat(self:GetChecked())
    end)
    
    -- 锁定窗口复选框
    local lockCheck = CreateFrame("CheckButton", nil, panel, "InterfaceOptionsCheckButtonTemplate")
    lockCheck:SetPoint("TOPLEFT", hexCheck, "BOTTOMLEFT", 0, -8)
    lockCheck.Text:SetText(L["LOCK_WINDOW"] or "Lock Window Position")
    lockCheck:SetChecked(PW.db.profile.isLocked)
    lockCheck:SetScript("OnClick", function(self)
        PW.db.profile.isLocked = self:GetChecked()
        PW:UpdateFrameLock()
    end)
    
    -- 显示工具提示复选框
    local tooltipCheck = CreateFrame("CheckButton", nil, panel, "InterfaceOptionsCheckButtonTemplate")
    tooltipCheck:SetPoint("TOPLEFT", lockCheck, "BOTTOMLEFT", 0, -8)
    tooltipCheck.Text:SetText(L["SHOW_TOOLTIP"] or "Show Detailed Tooltip")
    tooltipCheck:SetChecked(PW.db.profile.showTooltip)
    tooltipCheck:SetScript("OnClick", function(self)
        PW.db.profile.showTooltip = self:GetChecked()
    end)
    
    -- 战斗自动隐藏复选框
    local autoHideCheck = CreateFrame("CheckButton", nil, panel, "InterfaceOptionsCheckButtonTemplate")
    autoHideCheck:SetPoint("TOPLEFT", tooltipCheck, "BOTTOMLEFT", 0, -8)
    autoHideCheck.Text:SetText(L["AUTO_HIDE"] or "Auto Hide in Combat")
    autoHideCheck:SetChecked(PW.db.profile.autoHideInCombat)
    autoHideCheck:SetScript("OnClick", function(self)
        PW.db.profile.autoHideInCombat = self:GetChecked()
    end)
    
    -- 更新间隔滑块
    local intervalSlider = CreateFrame("Slider", nil, panel, "OptionsSliderTemplate")
    intervalSlider:SetPoint("TOPLEFT", autoHideCheck, "BOTTOMLEFT", 16, -32)
    intervalSlider:SetMinMaxValues(0.1, 2.0)
    intervalSlider:SetValue(PW.db.profile.updateInterval or 0.5)
    intervalSlider:SetValueStep(0.1)
    intervalSlider:SetObeyStepOnDrag(true)
    intervalSlider:SetWidth(200)
    
    -- 滑块标签
    local intervalLabel = intervalSlider:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    intervalLabel:SetPoint("BOTTOM", intervalSlider, "TOP", 0, 4)
    intervalLabel:SetText(string.format(L["UPDATE_INTERVAL"] or "Update Interval: %.1f sec", intervalSlider:GetValue()))
    
    -- 滑块数值显示
    intervalSlider.Low:SetText(L["UPDATE_INTERVAL_LOW"] or "0.1s")
    intervalSlider.High:SetText(L["UPDATE_INTERVAL_HIGH"] or "2.0s")
    
    intervalSlider:SetScript("OnValueChanged", function(self, value)
        value = math.floor(value * 10 + 0.5) / 10  -- 四舍五入到0.1
        intervalLabel:SetText(string.format(L["UPDATE_INTERVAL"] or "Update Interval: %.1f sec", value))
        
        -- 性能优化: 仅在数值实际变化时重置计时器
        if PW.db.profile.updateInterval ~= value then
            PW.db.profile.updateInterval = value
            PW:RestartUpdateTimer()
        end
    end)
    
    -- 重置位置按钮
    local resetButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    resetButton:SetPoint("TOPLEFT", intervalSlider, "BOTTOMLEFT", -16, -32)
    resetButton:SetSize(180, 22)
    resetButton:SetText(L["RESET_POSITION"] or "Reset Window Position")
    resetButton:SetScript("OnClick", function()
        PW:ResetPosition()
    end)
    
    -- 清除缓存按钮
    local clearButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    clearButton:SetPoint("TOPLEFT", resetButton, "BOTTOMLEFT", 0, -8)
    clearButton:SetSize(180, 22)
    clearButton:SetText(L["CLEAR_CACHE"] or "Clear Cached ID")
    clearButton:SetScript("OnClick", function()
        PW:ClearCache()
    end)
    
    -- 命令说明
    local commandsTitle = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    commandsTitle:SetPoint("TOPLEFT", clearButton, "BOTTOMLEFT", 0, -24)
    commandsTitle:SetText(L["COMMANDS_TITLE"] or "Commands:")
    
    local commandsText = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    commandsText:SetPoint("TOPLEFT", commandsTitle, "BOTTOMLEFT", 8, -8)
    commandsText:SetJustifyH("LEFT")
    commandsText:SetWidth(500)
    
    local commands = {
        L["CMD_TOGGLE"] or "/pw - Toggle window",
        L["CMD_SHOW"] or "/pw show - Show window",
        L["CMD_HIDE"] or "/pw hide - Hide window",
        L["CMD_RESET"] or "/pw reset - Reset position",
        L["CMD_CLEAR"] or "/pw clear - Clear cache",
        L["CMD_HEX"] or "/pw hex - Hexadecimal",
        L["CMD_DEC"] or "/pw dec - Decimal",
        L["CMD_LOCK"] or "/pw lock - Toggle lock",
        L["CMD_CONFIG"] or "/pw config - Open settings",
    }
    commandsText:SetText(table.concat(commands, "\n"))
    
    -- 注意事项
    local noteTitle = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    noteTitle:SetPoint("TOPLEFT", commandsText, "BOTTOMLEFT", -8, -16)
    noteTitle:SetText(L["NOTE_TITLE"] or "Note:")
    
    local noteText = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    noteText:SetPoint("TOPLEFT", noteTitle, "BOTTOMLEFT", 8, -8)
    noteText:SetJustifyH("LEFT")
    noteText:SetWidth(500)
    noteText:SetText(L["NOTE_INSTANCE"] or "In instances or combat, phase ID may not be available due to API limitations")
    
    -- 添加到Interface Options
    if Settings and Settings.RegisterCanvasLayoutCategory then
        -- 11.0+ 新API (The War Within)
        local category = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
        Settings.RegisterAddOnCategory(category)
        PW.settingsCategory = category
    elseif InterfaceOptions_AddCategory then
        -- 旧API (兼容性保留)
        InterfaceOptions_AddCategory(panel)
    end
    
    return panel
end

function PW:OpenConfig()
    -- 11.0+ 新API
    if Settings and Settings.OpenToCategory then
        if self.settingsCategory then
            Settings.OpenToCategory(self.settingsCategory)
        else
            Settings.OpenToCategory("PhaseWatcher")
        end
    -- 旧API
    elseif InterfaceOptionsFrame_OpenToCategory then
        InterfaceOptionsFrame_OpenToCategory("PhaseWatcher")
        InterfaceOptionsFrame_OpenToCategory("PhaseWatcher")  -- 调用两次确保打开
    end
end

-----------------------------
-- UI 初始化
-----------------------------

function PW:InitializeUI()
    -- 创建主框架
    if not self.mainFrame then
        CreateMainFrame()
    end
    
    -- 创建设置面板
    CreateSettingsPanel()
    
    -- 恢复位置
    self:UpdateFramePosition()
    
    -- 应用锁定状态
    self:UpdateFrameLock()
    
    -- 应用可见性
    self:UpdateFrameVisibility()
    
    -- 初始UI更新
    self:UpdateUI()
end

-----------------------------
-- 导出到全局
-----------------------------
_G["PhaseWatcher"] = PW