// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint
import Foundation

enum ShelfDockBackupTests {
    static func run(_ expect: (Bool, String) -> Void) {
        let key = DefaultsKey.shelfDockPlacement
        func envelope(_ settings: [String: Any]) -> [String: Any] {
            [SettingsBackupSupport.formatVersionKey: 1, SettingsBackupSupport.settingsKey: settings]
        }
        for raw in ["menuBar", "topCenter"] {
            expect(SettingsBackupSupport.valueLooksRight(key, raw), "shelf backup accepts placement \(raw)")
            let cleaned = SettingsBackupSupport.sanitizedSettings(from: envelope([key: raw]))
            expect(cleaned?[key] as? String == raw, "shelf import retains placement \(raw)")
            let payload = SettingsBackupSupport.payload(appVersion: "fixture") { $0 == key ? raw : nil }
            expect((payload[SettingsBackupSupport.settingsKey] as? [String: Any])?[key] as? String == raw,
                   "shelf export includes placement \(raw)")
        }
        let invalidValues: [Any] = ["unknown", "", 1, true, ["topCenter"]]
        for invalid in invalidValues {
            let cleaned = SettingsBackupSupport.sanitizedSettings(from: envelope([key: invalid]))
            expect(!SettingsBackupSupport.valueLooksRight(key, invalid) && cleaned != nil && cleaned?[key] == nil,
                   "shelf import filters invalid placement \(invalid)")
        }
        expect(Defaults.registeredDefaults[key] as? String == "menuBar", "registered shelf position preserves legacy default")

        let suite = "com.vorssaint.tests.shelf-dock-backup.\(UUID())"
        guard let defaults = UserDefaults(suiteName: suite) else { expect(false, "shelf suite available"); return }
        defer { defaults.removePersistentDomain(forName: suite) }
        // Never register defaults: registration domains can be shared across suites.
        defaults.setPersistentDomain([key: "topCenter"], forName: suite)
        guard let old = SettingsBackupSupport.sanitizedSettings(from: envelope([:])) else {
            expect(false, "old backup accepted"); return
        }
        expect(old[key] == nil, "old backup remains missing the new position key")
        SettingsBackupSupport.replaceExportedSettings(old, in: defaults)
        expect(defaults.persistentDomain(forName: suite)?[key] == nil, "old replacement clears a previous top position")
        expect(ShelfDockPlacement.normalized(defaults.string(forKey: key)) == .menuBar,
               "old replacement resolves to menu bar without registering defaults")

        defaults.set("topCenter", forKey: key)
        let payload = SettingsBackupSupport.payload(appVersion: "fixture") { defaults.object(forKey: $0) }
        do {
            let data = try PropertyListSerialization.data(fromPropertyList: payload, format: .xml, options: 0)
            guard let decoded = try PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any],
                  let settings = SettingsBackupSupport.sanitizedSettings(from: decoded) else {
                expect(false, "serialized shelf backup accepted"); return
            }
            expect(settings[key] as? String == "topCenter", "XML roundtrip preserves top placement")
            defaults.set("menuBar", forKey: key)
            SettingsBackupSupport.replaceExportedSettings(settings, in: defaults)
            expect(defaults.persistentDomain(forName: suite)?[key] as? String == "topCenter",
                   "real replacement writes top placement into isolated store")
            expect(ShelfDockPlacement.normalized(defaults.string(forKey: key)) == .topCenter,
                   "restored placement selects the top presentation")
            expect((decoded[SettingsBackupSupport.settingsKey] as? [String: Any])?[key] as? String == "topCenter",
                   "applying backup does not mutate decoded source")
        } catch { expect(false, "shelf XML roundtrip failed: \(error)") }
    }
}
