// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import AppKit

/// Bridges the pure feature catalog to the live singletons. Every binding is
/// a closure, so merely mentioning a feature never instantiates its service:
/// a service only comes to life when its binding runs, and syncAtLaunch skips
/// unavailable features entirely — switched off in the hub means nothing
/// loads and nothing runs after the next launch. Main thread only, like the
/// services it drives.
final class FeatureRuntime: ObservableObject {
    static let shared = FeatureRuntime()

    /// Bumped on every availability change; views observing the runtime
    /// re-read the catalog when it moves.
    @Published private(set) var revision = 0

    /// Every feature that came to life in THIS process: available at launch
    /// or installed later in the session. A feature uninstalled mid-session
    /// stops working immediately, but its (inert) singleton only leaves
    /// memory on the next launch — this set is what the hub's restart banner
    /// keys off, including the install-then-uninstall-again case.
    private var loadedThisSession = Set(AppFeature.allCases.filter(\.isAvailable))

    private init() {}

    /// True while something that loaded this session is now uninstalled, so
    /// a restart would actually unload it. Features already uninstalled when
    /// the app came up never loaded, so they need no restart.
    var needsRestartToUnload: Bool {
        loadedThisSession.contains { !$0.isAvailable }
    }

    /// Relaunches the app in place: a detached helper waits for this process
    /// to be gone and only then reopens it, so the fresh instance starts
    /// without the uninstalled features.
    ///
    /// It waits for the process rather than for a fixed moment because
    /// quitting flushes the clipboard history and every other pending write
    /// first: a reopen that arrives while the app is still here does nothing,
    /// and the restart ends as a plain quit.
    func relaunchApp() {
        let path = Bundle.main.bundlePath
        // Its own session: the reopen fires after we terminate, so the child
        // has to outlive the session it was started from. It gives up if we
        // are somehow still here after twenty seconds, so a quit that never
        // happens cannot reopen the app long afterwards.
        let script = """
            waited=0
            while kill -0 "$1" 2>/dev/null && [ "$waited" -lt 100 ]; do
                sleep 0.2
                waited=$((waited + 1))
            done
            kill -0 "$1" 2>/dev/null || /usr/bin/open "$2"
            """
        let pid = String(ProcessInfo.processInfo.processIdentifier)
        // Nothing is quit until the helper is running: without it, terminating
        // would close the app instead of restarting it.
        guard (try? DetachedProcess.spawn(
            "/bin/sh", ["-c", script, "vorssaint-relaunch", pid, path])) != nil
        else { return }
        NSApp.terminate(nil)
    }

    func isAvailable(_ feature: AppFeature) -> Bool { feature.isAvailable }

    var availableCount: Int { FeatureUnit.allCases.filter(\.isAvailable).count }

    /// How many units this Mac can end up with. Counting against the whole
    /// catalog instead would leave the hub's install-all button forever one
    /// short of its own disabled condition on a Mac missing some hardware.
    /// An install that predates the check still counts, so the tally can
    /// never read more installed than installable.
    var installableCount: Int {
        FeatureUnit.allCases.filter { $0.isHardwareSupported || $0.isAvailable }.count
    }

    /// Unit installs pass this hardware gate. The first-run feature picker
    /// checks each member through its shared `installBlockedReason` before
    /// applying the same catalog preferences.
    ///
    /// Uninstalls are never refused and an existing install is never revoked:
    /// the check reads hardware and can be wrong, and a wrong answer that
    /// strands someone's settings costs far more than one that leaves a
    /// feature reporting itself unsupported.
    private func mayFlip(_ unit: FeatureUnit, to available: Bool) -> Bool {
        guard unit.isAvailable != available else { return false }
        return !available || unit.isHardwareSupported
    }

    /// Flipping availability runs every member's binding immediately: off
    /// tears every resource down on the spot, on restores whatever switch and
    /// enabled state each member had (their own keys are never touched).
    func setAvailable(_ unit: FeatureUnit, _ available: Bool) {
        guard mayFlip(unit, to: available) else { return }
        install(unit, available)
        finishAvailabilityChange()
    }

