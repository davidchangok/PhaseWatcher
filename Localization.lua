-----------------------------
-- PhaseWatcher 本地化系统
-- Version 2.0.1
-----------------------------

local AddonName = "PhaseWatcher"
PhaseWatcher_Locale = PhaseWatcher_Locale or {}
local L = PhaseWatcher_Locale

-- 获取客户端语言
local locale = GetLocale()

-----------------------------
-- 默认语言：英文 (enUS)
-----------------------------
L["ADDON_LOADED"] = "loaded - Type %s to open settings"
L["ADDON_NAME"] = "Phase|cFFFFFFFFWatcher|r"
L["VERSION"] = "Version 2.0.1 - Fixed a bug in the display position initialization of the multi-role account plugin."

-- UI 文本
L["PHASE_MONITORING"] = "Phase Monitor"
L["INITIALIZING"] = "Initializing..."
L["PHASE_ID"] = "Phase ID: %s"
L["NOT_DETECTED"] = "Not Detected (Need Target/NPC)"
L["INSTANCE_LIMITATION"] = "In instance, may not detect due to API limitation"
L["SECRET_VALUE"] = "Hidden (Secret Value)"
L["DETECTING"] = "Detecting..."
L["DRAG_TO_MOVE"] = "Drag to move"

-- 设置面板
L["SETTINGS_TITLE"] = "Addon Settings"
L["SHOW_FRAME"] = "Show Phase Monitor Window"
L["USE_HEXADECIMAL"] = "Use Hexadecimal Format"
L["UPDATE_INTERVAL"] = "Update Interval: %.1f sec"
L["UPDATE_INTERVAL_LOW"] = "0.1 sec"
L["UPDATE_INTERVAL_HIGH"] = "2.0 sec"
L["RESET_POSITION"] = "Reset Window Position"
L["CLEAR_CACHE"] = "Clear Cached ID"
L["LOCK_WINDOW"] = "Lock Window Position"
L["SHOW_TOOLTIP"] = "Show Detailed Tooltip"
L["AUTO_HIDE"] = "Auto Hide in Combat"
L["GENERAL_SETTINGS"] = "General Settings"
L["APPEARANCE_TITLE"] = "Appearance Settings"
L["FONT_FACE"] = "Font"
L["FONT_SIZE"] = "Font Size: %d"
L["WINDOW_STYLE"] = "Window Style"
L["WINDOW_ALPHA"] = "Transparency: %.1f"
L["STYLE_STANDARD"] = "Blizzard Dialog"
L["STYLE_TOOLTIP"] = "Blizzard Tooltip"
L["STYLE_FLAT"] = "Flat"
L["STYLE_NONE"] = "No Background"
L["FONT_SYSTEM"] = "System Default"
L["FONT_CHAT"] = "Chat Font"
L["FONT_DAMAGE"] = "Combat Text Font"
L["BACKGROUND_COLOR"] = "Background Color"
L["BORDER_COLOR"] = "Border Color"

-- 命令说明
L["COMMANDS_TITLE"] = "Commands:"
L["CMD_TOGGLE"] = "/pw - Toggle window visibility"
L["CMD_SHOW"] = "/pw show - Show window"
L["CMD_HIDE"] = "/pw hide - Hide window"
L["CMD_RESET"] = "/pw reset - Reset window position"
L["CMD_CLEAR"] = "/pw clear - Clear cached ID"
L["CMD_HEX"] = "/pw hex - Switch to hexadecimal"
L["CMD_DEC"] = "/pw dec - Switch to decimal"
L["CMD_LOCK"] = "/pw lock - Toggle window lock"
L["CMD_CONFIG"] = "/pw config - Open settings panel"
L["NOTE_TITLE"] = "Note:"
L["NOTE_INSTANCE"] = "In instances or combat, phase ID may not be available due to API limitations (Secret Values)"
L["NOTE_TARGET"] = "Target an NPC or player to detect their phase"

