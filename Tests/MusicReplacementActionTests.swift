// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

enum MusicReplacementActionTests {
    static func run(_ expect: (Bool, String) -> Void) {
        let choice = MusicLaunchSupport.replacementChoice(path: "/Applications/Music.app",
            bundleID: "com.apple.Music", blockedBundleIDs: ["com.apple.Music"])
        expect(choice == .blocked, "a blocked replacement returns an explicit rejection instead of selecting a launch loop")
        expect(MusicLaunchSupport.replacementChoice(path: "/Applications/Player.app",
            bundleID: "example.player", blockedBundleIDs: ["com.apple.Music"]) == .selected("/Applications/Player.app"),
            "a different replacement retains the actual selected path")
        expect(MusicLaunchSupport.replacementChoice(path: "/Applications/Music.app",
            bundleID: "com.apple.Music", blockedBundleIDs: []) == .selected("/Applications/Music.app"),
            "removing an app from the blocklist permits selecting it")
    }
}
