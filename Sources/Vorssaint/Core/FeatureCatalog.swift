// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import Foundation

/// Every feature the Features hub can switch off entirely. The raw value is
/// the stable identity persisted inside the availability key, so cases can be
/// added but never renamed.
///
/// Availability is a layer ABOVE each feature's own enable key: an unavailable
/// feature disappears from Settings, the menu panel and the menu bar, and its
/// service tears down (and never instantiates on the next launch). Turning a
/// feature back on restores whatever enabled state it had, because the enable
/// keys are never touched.
enum AppFeature: String, CaseIterable {
    // Windows and desktop
    case switcher, dockPreview, dockClick, windowMaximizer, windowLayout, autoQuit
    // Input and control; quitWindowProtection is windows and desktop
    case scrollInverter, scrollHorizontal, focusFollowsMouse, smoothScroll, mouseAcceleration, mouseNavigation, mouseButtonShortcuts, middleClick,
         mouseClickDebounce, keyboardDebounce, textSnippets, superKey, quitWindowProtection
    // Clipboard and files
    case clipboardHistory, pastePlain, finderCutPaste, finderRename, shelf, urlCleaner
    // Sound and devices
    case mixer, soundOutputSwitcher, micMute, musicBlock
    // Focus and energy
    case keepAwake, brightness, bluetoothSleep
    // Mixed; `group` is the authority. Case order is pinned by a test, so
    // new cases append here rather than move.
    case colorPicker, screenOCR, cleaningMode, mediaTools,
         cleaner, uninstaller, homebrew, screenshot, radialMenu, scratchpad,
         commandBar, screenRecorder, environment, killProcess, cameraPreview, portManager
    // System monitor, one entry per metric family (temperatures live with
    // their parent metric: CPU temp with CPU, battery temp with power).
    case monitorCPU, monitorGPU, monitorMemory, monitorNetwork, monitorDisk, monitorPower, fanControl
}

/// What the hub installs: one tile, one availability key, one Settings page
/// (or none). A unit with several features owns the page they share; each
/// member then keeps only its switch on that page. Cases sit in the order
/// their first member has in `AppFeature`, so the hub keeps its rows where
/// they were. The raw value is persisted inside the availability key, so
/// cases can be added but never renamed.
enum FeatureUnit: String, CaseIterable {
    case switcher, dock, windowLayout, windowBehavior
    case mouse, trackpad, keyboard
    case clipboard, cutPaste, shelf
    case mixer, micMute, musicBlock, keepAwake, brightness, bluetoothSleep, cleaningMode
    case screenshot, media, cleaner, uninstaller, homebrew, environment,
         radialMenu, scratchpad, commandBar, killProcess, cameraPreview, portManager
    case monitor
}

/// Hub sections, in display order. The monitor comes first because it sits
/// above every feature in the Settings sidebar too.
enum FeatureGroup: String, CaseIterable {
    case globalEntry, monitor, focusEnergy, windowsDesktop, inputDevices, clipboardFiles, capture,
         soundDevices, appManagement
}

extension FeatureGroup {
    /// The one place a group's name is read, so the hub, the sidebar, the
    /// shortcut editor and the command bar never disagree.
    func title(_ hub: FeatureHubStrings) -> String {
        switch self {
        case .monitor: return hub.groupMonitor
        case .windowsDesktop: return hub.groupWindowsDesktop
        case .inputDevices: return hub.groupInputDevices
        case .globalEntry: return hub.groupGlobalEntry
        case .clipboardFiles: return hub.groupClipboardFiles
        case .capture: return hub.groupCapture
        case .soundDevices: return hub.groupSoundDevices
        case .focusEnergy: return hub.groupFocusEnergy
        case .appManagement: return hub.groupAppManagement
        }
    }

    var units: [FeatureUnit] {
        FeatureUnit.allCases.filter { $0.group == self }
    }
}

