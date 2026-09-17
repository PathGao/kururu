// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import SwiftUI

struct KeepAwakeSettings: View {
    @ObservedObject private var l10n = L10n.shared
    @ObservedObject private var features = FeatureRuntime.shared
    @ObservedObject private var awake = KeepAwakeManager.shared
    @ObservedObject private var hotkeys = HotkeyManager.shared
    @ObservedObject private var permissions = Permissions.shared
    @AppStorage(DefaultsKey.defaultDuration) private var defaultDuration = 0
    @AppStorage(DefaultsKey.hotkeyEnabled) private var hotkeyEnabled = true
    @AppStorage(DefaultsKey.batteryLimit) private var batteryLimit = 10
    @AppStorage(DefaultsKey.keepAwakeAutoStart) private var keepAwakeAutoStart = false
    @AppStorage(DefaultsKey.keepAwakeRightClickToggle) private var keepAwakeRightClickToggle = false
    @AppStorage(DefaultsKey.keepAwakeAllowDisplaySleep) private var keepAwakeAllowDisplaySleep = false
    @AppStorage(DefaultsKey.keepAwakePauseWhenLocked) private var keepAwakePauseWhenLocked = false
    @AppStorage(DefaultsKey.showCountdown) private var showCountdown = false
    @AppStorage(DefaultsKey.keepAwakeIconTint) private var keepAwakeIconTint = KeepAwakeIconTint.orange.rawValue
    @AppStorage(DefaultsKey.keepAwakeActiveIcon) private var keepAwakeActiveIcon = KeepAwakeActiveIcon.vorssaint.rawValue
    @AppStorage(DefaultsKey.keepAwakeMouseJiggleEnabled) private var keepAwakeMouseJiggle = false
    @AppStorage(DefaultsKey.keepAwakeMouseJiggleInterval) private var keepAwakeMouseJiggleInterval = 5

