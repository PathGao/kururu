// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import SwiftUI

/// Screenshot-specific sections inside the shared screen-capture page.
struct ScreenshotCaptureSettings: View {
    @ObservedObject private var l10n = L10n.shared
    @ObservedObject private var permissions = Permissions.shared
    @ObservedObject private var service = ScreenshotService.shared
    @AppStorage(DefaultsKey.screenshotFullScreenShortcutEnabled)
    private var fullScreenShortcutEnabled = false
    @AppStorage(DefaultsKey.screenshotLastCaptureShortcutEnabled)
    private var lastCaptureShortcutEnabled = false
    @AppStorage(DefaultsKey.screenshotClipboardShortcutEnabled)
    private var clipboardShortcutEnabled = false
    @AppStorage(DefaultsKey.screenshotFreeze) private var freeze = true
    @AppStorage(DefaultsKey.screenshotHideVorssaintWindows) private var hideVorssaintWindows = true
    @AppStorage(DefaultsKey.screenshotSaveFolder) private var saveFolder = ""
    @AppStorage(DefaultsKey.screenshotSaveSubfolder) private var saveSubfolder = ""
    @AppStorage(DefaultsKey.screenshotFileNamePattern) private var fileNamePattern = ""
    @AppStorage(DefaultsKey.screenshotFileNumberStart) private var numberStart = 1
    @AppStorage(DefaultsKey.screenshotFileNumberNext) private var nextNumber = 1
    @AppStorage(DefaultsKey.screenshotIncludePointer) private var includePointer = false
    @AppStorage(DefaultsKey.screenshotShowLastRegion) private var showLastRegion = true
    @AppStorage(DefaultsKey.screenshotLoupeStartsOn) private var loupeStartsOn = false
    @AppStorage(DefaultsKey.screenshotLoupeRememberZoom) private var rememberLoupeZoom = false
    @AppStorage(DefaultsKey.screenshotLoupeDefaultZoom) private var loupeDefaultZoom = 1.0
    @AppStorage(DefaultsKey.screenshotLoupeSteppedZoomByDefault)
    private var steppedLoupeZoomByDefault = false
    @AppStorage(DefaultsKey.screenshotDownscale) private var downscale = false
    @AppStorage(DefaultsKey.screenshotDelay) private var delay = 0
    @AppStorage(DefaultsKey.screenshotDefaultAction) private var defaultActionRaw = ""
    @AppStorage(DefaultsKey.screenshotToolOrder) private var toolOrderRaw =
        ScreenshotSupport.Tool.defaultOrderStorage
    @AppStorage(DefaultsKey.screenshotToolShortcutsEnabled) private var toolShortcutsEnabled = true
    @AppStorage(DefaultsKey.screenshotCopyToClipboard) private var copyToClipboard = false
    @AppStorage(DefaultsKey.screenshotPreviewPosition) private var previewPositionRaw = ""

    private var strings: ScreenshotFeatureStrings {
        FeatureStrings.screenshot(l10n.language)
    }

