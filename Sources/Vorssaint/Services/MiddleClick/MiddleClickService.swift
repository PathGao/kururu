// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import AppKit
import ApplicationServices
import CoreGraphics
import Foundation
import IOKit

/// Middle-click emulation for trackpads: a three-finger PHYSICAL click
/// becomes a middle click (mouse wheel click), and an opt-in tap mode fires
/// it from a light three or four finger tap (issue #161). By default taps,
/// swipes and resting fingers never click. Contact data comes from the
/// MultitouchSupport private framework (the only source; every middle-click
/// utility uses it), loaded via dlopen/dlsym so a macOS that changes it
/// degrades to the feature simply staying off. Requires Accessibility for
/// the event tap.
final class MiddleClickService: ObservableObject {
    static let shared = MiddleClickService()

    @Published private(set) var isRunning = false
    @Published private(set) var trackpadAvailable = false
    /// The system's own three-finger drag gesture (Accessibility) is enabled:
    /// it owns three-finger touches and synthesizes clicks from unpressed
    /// contact, so the middle click stands down and Settings shows why.
    @Published private(set) var systemDragGestureConflict = false

    private var tap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    /// Guards the tap port above and the press state below: the callback runs
    /// on the pointer thread while the main thread arms and tears the feature
    /// down.
    private let tapStateLock = NSLock()
    /// Guards the cached system gesture setting, read on the tap callback and
    /// written on the main thread.
    private let dragLock = NSLock()
    private var dragGestureRefreshScheduled = false
    /// Retains the MTDeviceRefs while listening; the framework hands out
    /// CF objects owned by this array.
    private var deviceList: CFArray?
    private var observers: [Any] = []
    private var hotplugPort: IONotificationPortRef?
    private var hotplugIterator: io_iterator_t = 0
    /// A physical primary or secondary press is currently being relayed as a
    /// middle button, so its drag and release must transform too.
    private var middleButtonHeld = false
    /// A duplicate native down was dropped; its drag and up must be dropped as
    /// well instead of leaking an orphan event or ending the real held click.
    private var suppressedButtonSequence = false
    /// The process that received the transformed down. A recovery up targets
    /// the same process even while this app is terminating.
    private var middleButtonTargetPID: pid_t?
    /// When the hold began; a hold without its release for far too long means
    /// the up was lost (tap briefly disabled), and the flag must not keep
    /// swallowing clicks forever.
    private var middleButtonHeldSince: TimeInterval = 0
    /// When the last transformed click finished, for the bounce guard.
    private var lastTransformEnd: TimeInterval?
    /// Cached three-finger drag system setting; re-read at most every 2 s,
    /// always on the main thread, never from the event path.
    private var dragGestureCache: (enabled: Bool, readAt: TimeInterval) = (false, -10)

    /// Contact state shared between the multitouch callback thread and the
    /// main thread; every access goes through `stateLock`.
    private let stateLock = NSLock()
    private var fingerCount = 0
    private var lastFrameUptime: TimeInterval = 0
    /// When the contact count last became exactly three.
    private var threeFingersSince: TimeInterval?

    private var touchStream = TrackpadTapStream()
    private var spreadStreams: [UInt: TrackpadSpreadRecognizer] = [:]
    private var spreadProfileID: UUID?
    private var gestureOwners: [Int: TrackpadGestureOwner] = [:]
    private var gestureGeneration: UInt64 = 0
    private var middleClickEnabled = false
    private var physicalButtonDown = false

    private init() {
        // Multitouch callbacks and the filter tap belong only to the login
        // session on screen. A switched-away process must own neither.
        SessionActivity.shared.onChange { [weak self] _ in
            self?.syncWithPreferences()
        }
    }

