// SPDX-License-Identifier: GPL-3.0-or-later

import Foundation

/// Delivers one Environment snapshot result on the main thread. Cancellation
/// settles immediately, so a queued second brew read cannot retain its caller.
final class HomebrewEnvironmentCheckSettlement: @unchecked Sendable {
    private let lock = NSLock()
    private var settled = false
    private let completion: (EnvironmentHomebrewSnapshot?) -> Void

    init(completion: @escaping (EnvironmentHomebrewSnapshot?) -> Void) {
        self.completion = completion
    }

    func settle(_ snapshot: EnvironmentHomebrewSnapshot?) {
        if Thread.isMainThread {
            settleOnMain(snapshot)
        } else {
            DispatchQueue.main.async { [self] in settleOnMain(snapshot) }
        }
    }

    private func settleOnMain(_ snapshot: EnvironmentHomebrewSnapshot?) {
        lock.lock()
        guard !settled else {
            lock.unlock()
            return
        }
        settled = true
        lock.unlock()
        completion(snapshot)
    }
}