extension AppFeature {
    var unit: FeatureUnit {
        switch self {
        case .switcher: return .switcher
        case .dockPreview, .dockClick: return .dock
        case .windowLayout: return .windowLayout
        case .windowMaximizer, .autoQuit, .quitWindowProtection: return .windowBehavior
        case .scrollInverter, .scrollHorizontal, .focusFollowsMouse, .smoothScroll, .mouseAcceleration,
             .mouseNavigation, .mouseButtonShortcuts, .mouseClickDebounce:
            return .mouse
        case .middleClick: return .trackpad
        case .keyboardDebounce, .textSnippets, .superKey: return .keyboard
        case .commandBar: return .commandBar
        case .radialMenu: return .radialMenu
        case .clipboardHistory, .pastePlain, .urlCleaner: return .clipboard
        case .finderCutPaste, .finderRename: return .cutPaste
        case .shelf: return .shelf
        case .scratchpad: return .scratchpad
        case .screenshot, .screenRecorder, .colorPicker, .screenOCR: return .screenshot
        case .mediaTools: return .media
        case .mixer, .soundOutputSwitcher: return .mixer
        case .micMute: return .micMute
        case .musicBlock: return .musicBlock
        case .keepAwake: return .keepAwake
        case .brightness: return .brightness
        case .bluetoothSleep: return .bluetoothSleep
        case .cleaningMode: return .cleaningMode
        case .cleaner: return .cleaner
        case .homebrew: return .homebrew
        case .environment: return .environment
        case .uninstaller: return .uninstaller
        case .killProcess: return .killProcess
        case .cameraPreview: return .cameraPreview
        case .portManager: return .portManager
        case .monitorCPU, .monitorGPU, .monitorMemory, .monitorNetwork, .monitorDisk, .monitorPower,
             .fanControl:
            return .monitor
        }
    }

    /// These metrics use placement controls instead of member switch rows.
    /// Collection follows the monitor unit's availability so hidden metrics
    /// still retain history; placement only controls where they appear.
    var isSwitchedByPlacement: Bool {
        switch self {
        case .monitorCPU, .monitorGPU, .monitorMemory, .monitorNetwork, .monitorDisk, .monitorPower:
            return true
        default:
            return false
        }
    }

    /// Resource-owning members that can be stopped independently of their
    /// unit. On-demand tools and groups of action toggles need no extra gate.
    var switchKey: String? {
        switch self {
        // The six read-only metrics have no switch: see `isSwitchedByPlacement`.
        // Fan control keeps one, because it writes to the SMC through a
        // privileged helper rather than just reading a number.
        case .fanControl: return DefaultsKey.fanControlEnabled
        default: return nil
        }
    }

    /// A single behavior toggle, when the member has one. Groups with several
    /// actions expose those actions directly instead of adding another gate.
    var pageSwitchKey: String? {
        switchKey ?? (enabledKeys.count == 1 ? enabledKeys[0] : nil)
    }

    /// Installed: the unit is, and the member's switch (if it has one) is on.
    func isAvailable(in defaults: UserDefaults) -> Bool {
        defaults.bool(forKey: unit.availabilityKey)
            && (switchKey.map { defaults.bool(forKey: $0) } ?? true)
    }

    /// Engaged as far as its own keys say: one of them on, or none to have.
    func isEngaged(in defaults: UserDefaults) -> Bool {
        enabledKeys.isEmpty || enabledKeys.contains { defaults.bool(forKey: $0) }
    }
}

extension FeatureUnit {
    var features: [AppFeature] { AppFeature.allCases.filter { $0.unit == self } }

    var group: FeatureGroup {
        let group = features[0].group
        assert(features.allSatisfy { $0.group == group }, "\(self) spans two groups")
        return group
    }

    var availabilityKey: String { DefaultsKey.unitAvailable(rawValue) }

    var isAvailable: Bool { UserDefaults.standard.bool(forKey: availabilityKey) }

    /// Registered defaults preserve existing units on update. A unit ships
    /// uninstalled only when every member was an opt-in on its own; an
    /// opt-in member inside a shipped unit keeps its switch off instead.
    /// Kill Process and Port Manager ship uninstalled, as upstream ships
    /// them; a stored choice is never rewritten.
    static var availabilityDefaults: [String: Any] {
        Dictionary(uniqueKeysWithValues: allCases.map {
            ($0.availabilityKey, $0 != .brightness && $0 != .killProcess && $0 != .portManager)
        })
    }

