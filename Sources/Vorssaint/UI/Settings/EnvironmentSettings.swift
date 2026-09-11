// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import AppKit
import SwiftUI

/// Read-only view of the command environment. It answers three questions a
/// person cannot answer from a GUI: which copy of a command wins, which of
/// them are wrappers around something else, and why an app started from
/// Finder cannot find any of them. The only thing it hands back is text on
/// the clipboard.
struct EnvironmentSettings: View {
    @ObservedObject private var l10n = L10n.shared
    @ObservedObject private var inspector = EnvironmentInspector.shared
    @State private var copyFeedback = EnvironmentCopyFeedback()

    private var detailText: EnvironmentDetailStrings { EnvironmentDetailStrings(language: l10n.language) }

    private var text: EnvironmentFeatureStrings { FeatureStrings.environment(l10n.language) }

    var body: some View {
        VStack(spacing: 0) {
            header
                .padding(.horizontal, SettingsVisualStyle.current.pageInset)
                .padding(.vertical, 12)
            SettingsForm {
                SettingsInfo(text: text.hubDescription, systemImage: "terminal")
                commandsSection
                pathSection
                cachesSection
            }
        }
        .font(SettingsTypography.body)
        .controlSize(.regular)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .onAppear {
            if inspector.report.tools.isEmpty {
                copyFeedback.clear()
                inspector.refresh()
            }
        }
        .onChange(of: inspector.isLoading) { _, _ in
            copyFeedback.clear()
        }
    }

    private var header: some View {
        HStack(spacing: 8) {
            Spacer(minLength: 0)
            EnvironmentCopyButton(title: text.copyReport,
                                  succeeded: copyFeedback.result(for: "report"),
                                  copied: text.copied, failed: text.copyFailed) {
                copy(EnvironmentInspector.diagnosticText(inspector.report), target: "report")
            }
            .disabled(inspector.isLoading)
            Button {
                copyFeedback.clear()
                inspector.refresh()
            } label: {
                HStack(spacing: 6) {
                    if inspector.isLoading {
                        ProgressView().controlSize(.small)
                    }
                    Label(text.refresh, systemImage: "arrow.clockwise")
                }
            }
            .settingsAction(.primary)
            .fixedSize()
            .help(text.refresh)
            .accessibilityLabel(text.refresh)
            .disabled(inspector.isLoading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Which copy wins

    private var commandsSection: some View {
        section(text.commandsTitle, systemImage: "terminal", note: text.commandsNote) {
            VStack(alignment: .leading, spacing: 2) {
                ForEach(inspector.report.tools) { tool in
                    commandRow(tool)
                }
            }
        }
    }

    private func commandRow(_ tool: EnvironmentTool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(tool.command)
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                if let version = tool.version {
                    Text("\(detailText.version(reportedByForwarder: tool.isShim)): \(version)")
                        .font(SettingsTypography.body)
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            if let path = tool.path {
                pathRow(label: detailText.resolvedPath, path: path)
                if let target = tool.shimTarget {
                    pathRow(label: detailText.forwardTarget, path: target)
                }
                if !tool.shadowedPaths.isEmpty {
                    DisclosureGroup(detailText.otherCopies(tool.shadowedPaths.count)) {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(tool.shadowedPaths, id: \.self) { path in
                                pathRow(label: nil, path: path)
                            }
                        }
                        .padding(.top, 6)
                    }
                    .font(SettingsTypography.body)
                    .accessibilityLabel("\(tool.command): \(detailText.otherCopies(tool.shadowedPaths.count))")
                }
            } else {
                Text(text.notFound)
                    .font(SettingsTypography.body)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .settingsItemSurface()
    }

    private func pathRow(label: String?, path: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                if let label {
                    Text(label)
                        .font(SettingsTypography.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                }
                Text(abbreviate(path))
                    .font(.system(size: 12, design: .monospaced))
                    .textSelection(.enabled)
                    .fixedSize(horizontal: false, vertical: true)
                    .help(path)
            }
            Spacer(minLength: 8)
            EnvironmentCopyButton(title: text.copyPath,
                                  succeeded: copyFeedback.result(for: path),
                                  copied: text.copied, failed: text.copyFailed) {
                copy(path, target: path)
            }
            .fixedSize()
            .disabled(inspector.isLoading)
        }
    }

    // MARK: - Terminal PATH vs app PATH

    private var pathSection: some View {
        section(text.pathTitle, systemImage: "arrow.triangle.branch", note: detailText.pathNote) {
            VStack(alignment: .leading, spacing: 10) {
                if !inspector.report.readLoginShell && !inspector.report.terminalPath.isEmpty {
                    Text(text.shellUnavailable)
                        .font(SettingsTypography.caption)
                        .foregroundStyle(.orange)
                        .fixedSize(horizontal: false, vertical: true)
                }
                pathList(detailText.pathDifference,
                         entries: inspector.report.terminalOnlyPath,
                         emptyText: text.pathNoDifference,
                         highlighted: true)
                DisclosureGroup(text.pathTerminal) {
                    pathList(text.pathTerminal, entries: inspector.report.terminalPath, showsTitle: false)
                }
                DisclosureGroup(text.pathGui) {
                    pathList(text.pathGui, entries: inspector.report.guiPath, showsTitle: false)
                }
            }
        }
    }

    private func pathList(_ title: String,
                          entries: [String],
                          emptyText: String? = nil,
                          highlighted: Bool = false,
                          showsTitle: Bool = true) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            if showsTitle {
                Text(title).font(SettingsTypography.body.weight(.medium))
            }
            if entries.isEmpty {
                Text(emptyText ?? "—")
                    .font(SettingsTypography.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(entries, id: \.self) { entry in
                    Text(abbreviate(entry))
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(highlighted ? Color.orange : Color.secondary)
                        .textSelection(.enabled)
                        .fixedSize(horizontal: false, vertical: true)
                        .help(entry)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Caches

    private var cachesSection: some View {
        section(text.cachesTitle, systemImage: "internaldrive", note: text.cachesNote) {
            VStack(alignment: .leading, spacing: 3) {
                if inspector.report.caches.isEmpty {
                    Text(text.cachesEmpty)
                        .font(SettingsTypography.caption)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(inspector.report.caches) { cache in
                        HStack(spacing: 8) {
                            Text(abbreviate(cache.path))
                                .font(.system(size: 12, design: .monospaced))
                                .textSelection(.enabled)
                                .fixedSize(horizontal: false, vertical: true)
                                .help(cache.path)
                            Spacer(minLength: 8)
                            Text(ByteCountFormatter.string(fromByteCount: cache.size, countStyle: .file))
                                .font(SettingsTypography.caption)
                                .monospacedDigit()
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Shared

    private func section<Content: View>(_ title: String,
                                        systemImage: String,
                                        note: String,
                                        @ViewBuilder content: () -> Content) -> some View {
        SettingsSection(title: title, systemImage: systemImage) {
            SettingsExplanation(note)
            content()
        }
    }

    private func abbreviate(_ path: String) -> String {
        let home = NSHomeDirectory()
        return path.hasPrefix(home + "/") ? "~" + path.dropFirst(home.count) : path
    }

    private func copy(_ value: String, target: String) {
        copyFeedback.copy(value, target: target) { value in
            NSPasteboard.general.clearContents()
            return NSPasteboard.general.setString(value, forType: .string)
        }
    }
}
