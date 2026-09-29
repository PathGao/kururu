// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import Foundation

/// Pure decisions behind the move-progress HUD (issue #168). Progress only
/// appears for moves that actually take time: same-volume moves are renames
/// and finish instantly, so they stay silent.
enum CutPasteProgressSupport {
    /// How often the destination file size is sampled during a cross-volume
    /// move. Sampling is a single stat call, so this can stay snappy.
    static let pollInterval: TimeInterval = 0.3

    /// A move leaves its volume only when both volume identities are known
    /// and differ. Unknown identities fall back to "same volume": the worst
    /// case is a silent move, which was the behavior before progress existed.
    static func isCrossVolume(source: NSObject?, destination: NSObject?) -> Bool {
        guard let source, let destination else { return false }
        return !source.isEqual(destination)
    }

    /// Fraction of the whole batch already on the destination, from the bytes
    /// of finished files plus the growing size of the file being copied.
    /// Returns nil when the total is unknown, which the HUD shows as an
    /// indeterminate bar. Clamped: a destination briefly reporting more bytes
    /// than expected must never push the bar past full.
    static func fraction(finishedBytes: Int64, currentBytes: Int64, totalBytes: Int64) -> Double? {
        guard totalBytes > 0 else { return nil }
        let done = min(max(finishedBytes, 0) + max(currentBytes, 0), totalBytes)
        return Double(done) / Double(totalBytes)
    }

    /// The "2 of 5" counter position for the file currently moving, clamped
    /// so a straggling publish can never show "6 of 5".
    static func displayPosition(completed: Int, total: Int) -> Int {
        min(max(completed, 0) + 1, max(total, 1))
    }
}
