// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import SwiftUI

/// Auto-quit configuration remains editable before its watcher is enabled.
struct AutoQuitSections: View {
    @ObservedObject private var l10n = L10n.shared
    @ObservedObject private var permissions = Permissions.shared
    @ObservedObject private var service = AutoQuitService.shared
    @AppStorage(DefaultsKey.autoQuitEnabled) private var enabled = false
    @State private var showingAppPicker = false

    var body: some View {
        Group {
            SettingsSection {
                VStack(alignment: .leading, spacing: 4) {
                    FeatureSwitchRow(feature: .autoQuit)
                    SettingsCaptionText(l10n.s.autoQuitEnableCaption)
                }
                if enabled, !permissions.accessibility {
                    PermissionRow(kind: .accessibility)
                }
                if enabled, service.isRunning {
                    Label(l10n.s.autoQuitActiveNow, systemImage: "checkmark.circle.fill")
                        .font(SettingsTypography.caption)
                        .foregroundStyle(.green)
                }
                bullet("rectangle.badge.xmark", l10n.s.autoQuitStep1)
                bullet("bolt.fill", l10n.s.autoQuitStep2)
                Text(l10n.s.autoQuitPredictableNote)
                    .font(SettingsTypography.caption)
                    .foregroundStyle(.secondary)
                Text(l10n.s.autoQuitExceptionsTitle).font(SettingsTypography.sectionTitle)
                    .accessibilityAddTraits(.isHeader)
                if sortedExceptions.isEmpty {
                    Text(l10n.s.autoQuitExceptionsEmpty)
                        .font(SettingsTypography.body)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(sortedExceptions, id: \.self) { bundleID in
                        AppBundleRow(bundleID: bundleID) {
                            if service.isMandatoryException(bundleID) {
                                Image(systemName: "lock.fill")
                                    .font(SettingsTypography.icon)
                                    .foregroundStyle(.tertiary)
                                    .frame(width: 24, height: 24)
                                    .help(UXEntryStrings(l10n.language).mandatoryException)
                                    .accessibilityLabel(UXEntryStrings(l10n.language).mandatoryException)
                            } else {
                                AppBundleRemoveButton(label: String(format: UXEntryStrings(l10n.language).removeFromListFormat,
                                                                         InstalledApps.name(for: bundleID))) {
                                    service.removeException(bundleID)
                                }
                            }
                        }
                    }
                }

                Button {
                    showingAppPicker = true
                } label: {
                    Label(l10n.s.autoQuitAddApp, systemImage: "plus")
                }

                Text(l10n.s.autoQuitExceptionsCaption)
                    .font(SettingsTypography.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .sheet(isPresented: $showingAppPicker) {
            appPickerSheet
        }
    }

    private var sortedExceptions: [String] {
        AutoQuitSupport.visibleExceptions(service.exceptions) {
            InstalledApps.url(for: $0) != nil
        }
        .sorted {
            InstalledApps.name(for: $0).localizedCaseInsensitiveCompare(InstalledApps.name(for: $1))
                == .orderedAscending
        }
    }

    private var appPickerSheet: some View {
        let excluded = Set(service.exceptions)
        return AppPickerView {
            showingAppPicker = false
        } onSelect: { url in
            showingAppPicker = false
            guard let bundleID = Bundle(url: url)?.bundleIdentifier else { return }
            service.addException(bundleID)
        } loadApps: {
            InstalledApps.installedBundleApplications(excluding: excluded)
        }
    }

    private func bullet(_ icon: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundStyle(.tint)
                .frame(width: 18)
            Text(text)
                .font(SettingsTypography.body)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