-- 聊天消息
L["WINDOW_RESET"] = "Window position has been reset"
L["CACHE_CLEARED"] = "Cached phase ID has been cleared"
L["FORMAT_SWITCHED_HEX"] = "Switched to hexadecimal display"
L["FORMAT_SWITCHED_DEC"] = "Switched to decimal display"
L["WINDOW_SHOWN"] = "Window shown"
L["WINDOW_HIDDEN"] = "Window hidden"
L["WINDOW_LOCKED"] = "Window locked"
L["WINDOW_UNLOCKED"] = "Window unlocked"
L["SETTINGS_SAVED"] = "Settings saved"

-- 错误消息
L["ERROR_GUID_PARSE"] = "Failed to parse GUID for phase information"
L["ERROR_API_RESTRICTED"] = "API temporarily restricted (Secret Value)"
L["ERROR_NO_UNIT"] = "No valid unit target found"

-- 工具提示
L["TOOLTIP_PHASE_ID"] = "Current Phase ID"
L["TOOLTIP_FORMAT"] = "Format:"
L["TOOLTIP_DECIMAL"] = "Decimal"
L["TOOLTIP_HEXADECIMAL"] = "Hexadecimal"
L["TOOLTIP_SOURCE"] = "Source:"
L["TOOLTIP_SOURCE_PLAYER"] = "Player"
L["TOOLTIP_SOURCE_TARGET"] = "Target"
L["TOOLTIP_SOURCE_MOUSEOVER"] = "Mouseover"
L["TOOLTIP_SOURCE_CACHED"] = "Cached"
L["TOOLTIP_RIGHT_CLICK"] = "Right-click for options"

-----------------------------
-- 简体中文 (zhCN)
-----------------------------
if locale == "zhCN" then
    L["ADDON_LOADED"] = "已加载 - 输入 %s 打开设置"
    L["ADDON_NAME"] = "位面|cFFFFFFFF监测|r"
    L["VERSION"] = "版本 2.0.1 - 修复多角色账号显示位置初始化错误"
    
    -- UI 文本
    L["PHASE_MONITORING"] = "位面监测"
    L["INITIALIZING"] = "初始化中..."
    L["PHASE_ID"] = "位面ID: %s"
    L["NOT_DETECTED"] = "未检测到 (需要目标/NPC)"
    L["INSTANCE_LIMITATION"] = "副本中可能因API限制无法检测"
    L["SECRET_VALUE"] = "已隐藏 (Secret Value)"
    L["DETECTING"] = "检测中..."
    L["DRAG_TO_MOVE"] = "拖动移动"
    
    -- 设置面板
    L["SETTINGS_TITLE"] = "插件设置"
    L["SHOW_FRAME"] = "显示位面监测窗口"
    L["USE_HEXADECIMAL"] = "使用16进制显示"
    L["UPDATE_INTERVAL"] = "更新间隔: %.1f 秒"
    L["UPDATE_INTERVAL_LOW"] = "0.1秒"
    L["UPDATE_INTERVAL_HIGH"] = "2.0秒"
    L["RESET_POSITION"] = "重置窗口位置"
    L["CLEAR_CACHE"] = "清除缓存ID"
    L["LOCK_WINDOW"] = "锁定窗口位置"
    L["SHOW_TOOLTIP"] = "显示详细提示"
    L["AUTO_HIDE"] = "战斗中自动隐藏"
    L["GENERAL_SETTINGS"] = "常规设置"
    L["APPEARANCE_TITLE"] = "外观设置"
    L["FONT_FACE"] = "字体"
    L["FONT_SIZE"] = "字体大小: %d"
    L["WINDOW_STYLE"] = "窗口风格"
    L["WINDOW_ALPHA"] = "透明度: %.1f"
    L["STYLE_STANDARD"] = "暴雪对话框"
    L["STYLE_TOOLTIP"] = "暴雪提示框"
    L["STYLE_FLAT"] = "扁平"
    L["STYLE_NONE"] = "无背景"
    L["FONT_SYSTEM"] = "系统默认"
    L["FONT_CHAT"] = "聊天字体"
    L["FONT_DAMAGE"] = "战斗文字"
