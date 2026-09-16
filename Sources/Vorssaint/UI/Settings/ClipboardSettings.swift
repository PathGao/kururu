// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import SwiftUI

struct ClipboardSettings: View {
    @ObservedObject private var l10n = L10n.shared
    @ObservedObject private var features = FeatureRuntime.shared
    @ObservedObject private var history = ClipboardHistoryService.shared
    @ObservedObject private var pastePlain = PastePlainService.shared
    @ObservedObject private var permissions = Permissions.shared
    @AppStorage(DefaultsKey.pastePlainEnabled) private var pastePlainEnabled = false
    @AppStorage(DefaultsKey.clipboardHistoryEnabled) private var enabled = false
    @AppStorage(DefaultsKey.clipboardHistoryLimit) private var limit = 50
    @AppStorage(DefaultsKey.clipboardHistorySkipSensitive) private var skipSensitive = true
    @AppStorage(DefaultsKey.clipboardHistoryIncludeImagesFiles) private var includeImagesFiles = true
    @AppStorage(DefaultsKey.clipboardHistoryShortcutEnabled) private var shortcutEnabled = true
    @AppStorage(DefaultsKey.clipboardAutoClearOnDelay) private var autoClearOnDelay = false
    @AppStorage(DefaultsKey.clipboardAutoClearDelay)
    private var autoClearDelay = Defaults.defaultClipboardAutoClearDelay
    @AppStorage(DefaultsKey.clipboardAutoClearOnSleep) private var autoClearOnSleep = false
    @AppStorage(DefaultsKey.clipboardAutoClearOnDisplaySleep) private var autoClearOnDisplaySleep = false
    @AppStorage(DefaultsKey.clipboardAutoClearOnScreenLock) private var autoClearOnScreenLock = false

    private var text: ClipboardFeatureStrings {
        FeatureStrings.clipboard(l10n.language)
    }

    var body: some View {
        SettingsForm {
            if AppFeature.clipboardHistory.isAvailable {
                SettingsSection(title: flowText.useClipboard, systemImage: "doc.on.clipboard") {
                    Button {
                        ClipboardHistoryService.shared.showHistoryWindow()
                    } label: {
                        Label(flowText.viewClipboard, systemImage: "doc.on.clipboard")
                    }
                    .settingsAction(.primary)
                    Toggle(text.shortcut, isOn: $shortcutEnabled)
                        .onChange(of: shortcutEnabled) { _, _ in
                            ClipboardHistoryService.shared.syncHotkey()
                        }
                    ShortcutPreferenceRow(role: .clipboard, isEnabled: shortcutEnabled) {
                        ClipboardHistoryService.shared.syncHotkey()
                    }
                    if shortcutEnabled, history.shortcutRegistrationFailed {
                        Text(l10n.s.shortcutUnavailable).font(SettingsTypography.caption).foregroundStyle(.orange)
                    }
                    PanelEntrySettings(title: l10n.s.monitorShowInPanel,
                                       key: DefaultsKey.panelUtilityClipboard)
                }
                .settingsSectionAnchor(.clipboardHistory)

                SettingsSection(title: flowText.automaticCapture, systemImage: "tray.and.arrow.down") {
                    FeatureSwitchRow(feature: .clipboardHistory, title: flowText.recordCopiedContent,
                                     help: flowText.automaticCaptureCaption + "\n\n" + text.localNote)
                    if enabled, history.isRunning {
                        Label(flowText.captureActive, systemImage: "checkmark.circle.fill")
                            .font(SettingsTypography.caption)
                            .foregroundStyle(.green)
                    } else if !enabled {
                        Label(flowText.capturePaused, systemImage: "pause.circle")
                            .font(SettingsTypography.caption)
                            .foregroundStyle(.secondary)
                    }
                    SettingsToggleWithCaption(title: text.includeImagesFiles,
                                              caption: text.includeImagesFilesCaption,
                                              showsCaptionInline: false,
                                              isOn: $includeImagesFiles)
                    SettingsToggleWithCaption(title: text.skipSensitive,
                                              caption: text.skipSensitiveCaption,
                                              isOn: $skipSensitive)
                    SettingsControlRow(title: text.limit, systemImage: "tray.full") {
                        Picker(text.limit, selection: $limit) {
                            ForEach(Defaults.allowedClipboardHistoryLimits, id: \.self) { value in
                                Text(value == 0 ? text.limitUnlimited : "\(value)").tag(value)
                            }
                        }
                        .labelsHidden()
                    }
                    ClipboardIgnoredAppsList()
                }

                clipboardAutoClearSection
                clipboardStatsSection
                ClipboardImportSettings()
            }

            if AppFeature.pastePlain.isAvailable {
                SettingsSection {
                    FeatureSwitchRow(feature: .pastePlain, help: l10n.s.pastePlainCaption)
                    ShortcutPreferenceRow(role: .pastePlain, isEnabled: pastePlainEnabled) {
                        PastePlainService.shared.syncWithPreferences()
                    }
                    if pastePlainEnabled, pastePlain.shortcutRegistrationFailed {
                        Text(l10n.s.shortcutUnavailable).font(SettingsTypography.caption).foregroundStyle(.orange)
                    }
                    if pastePlainEnabled, !permissions.accessibility { PermissionRow(kind: .accessibility) }
                }
                .settingsSectionAnchor(.pastePlain)
            }

            if AppFeature.urlCleaner.isAvailable {
                SettingsSection(title: flowText.relatedTools, systemImage: "link") {
                    Button {
                        SettingsRouter.shared.request(AppFeature.urlCleaner.settingsDestination)
                    } label: {
                        Label(flowText.openURLCleaner, systemImage: "link")
                    }
                }
            }
        }
        .formStyle(.grouped)
        .onAppear {
            limit = Defaults.sanitizedClipboardHistoryLimit(limit)
            autoClearDelay = Defaults.sanitizedClipboardAutoClearDelay(autoClearDelay)
        }
        .onChange(of: limit) { _, value in
            let sanitized = Defaults.sanitizedClipboardHistoryLimit(value)
            if sanitized != value { limit = sanitized }
            ClipboardHistoryService.shared.trimToLimit()
        }
        // No syncWithPreferences() here, unlike the auto-clear toggles: the
        // running poll reads this value from UserDefaults on every tick, so a
        // new delay takes effect on the next one. Syncing would just tear the
        // timer down and restart the wait.
        .onChange(of: autoClearDelay) { _, value in
            let sanitized = Defaults.sanitizedClipboardAutoClearDelay(value)
            if sanitized != value { autoClearDelay = sanitized }
        }
    }

