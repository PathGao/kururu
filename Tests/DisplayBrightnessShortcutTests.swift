import Foundation

enum DisplayBrightnessShortcutTests {
    static func run(_ expect: (Bool, String) -> Void) {
        expect(Defaults.registeredDefaults[BrightnessShortcutPreferenceKey.enabled] as? Bool == false,
               "display brightness shortcuts start disabled")
        expect(Defaults.registeredDefaults[BrightnessShortcutPreferenceKey.decrease] as? String == "shift+command:27"
                   && Defaults.registeredDefaults[BrightnessShortcutPreferenceKey.increase] as? String
                   == "shift+command:24",
               "display brightness directions ship upstream's Shift-Command-minus and Shift-Command-equals")
        expect(GlobalShortcut.displayBrightnessDecreaseDefault.storageValue == "shift+command:27"
                   && GlobalShortcut.displayBrightnessIncreaseDefault.storageValue == "shift+command:24",
               "the registered combinations are the roles' own defaults, not a second copy")
        let backupKeys = SettingsBackupSupport.exportKeys()
        expect([BrightnessShortcutPreferenceKey.enabled,
                BrightnessShortcutPreferenceKey.decrease,
                BrightnessShortcutPreferenceKey.increase].allSatisfy(backupKeys.contains),
               "display brightness shortcut choice and assigned directions follow settings backups")

        // Three stored states: nothing (a row never touched), an empty value
        // (a row the user cleared) and a combination (a row the user set).
        let role = GlobalShortcutRole.displayBrightnessDecrease
        let assigned = GlobalShortcut(keyCode: 12, modifiers: [.control, .option])
        expect(role.configuredShortcut(read: { _ in nil }) == .displayBrightnessDecreaseDefault,
               "a display direction nobody touched uses its default")
        expect(role.configuredShortcut(read: { _ in "" }) == nil,
               "a cleared display direction stays unassigned instead of returning to the default")
        expect(role.configuredShortcut(read: { _ in assigned.storageValue }) == assigned,
               "a display direction the user set keeps that combination")
        expect(GlobalShortcutRole.keyboardBrightnessDecrease.configuredShortcut(read: { _ in "" })
                   == .keyboardBrightnessDecreaseDefault,
               "an empty value still means the default for roles that cannot be cleared")

        let enabled: (String) -> Bool = { key in
            key == BrightnessShortcutPreferenceKey.enabled
        }
        expect(GlobalShortcutRole.displayBrightnessDecrease.isActive(
            isOn: enabled, shortcutValue: { _ in nil }),
               "an untouched display direction is live once its toggle is on")
        expect(!GlobalShortcutRole.displayBrightnessDecrease.isActive(
            isOn: enabled, shortcutValue: { _ in "" }),
               "a cleared display direction is inactive even when its toggle is on")
        let onlyDecrease: (String) -> String? = { key in
            key == BrightnessShortcutPreferenceKey.decrease ? assigned.storageValue : ""
        }
        let active = GlobalShortcutRole.activeRoles(
            isOn: enabled, shortcutValue: onlyDecrease)
        expect(active.contains(.displayBrightnessDecrease)
                   && !active.contains(.displayBrightnessIncrease),
               "one assigned display direction activates independently")
        expect(GlobalShortcutRole.conflict(
            for: assigned,
            excluding: .displayBrightnessDecrease,
            isOn: enabled,
            includeInactive: true,
            shortcutValue: onlyDecrease) == nil,
               "a cleared other display direction creates no false conflict")

        // The row writes these states; no seam reaches the view, so pin it.
        let recorder = (try? String(contentsOfFile: "Sources/Vorssaint/UI/ShortcutRecorderButton.swift",
                                    encoding: .utf8)) ?? ""
        expect(recorder.contains("wrappedValue: role.defaultShortcut.storageValue,")
                   && recorder.contains("Button(l10n.s.shortcutReset) {\n                            rawValue = role.defaultShortcut.storageValue"),
               "the row shows and resets to the default rather than writing an empty value")
        expect(recorder.contains("clearAction: role.isClearable ? clear : nil,")
                   && recorder.contains("private func clear() {\n        rawValue = \"\""),
               "clearing a display direction stores the empty value that keeps it unassigned")
    }
}
