-----------------------------
-- PhaseWatcher UI Module
-- Version 2.1.0
-- 功能：创建主显示窗口、右键菜单、设置面板，处理外观更新和窗口交互
-----------------------------

local AddonName, PW = ...
local L = PhaseWatcher_Locale or {}

-----------------------------
-- UI 变量（存储主框架和子控件的引用）
-----------------------------
PW.mainFrame = nil    -- 主窗口框架
PW.phaseText = nil    -- 显示位面 ID 的字体字符串
PW.dragHint = nil     -- “拖动移动”提示文本
PW.settingsCategory = nil  -- 设置面板在 Interface Options 中的 Category 对象

-----------------------------
-- 创建主框架
-----------------------------
local function CreateMainFrame()
    -- 创建主窗口帧，继承 BackdropTemplate 以支持 11.0+ 的背景系统
    local frame = CreateFrame("Frame", "PhaseWatcherFrame", UIParent, "BackdropTemplate")
    frame:SetSize(220, 60)
    -- 默认居中对齐 UIParent，后续由 UpdateFramePosition 覆盖为保存的位置
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    frame:SetFrameStrata("MEDIUM")   -- 层级，确保不被多数 UI 遮挡
    frame:SetFrameLevel(10)
    frame:EnableMouse(true)          -- 允许鼠标交互
    frame:SetMovable(true)           -- 允许拖动
    frame:RegisterForDrag("LeftButton")
    frame:SetClampedToScreen(true)   -- 限制窗口不可移出屏幕

    -- 设置背景纹理和边框（默认使用暴雪对话框样式）
    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    frame:SetBackdropColor(0, 0, 0, 0.85)        -- 背景黑色半透明
    frame:SetBackdropBorderColor(0.4, 0.4, 0.4, 1) -- 边框灰色

    -- 创建位面 ID 显示文本（主内容区域）
    local phaseText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    phaseText:SetPoint("CENTER", frame, "CENTER", 0, 0)
    phaseText:SetText(L["INITIALIZING"] or "Initializing...")
    phaseText:SetTextColor(0, 1, 0.5, 1)          -- 默认青绿色
    phaseText:SetJustifyH("CENTER")
    PW.phaseText = phaseText

    -- 拖动提示文本（仅在窗口未锁定时显示，初始透明）
    local dragHint = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalTiny")
    dragHint:SetPoint("BOTTOM", frame, "BOTTOM", 0, 6)
    dragHint:SetText(L["DRAG_TO_MOVE"] or "Drag to move")
    dragHint:SetTextColor(0.5, 0.5, 0.5, 0.7)
    dragHint:SetAlpha(0)                           -- 初始隐藏
    PW.dragHint = dragHint

    -- 鼠标进入事件：显示拖动提示（若未锁定）和工具提示（若开启）
    frame:SetScript("OnEnter", function(self)
        if not PW.db.profile.isLocked then
            dragHint:SetAlpha(1)
        end
        if PW.db.profile.showTooltip then
            PW:ShowTooltip(self)                   -- 调用工具提示方法
        end
    end)

    -- 鼠标离开事件：隐藏拖动提示和游戏内置提示
    frame:SetScript("OnLeave", function(self)
        dragHint:SetAlpha(0)
        GameTooltip:Hide()
    end)

    -- 鼠标按下事件：右键时弹出上下文菜单
    frame:SetScript("OnMouseDown", function(self, button)
        if button == "RightButton" then
            PW:ShowContextMenu(self)
        end
    end)

    -- 拖动开始：仅在未锁定且左键拖动时激活
    frame:SetScript("OnDragStart", function(self, button)
        if button == "LeftButton" then
            if not PW.db.profile.isLocked then
                self:StartMoving()
            end
        end
    end)

    -- 拖动结束：停止移动并保存新坐标
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        PW:SavePosition()
    end)

    PW.mainFrame = frame
    return frame
end

