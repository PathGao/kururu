// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import Foundation

enum MicMuteBatchTests {
    private final class Fixture {
        var volumes: [String: Float] = ["a": 0.6, "b": 0.8]
        var refuses: Set<String> = []
        var unreadable: Set<String> = []
        var writes: [String] = []
        var access: MicMuteDeviceAccess {
            MicMuteDeviceAccess(muteSwitch: { _ in nil },
                volume: { self.unreadable.contains($0) ? nil : self.volumes[$0] },
                setMuteSwitch: { _, _ in false },
                setVolume: { volume, uid in
                    self.writes.append(uid)
                    guard !self.refuses.contains(uid) else { return false }
                    self.volumes[uid] = volume
                    return true
                })
        }
    }
    static func run(_ expect: (Bool, String) -> Void) {
        let devices = [MicMuteDevice(uid: "a", name: "Built-in"), MicMuteDevice(uid: "b", name: "Headset")]
        let hardware = Fixture()
        hardware.refuses = ["b"]
        let partial = MicMuteBatchSupport.apply(muted: true, devices: devices, savedVolumes: [:], mutedDevices: [], legacyVolume: 0, access: hardware.access)
        expect(partial.result == .partial(muting: true, succeeded: 1, failed: 1), "A muted and B refused cannot report all microphones muted")
        expect(partial.mutedDevices == ["a"] && abs((partial.savedVolumes["a"] ?? 0) - 0.6) < 0.001,
               "partial mute preserves only the successfully changed device and its original level")
        expect(partial.failedDeviceNames == ["Headset"], "failure identifies the actual device")
        hardware.refuses = ["a", "b"]
        hardware.volumes = ["a": 0.6, "b": 0.8]
        let failed = MicMuteBatchSupport.apply(muted: true, devices: devices, savedVolumes: [:], mutedDevices: [], legacyVolume: 0, access: hardware.access)
        expect(failed.result == .failed(muting: true) && failed.mutedDevices.isEmpty, "all-failed mute has visible failure and no false ownership")
        let empty = MicMuteBatchSupport.apply(muted: true, devices: [], savedVolumes: partial.savedVolumes, mutedDevices: partial.mutedDevices, legacyVolume: 0, access: hardware.access)
        expect(empty.result == .noDevices && empty.mutedDevices == ["a"], "no devices reports absence without discarding recovery ownership")
        hardware.refuses = []
        hardware.volumes = ["a": 0, "b": 0]
        let recovered = MicMuteBatchSupport.apply(muted: false, devices: devices, savedVolumes: partial.savedVolumes, mutedDevices: partial.mutedDevices, legacyVolume: 0, access: hardware.access)
        expect(recovered.result == .unmuted && recovered.mutedDevices.isEmpty && abs((hardware.volumes["a"] ?? 0) - 0.6) < 0.001,
               "a superseded mute still supplies its recovery ledger to the following unmute")
        expect(hardware.volumes["b"] == 0, "restoration never unmutes a microphone silenced by its user")
        hardware.volumes = ["a": 0, "b": 0]
        hardware.refuses = ["b"]
        let restorePartial = MicMuteBatchSupport.apply(muted: false, devices: devices, savedVolumes: ["a": 0.6, "b": 0.8], mutedDevices: ["a", "b"], legacyVolume: 0, access: hardware.access)
        expect(restorePartial.result == .partial(muting: false, succeeded: 1, failed: 1), "partial restore cannot report complete recovery")
        expect(restorePartial.mutedDevices == ["b"] && restorePartial.savedVolumes["b"] == 0.8,
               "failed restoration retains its UID and saved level")
        let missing = MicMuteBatchSupport.apply(muted: false, devices: [devices[0]], savedVolumes: restorePartial.savedVolumes, mutedDevices: restorePartial.mutedDevices, legacyVolume: 0, access: hardware.access)
        expect(missing.result == .failed(muting: false) && missing.mutedDevices == ["b"], "disconnected owned device remains pending restoration")
        hardware.refuses = []
        let reconnected = MicMuteBatchSupport.apply(muted: false, devices: devices, savedVolumes: missing.savedVolumes, mutedDevices: missing.mutedDevices, legacyVolume: 0, access: hardware.access)
        expect(reconnected.result == .unmuted && reconnected.mutedDevices.isEmpty && abs((hardware.volumes["b"] ?? 0) - 0.8) < 0.001,
               "reconnected device restores the original saved value")
        hardware.unreadable = ["a"]
        let unreadable = MicMuteBatchSupport.apply(muted: false, devices: [devices[0]], savedVolumes: ["a": 0.6], mutedDevices: ["a"], legacyVolume: 0, access: hardware.access)
        expect(unreadable.result == .failed(muting: false) && unreadable.mutedDevices == ["a"], "unreadable restoration is a failure, not a no-op success")
        let refusedReadback = MicMuteDeviceAccess(muteSwitch: { _ in 0 }, volume: { _ in 0.6 },
            setMuteSwitch: { _, _ in true }, setVolume: { _, _ in true })
        let falseSuccess = MicMuteBatchSupport.apply(muted: true, devices: [devices[0]], savedVolumes: [:], mutedDevices: [], legacyVolume: 0, access: refusedReadback)
        expect(falseSuccess.result == .failed(muting: true) && falseSuccess.mutedDevices.isEmpty,
               "driver write acknowledgements without changed readback never confirm a mute")
        let refusedRestore = MicMuteDeviceAccess(muteSwitch: { _ in nil }, volume: { _ in 0 },
            setMuteSwitch: { _, _ in false }, setVolume: { _, _ in true })
        let falseRestore = MicMuteBatchSupport.apply(muted: false, devices: [devices[0]], savedVolumes: ["a": 0.6], mutedDevices: ["a"], legacyVolume: 0, access: refusedRestore)
        expect(falseRestore.result == .failed(muting: false) && falseRestore.savedVolumes["a"] == 0.6 && falseRestore.mutedDevices == ["a"],
               "a restore write that leaves the volume zero retains recovery state")
        expect(!MicMuteBatchSupport.toggleTarget(isMuteRequested: false, lastResult: .failed(muting: false)),
               "the default action retries failed recovery instead of muting again")
        expect(!MicMuteBatchSupport.toggleTarget(isMuteRequested: false, lastResult: .partial(muting: false, succeeded: 1, failed: 1)),
               "partial recovery defaults to restoring remaining devices")
        expect(!MicMuteBatchSupport.toggleTarget(isMuteRequested: true, lastResult: partial.result),
               "a partial mute defaults to releasing the microphones it did change")
        expect(MicMuteBatchSupport.toggleTarget(isMuteRequested: false, lastResult: .unmuted),
               "a fully restored operation can request a new mute")
        let quiet = Fixture()
        quiet.volumes = ["a": 0.005]
        let quietMute = MicMuteBatchSupport.apply(muted: true, devices: [devices[0]], savedVolumes: [:], mutedDevices: [], legacyVolume: 0, access: quiet.access)
        expect(quiet.writes == ["a"] && quiet.volumes["a"] == 0 && quietMute.mutedDevices == ["a"],
               "nonzero low volume is still audible and must actually be muted")
        _ = MicMuteBatchSupport.apply(muted: false, devices: [devices[0]], savedVolumes: quietMute.savedVolumes, mutedDevices: quietMute.mutedDevices, legacyVolume: 0, access: quiet.access)
        expect(abs((quiet.volumes["a"] ?? 0) - 0.005) < 0.00001, "restoring a quiet microphone preserves its exact low level instead of fallback volume")
        var channels: [UInt32: Float] = [1: 0.6, 2: 0.8]
        var touched: [UInt32] = []
        let newMute = MicMuteVolumeSupport.write(0, restoring: false,
            hasProperty: { channels[$0] != nil }, isSettable: { _ in true }, read: { channels[$0] },
            write: { value, element in touched.append(element); channels[element] = value; return true })
        expect(!newMute && touched.isEmpty && channels[1] == 0.6 && channels[2] == 0.8,
               "the real adapter policy refuses new mute on channel-only devices before writing anything")
        channels = [1: 0, 2: 0]
        let legacyRestore = MicMuteVolumeSupport.write(0.6, restoring: true,
            hasProperty: { channels[$0] != nil }, isSettable: { _ in true }, read: { channels[$0] },
            write: { value, element in if element == 2 { return false }; channels[element] = value; return true })
        expect(!legacyRestore && MicMuteVolumeSupport.read(restoring: true, hasProperty: { channels[$0] != nil }, read: { channels[$0] }) == 0,
               "one restored legacy channel cannot claim the device is restored")
        channels = [0: 0.7, 1: 0.4, 2: 0.8]
        touched = []
        let masterMute = MicMuteVolumeSupport.write(0, restoring: false,
            hasProperty: { channels[$0] != nil }, isSettable: { _ in true }, read: { channels[$0] },
            write: { value, element in touched.append(element); channels[element] = value; return true })
        expect(masterMute && touched == [0], "master mute does not overwrite independent channel levels")
        var wroteUnconfirmed = false
        let unknownAfterWrite = MicMuteDeviceAccess(muteSwitch: { _ in nil },
            volume: { _ in wroteUnconfirmed ? nil : 0.2 }, setMuteSwitch: { _, _ in false },
            setVolume: { value, _ in
                MicMuteVolumeSupport.write(value, restoring: false, hasProperty: { $0 == 0 }, isSettable: { _ in true },
                    read: { _ in wroteUnconfirmed ? nil : 0.2 }, write: { _, _ in wroteUnconfirmed = true; return true })
            }, mayHaveChanged: { _ in wroteUnconfirmed })
        let unconfirmed = MicMuteBatchSupport.apply(muted: true, devices: [devices[0]], savedVolumes: [:], mutedDevices: [], legacyVolume: 0, access: unknownAfterWrite)
        expect(unconfirmed.result == .failed(muting: true) && unconfirmed.mutedDevices == ["a"]
               && abs((unconfirmed.savedVolumes["a"] ?? 0) - 0.2) < 0.001,
               "acknowledged master write with unavailable readback retains ownership and original volume while reporting failure")
        let offlineRecovery = MicMuteBatchSupport.apply(muted: false, devices: [], savedVolumes: ["a": 0.6], mutedDevices: ["a"], legacyVolume: 0, access: hardware.access)
        expect(offlineRecovery.result == .failed(muting: false)
               && !MicMuteBatchSupport.toggleTarget(isMuteRequested: false, lastResult: offlineRecovery.result),
               "all devices disconnected with pending recovery keeps the next action restoring")
        expect(MicMuteBatchSupport.toggleTarget(isMuteRequested: false, lastResult: .noDevices),
               "no devices without recovery ownership does not trap the next action in restoring")
        channels = [1: 0, 2: 0.2]
        touched = []
        let preserveAdjustment = MicMuteVolumeSupport.write(0.6, restoring: true,
            hasProperty: { channels[$0] != nil }, isSettable: { _ in true }, read: { channels[$0] },
            write: { value, element in touched.append(element); channels[element] = value; return true })
        expect(preserveAdjustment && touched == [1] && channels[1] == 0.6 && channels[2] == 0.2,
               "legacy recovery restores zero channels while preserving a user's nonzero adjustment")
        let unknownMuteSwitch = MicMuteDeviceAccess(muteSwitch: { _ in nil }, volume: { _ in 0.6 },
            setMuteSwitch: { _, _ in false }, setVolume: { _, _ in false }, hasMuteSwitch: { _ in true })
        let unknownSwitchRestore = MicMuteBatchSupport.apply(muted: false, devices: [devices[0]], savedVolumes: [:], mutedDevices: ["a"], legacyVolume: 0, access: unknownMuteSwitch)
        expect(unknownSwitchRestore.result == .failed(muting: false) && unknownSwitchRestore.mutedDevices == ["a"],
               "positive volume cannot release ownership while a hardware mute switch remains unreadable")
        var ownedVolume: Float = 0
        var externalSwitch: UInt32 = 1
        var switchWrites = 0
        let layered = MicMuteDeviceAccess(muteSwitch: { _ in externalSwitch }, volume: { _ in ownedVolume },
            setMuteSwitch: { value, _ in switchWrites += 1; externalSwitch = value ? 1 : 0; return true },
            setVolume: { value, _ in ownedVolume = value; return true }, hasMuteSwitch: { _ in true })
        let volumeOwned = MicMuteBatchSupport.apply(muted: false, devices: [devices[0]], savedVolumes: ["a": 0.6], mutedDevices: ["a"], legacyVolume: 0, access: layered)
        expect(volumeOwned.result == .unmuted && ownedVolume == 0.6 && externalSwitch == 1 && switchWrites == 0,
               "a saved-volume restore leaves an external hardware mute untouched")
        expect(volumeOwned.savedVolumes.isEmpty && volumeOwned.mutedDevices.isEmpty,
               "volume ownership releases only after restoring the owned level")
        ownedVolume = 0.2
        externalSwitch = 0
        switchWrites = 0
        let hardwareOwned = MicMuteBatchSupport.apply(muted: true, devices: [devices[0]], savedVolumes: ["a": 0.6], mutedDevices: ["a"], legacyVolume: 0, access: layered)
        expect(hardwareOwned.result == .muted && hardwareOwned.savedVolumes.isEmpty && externalSwitch == 1,
               "a verified hardware takeover at a positive user-adjusted volume retires stale volume ownership")
        _ = MicMuteBatchSupport.apply(muted: false, devices: devices, savedVolumes: hardwareOwned.savedVolumes, mutedDevices: hardwareOwned.mutedDevices, legacyVolume: 0, access: layered)
        expect(ownedVolume == 0.2 && externalSwitch == 0 && switchWrites == 2,
               "hardware-owned recovery releases only the owned switch and preserves the adjusted volume")
        var releasedWrites = 0
        let manuallyReleased = MicMuteDeviceAccess(muteSwitch: { _ in 0 }, volume: { _ in nil },
            setMuteSwitch: { _, _ in releasedWrites += 1; return false },
            setVolume: { _, _ in releasedWrites += 1; return false }, hasMuteSwitch: { _ in true })
        let trackedReleased = MicMuteBatchSupport.apply(muted: false, devices: [devices[0]], savedVolumes: [:], mutedDevices: ["a"], legacyVolume: 0, access: manuallyReleased)
        expect(trackedReleased.result == .unmuted && trackedReleased.mutedDevices.isEmpty && releasedWrites == 0,
               "a tracked hardware mute already cleared by the user releases ownership without needing a volume property")
        let legacyReleased = MicMuteBatchSupport.apply(muted: false, devices: [devices[0]], savedVolumes: [:], mutedDevices: nil, legacyVolume: 0, access: manuallyReleased)
        expect(legacyReleased.result == .failed(muting: false) && legacyReleased.mutedDevices == ["a"],
               "an untracked legacy restore still requires its original volume fallback evidence")
    }
}