    func syncWithPreferences() {
        let defaults = UserDefaults.standard
        let enabled = AppFeature.middleClick.isAvailable
            && defaults.bool(forKey: DefaultsKey.middleClickEnabled)
        let radialEnabled = AppFeature.radialMenu.isAvailable
            && defaults.bool(forKey: DefaultsKey.radialMenuEnabled)
        let tapFingers = Defaults.sanitizedMiddleClickTapFingers(
            defaults.integer(forKey: DefaultsKey.middleClickTapFingers))
        let profiles = RadialMenuSupport.decodeProfiles(defaults.data(forKey: DefaultsKey.radialMenuProfiles), defaults: defaults)
        var owners: [Int: TrackpadGestureOwner] = [:]
        for fingers in [3, 4] {
            guard let owner = TrackpadGestureRouting.owner(fingers: fingers, middleClickTapFingers: tapFingers, profiles: profiles) else { continue }
            switch owner {
            case .middleClick: if enabled { owners[fingers] = owner }
            case .radial: if radialEnabled { owners[fingers] = owner }
            }
        }
        stateLock.lock()
        let previouslyEnabled = middleClickEnabled
        middleClickEnabled = enabled
        spreadProfileID = radialEnabled ? profiles.first { $0.id.uuidString == defaults.string(forKey: DefaultsKey.trackpadSpreadProfile) }?.id : nil
        gestureOwners = owners
        gestureGeneration &+= 1
        touchStream.reset()
        spreadStreams.removeAll()
        stateLock.unlock()
        if previouslyEnabled && !enabled { releaseHeldMiddleButton() }
        refreshDragGestureConflict()
        if SessionActivitySupport.tapShouldRun(
            featureWanted: (enabled || !owners.isEmpty || spreadProfileID != nil) && !CleaningModeManager.shared.isActive,
            accessibilityGranted: AXIsProcessTrusted(),
            sessionIsActive: SessionActivity.shared.isActive
        ) {
            start()
        } else {
            stop()
        }
    }

    /// Re-reads the conflicting system gesture; Settings calls this when the
    /// Mouse tab appears so the warning reflects reality.
    func refreshDragGestureConflict() {
        let enabled = Self.systemThreeFingerDragEnabled()
        dragLock.lock()
        dragGestureCache = (enabled, ProcessInfo.processInfo.systemUptime)
        dragGestureRefreshScheduled = false
        dragLock.unlock()
        if systemDragGestureConflict != enabled {
            systemDragGestureConflict = enabled
        }
    }

    /// Answers from the cache: reading a system preference and publishing the
    /// conflict belong on the main thread, never in the path of a click. A
    /// stale answer refreshes behind the press and applies to the next one.
    private func dragGestureEnabled(now: TimeInterval) -> Bool {
        dragLock.lock()
        let cache = dragGestureCache
        let needsRefresh = now - cache.readAt > 2 && !dragGestureRefreshScheduled
        if needsRefresh { dragGestureRefreshScheduled = true }
        dragLock.unlock()
        if needsRefresh {
            DispatchQueue.main.async { [weak self] in self?.refreshDragGestureConflict() }
        }
        return cache.enabled
    }

    private static func systemThreeFingerDragEnabled() -> Bool {
        boolPreference("TrackpadThreeFingerDrag", domain: "com.apple.AppleMultitouchTrackpad")
            || boolPreference("TrackpadThreeFingerDrag",
                              domain: "com.apple.driver.AppleBluetoothMultitouch.trackpad")
    }

    private static func boolPreference(_ key: String, domain: String) -> Bool {
        guard let value = CFPreferencesCopyAppValue(key as CFString, domain as CFString) else {
            return false
        }
        return (value as? NSNumber)?.boolValue ?? false
    }

    /// Force-stops everything regardless of the preference. Used by Cleaning
    /// Mode (wiping the trackpad is nothing but stray contacts) and before
    /// the app resets its own permissions.
    func suspend() { stop() }

    // MARK: - Lifecycle

    private func start() {
        guard tapStateLock.withLock({ tap }) == nil else { return }
        guard Multitouch.available else { return }

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(1 << CGEventType.leftMouseDown.rawValue)
                | CGEventMask(1 << CGEventType.leftMouseUp.rawValue)
                | CGEventMask(1 << CGEventType.leftMouseDragged.rawValue)
                | CGEventMask(1 << CGEventType.rightMouseDown.rawValue)
                | CGEventMask(1 << CGEventType.rightMouseUp.rawValue)
                | CGEventMask(1 << CGEventType.rightMouseDragged.rawValue),
            callback: { _, type, event, userInfo in
                guard let userInfo else { return Unmanaged.passUnretained(event) }
                let service = Unmanaged<MiddleClickService>.fromOpaque(userInfo).takeUnretainedValue()
                return service.handle(type: type, event: event)
            },
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else { return }

        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        tapStateLock.withLock {
            self.tap = tap
            runLoopSource = source
        }
        if let source {
            PointerTapRunLoop.add(source)
        }
        CGEvent.tapEnable(tap: tap, enable: true)

        startMultitouch()
        installObservers()
        isRunning = true
    }

