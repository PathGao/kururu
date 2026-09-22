// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import SwiftUI

struct CameraPreviewSettings: View {
    @ObservedObject private var l10n = L10n.shared
    @ObservedObject private var features = FeatureRuntime.shared
    @ObservedObject private var permissions = Permissions.shared
    @ObservedObject private var cameraPreview = CameraPreviewService.shared
    @AppStorage(DefaultsKey.cameraPreviewShortcutEnabled) private var cameraShortcutEnabled = false

    private var strings: CameraPreviewFeatureStrings {
        FeatureStrings.cameraPreview(l10n.language)
    }

    var body: some View {
        SettingsForm {
            if AppFeature.cameraPreview.isAvailable {
                SettingsSection(title: UXEntryStrings(l10n.language).activationAndShortcuts,
                                systemImage: "keyboard") {
                    SettingsControlRow(title: AppFeature.cameraPreview.name(l10n.s, language: l10n.language),
                                       systemImage: AppFeature.cameraPreview.symbolName,
                                       caption: strings.panelCaption) {
                        Button(strings.openButton) {
                            CameraPreviewService.shared.show()
                        }
                        .settingsAction(.primary)
                    }
                    Toggle(l10n.s.quickToolShortcutToggle, isOn: $cameraShortcutEnabled)
                        .onChange(of: cameraShortcutEnabled) { _, _ in
                            CameraPreviewService.shared.syncWithPreferences()
                        }
                    ShortcutPreferenceRow(role: .cameraPreview,
                                          isEnabled: cameraShortcutEnabled) {
                        CameraPreviewService.shared.syncWithPreferences()
                    }
                    if cameraShortcutEnabled, cameraPreview.shortcutRegistrationFailed {
                        Text(l10n.s.shortcutUnavailable)
                            .font(SettingsTypography.caption)
                            .foregroundStyle(.orange)
                    }
                }
                // Only when it is actually in the way: the hub's permission
                // portal is where the grant normally lives.
                if permissions.camera == .denied {
                    SettingsSection(title: strings.permName, systemImage: "camera") {
                        SettingsControlRow(title: strings.permName,
                                           systemImage: "exclamationmark.circle.fill",
                                           caption: l10n.s.permissionMissing) {
                            Button(l10n.s.permissionOpenSettings) {
                                Permissions.shared.openCameraSettings()
                            }
                        }
                        SettingsExplanation(strings.permExplain)
                    }
                }
            }
        }
        .formStyle(.grouped)
    }
}
