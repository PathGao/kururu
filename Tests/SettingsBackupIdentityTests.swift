// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint
import Foundation

enum SettingsBackupIdentityTests {
    static func run(_ expect: (Bool, String) -> Void) {
        let retiredAppearance = ["liquidGlassEnabled", "importedInterfaceTheme"]
        let oldAppearance: [String: Any] = [
            "liquidGlassEnabled": true,
            "importedInterfaceTheme": Data("obsolete theme".utf8),
            DefaultsKey.appearance: "dark"
        ]
        let appearancePayload = SettingsBackupSupport.payload(appVersion: "test") { oldAppearance[$0] }
        let appearanceExport = appearancePayload[SettingsBackupSupport.settingsKey] as? [String: Any]
        let appearanceImport = SettingsBackupSupport.sanitizedSettings(from: [
            SettingsBackupSupport.formatVersionKey: 1,
            SettingsBackupSupport.settingsKey: oldAppearance
        ])
        for key in retiredAppearance {
            expect(Defaults.registeredDefaults[key] == nil, "retired appearance preference is not registered: \(key)")
            expect(appearanceExport?[key] == nil, "retired appearance preference is not exported: \(key)")
            expect(appearanceImport?[key] == nil, "retired appearance preference is ignored during import: \(key)")
        }
        expect(appearanceImport?[DefaultsKey.appearance] as? String == "dark",
               "old theme bytes do not prevent importing the supported light/dark choice")
        let machine: [String: Any] = [
            DefaultsKey.launchAtLoginWanted: true,
            DefaultsKey.bluetoothSleepRestorePending: true,
            DefaultsKey.micMuteActive: true,
            DefaultsKey.micMuteSavedVolume: 0.6,
            DefaultsKey.micMuteSavedVolumes: ["old-device": 0.6],
            DefaultsKey.micMuteMutedDevices: ["old-device"],
            DefaultsKey.fanControlRecoveryNeeded: true,
            DefaultsKey.fanControlHelperVersion: "old-helper",
            DefaultsKey.switcherNativeHotkeysSuppressed: true,
            DefaultsKey.systemShortcutsSuppressed: ["old-shortcut"],
            DefaultsKey.screenshotSharingDeveloperEndpoint: "https://example.com",
            DefaultsKey.screenshotSharingEnabled: true
        ]
        for key in [DefaultsKey.screenshotSharingEnabled, DefaultsKey.screenshotSharingDeveloperEndpoint] {
            expect(Defaults.registeredDefaults[key] == nil, "retired screenshot preference has no registered default: \(key)")
        }
        let portable = DefaultsKey.scrollInverterEnabled
        let source = machine.merging([portable: true]) { _, rhs in rhs }
        let payload = SettingsBackupSupport.payload(appVersion: "test") { source[$0] }
        let exported = payload[SettingsBackupSupport.settingsKey] as? [String: Any] ?? [:]
        for key in machine.keys.sorted() {
            expect(exported[key] == nil, "identity-specific state is not exported: \(key)")
        }
        expect(exported[portable] as? Bool == true, "ordinary portable configuration is exported")
        let legacy: [String: Any] = [SettingsBackupSupport.formatVersionKey: 1,
                                    SettingsBackupSupport.settingsKey: source]
        let sourceURL = FileManager.default.temporaryDirectory.appendingPathComponent("vorssaint-tests-backup-identity-\(UUID()).plist")
        defer { try? FileManager.default.removeItem(at: sourceURL) }
        let sourceData: Data
        let decoded: [String: Any]
        do {
            sourceData = try PropertyListSerialization.data(fromPropertyList: legacy, format: .xml, options: 0)
            try sourceData.write(to: sourceURL, options: .withoutOverwriting)
            guard let payload = try PropertyListSerialization.propertyList(from: Data(contentsOf: sourceURL), format: nil) as? [String: Any] else {
                expect(false, "serialized backup decodes as dictionary"); return
            }
            decoded = payload
        } catch { expect(false, "backup file fixture: \(error)"); return }
        guard let accepted = SettingsBackupSupport.sanitizedSettings(from: decoded) else {
            expect(false, "valid legacy backup is accepted"); return
        }
        for key in machine.keys.sorted() {
            expect(accepted[key] == nil, "legacy payload cannot import identity state: \(key)")
        }
        expect(accepted[portable] as? Bool == true, "portable legacy setting remains accepted")
        let suite = "vorssaint-tests-backup-identity-\(UUID())"
        guard let defaults = UserDefaults(suiteName: suite) else { expect(false, "unique preference suite available"); return }
        defer { defaults.removePersistentDomain(forName: suite) }
        // No registration domain: this fixture cannot pollute other tests.
        defaults.setPersistentDomain([DefaultsKey.launchAtLoginWanted: false,
                                      DefaultsKey.fanControlRecoveryNeeded: true,
                                      portable: false], forName: suite)
        defaults.set(true, forKey: DefaultsKey.screenshotSharingEnabled)
        defaults.set("https://example.com", forKey: DefaultsKey.screenshotSharingDeveloperEndpoint)
        defaults.set(false, forKey: DefaultsKey.screenshotCopyToClipboard)
        Defaults.migrateDroppedFeatures(in: defaults)
        expect(defaults.object(forKey: DefaultsKey.screenshotSharingEnabled) == nil, "migration removes old screenshot upload choice")
        expect(defaults.object(forKey: DefaultsKey.screenshotSharingDeveloperEndpoint) == nil, "migration removes old upload endpoint")
        expect(defaults.object(forKey: DefaultsKey.screenshotCopyToClipboard) as? Bool == false, "migration preserves local screenshot output choice")
        SettingsBackupSupport.replaceExportedSettings(accepted, in: defaults)
        expect(!defaults.bool(forKey: DefaultsKey.launchAtLoginWanted), "import cannot opt the new identity into launch at login")
        expect(defaults.bool(forKey: DefaultsKey.fanControlRecoveryNeeded), "replacement preserves current identity's own recovery obligation")
        expect(defaults.bool(forKey: portable), "replacement applies ordinary portable preference")
        expect(defaults.object(forKey: DefaultsKey.micMuteSavedVolumes) == nil, "old device restoration ledger never enters new identity")
        expect((try? Data(contentsOf: sourceURL)) == sourceData, "import leaves serialized legacy backup byte-for-byte unchanged")
        let decodedSettings = decoded[SettingsBackupSupport.settingsKey] as? [String: Any]
        expect(decodedSettings?[DefaultsKey.launchAtLoginWanted] as? Bool == true,
               "filtering preserves the source payload's original login choice")
    }
}
