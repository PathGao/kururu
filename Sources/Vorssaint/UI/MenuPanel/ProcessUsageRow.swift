// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import AppKit
import SwiftUI

struct ProcessUsageRow: View {
    let row: ProcessUsage
    let value: String
    var iconSize: CGFloat = 15
    var leadingPadding: CGFloat = 0

    var body: some View {
        Group {
            if ProcessUsageService.shared.canActivate(row) {
                Button {
                    ProcessUsageService.shared.activate(row)
                } label: {
                    content
                }
                .buttonStyle(.plain)
            } else {
                content
            }
        }
        .help(row.name)
        .contextMenu { forceQuitItem }
    }

    /// The monitor already names who is eating the machine, so ending one is
    /// a right click away. Protected processes (the kernel, launchd, the
    /// window server, this app) never offer it.
    @ViewBuilder
    private var forceQuitItem: some View {
        if row.startedAt != nil, !KillProcessSupport.isProtected(pid: row.pid, name: row.name) {
            Button(FeatureStrings.killProcess(L10n.shared.language).forceKillButton, role: .destructive) {
                confirmForceQuit()
            }
        }
    }

    private func confirmForceQuit() {
        guard let startedAt = row.startedAt else { return }
        let strings = FeatureStrings.killProcess(L10n.shared.language)
        let alert = NSAlert()
        alert.alertStyle = .critical
        alert.messageText = String(format: strings.confirmForceKillFormat, row.name)
        alert.addButton(withTitle: strings.forceKillButton)
        alert.addButton(withTitle: L10n.shared.s.uninstallerCancel)
        NSApp.activate(ignoringOtherApps: true)
        guard alert.runModal() == .alertFirstButtonReturn else { return }
        KillProcessService.shared.kill(pid: row.pid, name: row.name, startedAt: startedAt, force: true)
    }

    private var content: some View {
        HStack(spacing: 7) {
            Image(nsImage: ResponsibleProcess.icon(for: row.pid))
                .resizable()
                .frame(width: iconSize, height: iconSize)
            Text(row.name)
                .font(.system(size: 10.5))
                .lineLimit(1)
                .truncationMode(.middle)
            Spacer(minLength: 0)
            Text(value)
                .font(.system(size: 10.5, weight: .medium))
                .monospacedDigit()
                .foregroundStyle(.secondary)
        }
        .contentShape(Rectangle())
        .padding(.leading, leadingPadding)
    }
}
