// SPDX-License-Identifier: GPL-3.0-or-later
import AppKit
import SwiftUI

/// Owns the reusable window and every native monitor attached while it is
/// visible. Search state and command semantics arrive through callbacks.
final class CommandBarPresentation {
    var onKeyDown: ((NSEvent, NSPanel) -> NSEvent?)?
    var onDismiss: (() -> Void)?
    var onCommandHeldChanged: ((Bool) -> Void)?
    private var panel: NSPanel?
    private var panelScreen: NSRect?
    private var keyMonitor: Any?
    private var outsideClickMonitor: Any?
    private var localClickMonitor: Any?
    private var flagsMonitor: Any?
    private var activationObserver: NSObjectProtocol?

    var isVisible: Bool { panel?.isVisible == true }
    var hasCustomPosition: Bool { positionOffset != .zero }
    func prepare() { _ = ensurePanel() }
    func show() {
        let panel = ensurePanel()
        position(panel)
        installMonitors(for: panel)
        panel.alphaValue = 1
        panel.orderFrontRegardless()
        panel.makeKey()
    }
    func hide() {
        removeMonitors()
        panel?.orderOut(nil)
    }
    func release() {
        hide()
        panel = nil
    }

    /// Re-fits the panel to its content as the result list grows and
    /// shrinks, keeping the top edge and horizontal center still so the
    /// field itself never jumps under the caret.
    func refreshLayout() {
        guard let panel, panel.isVisible else { return }
        DispatchQueue.main.async { [weak self] in
            guard let self, let panel = self.panel, panel.isVisible else { return }
            panel.contentViewController?.view.layoutSubtreeIfNeeded()
            let size = panel.contentViewController?.view.fittingSize ?? panel.frame.size
            let screen = self.panelScreen ?? NSScreen.pointerVisibleFrame
            var frame = panel.frame
            frame.origin.x = frame.midX - size.width / 2
            frame.origin.y = frame.maxY - size.height
            frame.size = size
            // Growing downward must stop at the screen edge; the list scrolls
            // instead of hiding its own footer below the bezel.
            frame.origin.y = max(frame.origin.y, screen.minY + 16)
            panel.setFrame(frame, display: true)
        }
    }

    /// Borderless panels refuse key status by default, and the bar's field
    /// needs it for typing while the target app stays active.
    private final class KeyableBarPanel: NSPanel {
        override var canBecomeKey: Bool { true }
    }

