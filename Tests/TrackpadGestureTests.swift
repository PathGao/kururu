// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint
import Foundation

enum TrackpadGestureTests {
    static func run(_ expect: (Bool, String) -> Void) {
        let still: TrackpadTapRecognizer.Geometry = ((0.5, 0.5), 0.1)
        func tap(_ counts: [Int], button: Bool = false, moved: Bool = false, drag: Bool = false, idle: TimeInterval = 1) -> [Int] {
            var recognizer = TrackpadTapRecognizer()
            var results: [Int] = []
            for (index, count) in counts.enumerated() {
                if button && index == 0 { recognizer.buttonPressed() }
                var geometry = still
                if moved && index > 0 { geometry.center.x = 0.8 }
                if let value = recognizer.frame(count: count, geometry: geometry, now: Double(index) * 0.05,
                    systemDragGestureEnabled: drag, secondsSinceLastKeyDown: idle) { results.append(value) }
            }
            return results
        }
        expect(tap([3, 3, 0, 0]) == [3], "three finger release fires exactly once")
        expect(tap([3, 4, 3, 0]) == [4], "four finger sequence never also fires three")
        expect(tap([4, 5, 4, 0]).isEmpty, "extra fingers reject sequence")
        expect(tap([3, 3, 0], button: true).isEmpty, "physical press before candidate cancels tap")
        expect(tap([3, 3, 0], moved: true).isEmpty, "swipe cannot become tap")
        expect(tap([3, 3, 0], drag: true).isEmpty, "system drag owns three fingers")
        expect(tap([4, 4, 0], drag: true) == [4], "system three drag leaves four finger tap")
        expect(tap([3, 0], idle: 0.1).isEmpty, "typing suppresses tap")
        var long = TrackpadTapRecognizer()
        _ = long.frame(count: 3, geometry: still, now: 0)
        expect(long.frame(count: 0, geometry: nil, now: 0.5) == nil, "resting fingers do not trigger")
        var pinch = TrackpadTapRecognizer()
        _ = pinch.frame(count: 4, geometry: still, now: 0)
        _ = pinch.frame(count: 4, geometry: ((0.5, 0.5), 0.3), now: 0.1)
        expect(pinch.frame(count: 0, geometry: nil, now: 0.2) == nil, "stationary centroid pinch is rejected")
        var unreadable = TrackpadTapRecognizer()
        _ = unreadable.frame(count: 3, geometry: nil, now: 0)
        expect(unreadable.frame(count: 0, geometry: nil, now: 0.1) == nil, "unreadable geometry fails closed")
        expect(tap([3, 0, 4, 0]) == [3, 4], "independent released sequences both work")
        var stream = TrackpadTapStream()
        _ = stream.frame(device: 1, count: 3, geometry: still, now: 0)
        expect(stream.frame(device: 2, count: 0, geometry: nil, now: 0.1) == nil, "another device lift cannot complete contact")
        _ = stream.frame(device: 2, count: 4, geometry: still, now: 0.11)
        expect(stream.frame(device: 1, count: 0, geometry: nil, now: 0.2) == 3, "first pad retains three finger identity")
        expect(stream.frame(device: 2, count: 0, geometry: nil, now: 0.25) == 4, "second pad retains four finger identity")
        _ = stream.frame(device: 1, count: 3, geometry: still, now: 1, buttonDown: true)
        expect(stream.frame(device: 1, count: 0, geometry: nil, now: 1.1) == nil, "button held before touch prevents tap")
        _ = stream.frame(device: 1, count: 3, geometry: still, now: 2)
        stream.reset()
        expect(stream.frame(device: 1, count: 0, geometry: nil, now: 2.1) == nil, "stream reset cancels all devices")
        var first = RadialMenuProfile(); first.trackpadTapFingers = 3
        var second = RadialMenuProfile(); second.trackpadTapFingers = 3
        expect(TrackpadGestureRouting.owner(fingers: 3, middleClickTapFingers: 0, profiles: [first]) == .radial(first.id), "single profile owns saved tap")
        expect(TrackpadGestureRouting.owner(fingers: 3, middleClickTapFingers: 3, profiles: [first]) == nil, "middle and radial collision fires neither")
        expect(TrackpadGestureRouting.owner(fingers: 3, middleClickTapFingers: 0, profiles: [first, second]) == nil, "duplicate profiles fire neither")
        expect(TrackpadGestureRouting.owner(fingers: 4, middleClickTapFingers: 4, profiles: [first]) == .middleClick, "different finger counts coexist")
        expect(TrackpadGestureRouting.conflicts(fingers: 3, middleClickTapFingers: 0, profiles: [first]), "saved radial binding occupies gesture without enabled state")
        expect(!TrackpadGestureRouting.conflicts(fingers: 3, middleClickTapFingers: 0, profiles: [first], excludingProfileID: first.id), "editing current assignment excludes itself")
        var reset = TrackpadTapRecognizer()
        _ = reset.frame(count: 3, geometry: still, now: 0)
        reset.reset()
        expect(reset.frame(count: 0, geometry: nil, now: 0.1) == nil, "configuration reset cancels in-flight contact")
    }
}
