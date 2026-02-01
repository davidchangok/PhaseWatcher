# PhaseWatcher

![Author](https://img.shields.io/badge/Author-David%20W%20Zhang-orange) ![Version](https://img.shields.io/badge/Version-v2.0.0-blue) [![GitHub](https://img.shields.io/badge/GitHub-Repo-181717?logo=github)](https://github.com/davidchangok/PhaseWatcher)

**PhaseWatcher** is a lightweight World of Warcraft addon designed to track and display Phase IDs, ZoneUIDs, and NPC GUID information. It provides essential phasing data to help players and developers verify if they are in the same shard or layer as their target.

## 🌟 Features

*   **Phase & GUID Tracking**: Real-time monitoring of NPC and Player Phase IDs.
*   **Modern API Support**: Built for WoW 11.0 (The War Within) and 12.0+, utilizing `MenuUtil` and the native `Settings` API to eliminate taint.
*   **Accurate Parsing**: Correctly interprets decimal ZoneUIDs and handles protected "Secret Values" in instances.
*   **Customizable UI**: Full control over fonts, colors, window styles (Blizzard/Flat/Tooltip), and transparency.
*   **Visual Indicators**: Color-coded status for Player (Green), Target (Teal), Cached (Grey), and Secret/Hidden (Orange) sources.

## 📋 Changelog

### v2.0.0 - Major Update: Architecture Refactor & 12.0 API Support

This update is a complete rewrite to fully support World of Warcraft 11.0+ (The War Within) and upcoming 12.0 API changes, addressing previous API taint issues and parsing errors.

#### 🌟 Highlights
*   **Full 11.0+ / 12.0 API Support**:
    *   Replaced deprecated `UIDropDownMenu` with the native `MenuUtil` for context menus, eliminating UI Taint issues during combat.
    *   Updated to the new Settings API (`Settings` Category) for full compatibility with the modern UI.
*   **Architecture Refactor (Pure Lua)**:
    *   Removed XML dependencies in favor of Pure Lua UI construction for better stability.
    *   Modularized code structure (`Core`, `UI`, `Localization`) for cleaner logic.

#### 🐛 Fixes & Optimizations
*   **Critical Fix for Secret Values**: Implemented strict protection against "Secret Values" (hidden GUIDs in instances/raids) to prevent addon crashes in restricted environments.
*   **GUID Parsing Fix**: Corrected the logic for parsing NPC Phase IDs. It now correctly interprets the decimal ZoneUID from the GUID, fixing previous inaccuracies.
*   **Performance**: Optimized settings sliders to prevent excessive updates while dragging.

#### ✨ New Features
*   **Enhanced Appearance Settings**:
    *   Added options to customize **Font** (System/Chat/Combat), **Font Size**, **Window Style** (Blizzard Dialog/Tooltip/Flat/None), **Transparency**, **Background Color**, and **Border Color**.
    *   Settings panel now uses Radio Buttons for easier selection.
*   **Visual Improvements**:
    *   Color-coded sources: <span style="color:green">Green (Player)</span>, <span style="color:teal">Teal (Target/Mouseover)</span>, <span style="color:gray">Grey (Cached)</span>, <span style="color:orange">Orange (Secret/Hidden)</span>.
    *   Added drag hints and detailed tooltips.

---

# PhaseWatcher (位面监视器)

**PhaseWatcher** 是一款专为魔兽世界设计的轻量级插件，用于追踪和显示位面 ID (Phase ID)、区域 UID (ZoneUID) 以及 NPC GUID 信息。它能帮助玩家和开发者确认当前位面状态，确保你与目标处于同一镜像或分层中。

## 🌟 功能特性

*   **位面与 GUID 追踪**：实时监控并显示 NPC 和玩家的位面 ID。
*   **现代 API 支持**：完美适配 WoW 11.0 (地心之战) 及 12.0+，使用 `MenuUtil` 和原生 `Settings` API，彻底解决 Taint 问题。
*   **精准解析**：正确解析 GUID 中的十进制 ZoneUID，并严格保护副本中的 "Secret Values" (隐藏 GUID)。
*   **高度可定制**：完全自定义字体、大小、窗口风格 (暴雪/扁平/提示框) 以及透明度。
*   **视觉指示**：清晰的颜色编码状态 —— 绿色(玩家)、青色(目标)、灰色(缓存)、橙色(受限/隐藏)。

## 📋 更新日志

### v2.0.0 - 核心变动：架构重构与 12.0 API 适配

本次更新是对插件的全面重写，旨在完美支持魔兽世界 11.0+ (地心之战) 及未来的 12.0 版本，并解决了旧版本存在的 API 污染和解析错误问题。

#### 🌟 主要更新
*   **全面适配 11.0+ / 12.0 API**：
    *   移除了过时的 `UIDropDownMenu`，改用原生 `MenuUtil` 构建右键菜单，彻底解决了战斗中可能出现的 UI 污染 (Taint) 问题。
    *   适配了新的设置面板 API (`Settings` Category)，确保配置界面在最新客户端中正常工作。
*   **架构重构 (Pure Lua)**：
    *   移除了 XML 依赖，采用纯 Lua 构建 UI，提升了加载稳定性和维护性。
    *   模块化拆分 (`Core`, `UI`, `Localization`)，代码逻辑更清晰。

#### 🐛 修复与优化
*   **Secret Value 崩溃修复**：针对副本/团本中的 "Secret Values" (隐藏 GUID) 实施了最严格的保护措施，防止插件在受限环境下因尝试读取受保护数据而崩溃。
*   **GUID 解析修正**：修复了 NPC 位面 ID 解析逻辑。现在能正确识别 GUID 中的十进制区域 ID，不再错误地将其作为十六进制处理，大幅提高了检测准确率。
*   **性能优化**：优化了设置面板滑块的响应逻辑，避免在拖动时频繁触发后台更新。

#### ✨ 新增功能
*   **增强的外观设置**：
    *   新增自定义 **字体** (系统/聊天/战斗)、**字体大小**、**窗口风格** (暴雪对话框/提示框/扁平/无背景)、**透明度**、**背景颜色** 和 **边框颜色** 的选项。
    *   设置面板现在使用单选按钮 (Radio Buttons) 进行更直观的选择。
*   **状态指示优化**：
    *   新增颜色编码：<span style="color:green">绿色(玩家)</span>、<span style="color:teal">青色(目标/鼠标)</span>、<span style="color:gray">灰色(缓存)</span>、<span style="color:orange">橙色(受限)</span>。
    *   新增拖拽提示和详细的鼠标悬停 Tooltip。