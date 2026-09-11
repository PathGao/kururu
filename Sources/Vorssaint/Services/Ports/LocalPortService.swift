// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import AppKit
import Combine

final class LocalPortService: ObservableObject {
    static let shared = LocalPortService()
    @Published private(set) var rows: [LocalPort] = []
    @Published private(set) var isLoading = false
    @Published private(set) var failed = false
    @Published private(set) var hasSnapshot = false
    private var completions: [() -> Void] = []

    private init() {}

    // Both surfaces share this snapshot. Only expansion, an explicit port
    // query or Refresh calls it; the monitor's sampler never does.
    func refresh(completion: (() -> Void)? = nil) {
        if let completion { completions.append(completion) }
        guard !isLoading else { return }
        isLoading = true
        DispatchQueue.global(qos: .userInitiated).async {
            let result = LocalPortScanner.snapshot()
            let rows = result.rows.map { row in
                var captured = row
                captured.startedAt = KillProcessService.currentStartTime(pid: row.pid)
                return captured
            }
            DispatchQueue.main.async {
                self.rows = rows
                self.failed = !result.isSuccess
                self.hasSnapshot = true
                self.isLoading = false
                let callbacks = self.completions
                self.completions = []
                callbacks.forEach { $0() }
            }
        }
    }

    func canTerminate(_ row: LocalPort) -> Bool {
        row.name != nil && row.startedAt != nil
            && !KillProcessSupport.isProtected(pid: row.pid, name: row.name ?? "")
    }

    func copy(_ row: LocalPort) {
        GeneralPasteboardAccess.shared.async({
            NSPasteboard.general.clearContents()
            return NSPasteboard.general.setString(row.copyText, forType: .string)
        }, then: { copied in
            let strings = LocalPortStrings.text(L10n.shared.language)
            QuickToolHUD.show(icon: copied ? "doc.on.doc" : "exclamationmark.circle",
                              message: copied ? strings.copied : strings.copyFailed)
        })
    }

    func confirmTermination(_ row: LocalPort) {
        guard canTerminate(row), let startedAt = row.startedAt, let name = row.name else { return }
        let strings = LocalPortStrings.text(L10n.shared.language)
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = String(format: strings.confirm, name, row.pid)
        alert.informativeText = strings.consequence
        alert.addButton(withTitle: strings.terminate)
        alert.addButton(withTitle: strings.cancel)
        NSApp.activate(ignoringOtherApps: true)
        guard alert.runModal() == .alertFirstButtonReturn else { return }
        DispatchQueue.global(qos: .userInitiated).async {
            let fresh = LocalPortScanner.snapshot()
            let matches = fresh.isSuccess && LocalPortSupport.matchesTarget(
                row, startedAt: startedAt, currentRows: fresh.rows,
                currentStart: KillProcessService.currentStartTime(pid: row.pid))
            let sent = matches && KillProcessService.terminateWithoutAuthorization(
                pid: row.pid, name: name, startedAt: startedAt)
            DispatchQueue.main.async {
                self.refresh()
                let result = NSAlert()
                result.messageText = sent ? strings.sent : strings.changed
                result.runModal()
            }
        }
    }

    func showActions(_ row: LocalPort) {
        let strings = LocalPortStrings.text(L10n.shared.language)
        let alert = NSAlert()
        alert.messageText = row.copyText
        alert.informativeText = strings.scope
        alert.addButton(withTitle: strings.copy)
        alert.addButton(withTitle: strings.cancel)
        if canTerminate(row) { alert.addButton(withTitle: strings.terminate) }
        NSApp.activate(ignoringOtherApps: true)
        switch alert.runModal() {
        case .alertFirstButtonReturn: copy(row)
        case .alertThirdButtonReturn: confirmTermination(row)
        default: break
        }
    }
}
