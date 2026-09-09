// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import ApplicationServices
import CoreGraphics

/// Resolves an Accessibility window element to its WindowServer id. Exported by
/// ApplicationServices and used by macOS window switchers; there is no public
/// alternative for this mapping.
@_silgen_name("_AXUIElementGetWindow")
private func _AXUIElementGetWindow(_ element: AXUIElement,
                                   _ windowID: UnsafeMutablePointer<CGWindowID>) -> AXError

enum AXWindowResolver {
    static func windowID(for element: AXUIElement) -> CGWindowID? {
        var id: CGWindowID = 0
        guard _AXUIElementGetWindow(element, &id) == .success, id != 0 else { return nil }
        return id
    }
}
