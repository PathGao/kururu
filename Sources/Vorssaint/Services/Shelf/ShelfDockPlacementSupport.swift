// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint
import Foundation
import CoreGraphics

enum ShelfDockPlacement: String, CaseIterable {
    case menuBar, topCenter
    static func normalized(_ raw: String?) -> Self { raw.flatMap(Self.init(rawValue:)) ?? .menuBar }
}

struct ShelfDockScreen: Equatable {
    let id: UInt32
    let frame: CGRect
    let visibleFrame: CGRect
    var safeTopInset: CGFloat = 0
}

/// The same resolved screen feeds both the panel frame and its drag target.
struct ShelfDockPlacementState {
    private(set) var placement: ShelfDockPlacement = .menuBar
    private(set) var screenID: UInt32?

    mutating func reset() { screenID = nil }

    mutating func resolve(placement requested: ShelfDockPlacement, screens: [ShelfDockScreen],
                          mouse: CGPoint, anchor: CGRect?) -> ShelfDockScreen? {
        if placement != requested { screenID = nil; placement = requested }
        let pointed = screens.first { $0.frame.contains(mouse) }
        let selected: ShelfDockScreen?
        switch requested {
        case .menuBar:
            selected = anchor.flatMap { a in screens.first { $0.frame.intersects(a) } } ?? pointed ?? screens.first
        case .topCenter:
            selected = screens.first { $0.id == screenID } ?? pointed ?? screens.first
        }
        screenID = selected?.id
        return selected
    }

    /// Called only during a qualified content drag. A crossing alone is insufficient.
    mutating func moveForDrag(mouse: CGPoint, screens: [ShelfDockScreen], targetSize: CGSize,
                              margin: CGFloat) -> Bool {
        guard placement == .topCenter,
              let candidate = screens.first(where: { $0.frame.contains(mouse) }),
              candidate.id != screenID,
              ShelfDockPlacementSupport.frame(size: targetSize, screen: candidate,
                                              placement: .topCenter, anchor: nil)
                .insetBy(dx: -margin, dy: -margin).contains(mouse) else { return false }
        screenID = candidate.id
        return true
    }
}

enum ShelfDockPlacementSupport {
    static func effectiveUsableFrame(screen: ShelfDockScreen, placement: ShelfDockPlacement) -> CGRect {
        guard placement == .topCenter else { return screen.visibleFrame }
        let top = min(screen.visibleFrame.maxY, screen.frame.maxY - max(0, screen.safeTopInset))
        return CGRect(x: screen.visibleFrame.minX, y: screen.visibleFrame.minY,
                      width: screen.visibleFrame.width, height: max(0, top - screen.visibleFrame.minY))
    }

    static func frame(size: CGSize, screen: ShelfDockScreen, placement: ShelfDockPlacement,
                      anchor: CGRect?) -> CGRect {
        let visible = effectiveUsableFrame(screen: screen, placement: placement)
        let width = placement == .menuBar ? size.width : min(size.width, max(0, visible.width - 16))
        let height = placement == .menuBar ? size.height : min(size.height, max(0, visible.height - 8))
        let requestedX: CGFloat
        if placement == .topCenter {
            requestedX = visible.midX - width / 2
        } else {
            requestedX = anchor.map { $0.midX - width / 2 } ?? (visible.maxX - width - 12)
        }
        let x = min(max(visible.minX + 8, requestedX), visible.maxX - width - 8)
        return CGRect(x: x, y: visible.maxY - 4 - height, width: width, height: height)
    }
}