-----------------------------
-- 自动调整窗口大小（根据文本内容）
-----------------------------
function PW:ResizeFrameToContent()
    if not self.mainFrame or not self.phaseText then return end

    -- 获取文本实际宽高
    local phaseWidth = self.phaseText:GetStringWidth() or 0
    local phaseHeight = self.phaseText:GetStringHeight() or 0

    -- 添加内边距：水平 30px，垂直 20px
    local paddingX = 30
    local paddingY = 20

    -- 计算最终尺寸，设置最小宽度 140、最小高度 50
    local width = phaseWidth + paddingX
    local height = phaseHeight + paddingY
    self.mainFrame:SetSize(math.max(width, 140), math.max(height, 50))
end

-----------------------------
-- 外观更新函数
-- 根据数据库设置同步更新窗口的透明度、字体、背景/边框样式
-----------------------------
function PW:UpdateAppearance()
    if not self.mainFrame then return end

    -- 1. 设置透明度
    self.mainFrame:SetAlpha(self.db.profile.windowAlpha or 1.0)

    -- 2. 更新字体（路径和大小），添加 OUTLINE 描边增强可读性
    local fontPath = self.db.profile.fontFace or STANDARD_TEXT_FONT
    local fontSize = self.db.profile.fontSize or 16
    if self.phaseText then
        self.phaseText:SetFont(fontPath, fontSize, "OUTLINE")
    end

    -- 3. 应用窗口风格
    local style = self.db.profile.windowStyle or "Standard"
    local bg = self.db.profile.backgroundColor or {r = 0, g = 0, b = 0, a = 0.85}
    local border = self.db.profile.borderColor or {r = 0.4, g = 0.4, b = 0.4, a = 1}

    if style == "None" then
        -- 无背景模式：移除所有背景和边框纹理
        self.mainFrame:SetBackdrop(nil)
    elseif style == "Tooltip" then
        -- 模拟暴雪工具提示样式
        self.mainFrame:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 }
        })
        self.mainFrame:SetBackdropColor(bg.r, bg.g, bg.b, bg.a)
        self.mainFrame:SetBackdropBorderColor(border.r, border.g, border.b, border.a)
    elseif style == "Flat" then
        -- 扁平纯色背景（使用纯白色纹理并染色）
        self.mainFrame:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            tile = false, edgeSize = 1,
            insets = { left = 0, right = 0, top = 0, bottom = 0 }
        })
        self.mainFrame:SetBackdropColor(bg.r, bg.g, bg.b, bg.a)
        self.mainFrame:SetBackdropBorderColor(border.r, border.g, border.b, border.a)
    else -- 默认 "Standard" 风格
        self.mainFrame:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true, tileSize = 32, edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 }
        })
        self.mainFrame:SetBackdropColor(bg.r, bg.g, bg.b, bg.a)
        self.mainFrame:SetBackdropBorderColor(border.r, border.g, border.b, border.a)
    end

    -- 4. 自动调整窗口大小（字体变化后）
    self:ResizeFrameToContent()
end

-----------------------------
-- UI 更新函数（被 Core.lua 调用，刷新位面 ID 显示）
-----------------------------
function PW:UpdateUI()
    if not self.phaseText then return end

    local phaseID = self.currentPhaseID
    local source = self.currentPhaseSource
    local isSecret = self.isSecretValue

    local displayText = ""
    local r, g, b = 0, 1, 0.5   -- 默认颜色：青绿

    if isSecret then
        -- 处于 Secret Value 受限状态
        displayText = L["SECRET_VALUE"] or "Hidden (Secret Value)"
        r, g, b = 1, 0.5, 0      -- 橙色
    elseif phaseID then
        -- 成功检测到位面 ID，根据来源设置不同颜色
        local formattedID = self.FormatPhaseID(phaseID, self.db.profile.useHexadecimal)
        displayText = string.format(L["PHASE_ID"] or "Phase ID: %s", formattedID)

        if source == "cached" then
            r, g, b = 0.7, 0.7, 0.7   -- 灰色（缓存）
        elseif source == "player" then
            r, g, b = 0.5, 1, 0.5      -- 浅绿（玩家自己）
        else
            r, g, b = 0, 1, 0.5        -- 青绿（目标/鼠标）
        end
    else
        -- 未检测到，根据是否在副本显示不同提示
        if IsInInstance() then
            displayText = L["INSTANCE_LIMITATION"] or "In instance, may not detect"
            r, g, b = 1, 1, 0           -- 黄色
        else
            displayText = L["NOT_DETECTED"] or "Not Detected (Need Target/NPC)"
            r, g, b = 1, 0.3, 0.3       -- 红色
        end
    end

    self.phaseText:SetText(displayText)
    self.phaseText:SetTextColor(r, g, b, 1)
    self:ResizeFrameToContent()
