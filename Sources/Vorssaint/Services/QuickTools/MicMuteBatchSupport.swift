// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import Foundation

enum MicMuteResult: Equatable {
    case muted, unmuted
    case partial(muting: Bool, succeeded: Int, failed: Int)
    case failed(muting: Bool)
    case noDevices
}

struct MicMuteDevice {
    let uid: String
    let name: String
}

struct MicMuteDeviceAccess {
    var muteSwitch: (String) -> UInt32?
    var volume: (String) -> Float?
    var setMuteSwitch: (Bool, String) -> Bool
    var setVolume: (Float, String) -> Bool
    var restorationVolume: ((String) -> Float?)? = nil
    var restoreVolume: ((Float, String) -> Bool)? = nil
    var mayHaveChanged: ((String) -> Bool)? = nil
    var hasMuteSwitch: ((String) -> Bool)? = nil
}

struct MicMuteBatchOutcome {
    let result: MicMuteResult
    let savedVolumes: [String: Double]
    let mutedDevices: [String]
    let failedDeviceNames: [String]
}

enum MicMuteBatchSupport {
    static func apply(muted: Bool, devices: [MicMuteDevice], savedVolumes: [String: Double],
                      mutedDevices: [String]?, legacyVolume: Double,
                      access: MicMuteDeviceAccess) -> MicMuteBatchOutcome {
        var saved = savedVolumes
        var owned = Set(mutedDevices ?? [])
        var succeeded = 0
        var failedNames: [String] = []
        let present = Set(devices.map(\.uid))
        let targets = Set(MicMuteSupport.restoreTargets(recorded: mutedDevices, present: devices.map(\.uid)))
        let restorationVolume = access.restorationVolume ?? access.volume
        let restoreVolume = access.restoreVolume ?? access.setVolume
        func silent(_ uid: String) -> Bool {
            access.muteSwitch(uid) == 1 || (access.volume(uid).map { $0.isFinite && $0 == 0 } ?? false)
        }
        func restoreLevel(_ uid: String) -> Bool {
            guard let volume = restorationVolume(uid), volume.isFinite else { return false }
            if volume > 0 { return true }
            let target = MicMuteSupport.volumeToRestore(uid: uid, saved: saved, legacy: legacyVolume)
            return restoreVolume(target, uid)
                && (restorationVolume(uid).map { $0.isFinite && $0 > 0 } ?? false)
        }
        for device in devices {
            let uid = device.uid
            if muted {
                if silent(uid) { succeeded += 1; continue }
                if access.setMuteSwitch(true, uid), access.muteSwitch(uid) == 1 {
                    // A positive level means the previous volume mute has
                    // already been released. This sweep now owns only the switch.
                    if let volume = access.volume(uid), volume.isFinite, volume > 0 {
                        saved.removeValue(forKey: uid)
                    }
                    owned.insert(uid); succeeded += 1; continue
                }
                if access.muteSwitch(uid) == nil, access.mayHaveChanged?(uid) == true {
                    owned.insert(uid); failedNames.append(device.name); continue
                }
                let volume = access.volume(uid)
                if MicMuteSupport.shouldSaveVolume(volume), let volume { saved[uid] = Double(volume) }
                if access.setVolume(0, uid), silent(uid) {
                    owned.insert(uid); succeeded += 1
                } else {
                    if access.mayHaveChanged?(uid) == true { owned.insert(uid) }
                    if !owned.contains(uid) { saved.removeValue(forKey: uid) }
                    failedNames.append(device.name)
                }
            } else if targets.contains(uid) {
                var restored = false
                let switchValue = access.muteSwitch(uid)
                if let savedLevel = saved[uid], savedLevel.isFinite, savedLevel > 0, savedLevel <= 1 {
                    // The ledger identifies a volume adjustment, not ownership
                    // of a hardware mute somebody may have enabled afterward.
                    restored = restoreLevel(uid)
                } else if saved[uid] == nil, mutedDevices?.contains(uid) == true,
                          access.hasMuteSwitch?(uid) == true, switchValue == 0 {
                    // This tracked switch was already released. Missing volume
                    // controls do not create another obligation; legacy unknown
                    // ownership must still use its existing recovery fallback.
                    restored = true
                } else if switchValue == 1 || (switchValue == nil && access.hasMuteSwitch?(uid) == true) {
                    restored = access.setMuteSwitch(false, uid) && access.muteSwitch(uid) == 0
                } else {
                    restored = restoreLevel(uid)
                }
                if restored {
                    succeeded += 1; owned.remove(uid); saved.removeValue(forKey: uid)
                } else {
                    owned.insert(uid); failedNames.append(device.name)
                }
            }
        }
        if !muted { failedNames += owned.subtracting(present).sorted() }
        let result: MicMuteResult
        if devices.isEmpty, !muted, !owned.isEmpty { result = .failed(muting: false) }
        else if devices.isEmpty { result = .noDevices }
        else if failedNames.isEmpty { result = muted ? .muted : .unmuted }
        else if succeeded > 0 { result = .partial(muting: muted, succeeded: succeeded, failed: failedNames.count) }
        else { result = .failed(muting: muted) }
        return MicMuteBatchOutcome(result: result, savedVolumes: saved, mutedDevices: owned.sorted(), failedDeviceNames: failedNames)
    }
}

/// The actual HAL adapter policy. New mute writes use only the master
/// element; restoring an old scalar ledger can still release legacy channels.
enum MicMuteVolumeSupport {
    static func elements(restoring: Bool, hasProperty: (UInt32) -> Bool) -> [UInt32] {
        if hasProperty(0) { return [0] }
        return restoring ? [UInt32(1), 2].filter(hasProperty) : []
    }

    static func read(restoring: Bool, hasProperty: (UInt32) -> Bool,
                     read: (UInt32) -> Float?) -> Float? {
        let channels = elements(restoring: restoring, hasProperty: hasProperty)
        guard !channels.isEmpty else { return nil }
        let values = channels.compactMap(read)
        guard values.count == channels.count, values.allSatisfy({ $0.isFinite && $0 >= 0 && $0 <= 1 }) else { return nil }
        // A legacy restore is incomplete while any channel remains zero.
        return values.min()
    }

    static func write(_ value: Float, restoring: Bool,
                      hasProperty: (UInt32) -> Bool, isSettable: (UInt32) -> Bool,
                      read: (UInt32) -> Float?, write: (Float, UInt32) -> Bool) -> Bool {
        let channels = elements(restoring: restoring, hasProperty: hasProperty)
        guard !channels.isEmpty else { return false }
        var pending: [UInt32] = []
        for channel in channels {
            guard let current = read(channel), current.isFinite, current >= 0, current <= 1 else { return false }
            if !restoring || current == 0 { pending.append(channel) }
        }
        guard pending.allSatisfy(isSettable) else { return false }
        var allWritten = true
        for channel in pending { if !write(value, channel) { allWritten = false } }
        return allWritten && channels.allSatisfy { channel in
            guard let actual = read(channel), actual.isFinite else { return false }
            return value == 0 ? actual == 0 : actual > 0 && actual <= 1
        }
    }
}

extension MicMuteBatchSupport {
    static func toggleTarget(isMuteRequested: Bool, lastResult: MicMuteResult?) -> Bool {
        switch lastResult {
        case .partial(muting: false, succeeded: _, failed: _), .failed(muting: false): return false
        default: return !isMuteRequested
        }
    }
}
