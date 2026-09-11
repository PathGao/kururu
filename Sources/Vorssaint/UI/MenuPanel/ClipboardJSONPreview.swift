// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import SwiftUI

struct ClipboardJSONPreview: View {
    let original: String
    let copyFormatted: (String) -> Void
    @ObservedObject private var l10n = L10n.shared
    @State private var result: (source: String, formatted: String)?
    @State private var showFormatted = true

    private var formatted: String? { result?.source == original ? result?.formatted : nil }
    private var chinese: Bool { l10n.language == .zhHans }

    var body: some View {
        VStack(spacing: 0) {
            if let formatted {
                VStack(alignment: .leading, spacing: 8) {
                    Picker("JSON", selection: $showFormatted) {
                        Text(chinese ? "格式化 JSON" : "Formatted JSON").tag(true)
                        Text(chinese ? "原文" : "Original").tag(false)
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    Button(chinese ? "拷贝格式化 JSON" : "Copy formatted JSON") { copyFormatted(formatted) }
                        .controlSize(.small)
                    Text(chinese ? "原文不变；底部拷贝仍使用原文。" : "The original text stays unchanged. Copy below uses it.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .padding(10)
            }
            ClipboardTextPreview(text: showFormatted ? (formatted ?? original) : original,
                                 monospaced: formatted != nil)
        }
        .task(id: original) {
            let source = original
            let worker = Task.detached(priority: .userInitiated) { JSONPreviewFormatter.format(source) }
            let value = await withTaskCancellationHandler {
                await worker.value
            } onCancel: { worker.cancel() }
            guard !Task.isCancelled else { return }
            result = value.map { (source, $0) }
        }
    }
}
