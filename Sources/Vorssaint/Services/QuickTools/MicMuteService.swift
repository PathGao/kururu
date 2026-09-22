// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import AppKit
import CoreAudio
import Foundation

/// Global microphone mute: one click or shortcut cuts every microphone the Mac
/// has, in any app. Muting only the system default is not enough, because an
/// app can be pointed at a device of its own (a headset picked inside a call
/// app keeps recording while the Mac's default sits muted), so the mute is
/// applied device by device. Each device uses its own mute switch when it has
/// one, else its input volume drops to zero and the saved level comes back on
/// unmute. A device that arrives while muted is muted as it appears, the mute
/// is re-asserted when the default input changes, and the state survives app
/// relaunches via the persisted flag.
final class MicMuteService: ObservableObject {
    static let shared = MicMuteService()

    @Published private(set) var isMuted = false
    @Published private(set) var isMuteRequested = false
    @Published private(set) var isApplying = false
    @Published private(set) var lastResult: MicMuteResult?
    @Published private(set) var failedDeviceNames: [String] = []
    @Published private(set) var shortcutRegistrationFailed = false

    private let hotkey = QuickToolHotkey(id: 12)
    private var installedListeners: [AudioObjectPropertySelector] = []
    /// Reading or writing a device property can block for as long as the audio
    /// daemon holds the device (a headset connecting, an interface waking),
    /// and that is exactly the moment the listeners fire. Sweeping every
    /// device on the main thread would hand the app one hang per reconnection,
    /// so all of it happens here, one sweep at a time.
    private let halQueue = DispatchQueue(label: "com.vorssaint.utils.micmute.hal", qos: .userInitiated)
    /// A sweep that finished after a newer one started must not publish what
    /// it saw.
    private var applyGeneration = 0

    private init() {
        hotkey.onPress = { [weak self] in self?.toggle() }
    }

    /// The smallest possible answer to a change: the system decides which
    /// thread this arrives on, so it only asks the main thread to re-assert
    /// the mute and returns. Handing a closure back to be removed never
    /// matches the one that was registered, so the plain callback is what
    /// makes stopping work.
    private static let listenerCallback: AudioObjectPropertyListenerProc = { _, _, _, client in
        guard let client else { return noErr }
        let service = Unmanaged<MicMuteService>.fromOpaque(client).takeUnretainedValue()
        DispatchQueue.main.async { service.reapplyIfNeeded() }
        return noErr
    }

    /// Unretained is safe here and only here: this is a single instance that
    /// lives as long as the app.
    private var listenerClient: UnsafeMutableRawPointer {
        Unmanaged.passUnretained(self).toOpaque()
    }

    func syncWithPreferences() {
        let available = AppFeature.micMute.isAvailable
        let enabled = available
            && UserDefaults.standard.bool(forKey: DefaultsKey.micMuteShortcutEnabled)
        let shortcut = GlobalShortcut.saved(for: DefaultsKey.micMuteShortcut,
                                            fallback: .micMuteDefault)
        shortcutRegistrationFailed = !hotkey.sync(enabled: enabled, shortcut: shortcut,
                                                  storageKey: DefaultsKey.micMuteShortcut)

        let defaults = UserDefaults.standard
        let wantsMute = available && defaults.bool(forKey: DefaultsKey.micMuteActive)
        let hasRecovery = !(defaults.stringArray(forKey: DefaultsKey.micMuteMutedDevices) ?? []).isEmpty
        if wantsMute || hasRecovery || defaults.bool(forKey: DefaultsKey.micMuteActive) {
            apply(muted: wantsMute, announce: false)
        } else {
            isMuteRequested = false
            isMuted = false
            syncListeners()
        }
    }

    /// A pending restore needs device-arrival notifications too. It must not
    /// be confused with a request to keep all microphones muted.
    private func syncListeners() {
        let pending = !(UserDefaults.standard.stringArray(forKey: DefaultsKey.micMuteMutedDevices) ?? []).isEmpty
        if isMuteRequested || pending { installListeners() }
        else { removeListeners() }
    }

    func suspend() {
        hotkey.unregister()
    }

    func toggle() {
        guard !isApplying else { return }
        setMuted(MicMuteBatchSupport.toggleTarget(isMuteRequested: isMuteRequested, lastResult: lastResult))
    }

