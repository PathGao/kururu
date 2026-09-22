// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import Foundation

/// English is the default for every field; a language that has no wording
/// for one falls back to it, so a partial translation stays usable.
struct WindowLayoutFeatureStrings {
    var title: String = "Window layout"
    var caption: String = "Arrange windows into screen sections or move and resize them with a trackpad or mouse."
    var showInPanel: String = "Show in panel"
    var gestureSection: String = "Window dragging"
    var gestureEnable: String = "Move and resize by dragging"
    var gestureCaption: String = "On a trackpad or mouse, hold the shown modifier keys and drag anywhere inside a window."
    var gestureModifiers: String = "Keys to move"
    var gestureMove: String = "Drag to move"
    var gestureResize: String = "Add Shift and drag to resize"
    var gestureResizeHint: String = "The starting point chooses the nearest edge or corner. On a mouse, right-button drag also resizes."
    var gestureRaiseWindow: String = "Bring the dragged window to front"
    var shortcuts: String = "Shortcuts"
    var shortcutsCaption: String = "Use global shortcuts to arrange the active window without opening the panel."
    var permissionCaption: String = "Uses Accessibility only to move and resize windows."
    var noWindow: String = "No active window found."
    var missingPermission: String = "Grant Accessibility to move windows."
    var failed: String = "Could not move this window."
    var done: String = "Window arranged."
    var restored: String = "Window restored."
    var noRestore: String = "No previous layout to restore."
    var target: String = "Active window"
    var halves: String = "Halves"
    var thirds: String = "Thirds"
    var sixths: String = "Sixths"
    var corners: String = "Corners"
    var other: String = "Actions"
    var leftHalf: String = "Left"
    var rightHalf: String = "Right"
    var topHalf: String = "Top"
    var bottomHalf: String = "Bottom"
    var centerHalf: String = "Center half"
    var leftThird: String = "Left 1/3"
    var centerThird: String = "Center 1/3"
    var rightThird: String = "Right 1/3"
    var leftTwoThirds: String = "Left 2/3"
    var rightTwoThirds: String = "Right 2/3"
    var centerTwoThirds: String = "Center 2/3"
    var topLeftSixth: String = "Top left 1/6"
    var topCenterSixth: String = "Top center 1/6"
    var topRightSixth: String = "Top right 1/6"
    var bottomLeftSixth: String = "Bottom left 1/6"
    var bottomCenterSixth: String = "Bottom center 1/6"
    var bottomRightSixth: String = "Bottom right 1/6"
    var topLeft: String = "Top left"
    var topRight: String = "Top right"
    var bottomLeft: String = "Bottom left"
    var bottomRight: String = "Bottom right"
    var maximize: String = "Maximize"
    var center: String = "Center"
    var nextDisplay: String = "Next display"
    var restore: String = "Restore"
    var fullScreen: String = "Full Screen"
    var previousDisplay: String = "Previous display"
    var edgeSnapEnable: String = "Snap windows at screen edges"
    var edgeSnapCaption: String = "Turn this on, choose the highlighted areas below, then drag a window title bar to one and release."
    var edgeSnapSystemConflict: String = "macOS is using the same edges. Turn off window tiling in Desktop & Dock so Vorssaint can take over."
    var edgeSnapOpenSystemSettings: String = "Open Desktop & Dock"
    var edgeSnapWaitingForSystem: String = "Enabled in Vorssaint. It starts working as soon as macOS tiling is off."
    var marginMaximize: String = "Maximize with Margin"
    var gapsSection: String = "Gaps"
    var gapsCaption: String = "Space between snapped windows, and between windows and the screen edge."
    var windowGap: String = "Window gap"
    var screenGap: String = "Screen gap"
    var gapNone: String = "None"
    var gapTiny: String = "Tiny"
    var gapSmall: String = "Small"
    var gapMedium: String = "Medium"
    var gapLarge: String = "Large"
    var gapExtraLarge: String = "Extra large"
}

extension FeatureStrings {
    static func windowLayout(_ language: AppLanguage) -> WindowLayoutFeatureStrings {
        language == .zhHans ? .zhHans : WindowLayoutFeatureStrings()
    }
}

extension WindowLayoutFeatureStrings {
    static let zhHans = WindowLayoutFeatureStrings(
        title: "窗口布局",
        caption: "将窗口排列到屏幕区域，或用触控板或鼠标移动和调整大小。",
        showInPanel: "在面板中显示",
        gestureSection: "窗口拖动",
        gestureEnable: "拖动以移动和调整大小",
        gestureCaption: "在触控板或鼠标上按住显示的修饰键，从窗口内任意位置拖动。",
        gestureModifiers: "移动按键",
        gestureMove: "拖动以移动",
        gestureResize: "加按 Shift 并拖动以调整大小",
        gestureResizeHint: "起点决定最近的边缘或角落。使用鼠标时，按住右键拖动也可调整大小。",
        gestureRaiseWindow: "将拖动的窗口置于最前",
        shortcuts: "快捷键",
        shortcutsCaption: "使用全局快捷键整理当前窗口，无需打开面板。",
        permissionCaption: "辅助功能权限仅用于移动窗口和调整窗口大小。",
        noWindow: "未找到当前窗口。",
        missingPermission: "请授予辅助功能权限以移动窗口。",
        failed: "无法移动此窗口。",
        done: "窗口已整理。",
        restored: "窗口已恢复。",
        noRestore: "没有可恢复的上一个布局。",
        target: "当前窗口",
        halves: "半屏",
        thirds: "三分屏",
        sixths: "六分屏",
        corners: "角落",
        other: "操作",
        leftHalf: "左半屏",
        rightHalf: "右半屏",
        topHalf: "上半屏",
        bottomHalf: "下半屏",
        centerHalf: "居中半屏",
        leftThird: "左侧 1/3",
        centerThird: "中间 1/3",
        rightThird: "右侧 1/3",
        leftTwoThirds: "左侧 2/3",
        rightTwoThirds: "右侧 2/3",
        centerTwoThirds: "居中 2/3",
        topLeftSixth: "左上 1/6",
        topCenterSixth: "上中 1/6",
        topRightSixth: "右上 1/6",
        bottomLeftSixth: "左下 1/6",
        bottomCenterSixth: "下中 1/6",
        bottomRightSixth: "右下 1/6",
        topLeft: "左上角",
        topRight: "右上角",
        bottomLeft: "左下角",
        bottomRight: "右下角",
        maximize: "最大化",
        center: "居中",
        nextDisplay: "下一台显示器",
        restore: "恢复",
        fullScreen: "全屏幕",
        previousDisplay: "上一台显示器",
        edgeSnapEnable: "将窗口贴靠到屏幕边缘",
        edgeSnapCaption: "开启后，在下方选择要使用的高亮区域，再将窗口标题栏拖到其中一个区域。",
        edgeSnapSystemConflict: "macOS 正在使用相同的屏幕边缘。请在“桌面与程序坞”中关闭窗口平铺，让 Vorssaint 接管。",
        edgeSnapOpenSystemSettings: "打开桌面与程序坞",
        edgeSnapWaitingForSystem: "已在 Vorssaint 中开启。关闭 macOS 窗口平铺后即可使用。",
        marginMaximize: "带边距最大化",
        gapsSection: "间距",
        gapsCaption: "贴靠窗口之间以及窗口与屏幕边缘之间的间距。",
        windowGap: "窗口间距",
        screenGap: "屏幕边距",
        gapNone: "无",
        gapTiny: "极小",
        gapSmall: "小",
        gapMedium: "中",
        gapLarge: "大",
        gapExtraLarge: "特大"
    )
}
