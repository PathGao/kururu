// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import Foundation

enum TrackpadGestureOwner: Equatable {
    case middleClick
    case radial(UUID)
}

enum TrackpadGestureRouting {
    static func owner(fingers: Int, middleClickTapFingers: Int,
                      profiles: [RadialMenuProfile]) -> TrackpadGestureOwner? {
        guard fingers == 3 || fingers == 4 else { return nil }
        var owners = profiles.filter { $0.trackpadTapFingers == fingers }.map { TrackpadGestureOwner.radial($0.id) }
        if middleClickTapFingers == fingers { owners.append(.middleClick) }
        return owners.count == 1 ? owners[0] : nil
    }

    static func conflicts(fingers: Int, middleClickTapFingers: Int,
                          profiles: [RadialMenuProfile], excludingProfileID: UUID? = nil) -> Bool {
        guard fingers == 3 || fingers == 4 else { return false }
        return middleClickTapFingers == fingers || profiles.contains {
            $0.id != excludingProfileID && $0.trackpadTapFingers == fingers
        }
    }
}

/// One contact sequence produces at most one tap, at its highest finger count.
struct TrackpadTapRecognizer {
    typealias Geometry = (center: (x: Float, y: Float), spread: Float)
    private var peak = 0
    private var started: TimeInterval?
    private var origin: Geometry?
    private var movement: Float = 0
    private var spreadChange: Float = 0
    private var sawButton = false
    private var unavailable = false

    mutating func buttonPressed() { sawButton = true }
    mutating func reset() { self = Self() }

    mutating func frame(count: Int, geometry: Geometry?, now: TimeInterval,
                        systemDragGestureEnabled: Bool = false,
                        secondsSinceLastKeyDown: TimeInterval = .infinity) -> Int? {
        if count == 0 {
            defer { reset() }
            guard let started else { return nil }
            return MiddleClickSupport.tapShouldFire(duration: now - started,
                maxMovement: movement, maxSpreadChange: spreadChange,
                exceededFingerCount: peak > 4, buttonPressedDuring: sawButton,
                positionUnavailable: unavailable, systemDragGestureEnabled: systemDragGestureEnabled,
                tapFingers: peak, secondsSinceLastKeyDown: secondsSinceLastKeyDown) ? peak : nil
        }
        if started == nil { started = now }
        if count > peak {
            peak = count
            origin = geometry
        }
        if count == peak {
            if let geometry, let origin {
                movement = max(movement, max(abs(geometry.center.x - origin.center.x), abs(geometry.center.y - origin.center.y)))
                spreadChange = max(spreadChange, abs(geometry.spread - origin.spread))
            } else { unavailable = true }
        }
        return nil
    }
}

/// Devices have independent contact lifetimes; a lift on another pad cannot
/// complete the active pad's candidate.
struct TrackpadTapStream {
    private var devices: [UInt: TrackpadTapRecognizer] = [:]
    mutating func reset() { devices.removeAll() }
    mutating func buttonPressed() {
        for key in Array(devices.keys) { devices[key]?.buttonPressed() }
    }
    mutating func frame(device: UInt, count: Int, geometry: TrackpadTapRecognizer.Geometry?,
                        now: TimeInterval, buttonDown: Bool = false,
                        systemDragGestureEnabled: Bool = false,
                        secondsSinceLastKeyDown: TimeInterval = .infinity) -> Int? {
        var recognizer = devices[device] ?? TrackpadTapRecognizer()
        if buttonDown { recognizer.buttonPressed() }
        let result = recognizer.frame(count: count, geometry: geometry, now: now,
            systemDragGestureEnabled: systemDragGestureEnabled,
            secondsSinceLastKeyDown: secondsSinceLastKeyDown)
        if count == 0 { devices.removeValue(forKey: device) }
        else { devices[device] = recognizer }
        return result
    }
}