L["BACKGROUND_COLOR"] = "背景颜色"
L["BORDER_COLOR"] = "边框颜色"
    
    -- 命令说明
    L["COMMANDS_TITLE"] = "命令说明:"
    L["CMD_TOGGLE"] = "/pw - 显示/隐藏窗口"
    L["CMD_SHOW"] = "/pw show - 显示窗口"
    L["CMD_HIDE"] = "/pw hide - 隐藏窗口"
    L["CMD_RESET"] = "/pw reset - 重置窗口位置"
    L["CMD_CLEAR"] = "/pw clear - 清除缓存ID"
    L["CMD_HEX"] = "/pw hex - 切换到16进制"
    L["CMD_DEC"] = "/pw dec - 切换到10进制"
    L["CMD_LOCK"] = "/pw lock - 切换窗口锁定"
    L["CMD_CONFIG"] = "/pw config - 打开设置面板"
    L["NOTE_TITLE"] = "注意:"
    L["NOTE_INSTANCE"] = "在副本或战斗中,由于API限制(Secret Values)可能无法获取位面ID"
    L["NOTE_TARGET"] = "选中一个NPC或玩家以检测其位面"
    
    -- 聊天消息
    L["WINDOW_RESET"] = "窗口位置已重置"
    L["CACHE_CLEARED"] = "已清除缓存的位面ID"
    L["FORMAT_SWITCHED_HEX"] = "已切换到16进制显示"
    L["FORMAT_SWITCHED_DEC"] = "已切换到10进制显示"
    L["WINDOW_SHOWN"] = "窗口已显示"
    L["WINDOW_HIDDEN"] = "窗口已隐藏"
    L["WINDOW_LOCKED"] = "窗口已锁定"
    L["WINDOW_UNLOCKED"] = "窗口已解锁"
    L["SETTINGS_SAVED"] = "设置已保存"
    
    -- 错误消息
    L["ERROR_GUID_PARSE"] = "解析GUID获取位面信息失败"
    L["ERROR_API_RESTRICTED"] = "API暂时受限 (Secret Value)"
    L["ERROR_NO_UNIT"] = "未找到有效的单位目标"
    
    -- 工具提示
    L["TOOLTIP_PHASE_ID"] = "当前位面ID"
    L["TOOLTIP_FORMAT"] = "格式:"
    L["TOOLTIP_DECIMAL"] = "十进制"
    L["TOOLTIP_HEXADECIMAL"] = "十六进制"
    L["TOOLTIP_SOURCE"] = "来源:"
    L["TOOLTIP_SOURCE_PLAYER"] = "玩家"
    L["TOOLTIP_SOURCE_TARGET"] = "目标"
    L["TOOLTIP_SOURCE_MOUSEOVER"] = "鼠标指向"
    L["TOOLTIP_SOURCE_CACHED"] = "缓存"
    L["TOOLTIP_RIGHT_CLICK"] = "右键点击打开选项"
end

-----------------------------
-- 繁体中文 (zhTW)
-----------------------------
if locale == "zhTW" then
    L["ADDON_LOADED"] = "已載入 - 輸入 %s 開啟設定"
    L["ADDON_NAME"] = "位面|cFFFFFFFF監測|r"
    L["VERSION"] = "版本 2.0.1 - 修復多角色帳號顯示位置初始化錯誤"
    
    -- UI 文本
    L["PHASE_MONITORING"] = "位面監測"
    L["INITIALIZING"] = "初始化中..."
    L["PHASE_ID"] = "位面ID: %s"
    L["NOT_DETECTED"] = "未檢測到 (需要目標/NPC)"
    L["INSTANCE_LIMITATION"] = "副本中可能因API限制無法檢測"
    L["SECRET_VALUE"] = "已隱藏 (Secret Value)"
    L["DETECTING"] = "檢測中..."
    L["DRAG_TO_MOVE"] = "拖動移動"
    
    -- 设置面板
    L["SETTINGS_TITLE"] = "插件設定"
    L["SHOW_FRAME"] = "顯示位面監測視窗"
    L["USE_HEXADECIMAL"] = "使用16進制顯示"
    L["UPDATE_INTERVAL"] = "更新間隔: %.1f 秒"
    L["UPDATE_INTERVAL_LOW"] = "0.1秒"
    L["UPDATE_INTERVAL_HIGH"] = "2.0秒"
    L["RESET_POSITION"] = "重置視窗位置"
    L["CLEAR_CACHE"] = "清除快取ID"
    L["LOCK_WINDOW"] = "鎖定視窗位置"
    L["SHOW_TOOLTIP"] = "顯示詳細提示"
    L["AUTO_HIDE"] = "戰鬥中自動隱藏"
    L["GENERAL_SETTINGS"] = "一般設定"
    L["APPEARANCE_TITLE"] = "外觀設定"
    L["FONT_FACE"] = "字型"
    L["FONT_SIZE"] = "字型大小: %d"
    L["WINDOW_STYLE"] = "視窗風格"
    L["WINDOW_ALPHA"] = "透明度: %.1f"
    L["STYLE_STANDARD"] = "暴雪對話框"
    L["STYLE_TOOLTIP"] = "暴雪提示框"
    L["STYLE_FLAT"] = "扁平"
    L["STYLE_NONE"] = "無背景"
    L["FONT_SYSTEM"] = "系統預設"
    L["FONT_CHAT"] = "聊天字型"
    L["FONT_DAMAGE"] = "戰鬥文字"