    private func stop() {
        stateLock.withLock {
            gestureGeneration &+= 1
            gestureOwners.removeAll()
            spreadProfileID = nil
            touchStream.reset()
            spreadStreams.removeAll()
        }
        // Close a transformed press while this process and its event tap are
        // still alive, before tearing down either source.
        releaseHeldMiddleButton()
        let (port, source) = tapStateLock.withLock { () -> (CFMachPort?, CFRunLoopSource?) in
            let current = (tap, runLoopSource)
            tap = nil
            runLoopSource = nil
            return current
        }
        if let port {
            CGEvent.tapEnable(tap: port, enable: false)
        }
        if let source {
            PointerTapRunLoop.remove(source, invalidating: port)
        }
        stopMultitouch()
        removeObservers()
        tapStateLock.withLock {
            lastTransformEnd = nil
            suppressedButtonSequence = false
        }
        stateLock.lock()
        fingerCount = 0
        physicalButtonDown = false
        lastFrameUptime = 0
        threeFingersSince = nil
        gestureGeneration &+= 1
        touchStream.reset()
        spreadStreams.removeAll()
        stateLock.unlock()
        isRunning = false
    }

    /// Trackpads come and go across sleep and Bluetooth: drop every contact
    /// registration and rebuild from the current device list.
    private func restartMultitouch() {
        guard tapStateLock.withLock({ tap }) != nil else { return }
        stateLock.withLock {
            gestureGeneration &+= 1
            touchStream.reset()
            spreadStreams.removeAll()
        }
        stopMultitouch()
        startMultitouch()
    }

    private func startMultitouch() {
        guard deviceList == nil, let list = Multitouch.deviceList() else { return }
        deviceList = list
        trackpadAvailable = true
        for index in 0..<CFArrayGetCount(list) {
            guard let device = CFArrayGetValueAtIndex(list, index) else { continue }
            Multitouch.register(UnsafeMutableRawPointer(mutating: device), middleClickContactCallback)
            Multitouch.start(UnsafeMutableRawPointer(mutating: device))
        }
    }

    private func stopMultitouch() {
        trackpadAvailable = false
        guard let list = deviceList else { return }
        for index in 0..<CFArrayGetCount(list) {
            guard let device = CFArrayGetValueAtIndex(list, index) else { continue }
            Multitouch.stop(UnsafeMutableRawPointer(mutating: device))
            Multitouch.register(UnsafeMutableRawPointer(mutating: device), nil)
        }
        deviceList = nil
    }

    private func installObservers() {
        guard observers.isEmpty else { return }
        let center = NSWorkspace.shared.notificationCenter
        observers.append(center.addObserver(forName: NSWorkspace.didWakeNotification,
                                            object: nil,
                                            queue: .main) { [weak self] _ in
            self?.restartMultitouch()
        })
        installHotplugObserver()
    }

    /// A Magic Trackpad appearing mid-session (Bluetooth or USB) must start
    /// streaming without a relaunch. Event-driven via IOKit matching; if the
    /// registration fails the internal trackpad still works.
    private func installHotplugObserver() {
        guard hotplugPort == nil else { return }
        guard let port = IONotificationPortCreate(kIOMainPortDefault) else { return }
        IONotificationPortSetDispatchQueue(port, DispatchQueue.main)
        let context = Unmanaged.passUnretained(self).toOpaque()
        var iterator: io_iterator_t = 0
        let result = IOServiceAddMatchingNotification(
            port,
            kIOFirstMatchNotification,
            IOServiceMatching("AppleMultitouchDevice"),
            { context, iterator in
                guard let context else { return }
                while case let entry = IOIteratorNext(iterator), entry != 0 {
                    IOObjectRelease(entry)
                }
                let service = Unmanaged<MiddleClickService>.fromOpaque(context).takeUnretainedValue()
                service.restartMultitouch()
            },
            context,
            &iterator
        )
        guard result == KERN_SUCCESS else {
            IONotificationPortDestroy(port)
            return
        }
        // Drain the existing devices or the notification never arms.
        while case let entry = IOIteratorNext(iterator), entry != 0 {
            IOObjectRelease(entry)
        }
        hotplugPort = port
        hotplugIterator = iterator
    }