    func setMuted(_ muted: Bool) {
        apply(muted: muted, announce: true)
    }

    /// Unmute for a caller that is about to tear the app down. The queue that
    /// carries a normal sweep may never be drained once the app is going away,
    /// and a microphone left cut by an app that no longer exists is the one
    /// failure this feature cannot afford, so this one waits.
    func unmuteForTeardown() -> Bool {
        let defaults = UserDefaults.standard
        guard defaults.bool(forKey: DefaultsKey.micMuteActive)
            || !(defaults.stringArray(forKey: DefaultsKey.micMuteMutedDevices) ?? []).isEmpty
            || isApplying else { return true }
        applyGeneration += 1
        defaults.set(false, forKey: DefaultsKey.micMuteActive)
        isMuteRequested = false
        let outcome = halQueue.sync { Self.runSweep(muted: false) }
        isApplying = false
        isMuted = false
        lastResult = outcome.result
        failedDeviceNames = outcome.failedDeviceNames
        let restored = outcome.mutedDevices.isEmpty
            && (outcome.result == .unmuted || outcome.result == .noDevices)
        if restored { removeListeners() }
        else { syncListeners() }
        return restored
    }

    private func reapplyIfNeeded() {
        let defaults = UserDefaults.standard
        let requested = defaults.bool(forKey: DefaultsKey.micMuteActive)
        guard requested || !(defaults.stringArray(forKey: DefaultsKey.micMuteMutedDevices) ?? []).isEmpty else { return }
        apply(muted: requested && AppFeature.micMute.isAvailable, announce: false)
    }

    // MARK: - Applying

    private func apply(muted: Bool, announce: Bool) {
        let requested = muted && AppFeature.micMute.isAvailable
        UserDefaults.standard.set(requested, forKey: DefaultsKey.micMuteActive)
        isMuteRequested = requested
        isApplying = true
        // A previous full-mute observation no longer proves the current batch.
        isMuted = false
        syncListeners()
        applyGeneration += 1
        let generation = applyGeneration
        halQueue.async { [weak self] in
            let outcome = Self.runSweep(muted: requested)
            DispatchQueue.main.async {
                self?.finish(outcome, announce: announce, generation: generation)
            }
        }
    }

    /// Serialized physical sweeps always persist their recovery ledger, even
    /// when a newer request supersedes their right to publish UI. The next
    /// sweep reads this ledger here, after all earlier hardware writes finish.
    private static func runSweep(muted: Bool) -> MicMuteBatchOutcome {
        let defaults = UserDefaults.standard
        let devices = inputDevices()
        let identifiers = Dictionary(uniqueKeysWithValues: devices.map { ($0.uid, $0.id) })
        var potentiallyChanged: Set<String> = []
        let access = MicMuteDeviceAccess(
            muteSwitch: { uid in identifiers[uid].flatMap { muteSwitchValue(of: $0) } },
            volume: { uid in identifiers[uid].flatMap { inputVolume(of: $0) } },
            setMuteSwitch: { muted, uid in identifiers[uid].map { setMuteSwitch(muted, of: $0, didWrite: { potentiallyChanged.insert(uid) }) } ?? false },
            setVolume: { volume, uid in identifiers[uid].map { setInputVolume(volume, of: $0, didWrite: { potentiallyChanged.insert(uid) }) } ?? false },
            restorationVolume: { uid in identifiers[uid].flatMap { inputVolume(of: $0, restoring: true) } },
            restoreVolume: { volume, uid in identifiers[uid].map { setInputVolume(volume, of: $0, restoring: true) } ?? false },
            mayHaveChanged: { potentiallyChanged.contains($0) },
            hasMuteSwitch: { uid in
                guard let id = identifiers[uid] else { return false }
                var address = muteAddress()
                return AudioObjectHasProperty(id, &address)
            })
        let outcome = MicMuteBatchSupport.apply(muted: muted,
            devices: devices.map { MicMuteDevice(uid: $0.uid, name: $0.name) },
            savedVolumes: defaults.dictionary(forKey: DefaultsKey.micMuteSavedVolumes) as? [String: Double] ?? [:],
            mutedDevices: defaults.stringArray(forKey: DefaultsKey.micMuteMutedDevices),
            legacyVolume: defaults.double(forKey: DefaultsKey.micMuteSavedVolume), access: access)
        defaults.set(outcome.savedVolumes, forKey: DefaultsKey.micMuteSavedVolumes)
        defaults.set(outcome.mutedDevices, forKey: DefaultsKey.micMuteMutedDevices)
        return outcome
    }