    var body: some View {
        Group {
            SettingsSection(title: AppFeature.screenshot.name(l10n.s, language: l10n.language),
                            systemImage: "camera.viewfinder") {
                HStack(spacing: 10) {
                    Button {
                        ScreenshotService.shared.capture()
                    } label: {
                        Label(strings.captureButton, systemImage: "camera.viewfinder")
                            .frame(maxWidth: .infinity)
                    }
                    .settingsAction(.primary)
                    Button {
                        ScreenshotService.shared.captureScrolling()
                    } label: {
                        Label(strings.scrollingCaptureButton, systemImage: "rectangle.stack")
                            .frame(maxWidth: .infinity)
                    }
                }
                .controlSize(.large)
                SettingsInfo(text: strings.panelCaption, systemImage: "camera.viewfinder")
                Divider()
                Toggle(strings.fullScreenShortcutTitle, isOn: $fullScreenShortcutEnabled)
                    .onChange(of: fullScreenShortcutEnabled) { _, _ in
                        ScreenshotService.shared.syncWithPreferences()
                    }
                ShortcutPreferenceRow(role: .screenshotFullScreen,
                                      isEnabled: fullScreenShortcutEnabled) {
                    ScreenshotService.shared.syncWithPreferences()
                }
                if fullScreenShortcutEnabled, service.fullScreenShortcutRegistrationFailed {
                    Text(l10n.s.shortcutUnavailable)
                        .font(SettingsTypography.caption)
                        .foregroundStyle(.orange)
                }
                Toggle(strings.editLastCapture, isOn: $lastCaptureShortcutEnabled)
                    .onChange(of: lastCaptureShortcutEnabled) { _, _ in
                        ScreenshotService.shared.syncWithPreferences()
                    }
                ShortcutPreferenceRow(role: .screenshotLastCapture,
                                      isEnabled: lastCaptureShortcutEnabled) {
                    ScreenshotService.shared.syncWithPreferences()
                }
                if lastCaptureShortcutEnabled,
                   service.lastCaptureShortcutRegistrationFailed {
                    Text(l10n.s.shortcutUnavailable)
                        .font(SettingsTypography.caption)
                        .foregroundStyle(.orange)
                }
                Toggle(strings.editClipboardImage, isOn: $clipboardShortcutEnabled)
                    .onChange(of: clipboardShortcutEnabled) { _, _ in
                        ScreenshotService.shared.syncWithPreferences()
                    }
                ShortcutPreferenceRow(role: .screenshotClipboard,
                                      isEnabled: clipboardShortcutEnabled) {
                    ScreenshotService.shared.syncWithPreferences()
                }
                if clipboardShortcutEnabled, service.clipboardShortcutRegistrationFailed {
                    Text(l10n.s.shortcutUnavailable)
                        .font(SettingsTypography.caption)
                        .foregroundStyle(.orange)
                }
                if !permissions.screenRecording {
                    PermissionRow(kind: .screenRecording)
                }
            }
            .settingsSectionAnchor(.screenshot)

            SettingsSection(title: UXEntryStrings(l10n.language).captureOptions, systemImage: "viewfinder") {
                SettingsToggleWithCaption(title: strings.freezeToggle,
                                          caption: strings.freezeCaption, isOn: $freeze)
                Toggle(strings.hideVorssaintWindowsToggle, isOn: $hideVorssaintWindows)
                SettingsControlRow(title: strings.delayLabel, systemImage: "timer") {
                    Picker(strings.delayLabel, selection: $delay) {
                        ForEach(ScreenshotSupport.allowedDelays, id: \.self) { seconds in
                            if seconds == 0 {
                                Text(strings.delayOff).tag(0)
                            } else {
                                Text(String(format: strings.delaySecondsFormat, seconds)).tag(seconds)
                            }
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                }
                Divider()
                Toggle(strings.pointerToggle, isOn: $includePointer)
                Toggle(strings.lastRegionToggle, isOn: $showLastRegion)
                previewPositionRow
                DisclosureGroup {
                    Toggle(strings.loupeStartsOnToggle, isOn: $loupeStartsOn)
                    Toggle(strings.loupeRememberZoomToggle, isOn: $rememberLoupeZoom)
                    if !rememberLoupeZoom {
                        Picker(strings.loupeDefaultZoomLabel, selection: $loupeDefaultZoom) {
                            ForEach(ScreenshotSupport.captureLoupeDefaultZooms, id: \.self) { zoom in
                                Text(zoom.formatted(
                                    .number.precision(.fractionLength(0...1))) + "×")
                                    .tag(zoom)
                            }
                        }
                    }
                    Picker(strings.loupeWheelZoomLabel,
                           selection: $steppedLoupeZoomByDefault) {
                        Text(strings.loupeZoomFast).tag(false)
                        Text(strings.loupeZoomStepped).tag(true)
                    }
                    .pickerStyle(.segmented)
                    Text(strings.loupeZoomOptionCaption)
                        .font(SettingsTypography.caption)
                        .foregroundStyle(.secondary)
                } label: {
                    Label(FeatureStrings.recorder(l10n.language).moreOptions,
                          systemImage: "slider.horizontal.3")
                }
            }

            SettingsSection(title: UXEntryStrings(l10n.language).outputSettings, systemImage: "square.and.arrow.down") {
                defaultActionRow
                SettingsToggleWithCaption(title: strings.autoCopyToggle,
                                          caption: strings.autoCopyCaption, isOn: $copyToClipboard)
                Divider()
                folderRow
                subfolderRow
                fileNameRow
                SettingsToggleWithCaption(title: strings.downscaleToggle,
                                          caption: strings.downscaleCaption, isOn: $downscale)
            }

            SettingsSection(title: strings.toolShortcutsTitle, systemImage: "slider.horizontal.3") {
                ScreenshotToolOrderControls(orderRaw: $toolOrderRaw,
                                            shortcutsEnabled: $toolShortcutsEnabled,
                                            showsTitle: false)
            }

        }
    }

    private var defaultActionRow: some View {
        SettingsControlRow(title: strings.defaultActionLabel, systemImage: "checkmark.circle",
                           caption: strings.defaultActionCaption) {
            Picker(strings.defaultActionLabel, selection: $defaultActionRaw) {
                Text(strings.defaultActionNone).tag(ScreenshotDefaultAction.none.rawValue)
                Text(strings.saveButton).tag(ScreenshotDefaultAction.save.rawValue)
                Text(strings.defaultActionSaveAndCopy).tag(ScreenshotDefaultAction.saveAndCopy.rawValue)
                Text(strings.copyButton).tag(ScreenshotDefaultAction.copy.rawValue)
                Text(strings.editButton).tag(ScreenshotDefaultAction.edit.rawValue)
            }
            .labelsHidden()
        }
    }

    private var previewPositionRow: some View {
        SettingsControlRow(title: strings.previewPositionLabel, systemImage: "rectangle.inset.filled") {
            Picker(strings.previewPositionLabel, selection: $previewPositionRaw) {
                Text(strings.previewPositionAutomatic)
                    .tag(ScreenshotSupport.QuickPreviewPosition.automatic.rawValue)
                Text(strings.previewPositionTopLeft)
                    .tag(ScreenshotSupport.QuickPreviewPosition.topLeft.rawValue)
                Text(strings.previewPositionTopRight)
                    .tag(ScreenshotSupport.QuickPreviewPosition.topRight.rawValue)
                Text(strings.previewPositionBottomLeft)
                    .tag(ScreenshotSupport.QuickPreviewPosition.bottomLeft.rawValue)
                Text(strings.previewPositionBottomRight)
                    .tag(ScreenshotSupport.QuickPreviewPosition.bottomRight.rawValue)
            }
            .labelsHidden()
        }
    }

    private var folderRow: some View {
        SettingsControlRow(title: strings.folderLabel, systemImage: "folder") {
            Text(currentFolderName)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)
            if !saveFolder.isEmpty {
                Button {
                    saveFolder = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.tertiary)
                }
                .buttonStyle(.borderless)
                .screenshotSafeHelp(l10n.s.shortcutReset)
                .accessibilityLabel(l10n.s.shortcutReset)
            }
            Button {
                chooseFolder()
            } label: {
                Label(strings.folderChoose, systemImage: "folder.badge.plus")
            }
        }
    }

