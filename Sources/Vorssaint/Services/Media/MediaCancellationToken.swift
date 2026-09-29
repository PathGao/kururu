// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import Foundation

final class MediaCancellationToken {
    private enum State { case active, cancelled, committed }
    private let lock = NSLock()
    private var state = State.active

    var isCancelled: Bool {
        lock.lock()
        defer { lock.unlock() }
        return state == .cancelled
    }

    // A final result, including no needed output, must survive late cancellation.
    @discardableResult
    func cancel() -> Bool {
        lock.lock()
        defer { lock.unlock() }
        guard state != .committed else { return false }
        state = .cancelled
        return true
    }

    @discardableResult
    func markCommitted() -> Bool {
        lock.lock()
        defer { lock.unlock() }
        guard state != .cancelled else { return false }
        state = .committed
        return true
    }
}