    /// What most members cost; a tie goes to the heavier cost, so the tile
    /// never understates a page.
    var energyProfile: FeatureEnergyProfile {
        var counts: [FeatureEnergyProfile: Int] = [:]
        for feature in features { counts[feature.energyProfile, default: 0] += 1 }
        return counts.max { a, b in a.value != b.value ? a.value < b.value : a.key < b.key }!.key
    }

    /// The tile's name is the sidebar row's name when the unit owns a page,
    /// otherwise the feature's own name.
    func title(_ s: Strings, language: AppLanguage) -> String {
        page?.title(s, language: language) ?? features[0].name(s, language: language)
    }

    var page: SettingsPage? {
        switch self {
        case .switcher: return .switcher
        case .dock: return .dock
        case .windowLayout: return .windowLayout

        case .windowBehavior: return .windowBehavior
        case .mouse: return .mouse
        case .trackpad: return .trackpad
        case .keyboard: return .keyboard
        case .commandBar: return .commandBar
        case .radialMenu: return .radialMenu
        case .clipboard: return .clipboard
        case .cutPaste: return .cutPaste
        case .shelf: return .shelf
        case .scratchpad: return .scratchpad
        case .screenshot: return .screenshot
        case .media: return .media
        case .mixer: return .mixer
        case .micMute: return .micMute
        case .musicBlock: return .musicBlock
        case .keepAwake: return .keepAwake
        case .brightness: return .brightness
        case .bluetoothSleep: return .bluetoothSleep
        case .cleaningMode: return .cleaningMode
        case .cleaner: return .cleaner
        case .homebrew: return .homebrew
        case .environment: return .environment
        case .uninstaller: return .uninstaller
        case .killProcess: return .killProcess
        case .cameraPreview: return .cameraPreview
        case .portManager: return .portManager
        case .monitor: return .monitor
        }
    }

    /// Where the tile's chevron goes: the unit's own page, or for a lone
    /// feature its nearest section (Maximize Window has no page but lives in
    /// the panel layout). `nil` keeps the chevron off the tile.
    var settingsDestination: FeatureSettingsDestination? {
        if features.count > 1 { return page.map { FeatureSettingsDestination($0) } }
        return features[0].hasNavigableSettingsDestination ? features[0].settingsDestination : nil
    }

    var symbolName: String {
        switch self {
        case .mouse: return "computermouse"
        case .trackpad: return "rectangle.and.hand.point.up.left"
        case .screenshot: return AppFeature.screenshot.symbolName
        default: return features[0].symbolName
        }
    }

    /// Beta only when every member is: one beta metric does not badge the
    /// whole monitor.
    var isBeta: Bool { features.allSatisfy(\.isBeta) }

    /// Every permission any member can use, in portal order.
    var permissions: [AppPermission] {
        let all = Set(features.flatMap(\.permissions))
        return AppPermission.allCases.filter(all.contains)
    }
}

/// System permissions surfaced by the hub's transparency portal.
enum AppPermission: String, CaseIterable {
    case accessibility, screenRecording, fullDiskAccess, filesAndFolders, notifications,
         automationFinder, automationTerminal, audioCapture, microphone, camera, appManagement
}

enum PermissionPollingSupport {
    static func interval(visibleSurfaceCount: Int,
                         accessibilityIsNeeded: Bool,
                         screenRecordingIsNeeded: Bool,
                         accessibilityIsGranted: Bool,
                         screenRecordingIsGranted: Bool) -> TimeInterval? {
        guard visibleSurfaceCount > 0 || accessibilityIsNeeded || screenRecordingIsNeeded else {
            return nil
        }
        if visibleSurfaceCount > 0
            || (accessibilityIsNeeded && !accessibilityIsGranted)
            || (screenRecordingIsNeeded && !screenRecordingIsGranted) {
            return 2.5
        }
        return 60
    }
}

extension AppFeature {
    /// Whether an engaged feature needs permission changes while it sits in
    /// the background. One-shot tools ask and refresh at the moment they run;
    /// polling for those just because their tile is installed wastes wakeups.
    var monitorsPermissionChanges: Bool {
        switch self {
        case .screenOCR, .cleaningMode, .screenshot, .commandBar, .screenRecorder:
            return false
        default:
            return true
        }
    }

