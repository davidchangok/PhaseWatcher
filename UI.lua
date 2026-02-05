-----------------------------
-- PhaseWatcher UI Module
-- Version 2.0.1
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
    frame:RegisterForDrag("LeftButton")
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
    
    -- 位面ID显示文本
    local phaseText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    -- phaseText:SetPoint("TOP", title, "BOTTOM", 0, -4)
    phaseText:SetPoint("CENTER", frame, "CENTER", 0, 0)
    phaseText:SetText(L["INITIALIZING"] or "Initializing...")
    phaseText:SetTextColor(0, 1, 0.5, 1)
    phaseText:SetJustifyH("CENTER")
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
        if button == "RightButton" then
            PW:ShowContextMenu(self)
        end
    end)

    frame:SetScript("OnDragStart", function(self, button)
        if button == "LeftButton" then
            if not PW.db.profile.isLocked then
                self:StartMoving()
            end
        end
    end)

    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        PW:SavePosition()
    end)

    PW.mainFrame = frame
    return frame
end

-----------------------------
-- 自动调整窗口大小
-----------------------------

function PW:ResizeFrameToContent()    
    if not self.mainFrame or not self.phaseText then return end
    
    local phaseWidth = self.phaseText:GetStringWidth() or 0
    local phaseHeight = self.phaseText:GetStringHeight() or 0
    
    local paddingX = 30
    local paddingY = 20 -- 10(Top) + 10(Bottom)
    
    local width = phaseWidth + paddingX
    local height = phaseHeight + paddingY
    
    self.mainFrame:SetSize(math.max(width, 140), math.max(height, 50))
end

-----------------------------
-- 外观更新函数
-----------------------------

function PW:UpdateAppearance()
    if not self.mainFrame then return end

    -- 应用透明度
    self.mainFrame:SetAlpha(self.db.profile.windowAlpha or 1.0)

    -- 应用字体
    local fontPath = self.db.profile.fontFace or STANDARD_TEXT_FONT
    local fontSize = self.db.profile.fontSize or 16
    
    if self.phaseText then
        self.phaseText:SetFont(fontPath, fontSize, "OUTLINE")
    end
    
    -- 应用窗口风格
    local style = self.db.profile.windowStyle or "Standard"
    local bg = self.db.profile.backgroundColor or {r = 0, g = 0, b = 0, a = 0.85}
    local border = self.db.profile.borderColor or {r = 0.4, g = 0.4, b = 0.4, a = 1}
    
    if style == "None" then
        self.mainFrame:SetBackdrop(nil)
    elseif style == "Tooltip" then
        self.mainFrame:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 }
        })
        self.mainFrame:SetBackdropColor(bg.r, bg.g, bg.b, bg.a)
        self.mainFrame:SetBackdropBorderColor(border.r, border.g, border.b, border.a)
    elseif style == "Flat" then
        self.mainFrame:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            tile = false, edgeSize = 1,
            insets = { left = 0, right = 0, top = 0, bottom = 0 }
        })
        self.mainFrame:SetBackdropColor(bg.r, bg.g, bg.b, bg.a)
        self.mainFrame:SetBackdropBorderColor(border.r, border.g, border.b, border.a)
    else -- Standard
        self.mainFrame:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true, tileSize = 32, edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 }
        })
        self.mainFrame:SetBackdropColor(bg.r, bg.g, bg.b, bg.a)
        self.mainFrame:SetBackdropBorderColor(border.r, border.g, border.b, border.a)
    end
    
    -- 调整大小以适应新字体
    self:ResizeFrameToContent()
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
    
    -- 调整大小以适应新文本
    self:ResizeFrameToContent()
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

    -- 获取框架在屏幕上的绝对位置，然后转换为相对于 UIParent BOTTOMLEFT 的坐标
    -- 这样可以确保跨角色/分辨率时位置一致
    local left = self.mainFrame:GetLeft()
    local top = self.mainFrame:GetTop()

    if left and top then
        self.db.profile.posX = left
        self.db.profile.posY = top
    end
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
        root:CreateButton(L["SETTINGS_TITLE"] or "PhaseWatcher Settings", function() self:OpenConfig() end)
    end)
