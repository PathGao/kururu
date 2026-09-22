// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import Combine
import Foundation

/// The Settings pages. Lives here (without SwiftUI) so the visibility rules
/// below and the unit tests can reason about pages without pulling UI in.
enum SettingsPage: Hashable {
    case features, menuBarIcon, menuBarPanel, monitor
    case keepAwake, brightness, bluetoothSleep, cleaningMode, mouse, trackpad, switcher, dock, keyboard, cutPaste, windowBehavior, cleaner, uninstaller, homebrew, environment, media, clipboard, urlCleaner, shelf, screenshot, radialMenu, commandBar, mixer, micMute, musicBlock, scratchpad
    case shortcuts, advanced, about, releaseNotes
}

extension SettingsPage: CaseIterable {
    /// The sidebar row title; the command bar searches by it too.
    func title(_ s: Strings, language: AppLanguage) -> String {
        switch self {
        case .features: return FeatureStrings.hub(language).pageTitle
        case .menuBarIcon: return s.tabMenuBarIcon
        case .menuBarPanel: return s.tabMenuBarPanel
        case .monitor: return s.tabMonitor
        case .switcher: return AppFeature.switcher.name(s, language: language)
        case .dock: return s.tabDock
        case .windowBehavior: return s.tabWindowBehavior
        case .mouse: return s.tabMouse
        case .trackpad: return s.tabTrackpad
        case .keyboard: return s.tabKeyboard
        case .commandBar: return FeatureStrings.commandBar(language).pageTitle
        case .radialMenu: return FeatureStrings.radialMenu(language).pageTitle
        case .clipboard: return FeatureStrings.clipboard(language).title
        case .urlCleaner: return s.urlCleanerName
        case .cutPaste: return FeatureStrings.finderRename(language).pageTitle
        case .shelf: return s.shelfName
        case .scratchpad: return FeatureStrings.scratchpad(language).pageTitle
        case .screenshot: return FeatureStrings.screenshot(language).screenCaptureTitle
        case .media: return s.mediaName
        case .mixer: return AppFeature.mixer.name(s, language: language)
        case .micMute: return AppFeature.micMute.name(s, language: language)
        case .musicBlock: return AppFeature.musicBlock.name(s, language: language)
        case .keepAwake: return AppFeature.keepAwake.name(s, language: language)
        case .brightness: return FeatureStrings.brightness(language).pageTitle
        case .bluetoothSleep: return AppFeature.bluetoothSleep.name(s, language: language)
        case .cleaningMode: return AppFeature.cleaningMode.name(s, language: language)
        case .cleaner: return s.cleanerName
        case .homebrew: return s.homebrewName
        case .environment: return FeatureStrings.environment(language).pageTitle
        case .uninstaller: return s.uninstallerName
        case .shortcuts: return s.shortcutsPageTitle
        case .advanced: return SettingsHierarchyStrings(language: language).pageTitle
        case .about: return s.tabAbout
        case .releaseNotes: return s.tabReleaseNotes
        }
    }
}

/// Stable, non-localized identities for destinations inside shared Settings
/// pages. Raw values may be persisted or used by UI identifiers, so cases can
/// be added but should not be renamed.
enum SettingsSectionAnchor: String, CaseIterable, Hashable {
    case panelConfiguration
    case musicBlocking
    case keepAwake
    case brightness
    case bluetoothSleep
    case scrollDirection
    case focusFollowsMouse
    case smoothScroll
    case mouseAcceleration
    case mouseNavigation
    case mouseButtonShortcuts
    case middleClick
    case mouseClickDebounce
    case switcher
    case dock
    case dockClick
    case finderCutPaste
    case finderRename
    case clipboardHistory
    case pastePlain
    case screenshot
    case screenRecorder
    case colorPicker
    case screenOCR
    case micMute
    case cleaningMode
    case soundOutputSwitcher
    case fanControl
    case keyboardDebounce
    case superKey
    case textSnippets
    case urlCleaner