    var group: FeatureGroup {
        switch self {
        case .monitorCPU, .monitorGPU, .monitorMemory, .monitorNetwork, .monitorDisk, .monitorPower,
             .fanControl:
            return .monitor
        case .switcher, .dockPreview, .dockClick, .windowMaximizer, .windowLayout, .autoQuit,
             .quitWindowProtection:
            return .windowsDesktop
        case .scrollInverter, .scrollHorizontal, .focusFollowsMouse, .smoothScroll, .mouseAcceleration,
             .mouseNavigation, .mouseButtonShortcuts, .middleClick, .mouseClickDebounce,
             .keyboardDebounce, .textSnippets, .superKey:
            return .inputDevices
        // Both open on top of anything and hold whatever is installed, so
        // they sit above the features they reach rather than inside them.
        case .commandBar, .radialMenu: return .globalEntry
        case .clipboardHistory, .pastePlain, .finderCutPaste, .finderRename, .shelf, .urlCleaner,
             .scratchpad:
            return .clipboardFiles
        case .screenshot, .screenRecorder, .colorPicker, .screenOCR, .mediaTools, .cameraPreview:
            return .capture
        case .mixer, .soundOutputSwitcher, .micMute, .musicBlock:
            return .soundDevices
        case .keepAwake, .brightness, .bluetoothSleep, .cleaningMode:
            return .focusEnergy
        case .cleaner, .uninstaller, .homebrew, .environment, .killProcess, .portManager:
            return .appManagement
        }
    }

    var symbolName: String {
        switch self {
        case .switcher: return "rectangle.on.rectangle"
        case .dockPreview: return "dock.rectangle"
        case .dockClick: return "dock.arrow.down.rectangle"
        case .windowMaximizer: return "arrow.up.left.and.arrow.down.right"
        case .windowLayout: return "rectangle.3.group"
        case .autoQuit: return "xmark.rectangle"
        case .scrollInverter: return "arrow.up.arrow.down"
        case .scrollHorizontal: return "arrow.triangle.swap"
        case .focusFollowsMouse: return "cursorarrow.and.square.on.square.dashed"
        case .smoothScroll: return "cursorarrow.motionlines"
        case .mouseAcceleration: return "cursorarrow.rays"
        case .mouseNavigation: return "arrow.left.arrow.right"
        case .mouseButtonShortcuts: return "button.programmable"
        case .middleClick: return "computermouse"
        case .keyboardDebounce: return "keyboard"
        case .textSnippets: return "text.append"
        case .superKey:
            return SuperKeySource.sanitized(
                UserDefaults.standard.string(forKey: DefaultsKey.superKeySource)
            ).systemImage
        case .mouseClickDebounce: return "cursorarrow.click"
        case .quitWindowProtection: return "shield.lefthalf.filled"
        case .clipboardHistory: return "doc.on.clipboard"
        case .pastePlain: return "doc.plaintext"
        case .finderCutPaste: return "scissors"
        case .finderRename: return "pencil"
        case .shelf: return "tray.full"
        case .urlCleaner: return "link"
        case .mixer: return "slider.horizontal.3"
        case .soundOutputSwitcher: return "hifispeaker"
        case .micMute: return "mic.slash"
        case .musicBlock: return "music.note"
        case .keepAwake: return "moon.zzz.fill"
        case .brightness: return "display.2"
        case .bluetoothSleep: return "wave.3.right.circle"
        case .colorPicker: return "eyedropper"
        case .screenOCR: return "text.viewfinder"
        case .cleaningMode: return "bubbles.and.sparkles"
        case .mediaTools: return "photo.on.rectangle.angled"
        case .cleaner: return "sparkles"
        case .uninstaller: return "trash"
        case .homebrew: return "shippingbox"
        case .environment: return "terminal"
        case .screenshot: return "camera.viewfinder"
        case .screenRecorder: return "record.circle"
        case .radialMenu: return "circle.grid.cross"
        case .scratchpad: return "note.text"
        case .commandBar: return "command"
        case .killProcess: return "xmark.octagon"
        case .cameraPreview: return "web.camera"
        case .portManager: return "network"
        case .monitorCPU: return "cpu"
        case .monitorGPU: return "rectangle.connected.to.line.below"
        case .monitorMemory: return "memorychip"
        case .monitorNetwork: return "network"
        case .monitorDisk: return "internaldrive"
        case .monitorPower: return "bolt.fill"
        case .fanControl: return "fanblades.fill"
        }
    }

