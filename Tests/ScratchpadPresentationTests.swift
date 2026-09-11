// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint
import Foundation
import CoreGraphics

enum ScratchpadPresentationTests {
    static func run(_ expect: (Bool, String) -> Void) {
        let floating = CGRect(x: -800, y: 100, width: 500, height: 400)
        let screen = ShelfDockScreen(id: 7, frame: CGRect(x: -1440, y: 0, width: 1440, height: 900),
                                    visibleFrame: CGRect(x: -1440, y: 0, width: 1440, height: 900), safeTopInset: 36)
        let other = ShelfDockScreen(id: 8, frame: CGRect(x: 0, y: 0, width: 1920, height: 1080),
                                   visibleFrame: CGRect(x: 0, y: 30, width: 1920, height: 1026))
        var state = ScratchpadPresentationState()
        expect(!state.isAtTop, "initial notes mode is floating")
        let top = state.enterTop(screen: screen, currentFrame: floating)
        expect(state.isAtTop && state.screenID == 7, "top presentation binds requested display")
        expect(top.size == CGSize(width: 380, height: 300), "top notes have bounded initial size")
        expect(top.midX == -720 && top.maxY == 860, "top notes center below notch safe area")
        _ = state.enterTop(screen: other, currentFrame: top)
        expect(state.floatingFrame == floating, "repositioning top does not overwrite saved floating frame")
        expect(state.screenID == 8, "explicit top move may choose another display")
        expect(state.screen(in: [screen, other], mouse: CGPoint(x: -500, y: 200))?.id == 8,
               "pointer movement keeps chosen top display")
        expect(state.screen(in: [screen], mouse: CGPoint(x: 500, y: 200))?.id == 7,
               "removed top display falls back to an existing display")
        expect(state.screenID == 7, "display fallback becomes the new binding")
        expect(state.leaveTop() == floating, "hide restores exact previous floating frame")
        expect(!state.isAtTop && state.screenID == nil && state.floatingFrame == nil,
               "hide clears all top presentation state")
        expect(state.leaveTop() == nil, "repeated hide has no stale frame to restore")
        _ = state.enterTop(screen: screen, currentFrame: floating)
        expect(state.screen(in: [], mouse: .zero) == nil, "no displays yields no placement")
        expect(state.leaveTop() == floating, "no displays does not lose floating restoration")
    }
}