    private var subfolderRow: some View {
        SettingsControlRow(title: strings.subfolderLabel, systemImage: "folder.badge.gearshape",
                           help: strings.subfolderCaption) {
            VStack(alignment: .leading, spacing: 4) {
                TextField(strings.subfolderLabel, text: $saveSubfolder)
                    .labelsHidden()
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 220)
                if !saveSubfolder.isEmpty {
                    Text(ScreenshotSupport.expandSaveSubfolder(saveSubfolder, date: Date()))
                        .font(SettingsTypography.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .frame(width: 220, alignment: .leading)
                }
            }
        }
    }

    private var fileNameRow: some View {
        VStack(alignment: .leading, spacing: 12) {
            SettingsControlRow(title: strings.fileNamePatternLabel, systemImage: "doc.text",
                               help: strings.fileNamePatternCaption) {
                VStack(alignment: .leading, spacing: 4) {
                    TextField(strings.fileNamePatternLabel, text: $fileNamePattern)
                        .labelsHidden()
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 220)
                    Text(fileNamePreview)
                        .font(SettingsTypography.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .frame(width: 220, alignment: .leading)
                }
            }
            if ScreenshotSupport.fileNamePatternUsesNumber(fileNamePattern) {
                SettingsControlRow(title: strings.fileNumberStartLabel, systemImage: "number",
                                   caption: String(format: strings.fileNumberNextFormat, nextNumber)) {
                    TextField(strings.fileNumberStartLabel, value: $numberStart,
                              formatter: Self.numberFieldFormatter)
                        .labelsHidden()
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 70)
                    Stepper(strings.fileNumberStartLabel, value: $numberStart, in: 0...999_999)
                        .labelsHidden()
                    Button {
                        nextNumber = numberStart
                    } label: {
                        Label(strings.fileNumberResetButton, systemImage: "arrow.counterclockwise")
                    }
                }
                .onChange(of: numberStart) { _, newValue in
                    nextNumber = newValue
                }
            }
        }
    }

    private static let numberFieldFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .none
        formatter.minimum = 0
        formatter.maximum = 999_999
        formatter.usesGroupingSeparator = false
        return formatter
    }()

    private var fileNamePreview: String {
        let trimmed = fileNamePattern.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return ScreenshotSupport.fileName(prefix: strings.fileNamePrefix, date: Date())
        }
        return ScreenshotSupport.expandFileNamePattern(trimmed, date: Date(), number: nextNumber) + ".png"
    }

    private var currentFolderName: String {
        let manager = FileManager.default
        if !saveFolder.isEmpty {
            let expanded = (saveFolder as NSString).expandingTildeInPath
            var isDirectory: ObjCBool = false
            if manager.fileExists(atPath: expanded, isDirectory: &isDirectory), isDirectory.boolValue {
                return manager.displayName(atPath: expanded)
            }
        }
        let desktop = manager.urls(for: .desktopDirectory, in: .userDomainMask).first
        return desktop.map { manager.displayName(atPath: $0.path) } ?? "Desktop"
    }

    private func chooseFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = true
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK, let url = panel.url {
            saveFolder = url.path
        }
    }
}