    // Ending other people's processes is powerful and still settling, so it
    // carries the same badge upstream gives it.
    var isBeta: Bool { self == .fanControl || self == .killProcess }

    var isAvailable: Bool { isAvailable(in: .standard) }

    /// The feature's own enable keys; any one being true means the feature is
    /// engaged. Empty means the feature works on demand (a panel tile, a
    /// context-menu action), so being available already counts as engaged for
    /// the permissions portal.
    var enabledKeys: [String] {
        switch self {
        case .switcher: return [DefaultsKey.switcherEnabled]
        case .dockPreview: return [DefaultsKey.dockPreviewEnabled]
        case .dockClick: return [DefaultsKey.dockClickMinimize,
                                 DefaultsKey.dockClickHide,
                                 DefaultsKey.dockClickCycleWindows]
        case .windowMaximizer: return [DefaultsKey.windowMaximizeEnabled]
        case .windowLayout: return [DefaultsKey.windowLayoutShortcutsEnabled,
                                    DefaultsKey.windowGestureEnabled,
                                    DefaultsKey.windowEdgeSnapEnabled]
        case .autoQuit: return [DefaultsKey.autoQuitEnabled]
        case .scrollInverter: return [DefaultsKey.scrollInverterEnabled,
                                      DefaultsKey.scrollInverterHorizontalEnabled]
        case .scrollHorizontal: return [DefaultsKey.scrollHorizontalEnabled]
        case .focusFollowsMouse: return [DefaultsKey.focusFollowsMouseEnabled]
        case .smoothScroll: return [DefaultsKey.smoothScrollEnabled]
        case .mouseAcceleration: return [DefaultsKey.mouseAccelerationDisabled]
        case .mouseNavigation: return [DefaultsKey.mouseNavigationEnabled]
        case .mouseButtonShortcuts: return [DefaultsKey.mouseButtonShortcutsEnabled,
                                            DefaultsKey.mouseSpacesGestureEnabled]
        case .middleClick: return [DefaultsKey.middleClickEnabled]
        case .keyboardDebounce: return [DefaultsKey.keyboardDebounceEnabled]
        case .quitWindowProtection:
            return [DefaultsKey.quitProtectionQuitEnabled, DefaultsKey.quitProtectionCloseEnabled]
        case .textSnippets: return [DefaultsKey.textSnippetsEnabled, DefaultsKey.snippetLibraryEnabled]
        case .superKey: return [DefaultsKey.superKeyEnabled]
        case .mouseClickDebounce: return [DefaultsKey.mouseClickDebounceEnabled]
        case .radialMenu: return [DefaultsKey.radialMenuEnabled]
        case .clipboardHistory: return [DefaultsKey.clipboardHistoryEnabled]
        case .pastePlain: return [DefaultsKey.pastePlainEnabled]
        case .finderCutPaste: return [DefaultsKey.finderCutPasteEnabled,
                                      DefaultsKey.finderPasteImageAsFile]
        case .finderRename: return [DefaultsKey.finderRenameEnabled]
        case .shelf: return [DefaultsKey.shelfEnabled]
        case .urlCleaner: return [DefaultsKey.urlCleanerEnabled]
        case .soundOutputSwitcher: return [DefaultsKey.soundOutputSwitcherEnabled]
        case .musicBlock: return [DefaultsKey.musicBlockEnabled]
        case .brightness: return []
        case .bluetoothSleep: return [DefaultsKey.bluetoothSleepEnabled]
        case .mixer, .micMute, .keepAwake,
 .colorPicker, .screenOCR, .cleaningMode, .mediaTools,
             .cleaner, .uninstaller, .homebrew, .environment, .screenshot, .scratchpad,
             .commandBar, .screenRecorder, .killProcess, .cameraPreview, .portManager,
             .monitorCPU, .monitorGPU, .monitorMemory, .monitorNetwork, .monitorDisk, .monitorPower,
             .fanControl:
            return []
        }
    }

