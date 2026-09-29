import Foundation

enum BrightnessPipelineTests {
    static func run(_ expect: (Bool, String) -> Void) {
        func frame(_ body: [UInt8]) -> [UInt8] { body + [body.reduce(UInt8(0x50), ^)] }
        expect(!BrightnessSupport.acceptsObservation(startedVersion: nil, currentVersion: 1), "old first read cannot overwrite new write")
        expect(!BrightnessSupport.acceptsObservation(startedVersion: 1, currentVersion: 2), "old80 cannot overwrite newer70")
        expect(BrightnessSupport.acceptsObservation(startedVersion: 2, currentVersion: 2), "same display version remains valid when another display writes")
        expect(BrightnessSupport.displayIdentity(uuid: nil, vendor: 1, model: 2, serial: 0) == nil, "ambiguous serial0 display is not cacheable")
        expect(BrightnessSupport.displayIdentity(uuid: "first", vendor: 1, model: 2, serial: 0)
            != BrightnessSupport.displayIdentity(uuid: "second", vendor: 1, model: 2, serial: 0), "identical models use display UUID identity")
        var unavailable = BrightnessState()
        unavailable.unreadable(.identityUnavailable)
        expect(unavailable.status == .unknown && unavailable.failure == .identityUnavailable
            && unavailable.observed == nil, "unidentified display exposes actionable unavailable state without a value")
        var state = BrightnessState()
        expect(state.observed == nil && state.requested == nil, "unknown state never invents50")
        state.observe(0.8, at: Date(timeIntervalSince1970: 10))
        state.request(0.7)
        expect(state.observed == 0.8 && state.requested == 0.7 && state.status == .pending, "request preserves actual reading")
        state.complete(succeeded: true, observed: nil, failure: .checksum)
        expect(state.observed == 0.8 && state.status == .sentUnconfirmed && state.failure == .checksum, "accepted write is unconfirmed on invalid reply")
        state.request(0.6)
        state.complete(succeeded: false, observed: nil, failure: .writeFailed)
        expect(state.observed == 0.8 && state.status == .failed, "failed write retains last actual reading")
        state.request(0.7)
        state.complete(succeeded: true, observed: 0.8, failure: .mismatch)
        expect(state.status == .failed && state.observed == 0.8 && state.requested == 0.7, "readback mismatch remains explicit")
        state.complete(succeeded: true, observed: 0.7, failure: nil)
        expect(state.status == .confirmed && state.requested == nil && state.observed == 0.7, "matching readback confirms")
        let valid: [UInt8] = [0x6e, 0x88, 0x02, 0, 0x10, 0, 0, 100, 0, 80]
        expect(BrightnessSupport.parseReply(frame(valid))?.current == 80, "valid luminance reply reads80")
        for (index, value): (Int, UInt8) in [(0, 0x60), (1, 0x80), (2, 0xbe), (3, 1), (4, 0x12), (5, 2), (7, 0), (9, 101)] {
            var bad = valid; bad[index] = value
            expect(BrightnessSupport.parseReply(frame(bad)) == nil, "reject malformed field \(index) even with valid checksum")
        }
        let nullReply: [UInt8] = [0x6e,0x80,0xbe,0,0x10,0,0,100,0,80,0x90]
        expect(BrightnessSupport.validateReply(nullReply) == .failure(.nullReply), "real monitor NULL reply ignores trailing stale80")
        expect(BrightnessSupport.validateReply([0x6e,0x80,0xbe]) == .failure(.nullReply), "three byte NULL is classified without fabricating a reading")
        expect(BrightnessSupport.parseReply(nullReply) == nil, "NULL never produces luminance")
        expect(BrightnessSupport.parseReply(frame(valid) + [0]) == nil, "reject trailing bytes")
    }
}
