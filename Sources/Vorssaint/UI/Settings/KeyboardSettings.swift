// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import SwiftUI

/// The three things that happen while you type: a filter on repeated presses,
/// abbreviations that expand, and a held key that becomes a modifier layer.
struct KeyboardSettings: View {
    /// Keyboard backlight belongs to Displays in the feature library, but people
    /// look for it under Keyboard, as in System Settings.
    static var showsBacklight: Bool {
        AppFeature.brightness.isAvailable && BrightnessService.keyboardLightIsSupported
    }

    var body: some View {
        SettingsForm {
            if Self.showsBacklight {
                KeyboardBacklightSection()
            }
            if AppFeature.keyboardDebounce.isAvailable {
                KeyboardDebounceSections()
            }
            if AppFeature.textSnippets.isAvailable {
                TextSnippetsSections()
            }
            if AppFeature.superKey.isAvailable {
                SuperKeySections()
            }
        }
        .formStyle(.grouped)
    }
}

private struct KeyboardBacklightSection: View {
    @ObservedObject private var l10n = L10n.shared
    @ObservedObject private var brightness = BrightnessService.shared
    @AppStorage(DefaultsKey.keyboardBrightnessShortcutsEnabled) private var keyboardBrightnessShortcutsEnabled = false

    var body: some View {
        SettingsSection(title: FeatureStrings.brightness(l10n.language).keyboardLight, systemImage: "keyboard") {
            keyboardBrightnessShortcutControls
        }
    }

    private var keyboardBrightnessShortcutControls: some View {
        Group {
            Toggle(FeatureStrings.brightness(l10n.language).keyboardBrightnessShortcuts,
                   isOn: $keyboardBrightnessShortcutsEnabled)
                .onChange(of: keyboardBrightnessShortcutsEnabled) { _, _ in
                    BrightnessService.shared.syncWithPreferences()
                }
            ForEach([GlobalShortcutRole.keyboardBrightnessDecrease, .keyboardBrightnessIncrease], id: \.self) { role in
                ShortcutPreferenceRow(
                    role: role,
                    isEnabled: keyboardBrightnessShortcutsEnabled,
                    label: role.title(l10n.s),
                    symbolName: "keyboard",
                    includeInactiveConflicts: true,
                    onChange: { BrightnessService.shared.syncWithPreferences() })
            }
            if keyboardBrightnessShortcutsEnabled, brightness.keyboardBrightnessShortcutRegistrationFailed {
                SettingsCaptionText(l10n.s.shortcutUnavailable)
                    .foregroundStyle(.orange)
            }
        }
    }
}
