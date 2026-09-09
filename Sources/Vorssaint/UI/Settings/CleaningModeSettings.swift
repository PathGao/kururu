// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import SwiftUI

struct CleaningModeSettings: View {
    @ObservedObject private var l10n = L10n.shared
    @ObservedObject private var features = FeatureRuntime.shared
    @AppStorage(DefaultsKey.cleaningModeKeepScreenVisible) private var cleaningModeKeepScreenVisible = false

    var body: some View {
        Form {
            if AppFeature.cleaningMode.isAvailable {
                Section {
                    Button {
                        CleaningModeManager.shared.activate()
                    } label: {
                        Label(l10n.s.cleaningStartNow, systemImage: "bubbles.and.sparkles")
                    }
                    Text(l10n.s.cleaningPanelCaption)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Toggle(l10n.s.cleaningKeepScreenVisibleToggle, isOn: $cleaningModeKeepScreenVisible)
                    Text(l10n.s.cleaningKeepScreenVisibleCaption)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } header: {
                    Text(AppFeature.cleaningMode.name(l10n.s, language: l10n.language))
                }
                .settingsSectionAnchor(.cleaningMode)
            }
        }
        .formStyle(.grouped)
    }
}
