// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

enum RadialTrackpadIntegrationTests {
    static func run(_ expect: (Bool, String) -> Void) {
        func active(profiles: Data?, enabled: Bool = true, available: Bool = true,
                    legacyButton: String = "off", legacyItems: Data? = nil) -> Bool {
            AppFeature.activeFeatures(using: .accessibility,
                isAvailable: { $0 == .radialMenu && available },
                boolFor: { $0 == DefaultsKey.radialMenuEnabled && enabled },
                stringFor: { $0 == DefaultsKey.radialMenuMouseButton ? legacyButton : nil },
                dataFor: { key in
                    if key == DefaultsKey.radialMenuProfiles { return profiles }
                    if key == DefaultsKey.radialMenuItems { return legacyItems }
                    return nil
                }).contains(.radialMenu)
        }
        let three = RadialMenuProfile(name: "Three", trackpadTapFingers: 3)
        let four = RadialMenuProfile(name: "Four", trackpadTapFingers: 4)
        let gestureData = RadialMenuSupport.encodeProfiles([three, four])
        let plainData = RadialMenuSupport.encodeProfiles([RadialMenuProfile(name: "Plain")])
        expect(active(profiles: gestureData), "Trackpad-only profiles count as active Accessibility use")
        expect(!active(profiles: gestureData, enabled: false), "Paused radial menu does not count as active Accessibility use")
        expect(!active(profiles: gestureData, available: false), "Unavailable radial menu does not count as active Accessibility use")
        expect(!active(profiles: plainData, legacyButton: "back"), "Valid profiles override a stale legacy mouse binding")
        expect(active(profiles: gestureData, legacyButton: "off"), "Profile gestures override legacy off")
        expect(!active(profiles: plainData), "Profiles without input controls do not count as Accessibility use")
        let mixed = Data("[{\"name\":\"Valid\",\"trackpadTapFingers\":4,\"items\":[]},17,{\"name\":9}]".utf8)
        expect(active(profiles: mixed), "A malformed neighboring profile does not hide valid gesture permission use")
        expect(active(profiles: nil, legacyButton: "back"), "Absent profile data falls back to legacy mouse permission use")
        expect(active(profiles: Data("not JSON".utf8), legacyButton: "back"), "Unreadable profile data falls back to legacy configuration")
        expect(active(profiles: nil), "Absent configuration retains the starter menu's Accessibility requirement")
        expect(!active(profiles: nil, legacyItems: RadialMenuSupport.encode([])),
               "An explicitly empty legacy menu without mouse binding does not require Accessibility")
        let legacyShortcutItems = RadialMenuSupport.encode([
            RadialMenuItem(kind: .shortcut, name: "Legacy shortcut", payload: GlobalShortcut.radialMenuDefault.storageValue)
        ])
        expect(active(profiles: nil, legacyItems: legacyShortcutItems),
               "Legacy shortcut items still require Accessibility without profile data")
        expect(!active(profiles: plainData, legacyItems: legacyShortcutItems),
               "Valid profiles override stale legacy shortcut items as well as mouse bindings")

        func backupRoundTrip(_ data: Data) -> [String: Any]? {
            let payload = SettingsBackupSupport.payload(appVersion: "trackpad-integration") { key in
                if key == DefaultsKey.radialMenuProfiles { return data }
                if key == DefaultsKey.radialMenuEnabled { return false }
                return nil
            }
            guard let serialized = try? PropertyListSerialization.data(fromPropertyList: payload,
                    format: .binary, options: 0),
                  let decoded = try? PropertyListSerialization.propertyList(from: serialized,
                    options: [], format: nil) as? [String: Any] else { return nil }
            return SettingsBackupSupport.sanitizedSettings(from: decoded)
        }
        let restored = gestureData.flatMap(backupRoundTrip)
        let restoredProfiles = RadialMenuSupport.decodedStoredProfiles(restored?[DefaultsKey.radialMenuProfiles] as? Data)
        expect(restoredProfiles?.map(\.trackpadTapFingers) == [3, 4],
               "Export envelope, binary plist and import sanitization preserve both gesture bindings")
        expect(restoredProfiles?.map(\.id) == [three.id, four.id],
               "Backup round trip preserves the profile identities that gesture routing targets")
        expect(restored?[DefaultsKey.radialMenuEnabled] as? Bool == false,
               "A paused backup keeps its assignments without enabling the feature")
        let oldData = Data("[{\"name\":\"Old backup\",\"items\":[]}]".utf8)
        let oldRestored = backupRoundTrip(oldData)
        let oldProfiles = RadialMenuSupport.decodedStoredProfiles(oldRestored?[DefaultsKey.radialMenuProfiles] as? Data)
        expect(oldProfiles?.first?.name == "Old backup" && oldProfiles?.first?.trackpadTapFingers == 0,
               "A real backup round trip leaves missing legacy gesture fields off")
    }
}
