import Foundation

enum MixerSwitchMigrationTests {
    static func run(_ expect: (Bool, String) -> Void) {
        let name = "com.vorssaint.tests.mixer-switch.\(UUID().uuidString)"
        let store = UserDefaults(suiteName: name)!
        defer { store.removePersistentDomain(forName: name) }
        for legacy in [nil, false, true] as [Bool?] {
            store.removePersistentDomain(forName: name)
            store.set(true, forKey: FeatureUnit.mixer.availabilityKey)
            if let legacy { store.set(legacy, forKey: DefaultsKey.mixerEnabled) }
            Defaults.migrateMixerSwitch(in: store)
            expect(AppFeature.mixer.isAvailable(in: store) == (legacy != false),
                   "mixer switch \(String(describing: legacy)) keeps whether the mixer ran")
            expect(store.object(forKey: DefaultsKey.mixerEnabled) == nil, "mixer migration consumes the retired switch")
        }
        store.set(true, forKey: FeatureUnit.mixer.availabilityKey)
        Defaults.migrateMixerSwitch(in: store)
        expect(AppFeature.mixer.isAvailable(in: store), "a later install survives repeated registration")
        let payload: [String: Any] = [SettingsBackupSupport.formatVersionKey: 2,
                                      SettingsBackupSupport.settingsKey: [FeatureUnit.mixer.availabilityKey: true,
                                                                          DefaultsKey.mixerEnabled: false]]
        SettingsBackupSupport.replaceExportedSettings(SettingsBackupSupport.sanitizedSettings(from: payload)!, in: store)
        Defaults.migrateMixerSwitch(in: store)
        expect(!AppFeature.mixer.isAvailable(in: store), "an old backup with the mixer off restores it uninstalled")
        expect(!SettingsBackupSupport.exportKeys().contains(DefaultsKey.mixerEnabled),
               "new backups exclude the retired mixer switch")
    }
}