end

-- 根据设置显示/隐藏窗口（同时考虑战斗自动隐藏）
function PW:UpdateFrameVisibility()
    if not self.mainFrame then return end

    local shouldShow = self.db.profile.showFrame

    -- 如果开启了战斗中隐藏且当前处于战斗锁定状态，强制隐藏
    if shouldShow and self.db.profile.autoHideInCombat and InCombatLockdown() then
        shouldShow = false
    end

    if shouldShow then
        self.mainFrame:Show()
    else
        self.mainFrame:Hide()
    end
end

-- 更新窗口锁定状态（锁定后不可拖动，并隐藏拖动提示）
function PW:UpdateFrameLock()
    if not self.mainFrame then return end

    if self.db.profile.isLocked then
        self.mainFrame:SetMovable(false)
        if self.dragHint then self.dragHint:Hide() end
    else
        self.mainFrame:SetMovable(true)
        if self.dragHint then self.dragHint:Show() end
    end
end

-----------------------------
-- 窗口位置保存 / 恢复（已修复：使用中心锚点相对偏移，适应多分辨率）
-----------------------------
function PW:UpdateFramePosition()
    if not self.mainFrame then return end

    local posX = self.db.profile.posX
    local posY = self.db.profile.posY

    self.mainFrame:ClearAllPoints()

    if posX and posY then
        -- 基于 UIParent 中心点的偏移放置
        self.mainFrame:SetPoint("CENTER", UIParent, "CENTER", posX, posY)
    else
        -- 没有保存位置时，默认居中
        self.mainFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    end
end

function PW:SavePosition()
    if not self.mainFrame then return end

    -- 计算窗口中心相对于 UIParent 中心的偏移（像素值）
    local centerX, centerY = self.mainFrame:GetCenter()
    local parentCenterX, parentCenterY = UIParent:GetCenter()

    if centerX and centerY then
        self.db.profile.posX = centerX - parentCenterX
        self.db.profile.posY = centerY - parentCenterY
    end
end

-----------------------------
-- 工具提示（鼠标悬停在窗口上时显示详细信息）
-----------------------------
function PW:ShowTooltip(frame)
    GameTooltip:SetOwner(frame, "ANCHOR_TOP")
    GameTooltip:ClearLines()

    -- 标题
    GameTooltip:AddLine(L["PHASE_MONITORING"] or "Phase Monitor", 1, 1, 1)
    GameTooltip:AddLine(" ")

    if self.currentPhaseID then
        -- 显示当前位面 ID（格式化后）
        local formattedID = self.FormatPhaseID(self.currentPhaseID, self.db.profile.useHexadecimal)
        GameTooltip:AddDoubleLine(
            L["TOOLTIP_PHASE_ID"] or "Current Phase ID:",
            formattedID,
            0.7, 0.7, 1,   -- 标签颜色
            0, 1, 0.5       -- 值颜色
        )

        -- 显示格式（十进制/十六进制）
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
        -- 受限状态下的提示
        GameTooltip:AddLine(L["ERROR_API_RESTRICTED"] or "API temporarily restricted (Secret Value)", 1, 0.5, 0)
    else
        -- 未检测到
        GameTooltip:AddLine(L["NOT_DETECTED"] or "Not Detected", 1, 0.3, 0.3)
    end

    GameTooltip:AddLine(" ")
    GameTooltip:AddLine(L["TOOLTIP_RIGHT_CLICK"] or "Right-click for options", 0.5, 0.5, 0.5)
    GameTooltip:Show()
end

