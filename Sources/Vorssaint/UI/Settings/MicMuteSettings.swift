// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import SwiftUI

struct MicMuteSettings: View {
    @ObservedObject private var l10n = L10n.shared
    @ObservedObject private var features = FeatureRuntime.shared
    @ObservedObject private var micMute = MicMuteService.shared
    @AppStorage(DefaultsKey.micMuteShortcutEnabled) private var micShortcutEnabled = false

    private var micMuteText: MicMuteFeatureStrings { FeatureStrings.micMute(l10n.language) }

    var body: some View {
        Form {
            if AppFeature.micMute.isAvailable {
                Section {
                    Button {
                        MicMuteService.shared.toggle()
                    } label: {
                        Label(micMute.isMuted ? micMuteText.unmuteName : AppFeature.micMute.name(l10n.s, language: l10n.language),
                              systemImage: micMute.isMuted ? "mic.slash.fill" : "mic")
                    }
                    if micMute.isMuted {
                        Label(micMuteText.mutedHUD, systemImage: "mic.slash.fill")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                    Text(micMuteText.caption)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Toggle(l10n.s.quickToolShortcutToggle, isOn: $micShortcutEnabled)
                        .onChange(of: micShortcutEnabled) { _, _ in
                            MicMuteService.shared.syncWithPreferences()
                        }
                    ShortcutPreferenceRow(role: .micMute,
                                          isEnabled: micShortcutEnabled) {
                        MicMuteService.shared.syncWithPreferences()
                    }
                    if micShortcutEnabled, micMute.shortcutRegistrationFailed {
                        Text(l10n.s.shortcutUnavailable)
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                } header: {
                    Text(AppFeature.micMute.name(l10n.s, language: l10n.language))
                }
                .settingsSectionAnchor(.micMute)
            }
        }
        .formStyle(.grouped)
    }
}