    var body: some View {
        SettingsForm {
            if AppFeature.keepAwake.isAvailable {
                SettingsSection(title: UXEntryStrings(l10n.language).startupAndShortcuts, systemImage: "keyboard") {
                    SettingsToggleWithCaption(title: l10n.s.keepAwakeAutoStart,
                                              caption: l10n.s.keepAwakeAutoStartCaption,
                                              isOn: $keepAwakeAutoStart)
                    Toggle(l10n.s.hotkeyToggle, isOn: $hotkeyEnabled)
                        .onChange(of: hotkeyEnabled) { _, enabled in
                            HotkeyManager.shared.setEnabled(enabled)
                        }
                    ShortcutPreferenceRow(role: .keepAwake, isEnabled: hotkeyEnabled) {
                        HotkeyManager.shared.syncWithPreferences()
                    }
                    if hotkeyEnabled, hotkeys.registrationFailed {
                        Text(l10n.s.shortcutUnavailable)
                            .font(SettingsTypography.caption)
                            .foregroundStyle(.orange)
                    }
                    Text(l10n.s.hotkeyCaption)
                        .font(SettingsTypography.caption)
                        .foregroundStyle(.secondary)
                }
                .settingsSectionAnchor(.keepAwake)
                SettingsSection(title: l10n.s.sessionSection, systemImage: "cup.and.saucer") {
                    SettingsControlRow(title: l10n.s.defaultDurationLabel, systemImage: "timer") {
                        Picker(l10n.s.defaultDurationLabel, selection: $defaultDuration) {
                            Text(l10n.s.minutes15).tag(15)
                            Text(l10n.s.minutes30).tag(30)
                            Text(l10n.s.hour1).tag(60)
                            Text(l10n.s.hours2).tag(120)
                            Text(l10n.s.hours4).tag(240)
                            Text(l10n.s.hours8).tag(480)
                            Text(l10n.s.indefinite).tag(0)
                        }
                        .labelsHidden()
                    }
                    SettingsToggleWithCaption(title: displaySleepStrings.allowDisplaySleep,
                                              caption: displaySleepStrings.allowDisplaySleepCaption,
                                              isOn: $keepAwakeAllowDisplaySleep)
                    SettingsToggleWithCaption(title: automationStrings.pauseWhenLockedToggle,
                                              caption: automationStrings.pauseWhenLockedCaption,
                                              isOn: $keepAwakePauseWhenLocked)
                    SettingsToggleWithCaption(title: l10n.s.keepAwakeMouseJiggle,
                                              caption: l10n.s.keepAwakeMouseJiggleCaption,
                                              isOn: $keepAwakeMouseJiggle)
                    if keepAwakeMouseJiggle {
                        SettingsControlRow(title: l10n.s.keepAwakeMouseJiggleInterval,
                                           systemImage: "computermouse") {
                            Picker(l10n.s.keepAwakeMouseJiggleInterval, selection: $keepAwakeMouseJiggleInterval) {
                                ForEach(Defaults.allowedKeepAwakeMouseJiggleIntervals, id: \.self) { minutes in
                                    Text(KeepAwakeMouseJiggleIntervalPicker.label(for: minutes)).tag(minutes)
                                }
                            }
                            .labelsHidden()
                        }
                        if !permissions.accessibility {
                            PermissionRow(kind: .accessibility)
                        }
                    }
                }
                SettingsSection(title: automationStrings.automationSection, systemImage: "calendar.badge.clock") {
                    SettingsInfo(text: automationStrings.automationCaption, systemImage: "calendar.badge.clock")
                    KeepAwakeAutomationEditor()
                }
                if PowerSampler.hasInternalBattery {
                    SettingsSection(title: l10n.s.batteryProtectionSection, systemImage: "battery.25percent") {
                        SettingsControlRow(title: l10n.s.batteryDisableBelow,
                                           systemImage: "battery.25percent",
                                           caption: l10n.s.batteryProtectionCaption) {
                            Picker(l10n.s.batteryDisableBelow, selection: $batteryLimit) {
                                Text(l10n.s.batteryNever).tag(0)
                                Text("5%").tag(5)
                                Text("10%").tag(10)
                                Text("15%").tag(15)
                                Text("20%").tag(20)
                            }
                            .labelsHidden()
                        }
                    }
                }
                SettingsSection(title: UXEntryStrings(l10n.language).menuBarDisplay, systemImage: "menubar.rectangle") {
                    SettingsToggleWithCaption(title: l10n.s.keepAwakeRightClickToggle,
                                              caption: l10n.s.keepAwakeRightClickToggleCaption, showsCaptionInline: false,
                                              isOn: $keepAwakeRightClickToggle)
                    KeepAwakeIconPicker(iconValue: $keepAwakeActiveIcon,
                                        tintValue: $keepAwakeIconTint)
                    Toggle(l10n.s.showCountdown, isOn: $showCountdown)
                }
                SettingsSection(title: l10n.s.clamshellSection, systemImage: "laptopcomputer") {
                    Toggle(l10n.s.clamshellTitle, isOn: $awake.clamshellPreferred)
                        .disabled(awake.clamshellSetupInProgress)
                    if awake.clamshellSetupInProgress {
                        Text(l10n.s.configuring)
                            .font(SettingsTypography.caption)
                            .foregroundStyle(.secondary)
                    } else if awake.clamshellSetupFailed {
                        Text(l10n.s.sudoersFailed)
                            .font(SettingsTypography.caption)
                            .foregroundStyle(.red)
                    }
                    SettingsInfo(text: l10n.s.clamshellExplanation, systemImage: "laptopcomputer")
                }
            }
        }
        .formStyle(.grouped)
        .onAppear {
            defaultDuration = Defaults.sanitizedDefaultDuration(defaultDuration)
            batteryLimit = Defaults.sanitizedBatteryLimit(batteryLimit)
            keepAwakeIconTint = Defaults.sanitizedKeepAwakeIconTint(keepAwakeIconTint).rawValue
            keepAwakeActiveIcon = Defaults.sanitizedKeepAwakeActiveIcon(keepAwakeActiveIcon).rawValue
            keepAwakeMouseJiggleInterval = Defaults.sanitizedKeepAwakeMouseJiggleInterval(keepAwakeMouseJiggleInterval)
            awake.refreshPasswordlessStatus()
        }
    }

    private var automationStrings: KeepAwakeAutomationStrings {
        FeatureStrings.keepAwakeAutomation(l10n.language)
    }

    private var displaySleepStrings: KeepAwakeDisplaySleepStrings {
        FeatureStrings.keepAwakeDisplaySleep(l10n.language)
    }
}
