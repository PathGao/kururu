import Foundation

enum DisplayBrightnessShortcutTests {
    static func run(_ expect: (Bool, String) -> Void) {
        expect(Defaults.registeredDefaults[BrightnessShortcutPreferenceKey.enabled] as? Bool == false,
               "display brightness shortcuts start disabled")
        expect(Defaults.registeredDefaults[BrightnessShortcutPreferenceKey.decrease] == nil
                   && Defaults.registeredDefaults[BrightnessShortcutPreferenceKey.increase] == nil,
               "display brightness directions start unassigned")
        let backupKeys = SettingsBackupSupport.exportKeys()
        expect([BrightnessShortcutPreferenceKey.enabled,
                BrightnessShortcutPreferenceKey.decrease,
                BrightnessShortcutPreferenceKey.increase].allSatisfy(backupKeys.contains),
               "display brightness shortcut choice and assigned directions follow settings backups")
        let enabled: (String) -> Bool = { key in
            key == DefaultsKey.brightnessControlEnabled
                || key == BrightnessShortcutPreferenceKey.enabled
        }
        let assigned = GlobalShortcut(keyCode: 12, modifiers: [.control, .option])
        let onlyDecrease: (String) -> String? = { key in
            key == BrightnessShortcutPreferenceKey.decrease ? assigned.storageValue : nil
        }
        expect(!GlobalShortcutRole.displayBrightnessDecrease.isActive(
            isOn: enabled, shortcutValue: { _ in nil }),
               "missing display shortcut is inactive even when its toggle is on")
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
               "missing other display direction creates no false conflict")
    }
}