    /// Which permissions the feature can use at all. Whether it is using them
    /// RIGHT NOW is answered by `activeFeatures(using:)`, which also applies
    /// the dynamic rules (simple-mode switcher needs no screen recording, the
    /// monitor only notifies when an alert is on, and so on).
    var permissions: [AppPermission] {
        switch self {
        case .mouseAcceleration:
            return []
        case .scrollInverter, .scrollHorizontal, .focusFollowsMouse, .smoothScroll, .mouseNavigation,
             .mouseButtonShortcuts, .middleClick,
             .keyboardDebounce, .textSnippets, .superKey, .mouseClickDebounce,
             .dockClick, .windowMaximizer, .windowLayout,
             .autoQuit, .quitWindowProtection, .cleaningMode, .pastePlain, .radialMenu:
            return [.accessibility]
        // The bar reads other apps' menus and windows and types at the caret,
        // all of it through Accessibility, and empties the Trash through the
        // Finder.
        case .commandBar: return [.accessibility, .automationFinder]
        case .finderCutPaste: return [.accessibility, .automationFinder]
        case .finderRename: return [.accessibility]
        case .switcher: return [.accessibility, .screenRecording]
        case .dockPreview: return [.accessibility, .screenRecording]
        case .screenOCR: return [.screenRecording]
        case .screenshot: return [.screenRecording]
        // The mirror only ever draws the image; nothing is written anywhere.
        case .cameraPreview: return [.camera]
        // The sound of the Mac is read through an audio grant of its own.
        // Microphone access stays contextual, and Accessibility only keeps
        // typing timing.
        case .screenRecorder: return [.screenRecording, .accessibility, .audioCapture, .microphone]
        case .keepAwake: return [.accessibility]
        case .brightness: return [.accessibility]
        case .cleaner: return [.fullDiskAccess, .filesAndFolders, .notifications]
        case .uninstaller: return [.fullDiskAccess, .automationFinder]
        case .homebrew: return [.automationTerminal, .appManagement]
        // Reading PATH, a few version strings and two cache folders needs nothing.
        case .environment: return []
        case .mixer: return [.audioCapture, .accessibility]
        case .monitorCPU, .monitorMemory, .monitorDisk, .monitorPower: return [.notifications]
        case .clipboardHistory, .shelf, .urlCleaner,
             .soundOutputSwitcher, .musicBlock,
             .bluetoothSleep, .colorPicker, .micMute, .mediaTools,
             .scratchpad, .monitorGPU, .monitorNetwork, .fanControl, .killProcess, .portManager:
            return []
        }
    }

    /// Broad grants worth explaining during first run. Permissions used only
    /// by an optional sub-feature stay contextual, at the moment that control
    /// is actually used.
    var onboardingPermissions: [AppPermission] {
        switch self {
        case .keepAwake, .brightness, .radialMenu, .cleaner,
             .uninstaller, .homebrew, .environment, .mixer,
             .micMute, .cleaningMode, .screenshot, .screenRecorder, .screenOCR, .colorPicker,
             .cameraPreview:
            return []
        default:
            return permissions.filter { $0 == .accessibility || $0 == .screenRecording }
        }
    }

    static func features(in group: FeatureGroup) -> [AppFeature] {
        allCases.filter { $0.group == group }
    }