    private func removeObservers() {
        let center = NSWorkspace.shared.notificationCenter
        for observer in observers {
            center.removeObserver(observer)
        }
        observers = []
        if hotplugIterator != 0 {
            IOObjectRelease(hotplugIterator)
            hotplugIterator = 0
        }
        if let hotplugPort {
            IONotificationPortDestroy(hotplugPort)
            self.hotplugPort = nil
        }
    }

    // MARK: - Contact frames (multitouch callback thread)

    fileprivate func contactFrame(device: UInt, fingerCount count: Int,
                                  touches: UnsafeMutableRawPointer?) {
        guard count >= 0, count <= 16 else { return }
        let now = ProcessInfo.processInfo.systemUptime
        // Refresh the shared cache even when only radial taps are enabled.
        let dragConflict = dragGestureEnabled(now: now)
        var delivery: (TrackpadGestureOwner, Int, UInt64)?
        stateLock.lock()
        if count == 3 {
            if fingerCount != 3 { threeFingersSince = now }
        } else { threeFingersSince = nil }
        fingerCount = count
        lastFrameUptime = now
        if !gestureOwners.isEmpty || spreadProfileID != nil {
            let geometry = Multitouch.touchGeometry(touches: touches, count: count)
            if let profileID = spreadProfileID {
                var spread = spreadStreams[device] ?? TrackpadSpreadRecognizer()
                if spread.frame(count: count, geometry: geometry, now: now, buttonDown: physicalButtonDown,
                    systemDragGestureEnabled: dragConflict,
                    secondsSinceLastKeyDown: CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: .keyDown)) {
                    touchStream.suppressTap(device: device)
                    delivery = (.radial(profileID), 0, gestureGeneration)
                }
                if count == 0 { spreadStreams.removeValue(forKey: device) }
                else { spreadStreams[device] = spread }
            }
            if let fingers = touchStream.frame(device: device, count: count, geometry: geometry, now: now, buttonDown: physicalButtonDown,
                systemDragGestureEnabled: dragConflict,
                secondsSinceLastKeyDown: CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: .keyDown)),
               let owner = gestureOwners[fingers] {
                delivery = (owner, fingers, gestureGeneration)
            }
        }
        stateLock.unlock()
        if let (owner, fingers, generation) = delivery { postTap(owner: owner, fingers: fingers, generation: generation) }
    }

    /// A judged tap becomes a full middle click at the current pointer. Runs
    /// on the main thread, away from the tap callback; also arms the bounce
    /// guard so a system-synthesized click right behind the tap is not
    /// transformed into a second one.
    private func postTap(owner: TrackpadGestureOwner, fingers: Int, generation: UInt64) {
        DispatchQueue.main.async { [weak self] in
            guard let self, self.tapStateLock.withLock({ self.tap }) != nil,
                  self.stateLock.withLock({ self.gestureGeneration == generation }),
                  SessionActivity.shared.isActive, !CleaningModeManager.shared.isActive,
                  AXIsProcessTrusted() else { return }
            // The system gesture may have changed since the contact frame.
            // Read on main at delivery so the first three-finger tap yields too.
            if fingers == 3 || fingers == 0 {
                self.refreshDragGestureConflict()
                guard !self.systemDragGestureConflict else { return }
            }
            if case .radial(let profileID) = owner {
                RadialMenuService.shared.toggleFromTrackpad(profileID: profileID, spread: fingers == 0)
                return
            }
            guard AppFeature.middleClick.isAvailable,
                  UserDefaults.standard.bool(forKey: DefaultsKey.middleClickEnabled) else { return }
            let position = CGEvent(source: nil)?.location ?? .zero
            // Nothing is synthesized over an app on the exception list.
            guard !MouseAppExceptions.shared.excludesPointerTarget(.middleClick, at: position) else { return }
            let source = CGEventSource(stateID: .hidSystemState)
            guard let down = CGEvent(mouseEventSource: source,
                                     mouseType: .otherMouseDown,
                                     mouseCursorPosition: position,
                                     mouseButton: .center),
                  let up = CGEvent(mouseEventSource: source,
                                   mouseType: .otherMouseUp,
                                   mouseCursorPosition: position,
                                   mouseButton: .center) else { return }
            down.setIntegerValueField(.mouseEventClickState, value: 1)
            up.setIntegerValueField(.mouseEventClickState, value: 1)
            down.post(tap: .cghidEventTap)
            up.post(tap: .cghidEventTap)
            self.tapStateLock.withLock {
                self.lastTransformEnd = ProcessInfo.processInfo.systemUptime
            }
        }
    }

    // MARK: - Event tap (pointer thread)

    private func handle(type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            releaseHeldMiddleButton()
            let enabled = stateLock.withLock { middleClickEnabled || !gestureOwners.isEmpty || spreadProfileID != nil }
            let shouldRearm = SessionActivitySupport.tapShouldRun(
                featureWanted: enabled && !CleaningModeManager.shared.isActive,
                accessibilityGranted: AXIsProcessTrusted(),
                sessionIsActive: SessionActivity.shared.isActive
            )
            if shouldRearm, let port = tapStateLock.withLock({ tap }) {
                CGEvent.tapEnable(tap: port, enable: true)
            } else {
                // The matching middle-up was sent above. Tear the disabled tap
                // down after its callback returns instead of resurrecting it.
                DispatchQueue.main.async { [weak self] in
                    self?.stop()
                    self?.syncWithPreferences()
                }
            }
            return Unmanaged.passUnretained(event)
        }

        if type == .leftMouseDown || type == .rightMouseDown {
            stateLock.withLock {
                physicalButtonDown = true
                gestureGeneration &+= 1
                touchStream.buttonPressed()
                for device in Array(spreadStreams.keys) { spreadStreams[device]?.cancel() }
            }
        }
        if type == .leftMouseUp || type == .rightMouseUp {
            stateLock.withLock { physicalButtonDown = false }
        }
        guard stateLock.withLock({ middleClickEnabled }),
              SessionActivity.shared.isActive, !CleaningModeManager.shared.isActive else {
            return Unmanaged.passUnretained(event)
        }
        let now = ProcessInfo.processInfo.systemUptime
        switch type {
        case .leftMouseDown, .rightMouseDown:
            tapStateLock.lock()
            if suppressedButtonSequence {
                tapStateLock.unlock()
                return nil
            }
            var releaseLostHold = false
            if middleButtonHeld {
                // A lost release must not swallow the user's clicks forever.
                if now - middleButtonHeldSince > 10 {
                    releaseLostHold = true
                } else {
                    // Duplicate synthesized press while the middle button is
                    // already being relayed: drop its whole sequence without
                    // ending the real held click.
                    suppressedButtonSequence = true
                    tapStateLock.unlock()
                    return nil
                }
            }
            tapStateLock.unlock()
            // The release posts an event and waits for it, so it happens with
            // no lock held. It also ends a transform, which the bounce guard
            // below reads back afterwards, exactly as it did inline.
            if releaseLostHold { releaseHeldMiddleButton() }
            // An app on the exception list keeps the plain native click, so a
            // three-finger click means to it what it always meant (issue #358).
            if MouseAppExceptions.shared.excludesPointerTarget(.middleClick, at: event.location) {
                return Unmanaged.passUnretained(event)
            }
            stateLock.lock()
            let spreadActive = spreadStreams.values.contains { $0.didFire }
            let count = fingerCount
            let age = now - lastFrameUptime
            let settledFor = threeFingersSince.map { now - $0 } ?? 0
            stateLock.unlock()
            if spreadActive { return Unmanaged.passUnretained(event) }
            let sinceLastTransformEnd = tapStateLock.withLock { lastTransformEnd }
            let action = MiddleClickSupport.actionForClick(
                fingerCount: count,
                frameAge: age,
                settledFor: settledFor,
                sinceLastTransformEnd: sinceLastTransformEnd.map { now - $0 },
                systemDragGestureEnabled: dragGestureEnabled(now: now)
            )
            switch action {
            case .passThrough:
                return Unmanaged.passUnretained(event)
            case .swallow:
                tapStateLock.withLock { suppressedButtonSequence = true }
                return nil
            case .transform:
                let targetPID = event.getIntegerValueField(.eventTargetUnixProcessID)
                tapStateLock.withLock {
                    middleButtonHeld = true
                    middleButtonHeldSince = now
                    middleButtonTargetPID = targetPID > 0 ? pid_t(targetPID) : nil
                }
                return Unmanaged.passUnretained(asMiddle(event, type: .otherMouseDown))
            }
        case .leftMouseDragged, .rightMouseDragged:
            let (held, suppressed) = tapStateLock.withLock {
                (middleButtonHeld, suppressedButtonSequence)
            }
            if held {
                return Unmanaged.passUnretained(asMiddle(event, type: .otherMouseDragged))
            }
            return suppressed ? nil : Unmanaged.passUnretained(event)
        case .leftMouseUp, .rightMouseUp:
            tapStateLock.lock()
            if suppressedButtonSequence {
                suppressedButtonSequence = false
                tapStateLock.unlock()
                return nil
            }
            guard middleButtonHeld else {
                tapStateLock.unlock()
                return Unmanaged.passUnretained(event)
            }
            middleButtonHeld = false
            middleButtonTargetPID = nil
            lastTransformEnd = now
            tapStateLock.unlock()
            return Unmanaged.passUnretained(asMiddle(event, type: .otherMouseUp))
        default:
            return Unmanaged.passUnretained(event)
        }
    }

    /// A transformed down must always get its matching middle-button up, even
    /// when the native release was lost or the event tap is being torn down.
    private func releaseHeldMiddleButton() {
        tapStateLock.lock()
        suppressedButtonSequence = false
        guard middleButtonHeld else {
            tapStateLock.unlock()
            return
        }
        middleButtonHeld = false
        let targetPID = middleButtonTargetPID
        middleButtonTargetPID = nil
        tapStateLock.unlock()
        let position = CGEvent(source: nil)?.location ?? .zero
        let event = CGEvent(mouseEventSource: CGEventSource(stateID: .hidSystemState),
                            mouseType: .otherMouseUp,
                            mouseCursorPosition: position,
                            mouseButton: .center)
        if let targetPID {
            event?.postToPid(targetPID)
        } else {
            event?.post(tap: .cghidEventTap)
        }
        // CGEvent posting is asynchronous. During app termination, keep this
        // process alive just long enough for WindowServer to deliver the up.
        Thread.sleep(forTimeInterval: 0.02)
        tapStateLock.withLock { lastTransformEnd = ProcessInfo.processInfo.systemUptime }
    }

    /// Rewrites the event in place: same position, timestamp and modifiers,
    /// but a middle-button event instead of its native button.
    private func asMiddle(_ event: CGEvent, type: CGEventType) -> CGEvent {
        event.type = type
        event.setIntegerValueField(.mouseEventButtonNumber, value: 2)
        return event
    }
}

