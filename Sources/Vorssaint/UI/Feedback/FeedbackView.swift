// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import SwiftUI

struct FeedbackView: View {
    let onClose: () -> Void

    @ObservedObject private var l10n = L10n.shared
    @State private var kind: FeedbackKind
    @State private var message = ""
    @State private var includeDiagnostics = false
    @State private var copied = false
    @State private var errorMessage: String?

    private let diagnostics = FeedbackDiagnostics.current()

    init(initialKind: FeedbackKind = .bug, onClose: @escaping () -> Void) {
        _kind = State(initialValue: initialKind)
        self.onClose = onClose
    }

    private var strings: FeedbackStrings { FeatureStrings.feedback(l10n.language) }
    private var local: LocalFeedbackCopy { .strings(language: l10n.language.rawValue) }
    private var count: Int { message.utf16.count }
    private var canCopy: Bool {
        let trimmedCount = message.trimmingCharacters(in: .whitespacesAndNewlines).utf16.count
        return trimmedCount > 0 && count <= 2_000
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            form
        }
        .frame(width: 600, height: 650)
    }

    private var header: some View {
        HStack(spacing: 12) {
            Image(systemName: "bubble.left.and.text.bubble.right.fill")
                .font(.title2)
                .foregroundStyle(.tint)
            Text(local.title)
                .font(.title2.weight(.semibold))
            Spacer()
            Button(strings.done, action: onClose)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 18)
    }

    private var form: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Picker("", selection: $kind) {
                        Text(strings.bugTitle).tag(FeedbackKind.bug)
                        Text(strings.featureTitle).tag(FeedbackKind.feature)
                    }
                    .labelsHidden()
                    .pickerStyle(.segmented)

                    VStack(alignment: .leading, spacing: 8) {
                        Text(strings.messageLabel)
                            .font(.headline)
                        ZStack(alignment: .topLeading) {
                            TextEditor(text: $message)
                                .font(.body)
                                .scrollContentBackground(.hidden)
                                .padding(6)
                            if message.isEmpty {
                                Text(kind == .bug ? strings.bugPlaceholder : strings.featurePlaceholder)
                                    .foregroundStyle(.tertiary)
                                    .padding(.horizontal, 11)
                                    .padding(.top, 6)
                                    .allowsHitTesting(false)
                            }
                        }
                        .frame(minHeight: 145)
                        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 9))
                        .overlay {
                            RoundedRectangle(cornerRadius: 9)
                                .strokeBorder(.separator, lineWidth: 1)
                        }
                        Text(String(format: strings.charactersFormat, count))
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(count > 2_000 ? .red : .secondary)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }

                    VStack(alignment: .leading, spacing: 5) {
                        Toggle(strings.includeDiagnostics, isOn: $includeDiagnostics)
                        Text(strings.includeDiagnosticsCaption)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Label(local.preview, systemImage: "eye")
                            .font(.headline)
                        Label(strings.previewBasic, systemImage: "text.alignleft")
                        if includeDiagnostics {
                            Label(strings.previewDiagnostics, systemImage: "info.circle")
                            diagnosticsPreview
                                .padding(.leading, 26)
                        }
                        Divider()
                        Label(local.explanation, systemImage: "hand.raised")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(16)
                    .background(.quaternary.opacity(0.45), in: RoundedRectangle(cornerRadius: 12))
                }
                .padding(24)
            }

            Divider()
            VStack(alignment: .leading, spacing: 10) {
                if let errorMessage {
                    Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(.red)
                        .fixedSize(horizontal: false, vertical: true)
                } else if copied {
                    Text(local.copied)
                        .font(.caption)
                        .foregroundStyle(.green)
                        .fixedSize(horizontal: false, vertical: true)
                }
                HStack(spacing: 12) {
                    Link(local.issues, destination: FeedbackDraftSupport.issuesURL)
                    Spacer()
                    Button(local.copy) { copyFeedback() }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .disabled(!canCopy)
                        .keyboardShortcut(.return, modifiers: [.command])
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
        }
        .onChange(of: kind) { _, _ in copied = false }
        .onChange(of: includeDiagnostics) { _, _ in copied = false }
        .onChange(of: message) { oldValue, newValue in
            if newValue.utf16.count > 2_000 {
                var limited = ""
                var units = 0
                for character in newValue {
                    let piece = String(character)
                    let pieceUnits = piece.utf16.count
                    if units + pieceUnits > 2_000 { break }
                    limited.append(contentsOf: piece)
                    units += pieceUnits
                }
                message = limited.isEmpty ? oldValue : limited
            }
            if errorMessage != nil { errorMessage = nil }
            copied = false
        }
    }

    private var diagnosticsPreview: some View {
        Grid(alignment: .leading, horizontalSpacing: 14, verticalSpacing: 5) {
            diagnosticRow(AppInfo.name, "\(diagnostics.appVersion) (\(diagnostics.appBuild))")
            diagnosticRow("macOS", diagnostics.macOS)
            if let model = diagnostics.macModel { diagnosticRow("Mac", model) }
            diagnosticRow(l10n.s.languageLabel, diagnostics.language)
            diagnosticRow(l10n.s.betaBadgeLabel, diagnostics.isBeta ? "✓" : "○")
            diagnosticRow(strings.diagnosticsChannelLabel,
                          diagnostics.updateChannel.replacingOccurrences(of: "-", with: " ").capitalized)
        }
        .font(.caption.monospaced())
        .foregroundStyle(.secondary)
    }

    private func diagnosticRow(_ label: String, _ value: String) -> some View {
        GridRow {
            Text(label).foregroundStyle(.tertiary)
            Text(value).textSelection(.enabled)
        }
    }

    private func copyFeedback() {
        guard canCopy else { return }
        var details = [
            AppInfo.name: "\(diagnostics.appVersion) (\(diagnostics.appBuild))",
            "macOS": diagnostics.macOS,
            "Language": diagnostics.language,
            "Beta": diagnostics.isBeta ? "true" : "false",
            "Channel": diagnostics.updateChannel,
        ]
        if let model = diagnostics.macModel { details["Mac"] = model }
        let text = FeedbackDraftSupport.text(
            category: kind == .bug ? strings.bugTitle : strings.featureTitle,
            message: message, diagnostics: details, includeDiagnostics: includeDiagnostics)
        NSPasteboard.general.clearContents()
        copied = NSPasteboard.general.setString(text, forType: .string)
        errorMessage = copied ? nil : local.copyFailed
    }
}
