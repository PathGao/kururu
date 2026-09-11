// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import SwiftUI

struct CutPasteSettings: View {
    @ObservedObject private var l10n = L10n.shared
    @ObservedObject private var features = FeatureRuntime.shared
    @ObservedObject private var permissions = Permissions.shared
    @ObservedObject private var service = FinderCutPaste.shared
    @AppStorage(DefaultsKey.finderCutPasteEnabled) private var enabled = false
    @AppStorage(DefaultsKey.finderCutPasteShowHUD) private var showHUD = true
    @AppStorage(DefaultsKey.finderPasteImageAsFile) private var pasteImageAsFile = false
    @AppStorage(DefaultsKey.finderRenameEnabled) private var renameEnabled = false
    @AppStorage(DefaultsKey.finderRenameShortcut) private var renameShortcutRaw =
        GlobalShortcut.finderRenameDefault.storageValue
    @StateObject private var arrangement = FinderArrangementService()
    @State private var renameError: String?
    @State private var recordingRename = false

    private var renameText: FinderRenameFeatureStrings {
        FeatureStrings.finderRename(l10n.language)
    }

    private var renameShortcut: GlobalShortcut {
        GlobalShortcut(storageValue: renameShortcutRaw) ?? .finderRenameDefault
    }

    private var needsAccessibility: Bool {
        (AppFeature.finderCutPaste.isAvailable && enabled)
            || (AppFeature.finderRename.isAvailable && renameEnabled)
    }