    private func install(_ unit: FeatureUnit, _ available: Bool) {
        UserDefaults.standard.set(available, forKey: unit.availabilityKey)
        for feature in unit.features {
            if feature.isAvailable { loadedThisSession.insert(feature) }
            Self.bindings[feature]?()
        }
    }

    /// Flips a member's switch row inside an installed unit: the same gate,
    /// binding run and revision bump as an install, since off is uninstalled
    /// in every respect but the switch staying on the page. A row bound to a
    /// member's one enable key takes the same path; its service syncs either
    /// way.
    func setSwitch(_ feature: AppFeature, _ on: Bool) {
        guard let key = feature.pageSwitchKey, !on || feature.isHardwareSupported else { return }
        UserDefaults.standard.set(on, forKey: key)
        if on { loadedThisSession.insert(feature) }
        Self.bindings[feature]?()
        finishAvailabilityChange()
    }

    /// Apply all preference gates before any binding runs, so enabling one
    /// member cannot briefly start its unselected siblings.
    func applyOnboardingSelection(_ selected: Set<AppFeature>) {
        let accepted = Set(selected.filter { $0.installBlockedReason == nil })
        let previouslyAvailable = Set(AppFeature.allCases.filter(\.isAvailable))
        let defaults = UserDefaults.standard
        let changes = OnboardingFeatureSelection.preferenceChanges(for: accepted,
                                                                     isEnabled: defaults.bool(forKey:))
        for (key, value) in changes { defaults.set(value, forKey: key) }
        let available = Set(AppFeature.allCases.filter(\.isAvailable))
        loadedThisSession.formUnion(available)
        for feature in previouslyAvailable.union(available) {
            Self.bindings[feature]?()
        }
        finishAvailabilityChange()
    }

    /// Applies a preserved preset definition: its units become the installed set, with the
    /// enable keys it names switched on so they work right away, and
    /// everything else uninstalls. Nothing is deleted, so any unit returns
    /// with one click, settings intact.
    func apply(_ preset: FeaturePreset) {
        replaceAvailable(with: preset.units, enabling: preset.enableKeys)
    }

    /// Replaces the installed set after the first-run picker. It uses the same
    /// availability layer as the hub, so unselected units disappear without
    /// losing any of their settings.
    func replaceAvailable(with selected: Set<FeatureUnit>, enabling keys: [String] = []) {
        for key in keys {
            UserDefaults.standard.set(true, forKey: key)
        }
        for unit in FeatureUnit.allCases where mayFlip(unit, to: selected.contains(unit)) {
            install(unit, selected.contains(unit))
        }
        // Units that stayed installed still need a sync: their enable keys
        // may have just flipped on. Syncs are idempotent, so a repeat for the
        // ones handled above costs nothing. A selected unit the gate refused
        // is not installed, so it is skipped like any other unavailable one
        // and its services never come to life.
        for unit in selected where unit.isAvailable {
            for feature in unit.features {
                Self.bindings[feature]?()
            }
        }
        finishAvailabilityChange()
    }

    /// Bulk install or uninstall for the hub's "all" buttons: one revision
    /// bump, every changed unit's bindings run.
    func setAllAvailable(_ available: Bool) {
        var changed = false
        for unit in FeatureUnit.allCases where mayFlip(unit, to: available) {
            install(unit, available)
            changed = true
        }
        if changed { finishAvailabilityChange() }
    }

    /// Launch path: replaces the old unconditional sync block. Only available
    /// features get their binding run, so nothing else even instantiates.
    func syncAtLaunch() {
        for feature in AppFeature.allCases where feature.isAvailable {
            Self.bindings[feature]?()
        }
    }

    /// Re-syncs a set of features (used by the permission sinks); skips
    /// unavailable ones so their singletons never come to life.
    func sync(_ features: [AppFeature]) {
        for feature in features where feature.isAvailable {
            Self.bindings[feature]?()
        }
    }