    var page: SettingsPage {
        switch self {
        case .musicBlocking: return .musicBlock
        case .micMute: return .micMute
        case .soundOutputSwitcher: return .mixer
        case .keepAwake: return .keepAwake
        case .brightness: return .brightness
        case .bluetoothSleep: return .bluetoothSleep
        case .cleaningMode: return .cleaningMode
        case .scrollDirection, .focusFollowsMouse, .smoothScroll, .mouseAcceleration, .mouseNavigation, .mouseButtonShortcuts,
             .mouseClickDebounce:
            return .mouse
        case .middleClick: return .trackpad
        case .switcher: return .switcher
        case .dock, .dockClick: return .dock
        case .finderCutPaste, .finderRename: return .cutPaste
        case .clipboardHistory, .pastePlain: return .clipboard
        case .urlCleaner: return .urlCleaner
        case .keyboardDebounce, .superKey, .textSnippets: return .keyboard
        case .screenshot, .screenRecorder, .colorPicker, .screenOCR:
            return .screenshot
        case .panelConfiguration: return .menuBarPanel
        case .fanControl: return .monitor
        }
    }
}

/// A feature's nearest configuration surface. The optional anchor distinguishes
/// a feature section on a shared page; nil means the page itself is the target.
struct FeatureSettingsDestination: Hashable {
    let page: SettingsPage
    let sectionAnchor: SettingsSectionAnchor?

    init(_ page: SettingsPage, sectionAnchor: SettingsSectionAnchor? = nil) {
        self.page = page
        self.sectionAnchor = sectionAnchor
    }

    var hasValidSectionAnchor: Bool {
        sectionAnchor == nil || sectionAnchor?.page == page
    }
}

struct SettingsDestinationRequest: Equatable {
    let id: UUID
    let destination: FeatureSettingsDestination
}

/// A one-shot request to reveal a specific feature's row inside the Features
/// hub, correlated with the destination request that carries it by sharing
/// the same request id.
struct SettingsFeatureTargetRequest: Equatable {
    let id: UUID
    let feature: AppFeature
}

/// Selects a Settings destination and publishes a fresh request identity even
/// when callers ask for the same page and anchor repeatedly.
final class SettingsRouter: ObservableObject {
    static let shared = SettingsRouter()

    @Published var page: SettingsPage = .features
    @Published private(set) var destination = FeatureSettingsDestination(.features)
    @Published private(set) var requestID = UUID()
    @Published private(set) var pendingDestinationRequest: SettingsDestinationRequest?
    /// One-shot hint for the Features hub: which feature row to reveal once
    /// the requested page lands. Always set (to nil when no target is given)
    /// on every `request`, so a stale target from an earlier search can never
    /// leak into a later, unrelated navigation.
    @Published private(set) var pendingFeatureTarget: SettingsFeatureTargetRequest?
    /// One-shot hint for the Cleaner page's tool switcher, so a panel surface
    /// can land directly on a specific tool. Consumed and cleared on arrival.
    @Published var cleanerTool: String?

    private init() {}

    func request(_ destination: FeatureSettingsDestination, targetFeature: AppFeature? = nil) {
        let requestID = UUID()
        self.destination = destination
        page = destination.page
        pendingDestinationRequest = SettingsDestinationRequest(id: requestID,
                                                               destination: destination)
        pendingFeatureTarget = targetFeature.map {
            SettingsFeatureTargetRequest(id: requestID, feature: $0)
        }
        self.requestID = requestID
    }

    /// Clears only the request a view actually handled. A newer request that
    /// arrived while the destination page was being installed must survive.
    func consumeDestinationRequest(id: UUID) {
        guard pendingDestinationRequest?.id == id else { return }
        pendingDestinationRequest = nil
    }

    /// Clears only the feature target a view actually revealed. Mirrors
    /// `consumeDestinationRequest`: a newer request that arrived while the
    /// Features hub was still laying out must survive.
    func consumeFeatureTarget(id: UUID) {
        guard pendingFeatureTarget?.id == id else { return }
        pendingFeatureTarget = nil
    }
}

extension AppFeature {
    /// The hub itself is the honest fallback for features without a separate
    /// configuration surface, but linking a row back to its current page would
    /// present a chevron that appears to do nothing.
    var hasNavigableSettingsDestination: Bool {
        settingsDestination.page != .features
    }