L["BACKGROUND_COLOR"] = "背景顏色"
L["BORDER_COLOR"] = "邊框顏色"
    
    -- 命令说明
    L["COMMANDS_TITLE"] = "指令說明:"
    L["CMD_TOGGLE"] = "/pw - 顯示/隱藏視窗"
    L["CMD_SHOW"] = "/pw show - 顯示視窗"
    L["CMD_HIDE"] = "/pw hide - 隱藏視窗"
    L["CMD_RESET"] = "/pw reset - 重置視窗位置"
    L["CMD_CLEAR"] = "/pw clear - 清除快取ID"
    L["CMD_HEX"] = "/pw hex - 切換到16進制"
    L["CMD_DEC"] = "/pw dec - 切換到10進制"
    L["CMD_LOCK"] = "/pw lock - 切換視窗鎖定"
    L["CMD_CONFIG"] = "/pw config - 開啟設定面板"
    L["NOTE_TITLE"] = "注意:"
    L["NOTE_INSTANCE"] = "在副本或戰鬥中,由於API限制(Secret Values)可能無法獲取位面ID"
    L["NOTE_TARGET"] = "選取一個NPC或玩家以檢測其位面"
    
    -- 聊天消息
    L["WINDOW_RESET"] = "視窗位置已重置"
    L["CACHE_CLEARED"] = "已清除快取的位面ID"
    L["FORMAT_SWITCHED_HEX"] = "已切換到16進制顯示"
    L["FORMAT_SWITCHED_DEC"] = "已切換到10進制顯示"
    L["WINDOW_SHOWN"] = "視窗已顯示"
    L["WINDOW_HIDDEN"] = "視窗已隱藏"
    L["WINDOW_LOCKED"] = "視窗已鎖定"
    L["WINDOW_UNLOCKED"] = "視窗已解鎖"
    L["SETTINGS_SAVED"] = "設定已儲存"
    
    -- 错误消息
    L["ERROR_GUID_PARSE"] = "解析GUID獲取位面資訊失敗"
    L["ERROR_API_RESTRICTED"] = "API暫時受限 (Secret Value)"
    L["ERROR_NO_UNIT"] = "未找到有效的單位目標"
    
    -- 工具提示
    L["TOOLTIP_PHASE_ID"] = "目前位面ID"
    L["TOOLTIP_FORMAT"] = "格式:"
    L["TOOLTIP_DECIMAL"] = "十進制"
    L["TOOLTIP_HEXADECIMAL"] = "十六進制"
    L["TOOLTIP_SOURCE"] = "來源:"
    L["TOOLTIP_SOURCE_PLAYER"] = "玩家"
    L["TOOLTIP_SOURCE_TARGET"] = "目標"
    L["TOOLTIP_SOURCE_MOUSEOVER"] = "滑鼠指向"
    L["TOOLTIP_SOURCE_CACHED"] = "快取"
    L["TOOLTIP_RIGHT_CLICK"] = "右鍵點擊開啟選項"
end

-----------------------------
-- 导出本地化表
-----------------------------
-- 确保全局访问
_G["PhaseWatcher_Locale"] = L