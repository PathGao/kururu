// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import SwiftUI

struct BrightnessSettings: View {
    @ObservedObject private var l10n = L10n.shared
    @ObservedObject private var features = FeatureRuntime.shared
    @ObservedObject private var permissions = Permissions.shared
    @ObservedObject private var brightness = BrightnessService.shared
    @AppStorage(DefaultsKey.brightnessKeysEnabled) private var brightnessKeysEnabled = false
    @AppStorage(DefaultsKey.brightnessOSDEnabled) private var brightnessOSDEnabled = false
    @AppStorage(BrightnessShortcutPreferenceKey.enabled)
    private var displayBrightnessShortcutsEnabled = false

    @State private var refreshOwner = UUID()

    var body: some View {
        SettingsForm {
            if AppFeature.brightness.isAvailable {
                let strings = FeatureStrings.brightness(l10n.language)
                SettingsSection(title: UXEntryStrings(l10n.language).displayDevices, systemImage: "display") {
                    HStack {
                        Text(strings.enable)
                            .font(SettingsTypography.body)
                        SettingsHelpButton(title: UXEntryStrings(l10n.language).displayDevices,
                                           text: strings.enableCaption + "\n\n" + strings.externalCaption)
                    }
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
                .settingsSectionAnchor(.brightness)

                SettingsSection(title: UXEntryStrings(l10n.language).keyboardControl, systemImage: "keyboard") {
                    SettingsToggleWithCaption(title: strings.keysToggle,
                                              caption: strings.keysCaption,
                                              showsCaptionInline: false,
                                              isOn: $brightnessKeysEnabled)
                        .onChange(of: brightnessKeysEnabled) { _, isOn in
                            if isOn { Permissions.shared.requestAccessibility() }
                            BrightnessService.shared.syncWithPreferences()
                        }
                    if brightness.brightnessOSDSupported {
                        SettingsToggleWithCaption(title: strings.osdToggle,
                                                  caption: strings.osdCaption,
                                                  showsCaptionInline: false,
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
                    Divider()
                    displayBrightnessShortcutControls
                }
            }
        }
        .formStyle(.grouped)
        .onAppear { brightness.beginVisibleRefresh(refreshOwner) }
        .onDisappear { brightness.endVisibleRefresh(refreshOwner) }
    }

    private var displayBrightnessShortcutControls: some View {
        let text = BrightnessShortcutStrings.localized(l10n.language)
        return Group {
            SettingsToggleWithCaption(title: text.toggle, caption: text.caption,
                                      showsCaptionInline: false,
                                      isOn: $displayBrightnessShortcutsEnabled)
                .onChange(of: displayBrightnessShortcutsEnabled) { _, _ in
                    BrightnessService.shared.syncWithPreferences()
                }
            ShortcutPreferenceRow(
                role: .displayBrightnessDecrease,
                isEnabled: displayBrightnessShortcutsEnabled,
                label: text.decrease,
                symbolName: "sun.min",
                includeInactiveConflicts: true,
                onChange: { BrightnessService.shared.syncWithPreferences() })
            ShortcutPreferenceRow(
                role: .displayBrightnessIncrease,
                isEnabled: displayBrightnessShortcutsEnabled,
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
                if display.isActive, display.method != nil {
                    DisplayBrightnessControl(display: display, showOSD: brightnessOSDEnabled)
                    Text(display.observedBrightness.map { "\(Int(($0 * 100).rounded()))%" } ?? "—")
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
