// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import AppKit
import SwiftUI

struct MusicBlockSettings: View {
    @ObservedObject private var l10n = L10n.shared
    @ObservedObject private var features = FeatureRuntime.shared
    @AppStorage(DefaultsKey.musicBlockEnabled) private var musicBlockEnabled = false
    @AppStorage(DefaultsKey.musicBlockReplacementPath) private var musicBlockReplacementPath = ""

    @State private var blockedApps = MusicLaunchBlocker.blockedBundleIDs

    @State private var replacementNotice: String?
    private var actionText: SettingsActionStrings { SettingsActionStrings(language: l10n.language) }

    private var musicBlockText: MusicBlockFeatureStrings { FeatureStrings.musicBlock(l10n.language) }

    var body: some View {
        SettingsForm {
            if AppFeature.musicBlock.isAvailable {
                SettingsSection(musicBlockText.section) {
                    Toggle(musicBlockText.title, isOn: $musicBlockEnabled)
                        .onChange(of: musicBlockEnabled) { _, _ in
                            MusicLaunchBlocker.shared.syncWithPreferences()
                        }
                    if musicBlockEnabled {
                        AppBundleList(title: musicBlockText.listTitle,
                                      caption: musicBlockText.listCaption,
                                      addTitle: l10n.s.autoQuitAddApp,
                                      removeLabel: musicBlockText.removeApp,
                                      bundleIDs: blockedApps,
                                      reachesEveryApp: true,
                                      onAdd: { saveBlockedApps(blockedApps + [$0]) },
                                      onRemove: { id in saveBlockedApps(blockedApps.filter { $0 != id }) })
                        HStack {
                            Text(musicBlockText.replacementLabel)
                            Spacer()
                            Text(musicBlockReplacementName)
                                .foregroundStyle(.secondary)
                            Button(musicBlockText.chooseApp) { chooseMusicReplacement() }
                            if !musicBlockReplacementPath.isEmpty {
                                Button {
                                    musicBlockReplacementPath = ""
                                    replacementNotice = nil
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                }
                                .buttonStyle(.plain)
                                .foregroundStyle(.secondary)
                            }
                        }
                    }
                    if let replacementNotice {
                        Text(replacementNotice)
                            .font(SettingsTypography.caption)
                            .foregroundStyle(.orange)
                    }
                    SettingsCaptionText(musicBlockText.caption)
                }
                .settingsSectionAnchor(.musicBlocking)
            }
        }
        .formStyle(.grouped)
    }

    private func saveBlockedApps(_ apps: [String]) {
        let sanitized = Defaults.sanitizedBundleIdentifierList(apps)
        UserDefaults.standard.set(sanitized, forKey: DefaultsKey.musicBlockBundleIDs)
        blockedApps = sanitized
        if let replacementID = Bundle(path: musicBlockReplacementPath)?.bundleIdentifier,
           sanitized.contains(replacementID) {
            musicBlockReplacementPath = ""
            replacementNotice = actionText.replacementCleared
        }
    }

    private var musicBlockReplacementName: String {
        guard !musicBlockReplacementPath.isEmpty else { return musicBlockText.replacementNone }
        let name = FileManager.default.displayName(atPath: musicBlockReplacementPath)
        return (name as NSString).deletingPathExtension
    }

    private func chooseMusicReplacement() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [.applicationBundle]
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        NSApp.activate(ignoringOtherApps: true)
        guard panel.runModal() == .OK, let url = panel.url else { return }
        // Picking the blocked app itself would start a launch-and-kill loop.
        switch MusicLaunchSupport.replacementChoice(path: url.path,
                bundleID: Bundle(url: url)?.bundleIdentifier,
                blockedBundleIDs: MusicLaunchBlocker.blockedBundleIDs) {
        case .blocked:
            replacementNotice = actionText.replacementBlocked
        case let .selected(path):
            musicBlockReplacementPath = path
            replacementNotice = nil
        }
    }
}
