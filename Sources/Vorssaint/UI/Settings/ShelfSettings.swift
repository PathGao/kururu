// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import SwiftUI

struct ShelfSettings: View {
    @ObservedObject private var l10n = L10n.shared
    @ObservedObject private var shelf = ShelfService.shared
    @AppStorage(DefaultsKey.shelfEnabled) private var enabled = false
    @AppStorage(DefaultsKey.shelfShortcutEnabled) private var shortcutEnabled = true
    @AppStorage(DefaultsKey.shelfShakeToOpen) private var shake = true
    @AppStorage(DefaultsKey.shelfDropZoneEnabled) private var dropZone = true
    @AppStorage(DefaultsKey.shelfDockPlacement) private var dockPlacement = "menuBar"
    @AppStorage(DefaultsKey.shelfEdgeDragEnabled) private var edgeDrag = false
    @AppStorage(DefaultsKey.shelfCloseAfterDrop) private var closeAfterDrop = false
    @AppStorage(DefaultsKey.shelfRemoveAfterDrop) private var removeAfterDrop = true
    @AppStorage(DefaultsKey.shelfClearOnClose) private var clearOnClose = false
    @State private var showingAppPicker = false

    var body: some View {
        let placementText = ShelfDockPlacementStrings.text(l10n.language)
        SettingsForm {
            if let issue = shelf.persistenceIssue {
                SettingsSection {
                    ShelfPersistenceNotice(issue: issue, isSaving: shelf.isSaving,
                                           strings: .text(l10n.language), onRetry: { shelf.retryPersistence() })
                }
            }
            SettingsSection {
                Toggle(l10n.s.shelfEnable, isOn: $enabled)
                    .onChange(of: enabled) { _, _ in
                        ShelfService.shared.syncWithPreferences()
                    }
                Text(l10n.s.shelfEnableCaption)
                    .font(SettingsTypography.caption)
                    .foregroundStyle(.secondary)
                Label(l10n.s.shelfNoPermission, systemImage: "checkmark.shield")
                    .font(SettingsTypography.caption)
                    .foregroundStyle(.secondary)
                Button {
                    ShelfService.shared.summon()
                } label: {
                    Label(l10n.s.shelfOpenNow, systemImage: "tray.and.arrow.down")
                }
                .settingsAction(.primary)
                .disabled(!enabled)
            }

            SettingsSection(l10n.s.shelfHowTitle) {
                bullet("1", l10n.s.shelfStep1)
                bullet("2", l10n.s.shelfStep2)
                bullet("3", l10n.s.shelfStep3)
            }

            Group {
                SettingsSection(title: UXEntryStrings(l10n.language).activationAndShortcuts,
                                systemImage: "hand.tap") {
                    Toggle(l10n.s.shelfShortcutToggle, isOn: $shortcutEnabled)
                        .onChange(of: shortcutEnabled) { _, _ in
                            ShelfService.shared.syncHotkey()
                        }
                    ShortcutPreferenceRow(role: .shelf, isEnabled: shortcutEnabled) {
                        ShelfService.shared.syncHotkey()
                    }
                    if enabled, shortcutEnabled, shelf.hotkeyRegistrationFailed {
                        Text(l10n.s.shortcutUnavailable)
                            .font(SettingsTypography.caption)
                            .foregroundStyle(.orange)
                    }
                    VStack(alignment: .leading, spacing: 3) {
                        Toggle(l10n.s.shelfShakeToggle, isOn: $shake)
                            .onChange(of: shake) { _, _ in
                                ShelfService.shared.syncDragMonitor()
                            }
                        Text(l10n.s.shelfShakeCaption)
                            .font(SettingsTypography.caption)
                            .foregroundStyle(.secondary)
                    }
                    VStack(alignment: .leading, spacing: 3) {
                        Toggle(ShelfDockPlacement.normalized(dockPlacement) == .topCenter
                               ? placementText.topToggle : l10n.s.shelfDropZoneToggle, isOn: $dropZone)
                            .onChange(of: dropZone) { _, _ in
                                ShelfService.shared.syncDragMonitor()
                            }
                        Picker(placementText.position, selection: $dockPlacement) {
                            Text(placementText.menuBar).tag("menuBar")
                            Text(placementText.topCenter).tag("topCenter")
                        }
                        .onChange(of: dockPlacement) { _, _ in
                            shelf.syncDockedPresentation()
                        }
                        Text(ShelfDockPlacement.normalized(dockPlacement) == .topCenter
                             ? placementText.topCaption : l10n.s.shelfDropZoneCaption)
                            .font(SettingsTypography.caption)
                            .foregroundStyle(.secondary)
                    }
                    VStack(alignment: .leading, spacing: 3) {
                        Toggle(l10n.s.shelfEdgeToggle, isOn: $edgeDrag)
                            .onChange(of: edgeDrag) { _, _ in
                                ShelfService.shared.syncDragMonitor()
                            }
                        Text(l10n.s.shelfEdgeCaption)
                            .font(SettingsTypography.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                SettingsSection(l10n.s.shelfBehaviorTitle) {
                    VStack(alignment: .leading, spacing: 3) {
                        Toggle(l10n.s.shelfCloseAfterDrop, isOn: $closeAfterDrop)
                        Text(l10n.s.shelfCloseAfterDropCaption)
                            .font(SettingsTypography.caption)
                            .foregroundStyle(.secondary)
                    }
                    VStack(alignment: .leading, spacing: 3) {
                        Toggle(l10n.s.shelfRemoveAfterDrop, isOn: $removeAfterDrop)
                        Text(l10n.s.shelfRemoveAfterDropCaption)
                            .font(SettingsTypography.caption)
                            .foregroundStyle(.secondary)
                    }
                    VStack(alignment: .leading, spacing: 3) {
                        Toggle(l10n.s.shelfClearOnClose, isOn: $clearOnClose)
                        Text(l10n.s.shelfClearOnCloseCaption)
                            .font(SettingsTypography.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                SettingsSection(l10n.s.shelfExclusionsTitle) {
                    if sortedExclusions.isEmpty {
                        Text(l10n.s.shelfExclusionsEmpty)
                            .font(SettingsTypography.body)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(sortedExclusions, id: \.self) { bundleID in
                            AppBundleRow(bundleID: bundleID) {
                                AppBundleRemoveButton(label: String(format: UXEntryStrings(l10n.language).removeFromListFormat,
                                                                         InstalledApps.name(for: bundleID))) {
                                    shelf.removeAutomaticExclusion(bundleID)
                                }
                            }
                        }
                    }
                    Button {
                        showingAppPicker = true
                    } label: {
                        Label(l10n.s.autoQuitAddApp, systemImage: "plus")
                    }
                    Text(l10n.s.shelfExclusionsCaption)
                        .font(SettingsTypography.caption)
                        .foregroundStyle(.secondary)
                }
            }
            ShelfImportSettings()
        }
        .formStyle(.grouped)
        .sheet(isPresented: $showingAppPicker) {
            appPickerSheet
        }
    }

    private var sortedExclusions: [String] {
        shelf.automaticExclusions.sorted {
            InstalledApps.name(for: $0)
                .localizedCaseInsensitiveCompare(InstalledApps.name(for: $1)) == .orderedAscending
        }
    }

    private var appPickerSheet: some View {
        let excluded = Set(shelf.automaticExclusions)
        return AppPickerView {
            showingAppPicker = false
        } onSelect: { url in
            showingAppPicker = false
            guard let bundleID = Bundle(url: url)?.bundleIdentifier else { return }
            shelf.addAutomaticExclusion(bundleID)
        } loadApps: {
            InstalledApps.installedBundleApplications(excluding: excluded)
        }
    }

    private func bullet(_ number: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text(number)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .frame(width: 18, height: 18)
                .background(Circle().fill(Color.accentColor))
            Text(text)
                .font(SettingsTypography.body)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