// MARK: - MultitouchSupport bridge

/// The raw contact callback: (device, touches, count, timestamp, frame).
/// The finger count always feeds the press path; the touch records are read
/// (two floats per touch, range-checked) only while the opt-in tap mode is
/// on — see Multitouch.touchGeometry for the layout contract.
private func middleClickContactCallback(_ device: UnsafeMutableRawPointer?,
                                        _ touches: UnsafeMutableRawPointer?,
                                        _ count: Int32,
                                        _ timestamp: Double,
                                        _ frame: Int32) -> Int32 {
    MiddleClickService.shared.contactFrame(device: device.map { UInt(bitPattern: $0) } ?? 0, fingerCount: Int(count), touches: touches)
    return 0
}

/// dlopen/dlsym bridge to MultitouchSupport. Everything is optional: a macOS
/// build without the framework or its symbols makes `available` false and the
/// feature stays off instead of crashing.
private enum Multitouch {
    typealias ContactCallback = @convention(c) (
        UnsafeMutableRawPointer?, UnsafeMutableRawPointer?, Int32, Double, Int32
    ) -> Int32
    private typealias CreateListFn = @convention(c) () -> Unmanaged<CFArray>?
    private typealias RegisterFn = @convention(c) (UnsafeMutableRawPointer, ContactCallback?) -> Void
    private typealias StartFn = @convention(c) (UnsafeMutableRawPointer, Int32) -> Void
    private typealias StopFn = @convention(c) (UnsafeMutableRawPointer) -> Void

