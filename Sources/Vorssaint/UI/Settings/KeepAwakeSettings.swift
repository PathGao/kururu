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
        Form {
            if AppFeature.keepAwake.isAvailable {
                Section(l10n.s.sessionSection) {
                    Picker(l10n.s.defaultDurationLabel, selection: $defaultDuration) {
                        Text(l10n.s.minutes15).tag(15)
                        Text(l10n.s.minutes30).tag(30)
                        Text(l10n.s.hour1).tag(60)
                        Text(l10n.s.hours2).tag(120)
                        Text(l10n.s.hours4).tag(240)
                        Text(l10n.s.hours8).tag(480)
                        Text(l10n.s.indefinite).tag(0)
                    }
                    SettingsToggleWithCaption(title: l10n.s.keepAwakeAutoStart,
                                              caption: l10n.s.keepAwakeAutoStartCaption,
                                              isOn: $keepAwakeAutoStart)
                    SettingsToggleWithCaption(title: l10n.s.keepAwakeRightClickToggle,
                                              caption: l10n.s.keepAwakeRightClickToggleCaption,
                                              isOn: $keepAwakeRightClickToggle)
                    // The countdown is a Keep Awake session readout, so it sits
                    // with the session options. Under the General page's menu
                    // bar section the label gave no clue which time it meant.
                    Toggle(l10n.s.showCountdown, isOn: $showCountdown)
                    SettingsToggleWithCaption(title: displaySleepStrings.allowDisplaySleep,
                                              caption: displaySleepStrings.allowDisplaySleepCaption,
                                              isOn: $keepAwakeAllowDisplaySleep)
                    Toggle(l10n.s.hotkeyToggle, isOn: $hotkeyEnabled)
                        .onChange(of: hotkeyEnabled) { _, enabled in
                            HotkeyManager.shared.setEnabled(enabled)
                        }
                    ShortcutPreferenceRow(role: .keepAwake, isEnabled: hotkeyEnabled) {
                        HotkeyManager.shared.syncWithPreferences()
                    }
                    if hotkeyEnabled, hotkeys.registrationFailed {
                        Text(l10n.s.shortcutUnavailable)
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                    Text(l10n.s.hotkeyCaption)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .settingsSectionAnchor(.keepAwake)
                Section(automationStrings.automationSection) {
                    SettingsCaptionText(automationStrings.automationCaption)
                    KeepAwakeAutomationEditor()
                }
                Section {
                    SettingsToggleWithCaption(title: automationStrings.pauseWhenLockedToggle,
                                              caption: automationStrings.pauseWhenLockedCaption,
                                              isOn: $keepAwakePauseWhenLocked)
                }
                if PowerSampler.hasInternalBattery {
                    Section(l10n.s.batteryProtectionSection) {
                        Picker(l10n.s.batteryDisableBelow, selection: $batteryLimit) {
                            Text(l10n.s.batteryNever).tag(0)
                            Text("5%").tag(5)
                            Text("10%").tag(10)
                            Text("15%").tag(15)
                            Text("20%").tag(20)
                        }
                        SettingsCaptionText(l10n.s.batteryProtectionCaption)
                    }
                }
                Section(AppFeature.keepAwake.name(l10n.s, language: l10n.language)) {
                    KeepAwakeIconPicker(iconValue: $keepAwakeActiveIcon,
                                        tintValue: $keepAwakeIconTint)
                    SettingsToggleWithCaption(title: l10n.s.keepAwakeMouseJiggle,
                                              caption: l10n.s.keepAwakeMouseJiggleCaption,
                                              isOn: $keepAwakeMouseJiggle)
                    if keepAwakeMouseJiggle {
                        Picker(l10n.s.keepAwakeMouseJiggleInterval, selection: $keepAwakeMouseJiggleInterval) {
                            ForEach(Defaults.allowedKeepAwakeMouseJiggleIntervals, id: \.self) { minutes in
                                Text(KeepAwakeMouseJiggleIntervalPicker.label(for: minutes)).tag(minutes)
                            }
                        }
                        if !permissions.accessibility {
                            PermissionRow(kind: .accessibility)
                        }
                    }
                }
                Section(l10n.s.clamshellSection) {
                    Toggle(l10n.s.clamshellTitle, isOn: $awake.clamshellPreferred)
                        .disabled(awake.clamshellSetupInProgress)
                    if awake.clamshellSetupInProgress {
                        Text(l10n.s.configuring)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else if awake.clamshellSetupFailed {
                        Text(l10n.s.sudoersFailed)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                    SettingsCaptionText(l10n.s.clamshellExplanation)
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
