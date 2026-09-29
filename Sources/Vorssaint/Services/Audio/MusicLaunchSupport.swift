// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import Foundation

/// A recent media key is evidence for blocking a selected app's launch, not
/// proof of its origin. Manual launches within the same window also match.
enum MusicLaunchSupport {
    enum ReplacementChoice: Equatable {
        case selected(String)
        case blocked
    }

    static func replacementChoice(path: String, bundleID: String?, blockedBundleIDs: [String]) -> ReplacementChoice {
        if let bundleID, blockedBundleIDs.contains(bundleID) { return .blocked }
        return .selected(path)
    }

    static let defaultBlockedBundleIDs = ["com.apple.Music"]
    static let systemDefinedEventTypeRawValue: UInt32 = 14
    static let auxiliaryControlButtonsSubtype = 8
    static let keyDownState = 10
    /// Launch Services needs a moment after the key to start the app.
    static let launchArmWindow: TimeInterval = 2.0

    static let playPauseKeyCode: UInt16 = 16
    static let nextTrackKeyCode: UInt16 = 17
    static let previousTrackKeyCode: UInt16 = 18
    static let fastForwardKeyCode: UInt16 = 19
    static let rewindKeyCode: UInt16 = 20

    static let musicLaunchKeyCodes: Set<UInt16> = [
        playPauseKeyCode, nextTrackKeyCode, previousTrackKeyCode,
        fastForwardKeyCode, rewindKeyCode
    ]

    /// True for the key-down of a media key that would otherwise open the
    /// music app. Releases, auto-repeat and volume or brightness keys do not
    /// count, so those never arm the blocker.
    static func isMusicLaunchTrigger(subtype: Int, data1: Int) -> Bool {
        guard subtype == auxiliaryControlButtonsSubtype else { return false }
        let raw = UInt32(truncatingIfNeeded: data1)
        let state = Int((raw >> 8) & 0xFF)
        guard state == keyDownState, (raw & 0x1) == 0 else { return false }
        let keyCode = UInt16((raw >> 16) & 0xFFFF)
        return musicLaunchKeyCodes.contains(keyCode)
    }

    static func shouldBlockLaunch(bundleID: String, blockedBundleIDs: [String],
                                  now: TimeInterval, lastTriggerAt: TimeInterval?) -> Bool {
        blockedBundleIDs.contains(bundleID)
            && shouldBlockLaunch(now: now, lastTriggerAt: lastTriggerAt)
    }

    static func shouldBlockLaunch(now: TimeInterval, lastTriggerAt: TimeInterval?) -> Bool {
        guard let lastTriggerAt else { return false }
        return (0...launchArmWindow).contains(now - lastTriggerAt)
    }
}
