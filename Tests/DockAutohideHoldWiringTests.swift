// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import Foundation

/// DockAutohideHoldTests runs the hold's production bodies but stubs
/// `endSession`, so the callers that reach the restore are pinned here by
/// source: dismissing a preview, dragging a window out of it, switching the
/// toggle off and quitting must each release the hold.
enum DockAutohideHoldWiringTests {
    static func run(_ suite: TestSuite) {
        let service = code("Sources/Vorssaint/Services/DockPreview/DockPreviewService.swift")
        let delegate = code("Sources/Vorssaint/App/AppDelegate.swift")
        let owner = "final class DockPreviewService:"
        suite.expect(body(service, owner, "private func endSession() {").contains("releaseDockAutohideHold()"),
                     "closing a Dock preview restores auto-hide")
        suite.expect(body(service, owner, "func beginWindowDrag(").contains(
            "isDraggingWindow = true releaseDockAutohideHold()"),
                     "dragging a window out of the preview restores auto-hide first")
        suite.expect(body(service, owner, "func syncWithPreferences() {").hasPrefix(
            "func syncWithPreferences() { if !UserDefaults.standard.bool(forKey: DefaultsKey.dockPreviewKeepDockVisible), "
                + "dockAutohideHold.isHolding { endSession() }"),
                     "switching the toggle off ends a held session")
        suite.expect(body(service, owner, "func stop() {").contains("endSession()"),
                     "stopping Dock Preview ends its session")
        suite.expect(body(delegate, "final class AppDelegate", "func applicationWillTerminate(")
                        .contains("DockPreviewService.shared.stop()"),
                     "quitting the app stops Dock Preview, which restores auto-hide")
    }

    /// Source without line comments, with all whitespace collapsed to one space.
    private static func code(_ path: String) -> String {
        let text = (try? String(contentsOfFile: path, encoding: .utf8)) ?? ""
        return text.components(separatedBy: "\n")
            .map { line in line.range(of: "//").map { String(line[..<$0.lowerBound]) } ?? line }
            .joined(separator: " ")
            .split(whereSeparator: \.isWhitespace).joined(separator: " ")
    }

    /// The member declared by `signature` inside `owner`, up to its matching brace.
    private static func body(_ code: String, _ owner: String, _ signature: String) -> String {
        guard let scope = code.range(of: owner),
              let start = code.range(of: signature, range: scope.upperBound..<code.endIndex)
        else { return "" }
        var depth = 0
        var index = start.lowerBound
        while index < code.endIndex {
            if code[index] == "{" { depth += 1 }
            if code[index] == "}" {
                depth -= 1
                if depth == 0 { return String(code[start.lowerBound...index]) }
            }
            index = code.index(after: index)
        }
        return ""
    }
}
