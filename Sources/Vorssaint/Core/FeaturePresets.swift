// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import Foundation

/// Preserved starting sets for first-run seeding and existing preset behavior.
/// The Features hub and onboarding no longer expose preset buttons.
enum FeaturePreset: String, CaseIterable, Identifiable {
    case essential, windows, battery

    var id: String { rawValue }

    /// A clean install starts from the small Essential set before any feature
    /// binding runs. Updates keep every existing availability choice, and an
    /// interrupted setup keeps the selection already applied on its purpose
    /// step.
    static func prepareFirstRunAvailability(in defaults: UserDefaults = .standard) {
        guard !defaults.bool(forKey: DefaultsKey.hasOnboarded),
              defaults.integer(forKey: DefaultsKey.onboardingStep) == 0
        else { return }
        let selected = FeaturePreset.essential.units
        for unit in FeatureUnit.allCases {
            defaults.set(selected.contains(unit), forKey: unit.availabilityKey)
        }
    }

    /// The units the preset keeps installed. Their members arrive with
    /// whatever switches and enable keys they already had.
    var units: Set<FeatureUnit> {
        switch self {
        case .essential:
            return [.mixer, .keepAwake, .monitor]
        case .windows:
            return [.switcher, .dock, .windowLayout, .windowBehavior]
        case .battery:
            // The monitor alone: nothing that listens to input events.
            return [.monitor]
        }
    }

    /// Enable keys switched on along with the install, so the preset's
    /// features actually work instead of arriving as more toggles to find.
    /// Presets whose features are on-demand need none.
    var enableKeys: [String] {
        switch self {
        case .essential, .battery:
            return []
        case .windows:
            return [DefaultsKey.switcherEnabled,
                    DefaultsKey.dockPreviewEnabled,
                        DefaultsKey.dockClickMinimize,
                    DefaultsKey.windowMaximizeEnabled]
        }
    }

    var symbolName: String {
        switch self {
        case .essential: return "star.fill"
        case .windows: return "macwindow.on.rectangle"
        case .battery: return "battery.75percent"
        }
    }
}

/// The honest, curated cost label each feature earns in the hub: what the
/// feature keeps alive WHILE IT IS ON. Uninstalled features load nothing at
/// all, which is the hub's own promise. Static by design — pretending to
/// measure per-feature cost live would be theater.
enum FeatureEnergyProfile: String, Comparable {
    /// Nothing at rest: on-demand tools, shortcut-driven actions and
    /// system-notification listeners.
    case idle
    /// A mouse event tap (scrolls, clicks or pointer moves).
    case mouse
    /// A pointer gesture that works with either a trackpad or mouse.
    case pointer
    /// A keyboard event tap.
    case keyboard
    /// Both input taps.
    case inputs
    /// Samples or polls on an interval while active or visible.
    case periodic

    /// Heavier costs sort later: taps over polling over nothing.
    private var weight: Int {
        switch self {
        case .idle: return 0
        case .periodic: return 1
        case .pointer: return 2
        case .mouse: return 3
        case .keyboard: return 4
        case .inputs: return 5
        }
    }

    static func < (lhs: Self, rhs: Self) -> Bool { lhs.weight < rhs.weight }

    func label(_ hub: FeatureHubStrings) -> String {
        switch self {
        case .idle: return hub.energyIdle
        case .mouse: return hub.energyMouse
        case .pointer: return hub.energyPointer
        case .keyboard: return hub.energyKeyboard
        case .inputs: return hub.energyInputs
        case .periodic: return hub.energyPeriodic
        }
    }
}

extension AppFeature {
    var energyProfile: FeatureEnergyProfile {
        switch self {
        case .scrollInverter, .scrollHorizontal, .focusFollowsMouse, .smoothScroll, .windowMaximizer,
             .middleClick,
             .mouseNavigation, .mouseButtonShortcuts, .mouseClickDebounce,
             .dockPreview, .dockClick, .shelf:
            return .mouse
        case .switcher, .keyboardDebounce, .finderCutPaste, .finderRename, .superKey, .quitWindowProtection:
            return .keyboard
        case .textSnippets, .autoQuit:
            return .inputs
        case .windowLayout:
            let edgeSnapRuns = UserDefaults.standard.bool(forKey: DefaultsKey.windowEdgeSnapEnabled)
                && !WindowEdgeSnapZone.enabledZones(
                    from: UserDefaults.standard.string(
                        forKey: DefaultsKey.windowEdgeSnapDisabledZones)
                ).isEmpty
            return UserDefaults.standard.bool(forKey: DefaultsKey.windowGestureEnabled)
                || edgeSnapRuns
                ? .pointer : .idle
        case .radialMenu:
            // With a side button configured the trigger is a mouse tap;
            // shortcut-only costs nothing at rest.
            return RadialMenuMouseTrigger.sanitized(
                UserDefaults.standard.string(forKey: DefaultsKey.radialMenuMouseButton)) == .off
                ? .idle : .mouse
        case .clipboardHistory, .urlCleaner,
             .monitorCPU, .monitorGPU, .monitorMemory,
             .monitorNetwork, .monitorDisk, .monitorPower:
            return .periodic
        case .mixer:
            // The keyboard tap is the precise volume roller's, not the
            // mixer's: its own switch costs nothing at rest.
            return UserDefaults.standard.bool(forKey: DefaultsKey.preciseVolumeRollerEnabled)
                ? .keyboard : .idle
        case .mouseAcceleration, .pastePlain, .soundOutputSwitcher, .micMute,
             .musicBlock, .bluetoothSleep, .keepAwake, .brightness, .colorPicker,
             .screenOCR, .cleaningMode, .mediaTools, .cleaner, .uninstaller, .homebrew, .environment, .screenshot,
             .scratchpad, .commandBar, .screenRecorder, .fanControl, .killProcess,
             .cameraPreview, .portManager:
            return .idle
        }
    }
}