    private func ensurePanel() -> NSPanel {
        if let panel { return panel }
        let panel = KeyableBarPanel(contentRect: NSRect(x: 0, y: 0, width: 560, height: 380),
                                    styleMask: [.borderless, .nonactivatingPanel],
                                    backing: .buffered,
                                    defer: false)
        panel.title = AppInfo.name
        panel.isReleasedWhenClosed = false
        panel.isMovableByWindowBackground = false
        panel.hidesOnDeactivate = false
        panel.level = .floating
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle]
        let host = NSHostingController(rootView: CommandBarView())
        host.sizingOptions = .preferredContentSize
        panel.contentViewController = host
        self.panel = panel
        return panel
    }

    /// Centered, a bit above the middle of the screen the pointer is on:
    /// where the eye already is, and where the system's own search field
    /// puts itself. Anchored by the top edge so the list can grow and shrink
    /// below a field that never moves. Wherever the person dragged the bar
    /// away from that spot is added on, so the choice survives the close.
    private func position(_ panel: NSPanel, animated: Bool = false) {
        panel.contentViewController?.view.layoutSubtreeIfNeeded()
        let size = panel.contentViewController?.view.fittingSize ?? NSSize(width: 560, height: 380)
        // Decided once, here: moving the pointer to another display while
        // typing must not clamp the panel against a screen it is not on.
        let screen = NSScreen.pointerVisibleFrame
        panelScreen = screen
        let offset = positionOffset
        let origin = CommandBarPreferences.clampedPanelOrigin(
            size: size, in: screen, offset: offset)
        panel.setFrame(NSRect(origin: origin, size: size),
                       display: true,
                       animate: animated)
    }

    /// How far the person dragged the bar from the spot it would otherwise
    /// open on.
    private var positionOffset: CGSize {
        CommandBarPreferences.decodePositionOffset(
            UserDefaults.standard.string(forKey: DefaultsKey.commandBarPositionOffset) ?? "")
    }

    // MARK: - Moving the bar

    /// Clamps and saves only after the person's drag has ended. Programmatic
    /// positioning and content-driven resizing never rewrite this preference.
    func finishDrag() {
        guard let panel else { return }
        let screen = panel.screen?.visibleFrame ?? panelScreen ?? NSScreen.pointerVisibleFrame
        panelScreen = screen
        let draggedOffset = CGSize(
            width: panel.frame.midX - screen.midX,
            height: panel.frame.maxY - (screen.minY + screen.height * 0.72))
        let origin = CommandBarPreferences.clampedPanelOrigin(
            size: panel.frame.size, in: screen, offset: draggedOffset)
        if panel.frame.origin != origin { panel.setFrameOrigin(origin) }
        let offset = CGSize(width: panel.frame.midX - screen.midX,
                            height: panel.frame.maxY - (screen.minY + screen.height * 0.72))
        let encoded = CommandBarPreferences.encodePositionOffset(offset)
        if encoded.isEmpty {
            UserDefaults.standard.removeObject(forKey: DefaultsKey.commandBarPositionOffset)
        } else {
            UserDefaults.standard.set(encoded, forKey: DefaultsKey.commandBarPositionOffset)
        }
    }

    /// The way back: a double-click on the mark, or the button in Settings,
    /// returns the bar to the spot it opens on by default, with the same
    /// short slide it took on the way there.
    func resetPosition() {
        UserDefaults.standard.removeObject(forKey: DefaultsKey.commandBarPositionOffset)
        guard let panel, panel.isVisible else { return }
        position(panel, animated: true)
    }

    private func installMonitors(for panel: NSPanel) {
        removeMonitors()
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self, weak panel] event in
            guard let self, let panel, event.window === panel else { return event }
            // Input-method composition owns Return and navigation keys.
            if self.fieldIsComposing(in: panel) { return event }
            guard let onKeyDown = self.onKeyDown else { return event }
            return onKeyDown(event, panel)
        }
        flagsMonitor = NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            guard let self else { return event }
            let held = event.modifierFlags.contains(.command)
            self.onCommandHeldChanged?(held)
            return event
        }
        let mouseEvents: NSEvent.EventTypeMask = [.leftMouseDown, .rightMouseDown, .otherMouseDown]
        localClickMonitor = NSEvent.addLocalMonitorForEvents(matching: mouseEvents) { [weak self, weak panel] event in
            guard let self, let panel, panel.isVisible else { return event }
            if event.window !== panel, !Self.mouseIsInside(panel) {
                self.onDismiss?()
            }
            return event
        }
        outsideClickMonitor = NSEvent.addGlobalMonitorForEvents(matching: mouseEvents) { [weak self, weak panel] event in
            guard let self, let panel, panel.isVisible else { return }
            if event.windowNumber != panel.windowNumber, !Self.mouseIsInside(panel),
               // Every key on the Accessibility Keyboard is a click outside this
               // panel. Dismissing on those makes the panel impossible to type into.
               !AssistiveKeyboard.ownsCocoaPoint(NSEvent.mouseLocation) {
                self.onDismiss?()
            }
        }
        activationObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self,
                  let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
                  app.bundleIdentifier != Bundle.main.bundleIdentifier,
                  app.bundleIdentifier != AssistiveKeyboard.bundleID
            else { return }
            self.onDismiss?()
        }
    }

    private func removeMonitors() {
        if let keyMonitor {
            NSEvent.removeMonitor(keyMonitor)
            self.keyMonitor = nil
        }
        if let localClickMonitor {
            NSEvent.removeMonitor(localClickMonitor)
            self.localClickMonitor = nil
        }
        if let outsideClickMonitor {
            NSEvent.removeMonitor(outsideClickMonitor)
            self.outsideClickMonitor = nil
        }
        if let flagsMonitor {
            NSEvent.removeMonitor(flagsMonitor)
            self.flagsMonitor = nil
        }
        onCommandHeldChanged?(false)
        if let activationObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(activationObserver)
            self.activationObserver = nil
        }
    }

    /// True while an input method is still composing in the field. The panel
    /// edits through a field editor, so the marked range lives there.
    private func fieldIsComposing(in panel: NSPanel) -> Bool {
        guard let responder = panel.firstResponder as? NSTextView else { return false }
        return responder.hasMarkedText()
    }

    private static func mouseIsInside(_ panel: NSPanel) -> Bool {
        panel.frame.insetBy(dx: -2, dy: -2).contains(NSEvent.mouseLocation)
    }

}
