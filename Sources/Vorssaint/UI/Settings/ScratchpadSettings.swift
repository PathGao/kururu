// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import SwiftUI

struct ScratchpadSettings: View {
    @ObservedObject private var l10n = L10n.shared
    @ObservedObject private var features = FeatureRuntime.shared
    @ObservedObject private var scratchpad = ScratchpadService.shared
    @AppStorage(DefaultsKey.scratchpadShortcutEnabled) private var scratchpadShortcutEnabled = false
    @AppStorage(DefaultsKey.scratchpadRetention) private var scratchpadRetention = ScratchpadRetention.never.rawValue
    @AppStorage(DefaultsKey.scratchpadCloseOnClickOutside) private var scratchpadCloseOnClickOutside = true
    @AppStorage(DefaultsKey.scratchpadBackgroundOpacity) private var scratchpadBackgroundOpacity = 0.0

    var body: some View {
        SettingsForm {
            if let issue = scratchpad.saveIssue {
                SettingsSection {
                    ScratchpadSaveNotice(issue: issue, text: .text(l10n.language)) {
                        _ = scratchpad.retrySave()
                    }
                }
            }
            if AppFeature.scratchpad.isAvailable {
                SettingsSection(title: UXEntryStrings(l10n.language).activationAndShortcuts,
                                systemImage: "keyboard") {
                    SettingsControlRow(title: AppFeature.scratchpad.name(l10n.s, language: l10n.language),
                                       systemImage: "note.text",
                                       caption: FeatureStrings.scratchpad(l10n.language).panelCaption) {
                        Button(FeatureStrings.scratchpad(l10n.language).openButton) {
                            ScratchpadService.shared.show()
                        }
                        .settingsAction(.primary)
                    }
                    Divider()
                    Toggle(l10n.s.quickToolShortcutToggle, isOn: $scratchpadShortcutEnabled)
                        .onChange(of: scratchpadShortcutEnabled) { _, _ in
                            ScratchpadService.shared.syncWithPreferences()
                        }
                    ShortcutPreferenceRow(role: .scratchpad,
                                          isEnabled: scratchpadShortcutEnabled) {
                        ScratchpadService.shared.syncWithPreferences()
                    }
                    if scratchpadShortcutEnabled, scratchpad.shortcutRegistrationFailed {
                        Text(l10n.s.shortcutUnavailable)
                            .font(SettingsTypography.caption)
                            .foregroundStyle(.orange)
                    }
                }
                SettingsSection(title: UXEntryStrings(l10n.language).retentionAndBehavior,
                                systemImage: "clock") {
                    SettingsControlRow(title: FeatureStrings.scratchpad(l10n.language).retentionTitle,
                                       systemImage: "clock.arrow.circlepath") {
                        Picker(FeatureStrings.scratchpad(l10n.language).retentionTitle,
                               selection: $scratchpadRetention) {
                            Text(FeatureStrings.scratchpad(l10n.language).retentionNever)
                                .tag(ScratchpadRetention.never.rawValue)
                            Text(FeatureStrings.scratchpad(l10n.language).retentionDay)
                                .tag(ScratchpadRetention.day.rawValue)
                            Text(FeatureStrings.scratchpad(l10n.language).retentionWeek)
                                .tag(ScratchpadRetention.week.rawValue)
                            Text(FeatureStrings.scratchpad(l10n.language).retentionMonth)
                                .tag(ScratchpadRetention.month.rawValue)
                        }
                        .labelsHidden()
                    }
                    SettingsExplanation(FeatureStrings.scratchpad(l10n.language).retentionCaption)
                    Divider()
                    Toggle(FeatureStrings.scratchpad(l10n.language).closeOnClickOutside,
                           isOn: $scratchpadCloseOnClickOutside)
                        .onChange(of: scratchpadCloseOnClickOutside) { _, _ in
                            ScratchpadService.shared.outsideClickPreferenceDidChange()
                        }
                }
                SettingsSection(title: UXEntryStrings(l10n.language).appearance,
                                systemImage: "square.on.square") {
                    SettingsControlRow(title: FeatureStrings.scratchpad(l10n.language).backgroundOpacity,
                                       systemImage: "circle.lefthalf.filled") {
                        VStack(spacing: 6) {
                            Slider(value: scratchpadBackgroundOpacityBinding,
                                   in: ScratchpadSupport.backgroundOpacityRange,
                                   step: 0.05)
                                .labelsHidden()
                                .accessibilityLabel(FeatureStrings.scratchpad(l10n.language).backgroundOpacity)
                            HStack {
                                Text(FeatureStrings.scratchpad(l10n.language).backgroundTranslucent)
                                Spacer()
                                Text(FeatureStrings.scratchpad(l10n.language).backgroundOpaque)
                            }
                            .font(SettingsTypography.caption)
                            .foregroundStyle(.secondary)
                        }
                        .frame(width: 200)
                    }
                }
                ScratchpadImportSettings()
            }
        }
        .formStyle(.grouped)
    }

    private var scratchpadBackgroundOpacityBinding: Binding<Double> {
        Binding(
            get: { ScratchpadSupport.sanitizedBackgroundOpacity(scratchpadBackgroundOpacity) },
            set: { scratchpadBackgroundOpacity = ScratchpadSupport.sanitizedBackgroundOpacity($0) }
        )
    }
}
