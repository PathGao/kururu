// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import Foundation

extension DefaultsKey {
    static let cleanerLastAutoFailed = "cleanerLastAutoFailed"
    static let cleanerLastAutoAttempted = "cleanerLastAutoAttempted"
}

struct CleanerRunResult {
    enum Outcome { case unknown, success, partialFailure, failure }

    let failed: Int
    let attempted: Int

    init(failed: Int, attempted: Int) {
        self.failed = failed
        self.attempted = attempted
    }

    init(defaults: UserDefaults) {
        failed = (defaults.object(forKey: DefaultsKey.cleanerLastAutoFailed) as? NSNumber)?.intValue ?? -1
        attempted = (defaults.object(forKey: DefaultsKey.cleanerLastAutoAttempted) as? NSNumber)?.intValue ?? -1
    }

    func save(freed: Int64, at date: Date, defaults: UserDefaults) {
        defaults.set(date.timeIntervalSince1970, forKey: DefaultsKey.cleanerLastAutoRun)
        defaults.set(freed, forKey: DefaultsKey.cleanerLastAutoFreed)
        defaults.set(failed, forKey: DefaultsKey.cleanerLastAutoFailed)
        defaults.set(attempted, forKey: DefaultsKey.cleanerLastAutoAttempted)
    }

    var outcome: Outcome {
        guard failed >= 0, attempted >= failed else { return .unknown }
        if failed == 0 { return .success }
        return failed == attempted ? .failure : .partialFailure
    }
}