    /// Exhaustive by design: adding an AppFeature requires choosing its
    /// Settings destination before the project compiles.
    var settingsDestination: FeatureSettingsDestination {
        switch self {
        case .switcher: return FeatureSettingsDestination(.switcher, sectionAnchor: .switcher)
        case .dockPreview: return FeatureSettingsDestination(.dock, sectionAnchor: .dock)
        case .dockClick: return FeatureSettingsDestination(.dock, sectionAnchor: .dockClick)
        case .windowMaximizer, .autoQuit, .quitWindowProtection:
            return FeatureSettingsDestination(.windowBehavior)

        case .scrollInverter, .scrollHorizontal:
            return FeatureSettingsDestination(.mouse, sectionAnchor: .scrollDirection)
        case .focusFollowsMouse:
            return FeatureSettingsDestination(.mouse, sectionAnchor: .focusFollowsMouse)
        case .smoothScroll:
            return FeatureSettingsDestination(.mouse, sectionAnchor: .smoothScroll)
        case .mouseAcceleration:
            return FeatureSettingsDestination(.mouse, sectionAnchor: .mouseAcceleration)
        case .mouseNavigation:
            return FeatureSettingsDestination(.mouse, sectionAnchor: .mouseNavigation)
        case .mouseButtonShortcuts:
            return FeatureSettingsDestination(.mouse, sectionAnchor: .mouseButtonShortcuts)
        case .middleClick:
            return FeatureSettingsDestination(.trackpad, sectionAnchor: .middleClick)
        case .mouseClickDebounce:
            return FeatureSettingsDestination(.mouse, sectionAnchor: .mouseClickDebounce)
        case .keyboardDebounce:
            return FeatureSettingsDestination(.keyboard, sectionAnchor: .keyboardDebounce)
        case .textSnippets:
            return FeatureSettingsDestination(.keyboard, sectionAnchor: .textSnippets)
        case .superKey:
            return FeatureSettingsDestination(.keyboard, sectionAnchor: .superKey)

        case .clipboardHistory:
            return FeatureSettingsDestination(.clipboard, sectionAnchor: .clipboardHistory)
        case .pastePlain:
            return FeatureSettingsDestination(.clipboard, sectionAnchor: .pastePlain)
        case .finderCutPaste:
            return FeatureSettingsDestination(.cutPaste, sectionAnchor: .finderCutPaste)
        case .finderRename:
            return FeatureSettingsDestination(.cutPaste, sectionAnchor: .finderRename)
        case .shelf: return FeatureSettingsDestination(.shelf)
        case .urlCleaner: return FeatureSettingsDestination(.urlCleaner, sectionAnchor: .urlCleaner)

        case .mixer: return FeatureSettingsDestination(.mixer)
        case .soundOutputSwitcher:
            return FeatureSettingsDestination(.mixer, sectionAnchor: .soundOutputSwitcher)
        case .micMute:
            return FeatureSettingsDestination(.micMute, sectionAnchor: .micMute)
        case .musicBlock:
            return FeatureSettingsDestination(.musicBlock, sectionAnchor: .musicBlocking)

        case .keepAwake:
            return FeatureSettingsDestination(.keepAwake, sectionAnchor: .keepAwake)
        case .brightness:
            return FeatureSettingsDestination(.brightness, sectionAnchor: .brightness)
        case .bluetoothSleep:
            return FeatureSettingsDestination(.bluetoothSleep, sectionAnchor: .bluetoothSleep)

        case .colorPicker:
            return FeatureSettingsDestination(.screenshot, sectionAnchor: .colorPicker)
        case .screenOCR:
            return FeatureSettingsDestination(.screenshot, sectionAnchor: .screenOCR)
        case .cleaningMode:
            return FeatureSettingsDestination(.cleaningMode, sectionAnchor: .cleaningMode)
        case .mediaTools: return FeatureSettingsDestination(.media)
        case .cleaner: return FeatureSettingsDestination(.cleaner)
        case .uninstaller: return FeatureSettingsDestination(.uninstaller)
        case .homebrew: return FeatureSettingsDestination(.homebrew)
        case .environment: return FeatureSettingsDestination(.environment)
        case .screenshot:
            return FeatureSettingsDestination(.screenshot, sectionAnchor: .screenshot)
        case .radialMenu: return FeatureSettingsDestination(.radialMenu)
        case .scratchpad: return FeatureSettingsDestination(.scratchpad)
        case .commandBar: return FeatureSettingsDestination(.commandBar)
        case .screenRecorder:
            return FeatureSettingsDestination(.screenshot, sectionAnchor: .screenRecorder)

        case .monitorCPU, .monitorGPU, .monitorMemory, .monitorNetwork, .monitorDisk, .monitorPower:
            return FeatureSettingsDestination(.monitor)
        case .fanControl:
            return FeatureSettingsDestination(.monitor, sectionAnchor: .fanControl)
        }
    }
}

