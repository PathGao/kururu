import Foundation

enum OnboardingFeatureSelectionTests {
    static func run(_ expect: (Bool, String) -> Void) {
        runDependencies(expect)
        runRestoration(expect)
        let cases: [(AppFeature, String, [String])] = [
            (.scrollInverter, DefaultsKey.scrollInverterEnabled, [DefaultsKey.scrollInverterHorizontalEnabled]),
            (.mouseButtonShortcuts, DefaultsKey.mouseButtonShortcutsEnabled, [DefaultsKey.mouseSpacesGestureEnabled]),
            (.finderCutPaste, DefaultsKey.finderCutPasteEnabled, [DefaultsKey.finderPasteImageAsFile]),
            (.quitWindowProtection, DefaultsKey.quitProtectionQuitEnabled, [DefaultsKey.quitProtectionCloseEnabled]),
            (.textSnippets, DefaultsKey.snippetLibraryEnabled, [DefaultsKey.textSnippetsEnabled]),
            (.dockClick, DefaultsKey.dockClickMinimize, [DefaultsKey.dockClickHide, DefaultsKey.dockClickCycleWindows])
        ]
        for (feature, primary, optional) in cases {
            let changes = OnboardingFeatureSelection.preferenceChanges(for: [feature], isEnabled: { _ in false })
            expect(changes[feature.unit.availabilityKey] == true, "selection enables the owning unit: \(feature)")
            expect(feature.pageSwitchKey == nil, "multi-action selection has no redundant feature gate: \(feature)")
            expect(changes[primary] == true, "selection enables only its primary action: \(feature)")
            expect(optional.allSatisfy { changes[$0] == nil }, "selection preserves optional actions: \(feature)")
            let configured = OnboardingFeatureSelection.preferenceChanges(for: [feature], isEnabled: { $0 == optional[0] })
            expect(configured[primary] == nil && configured[optional[0]] == nil,
                   "an existing alternate action is not replaced: \(feature)")
        }
        let mouse = OnboardingFeatureSelection.preferenceChanges(for: [.smoothScroll], isEnabled: { _ in true })
        expect(mouse[DefaultsKey.smoothScrollEnabled] == true, "a single-switch selection works immediately")
        expect(mouse[DefaultsKey.mouseAccelerationDisabled] == false,
               "selecting smooth scroll does not enable the sibling acceleration override")
        expect(mouse[DefaultsKey.mouseButtonShortcutsEnabled] == false
               && mouse[DefaultsKey.mouseSpacesGestureEnabled] == false,
               "an unselected sibling's actions stay off without adding a group gate")
        expect(OnboardingFeatureSelection.actionOnInstall(.bluetoothSleep, isEnabled: { _ in false })
               == DefaultsKey.bluetoothSleepEnabled, "installing a one-behavior unit turns that behavior on")
        expect(OnboardingFeatureSelection.actionOnInstall(.bluetoothSleep, isEnabled: { _ in true }) == nil,
               "installing keeps a behavior that is already configured")
        expect(OnboardingFeatureSelection.actionOnInstall(.mouse, isEnabled: { _ in false }) == nil,
               "installing a multi-member unit starts no member")
        expect(OnboardingFeatureSelection.actionOnInstall(.keepAwake, isEnabled: { _ in false }) == nil,
               "installing keep awake never starts a session")
        let monitor = OnboardingFeatureSelection.preferenceChanges(for: [.monitorCPU], isEnabled: { _ in false })
        expect(monitor[FeatureUnit.monitor.availabilityKey] == true, "the monitor has one selection entry")
        expect(monitor[DefaultsKey.fanControlEnabled] == false, "monitor selection never starts fan control")
        expect(!monitor.keys.contains { $0.hasPrefix("menuBar") || $0.hasPrefix("monitorAlert") || $0.hasPrefix("panel") },
               "monitor selection does not change placement or alert preferences")
        let tools = OnboardingFeatureSelection.preferenceChanges(for: [.keepAwake, .screenRecorder], isEnabled: { _ in false })
        expect(tools[FeatureUnit.screenshot.availabilityKey] == true
               && tools[DefaultsKey.recorderShortcutEnabled] == nil,
               "selecting capture tools enables the shared entry without starting shortcuts")
        expect(tools[DefaultsKey.keepAwakeAutoStart] == nil, "selecting keep awake never starts an awake session")
        let off = OnboardingFeatureSelection.preferenceChanges(for: [], isEnabled: { _ in true })
        expect(off[FeatureUnit.mouse.availabilityKey] == false && off[DefaultsKey.mouseSpacesGestureEnabled] == nil,
               "deselecting a unit keeps its preferences for later")
        expect(OnboardingFeatureSelection.options.filter(\.isSwitchedByPlacement) == [.monitorCPU],
               "the six coupled monitor families are represented by one honest choice")
    }
    static func runDependencies(_ expect: (Bool, String) -> Void) {
        expect(OnboardingFeatureSelection.normalized([.fanControl]) == [.monitorCPU, .fanControl],
               "fan control selection exposes its monitoring dependency")
        expect(OnboardingFeatureSelection.toggling(.fanControl, in: []) == [.monitorCPU, .fanControl],
               "selecting fan control also checks monitoring")
        expect(OnboardingFeatureSelection.toggling(.monitorCPU, in: [.monitorCPU, .fanControl, .keepAwake]) == [.keepAwake],
               "unchecking monitoring also unchecks dependent fan control")
        expect(OnboardingFeatureSelection.toggling(.fanControl, in: [.monitorCPU, .fanControl]) == [.monitorCPU],
               "unchecking fan control keeps independently selected monitoring")
    }