    /// Features that are available, engaged and using `permission` right now.
    /// Readers are injectable so the logic stays testable without touching
    /// real UserDefaults.
    static func activeFeatures(using permission: AppPermission,
                               isAvailable: (AppFeature) -> Bool,
                               boolFor: (String) -> Bool,
                               stringFor: (String) -> String?,
                               dataFor: (String) -> Data? = { _ in nil }) -> [AppFeature] {
        allCases.filter { feature in
            guard feature.permissions.contains(permission), isAvailable(feature) else { return false }
            let keys = feature.enabledKeys
            guard keys.isEmpty || keys.contains(where: boolFor) else { return false }
            switch (feature, permission) {
            case (.switcher, .screenRecording):
                return !boolFor(DefaultsKey.switcherSimpleMode)
            case (.radialMenu, .accessibility):
                if let profiles = RadialMenuSupport.decodedStoredProfiles(dataFor(DefaultsKey.radialMenuProfiles)) {
                    return RadialMenuSupport.needsAccessibility(profiles)
                }
                return RadialMenuSupport.needsAccessibility(
                    RadialMenuSupport.decode(dataFor(DefaultsKey.radialMenuItems)))
                    || RadialMenuMouseTrigger.sanitized(
                        stringFor(DefaultsKey.radialMenuMouseButton)) != .off
            case (.keepAwake, .accessibility):
                return boolFor(DefaultsKey.keepAwakeMouseJiggleEnabled)
            case (.mixer, .accessibility):
                return boolFor(DefaultsKey.preciseVolumeRollerEnabled)
            case (.brightness, .accessibility):
                return boolFor(DefaultsKey.brightnessKeysEnabled)
                    || boolFor(DefaultsKey.brightnessOSDEnabled)
            case (.monitorCPU, .notifications):
                return boolFor(DefaultsKey.monitorAlertCPU) || boolFor(DefaultsKey.monitorAlertCPUTemperature)
            case (.monitorMemory, .notifications):
                return boolFor(DefaultsKey.monitorAlertMemory)
            case (.monitorDisk, .notifications):
                return boolFor(DefaultsKey.monitorAlertDisk)
            case (.monitorPower, .notifications):
                return boolFor(DefaultsKey.monitorAlertBattery)
                    || boolFor(DefaultsKey.monitorAlertBatteryTemperature)
            case (.cleaner, .filesAndFolders):
                return boolFor(DefaultsKey.whatsAppDownloadsEnabled)
            case (.cleaner, .notifications):
                let cleanerNotifies = (stringFor(DefaultsKey.cleanerScheduleFrequency) ?? "off") != "off"
                    && boolFor(DefaultsKey.cleanerScheduleNotify)
                let whatsAppNotifies = boolFor(DefaultsKey.whatsAppDownloadsEnabled)
                    && (boolFor(DefaultsKey.whatsAppDownloadsAutomaticEnabled)
                        || boolFor(DefaultsKey.whatsAppOrganizerEnabled))
                    && boolFor(DefaultsKey.whatsAppDownloadsNotify)
                return cleanerNotifies || whatsAppNotifies
            case (.screenRecorder, .audioCapture):
                return boolFor(DefaultsKey.recorderSystemAudio)
            case (.screenRecorder, .microphone):
                return boolFor(DefaultsKey.recorderMicrophone)
            default:
                return true
            }
        }
    }

    /// Monitor alert keys and the metric feature each one belongs to. An
    /// alert only counts while its metric is available in the hub.
    static let monitorAlertPairs: [(key: String, feature: AppFeature)] = [
        (DefaultsKey.monitorAlertCPU, .monitorCPU),
        (DefaultsKey.monitorAlertCPUTemperature, .monitorCPU),
        (DefaultsKey.monitorAlertBatteryTemperature, .monitorPower),
        (DefaultsKey.monitorAlertMemory, .monitorMemory),
        (DefaultsKey.monitorAlertDisk, .monitorDisk),
        (DefaultsKey.monitorAlertBattery, .monitorPower),
    ]

    static func anyMonitorAlertEnabled(isAvailable: (AppFeature) -> Bool,
                                       boolFor: (String) -> Bool) -> Bool {
        monitorAlertPairs.contains { boolFor($0.key) && isAvailable($0.feature) }
    }

    /// Runtime convenience over the injectable core.
    static func activeFeatures(using permission: AppPermission,
                               defaults: UserDefaults = .standard) -> [AppFeature] {
        activeFeatures(using: permission,
                       isAvailable: { $0.isAvailable(in: defaults) },
                       boolFor: { defaults.bool(forKey: $0) },
                       stringFor: { defaults.string(forKey: $0) },
                       dataFor: { defaults.data(forKey: $0) })
    }
}

