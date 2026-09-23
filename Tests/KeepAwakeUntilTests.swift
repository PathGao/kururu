// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import Foundation

/// Runs the production session entry points on the closed-lid fixture: how a
/// duration or an end time becomes the session's end date.
enum KeepAwakeUntilTests {
    private typealias C = KeepAwakeLidSleepContract

    static func run(expect: (Bool, String) -> Void) {
        func service() -> C.Service {
            let service = C.reset()
            service.clamshellPreferred = false
            return service
        }
        let past = service()
        past.activate(until: Date().addingTimeInterval(-60))
        expect(!past.isActive && past.endDate == nil, "an end time already passed starts no session")

        let end = Date().addingTimeInterval(3600)
        let until = service()
        until.activate(until: end)
        expect(until.isActive && until.endDate == end && until.sessionTrigger == .manual,
               "an end time starts a manual session that ends then")

        let indefinite = service()
        indefinite.activate(minutes: 0)
        expect(indefinite.isActive && indefinite.endDate == nil, "zero minutes keeps the Mac awake until turned off")

        let timed = service()
        let before = Date()
        timed.activate(minutes: 30)
        let remaining = timed.endDate.map { $0.timeIntervalSince(before) } ?? 0
        expect(timed.isActive && remaining >= 30 * 60 && remaining < 30 * 60 + 5,
               "a duration ends the session that many minutes from now")

        let unlisted = service()
        unlisted.activate(minutes: 7)
        expect(unlisted.isActive && unlisted.endDate == nil,
               "a duration outside the offered choices falls back to indefinite, as before")
    }
}
