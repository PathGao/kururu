// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint
import Foundation
import CoreGraphics

enum ShelfDockPlacementTests {
    static func run(_ expect: (Bool, String) -> Void) {
        let first = ShelfDockScreen(id: 1, frame: CGRect(x: 0, y: 0, width: 1440, height: 900),
                                   visibleFrame: CGRect(x: 0, y: 30, width: 1440, height: 846))
        let left = ShelfDockScreen(id: 2, frame: CGRect(x: -1280, y: -100, width: 1280, height: 800),
                                  visibleFrame: CGRect(x: -1280, y: -100, width: 1280, height: 776))
        let screens = [first, left]
        let mouse = CGPoint(x: -600, y: 300)
        let anchor = CGRect(x: 1300, y: 878, width: 24, height: 22)
        expect(ShelfDockPlacement.normalized(nil) == .menuBar, "missing placement keeps old mode")
        expect(ShelfDockPlacement.normalized("unknown") == .menuBar, "invalid placement keeps old mode")
        expect(ShelfDockPlacement.normalized("topCenter") == .topCenter, "top mode decodes")
        var state = ShelfDockPlacementState()
        expect(state.resolve(placement: .topCenter, screens: screens, mouse: mouse, anchor: anchor)?.id == 2,
               "first top presentation chooses pointer screen over menu anchor")
        expect(state.resolve(placement: .topCenter, screens: screens, mouse: CGPoint(x: 700, y: 400), anchor: anchor)?.id == 2,
               "ordinary pointer movement does not move top shelf")
        expect(!state.moveForDrag(mouse: CGPoint(x: 700, y: 400), screens: screens,
                                  targetSize: CGSize(width: 72, height: 48), margin: 16), "crossing away from top does not switch")
        expect(state.moveForDrag(mouse: CGPoint(x: 720, y: 860), screens: screens,
                                 targetSize: CGSize(width: 72, height: 48), margin: 16), "qualified drag near other top switches")
        expect(state.screenID == 1, "drag switch locks new screen")
        expect(!state.moveForDrag(mouse: CGPoint(x: 720, y: 860), screens: screens,
                                  targetSize: CGSize(width: 72, height: 48), margin: 16), "same screen does not restart dwell")
        expect(state.resolve(placement: .topCenter, screens: [left], mouse: .zero, anchor: anchor)?.id == 2,
               "removed display falls back to remaining screen")
        expect(state.resolve(placement: .menuBar, screens: screens, mouse: mouse, anchor: anchor)?.id == 1,
               "mode switch resolves menu anchor")
        expect(state.resolve(placement: .topCenter, screens: screens, mouse: mouse, anchor: anchor)?.id == 2,
               "switching back resets top screen lock")
        state.reset()
        expect(state.screenID == nil, "disable or explicit presentation reset releases screen lock")
        expect(state.resolve(placement: .topCenter, screens: [], mouse: mouse, anchor: nil) == nil,
               "no screens returns no target")
        let pill = ShelfDockPlacementSupport.frame(size: CGSize(width: 72, height: 48), screen: left,
                                                   placement: .topCenter, anchor: anchor)
        let card = ShelfDockPlacementSupport.frame(size: CGSize(width: 340, height: 420), screen: left,
                                                   placement: .topCenter, anchor: anchor)
        expect(pill.midX == left.visibleFrame.midX && card.midX == pill.midX, "negative-coordinate screen centers both sizes")
        expect(pill.maxY == left.visibleFrame.maxY - 4 && card.maxY == pill.maxY, "expansion keeps same top edge")
        expect(left.visibleFrame.contains(card), "expanded card stays in usable frame")
        let menu = ShelfDockPlacementSupport.frame(size: CGSize(width: 72, height: 48), screen: first,
                                                   placement: .menuBar, anchor: anchor)
        expect(menu.midX == anchor.midX && menu.maxY == first.visibleFrame.maxY - 4, "menu mode keeps original anchor semantics")
        let notched = ShelfDockScreen(id: 3, frame: first.frame, visibleFrame: first.frame, safeTopInset: 36)
        let notchPill = ShelfDockPlacementSupport.frame(size: CGSize(width: 72, height: 48), screen: notched,
                                                        placement: .topCenter, anchor: nil)
        expect(notchPill.maxY == 860, "auto-hidden menu still leaves notch safe inset plus gap")
        let menuVisible = ShelfDockScreen(id: 4, frame: first.frame, visibleFrame: first.visibleFrame, safeTopInset: 12)
        expect(ShelfDockPlacementSupport.effectiveUsableFrame(screen: menuVisible, placement: .topCenter).maxY == 876,
               "visible menu bar takes precedence over smaller safe inset")
        expect(ShelfDockPlacementSupport.effectiveUsableFrame(screen: notched, placement: .menuBar) == notched.visibleFrame,
               "safe inset adaptation does not change legacy menu mode")
    }
}
