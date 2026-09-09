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
        Form {
            if AppFeature.scratchpad.isAvailable {
                Section {
                    Button {
                        ScratchpadService.shared.show()
                    } label: {
                        Label(FeatureStrings.scratchpad(l10n.language).openButton,
                              systemImage: "note.text")
                    }
                    Text(FeatureStrings.scratchpad(l10n.language).panelCaption)
                        .font(.caption)
                        .foregroundStyle(.secondary)
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
                    Text(FeatureStrings.scratchpad(l10n.language).retentionCaption)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Toggle(FeatureStrings.scratchpad(l10n.language).closeOnClickOutside,
                           isOn: $scratchpadCloseOnClickOutside)
                        .onChange(of: scratchpadCloseOnClickOutside) { _, _ in
                            ScratchpadService.shared.outsideClickPreferenceDidChange()
                        }
                    VStack(alignment: .leading, spacing: 6) {
                        Text(FeatureStrings.scratchpad(l10n.language).backgroundOpacity)
                        Slider(value: scratchpadBackgroundOpacityBinding,
                               in: ScratchpadSupport.backgroundOpacityRange,
                               step: 0.05)
                        HStack {
                            Text(FeatureStrings.scratchpad(l10n.language).backgroundTranslucent)
                            Spacer()
                            Text(FeatureStrings.scratchpad(l10n.language).backgroundOpaque)
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
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
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                } header: {
                    Text(AppFeature.scratchpad.name(l10n.s, language: l10n.language))
                }
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
