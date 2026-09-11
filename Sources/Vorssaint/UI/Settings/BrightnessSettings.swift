// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import SwiftUI

struct BrightnessSettings: View {
    @ObservedObject private var l10n = L10n.shared
    @ObservedObject private var features = FeatureRuntime.shared
    @ObservedObject private var permissions = Permissions.shared
    @ObservedObject private var brightness = BrightnessService.shared
    @AppStorage(DefaultsKey.brightnessControlEnabled) private var brightnessEnabled = false
    @AppStorage(DefaultsKey.brightnessKeysEnabled) private var brightnessKeysEnabled = false
    @AppStorage(DefaultsKey.brightnessOSDEnabled) private var brightnessOSDEnabled = false
    @AppStorage(BrightnessShortcutPreferenceKey.enabled)
    private var displayBrightnessShortcutsEnabled = false

    var body: some View {
        SettingsForm {
            if AppFeature.brightness.isAvailable {
                let strings = FeatureStrings.brightness(l10n.language)
                SettingsSection(title: UXEntryStrings(l10n.language).displayDevices, systemImage: "display") {
                    FeatureSwitchRow(feature: .brightness)
                    SettingsCaptionText(strings.enableCaption)
                    if brightnessEnabled {
                        if brightness.displays.isEmpty {
                            SettingsCaptionText(strings.noDisplays)
                        } else {
                            ForEach(brightness.displays) { display in
                                VStack(alignment: .leading, spacing: 4) {
                                    brightnessRow(display)
                                    if brightness.brightnessWriteFailures[display.id] != nil {
                                        SettingsCaptionText(strings.brightnessWriteFailed)
                                            .foregroundStyle(.red)
                                    }
                                }
                            }
                        }
                        if let failure = brightness.displayControlFailure {
                            SettingsCaptionText(displayControlFailureText(failure, strings: strings))
                                .foregroundStyle(.red)
                        }
                    }
                    SettingsCaptionText(strings.externalCaption)
                }
                .settingsSectionAnchor(.brightness)

                SettingsSection(title: UXEntryStrings(l10n.language).keyboardControl, systemImage: "keyboard") {
                    SettingsToggleWithCaption(title: strings.keysToggle,
                                              caption: strings.keysCaption,
                                              isOn: $brightnessKeysEnabled)
                        .onChange(of: brightnessKeysEnabled) { _, isOn in
                            if isOn && brightnessEnabled { Permissions.shared.requestAccessibility() }
                            BrightnessService.shared.syncWithPreferences()
                        }
                    if brightness.brightnessOSDSupported {
                        SettingsToggleWithCaption(title: strings.osdToggle,
                                                  caption: strings.osdCaption,
                                                  isOn: $brightnessOSDEnabled)
                            .onChange(of: brightnessOSDEnabled) { _, isOn in
                                if isOn && brightnessEnabled { Permissions.shared.requestAccessibility() }
                                BrightnessService.shared.syncWithPreferences()
                            }
                    }
                    if brightnessEnabled, (brightnessKeysEnabled || brightnessOSDEnabled),
                       !permissions.accessibility {
                        PermissionRow(kind: .accessibility)
                    }
                    Divider()
                    displayBrightnessShortcutControls
                }
            }
        }
        .formStyle(.grouped)
        .onAppear {
            BrightnessService.shared.refresh()
        }
    }

    private var displayBrightnessShortcutControls: some View {
        let text = BrightnessShortcutStrings.localized(l10n.language)
        return Group {
            SettingsCaptionText(text.caption)
            Toggle(text.toggle, isOn: $displayBrightnessShortcutsEnabled)
                .onChange(of: displayBrightnessShortcutsEnabled) { _, _ in
                    BrightnessService.shared.syncWithPreferences()
                }
            ShortcutPreferenceRow(
                role: .displayBrightnessDecrease,
                isEnabled: true,
                label: text.decrease,
                symbolName: "sun.min",
                includeInactiveConflicts: true,
                onChange: { BrightnessService.shared.syncWithPreferences() })
            ShortcutPreferenceRow(
                role: .displayBrightnessIncrease,
                isEnabled: true,
                label: text.increase,
                symbolName: "sun.max",
                includeInactiveConflicts: true,
                onChange: { BrightnessService.shared.syncWithPreferences() })
            if displayBrightnessShortcutsEnabled,
               brightness.displayBrightnessShortcutRegistrationFailed {
                SettingsCaptionText(l10n.s.shortcutUnavailable)
                    .foregroundStyle(.orange)
            }
        }
    }

    private func brightnessRow(_ display: BrightnessDisplay) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 10) {
                Image(systemName: display.isBuiltIn ? "laptopcomputer" : "display")
                    .foregroundStyle(.secondary)
                    .frame(width: 18)
                Text(display.name)
                    .lineLimit(1)
                    .truncationMode(.middle)
                if !display.isBuiltIn, display.isActive, display.method != nil {
                    Slider(value: Binding(get: { display.brightness },
                                          set: { BrightnessService.shared.setBrightness(
                                              $0, for: display.id,
                                              showOSD: brightnessOSDEnabled) }),
                           in: 0...1)
                        .disabled(brightness.isDisplayPending(display.id))
                        .accessibilityLabel(display.name)
                        .accessibilityValue(display.hasKnownBrightness ? "\(Int((display.brightness * 100).rounded()))%" : FeatureStrings.brightness(l10n.language).brightnessUnknownNote)
                    Text(display.hasKnownBrightness ? "\(Int((display.brightness * 100).rounded()))%" : "—")
                        .font(.system(.body, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .frame(width: 52, alignment: .trailing)
                } else {
                    Spacer()
                    if !display.isActive {
                        Text(FeatureStrings.brightness(l10n.language).displayOff)
                            .foregroundStyle(.secondary)
                            .frame(width: 52, alignment: .trailing)
                    }
                }
                DisplayPowerButton(display: display)
            }

            if let explanation = brightnessControlExplanation(
                display, strings: FeatureStrings.brightness(l10n.language)) {
                Text(explanation)
                    .font(SettingsTypography.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
