// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import AppKit
import SwiftUI

struct MusicBlockSettings: View {
    @ObservedObject private var l10n = L10n.shared
    @ObservedObject private var features = FeatureRuntime.shared
    @AppStorage(DefaultsKey.musicBlockEnabled) private var musicBlockEnabled = false
    @AppStorage(DefaultsKey.musicBlockReplacementPath) private var musicBlockReplacementPath = ""

    private var musicBlockText: MusicBlockFeatureStrings { FeatureStrings.musicBlock(l10n.language) }

    var body: some View {
        Form {
            if AppFeature.musicBlock.isAvailable {
                Section(musicBlockText.section) {
                    Toggle(musicBlockText.title, isOn: $musicBlockEnabled)
                        .onChange(of: musicBlockEnabled) { _, _ in
                            MusicLaunchBlocker.shared.syncWithPreferences()
                        }
                    if musicBlockEnabled {
                        HStack {
                            Text(musicBlockText.replacementLabel)
                            Spacer()
                            Text(musicBlockReplacementName)
                                .foregroundStyle(.secondary)
                            Button(musicBlockText.chooseApp) { chooseMusicReplacement() }
                            if !musicBlockReplacementPath.isEmpty {
                                Button {
                                    musicBlockReplacementPath = ""
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                }
                                .buttonStyle(.plain)
                                .foregroundStyle(.secondary)
                            }
                        }
                    }
                    SettingsCaptionText(musicBlockText.caption)
                }
                .settingsSectionAnchor(.musicBlocking)
            }
        }
        .formStyle(.grouped)
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
        if let bundleID = Bundle(url: url)?.bundleIdentifier,
           MusicLaunchBlocker.blockedBundleIDs.contains(bundleID) { return }
        musicBlockReplacementPath = url.path
    }
}
