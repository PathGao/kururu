// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import SwiftUI

/// Mixer behavior and output-cycle configuration; the panel keeps live volume controls.
struct MixerSettings: View {
    @ObservedObject private var l10n = L10n.shared
    @ObservedObject private var features = FeatureRuntime.shared
    @ObservedObject private var mixer = AppVolumeMixer.shared
    @ObservedObject private var outputSwitcher = SoundOutputSwitcher.shared
    @ObservedObject private var preciseVolumeRoller = PreciseVolumeRollerService.shared
    @ObservedObject private var permissions = Permissions.shared
    @AppStorage(DefaultsKey.mixerHideInactiveApps) private var hideInactiveApps = false
    @AppStorage(DefaultsKey.mixerLowerVolumeOnHeadphonesDisconnect) private var lowerOnHeadphonesDisconnect = false
    @AppStorage(DefaultsKey.mixerHeadphonesDisconnectVolumePercent) private var headphonesDisconnectVolumePercent = Defaults.defaultMixerHeadphonesDisconnectVolumePercent
    @AppStorage(DefaultsKey.preciseVolumeRollerEnabled) private var preciseVolumeRollerEnabled = false
    @AppStorage(DefaultsKey.soundOutputSwitcherEnabled) private var soundOutputSwitcherEnabled = false

    private var hierarchy: SettingsHierarchyStrings { SettingsHierarchyStrings(language: l10n.language) }
    private var mixerText: MixerFeatureStrings { FeatureStrings.mixer(l10n.language) }
    private var switcherText: SoundOutputSwitcherFeatureStrings {
        FeatureStrings.soundOutputSwitcher(l10n.language)
    }

    var body: some View {
        SettingsForm {
            Group {
                SettingsSection {
                    FeatureSwitchRow(feature: .mixer)
                    if AppVolumeMixer.isSupported {
                        MixerAppScopePicker(hideInactiveApps: $hideInactiveApps, strings: mixerText)
                        SettingsExplanation(hierarchy.mixerScope)
                    }
                    SettingsToggleWithCaption(title: mixerText.lowerOnHeadphonesDisconnect,
                                              caption: mixerText.lowerOnHeadphonesDisconnectCaption,
                                              isOn: $lowerOnHeadphonesDisconnect)
                    if lowerOnHeadphonesDisconnect {
                        Stepper(value: headphonesDisconnectVolumeBinding,
                                in: Defaults.minimumMixerHeadphonesDisconnectVolumePercent...100,
                                step: 5) {
                            HStack {
                                Text(mixerText.headphonesDisconnectVolume)
                                Spacer()
                                Text("\(headphonesDisconnectDisplayPercent)%")
                                    .foregroundStyle(.secondary)
                                    .monospacedDigit()
                            }
                        }
                    }
                    preciseVolumeRollerToggle
                }
            }

            if AppFeature.soundOutputSwitcher.isAvailable {
                SettingsSection {
                    FeatureSwitchRow(feature: .soundOutputSwitcher)
                    SettingsCaptionText(switcherText.caption)
                    SoundOutputSwitcherDevicePicker()
                    ShortcutPreferenceRow(role: .soundOutputSwitcher,
                                          isEnabled: soundOutputSwitcherEnabled) {
                        SoundOutputSwitcher.shared.syncWithPreferences()
                    }
                    if soundOutputSwitcherEnabled, outputSwitcher.registrationFailed {
                        Text(l10n.s.shortcutUnavailable)
                            .font(SettingsTypography.caption)
                            .foregroundStyle(.orange)
                    }
                }
                .settingsSectionAnchor(.soundOutputSwitcher)
                .onChange(of: soundOutputSwitcherEnabled) { _, enabled in
                    if enabled, SoundOutputSwitcher.shared.selectedDeviceUIDs().isEmpty,
                       let current = mixer.currentOutputDeviceUID,
                       mixer.outputDevices.contains(where: { $0.canBeDefaultOutput && $0.uid == current }) {
                        SoundOutputSwitcher.shared.setSelectedDeviceUIDs([current])
                    }
                }
            }
        }
        .formStyle(.grouped)
    }

    private var headphonesDisconnectVolumeBinding: Binding<Int> {
        Binding(
            get: { Defaults.sanitizedMixerHeadphonesDisconnectVolumePercent(headphonesDisconnectVolumePercent) },
            set: { headphonesDisconnectVolumePercent = Defaults.sanitizedMixerHeadphonesDisconnectVolumePercent($0) }
        )
    }

    private var headphonesDisconnectDisplayPercent: Int {
        Defaults.sanitizedMixerHeadphonesDisconnectVolumePercent(headphonesDisconnectVolumePercent)
    }

    /// Badged like a switch row: the keyboard tap is this option's cost, not
    /// the mixer's.
    private var preciseVolumeRollerToggle: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                SettingsToggleWithCaption(title: l10n.s.preciseVolumeRollerEnable,
                                          caption: l10n.s.preciseVolumeRollerCaption,
                                          isOn: $preciseVolumeRollerEnabled)
                    .onChange(of: preciseVolumeRollerEnabled) { _, enabled in
                        if enabled && AppFeature.mixer.isAvailable { permissions.requestAccessibility() }
                        PreciseVolumeRollerService.shared.syncWithPreferences()
                    }
                Text(FeatureStrings.hub(l10n.language).energyKeyboard)
                    .font(.system(size: 9))
                    .foregroundStyle(.tertiary)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 1)
                    .background(Capsule().fill(Color.secondary.opacity(0.12)))
                    .help(FeatureStrings.hub(l10n.language).energyHelp)
            }

            if preciseVolumeRollerEnabled, AppFeature.mixer.isAvailable, !permissions.accessibility {
                Button {
                    Permissions.shared.openAccessibilitySettings()
                } label: {
                    Label(l10n.s.permissionOpenSettings, systemImage: "hand.raised")
                }
                .buttonStyle(.link)
            } else if preciseVolumeRoller.tapFailed {
                Text(l10n.s.preciseVolumeRollerTapFailed)
                    .font(SettingsTypography.caption)
                    .foregroundStyle(.orange)
            }
        }
    }
}
