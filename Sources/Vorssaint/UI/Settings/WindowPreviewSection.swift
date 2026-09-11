// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import SwiftUI

/// Thumbnail size and exclusions for one preview surface. The App Switcher
/// and Dock Preview each include it with their own pair of keys.
struct WindowPreviewControls: View {
    @ObservedObject private var l10n = L10n.shared
    @AppStorage private var previewSize: String
    private let exclusionsKey: String
    private let onSizeChange: () -> Void

    init(sizeKey: String, exclusionsKey: String, onSizeChange: @escaping () -> Void = {}) {
        _previewSize = AppStorage(wrappedValue: "normal", sizeKey)
        self.exclusionsKey = exclusionsKey
        self.onSizeChange = onSizeChange
    }

    private var text: WindowPreviewExclusionStrings { FeatureStrings.windowPreviewExclusions(l10n.language) }

    var body: some View {
        Group {
            SettingsControlRow(title: text.previewSizeLabel, systemImage: "rectangle.on.rectangle") {
                Picker(text.previewSizeLabel, selection: $previewSize) {
                    Text(text.previewSizeSmall).tag("small")
                    Text(text.previewSizeNormal).tag("normal")
                    Text(text.previewSizeLarge).tag("large")
                    Text(text.previewSizeXLarge).tag("xlarge")
                }
                .labelsHidden()
                .pickerStyle(.segmented)
                .frame(minWidth: 260)
                .onChange(of: previewSize) { _, _ in onSizeChange() }
            }
            WindowPreviewExclusionsList(key: exclusionsKey)
        }
    }
}
