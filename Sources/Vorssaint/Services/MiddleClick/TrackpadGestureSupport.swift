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
    mutating func suppressTap(device: UInt) { devices[device]?.buttonPressed() }
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

/// A spread is opt-in and requires three settled contacts. Any incompatible
/// contact or press cancels the sequence until every finger has lifted.
struct TrackpadSpreadRecognizer {
    private var origin: TrackpadTapRecognizer.Geometry?
    private var started: TimeInterval?
    private var blocked = false
    private(set) var didFire = false

    mutating func cancel() { blocked = true }

    mutating func frame(count: Int, geometry: TrackpadTapRecognizer.Geometry?, now: TimeInterval,
                        buttonDown: Bool = false, systemDragGestureEnabled: Bool = false,
                        secondsSinceLastKeyDown: TimeInterval = .infinity) -> Bool {
        if count == 0 { self = Self(); return false }
        guard !blocked else { return false }
        guard !buttonDown, !systemDragGestureEnabled, secondsSinceLastKeyDown >= 0.3,
              count <= 3, now.isFinite else { blocked = true; return false }
        if count < 3 {
            if origin != nil { blocked = true }
            return false
        }
        guard let geometry, geometry.spread.isFinite,
              geometry.center.x.isFinite, geometry.center.y.isFinite else {
            blocked = true; return false
        }
        guard let origin, let started else {
            self.origin = geometry; self.started = now; return false
        }
        let duration = now - started
        guard duration >= 0, duration <= 0.8,
              abs(geometry.center.x - origin.center.x) <= 0.08,
              abs(geometry.center.y - origin.center.y) <= 0.08,
              geometry.spread >= origin.spread - 0.02 else { blocked = true; return false }
        guard duration >= 0.08,
              geometry.spread - origin.spread >= 0.06,
              geometry.spread >= origin.spread * 1.35 else { return false }
        blocked = true
        didFire = true
        return true
    }
}
