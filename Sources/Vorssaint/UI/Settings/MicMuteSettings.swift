// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import SwiftUI

struct MicMuteSettings: View {
    @ObservedObject private var l10n = L10n.shared
    @ObservedObject private var features = FeatureRuntime.shared
    @ObservedObject private var micMute = MicMuteService.shared
    @AppStorage(DefaultsKey.micMuteShortcutEnabled) private var micShortcutEnabled = false

    private var micMuteText: MicMuteFeatureStrings { FeatureStrings.micMute(l10n.language) }

    private func retryDirection(for result: MicMuteResult) -> Bool? {
        switch result {
        case let .partial(muting, _, _), let .failed(muting): return muting
        case .noDevices: return micMute.isMuteRequested
        case .muted, .unmuted: return nil
        }
    }

    var body: some View {
        SettingsForm {
            if AppFeature.micMute.isAvailable {
                SettingsSection {
                    Button {
                        MicMuteService.shared.toggle()
                    } label: {
                        Label(micMuteText.actionTitle(isMuteRequested: micMute.isMuteRequested, result: micMute.lastResult),
                              systemImage: MicMuteBatchSupport.toggleTarget(isMuteRequested: micMute.isMuteRequested, lastResult: micMute.lastResult) ? "mic.slash.fill" : "mic")
                    }
                    .disabled(micMute.isApplying)
                    if micMute.isApplying {
                        Label(micMuteText.applyingStatus, systemImage: "arrow.triangle.2.circlepath")
                            .font(SettingsTypography.caption).foregroundStyle(.secondary)
                    } else if let result = micMute.lastResult {
                        Label(micMuteText.resultMessage(for: result), systemImage: micMuteText.resultSymbol(for: result))
                            .font(SettingsTypography.caption)
                            .foregroundStyle(retryDirection(for: result) == nil ? Color.secondary : Color.orange)
                        if !micMute.failedDeviceNames.isEmpty {
                            Text(micMuteText.failedDevices + micMute.failedDeviceNames.joined(separator: ", "))
                                .font(SettingsTypography.caption).foregroundStyle(.secondary)
                                .textSelection(.enabled)
                        }
                        if let muting = retryDirection(for: result) {
                            Button(micMuteText.retryTitle(muting: muting)) {
                                micMute.setMuted(muting)
                            }
                        }
                    }
                    Text(micMuteText.caption)
                        .font(SettingsTypography.caption)
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
                            .font(SettingsTypography.caption)
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