-----------------------------
-- 右键菜单（使用 11.0+ 的 MenuUtil 创建，避免 Taint）
-----------------------------
function PW:ShowContextMenu(owner)
    if not MenuUtil or not MenuUtil.CreateContextMenu then return end

    MenuUtil.CreateContextMenu(owner, function(owner, root)
        root:CreateTitle(L["PHASE_MONITORING"] or "Phase Monitor")
        root:CreateDivider()

        -- 复选框：十六进制格式
        root:CreateCheckbox(
            L["USE_HEXADECIMAL"] or "Use Hexadecimal Format",
            function() return self.db.profile.useHexadecimal end,  -- 获取当前状态
            function() self:ToggleFormat() end                     -- 点击回调
        )

        -- 复选框：锁定窗口
        root:CreateCheckbox(
            L["LOCK_WINDOW"] or "Lock Window Position",
            function() return self.db.profile.isLocked end,
            function() self:ToggleLock() end
        )

        -- 复选框：显示工具提示
        root:CreateCheckbox(
            L["SHOW_TOOLTIP"] or "Show Detailed Tooltip",
            function() return self.db.profile.showTooltip end,
            function() self.db.profile.showTooltip = not self.db.profile.showTooltip end
        )

        root:CreateDivider()

        -- 按钮：清除缓存
        root:CreateButton(L["BUTTON_CLEAR_CACHE"] or "Clear Cached ID", function() self:ClearCache() end)
        -- 按钮：重置窗口位置
        root:CreateButton(L["BUTTON_RESET_POSITION"] or "Reset Window Position", function() self:ResetPosition() end)
        -- 按钮：打开完整设置
        root:CreateButton(L["SETTINGS_TITLE"] or "PhaseWatcher Settings", function() self:OpenConfig() end)

    end)
end

-----------------------------
-- 设置面板辅助函数
-----------------------------

-- 创建带边框和标题的分组框
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

-- 颜色选择器（已修复：使用最新的 ColorPickerUtil API，避免过期问题）
local function ShowColorPicker(r, g, b, a, callback)
    -- 优先使用新的 ColorPickerUtil API
    if ColorPickerUtil and ColorPickerUtil.ShowColorPicker then
        ColorPickerUtil.ShowColorPicker({
            r = r,
            g = g,
            b = b,
            opacity = a,
            -- 确认颜色后的回调
            callback = function(r, g, b, a)
                callback(r, g, b, a)
            end,
            -- 取消时的回调（恢复为打开色盘前的颜色）
            cancelCallback = function(previousValues)
                callback(previousValues.r, previousValues.g, previousValues.b, previousValues.opacity)
            end,
        })
    else
        -- 极特殊情况下的旧 API 回退（基本不会执行到）
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
end

