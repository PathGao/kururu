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

    var body: some View {
        Form {
            FeatureSwitchSection(unit: .brightness)
            if AppFeature.brightness.isAvailable {
                let strings = FeatureStrings.brightness(l10n.language)
                Section(AppFeature.brightness.name(l10n.s, language: l10n.language)) {
                    SettingsCaptionText(strings.enableCaption)
                    if brightnessEnabled {
                        if brightness.displays.isEmpty {
                            SettingsCaptionText(strings.noDisplays)
                        } else {
                            ForEach(brightness.displays) { display in
                                brightnessRow(display)
                            }
                        }
                        if let failure = brightness.displayControlFailure {
                            SettingsCaptionText(displayControlFailureText(failure, strings: strings))
                                .foregroundStyle(.red)
                        }
                        SettingsToggleWithCaption(title: strings.keysToggle,
                                                  caption: strings.keysCaption,
                                                  isOn: $brightnessKeysEnabled)
                            .onChange(of: brightnessKeysEnabled) { _, isOn in
                                if isOn { Permissions.shared.requestAccessibility() }
                                BrightnessService.shared.syncWithPreferences()
                            }
                        if brightness.brightnessOSDSupported {
                            SettingsToggleWithCaption(title: strings.osdToggle,
                                                      caption: strings.osdCaption,
                                                      isOn: $brightnessOSDEnabled)
                                .onChange(of: brightnessOSDEnabled) { _, isOn in
                                    if isOn { Permissions.shared.requestAccessibility() }
                                    BrightnessService.shared.syncWithPreferences()
                                }
                        }
                        if (brightnessKeysEnabled || brightnessOSDEnabled),
                           !permissions.accessibility {
                            PermissionRow(kind: .accessibility)
                        }
                        SettingsCaptionText(strings.externalCaption)
                    }
                }
                .settingsSectionAnchor(.brightness)
            }
        }
        .formStyle(.grouped)
        .onAppear {
            BrightnessService.shared.refresh()
        }
    }

    private func brightnessRow(_ display: BrightnessDisplay) -> some View {
        HStack(spacing: 10) {
            Image(systemName: display.isBuiltIn ? "laptopcomputer" : "display")
                .foregroundStyle(.secondary)
                .frame(width: 18)
            Text(display.name)
                .lineLimit(1)
                .truncationMode(.middle)
            if display.isActive, display.method != nil {
                Slider(value: Binding(get: { display.brightness },
                                      set: { BrightnessService.shared.setBrightness(
                                          $0, for: display.id,
                                          showOSD: brightnessOSDEnabled) }),
                       in: 0...1)
                    .disabled(brightness.isDisplayPending(display.id))
                    .accessibilityLabel(display.name)
                Text("\(Int((display.brightness * 100).rounded()))%")
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
    }
}
