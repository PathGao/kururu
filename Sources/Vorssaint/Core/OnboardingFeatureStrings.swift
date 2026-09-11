// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

struct OnboardingFeatureStrings {
    var monitor = "Uses the existing background sampler with five minutes of in-memory history. Chart visibility, alerts and fan control are unchanged."
    var fan = "Requires monitoring; selecting fan control also selects monitoring. Configure fan behavior in Settings."
    var vertical = "With no axis enabled, starts with vertical scrolling only."
    var mouseButtons = "Keeps existing button mappings. If the list is empty, configure buttons in Settings. Gestures stay off by default."
    var finder = "With no action enabled, starts with file cut and paste only; image paste stays off."
    var quit = "With neither protection enabled, protects Quit only; Close stays unchanged."
    var snippets = "With neither mode enabled, starts with the manual snippet library. Add snippets in Settings before using it."
    var dock = "With no click action enabled, starts with minimize only; Hide and Cycle stay unchanged."
    var appList = "An empty app list does nothing. Choose apps in this feature’s Settings."
    var onDemand = "Selecting a tool provides its entry point without starting an action. Existing automations still follow their saved settings."
    var capture = "Screenshots, recording, screen text and color picking. Screen content access is requested when capturing; recording asks for audio access only when needed. Native color picking needs no screen-recording permission."

    static func text(_ language: AppLanguage) -> Self {
        guard language == .zhHans else { return Self() }
        return Self(
            monitor: "沿用现有后台采样，保留最近五分钟内存历史。不更改图表显示、警报或风扇控制。",
            fan: "需要监控。选择风扇控制会同时选择监控，具体风扇行为在设置中配置。",
            vertical: "若尚未启用任一方向，默认仅开启垂直滚动反转。",
            mouseButtons: "保留已有按键映射。空列表需先到设置配置按键，默认不开启手势。",
            finder: "若尚未启用任何动作，默认仅开启文件剪切粘贴，不开启图片粘贴。",
            quit: "若两项保护都未启用，默认仅保护退出，不更改关闭保护。",
            snippets: "若两个模式都未启用，默认仅开启手动片段库，使用前需在设置添加片段。",
            dock: "若尚未启用点击动作，默认仅开启最小化，不更改隐藏或循环窗口。",
            appList: "空名单不会执行任何动作，请先到该功能的设置中选择 App。",
            onDemand: "勾选按需工具只提供入口，不主动执行动作。已有自动化仍按原设置运行。",
            capture: "截图、录屏、屏幕文字识别和取色。截取屏幕时才请求屏幕录制权限，录屏按需要请求音频权限。系统原生取色不需要屏幕录制权限。")
    }
}
