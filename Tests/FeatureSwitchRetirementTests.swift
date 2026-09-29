import Foundation

enum FeatureSwitchRetirementTests {
    static func run(_ expect: (Bool, String) -> Void) {
        let registration = UserDefaults.standard.volatileDomain(forName: UserDefaults.registrationDomain)
        defer { UserDefaults.standard.setVolatileDomain(registration, forName: UserDefaults.registrationDomain) }
        let suite = "com.vorssaint.tests.switch-retirement.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suite) else {
            expect(false, "isolated retirement preferences are available")
            return
        }
        defer { defaults.removePersistentDomain(forName: suite) }
        defaults.set(true, forKey: FeatureUnit.screenshot.availabilityKey)
        for key in [DefaultsKey.screenshotEnabled, DefaultsKey.recorderEnabled,
                    DefaultsKey.screenOCREnabled, DefaultsKey.colorPickerEnabled] {
            defaults.set(false, forKey: key)
        }
        let tools = ScreenCaptureTool.available(isAvailable: { $0.isAvailable(in: defaults) })
        expect(tools == ScreenCaptureTool.allCases,
               "an installed capture group offers all four on-demand tools without member gates")
        for tool in ScreenCaptureTool.allCases {
            expect(tool.feature.pageSwitchKey == nil, "capture tool has no persistent enable switch: \(tool)")
            expect(tool.feature.onboardingPermissions.isEmpty,
                   "selecting a capture entry does not pre-request permissions: \(tool)")
            defaults.set(false, forKey: tool.dedicatedShortcut.enabledKey)
        }
        expect(!ScreenshotSupport.captureAvailabilityChanged(
            activeTools: tools,
            availableTools: ScreenCaptureTool.available(isAvailable: { $0.isAvailable(in: defaults) })),
               "turning shortcuts off keeps active capture availability unchanged")
        defaults.set(false, forKey: FeatureUnit.screenshot.availabilityKey)
        let stopped = ScreenCaptureTool.available(isAvailable: { $0.isAvailable(in: defaults) })
        expect(stopped.isEmpty && ScreenshotSupport.captureAvailabilityChanged(activeTools: tools, availableTools: stopped),
               "uninstalling the capture group still invalidates active capture tools")
        expect(OnboardingFeatureSelection.options.filter { $0.unit == .screenshot } == [.screenshot],
               "onboarding represents the capture group with one entry")
        runMigration(expect, defaults: defaults, suite: suite)
    }

    private static func runMigration(_ expect: (Bool, String) -> Void,
                                     defaults: UserDefaults, suite: String) {
        let groups: [(AppFeature, String)] = [
            (.scrollInverter, DefaultsKey.scrollInverterSwitchEnabled),
            (.mouseButtonShortcuts, DefaultsKey.mouseButtonShortcutsSwitchEnabled),
            (.finderCutPaste, DefaultsKey.finderCutPasteSwitchEnabled),
            (.quitWindowProtection, DefaultsKey.quitProtectionSwitchEnabled),
            (.textSnippets, DefaultsKey.textSnippetsSwitchEnabled),
            (.dockClick, DefaultsKey.dockClickEnabled)
        ]
        let captures: [(AppFeature, String, [String])] = [
            (.screenshot, DefaultsKey.screenshotEnabled,
             [DefaultsKey.screenshotShortcutEnabled, DefaultsKey.screenshotFullScreenShortcutEnabled,
              DefaultsKey.screenshotLastCaptureShortcutEnabled, DefaultsKey.screenshotClipboardShortcutEnabled]),
            (.screenRecorder, DefaultsKey.recorderEnabled, [DefaultsKey.recorderShortcutEnabled]),
            (.screenOCR, DefaultsKey.screenOCREnabled, [DefaultsKey.screenOCRShortcutEnabled]),
            (.colorPicker, DefaultsKey.colorPickerEnabled, [DefaultsKey.colorPickerShortcutEnabled])
        ]
        let entries = groups.map { ($0.0, $0.1, $0.0.enabledKeys) } + captures
        for (feature, gate, actions) in entries {
            for oldGate in [false, true] {
                defaults.setPersistentDomain([
                    feature.unit.availabilityKey: true,
                    gate: oldGate,
                    DefaultsKey.unifiedScreenCaptureShortcutMigrated: true,
                    DefaultsKey.restoredScreenCaptureShortcutsMigrated: true,
                    DefaultsKey.orphanedCaptureShortcutMigrated: true
                ], forName: suite)
                for key in actions { defaults.set(true, forKey: key) }
                Defaults.register(in: defaults)
                expect(actions.allSatisfy { defaults.bool(forKey: $0) == oldGate },
                       "retired \(feature) gate \(oldGate) preserves effective actions")
                expect(defaults.object(forKey: gate) == nil,
                       "retired gate is consumed: \(gate)")
                for key in actions { defaults.set(true, forKey: key) }
                Defaults.register(in: defaults)
                expect(actions.allSatisfy { defaults.bool(forKey: $0) },
                       "subsequent registration preserves explicit new actions: \(feature)")
            }
            defaults.setPersistentDomain([
                DefaultsKey.featureAvailable(feature.rawValue): false,
                feature.unit.availabilityKey: true
            ], forName: suite)
            for key in actions { defaults.set(true, forKey: key) }
            Defaults.register(in: defaults)
            expect(actions.allSatisfy { !defaults.bool(forKey: $0) },
                   "pre-unit unavailable feature remains inactive: \(feature)")
            let imported = SettingsBackupSupport.sanitizedSettings(from: [
                SettingsBackupSupport.formatVersionKey: SettingsBackupSupport.formatVersion,
                SettingsBackupSupport.settingsKey: [gate: false]
            ]) ?? [:]
            expect(imported[gate] as? Bool == false, "legacy backup accepts retired gate: \(gate)")
            for key in actions { defaults.set(true, forKey: key) }
            for (key, value) in imported { defaults.set(value, forKey: key) }
            Defaults.register(in: defaults)
            expect(actions.allSatisfy { !defaults.bool(forKey: $0) },
                   "reimported old off gate is honored after an earlier migration: \(feature)")
        }
        for (feature, _) in groups {
            expect(feature.pageSwitchKey == nil, "multi-action group has no additional persistent switch: \(feature)")
            let changes = OnboardingFeatureSelection.preferenceChanges(for: [], isEnabled: { _ in true })
            expect(changes[feature.unit.availabilityKey] == false, "unselected unit remains unavailable")
            if let sibling = feature.unit.features.first(where: { $0 != feature }) {
                let changes = OnboardingFeatureSelection.preferenceChanges(for: [sibling], isEnabled: { _ in true })
                expect(feature.enabledKeys.allSatisfy { changes[$0] == false },
                       "selecting a sibling turns off every concrete action of \(feature)")
            }
        }
        defaults.setPersistentDomain([
            FeatureUnit.screenshot.availabilityKey: true,
            DefaultsKey.screenshotEnabled: false,
            DefaultsKey.recorderEnabled: true,
            DefaultsKey.screenOCREnabled: false,
            DefaultsKey.colorPickerEnabled: false,
            DefaultsKey.screenshotShortcutEnabled: true,
            DefaultsKey.screenshotShortcut: "control+option:42",
            DefaultsKey.recentCapturesShortcutEnabled: true
        ], forName: suite)
        Defaults.register(in: defaults)
        expect(defaults.bool(forKey: DefaultsKey.recorderShortcutEnabled)
               && defaults.string(forKey: DefaultsKey.recorderShortcut) == "control+option:42"
               && !defaults.bool(forKey: DefaultsKey.screenshotShortcutEnabled),
               "an old orphaned general shortcut transfers to a previously available tool before gates retire")
        expect(defaults.bool(forKey: DefaultsKey.recentCapturesShortcutEnabled),
               "capture history shortcut stays enabled while a previous owner was available")

        defaults.setPersistentDomain([
            FeatureUnit.screenshot.availabilityKey: true,
            DefaultsKey.screenshotEnabled: false,
            DefaultsKey.recorderEnabled: false,
            DefaultsKey.screenOCREnabled: true,
            DefaultsKey.colorPickerEnabled: true,
            DefaultsKey.recorderShortcutEnabled: true,
            DefaultsKey.recorderShortcut: "control+option:42",
            DefaultsKey.recentCapturesShortcutEnabled: true
        ], forName: suite)
        Defaults.register(in: defaults)
        expect(!defaults.bool(forKey: DefaultsKey.recorderShortcutEnabled)
               && !defaults.bool(forKey: DefaultsKey.screenshotShortcutEnabled),
               "restoring dedicated shortcuts never reactivates a formerly disabled recorder")
        expect(!defaults.bool(forKey: DefaultsKey.recentCapturesShortcutEnabled),
               "capture history shortcut stays off when both former owners were disabled")
        expect(defaults.string(forKey: DefaultsKey.recorderShortcut) == "control+option:42",
               "retiring availability preserves the configured combination")

        expect(Defaults.retiredFeatureSwitchKeys.values.allSatisfy {
            !SettingsBackupSupport.exportKeys().contains($0)
        }, "new backups omit retired switches")
        let captureChoice = OnboardingFeatureSelection.normalized([.colorPicker])
        expect(captureChoice == [.screenshot]
               && captureChoice.flatMap(\.onboardingPermissions).isEmpty,
               "legacy color-only onboarding maps to one capture entry without expanding requested permissions")
    }
}
