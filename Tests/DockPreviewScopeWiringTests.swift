// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import Foundation

/// DockPreviewScopeTests runs the observer and the activation check on
/// fixtures, so the callers that reach them are pinned here by source.
enum DockPreviewScopeWiringTests {
    static func run(_ suite: TestSuite) {
        let code = DockAutohideHoldWiringTests.code
        let body = DockAutohideHoldWiringTests.body
        let service = code("Sources/Vorssaint/Services/DockPreview/DockPreviewService.swift")
        let enumerator = code("Sources/Vorssaint/Services/Switcher/WindowEnumerator.swift")
        let owner = "final class DockPreviewService:"
        let pinned = "final class DockPreviewPinnedPanel:"
        let scoped = "WindowEnumerator.listWindowsForDockPreview("

        suite.expect(body(service, owner, "private func endSession() {").contains(
            "panel?.orderOut(nil) releaseDockAutohideHold() tearDownVisuals()"),
                     "closing a preview removes the panel before emptying it")
        suite.expect(service.components(separatedBy: "panel.animationBehavior = .none").count == 3,
                     "neither preview panel animates its dismissal")
        suite.expect(body(service, owner, "func syncWithPreferences() {").contains(
            "if freshScope != currentSpaceOnly { currentSpaceOnly = freshScope endSession() }"),
                     "changing the desktop scope drops the open list")
        suite.expect(body(service, owner, "func syncWithPreferences() {").contains("startTap() syncSpaceObservation()"),
                     "starting Dock Preview begins desktop observation")
        suite.expect(body(service, owner, "private func stopTap() {").contains("stopSpaceObservation()"),
                     "stopping Dock Preview ends desktop observation")
        suite.expect(body(service, owner, "private static func previewableWindows(").contains(scoped)
                        && body(service, pinned, "private func refreshWindows() {").contains(scoped),
                     "open and pinned previews list windows with the Dock Preview scope")
        suite.expect(body(service, owner, "func commit(").contains(
            "endSession() guard WindowEnumerator.dockPreviewMayActivate(item) else { return } WindowActivator.activate(item)"),
                     "a preview never activates a window that left the current desktop")
        suite.expect(body(service, pinned, "func commit(").contains(
            "guard WindowEnumerator.dockPreviewMayActivate(item) else { refreshWindows() return }"),
                     "a pinned preview refreshes instead of activating a window that left the current desktop")
        suite.expect(body(enumerator, "enum WindowEnumerator", "static func listWindowsForDockPreview(").contains(
            "currentSpaceOnly: UserDefaults.standard.bool(forKey: DefaultsKey.dockPreviewCurrentSpaceOnly)"),
                     "Dock Preview reads its own desktop setting")
        suite.expect(body(enumerator, "enum WindowEnumerator", "static func listWindows(for pid: pid_t,").contains(
            "currentSpaceOnly: currentSpaceOnly, marksHiddenSpaces: marksHiddenSpaces && !currentSpaceOnly,"),
                     "the per-app list applies the scope it is given")
        suite.expect(enumerator.contains(
            "isOrderedIn: hiddenSpaceSurfaceIsWitnessed && !isConfirmedHiddenAppWindow "
                + "? SpaceWindowBridge.isWindowOrderedIn(CGWindowID(windowID)) : nil,"),
                     "an unmatched window on another desktop is checked against window ordering")
        suite.expect(code("Sources/Vorssaint/UI/Settings/DockSettings.swift").contains(
            "SettingsToggleWithCaption(title: l10n.s.switcherCurrentSpaceOnly, caption: text.currentSpaceOnlyCaption, "
                + "isOn: $dockPreviewCurrentSpaceOnly) .onChange(of: dockPreviewCurrentSpaceOnly) { _, _ in "
                + "dockPreview.syncWithPreferences() }"),
                     "the Dock page switch applies the desktop scope at once")
    }
}