    /// One bump for Settings, and the Command Bar drops rows of features that
    /// just left the hub so a pin cannot linger as a bare id.
    private func finishAvailabilityChange() {
        revision += 1
        CommandBarService.shared.noteHubChange()
    }

    /// What each feature must re-evaluate when its availability (or a
    /// permission it depends on) changes. Most on-demand tools have no binding;
    /// Media only binds so uninstalling it can cancel work already in flight.
    private static let bindings: [AppFeature: () -> Void] = [
        .switcher: {
            WindowUseTracker.shared.syncWithFeatures()
            AppSwitcher.shared.syncWithPreferences()
        },
        .dockPreview: { DockPreviewService.shared.syncWithPreferences() },
        .dockClick: { DockClickService.shared.syncWithPreferences() },
        .windowMaximizer: { WindowMaximizer.shared.syncWithPreferences() },
        .autoQuit: { AutoQuitService.shared.syncWithPreferences() },
        .scrollInverter: { ScrollInverter.shared.syncWithPreferences() },
        .focusFollowsMouse: { FocusFollowsMouseService.shared.syncWithPreferences() },
        .smoothScroll: { SmoothScrollService.shared.syncWithPreferences() },
        .mouseAcceleration: { MouseAccelerationService.shared.syncWithPreferences() },
        .mouseNavigation: { MouseNavigationService.shared.syncWithPreferences() },
        .mouseButtonShortcuts: { MouseButtonShortcutService.shared.syncWithPreferences() },
        .middleClick: { MiddleClickService.shared.syncWithPreferences() },
        .mouseClickDebounce: { MouseClickDebounceService.shared.syncWithPreferences() },
        .keyboardDebounce: { KeyboardDebounceService.shared.syncWithPreferences() },
        .quitWindowProtection: { QuitProtectionService.shared.syncWithPreferences() },
        .superKey: { SuperKeyService.shared.syncWithPreferences() },
        .textSnippets: {
            TextSnippetService.shared.syncWithPreferences()
            SnippetLibraryService.shared.syncWithPreferences()
        },
        .clipboardHistory: {
            ClipboardHistoryService.shared.syncWithPreferences()
            // Auto clear rides the clipboard feature's availability but not its
            // capture toggle: uninstalling the feature stops it, turning history
            // off does not.
            ClipboardAutoClearService.shared.syncWithPreferences()
        },
        .mediaTools: {
            guard !AppFeature.mediaTools.isAvailable else { return }
            MediaService.shared.cancel()
            ScreenRecorderService.shared.closeEditors(ownedBy: .mediaTools)
        },
        .pastePlain: { PastePlainService.shared.syncWithPreferences() },
        .finderCutPaste: { FinderCutPaste.shared.syncWithPreferences() },
        .finderRename: { FinderRenameService.shared.syncWithPreferences() },
        .shelf: { ShelfService.shared.syncWithPreferences() },
        .urlCleaner: { URLCleanerService.shared.syncWithPreferences() },
        .mixer: {
            PreciseVolumeRollerService.shared.syncWithPreferences()
            AppVolumeMixer.shared.syncWithPreferences()
            AudioInputDeviceManager.shared.syncWithPreferences()
        },
        .soundOutputSwitcher: { SoundOutputSwitcher.shared.syncWithPreferences() },
        .micMute: { MicMuteService.shared.syncWithPreferences() },
        .musicBlock: { MusicLaunchBlocker.shared.syncWithPreferences() },
        .keepAwake: {
            KeepAwakeManager.shared.syncWithFeatures()
            HotkeyManager.shared.syncWithPreferences()
        },
        .brightness: { BrightnessService.shared.syncWithPreferences() },
        .bluetoothSleep: { BluetoothSleepService.shared.syncWithPreferences() },
        .colorPicker: {
            ScreenCaptureService.shared.syncWithPreferences()
        },
        .screenOCR: {
            ScreenCaptureService.shared.syncWithPreferences()
            ScreenTextService.shared.syncWithPreferences()
        },
        .screenshot: {
            ScreenCaptureService.shared.syncWithPreferences()
            ScreenshotService.shared.syncWithPreferences()
            RecentCaptureService.shared.syncWithPreferences()
        },
        .screenRecorder: {
            ScreenCaptureService.shared.syncWithPreferences()
            ScreenRecorderService.shared.syncWithPreferences()
            RecentCaptureService.shared.syncWithPreferences()
        },
        .radialMenu: { RadialMenuService.shared.syncWithPreferences() },
        .scratchpad: {
            ScratchpadService.shared.syncWithPreferences()
            ShelfService.shared.syncDockedShelf()
        },
        .commandBar: { CommandBarService.shared.syncWithPreferences() },
        .cleaner: {
            CleanerScheduler.shared.syncWithPreferences()
            WhatsAppDownloadScheduler.shared.syncWithPreferences()
            WhatsAppDownloadOrganizer.shared.syncWithPreferences()
            if !AppFeature.cleaner.isAvailable || !WhatsAppDownloadSupport.isEnabled {
                WhatsAppDownloadManager.shared.reset()
                WhatsAppDownloadOrganizer.shared.stop()
            }
        },
        .monitorCPU: { FeatureRuntime.syncMonitor() },
        .monitorGPU: { FeatureRuntime.syncMonitor() },
        .monitorMemory: { FeatureRuntime.syncMonitor() },
        .monitorNetwork: { FeatureRuntime.syncMonitor() },
        .monitorDisk: { FeatureRuntime.syncMonitor() },
        .monitorPower: { FeatureRuntime.syncMonitor() },
        .fanControl: {
            SystemMonitor.shared.planDidChange()
            let defaults = UserDefaults.standard
            let needsRecovery = defaults.bool(forKey: DefaultsKey.fanControlRecoveryNeeded)
            let hasRegisteredHelper = !(defaults.string(forKey: DefaultsKey.fanControlHelperVersion) ?? "").isEmpty
            if needsRecovery || (!AppFeature.fanControl.isAvailable && hasRegisteredHelper) {
                FanControlService.shared.syncWithPreferences()
            }
        },
    ]

