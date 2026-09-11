// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import SwiftUI

struct BluetoothSleepSettings: View {
    @ObservedObject private var l10n = L10n.shared
    @ObservedObject private var features = FeatureRuntime.shared
    @AppStorage(DefaultsKey.bluetoothSleepEnabled) private var bluetoothSleepEnabled = false
    @AppStorage(DefaultsKey.bluetoothSleepRestoreOnWake) private var bluetoothSleepRestoreOnWake = true

    var body: some View {
        SettingsForm {
            if AppFeature.bluetoothSleep.isAvailable {
                let strings = FeatureStrings.bluetoothSleep(l10n.language)
                SettingsSection(AppFeature.bluetoothSleep.name(l10n.s, language: l10n.language)) {
                    if BluetoothSleepService.isSupported {
                        SettingsToggleWithCaption(title: strings.enable,
                                                  caption: strings.enableCaption,
                                                  isOn: $bluetoothSleepEnabled)
                            .onChange(of: bluetoothSleepEnabled) { _, _ in
                                BluetoothSleepService.shared.syncWithPreferences()
                            }
                        if bluetoothSleepEnabled {
                            SettingsToggleWithCaption(title: strings.restoreToggle,
                                                      caption: strings.restoreCaption,
                                                      isOn: $bluetoothSleepRestoreOnWake)
                        }
                    } else {
                        SettingsCaptionText(strings.unsupported)
                    }
                }
                .settingsSectionAnchor(.bluetoothSleep)
            }
        }
        .formStyle(.grouped)
    }
}