    private var flowText: UXTaskFlowStrings { UXTaskFlowStrings(language: l10n.language) }

    // Never disabled by the capture toggle, unlike the sections above it:
    // emptying the pasteboard is a security setting in its own right, and
    // someone who keeps no history is exactly who reaches for it.
    @ViewBuilder
    private var clipboardAutoClearSection: some View {
        SettingsSection(title: UXEntryStrings(l10n.language).clipboardAutoClearTitle, systemImage: "eraser") {
            HStack {
                Toggle(text.autoClearEnable, isOn: $autoClearOnDelay)
                    .onChange(of: autoClearOnDelay) { _, _ in
                        ClipboardAutoClearService.shared.syncWithPreferences()
                    }
                TextField("", value: $autoClearDelay, formatter: Self.delayFieldFormatter)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 60)
                    .disabled(!autoClearOnDelay)
                Text(text.autoClearSecondsSuffix)
                    .foregroundStyle(.secondary)
            }
            .fixedSize(horizontal: false, vertical: true)
            Toggle(text.autoClearOnSleep, isOn: $autoClearOnSleep)
                .onChange(of: autoClearOnSleep) { _, _ in
                    ClipboardAutoClearService.shared.syncWithPreferences()
                }
            Toggle(text.autoClearOnDisplaySleep, isOn: $autoClearOnDisplaySleep)
                .onChange(of: autoClearOnDisplaySleep) { _, _ in
                    ClipboardAutoClearService.shared.syncWithPreferences()
                }
            Toggle(text.autoClearOnScreenLock, isOn: $autoClearOnScreenLock)
                .onChange(of: autoClearOnScreenLock) { _, _ in
                    ClipboardAutoClearService.shared.syncWithPreferences()
                }
            SettingsInfo(text: text.autoClearCaption, systemImage: "eraser")
        }
    }

    private static let delayFieldFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .none
        formatter.minimum = NSNumber(value: Defaults.allowedClipboardAutoClearDelayRange.lowerBound)
        formatter.maximum = NSNumber(value: Defaults.allowedClipboardAutoClearDelayRange.upperBound)
        formatter.usesGroupingSeparator = false
        return formatter
    }()

    private var clipboardStatsSection: some View {
            SettingsSection(title: flowText.dataManagement, systemImage: "externaldrive") {
                HStack {
                    Text("\(history.pinnedEntries.count)")
                    Text(text.pinned)
                        .foregroundStyle(.secondary)
                    Text("·")
                        .foregroundStyle(.tertiary)
                    Text("\(history.recentEntries.count)")
                    Text(text.recent)
                        .foregroundStyle(.secondary)
                    Spacer()
                    ClipboardClearRecentButton()
                    .disabled(history.recentEntries.isEmpty)
                }
            }
    }
}
