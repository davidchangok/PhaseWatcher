-----------------------------
-- PhaseWatcher 本地化系统
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
L["VERSION"] = "Version 1.3 - Fixed 12.0 Secret Value Issue"

-- UI 文本
L["PHASE_MONITORING"] = "Phase Monitor"
L["INITIALIZING"] = "Initializing..."
L["PHASE_ID"] = "Phase ID: %s"
L["NOT_DETECTED"] = "Not Detected (Need Target/NPC)"
L["INSTANCE_LIMITATION"] = "In instance, may not detect due to 12.0 API limitation"

-- 设置面板
L["SHOW_FRAME"] = "Show Phase Monitor Window"
L["USE_HEXADECIMAL"] = "Use Hexadecimal Format"
L["UPDATE_INTERVAL"] = "Update Interval: %.1f sec"
L["UPDATE_INTERVAL_LOW"] = "0.1 sec"
L["UPDATE_INTERVAL_HIGH"] = "2.0 sec"
L["RESET_POSITION"] = "Reset Window Position"
L["CLEAR_CACHE"] = "Clear Cached ID"

-- 命令说明
L["COMMANDS_TITLE"] = "Commands:"
L["CMD_TOGGLE"] = "/pw - Toggle window visibility"
L["CMD_RESET"] = "/pw reset - Reset window position"
L["CMD_CLEAR"] = "/pw clear - Clear cached ID"
L["CMD_HEX"] = "/pw hex - Switch to hexadecimal"
L["CMD_DEC"] = "/pw dec - Switch to decimal"
L["CMD_CONFIG"] = "/pw config - Open settings panel"
L["NOTE_TITLE"] = "Note:"
L["NOTE_INSTANCE"] = "In instances, phase ID may not be available due to 12.0 API limitations"

-- 聊天消息
L["WINDOW_RESET"] = "Window position has been reset"
L["CACHE_CLEARED"] = "Cached phase ID has been cleared"
L["FORMAT_SWITCHED_HEX"] = "Switched to hexadecimal display"
L["FORMAT_SWITCHED_DEC"] = "Switched to decimal display"
L["WINDOW_SHOWN"] = "Window shown"
L["WINDOW_HIDDEN"] = "Window hidden"

-- 错误消息
L["ERROR_NO_PHASETEXT"] = "Cannot find PhaseText control, please check XML name attribute."

-----------------------------
-- 简体中文 (zhCN)
-----------------------------
if locale == "zhCN" then
    L["ADDON_LOADED"] = "已加载 - 输入 %s 打开设置"
    L["ADDON_NAME"] = "位面|cFFFFFFFF监测|r"
    L["VERSION"] = "版本 1.3 - 修复12.0 Secret Value问题"
    
    -- UI 文本
    L["PHASE_MONITORING"] = "位面监测"
    L["INITIALIZING"] = "初始化..."
    L["PHASE_ID"] = "位面ID: %s"
    L["NOT_DETECTED"] = "未获取 (需目标/NPC)"
    L["INSTANCE_LIMITATION"] = "在副本中，由于12.0 API限制可能无法检测"
    
    -- 设置面板
    L["SHOW_FRAME"] = "显示位面监测窗口"
    L["USE_HEXADECIMAL"] = "使用16进制显示"
    L["UPDATE_INTERVAL"] = "更新间隔: %.1f 秒"
    L["UPDATE_INTERVAL_LOW"] = "0.1秒"
    L["UPDATE_INTERVAL_HIGH"] = "2.0秒"
    L["RESET_POSITION"] = "重置窗口位置"
    L["CLEAR_CACHE"] = "清除缓存ID"
    
    -- 命令说明
    L["COMMANDS_TITLE"] = "命令说明:"
    L["CMD_TOGGLE"] = "/pw - 显示/隐藏窗口"
    L["CMD_RESET"] = "/pw reset - 重置窗口位置"
    L["CMD_CLEAR"] = "/pw clear - 清除缓存ID"
    L["CMD_HEX"] = "/pw hex - 切换到16进制"
    L["CMD_DEC"] = "/pw dec - 切换到10进制"
    L["CMD_CONFIG"] = "/pw config - 打开设置面板"
    L["NOTE_TITLE"] = "注意:"
    L["NOTE_INSTANCE"] = "在副本中由于12.0 API限制，某些情况下可能无法获取位面ID"
    
    -- 聊天消息
    L["WINDOW_RESET"] = "窗口位置已重置"
    L["CACHE_CLEARED"] = "已清除缓存的位面ID"
    L["FORMAT_SWITCHED_HEX"] = "切换到16进制显示"
    L["FORMAT_SWITCHED_DEC"] = "切换到10进制显示"
    L["WINDOW_SHOWN"] = "窗口已显示"
    L["WINDOW_HIDDEN"] = "窗口已隐藏"
    
    -- 错误消息
    L["ERROR_NO_PHASETEXT"] = "无法找到 PhaseText 控件,请检查 XML name 属性。"
