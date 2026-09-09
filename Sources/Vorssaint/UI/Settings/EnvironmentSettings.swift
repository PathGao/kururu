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

    private var text: EnvironmentFeatureStrings { FeatureStrings.environment(l10n.language) }

    var body: some View {
        VStack(spacing: 0) {
            header
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    commandsSection
                    pathSection
                    cachesSection
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .onAppear {
            if inspector.report.tools.isEmpty { inspector.refresh() }
        }
    }

    private var header: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 3) {
                Label(AppFeature.environment.name(l10n.s, language: l10n.language),
                      systemImage: "terminal")
                    .font(.system(size: 14, weight: .semibold))
                Text(text.hubDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 8)
            Button(text.copyReport) {
                copy(EnvironmentInspector.diagnosticText(inspector.report))
            }
            .controlSize(.small)
            .disabled(inspector.isLoading)
            Button {
                inspector.refresh()
            } label: {
                if inspector.isLoading {
                    ProgressView().controlSize(.small)
                } else {
                    Image(systemName: "arrow.clockwise")
                }
            }
            .fixedSize()
            .help(text.refresh)
            .disabled(inspector.isLoading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Which copy wins

    private var commandsSection: some View {
        section(text.commandsTitle, note: text.commandsNote) {
            VStack(alignment: .leading, spacing: 2) {
                ForEach(inspector.report.tools) { tool in
                    commandRow(tool)
                }
            }
        }
    }

    private func commandRow(_ tool: EnvironmentTool) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(tool.command)
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .frame(width: 62, alignment: .leading)
            VStack(alignment: .leading, spacing: 2) {
                if let path = tool.path {
                    HStack(spacing: 6) {
                        Text(abbreviate(path))
                            .font(.system(size: 11, design: .monospaced))
                            .textSelection(.enabled)
                            .lineLimit(1)
                            .truncationMode(.middle)
                        if tool.isShim {
                            Text(text.shimBadge)
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundStyle(.orange)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 1)
                                .background(Capsule().fill(Color.orange.opacity(0.12)))
                        }
                    }
                    // The version a shim reports is the wrapper's, not the tool
                    // the name promises, so both lines sit together.
                    let detail = [tool.version,
                                  tool.shimTarget.map { String(format: text.shimFormat, abbreviate($0)) },
                                  tool.shadowedPaths.isEmpty
                                    ? nil
                                    : String(format: text.shadowedFormat, tool.shadowedPaths.count)]
                        .compactMap { $0 }
                        .joined(separator: "  ·  ")
                    if !detail.isEmpty {
                        Text(detail)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                } else {
                    Text(text.notFound)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 8)
            if let path = tool.path {
                Button(text.copyPath) { copy(path) }
                    .controlSize(.small)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 6).fill(Color.primary.opacity(0.03)))
    }

    // MARK: - Terminal PATH vs app PATH

    private var pathSection: some View {
        section(text.pathTitle, note: text.pathNote) {
            VStack(alignment: .leading, spacing: 10) {
                if !inspector.report.readLoginShell && !inspector.report.terminalPath.isEmpty {
                    Text(text.shellUnavailable)
                        .font(.caption)
                        .foregroundStyle(.orange)
                        .fixedSize(horizontal: false, vertical: true)
                }
                pathList(text.pathTerminalOnly,
                         entries: inspector.report.terminalOnlyPath,
                         emptyText: text.pathNoDifference,
                         highlighted: true)
                pathList(text.pathTerminal, entries: inspector.report.terminalPath)
                pathList(text.pathGui, entries: inspector.report.guiPath)
            }
        }
    }

    private func pathList(_ title: String,
                          entries: [String],
                          emptyText: String? = nil,
                          highlighted: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.system(size: 11, weight: .medium))
            if entries.isEmpty {
                Text(emptyText ?? "—")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(entries, id: \.self) { entry in
                    Text(abbreviate(entry))
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(highlighted ? Color.orange : Color.secondary)
                        .textSelection(.enabled)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Caches

    private var cachesSection: some View {
        section(text.cachesTitle, note: text.cachesNote) {
            VStack(alignment: .leading, spacing: 3) {
                if inspector.report.caches.isEmpty {
                    Text(text.cachesEmpty)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(inspector.report.caches) { cache in
                        HStack(spacing: 8) {
                            Text(abbreviate(cache.path))
                                .font(.system(size: 11, design: .monospaced))
                                .lineLimit(1)
                                .truncationMode(.middle)
                            Spacer(minLength: 8)
                            Text(ByteCountFormatter.string(fromByteCount: cache.size, countStyle: .file))
                                .font(.system(size: 11))
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
                                        note: String,
                                        @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)
            Text(note)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func abbreviate(_ path: String) -> String {
        let home = NSHomeDirectory()
        return path.hasPrefix(home + "/") ? "~" + path.dropFirst(home.count) : path
    }

    private func copy(_ value: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(value, forType: .string)
    }
}
