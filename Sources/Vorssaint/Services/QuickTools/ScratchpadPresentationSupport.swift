// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint
import Foundation
import CoreGraphics

/// Presentation state only; the service keeps its existing panel and editor.
struct ScratchpadPresentationState {
    private(set) var screenID: UInt32?
    private(set) var floatingFrame: CGRect?
    var isAtTop: Bool { floatingFrame != nil }

    mutating func enterTop(screen: ShelfDockScreen, currentFrame: CGRect) -> CGRect {
        if floatingFrame == nil { floatingFrame = currentFrame }
        screenID = screen.id
        return Self.topFrame(on: screen)
    }

    mutating func screen(in screens: [ShelfDockScreen], mouse: CGPoint) -> ShelfDockScreen? {
        let resolved = screens.first { $0.id == screenID }
            ?? screens.first { $0.frame.contains(mouse) } ?? screens.first
        screenID = resolved?.id
        return resolved
    }

    mutating func leaveTop() -> CGRect? {
        let original = floatingFrame
        floatingFrame = nil
        screenID = nil
        return original
    }

    static func topFrame(on screen: ShelfDockScreen) -> CGRect {
        ShelfDockPlacementSupport.frame(size: CGSize(width: 380, height: 300), screen: screen,
                                        placement: .topCenter, anchor: nil)
    }
}