end

-----------------------------
-- 繁体中文 (zhTW)
-----------------------------
if locale == "zhTW" then
    L["ADDON_LOADED"] = "已載入 - 輸入 %s 開啟設定"
    L["ADDON_NAME"] = "位面|cFFFFFFFF監測|r"
    L["VERSION"] = "版本 1.3 - 修復12.0 Secret Value問題"
    
    -- UI 文本
    L["PHASE_MONITORING"] = "位面監測"
    L["INITIALIZING"] = "初始化..."
    L["PHASE_ID"] = "位面ID: %s"
    L["NOT_DETECTED"] = "未獲取 (需目標/NPC)"
    L["INSTANCE_LIMITATION"] = "在副本中，由於12.0 API限制可能無法檢測"
    
    -- 设置面板
    L["SHOW_FRAME"] = "顯示位面監測視窗"
    L["USE_HEXADECIMAL"] = "使用16進制顯示"
    L["UPDATE_INTERVAL"] = "更新間隔: %.1f 秒"
    L["UPDATE_INTERVAL_LOW"] = "0.1秒"
    L["UPDATE_INTERVAL_HIGH"] = "2.0秒"
    L["RESET_POSITION"] = "重置視窗位置"
    L["CLEAR_CACHE"] = "清除快取ID"
    
    -- 命令说明
    L["COMMANDS_TITLE"] = "指令說明:"
    L["CMD_TOGGLE"] = "/pw - 顯示/隱藏視窗"
    L["CMD_RESET"] = "/pw reset - 重置視窗位置"
    L["CMD_CLEAR"] = "/pw clear - 清除快取ID"
    L["CMD_HEX"] = "/pw hex - 切換到16進制"
    L["CMD_DEC"] = "/pw dec - 切換到10進制"
    L["CMD_CONFIG"] = "/pw config - 開啟設定面板"
    L["NOTE_TITLE"] = "注意:"
    L["NOTE_INSTANCE"] = "在副本中由於12.0 API限制，某些情況下可能無法獲取位面ID"
    
    -- 聊天消息
    L["WINDOW_RESET"] = "視窗位置已重置"
    L["CACHE_CLEARED"] = "已清除快取的位面ID"
    L["FORMAT_SWITCHED_HEX"] = "切換到16進制顯示"
    L["FORMAT_SWITCHED_DEC"] = "切換到10進制顯示"
    L["WINDOW_SHOWN"] = "視窗已顯示"
    L["WINDOW_HIDDEN"] = "視窗已隱藏"
    
    -- 错误消息
    L["ERROR_NO_PHASETEXT"] = "無法找到 PhaseText 控件,請檢查 XML name 屬性。"
end

-----------------------------
-- 导出本地化表
-----------------------------
-- 确保 PhaseWatcher 表存在
PhaseWatcher = PhaseWatcher or {}
PhaseWatcher.L = L