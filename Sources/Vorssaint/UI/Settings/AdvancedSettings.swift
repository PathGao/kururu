// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import SwiftUI

struct AdvancedSettings: View {
    @ObservedObject private var l10n = L10n.shared
    @ObservedObject private var appearance = AppAppearanceController.shared
    @State private var launchAtLogin = LaunchAtLogin.isEnabled
    @State private var loginError: String?
    @State private var showClearConfirm = false
    @State private var showUninstallConfirm = false
    @State private var uninstallFailed = false
    @State private var uninstallFailure: SelfUninstall.Failure?
    @State private var working = false
    @State private var clearingPermissions = false
    @State private var cleared = false
    @State private var exportResult: SettingsBackupExport?
    @State private var clearResult: PermissionResetResult?
    @State private var importFailed = false
    @State private var pendingImport: [String: Any]?
    @State private var showImportConfirm = false

    private var hierarchy: SettingsHierarchyStrings { SettingsHierarchyStrings(language: l10n.language) }

    private var actionText: SettingsActionStrings { SettingsActionStrings(language: l10n.language) }

    private var backup: BackupFeatureStrings {
        FeatureStrings.backup(l10n.language)
    }

    private var appearanceStrings: AppearanceStrings { FeatureStrings.appearance(l10n.language) }

    var body: some View {
        SettingsForm {
            SettingsSection(hierarchy.general) {
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
                        .font(SettingsTypography.caption)
                        .foregroundStyle(.red)
                }
                Picker(l10n.s.languageLabel, selection: $l10n.language) {
                    ForEach(AppLanguage.allCases) { language in
                        Text(language.displayName).tag(language)
                    }
                }
            }
            SettingsSection(appearanceStrings.label) {
                Picker(appearanceStrings.label, selection: $appearance.appearance) {
                    ForEach(AppAppearance.allCases) { option in
                        Text(option.title(appearanceStrings)).tag(option)
                    }
                }
                .pickerStyle(.segmented)
            }
            SettingsSection(hierarchy.maintenance) {
                VStack(alignment: .leading, spacing: 12) {
                    Text(backup.title).font(.headline)
                    SettingsExplanation(backup.description)
                    ViewThatFits(in: .horizontal) {
                        HStack(spacing: 10) { backupActions }
                            .fixedSize(horizontal: true, vertical: false)
                        VStack(alignment: .leading, spacing: 10) { backupActions }
                    }
                    if exportResult == .saved {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                            Text(backup.exported).font(SettingsTypography.caption).foregroundStyle(.green)
                        }
                    }
                    if case let .failed(reason) = exportResult {
                        Text("\(actionText.exportFailed)\n\(reason)")
                            .font(SettingsTypography.caption)
                            .foregroundStyle(.orange)
                            .textSelection(.enabled)
                    }
                    if importFailed {
                        Text(backup.invalidFile)
                            .font(SettingsTypography.caption)
                            .foregroundStyle(.orange)
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text(l10n.s.advancedResetSection).font(.headline)
                    SettingsExplanation(l10n.s.advancedResetDescription)
                    Button(role: .destructive) {
                        showClearConfirm = true
                    } label: {
                        Label(l10n.s.advancedClearButton, systemImage: "lock.slash")
                    }
                    .disabled(working)
                    if clearingPermissions { ProgressView().controlSize(.small) }
                    if let clearResult, clearResult != .completed {
                        Text(actionText.permissionFailure(clearResult))
                            .font(SettingsTypography.caption)
                            .foregroundStyle(.orange)
                    }
                    if cleared {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                            Text(l10n.s.advancedCleared).font(SettingsTypography.caption).foregroundStyle(.green)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text(l10n.s.advancedUninstallSection).font(.headline)
                    SettingsExplanation(l10n.s.advancedUninstallDescription)
                    Button(role: .destructive) {
                        showUninstallConfirm = true
                    } label: {
                        Label(l10n.s.advancedUninstallButton, systemImage: "trash")
                    }
                    .disabled(working)
                }
            }
        }
        .formStyle(.grouped)
        .alert(l10n.s.advancedClearConfirmTitle, isPresented: $showClearConfirm) {
            Button(l10n.s.uninstallerCancel, role: .cancel) {}
            Button(l10n.s.advancedClearButton, role: .destructive) {
                working = true
                clearingPermissions = true
                cleared = false
                clearResult = nil
                SelfUninstall.clearPermissions { result in
                    working = false
                    clearingPermissions = false
                    clearResult = result
                    cleared = result == .completed
                }
            }
        } message: {
            Text(l10n.s.advancedClearConfirmBody)
        }
        .alert(l10n.s.advancedUninstallConfirmTitle, isPresented: $showUninstallConfirm) {
            Button(l10n.s.uninstallerCancel, role: .cancel) {}
            Button(l10n.s.advancedUninstallButton, role: .destructive) {
                working = true
                SelfUninstall.uninstallCompletely { failure in
                    working = false
                    uninstallFailure = failure
                    uninstallFailed = true
                }
            }
        } message: {
            Text(l10n.s.advancedUninstallConfirmBody)
        }
        .alert(l10n.s.advancedUninstallFailedTitle, isPresented: $uninstallFailed) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(uninstallFailure.map(actionText.uninstallFailure) ?? l10n.s.advancedUninstallFailedBody)
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

    @ViewBuilder
    private var backupActions: some View {
        Button {
            importFailed = false
            exportResult = SettingsBackup.runExportPanel()
        } label: {
            Label(backup.exportButton, systemImage: "square.and.arrow.up")
        }
        Button {
            exportResult = nil
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

}
