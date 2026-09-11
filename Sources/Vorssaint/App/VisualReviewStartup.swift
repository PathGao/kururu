// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

/// Isolated review bundles expose every page without enabling automatic actions.
enum VisualReviewStartup {
    static func prepare() {
        guard VisualReviewConfiguration.current != nil else { return }
        let defaults = UserDefaults.standard
        let marker = "visualReviewInitialized20260911"
        guard !defaults.bool(forKey: marker) else { return }
        FeaturePreset.prepareVisualReviewAvailability(
            in: defaults, supportedUnits: Set(FeatureUnit.allCases.filter(\.isHardwareSupported)))
        var disabled = Set(AppFeature.allCases.flatMap(\.enabledKeys))
        disabled.formUnion(AppFeature.allCases.compactMap(\.switchKey))
        disabled.formUnion(GlobalShortcutRole.allCases.flatMap(\.requiredEnableKeys))
        disabled.formUnion([
            DefaultsKey.keepAwakeAutoStart, DefaultsKey.keepAwakeExternalDisplay,
            DefaultsKey.keepAwakeConnectedToPower, DefaultsKey.keepAwakeRunningApps,
            DefaultsKey.keepAwakeMouseJiggleEnabled, DefaultsKey.micMuteActive,
            DefaultsKey.preciseVolumeRollerEnabled, DefaultsKey.clipboardAutoClearOnDelay,
            DefaultsKey.clipboardAutoClearOnSleep, DefaultsKey.clipboardAutoClearOnDisplaySleep,
            DefaultsKey.clipboardAutoClearOnScreenLock, DefaultsKey.whatsAppDownloadsEnabled,
            DefaultsKey.whatsAppDownloadsAutomaticEnabled, DefaultsKey.whatsAppOrganizerEnabled,
            DefaultsKey.launchAtLoginWanted, DefaultsKey.autoCheckUpdates,
            DefaultsKey.fanControlEnabled, DefaultsKey.brightnessKeysEnabled,
            DefaultsKey.brightnessOSDEnabled
        ])
        for key in disabled { defaults.set(false, forKey: key) }
        defaults.set(true, forKey: DefaultsKey.hasOnboarded)
        defaults.set("zh-Hans", forKey: DefaultsKey.language)
        defaults.set(1100.0, forKey: DefaultsKey.settingsWindowWidth)
        defaults.set(780.0, forKey: DefaultsKey.settingsWindowHeight)
        defaults.set(true, forKey: marker)
    }
}
