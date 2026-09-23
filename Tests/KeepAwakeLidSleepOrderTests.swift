// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import Foundation

/// A lid-sleep retry belongs to the restore that queued it. Upstream's
/// contract covers new sessions; this covers a newer restore alone.
enum KeepAwakeLidSleepOrderTests {
    private typealias C = KeepAwakeLidSleepContract

    static func run(expect: (Bool, String) -> Void) {
        let service = C.reset()
        service.isActive = true; service.clamshellActive = true; service.sessionPausedForScreenLock = true
        C.Sudoers.disabled = true; C.results = [1]
        service.disableClamshell(synchronous: false); C.drain()
        expect(C.calls == 1 && C.DispatchQueue.main.pending.count == 1,
               "a restore for a session paused by the screen lock asks for lid sleep and queues a retry")
        service.clamshellActive = true; C.Sudoers.disabled = true
        service.disableClamshell(synchronous: false)
        C.DispatchQueue.main.advance()
        expect(C.calls == 1, "a retry left by an earlier restore cannot sleep while a newer restore is still clearing the override")
        C.drain()
        expect(C.calls == 2 && !C.Sudoers.disabled, "the newer restore asks for lid sleep once its override is cleared")
    }
}
