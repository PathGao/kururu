import Foundation

enum BrightnessModuleMigrationTests {
    static func run(_ expect: (Bool, String) -> Void) {
        let name = "com.vorssaint.tests.brightness-migration.\(UUID().uuidString)"
        let store = UserDefaults(suiteName: name)!
        defer { store.removePersistentDomain(forName: name) }
        for available in [false, true] {
            for enabled in [false, true] {
                store.removePersistentDomain(forName: name)
                store.set(available, forKey: FeatureUnit.brightness.availabilityKey)
                store.set(enabled, forKey: DefaultsKey.brightnessControlEnabled)
                Defaults.migrateBrightnessModuleGate(in: store)
                expect(AppFeature.brightness.isAvailable(in: store) == (available && enabled),
                       "brightness migration preserves both legacy gates")
                expect(store.object(forKey: DefaultsKey.brightnessControlEnabled) == nil,
                       "brightness migration consumes retired gate")
                store.set(true, forKey: FeatureUnit.brightness.availabilityKey)
                Defaults.migrateBrightnessModuleGate(in: store)
                expect(AppFeature.brightness.isAvailable(in: store),
                       "later module enable survives repeated registration")
            }
        }
        store.removePersistentDomain(forName: name)
        store.set(true, forKey: FeatureUnit.brightness.availabilityKey)
        Defaults.migrateBrightnessModuleGate(in: store)
        expect(!AppFeature.brightness.isAvailable(in: store),
               "legacy absent gate preserves former off default")
        for version in [1, 2] {
            let settings: [String: Any] = [FeatureUnit.brightness.availabilityKey: true,
                                           DefaultsKey.featureAvailable(AppFeature.brightness.rawValue): false,
                                           DefaultsKey.brightnessControlEnabled: false]
            let payload: [String: Any] = [SettingsBackupSupport.formatVersionKey: version,
                                          SettingsBackupSupport.settingsKey: settings]
            let sanitized = SettingsBackupSupport.sanitizedSettings(from: payload)!
            SettingsBackupSupport.replaceExportedSettings(sanitized, in: store)
            Defaults.migrateBrightnessModuleGate(in: store)
            expect(AppFeature.brightness.isAvailable(in: store) == (version == 2),
                   "backup version distinguishes retired gate from current module intent")
        }
        expect(!SettingsBackupSupport.exportKeys().contains(DefaultsKey.brightnessControlEnabled),
               "new backups exclude retired brightness gate")
        expect(AppFeature.brightness.pageSwitchKey == nil,
               "brightness has a single module gate")
    }
}
