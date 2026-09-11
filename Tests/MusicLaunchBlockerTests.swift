import Foundation

enum MusicLaunchBlockerTests {
    static func run(_ expect: (Bool, String) -> Void) {
        expect(MusicLaunchSupport.shouldBlockLaunch(bundleID: "com.apple.Music",
                                                    blockedBundleIDs: MusicLaunchSupport.defaultBlockedBundleIDs,
                                                    now: 10, lastTriggerAt: 9),
               "the default list blocks Music after a media key")
        expect(!MusicLaunchSupport.shouldBlockLaunch(bundleID: "com.apple.iTunes",
                                                     blockedBundleIDs: MusicLaunchSupport.defaultBlockedBundleIDs,
                                                     now: 10, lastTriggerAt: 9),
               "the default list does not silently include a legacy app")
        let selected = ["com.example.Player"]
        expect(MusicLaunchSupport.shouldBlockLaunch(bundleID: "com.example.Player", blockedBundleIDs: selected,
                                                    now: 10, lastTriggerAt: 9),
               "a selected app is blocked after a media key")
        expect(!MusicLaunchSupport.shouldBlockLaunch(bundleID: "com.apple.Music", blockedBundleIDs: selected,
                                                     now: 10, lastTriggerAt: 9),
               "removing Music from the list allows its launch")
        expect(!MusicLaunchSupport.shouldBlockLaunch(bundleID: "com.example.Player.Helper", blockedBundleIDs: selected,
                                                     now: 10, lastTriggerAt: 9),
               "selection matches exact identifiers, not prefixes")
        expect(!MusicLaunchSupport.shouldBlockLaunch(bundleID: "com.example.Player", blockedBundleIDs: [],
                                                     now: 10, lastTriggerAt: 9),
               "an empty list blocks nothing")
        expect(!MusicLaunchSupport.shouldBlockLaunch(bundleID: "com.example.Player", blockedBundleIDs: selected,
                                                     now: 10, lastTriggerAt: nil),
               "a selected app launched without a media key is allowed")
        expect(!MusicLaunchSupport.shouldBlockLaunch(bundleID: "com.example.Player", blockedBundleIDs: selected,
                                                     now: 10, lastTriggerAt: 7.9),
               "a selected app launched after the trigger expires is allowed")
        expect(MusicLaunchSupport.shouldBlockLaunch(bundleID: "com.example.Player", blockedBundleIDs: selected,
                                                    now: 10, lastTriggerAt: 8),
               "the existing two-second boundary remains inclusive")
        expect(!MusicLaunchSupport.shouldBlockLaunch(now: 10, lastTriggerAt: 11),
               "a future trigger cannot authorize termination")
    }
}
