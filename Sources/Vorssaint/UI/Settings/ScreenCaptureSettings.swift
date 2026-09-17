// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import SwiftUI

/// Every capture tool starts from the same overlay, where 1–4 switch between
/// them, so the page follows that flow instead of separating the tools:
/// shortcuts that open the overlay, what happens while selecting, then each
/// tool's result.
struct ScreenCaptureSettings: View {
    @ObservedObject private var l10n = L10n.shared
    @ObservedObject private var features = FeatureRuntime.shared
    @ObservedObject private var permissions = Permissions.shared

    private var availableTools: [ScreenCaptureTool] {
        ScreenCaptureTool.available()
    }

    var body: some View {
        let entry = UXEntryStrings(l10n.language)
        SettingsForm {
            if !availableTools.isEmpty {
                SettingsSection(title: entry.captureShortcuts, systemImage: "keyboard") {
                    if !permissions.screenRecording {
                        PermissionRow(kind: .screenRecording)
                    }
                    ForEach(availableTools, id: \.self) { tool in
                        ToolShortcutRows(tool: tool, keys: tool.dedicatedShortcut)
                        if tool == .screenshot {
                            ScreenshotExtraShortcutRows()
                        }
                    }
                    if AppFeature.screenshot.isAvailable || AppFeature.screenRecorder.isAvailable {
                        RecentCapturesShortcutRows()
                    }
                }

                SettingsSection(title: entry.captureSelection, systemImage: "viewfinder") {
                    CaptureSelectionRows(tools: availableTools)
                }
            }
            if AppFeature.screenshot.isAvailable {
                ScreenshotCaptureSettings()
            }
            if AppFeature.screenRecorder.isAvailable {
                ScreenRecordingCaptureSettings()
            }
            if AppFeature.screenOCR.isAvailable {
                ScreenTextCaptureSettings()
            }
            if AppFeature.colorPicker.isAvailable {
                ColorCaptureSettings()
            }
        }
        .formStyle(.grouped)
    }
}

/// Capture history belongs to screenshots and recordings together, so its
/// shortcut stays visible whichever of those tools is selected.
private struct RecentCapturesShortcutRows: View {
    @ObservedObject private var l10n = L10n.shared
    @ObservedObject private var service = RecentCaptureService.shared
    @AppStorage(DefaultsKey.recentCapturesShortcutEnabled) private var enabled = false

    var body: some View {
        let role = GlobalShortcutRole.recentCaptures
        Toggle(role.title(l10n.s), isOn: $enabled)
            .onChange(of: enabled) { _, _ in
                service.syncWithPreferences()
            }
        ShortcutPreferenceRow(role: role, isEnabled: enabled) {
            service.syncWithPreferences()
        }
        if enabled, service.shortcutRegistrationFailed {
            Text(l10n.s.shortcutUnavailable)
                .font(SettingsTypography.caption)
                .foregroundStyle(.orange)
        }
    }
}

/// The shortcut that opens the overlay straight on one tool.
private struct ToolShortcutRows: View {
    @ObservedObject private var l10n = L10n.shared
    @ObservedObject private var service = ScreenCaptureService.shared
    @AppStorage private var enabled: Bool
    @AppStorage private var showsCaptureMenu: Bool

    private let tool: ScreenCaptureTool
    private let keys: ScreenCaptureTool.DedicatedShortcut

    init(tool: ScreenCaptureTool, keys: ScreenCaptureTool.DedicatedShortcut) {
        self.tool = tool
        self.keys = keys
        _enabled = AppStorage(wrappedValue: false, keys.enabledKey)
        _showsCaptureMenu = AppStorage(wrappedValue: true, tool.showCaptureMenuOnShortcutKey)
    }

    var body: some View {
        Toggle(keys.role.title(l10n.s), isOn: $enabled)
            .onChange(of: enabled) { _, _ in
                service.syncWithPreferences()
            }
        ShortcutPreferenceRow(role: keys.role, isEnabled: enabled) {
            service.syncWithPreferences()
        }
        Toggle(FeatureStrings.screenshot(l10n.language).showCaptureMenuOnShortcut,
               isOn: $showsCaptureMenu)
            .disabled(!enabled)
        if enabled, service.toolShortcutRegistrationFailures.contains(tool) {
            Text(l10n.s.shortcutUnavailable)
                .font(SettingsTypography.caption)
                .foregroundStyle(.orange)
        }
    }
}

private struct ScreenTextCaptureSettings: View {
    @ObservedObject private var l10n = L10n.shared
    @AppStorage(DefaultsKey.screenOCRRemoveLineBreaks) private var removesLineBreaks = false
    @AppStorage(DefaultsKey.screenOCRDetectQRCodes) private var detectsQRCodes = true

    var body: some View {
        SettingsSection(title: AppFeature.screenOCR.name(l10n.s, language: l10n.language),
                        systemImage: "text.viewfinder") {
            SettingsToggleWithCaption(title: l10n.s.ocrRemoveLineBreaksToggle,
                                      caption: l10n.s.ocrRemoveLineBreaksCaption,
                                      isOn: $removesLineBreaks)
            SettingsToggleWithCaption(title: l10n.s.ocrQRToggle,
                                      caption: l10n.s.ocrQRCaption,
                                      isOn: $detectsQRCodes)
        }
        .settingsSectionAnchor(.screenOCR)
    }
}

private struct ColorCaptureSettings: View {
    @ObservedObject private var l10n = L10n.shared
    @AppStorage(DefaultsKey.colorPickerFormat) private var format = "hex"
    @AppStorage(DefaultsKey.colorPickerBareHex) private var usesBareHex = false

    var body: some View {
        SettingsSection(title: AppFeature.colorPicker.name(l10n.s, language: l10n.language),
                        systemImage: "eyedropper") {
            Picker(l10n.s.colorPickerFormatLabel, selection: $format) {
                ForEach(ColorCopyFormat.allCases) { format in
                    Text(format.label).tag(format.rawValue)
                }
            }
            .pickerStyle(.segmented)
            if format == ColorCopyFormat.hex.rawValue {
                Toggle(l10n.s.colorPickerBareHexToggle, isOn: $usesBareHex)
            }
        }
        .settingsSectionAnchor(.colorPicker)
    }
}