    private static let handle: UnsafeMutableRawPointer? = dlopen(
        "/System/Library/PrivateFrameworks/MultitouchSupport.framework/MultitouchSupport",
        RTLD_NOW
    )

    private static let createListFn: CreateListFn? = symbol("MTDeviceCreateList")
    private static let registerFn: RegisterFn? = symbol("MTRegisterContactFrameCallback")
    private static let startFn: StartFn? = symbol("MTDeviceStart")
    private static let stopFn: StopFn? = symbol("MTDeviceStop")

    static var available: Bool {
        createListFn != nil && registerFn != nil && startFn != nil && stopFn != nil
    }

    static func deviceList() -> CFArray? {
        guard let createListFn else { return nil }
        let list = createListFn()?.takeRetainedValue()
        guard let list, CFArrayGetCount(list) > 0 else { return nil }
        return list
    }

    static func register(_ device: UnsafeMutableRawPointer, _ callback: ContactCallback?) {
        registerFn?(device, callback)
    }

    static func start(_ device: UnsafeMutableRawPointer) {
        startFn?(device, 0)
    }

    static func stop(_ device: UnsafeMutableRawPointer) {
        stopFn?(device)
    }

    /// The canonical touch record layout every multitouch utility relies on
    /// (96-byte stride; normalized position floats at offsets 32/36),
    /// unchanged for over a decade. Only those two floats are read, and any
    /// value outside the pad's normalized range means the layout moved: the
    /// frame reports no position and tap detection stands down for the touch
    /// instead of misfiring.
    private static let touchStride = 96
    private static let touchPositionXOffset = 32
    private static let touchPositionYOffset = 36

