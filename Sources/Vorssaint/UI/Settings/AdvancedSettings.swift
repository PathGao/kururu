// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import SwiftUI

/// Advanced page: a clean way to reset every permission the app holds, and a
/// full self-uninstall. Both actions are confirmation-gated and scoped entirely
/// to this app (see `SelfUninstall`).
struct AdvancedSettings: View {
    @ObservedObject private var l10n = L10n.shared
    @ObservedObject private var appearance = AppAppearanceController.shared
    @State private var launchAtLogin = LaunchAtLogin.isEnabled
    @State private var loginError: String?
    @State private var showClearConfirm = false
    @State private var showUninstallConfirm = false
    @State private var uninstallFailed = false
    @State private var working = false
    @State private var cleared = false
    @State private var exported = false
    @State private var importFailed = false
    @State private var pendingImport: [String: Any]?
    @State private var showImportConfirm = false

    private var backup: BackupFeatureStrings {
        FeatureStrings.backup(l10n.language)
    }

    private var appearanceStrings: AppearanceStrings { FeatureStrings.appearance(l10n.language) }

    var body: some View {
        Form {
            Section {
                Toggle(l10n.s.launchAtLogin, isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, enabled in
                        do {
                            try LaunchAtLogin.setEnabled(enabled)
                            loginError = nil
                        } catch {
                            loginError = error.localizedDescription
                            launchAtLogin = LaunchAtLogin.isEnabled
                        }
                    }
                    .onAppear { launchAtLogin = LaunchAtLogin.isEnabled }
                if let loginError {
                    Text(loginError)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
                Picker(l10n.s.languageLabel, selection: $l10n.language) {
                    ForEach(AppLanguage.allCases) { language in
                        Text(language.displayName).tag(language)
                    }
                }
                Picker(appearanceStrings.label, selection: $appearance.appearance) {
                    ForEach(AppAppearance.allCases) { option in
                        Text(option.title(appearanceStrings)).tag(option)
                    }
                }
                .pickerStyle(.segmented)
#if compiler(>=6.2)
                if #available(macOS 26.0, *) {
                    Toggle(appearanceStrings.liquidGlass, isOn: $appearance.liquidGlassEnabled)
                }
#endif
            }
            Section(backup.title) {
                Text(backup.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: 10) {
                    Button {
                        importFailed = false
                        exported = SettingsBackup.runExportPanel() == true
                    } label: {
                        Label(backup.exportButton, systemImage: "square.and.arrow.up")
                    }
                    Button {
                        exported = false
                        importFailed = false
                        guard let url = SettingsBackup.runImportPanel() else { return }
                        if let settings = SettingsBackup.readSettings(at: url) {
                            pendingImport = settings
                            showImportConfirm = true
                        } else {
                            importFailed = true
                        }
                    } label: {
                        Label(backup.importButton, systemImage: "square.and.arrow.down")
                    }
                }
                if exported {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                        Text(backup.exported).font(.caption).foregroundStyle(.green)
                    }
                }
                if importFailed {
                    Text(backup.invalidFile)
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }

            Section(l10n.s.advancedResetSection) {
                Text(l10n.s.advancedResetDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                Button(role: .destructive) {
                    showClearConfirm = true
                } label: {
                    Label(l10n.s.advancedClearButton, systemImage: "lock.slash")
                }
                .disabled(working)
                if cleared {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                        Text(l10n.s.advancedCleared).font(.caption).foregroundStyle(.green)
                    }
                }
            }

            Section(l10n.s.advancedUninstallSection) {
                Text(l10n.s.advancedUninstallDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                Button(role: .destructive) {
                    showUninstallConfirm = true
                } label: {
                    Label(l10n.s.advancedUninstallButton, systemImage: "trash")
                }
                .disabled(working)
            }
        }
        .formStyle(.grouped)
        .alert(l10n.s.advancedClearConfirmTitle, isPresented: $showClearConfirm) {
            Button(l10n.s.uninstallerCancel, role: .cancel) {}
            Button(l10n.s.advancedClearButton, role: .destructive) {
                working = true
                cleared = false
                SelfUninstall.clearPermissions {
                    working = false
                    cleared = true
                }
            }
        } message: {
            Text(l10n.s.advancedClearConfirmBody)
        }
        .alert(l10n.s.advancedUninstallConfirmTitle, isPresented: $showUninstallConfirm) {
            Button(l10n.s.uninstallerCancel, role: .cancel) {}
            Button(l10n.s.advancedUninstallButton, role: .destructive) {
                working = true
                SelfUninstall.uninstallCompletely {
                    working = false
                    // Stopping leaves the Mac exactly as it was, so the only
                    // thing left to do is say so: the button going quiet on
                    // its own reads as the app ignoring the request.
                    uninstallFailed = true
                }
            }
        } message: {
            Text(l10n.s.advancedUninstallConfirmBody)
        }
        .alert(l10n.s.advancedUninstallFailedTitle, isPresented: $uninstallFailed) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(l10n.s.advancedUninstallFailedBody)
        }
        .alert(backup.importConfirmTitle, isPresented: $showImportConfirm) {
            Button(l10n.s.uninstallerCancel, role: .cancel) { pendingImport = nil }
            Button(backup.importAction) {
                if let pendingImport {
                    SettingsBackup.applyAndRelaunch(settings: pendingImport)
                }
            }
        } message: {
            Text(backup.importConfirmBody)
        }
    }
}