end

-----------------------------
-- 设置面板 (Interface Options)
-----------------------------

-- 创建分组框辅助函数
local function CreateGroupBox(parent, title)
    local frame = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    frame:SetBackdrop({
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 16,
    })
    frame:SetBackdropBorderColor(0.6, 0.6, 0.6, 1)
    
    local label = frame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    label:SetPoint("TOPLEFT", 16, 10)
    label:SetText(title)
    
    return frame
end

-- 颜色选择器辅助函数
local function ShowColorPicker(r, g, b, a, callback)
    local info = {
        r = r, g = g, b = b, opacity = a,
        hasOpacity = true,
        swatchFunc = function()
            local nr, ng, nb = ColorPickerFrame:GetColorRGB()
            local na = ColorPickerFrame:GetColorAlpha()
            callback(nr, ng, nb, na)
        end,
        opacityFunc = function()
            local nr, ng, nb = ColorPickerFrame:GetColorRGB()
            local na = ColorPickerFrame:GetColorAlpha()
            callback(nr, ng, nb, na)
        end,
        cancelFunc = function()
            callback(r, g, b, a)
        end,
    }
    ColorPickerFrame:SetupColorPickerAndShow(info)
end

local function CreateSettingsPanel()
    local panel = CreateFrame("Frame", "PhaseWatcherSettingsPanel", UIParent)
    panel.name = "|cffff8000Phase|rWatcher"
    
    -- 标题
    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText(L["SETTINGS_TITLE"] or "PhaseWatcher Settings")
    
    -- 版本信息
    local version = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    version:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    version:SetText(L["VERSION"] or "Version 2.0.1")
    version:SetTextColor(0.7, 0.7, 0.7, 1)
    
    -- 创建滚动框架
    local scrollFrame = CreateFrame("ScrollFrame", nil, panel, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 10, -60)
    scrollFrame:SetPoint("BOTTOMRIGHT", -30, 10)
    
    -- 创建内容框架
    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetSize(600, 750)
    scrollFrame:SetScrollChild(content)
    
    -----------------------------
    -- 分组 1: 常规设置
    -----------------------------
    
    local groupGeneral = CreateGroupBox(content, L["GENERAL_SETTINGS"] or "General Settings")
    groupGeneral:SetPoint("TOPLEFT", 10, -30)
    groupGeneral:SetPoint("RIGHT", -10, 0)
    groupGeneral:SetHeight(320)
    
    -- 显示窗口复选框
    local showFrameCheck = CreateFrame("CheckButton", nil, groupGeneral, "InterfaceOptionsCheckButtonTemplate")
    showFrameCheck:SetPoint("TOPLEFT", 16, -30)
    showFrameCheck.Text:SetText(L["SHOW_FRAME"] or "Show Phase Monitor Window")
    showFrameCheck:SetChecked(PW.db.profile.showFrame)
    showFrameCheck:SetScript("OnClick", function(self)
        PW.db.profile.showFrame = self:GetChecked()
        PW:UpdateFrameVisibility()
    end)
    
    -- 十六进制复选框
    local hexCheck = CreateFrame("CheckButton", nil, groupGeneral, "InterfaceOptionsCheckButtonTemplate")
    hexCheck:SetPoint("TOPLEFT", showFrameCheck, "BOTTOMLEFT", 0, -8)
    hexCheck.Text:SetText(L["USE_HEXADECIMAL"] or "Use Hexadecimal Format")
    hexCheck:SetChecked(PW.db.profile.useHexadecimal)
    hexCheck:SetScript("OnClick", function(self)
        PW:ToggleFormat(self:GetChecked())
    end)
    
    -- 锁定窗口复选框
    local lockCheck = CreateFrame("CheckButton", nil, groupGeneral, "InterfaceOptionsCheckButtonTemplate")
    lockCheck:SetPoint("TOPLEFT", hexCheck, "BOTTOMLEFT", 0, -8)
    lockCheck.Text:SetText(L["LOCK_WINDOW"] or "Lock Window Position")
    lockCheck:SetChecked(PW.db.profile.isLocked)
    lockCheck:SetScript("OnClick", function(self)
        PW.db.profile.isLocked = self:GetChecked()
        PW:UpdateFrameLock()
    end)
    
    -- 显示工具提示复选框
    local tooltipCheck = CreateFrame("CheckButton", nil, groupGeneral, "InterfaceOptionsCheckButtonTemplate")
    tooltipCheck:SetPoint("TOPLEFT", lockCheck, "BOTTOMLEFT", 0, -8)
    tooltipCheck.Text:SetText(L["SHOW_TOOLTIP"] or "Show Detailed Tooltip")
    tooltipCheck:SetChecked(PW.db.profile.showTooltip)
    tooltipCheck:SetScript("OnClick", function(self)
        PW.db.profile.showTooltip = self:GetChecked()
    end)
    
    -- 战斗自动隐藏复选框
    local autoHideCheck = CreateFrame("CheckButton", nil, groupGeneral, "InterfaceOptionsCheckButtonTemplate")
    autoHideCheck:SetPoint("TOPLEFT", tooltipCheck, "BOTTOMLEFT", 0, -8)
    autoHideCheck.Text:SetText(L["AUTO_HIDE"] or "Auto Hide in Combat")
    autoHideCheck:SetChecked(PW.db.profile.autoHideInCombat)
    autoHideCheck:SetScript("OnClick", function(self)
        PW.db.profile.autoHideInCombat = self:GetChecked()
    end)
    
    -- 更新间隔滑块
    local intervalSlider = CreateFrame("Slider", nil, groupGeneral, "OptionsSliderTemplate")
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
    local resetButton = CreateFrame("Button", nil, groupGeneral, "UIPanelButtonTemplate")
    resetButton:SetPoint("TOPLEFT", intervalSlider, "BOTTOMLEFT", -16, -32)
    resetButton:SetSize(180, 22)
    resetButton:SetText(L["RESET_POSITION"] or "Reset Window Position")
    resetButton:SetScript("OnClick", function()
        PW:ResetPosition()
    end)
    
    -- 清除缓存按钮
    local clearButton = CreateFrame("Button", nil, groupGeneral, "UIPanelButtonTemplate")
    clearButton:SetPoint("LEFT", resetButton, "RIGHT", 10, 0)
    clearButton:SetSize(180, 22)
    clearButton:SetText(L["CLEAR_CACHE"] or "Clear Cached ID")
    clearButton:SetScript("OnClick", function()
        PW:ClearCache()
    end)
    
    -----------------------------
    -- 分组 2: 外观设置
    -----------------------------
    
    local groupAppearance = CreateGroupBox(content, L["APPEARANCE_TITLE"] or "Appearance Settings")
    groupAppearance:SetPoint("TOPLEFT", groupGeneral, "BOTTOMLEFT", 0, -30)
    groupAppearance:SetPoint("RIGHT", -10, 0)
    groupAppearance:SetHeight(250)

    -- 字体大小滑块
    local fontSizeSlider = CreateFrame("Slider", nil, groupAppearance, "OptionsSliderTemplate")
    fontSizeSlider:SetPoint("TOPLEFT", 16, -40)
    fontSizeSlider:SetMinMaxValues(10, 32)
    fontSizeSlider:SetValue(PW.db.profile.fontSize or 16)
    fontSizeSlider:SetValueStep(1)
    fontSizeSlider:SetObeyStepOnDrag(true)
    fontSizeSlider:SetWidth(200)
    
    local fontSizeLabel = fontSizeSlider:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    fontSizeLabel:SetPoint("BOTTOM", fontSizeSlider, "TOP", 0, 4)
    fontSizeLabel:SetText(string.format(L["FONT_SIZE"] or "Font Size: %d", fontSizeSlider:GetValue()))
    
    fontSizeSlider.Low:SetText("10")
    fontSizeSlider.High:SetText("32")
    
    fontSizeSlider:SetScript("OnValueChanged", function(self, value)
        value = math.floor(value + 0.5)
        fontSizeLabel:SetText(string.format(L["FONT_SIZE"] or "Font Size: %d", value))
        PW.db.profile.fontSize = value
        PW:UpdateAppearance()
    end)

    -- 透明度滑块
    local alphaSlider = CreateFrame("Slider", nil, groupAppearance, "OptionsSliderTemplate")
    alphaSlider:SetPoint("LEFT", fontSizeSlider, "RIGHT", 40, 0)
    alphaSlider:SetMinMaxValues(0.1, 1.0)
    alphaSlider:SetValue(PW.db.profile.windowAlpha or 1.0)
    alphaSlider:SetValueStep(0.1)
    alphaSlider:SetObeyStepOnDrag(true)
    alphaSlider:SetWidth(200)
    
    local alphaLabel = alphaSlider:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    alphaLabel:SetPoint("BOTTOM", alphaSlider, "TOP", 0, 4)
    alphaLabel:SetText(string.format(L["WINDOW_ALPHA"] or "Transparency: %.1f", alphaSlider:GetValue()))
    
    alphaSlider.Low:SetText("0.1")
    alphaSlider.High:SetText("1.0")
    
    alphaSlider:SetScript("OnValueChanged", function(self, value)
        value = math.floor(value * 10 + 0.5) / 10
        alphaLabel:SetText(string.format(L["WINDOW_ALPHA"] or "Transparency: %.1f", value))
        PW.db.profile.windowAlpha = value
        PW:UpdateAppearance()
    end)

    -- 字体选择 (单选按钮组)
    local fontLabel = groupAppearance:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    fontLabel:SetPoint("TOPLEFT", fontSizeSlider, "BOTTOMLEFT", -16, -24)
    fontLabel:SetText(L["FONT_FACE"] or "Font")

    local fonts = {
        {name = L["FONT_SYSTEM"] or "System Default", path = STANDARD_TEXT_FONT},
        {name = L["FONT_CHAT"] or "Chat Font", path = ChatFontNormal:GetFont()},
        {name = L["FONT_DAMAGE"] or "Combat Text", path = DAMAGE_TEXT_FONT},
    }

    local fontRadioButtons = {}
    for i, f in ipairs(fonts) do
        local rb = CreateFrame("CheckButton", nil, groupAppearance, "UIRadioButtonTemplate")
        if i == 1 then
            rb:SetPoint("TOPLEFT", fontLabel, "BOTTOMLEFT", 0, -8)
        else
            rb:SetPoint("LEFT", fontRadioButtons[i-1].text, "RIGHT", 20, 0)
        end
        
        rb.text = rb:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        rb.text:SetPoint("LEFT", rb, "RIGHT", 5, 1)
        rb.text:SetText(f.name)
        
        rb:SetScript("OnClick", function(self)
            PW.db.profile.fontFace = f.path
            PW:UpdateAppearance()
            for _, btn in ipairs(fontRadioButtons) do
                btn:SetChecked(btn == self)
            end
        end)
        
        -- 初始化选中状态
        -- 注意: 简单的字符串比较可能因为路径格式不同而失败，这里做简单处理
        -- 实际应用中可能需要更严谨的路径比较
        rb:SetChecked(PW.db.profile.fontFace == f.path)
        
        table.insert(fontRadioButtons, rb)
    end

    -- 窗口风格选择 (单选按钮组)
    local styleLabel = groupAppearance:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    styleLabel:SetPoint("TOPLEFT", fontRadioButtons[1], "BOTTOMLEFT", 0, -16)
    styleLabel:SetText(L["WINDOW_STYLE"] or "Window Style")

    local styles = {
        {name = L["STYLE_STANDARD"] or "Blizzard Dialog", value = "Standard"},
        {name = L["STYLE_TOOLTIP"] or "Blizzard Tooltip", value = "Tooltip"},
        {name = L["STYLE_FLAT"] or "Flat", value = "Flat"},
        {name = L["STYLE_NONE"] or "None", value = "None"},
    }

    local styleRadioButtons = {}
    for i, s in ipairs(styles) do
        local rb = CreateFrame("CheckButton", nil, groupAppearance, "UIRadioButtonTemplate")
        if i == 1 then
            rb:SetPoint("TOPLEFT", styleLabel, "BOTTOMLEFT", 0, -8)
        else
            rb:SetPoint("LEFT", styleRadioButtons[i-1].text, "RIGHT", 20, 0)
        end
        
        rb.text = rb:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        rb.text:SetPoint("LEFT", rb, "RIGHT", 5, 1)
        rb.text:SetText(s.name)
        
        rb:SetScript("OnClick", function(self)
            PW.db.profile.windowStyle = s.value
            PW:UpdateAppearance()
            for _, btn in ipairs(styleRadioButtons) do
                btn:SetChecked(btn == self)
            end
        end)
        
        rb:SetChecked(PW.db.profile.windowStyle == s.value)
        table.insert(styleRadioButtons, rb)
    end

    -- 背景颜色按钮
    local bgColorButton = CreateFrame("Button", nil, groupAppearance, "UIPanelButtonTemplate")
    bgColorButton:SetPoint("TOPLEFT", styleRadioButtons[1], "BOTTOMLEFT", 0, -24)
    bgColorButton:SetSize(180, 22)
    bgColorButton:SetText(L["BACKGROUND_COLOR"] or "Background Color")
    
    local bgSwatch = bgColorButton:CreateTexture(nil, "OVERLAY")
    bgSwatch:SetSize(16, 16)
    bgSwatch:SetPoint("RIGHT", -4, 0)
    local bgCol = PW.db.profile.backgroundColor
    bgSwatch:SetColorTexture(bgCol.r, bgCol.g, bgCol.b, bgCol.a)
    
    bgColorButton:SetScript("OnClick", function()
        local c = PW.db.profile.backgroundColor
        ShowColorPicker(c.r, c.g, c.b, c.a, function(r, g, b, a)
            PW.db.profile.backgroundColor = {r = r, g = g, b = b, a = a}
            bgSwatch:SetColorTexture(r, g, b, a)
            PW:UpdateAppearance()
        end)
    end)

    -- 边框颜色按钮
    local borderColorButton = CreateFrame("Button", nil, groupAppearance, "UIPanelButtonTemplate")
    borderColorButton:SetPoint("LEFT", bgColorButton, "RIGHT", 60, 0)
    borderColorButton:SetSize(180, 22)
    borderColorButton:SetText(L["BORDER_COLOR"] or "Border Color")
    
    local borderSwatch = borderColorButton:CreateTexture(nil, "OVERLAY")
    borderSwatch:SetSize(16, 16)
    borderSwatch:SetPoint("RIGHT", -4, 0)
    local borderCol = PW.db.profile.borderColor
    borderSwatch:SetColorTexture(borderCol.r, borderCol.g, borderCol.b, borderCol.a)
    
    borderColorButton:SetScript("OnClick", function()
        local c = PW.db.profile.borderColor
        ShowColorPicker(c.r, c.g, c.b, c.a, function(r, g, b, a)
            PW.db.profile.borderColor = {r = r, g = g, b = b, a = a}
            borderSwatch:SetColorTexture(r, g, b, a)
            PW:UpdateAppearance()
        end)
    end)

    -----------------------------
    -- 底部说明区域
    -----------------------------
    
    -- 命令说明
    local commandsTitle = content:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    commandsTitle:SetPoint("TOPLEFT", groupAppearance, "BOTTOMLEFT", 0, -30)
    commandsTitle:SetText(L["COMMANDS_TITLE"] or "Commands:")
    
    local commandsText = content:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
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
    local noteTitle = content:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    noteTitle:SetPoint("TOPLEFT", commandsText, "BOTTOMLEFT", -8, -16)
    noteTitle:SetText(L["NOTE_TITLE"] or "Note:")
    
    local noteText = content:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
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
    if self.settingsCategory and Settings and Settings.OpenToCategory then
        Settings.OpenToCategory(self.settingsCategory:GetID())
    -- 旧API
    elseif InterfaceOptionsFrame_OpenToCategory then
        InterfaceOptionsFrame_OpenToCategory("|cffff8000Phase|rWatcher")
        InterfaceOptionsFrame_OpenToCategory("|cffff8000Phase|rWatcher")  -- 调用两次确保打开
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
    
    -- 应用外观设置
    self:UpdateAppearance()
    
    -- 初始UI更新
    self:UpdateUI()
end

-----------------------------
-- 导出到全局
-----------------------------
_G["PhaseWatcher"] = PW