    private func finish(_ outcome: MicMuteBatchOutcome, announce: Bool, generation: Int) {
        guard generation == applyGeneration else { return }
        isApplying = false
        isMuted = outcome.result == .muted
        lastResult = outcome.result
        failedDeviceNames = outcome.failedDeviceNames
        syncListeners()
        guard announce else { return }
        let text = FeatureStrings.micMute(L10n.shared.language)
        QuickToolHUD.show(icon: text.resultSymbol(for: outcome.result),
                          message: text.resultMessage(for: outcome.result))
    }

    // MARK: - CoreAudio

    private struct InputDevice {
        let id: AudioDeviceID
        let uid: String
        let name: String
    }

    /// Every device that can capture audio, skipping the app's own mixing
    /// device and the ones the system is not really offering.
    private static func inputDevices() -> [InputDevice] {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var size: UInt32 = 0
        guard AudioObjectGetPropertyDataSize(AudioObjectID(kAudioObjectSystemObject),
                                             &address, 0, nil, &size) == noErr, size > 0 else { return [] }
        var deviceIDs = [AudioDeviceID](repeating: 0, count: Int(size) / MemoryLayout<AudioDeviceID>.size)
        guard AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject),
                                         &address, 0, nil, &size, &deviceIDs) == noErr else { return [] }

        var devices: [InputDevice] = []
        for deviceID in deviceIDs {
            guard hasInputStreams(deviceID) else { continue }

            var isAlive: UInt32 = 1
            if read(deviceID, kAudioDevicePropertyDeviceIsAlive, &isAlive), isAlive == 0 { continue }

            var uidRef: CFString = "" as CFString
            guard read(deviceID, kAudioDevicePropertyDeviceUID, &uidRef) else { continue }
            let uid = uidRef as String
            guard !uid.isEmpty else { continue }

            var nameRef: CFString = "" as CFString
            let name = read(deviceID, kAudioObjectPropertyName, &nameRef) ? nameRef as String : uid
            guard !MicMuteSupport.isOwnDevice(name: name) else { continue }

            devices.append(InputDevice(id: deviceID, uid: uid, name: name))
        }
        return devices
    }

    private static func hasInputStreams(_ deviceID: AudioDeviceID) -> Bool {
        var address = AudioObjectPropertyAddress(mSelector: kAudioDevicePropertyStreams,
                                                 mScope: kAudioDevicePropertyScopeInput,
                                                 mElement: kAudioObjectPropertyElementMain)
        var size: UInt32 = 0
        return AudioObjectGetPropertyDataSize(deviceID, &address, 0, nil, &size) == noErr
            && size >= MemoryLayout<AudioObjectID>.size
    }

    private static func muteAddress() -> AudioObjectPropertyAddress {
        AudioObjectPropertyAddress(mSelector: kAudioDevicePropertyMute,
                                   mScope: kAudioDevicePropertyScopeInput,
                                   mElement: kAudioObjectPropertyElementMain)
    }

    private static func muteSwitchValue(of device: AudioDeviceID) -> UInt32? {
        var address = muteAddress()
        guard AudioObjectHasProperty(device, &address) else { return nil }
        var value: UInt32 = 0
        var size = UInt32(MemoryLayout<UInt32>.size)
        guard AudioObjectGetPropertyData(device, &address, 0, nil, &size, &value) == noErr else { return nil }
        return value
    }

    /// The device's own mute switch, when it has one that can be written. Some
    /// drivers answer a write with success and keep their own value, so the
    /// switch only counts when the device reads back the way it was asked to;
    /// otherwise the caller still has the volume to fall back on.
    private static func setMuteSwitch(_ muted: Bool, of device: AudioDeviceID, didWrite: () -> Void = {}) -> Bool {
        var address = muteAddress()
        var settable = DarwinBoolean(false)
        guard AudioObjectHasProperty(device, &address),
              AudioObjectIsPropertySettable(device, &address, &settable) == noErr,
              settable.boolValue else { return false }
        var value: UInt32 = muted ? 1 : 0
        guard AudioObjectSetPropertyData(device, &address, 0, nil,
                                         UInt32(MemoryLayout<UInt32>.size), &value) == noErr else { return false }
        didWrite()
        guard let readBack = muteSwitchValue(of: device) else { return false }
        return readBack == value
    }

    private static func volumeAddress(_ element: UInt32) -> AudioObjectPropertyAddress {
        AudioObjectPropertyAddress(mSelector: kAudioDevicePropertyVolumeScalar,
                                   mScope: kAudioDevicePropertyScopeInput, mElement: element)
    }

    private static func hasVolume(_ device: AudioDeviceID, element: UInt32) -> Bool {
        var address = volumeAddress(element)
        return AudioObjectHasProperty(device, &address)
    }

    private static func readVolume(_ device: AudioDeviceID, element: UInt32) -> Float? {
        var address = volumeAddress(element)
        var volume = Float(0)
        var size = UInt32(MemoryLayout<Float>.size)
        guard AudioObjectGetPropertyData(device, &address, 0, nil, &size, &volume) == noErr else { return nil }
        return volume
    }

    private static func inputVolume(of device: AudioDeviceID, restoring: Bool = false) -> Float? {
        MicMuteVolumeSupport.read(restoring: restoring,
            hasProperty: { hasVolume(device, element: $0) },
            read: { readVolume(device, element: $0) })
    }

    private static func setInputVolume(_ volume: Float, of device: AudioDeviceID, restoring: Bool = false, didWrite: () -> Void = {}) -> Bool {
        MicMuteVolumeSupport.write(volume, restoring: restoring,
            hasProperty: { hasVolume(device, element: $0) },
            isSettable: { element in
                var address = volumeAddress(element)
                var settable = DarwinBoolean(false)
                return AudioObjectIsPropertySettable(device, &address, &settable) == noErr && settable.boolValue
            }, read: { readVolume(device, element: $0) },
            write: { value, element in
                var address = volumeAddress(element)
                var value = value
                let written = AudioObjectSetPropertyData(device, &address, 0, nil,
                    UInt32(MemoryLayout<Float>.size), &value) == noErr
                if written { didWrite() }
                return written
            })
    }

    @discardableResult
    private static func read<T>(_ object: AudioObjectID,
                                _ selector: AudioObjectPropertySelector,
                                _ value: inout T) -> Bool {
        var address = AudioObjectPropertyAddress(mSelector: selector,
                                                 mScope: kAudioObjectPropertyScopeGlobal,
                                                 mElement: kAudioObjectPropertyElementMain)
        var size = UInt32(MemoryLayout<T>.size)
        return withUnsafeMutablePointer(to: &value) { pointer in
            AudioObjectGetPropertyData(object, &address, 0, nil, &size,
                                       UnsafeMutableRawPointer(pointer)) == noErr
        }
    }

    // MARK: - Listeners

    /// Two changes can defeat an active mute: a device arriving (a headset
    /// connecting mid call) and the default input moving. Both re-assert it.
    private static let watchedSelectors: [AudioObjectPropertySelector] = [
        kAudioHardwarePropertyDevices,
        kAudioHardwarePropertyDefaultInputDevice,
    ]

    private func installListeners() {
        for selector in Self.watchedSelectors where !installedListeners.contains(selector) {
            var address = AudioObjectPropertyAddress(mSelector: selector,
                                                     mScope: kAudioObjectPropertyScopeGlobal,
                                                     mElement: kAudioObjectPropertyElementMain)
            let status = AudioObjectAddPropertyListener(AudioObjectID(kAudioObjectSystemObject),
                                                        &address, Self.listenerCallback,
                                                        listenerClient)
            if status == noErr {
                installedListeners.append(selector)
            }
        }
    }

    private func removeListeners() {
        for selector in installedListeners {
            var address = AudioObjectPropertyAddress(mSelector: selector,
                                                     mScope: kAudioObjectPropertyScopeGlobal,
                                                     mElement: kAudioObjectPropertyElementMain)
            AudioObjectRemovePropertyListener(AudioObjectID(kAudioObjectSystemObject),
                                              &address, Self.listenerCallback,
                                              listenerClient)
        }
        installedListeners.removeAll()
    }
}