    private static func syncMonitor() {
        SystemMonitor.shared.planDidChange()
        MonitorAlertService.shared.syncWithPreferences()
    }
}

/// Hardware a feature needs and this Mac may not have. One switch answers
/// both questions, so a feature can never be unsupported without a reason to
/// show for it, and a feature added here can never grey a row silently.
/// It lives beside the runtime rather than in the catalog because the answer
/// comes from a service, and the catalog stays a pure description.
extension AppFeature {
    /// Why this Mac cannot run the feature, ready to show. `nil` when it can,
    /// or when the feature depends on no hardware at all.
    var hardwareUnsupportedReason: String? {
        switch self {
        case .fanControl:
            return FanControlHardware.hasControllableFan
                ? nil : FeatureStrings.fanControl(L10n.shared.language).noFans
        default:
            return nil
        }
    }

    var isHardwareSupported: Bool { hardwareUnsupportedReason == nil }

    /// Why a page must refuse to switch this feature on, ready to show as a
    /// tooltip. `nil` once it is on: the check reads hardware and can be
    /// wrong, so it is never allowed to strand an existing install behind a
    /// greyed row. The member switch reads this, so it cannot drift from the
    /// gate in `FeatureRuntime.setSwitch`.
    var installBlockedReason: String? {
        isAvailable ? nil : hardwareUnsupportedReason
    }
}

extension FeatureUnit {
    /// A unit this Mac cannot run at all: every member needs hardware it
    /// lacks. One such member inside a larger unit installs with the unit
    /// and has its own switch refused instead.
    var hardwareUnsupportedReason: String? {
        features.contains(where: \.isHardwareSupported) ? nil : features[0].hardwareUnsupportedReason
    }

    var isHardwareSupported: Bool { hardwareUnsupportedReason == nil }

    /// The hub tile's and the first-run card's version of
    /// `AppFeature.installBlockedReason`, so neither picker drifts from
    /// `FeatureRuntime.mayFlip`.
    var installBlockedReason: String? {
        isAvailable ? nil : hardwareUnsupportedReason
    }
}