/// Which hub features keep each Settings page alive. A page with several
/// features only disappears when ALL of them are switched off in the hub.
enum FeatureVisibilitySupport {
    static let monitorFeatures: [AppFeature] = [
        .monitorCPU, .monitorGPU, .monitorMemory, .monitorNetwork, .monitorDisk, .monitorPower,
        .fanControl,
    ]

    /// Features gating a page; empty means the page is part of the app and
    /// always shows (Appearance, Shortcuts, About and friends).
    static func features(for page: SettingsPage) -> [AppFeature] {
        switch page {
        case .keepAwake: return [.keepAwake]
        case .brightness: return [.brightness]
        case .bluetoothSleep: return [.bluetoothSleep]
        case .cleaningMode: return [.cleaningMode]
        case .monitor: return monitorFeatures
        case .mouse: return [.scrollInverter, .scrollHorizontal, .focusFollowsMouse, .smoothScroll, .mouseAcceleration, .mouseNavigation, .mouseButtonShortcuts,
                             .mouseClickDebounce]
        case .trackpad: return [.middleClick]
        case .switcher: return [.switcher]
        case .dock: return [.dockPreview, .dockClick]
        case .windowBehavior: return [.windowMaximizer, .autoQuit, .quitWindowProtection]
        case .clipboard: return [.clipboardHistory, .pastePlain]
        case .urlCleaner: return [.urlCleaner]
        case .cutPaste: return [.finderCutPaste, .finderRename]
        case .shelf: return [.shelf]
        case .media: return [.mediaTools]
        case .mixer: return [.mixer, .soundOutputSwitcher]
        case .micMute: return [.micMute]
        case .musicBlock: return [.musicBlock]
        case .scratchpad: return [.scratchpad]
        case .cleaner: return [.cleaner]
        case .homebrew: return [.homebrew]
        case .environment: return [.environment]
        case .uninstaller: return [.uninstaller]
        case .keyboard: return [.keyboardDebounce, .textSnippets, .superKey]
        case .screenshot: return [.screenshot, .screenRecorder, .screenOCR, .colorPicker]
        case .radialMenu: return [.radialMenu]
        case .commandBar: return [.commandBar]
        case .features, .menuBarIcon, .menuBarPanel, .shortcuts, .advanced, .about, .releaseNotes:
            return []
        }
    }

    /// Keep only the page currently being inspected alongside active modules.
    static func isSidebarPageVisible(_ page: SettingsPage, selectedPage: SettingsPage,
                                     isAvailable: (AppFeature) -> Bool) -> Bool {
        page == selectedPage || isPageVisible(page, isAvailable: isAvailable)
    }

    static func configurationUnit(for page: SettingsPage) -> FeatureUnit? {
        if page == .urlCleaner { return .clipboard }
        return FeatureUnit.allCases.first { $0.page == page }
    }

    /// Callers pass the unit's availability, not the feature's: a page is
    /// the unit's surface and has to stay while a member is only switched
    /// off, or the switch could never be reached again.
    static func isPageVisible(_ page: SettingsPage,
                              isAvailable: (AppFeature) -> Bool) -> Bool {
        let gate = features(for: page)
        return gate.isEmpty || gate.contains(where: isAvailable)
    }
}