-----------------------------
-- 创建设置面板（注册到 Interface Options）
-----------------------------
local function CreateSettingsPanel()
    local panel = CreateFrame("Frame", "PhaseWatcherSettingsPanel", UIParent)
    panel.name = "|cffff8000Phase|rWatcher"  -- 在选项列表中显示的名称

    -- 标题
    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText(L["SETTINGS_TITLE"] or "PhaseWatcher Settings")

    -- 版本信息
    local version = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    version:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    version:SetText(L["VERSION"] or "Version 2.1.0")
    version:SetTextColor(0.7, 0.7, 0.7, 1)

    -- 滚动框架（容纳较多设置项）
    local scrollFrame = CreateFrame("ScrollFrame", nil, panel, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 10, -60)
    scrollFrame:SetPoint("BOTTOMRIGHT", -30, 10)

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

    -- 1. 显示窗口复选框
    local showFrameCheck = CreateFrame("CheckButton", nil, groupGeneral, "InterfaceOptionsCheckButtonTemplate")
    showFrameCheck:SetPoint("TOPLEFT", 16, -30)
    showFrameCheck.Text:SetText(L["SHOW_FRAME"] or "Show Phase Monitor Window")
    showFrameCheck:SetChecked(PW.db.profile.showFrame)
    showFrameCheck:SetScript("OnClick", function(self)
        PW.db.profile.showFrame = self:GetChecked()
        PW:UpdateFrameVisibility()
    end)

    -- 2. 十六进制显示复选框
    local hexCheck = CreateFrame("CheckButton", nil, groupGeneral, "InterfaceOptionsCheckButtonTemplate")
    hexCheck:SetPoint("TOPLEFT", showFrameCheck, "BOTTOMLEFT", 0, -8)
    hexCheck.Text:SetText(L["USE_HEXADECIMAL"] or "Use Hexadecimal Format")
    hexCheck:SetChecked(PW.db.profile.useHexadecimal)
    hexCheck:SetScript("OnClick", function(self)
        PW:ToggleFormat(self:GetChecked())
    end)

    -- 3. 锁定窗口复选框
    local lockCheck = CreateFrame("CheckButton", nil, groupGeneral, "InterfaceOptionsCheckButtonTemplate")
    lockCheck:SetPoint("TOPLEFT", hexCheck, "BOTTOMLEFT", 0, -8)
    lockCheck.Text:SetText(L["LOCK_WINDOW"] or "Lock Window Position")
    lockCheck:SetChecked(PW.db.profile.isLocked)
    lockCheck:SetScript("OnClick", function(self)
        PW.db.profile.isLocked = self:GetChecked()
        PW:UpdateFrameLock()
    end)

    -- 4. 显示工具提示复选框
    local tooltipCheck = CreateFrame("CheckButton", nil, groupGeneral, "InterfaceOptionsCheckButtonTemplate")
    tooltipCheck:SetPoint("TOPLEFT", lockCheck, "BOTTOMLEFT", 0, -8)
    tooltipCheck.Text:SetText(L["SHOW_TOOLTIP"] or "Show Detailed Tooltip")
    tooltipCheck:SetChecked(PW.db.profile.showTooltip)
    tooltipCheck:SetScript("OnClick", function(self)
        PW.db.profile.showTooltip = self:GetChecked()
    end)

    -- 5. 战斗中自动隐藏复选框
    local autoHideCheck = CreateFrame("CheckButton", nil, groupGeneral, "InterfaceOptionsCheckButtonTemplate")
    autoHideCheck:SetPoint("TOPLEFT", tooltipCheck, "BOTTOMLEFT", 0, -8)
    autoHideCheck.Text:SetText(L["AUTO_HIDE"] or "Auto Hide in Combat")
    autoHideCheck:SetChecked(PW.db.profile.autoHideInCombat)
    autoHideCheck:SetScript("OnClick", function(self)
        PW.db.profile.autoHideInCombat = self:GetChecked()
    end)

    -- 6. 更新间隔滑块
    local intervalSlider = CreateFrame("Slider", nil, groupGeneral, "OptionsSliderTemplate")
    intervalSlider:SetPoint("TOPLEFT", autoHideCheck, "BOTTOMLEFT", 16, -32)
    intervalSlider:SetMinMaxValues(0.1, 2.0)
    intervalSlider:SetValue(PW.db.profile.updateInterval or 0.5)
    intervalSlider:SetValueStep(0.1)
    intervalSlider:SetObeyStepOnDrag(true)  -- 拖动时按步长吸附
    intervalSlider:SetWidth(200)

    -- 滑块上方的数值标签
    local intervalLabel = intervalSlider:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    intervalLabel:SetPoint("BOTTOM", intervalSlider, "TOP", 0, 4)
    intervalLabel:SetText(string.format(L["UPDATE_INTERVAL"] or "Update Interval: %.1f sec", intervalSlider:GetValue()))

    intervalSlider.Low:SetText(L["UPDATE_INTERVAL_LOW"] or "0.1s")
    intervalSlider.High:SetText(L["UPDATE_INTERVAL_HIGH"] or "2.0s")

    intervalSlider:SetScript("OnValueChanged", function(self, value)
        value = math.floor(value * 10 + 0.5) / 10   -- 四舍五入到 0.1
        intervalLabel:SetText(string.format(L["UPDATE_INTERVAL"] or "Update Interval: %.1f sec", value))
        if PW.db.profile.updateInterval ~= value then
            PW.db.profile.updateInterval = value
            PW:RestartUpdateTimer()
        end
    end)

    -- 7. 重置窗口位置按钮
    local resetButton = CreateFrame("Button", nil, groupGeneral, "UIPanelButtonTemplate")
    resetButton:SetPoint("TOPLEFT", intervalSlider, "BOTTOMLEFT", -16, -32)
    resetButton:SetSize(180, 22)
    resetButton:SetText(L["RESET_POSITION"] or "Reset Window Position")
    resetButton:SetScript("OnClick", function()
        PW:ResetPosition()
    end)

    -- 8. 清除缓存按钮
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

    -- 字体选择单选按钮组
    local fontLabel = groupAppearance:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    fontLabel:SetPoint("TOPLEFT", fontSizeSlider, "BOTTOMLEFT", -16, -24)
    fontLabel:SetText(L["FONT_FACE"] or "Font")

    local fonts = {
        {name = L["FONT_SYSTEM"] or "System Default", path = STANDARD_TEXT_FONT},
        {name = L["FONT_CHAT"] or "Chat Font", path = (ChatFontNormal and ChatFontNormal:GetFont()) or STANDARD_TEXT_FONT},
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
        rb:SetChecked(PW.db.profile.fontFace == f.path)
        table.insert(fontRadioButtons, rb)
    end

    -- 窗口风格选择单选按钮组
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

    -- 背景颜色选择按钮
    local bgColorButton = CreateFrame("Button", nil, groupAppearance, "UIPanelButtonTemplate")
    bgColorButton:SetPoint("TOPLEFT", styleRadioButtons[1], "BOTTOMLEFT", 0, -24)
    bgColorButton:SetSize(180, 22)
    bgColorButton:SetText(L["BACKGROUND_COLOR"] or "Background Color")

    -- 按钮右侧的颜色预览方块
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

    -- 边框颜色选择按钮
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
    -- 命令说明标题
    local commandsTitle = content:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    commandsTitle:SetPoint("TOPLEFT", groupAppearance, "BOTTOMLEFT", 0, -30)
    commandsTitle:SetText(L["COMMANDS_TITLE"] or "Commands:")

    -- 命令列表
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

    -- 注意事项标题
    local noteTitle = content:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    noteTitle:SetPoint("TOPLEFT", commandsText, "BOTTOMLEFT", -8, -16)
    noteTitle:SetText(L["NOTE_TITLE"] or "Note:")

    -- 注意事项内容
    local noteText = content:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    noteText:SetPoint("TOPLEFT", noteTitle, "BOTTOMLEFT", 8, -8)
    noteText:SetJustifyH("LEFT")
    noteText:SetWidth(500)
    noteText:SetText(L["NOTE_INSTANCE"] or "In instances or combat, phase ID may not be available due to API limitations")

    -----------------------------
    -- 注册到系统设置（Interface Options）
    -----------------------------
    if Settings and Settings.RegisterCanvasLayoutCategory then
        -- 11.0+ 新 API（正式服）
        local category = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
        Settings.RegisterAddOnCategory(category)
        PW.settingsCategory = category
    elseif InterfaceOptions_AddCategory then
        -- 旧 API（保留兼容，但正式服已不再需要）
        InterfaceOptions_AddCategory(panel)
    end

    return panel
end

-- 打开设置面板（从命令或右键菜单调用）
function PW:OpenConfig()
    if self.settingsCategory and Settings and Settings.OpenToCategory then
        -- 11.0+ 方式：定位到我们注册的分类
        Settings.OpenToCategory(self.settingsCategory:GetID())
    elseif InterfaceOptionsFrame_OpenToCategory then
        -- 旧方式（调用两次以确保定位）
        InterfaceOptionsFrame_OpenToCategory("|cffff8000Phase|rWatcher")
        InterfaceOptionsFrame_OpenToCategory("|cffff8000Phase|rWatcher")
    end
end

-----------------------------
-- UI 初始化入口（由 Core.lua 在 ADDON_LOADED 时调用）
-----------------------------
function PW:InitializeUI()
    -- 如果主框架尚未创建（首次调用），则创建
    if not self.mainFrame then
        CreateMainFrame()
    end

    -- 创建设置面板（注册到选项窗口）
    CreateSettingsPanel()

    -- 恢复或初始化窗口位置、锁定状态、可见性、外观
    self:UpdateFramePosition()
    self:UpdateFrameLock()
    self:UpdateFrameVisibility()
    self:UpdateAppearance()

    -- 刷新位面 ID 显示
    self:UpdateUI()
end

-----------------------------
-- 导出到全局（确保其他模块和脚本可访问）
-----------------------------
_G["PhaseWatcher"] = PW