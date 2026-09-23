// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import AppKit
import Foundation

/// The production display shortcut step and the Command Bar's brightness
/// target, compiled against an in-memory screen list, pointer, preferences
/// and display list. Nothing reaches a real display.
enum BrightnessShortcutTargetContract {
    struct Display {
        enum Method { case system, ddc }
        let id: UInt32
        var isBuiltIn = false
        var isActive = true
        var method: Method? = .ddc
    }
    struct Screen {
        let number: UInt32
        let frame: CGRect
        var deviceDescription: [NSDeviceDescriptionKey: Any] {
            [NSDeviceDescriptionKey("NSScreenNumber"): NSNumber(value: number)]
        }
    }
    enum Screens {
        static var screens: [Screen] = []
    }
    enum Pointer {
        static var mouseLocation = CGPoint.zero
    }
    enum Preferences {
        static var standard: Preferences.Type { Self.self }
        static var values: [String: Bool] = [:]
        static func bool(forKey key: String) -> Bool { values[key] ?? false }
    }
    enum Feature {
        case brightness
        var isAvailable: Bool { true }
    }
    final class Session {
        static let shared = Session()
        var isActive = true
    }
    class Fixture {
        typealias NSEvent = Pointer
        typealias NSScreen = Screens
        typealias UserDefaults = Preferences
        typealias AppFeature = Feature
        typealias SessionActivity = Session
        var running = true
        var displays: [Display] = []
        var pendingDisplayIDs = Set<UInt32>()
        var primary: UInt32 = 1
        var steps: [(id: UInt32, method: Display.Method, delta: Double, showOSD: Bool)] = []
        func CGMainDisplayID() -> UInt32 { primary }
        func step(_ id: UInt32, method: Display.Method, delta: Double, showOSD: Bool) {
            steps.append((id, method, delta, showOSD))
        }
    }

    final class Brightness {
        static var shared = Brightness()
        var displays: [Display] = []
        var writes: [(value: Double, id: UInt32, showOSD: Bool)] = []
        var refreshes = 0
        func setBrightness(_ value: Double, for id: UInt32, showOSD: Bool) {
            writes.append((value, id, showOSD))
        }
        func refresh() { refreshes += 1 }
    }
    enum Beep {
        static var count = 0
        static func beep() { count += 1 }
    }
    enum Queue {
        static var main: Queue.Type { Self.self }
        static var later: [() -> Void] = []
        static func asyncAfter(deadline: DispatchTime, execute work: @escaping () -> Void) {
            later.append(work)
        }
        static func drain() { while !later.isEmpty { later.removeFirst()() } }
    }
    class CatalogFixture {
        typealias BrightnessService = Brightness
        typealias BrightnessDisplay = Display
        typealias NSEvent = Pointer
        typealias NSScreen = Screens
        typealias NSSound = Beep
        typealias DispatchQueue = Queue
    }

