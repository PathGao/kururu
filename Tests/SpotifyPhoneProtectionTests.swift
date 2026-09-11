import Foundation

enum SpotifyPhoneProtectionTests {
    static func run(_ expect: (Bool, String) -> Void) {
        for name in ["com.spotify.client", "COM.SPOTIFY.CLIENT", "com.spotify.client.helper"] {
            expect(CleanerPolicy.isExcludedCacheEntry(name),
                   "Spotify cache containing Spicetify state never enters the cleanup list: \(name)")
            expect(!CleanerPolicy.precheckCacheEntry(name),
                   "excluded Spotify cache cannot be recommended: \(name)")
        }
        expect(!CleanerPolicy.isExcludedCacheEntry("com.vendor.editor")
               && !CleanerPolicy.isExcludedCacheEntry("ms-playwright"),
               "ordinary and downloadable sensitive caches remain available for review")
        expect(CleanerPolicy.precheckCacheEntry("com.vendor.editor")
               && !CleanerPolicy.precheckCacheEntry("ms-playwright"),
               "ordinary and sensitive cache defaults retain their distinction")

        let phone = "com.apple.mobilephone"
        let finder = Defaults.finderBundleIdentifier
        expect(Defaults.mandatoryAutoQuitExceptionBundleIDs.contains(phone),
               "incoming Continuity calls keep Phone running")
        expect(Defaults.sanitizedAutoQuitExceptions([finder, "com.example.app"])
               == [finder, phone, "com.example.app"],
               "saved exception lists gain mandatory Phone protection")
        expect(!AutoQuitSupport.shouldDisplayException(bundleID: phone, isInstalled: false)
               && AutoQuitSupport.shouldDisplayException(bundleID: phone, isInstalled: true),
               "Phone's settings row is visible only where installed")
        expect(AutoQuitSupport.visibleExceptions([finder, phone, "com.example.app"],
                                                isInstalled: { _ in false })
               == [finder, "com.example.app"],
               "hiding absent Phone preserves Finder and user exceptions")
        expect(AutoQuitSupport.visibleExceptions([finder, phone], isInstalled: { _ in true })
               == [finder, phone],
               "installed Phone remains visible as a mandatory exception")
    }
}