extension AppPermission {
    var symbolName: String {
        switch self {
        case .accessibility: return "accessibility"
        case .screenRecording: return "rectangle.dashed.badge.record"
        case .fullDiskAccess: return "externaldrive.badge.person.crop"
        case .filesAndFolders: return "folder.badge.person.crop"
        case .notifications: return "bell.badge"
        case .automationFinder, .automationTerminal: return "gearshape.2"
        case .audioCapture: return "waveform"
        case .microphone: return "mic"
        case .camera: return "camera"
        case .appManagement: return "app.badge"
        }
    }
}

extension AppFeature {
    /// Titles reuse the strings users already see across the app; only names
    /// with no clean existing form live in the hub strings.
    func name(_ s: Strings, language: AppLanguage) -> String {
        switch self {
        case .switcher: return s.switcherSection
        case .dockPreview: return FeatureStrings.dockPreview(language).pageTitle
        case .dockClick: return FeatureStrings.dockClick(language).pageTitle
        case .windowMaximizer: return s.windowMaximizeName
        case .windowLayout: return FeatureStrings.windowLayout(language).title
        case .autoQuit: return s.autoQuitName
        case .quitWindowProtection: return FeatureStrings.quitProtection(language).name
        case .scrollInverter: return s.invertMouseScroll
        case .scrollHorizontal: return s.scrollHorizontalName
        case .focusFollowsMouse: return s.focusFollowsMouseName
        case .smoothScroll: return s.smoothScrollName
        case .mouseAcceleration: return s.mouseAccelerationName
        case .mouseNavigation: return FeatureStrings.hub(language).titleMouseNavigation
        case .mouseButtonShortcuts: return FeatureStrings.mouseButtons(language).pageTitle
        case .middleClick: return s.middleClickSection
        case .keyboardDebounce: return s.keyDebounceName
        case .textSnippets: return FeatureStrings.snippets(language).pageTitle
        case .superKey: return FeatureStrings.superKey(language).pageTitle
        case .mouseClickDebounce:
            return FeatureStrings.mouseClickDebounce(language).title
        case .clipboardHistory: return FeatureStrings.clipboard(language).title
        case .pastePlain: return s.pastePlainName
        case .finderCutPaste: return s.cutPasteName
        case .finderRename: return FeatureStrings.finderRename(language).hubTitle
        case .shelf: return s.shelfName
        case .urlCleaner: return s.urlCleanerName
        case .mixer: return FeatureStrings.mixer(language).pageTitle
        case .soundOutputSwitcher: return FeatureStrings.soundOutputSwitcher(language).pageTitle
        case .micMute: return FeatureStrings.micMute(language).pageTitle
        case .musicBlock: return FeatureStrings.musicBlock(language).pageTitle
        case .keepAwake: return s.keepAwakeTitle
        case .brightness: return FeatureStrings.brightness(language).pageTitle
        case .bluetoothSleep: return FeatureStrings.bluetoothSleep(language).pageTitle
        case .colorPicker: return s.colorPickerName
        case .screenOCR: return s.ocrName
        case .screenshot: return FeatureStrings.screenshot(language).pageTitle
        case .screenRecorder: return FeatureStrings.recorder(language).pageTitle
        case .radialMenu: return FeatureStrings.radialMenu(language).pageTitle
        case .scratchpad: return FeatureStrings.scratchpad(language).pageTitle
        case .commandBar: return FeatureStrings.commandBar(language).pageTitle
        case .cleaningMode: return s.cleaningMenuItem
        case .mediaTools: return s.mediaName
        case .cleaner: return s.cleanerName
        case .uninstaller: return s.uninstallerName
        case .homebrew: return s.homebrewName
        case .environment: return FeatureStrings.environment(language).pageTitle
        case .killProcess: return FeatureStrings.killProcess(language).pageTitle
        case .cameraPreview: return FeatureStrings.cameraPreview(language).pageTitle
        case .portManager: return FeatureStrings.portManager(language).title
        case .monitorCPU: return s.monitorShowCPU
        case .monitorGPU: return s.monitorShowGPU
        case .monitorMemory: return s.monitorShowMemory
        case .monitorNetwork: return s.monitorShowNetwork
        case .monitorDisk: return s.diskSection
        case .monitorPower: return s.powerSection
        case .fanControl: return FeatureStrings.fanControl(language).title
        }
    }
}