    static func run(_ suite: TestSuite) {
        // A built-in panel at the origin and an external monitor to its right.
        let builtIn = Display(id: 1, isBuiltIn: true, method: .system)
        let external = Display(id: 2)
        let onBuiltIn = CGPoint(x: 100, y: 100)
        let onExternal = CGPoint(x: 1600, y: 100)
        Screens.screens = [Screen(number: 1, frame: CGRect(x: 0, y: 0, width: 1440, height: 900)),
                           Screen(number: 2, frame: CGRect(x: 1440, y: 0, width: 1920, height: 1080))]
        defer {
            Screens.screens = []
            Pointer.mouseLocation = .zero
            Preferences.values = [:]
            Brightness.shared = Brightness()
            Beep.count = 0
            Queue.later = []
        }
        func service(followsPointer: Bool, pointer: CGPoint) -> Service {
            Preferences.values = [BrightnessShortcutPreferenceKey.enabled: true,
                                  DefaultsKey.brightnessKeysEnabled: followsPointer,
                                  DefaultsKey.brightnessOSDEnabled: true]
            Pointer.mouseLocation = pointer
            let service = Service()
            service.displays = [builtIn, external]
            return service
        }

        // MARK: Display shortcuts

        let pointedBuiltIn = service(followsPointer: true, pointer: onBuiltIn)
        pointedBuiltIn.stepDisplayBrightness(delta: -BrightnessSupport.brightnessKeyStep)
        suite.expect(pointedBuiltIn.steps.map(\.id) == [1] && pointedBuiltIn.steps.first?.method == .system
                     && pointedBuiltIn.steps.first?.delta == -BrightnessSupport.brightnessKeyStep
                     && pointedBuiltIn.steps.first?.showOSD == true,
                     "a shortcut following the pointer onto the built-in panel steps the panel itself")
        let pointedExternal = service(followsPointer: true, pointer: onExternal)
        pointedExternal.stepDisplayBrightness(delta: BrightnessSupport.brightnessKeyStep)
        suite.expect(pointedExternal.steps.map(\.id) == [2] && pointedExternal.steps.first?.method == .ddc,
                     "a shortcut following the pointer onto an external monitor steps that monitor")
        let primaryBuiltIn = service(followsPointer: false, pointer: onExternal)
        primaryBuiltIn.stepDisplayBrightness(delta: BrightnessSupport.brightnessKeyStep)
        suite.expect(primaryBuiltIn.steps.map(\.id) == [1],
                     "without pointer following a shortcut steps the primary display, built-in included")
        let primaryExternal = service(followsPointer: false, pointer: onBuiltIn)
        primaryExternal.primary = 2
        primaryExternal.stepDisplayBrightness(delta: BrightnessSupport.brightnessKeyStep)
        suite.expect(primaryExternal.steps.map(\.id) == [2],
                     "an external primary display is the target wherever the pointer is")
        let pending = service(followsPointer: true, pointer: onBuiltIn)
        pending.pendingDisplayIDs = [1]
        pending.stepDisplayBrightness(delta: BrightnessSupport.brightnessKeyStep)
        suite.expect(pending.steps.isEmpty,
                     "a display still being set up is not stepped, and no other display stands in")
        let switchedOff = service(followsPointer: true, pointer: onBuiltIn)
        Preferences.values[BrightnessShortcutPreferenceKey.enabled] = false
        switchedOff.stepDisplayBrightness(delta: BrightnessSupport.brightnessKeyStep)
        suite.expect(switchedOff.steps.isEmpty, "a shortcut does nothing while its toggle is off")

        // MARK: Command Bar "brightness N"

        Brightness.shared = Brightness()
        Brightness.shared.displays = [external, builtIn]
        Pointer.mouseLocation = onBuiltIn
        Catalog.applyBrightness(percent: 40)
        suite.expect(Brightness.shared.writes.map(\.id) == [1] && Brightness.shared.writes.first?.value == 0.4
                     && Brightness.shared.writes.first?.showOSD == true,
                     "the command sets the built-in panel when the pointer is on it")
        Brightness.shared = Brightness()
        Brightness.shared.displays = [builtIn, external]
        Pointer.mouseLocation = onExternal
        Catalog.applyBrightness(percent: 70)
        suite.expect(Brightness.shared.writes.map(\.id) == [2],
                     "the command sets the monitor under the pointer, not the first one listed")
        Brightness.shared = Brightness()
        Brightness.shared.displays = [builtIn, external]
        Pointer.mouseLocation = CGPoint(x: -500, y: -500)
        Catalog.applyBrightness(percent: 10)
        suite.expect(Brightness.shared.writes.map(\.id) == [1],
                     "with the pointer on no known screen the command uses the first display")
        Brightness.shared = Brightness()
        Pointer.mouseLocation = onBuiltIn
        Beep.count = 0
        Catalog.applyBrightness(percent: 55)
        suite.expect(Brightness.shared.writes.isEmpty && Brightness.shared.refreshes == 1
                     && Queue.later.count == 1 && Beep.count == 0,
                     "with no displays known yet the command refreshes and tries once more")
        Brightness.shared.displays = [builtIn, external]
        Queue.drain()
        suite.expect(Brightness.shared.writes.map(\.id) == [1] && Brightness.shared.refreshes == 1,
                     "the retry lands on the display under the pointer once the list is in")
        Brightness.shared = Brightness()
        Catalog.applyBrightness(percent: 55)
        Queue.drain()
        suite.expect(Brightness.shared.writes.isEmpty && Beep.count == 1,
                     "a retry that still finds no display beeps instead of looping")
    }
}