    var body: some View {
        SettingsForm {
            if AppFeature.finderCutPaste.isAvailable {
                SettingsSection {
                    SettingsToggleWithCaption(title: l10n.s.cutPasteEnable,
                                              caption: l10n.s.cutPasteEnableCaption,
                                              isOn: $enabled)
                        .onChange(of: enabled) { _, _ in
                            FinderCutPaste.shared.syncWithPreferences()
                        }
                    Group {
                        SettingsToggleWithCaption(title: l10n.s.cutPasteShowHUD,
                                                  caption: l10n.s.cutPasteShowHUDCaption,
                                                  isOn: $showHUD)
                            .onChange(of: showHUD) { _, _ in
                                FinderCutPaste.shared.syncWithPreferences()
                            }
                    }
                    if enabled, service.isRunning {
                        Label(l10n.s.cutPasteActiveNow, systemImage: "checkmark.circle.fill")
                            .font(SettingsTypography.caption)
                            .foregroundStyle(.green)
                    }
                    Divider()
                    Text(l10n.s.cutPasteHowTitle).font(SettingsTypography.sectionTitle)
                        .accessibilityAddTraits(.isHeader)
                    howRow(keys: ["⌘", "X"], text: l10n.s.cutPasteStep1)
                    howRow(keys: ["⌘", "V"], text: l10n.s.cutPasteStep2)
                    Text(l10n.s.cutPasteTextNote)
                        .font(SettingsTypography.caption)
                        .foregroundStyle(.secondary)
                    Divider()
                    SettingsToggleWithCaption(title: FeatureStrings.clipboard(l10n.language).pasteImageAsFile,
                                              caption: FeatureStrings.clipboard(l10n.language).pasteImageAsFileCaption,
                                              isOn: $pasteImageAsFile)
                        .onChange(of: pasteImageAsFile) { _, _ in
                            FinderCutPaste.shared.syncWithPreferences()
                        }
                    if pasteImageAsFile, !permissions.accessibility {
                        PermissionRow(kind: .accessibility)
                    }
                }
                .settingsSectionAnchor(.finderCutPaste)
            }

            if AppFeature.finderRename.isAvailable {
                SettingsSection {
                    VStack(alignment: .leading, spacing: 4) {
                        FeatureSwitchRow(feature: .finderRename)
                        SettingsCaptionText(renameText.caption)
                    }
                    SettingsControlRow(title: renameText.shortcutLabel, systemImage: "keyboard") {
                        ShortcutRecorderButton(
                            shortcut: renameShortcut,
                            isEnabled: true,
                            waitingTitle: l10n.s.shortcutPressKeys,
                            notCapturedAction: { renameError = l10n.s.shortcutNotCaptured },
                            recordingChanged: { recording in
                                recordingRename = recording
                                if recording { renameError = nil }
                            },
                            invalidAction: { renameError = l10n.s.shortcutInvalid },
                            captureAction: saveRenameShortcut
                        )
                        .frame(width: 108)
                        Button(l10n.s.shortcutReset) {
                            renameShortcutRaw = GlobalShortcut.finderRenameDefault.storageValue
                            renameError = nil
                            FinderRenameService.shared.syncWithPreferences()
                        }
                        .disabled(renameShortcut == .finderRenameDefault)
                    }
                    if let renameError {
                        Text(renameError)
                            .font(SettingsTypography.caption)
                            .foregroundStyle(.orange)
                    } else if recordingRename {
                        Text(ShortcutRecordingCaption.text(l10n.s, canClear: false))
                            .font(SettingsTypography.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .settingsSectionAnchor(.finderRename)
            }

            if AppFeature.finderCutPaste.isAvailable || AppFeature.finderRename.isAvailable {
                arrangementSection
            }

            if needsAccessibility, !permissions.accessibility {
                SettingsSection(l10n.s.permissionRequired) {
                    PermissionRow(kind: .accessibility)
                    if AppFeature.finderCutPaste.isAvailable, enabled {
                        Text(l10n.s.cutPasteAutomationNote)
                            .font(SettingsTypography.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .onChange(of: l10n.language) { _, _ in renameError = nil }
    }

    private var arrangementSection: some View {
        let text = FinderArrangementStrings.localized(l10n.language)
        return SettingsSection(text.title) {
            Text(text.caption).font(SettingsTypography.caption).foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            HStack {
                Button(text.choose) { chooseArrangementFolder() }
                Button(text.current) { arrangement.capture() }
            }
            if let snapshot = arrangement.snapshot {
                HStack(alignment: .top, spacing: 10) {
                    SettingsSymbol(systemImage: "folder")
                    VStack(alignment: .leading, spacing: 4) {
                        Text(snapshot.path).textSelection(.enabled)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(text.rule(snapshot.rule))
                            .font(SettingsTypography.caption).foregroundStyle(.secondary)
                    }
                }
                HStack(spacing: 8) {
                    Button(text.apply) { arrangement.apply() }
                        .settingsAction(.primary)
                        .disabled(snapshot.rule == .name)
                    if arrangement.originalRule != nil {
                        Button(text.restore) { arrangement.restore() }
                    }
                }
                Text(text.restoreNote).font(SettingsTypography.caption).foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if arrangement.isBusy {
                Text(text.busy).font(SettingsTypography.caption)
            } else if let failure = arrangement.failure {
                Text(text.failure(failure)).font(SettingsTypography.caption).foregroundStyle(.orange)
                    .fixedSize(horizontal: false, vertical: true)
            } else if arrangement.completed {
                Label(text.done, systemImage: "checkmark.circle").font(SettingsTypography.caption)
            }
        }
        .disabled(arrangement.isBusy)
    }

    private func chooseArrangementFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = false
        guard panel.runModal() == .OK, let url = panel.url else { return }
        arrangement.select(url)
    }

    private func howRow(keys: [String], text: String) -> some View {
        HStack(spacing: 10) {
            ShortcutCaps(keys: keys)
                .frame(width: 56, alignment: .leading)
            Text(text)
                .font(.callout)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func saveRenameShortcut(_ shortcut: GlobalShortcut) {
        if let conflict = GlobalShortcutRole.conflict(for: shortcut, excluding: .finderRename,
                                                  hasClipboardHistory: { !ClipboardHistoryService.shared.entries.isEmpty }) {
            renameError = String(format: l10n.s.shortcutConflictFormat, conflict.title(l10n.s))
            return
        }
        if shortcut.conflictsWithSystemShortcut {
            renameError = String(format: l10n.s.shortcutConflictFormat, "macOS")
            return
        }
        renameShortcutRaw = shortcut.storageValue
        renameError = nil
        FinderRenameService.shared.syncWithPreferences()
    }
}