    /// Centroid plus spread (mean distance of the touches from the centroid):
    /// the spread is what separates a still tap from a pinch, whose centroid
    /// barely moves.
    static func touchGeometry(touches: UnsafeMutableRawPointer?,
                              count: Int) -> (center: (x: Float, y: Float), spread: Float)? {
        guard let touches, count > 0 else { return nil }
        var sumX: Float = 0
        var sumY: Float = 0
        for index in 0..<count {
            let base = touches.advanced(by: index * touchStride)
            let x = base.loadUnaligned(fromByteOffset: touchPositionXOffset, as: Float.self)
            let y = base.loadUnaligned(fromByteOffset: touchPositionYOffset, as: Float.self)
            guard x.isFinite, y.isFinite,
                  x >= -0.2, x <= 1.2, y >= -0.2, y <= 1.2 else { return nil }
            sumX += x
            sumY += y
        }
        let centerX = sumX / Float(count)
        let centerY = sumY / Float(count)
        var spread: Float = 0
        for index in 0..<count {
            let base = touches.advanced(by: index * touchStride)
            let x = base.loadUnaligned(fromByteOffset: touchPositionXOffset, as: Float.self)
            let y = base.loadUnaligned(fromByteOffset: touchPositionYOffset, as: Float.self)
            let dx = x - centerX
            let dy = y - centerY
            spread += (dx * dx + dy * dy).squareRoot()
        }
        spread /= Float(count)
        return ((centerX, centerY), spread)
    }

    private static func symbol<T>(_ name: String) -> T? {
        guard let handle, let raw = dlsym(handle, name) else { return nil }
        return unsafeBitCast(raw, to: T.self)
    }
}