    static func runRestoration(_ expect: (Bool, String) -> Void) {
        let suite = "com.vorssaint.onboarding-tests.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suite) else {
            expect(false, "isolated onboarding preferences are available")
            return
        }
        defer { defaults.removePersistentDomain(forName: suite) }
        // Registration defaults are shared across suites in the test process.
        defaults.setPersistentDomain(
            Defaults.registeredDefaults.merging(FeatureUnit.availabilityDefaults) { _, value in value },
            forName: suite)
        for unit in FeatureUnit.allCases { defaults.set(false, forKey: unit.availabilityKey) }
        defaults.set(true, forKey: FeatureUnit.dock.availabilityKey)
        defaults.set(true, forKey: DefaultsKey.dockClickEnabled)
        defaults.set(true, forKey: DefaultsKey.dockClickHide)
        defaults.set(true, forKey: FeatureUnit.monitor.availabilityKey)
        let saved = OnboardingFeatureSelection.currentSelection(in: defaults)
        expect(saved == [.dockClick, .monitorCPU],
               "existing preset preferences restore the engaged features, not every unit member")
        let changes = OnboardingFeatureSelection.preferenceChanges(for: saved, isEnabled: defaults.bool(forKey:))
        for (key, value) in changes { defaults.set(value, forKey: key) }
        expect(OnboardingFeatureSelection.currentSelection(in: defaults) == saved,
               "returning from the permissions restart restores the same choices")
        expect(defaults.bool(forKey: DefaultsKey.dockClickHide)
               && !defaults.bool(forKey: DefaultsKey.dockClickMinimize),
               "revisiting onboarding does not replace the user's Dock action")
        let onlyPreview = OnboardingFeatureSelection.preferenceChanges(for: [.dockPreview], isEnabled: defaults.bool(forKey:))
        for (key, value) in onlyPreview { defaults.set(value, forKey: key) }
        expect(OnboardingFeatureSelection.currentSelection(in: defaults) == [.dockPreview],
               "switching to a sibling changes the selected feature without leaking the old one")
        expect(!defaults.bool(forKey: DefaultsKey.dockClickHide),
               "deselecting a sibling disables its concrete action instead of hiding an enabled action")
    }

}
