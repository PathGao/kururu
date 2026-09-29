// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import Combine
import Foundation

/// Languages the interface can use. The first launch defaults to the system
/// language; the onboarding and Settings let the user override it at any time.
enum AppLanguage: String, CaseIterable, Identifiable {
    case enUS = "en-US"
    case ptBR = "pt-BR"
    case tr = "tr"
    case ru = "ru"
    case es = "es"
    case de = "de"
    case fr = "fr"
    case it = "it"
    case ja = "ja"
    case ko = "ko"
    case zhHans = "zh-Hans"
    case zhTW = "zh-TW"
    case zhHK = "zh-HK"

    var id: String { rawValue }

    /// Whether this language puts a distinct form between one and many. Only
    /// Russian, of the thirteen: two through four take a form of their own,
    /// so "2 файла" and not "2 файлов".
    var usesFewCountForm: Bool { self == .ru }

    /// The language's own name, shown in its own script, the way macOS lists them.
    var displayName: String {
        switch self {
        case .enUS: return "English (US)"
        case .ptBR: return "Português (Brasil)"
        case .tr: return "Türkçe"
        case .ru: return "Русский"
        case .es: return "Español"
        case .de: return "Deutsch"
        case .fr: return "Français"
        case .it: return "Italiano"
        case .ja: return "日本語"
        case .ko: return "한국어"
        case .zhHans: return "简体中文"
        case .zhHK: return "繁體中文（香港）"
        case .zhTW: return "繁體中文（台灣）"
        }
    }

    static var systemDefault: AppLanguage {
        let preferred = Locale.preferredLanguages.first ?? "en"
        let p = preferred.lowercased()

        if p.hasPrefix("zh-hk") || p.hasPrefix("zh-hant-hk") {
            return .zhHK
        }

        if p.hasPrefix("zh-tw") || p.hasPrefix("zh-hant-tw") || p.hasPrefix("zh-hant") {
            return .zhTW
        }

        let matches: [(String, AppLanguage)] = [
            ("pt", .ptBR), ("tr", .tr), ("ru", .ru), ("es", .es), ("de", .de), ("fr", .fr),
            ("it", .it), ("ja", .ja), ("ko", .ko), ("zh", .zhHans),
        ]
        for (prefix, language) in matches where preferred.hasPrefix(prefix) { return language }
        return .enUS
    }
}

/// Source of every user-facing string. Views observe this object so the whole
/// interface re-renders immediately when the language changes.
final class L10n: ObservableObject {
    static let shared = L10n()

    @Published var language: AppLanguage {
        didSet { UserDefaults.standard.set(language.rawValue, forKey: DefaultsKey.language) }
    }

    var s: Strings {
        switch language {
        case .enUS: return .enUS
        case .ptBR: return .ptBR
        case .tr: return .tr
        case .ru: return .ru
        case .es: return .es
        case .de: return .de
        case .fr: return .fr
        case .it: return .it
        case .ja: return .ja
        case .ko: return .ko
        case .zhHans: return .zhHans
        case .zhHK: return .zhHK
        case .zhTW: return .zhTW
        }
    }

    private init() {
        if let raw = UserDefaults.standard.string(forKey: DefaultsKey.language),
           let saved = AppLanguage(rawValue: raw) {
            language = saved
        } else {
            language = .systemDefault
        }
    }
}

/// Flat, compiler-checked catalog of UI strings. Adding a field here forces
/// both translations to be provided.
/// Every field carries its English text as the default, so a language passes
/// only what it has translated and whatever it omits reads as English. Adding
/// a field means writing English here and nothing else; the twelve other
/// literals keep compiling untouched.
///
/// English is the only language that has to be complete, and it is complete by
/// construction: it is these defaults. Every other language translates as much
/// or as little as it wants.
struct Strings {
    // MARK: Menu bar & context menu
    var statusIdleTooltip: String = "\(AppInfo.name): normal sleep"
    var statusActiveUntil: String = "\(AppInfo.name): awake until"      // + time
    var statusActiveIndefinite: String = "\(AppInfo.name): awake indefinitely"
    var menuEnableAwake: String = "Enable keep awake"
    var menuDisableAwake: String = "Disable keep awake"
    var menuActivateFor: String = "Activate for…"
    var menuSettings: String = "Settings…"
    var menuAbout: String = "About \(AppInfo.name)"
    var menuQuit: String = "Quit \(AppInfo.name)"
    // Standard application menu bar (App / Edit / Window) shown while one of the
    // app's own windows is focused. Without it, an accessory app has no main menu
    // and the standard shortcuts (Cmd+H/M/W/Q, Cmd+C/V/X/A) do nothing.
    var menuHide: String = "Hide \(AppInfo.name)"
    var menuHideOthers: String = "Hide Others"
    var menuShowAll: String = "Show All"
    var menuEdit: String = "Edit"
    var menuUndo: String = "Undo"
    var menuRedo: String = "Redo"
    /// Named actions an icon-only control borrows so it can say what it
    /// does. No feature owns these, because half a dozen already share them.
    var actionClear: String = "Clear"
    var actionRemove: String = "Remove"
    var actionBack: String = "Back"
    var actionSearch: String = "Search"
    var actionMute: String = "Mute"
    var actionUnmute: String = "Unmute"
    var actionPlay: String = "Play"
    var actionPause: String = "Pause"
    var menuCut: String = "Cut"
    var menuCopy: String = "Copy"
    var menuPaste: String = "Paste"
    var menuSelectAll: String = "Select All"
    var menuWindow: String = "Window"
    var menuMinimize: String = "Minimize"
    var menuZoom: String = "Zoom"
    var menuClose: String = "Close"

    // MARK: Durations
    var minutes15: String = "15 minutes"
    var minutes30: String = "30 minutes"
    var hour1: String = "1 hour"
    var hours2: String = "2 hours"
    var hours4: String = "4 hours"
    var hours8: String = "8 hours"
    var indefinitely: String = "Indefinitely"
    var indefinite: String = "Indefinite"

    // MARK: Panel — header & footer
    var panelSettings: String = "Settings"
    var panelQuit: String = "Quit"

    // MARK: Panel — keep awake card
    var keepAwakeTitle: String = "Keep awake"
    var keepAwakeEndsIn: String = "Ends in"        // + remaining
    var keepAwakeUntilDisabled: String = "Active until you turn it off"
    var keepAwakeNormalRules: String = "The Mac follows its normal energy rules"
    var keepAwakeUntilLabel: String = "Until"
    var keepAwakeUntilStart: String = "Start"
    var keepAwakeOptions: String = "Options"
    var keepAwakeMouseJiggle: String = "Move pointer slightly"
    var keepAwakeMouseJiggleCaption: String = "During a session, moves the pointer a little at the chosen interval."
    var keepAwakeMouseJiggleInterval: String = "Interval"
    var keepAwakeActiveIconLabel: String = "Active icon"
    var keepAwakeActiveIconVorssaint: String = "\(AppInfo.name)"
    var keepAwakeActiveIconCoffee: String = "Coffee"
    var keepAwakeActiveIconEye: String = "Eye"
    var keepAwakeActiveIconMoon: String = "Moon"
    var keepAwakeActiveIconLight: String = "Lightbulb"
    var keepAwakeIconTintLabel: String = "Active icon color"
    var keepAwakeIconTintOrange: String = "Orange"
    var keepAwakeIconTintGreen: String = "Green"
    var keepAwakeIconTintBlue: String = "Blue"
    var keepAwakeIconTintPurple: String = "Purple"
    var keepAwakeIconTintPink: String = "Pink"
    var keepAwakeIconTintNone: String = "No color"
    var durationLabel: String = "Duration"
    var clamshellTitle: String = "Keep going with the lid closed"
    var clamshellOnCaption: String = "Sleep fully disabled. Mind the power"
    var clamshellNeedsSession: String = "Applied whenever “Keep awake” is active"
    var clamshellReady: String = "Ready. Toggles without a password"
    var clamshellNeedsPassword: String = "Will ask for the administrator password once"

    // MARK: Panel — system monitor
    var systemSection: String = "System"
    var temperatures: String = "Temperatures"
    var cpuLabel: String = "CPU"
    var gpuLabel: String = "GPU"
    var batteryLabel: String = "Battery"
    var usageSection: String = "Hardware usage"
    var memorySection: String = "Memory"
    var memoryPressure: String = "Pressure"
    var memorySwapUsed: String = "Swap used"
    var memoryCompressed: String = "Compressed"
    var memoryCachedFiles: String = "Cached files"
    var pressureNormal: String = "Normal"
    var pressureWarning: String = "Caution"
    var pressureCritical: String = "Critical"
    var monitorUnavailable: String = "Sensors unavailable on this Mac"
    var energyAppsTitle: String = "Apps using significant energy"
    var energyAppsIdle: String = "No significant energy use"

    // MARK: Notifications
    var notifySessionEndedTitle: String = "Session ended"
    var notifySessionEndedBody: String = "Time is up. The Mac will sleep normally again."
    var notifyBatteryTitle: String = "\(AppInfo.name) disabled"
    var notifyBatteryBody: String = "Low battery. Normal sleep was restored to protect the charge."

    // MARK: Administrator prompts (shown by macOS password dialogs)
    var adminPromptClamshellOff: String = "\(AppInfo.name) needs your password to restore the Mac’s normal sleep."
    var adminPromptRecover: String = "\(AppInfo.name) quit while the Mac’s sleep was disabled. Enter the password to restore normal sleep."
    var adminPromptUpdate: String = "\(AppInfo.name) needs your password to install the update."
    var adminPromptSudoersInstall: String = "\(AppInfo.name) will create a restricted rule (pmset disablesleep only) to toggle closed-lid mode without asking for a password. This is the only time the password is needed."
    var adminPromptSudoersRemove: String = "\(AppInfo.name) will remove the password-free closed-lid rule."

    // MARK: Settings — window & tabs
    var settingsTitle: String = "\(AppInfo.name) Settings"
    var tabGeneral: String = "General"
    var tabMouse: String = "Mouse"
    var tabDock: String = "Dock"
    var tabWindowBehavior: String = "Window behaviour"
    var tabKeyboard: String = "Keyboard"
    var tabTrackpad: String = "Trackpad"
    var tabAdvanced: String = "Advanced"
    var tabAbout: String = "About"
    var tabReleaseNotes: String = "What’s New"

    // MARK: Settings — advanced
    var advancedResetSection: String = "Permissions"
    var advancedResetDescription: String = "Removes every permission you granted \(AppInfo.name) (Accessibility, Screen Recording, Full Disk Access and others), the login item and the closed-lid rule. Useful to start fresh or before uninstalling. The app stays installed."
    var advancedClearButton: String = "Clear all permissions"
    var advancedCleared: String = "Permissions cleared."
    var advancedClearConfirmTitle: String = "Clear all permissions?"
    var advancedClearConfirmBody: String = "Features that need permissions will stop working until you grant them again. Your settings are kept."
    var advancedUninstallSection: String = "Uninstall"
    var advancedUninstallDescription: String = "Attempts to remove this app’s permissions, login item and password-free closed-lid rule, and clear its preferences and local app data. After the app quits, it attempts to move itself to the Trash. Separately saved backups and exports are not deleted."
    var advancedUninstallButton: String = "Uninstall \(AppInfo.name) completely"
    var advancedUninstallConfirmTitle: String = "Uninstall \(AppInfo.name)?"
    var advancedUninstallConfirmBody: String = "\(AppInfo.name) will clear its permissions, remove its preferences and move to the Trash, then quit. This can’t be undone from the app, but it stays in the Trash until you empty it."
    var advancedUninstallFailedTitle: String = "Uninstall stopped"
    var advancedUninstallFailedBody: String = "\(AppInfo.name) could not put back a system setting it changed: sleep, fan speed or mouse acceleration. Nothing was removed. Try again and allow the password request if it appears."

    // MARK: Settings — general
    var launchAtLogin: String = "Launch at login"
    var languageLabel: String = "Language"
    var showCountdown: String = "Show remaining time next to the icon"
    var hotkeyToggle: String = "Enable shortcut for “Keep awake”"
    var hotkeyCaption: String = "Works in any app, no extra permissions."

    // MARK: Settings — energy
    var sessionSection: String = "Session"
    var defaultDurationLabel: String = "Default duration"
    var keepAwakeAutoStart: String = "Keep Awake when \(AppInfo.name) opens"
    var keepAwakeAutoStartCaption: String = "Starts a session with the default duration."
    var batteryProtectionSection: String = "Battery protection"
    var batteryDisableBelow: String = "Disable when battery drops below"
    var batteryNever: String = "Never"
    var batteryProtectionCaption: String = "Keeps a forgotten session from draining the MacBook battery."
    var clamshellSection: String = "Closed lid"
    var configuring: String = "Configuring…"
    var sudoersFailed: String = "Couldn’t turn on closed-lid mode. Try again."
    var clamshellExplanation: String = "“Keep going with the lid closed” fully disables sleep while “Keep awake” is active and is reverted automatically when the session ends or the app quits. Prefer using it plugged in."

    // MARK: Settings — mouse
    var scrollSection: String = "Scrolling"
    var invertMouseScroll: String = "Invert mouse scrolling"
    var invertMouseScrollCaption: String = "Reverses the mouse wheel direction."
    var scrollTrackpadNote: String = "The trackpad is untouched: it keeps macOS natural scrolling."
    var scrollActiveNow: String = "Inverting mouse scrolling right now"
    var mouseNavigationActiveNow: String = "Side buttons active right now"
    var smoothScrollName: String = "Smooth scrolling"
    var smoothScrollCaption: String = "Turns each mouse wheel step into a short, gentle glide. The trackpad is not affected."
    var smoothScrollStepLabel: String = "Scrolling speed"
    var mouseNavigationEnable: String = "Use side buttons for Back and Forward"
    var mouseNavigationCaption: String = "Turns the mouse Back and Forward buttons into navigation commands in Finder, browsers and compatible apps."
    var middleClickSection: String = "Middle click"
    var middleClickEnable: String = "Three-finger click acts as middle click"
    var middleClickEnableCaption: String = "Pressing the trackpad with three fingers works like a mouse wheel click: open links in a new tab, close tabs and everything else the middle button does."
    var middleClickDragConflict: String = "macOS three-finger drag is turned on and uses this same gesture. Turn it off in System Settings under Accessibility, Pointer Control, Trackpad Options, and the middle click will work."
    var middleClickTapPicker: String = "A light tap also clicks"
    var middleClickTapOff: String = "Off"
    var middleClickTapThreeFingers: String = "3 fingers"
    var middleClickTapFourFingers: String = "4 fingers"
    var middleClickTapCaption: String = "A light tap with that many fingers, without pressing, also fires the middle click. Sliding never counts. If the macOS three-finger tap is assigned to Look Up, turn it off so both do not fire together."
    var quickToolShortcutToggle: String = "Global shortcut"
    var ocrName: String = "Copy text from screen"
    var ocrCaption: String = "Select an area of the screen and the recognized text is copied, ready to paste."
    var ocrCopied: String = "Text copied"
    var ocrNoText: String = "No text found"
    var colorPickerName: String = "Color picker"
    var colorPickerCaption: String = "Grab the color of any pixel on screen and copy it in your favorite format."
    var colorPickerFormatLabel: String = "Copied format"
    var colorPickerBareHexToggle: String = "Copy without the # prefix"
    var colorPickerPickNow: String = "Pick color"
    var pastePlainName: String = "Paste as plain text"
    var pastePlainCaption: String = "Pastes what you copied without colors, fonts or formatting. The original stays on the clipboard."

    // MARK: Settings — switcher
    var switcherSection: String = "App switcher"
    var switcherEnable: String = "Use the \(AppInfo.name) switcher"
    var switcherEnableCaption: String = "Switch between apps and windows, including minimized windows and multiple windows from the same app."
    var switcherNoWindows: String = "No open windows"
    var appQuitFailedFormat: String = "Could not request quitting %@."
    var switcherIconRowMode: String = "Show %@ with large icons"
    var switcherIconRowModeCaption: String = "Shows one icon per app with that app’s window previews above it."
    var switcherSimpleMode: String = "Simple app switcher"
    var switcherSimpleModeCaption: String = "Shows app icons and window titles, without previews or screen capture by the switcher."
    var switcherShortcutHintApps: String = "Apps"
    var switcherShortcutHintWindows: String = "Windows"
    var switcherWindowShortcutCaption: String = "Opens a switcher for the frontmost app’s windows. While the Apps switcher is open, jumps between the selected app’s windows."
    var switcherTakeOverSystemShortcuts: String = "Replace macOS ⌘Tab and ⌘`"
    var switcherTakeOverSystemShortcutsCaption: String = "Disables the matching macOS app and window shortcuts only while \(AppInfo.name)’s switcher is active. All running apps stay reachable."
    var switcherAppearanceDelay: String = "Appearance delay"
    var switcherAppearanceDelayCaption: String = "How long the shortcut must be held before the switcher appears."
    var switcherMergeTabs: String = "Show one entry per app"
    var switcherMergeTabsCaption: String = "Collapses all of an app’s windows into one entry in the switcher, instead of one entry per window."
    var switcherWindowlessApps: String = "Apps with no open window"
    var switcherWindowlessAppsCaption: String = "Chooses which running apps with no window at all show up in the switcher."
    var switcherWindowlessAppsOff: String = "Do not show"
    var switcherWindowlessAppsFinder: String = "Finder only"
    var switcherWindowlessAppsAll: String = "All apps"
    var switcherNoOpenWindow: String = "No open window"
    var switcherOtherDesktop: String = "Other desktop"

    // MARK: Feature — cut & paste in Finder
    var cutPasteName: String = "Cut & paste"
    var cutPasteEnable: String = "Cut & paste files in Finder"
    var cutPasteEnableCaption: String = "Use ⌘X to cut and ⌘V to move files and folders in Finder."
    var cutPasteShowHUD: String = "Show floating panel"
    var cutPasteShowHUDCaption: String = "Display a floating indicator with the cut files while Finder is active."
    var cutPasteHowTitle: String = "How to use"
    var cutPasteStep1: String = "Select items in Finder and press ⌘X to cut them."
    var cutPasteStep2: String = "Open the destination folder and press ⌘V to move them there."
    var cutPasteTextNote: String = "In text fields (like when renaming), ⌘X and ⌘V keep working as usual."
    var cutPasteActiveNow: String = "Ready to cut in Finder"
    var cutPasteAutomationNote: String = "The first time, macOS asks for permission to control Finder."
    var cutReadyTitle: String = "Cut"
    var cutReadyHint: String = "in the destination folder to move"
    var cutCancel: String = "Cancel cut"
    var cutDoneTitle: String = "Moved!"
    var cutMovedSingular: String = "1 item moved"
    var cutMovedPluralFormat: String = "%d items moved"      // + count
    var cutSomeFailed: String = "Some items couldn’t be moved"
    var cutMovingTitle: String = "Moving…"
    var cutMovingCountFormat: String = "%d of %d"      // + position, total

    // MARK: Feature — quit on last window close
    var autoQuitName: String = "Quit on close"
    var autoQuitEnable: String = "Quit an app when its last window closes"
    var autoQuitEnableCaption: String = "Closing an app’s last window also quits it."
    var autoQuitActiveNow: String = "Active now"
    var autoQuitStep1: String = "Close an app’s last window (⌘W or the red button)."
    var autoQuitStep2: String = "The app quits on its own. “Save changes?” dialogs still appear."
    var autoQuitPredictableNote: String = "Apps that normally run without a window are never quit."
    var autoQuitExceptionsTitle: String = "Exceptions"
    var autoQuitExceptionsCaption: String = "Apps on this list stay open even with no windows."
    var autoQuitExceptionsEmpty: String = "No exceptions"
    var autoQuitAddApp: String = "Add app…"

    // MARK: Feature — complete app uninstaller
    var uninstallerName: String = "Uninstaller"
    var uninstallerEnableCaption: String = "Removes an app together with the caches, preferences, logs and leftovers it leaves behind."
    var uninstallerMenuItem: String = "Uninstall an app…"
    var uninstallerDropTitle: String = "Drag an app here"
    var uninstallerDropSubtitle: String = "or choose one to scan"
    var uninstallerChoose: String = "Choose app…"
    var uninstallerPickerTitle: String = "Choose app"
    var uninstallerPickerSearch: String = "Search apps"
    var uninstallerPickerEmpty: String = "No apps found"
    var uninstallerEmptyNote: String = "Nothing is removed without your confirmation."
    var uninstallerFDANote: String = "Grant Full Disk Access for a more thorough scan."
    var uninstallerFDAGrant: String = "Grant access…"
    var uninstallerFDAHint: String = "Turn \(AppInfo.name) on in the list. If it isn’t there, click + and pick \(AppInfo.name) from Applications. Access only applies after you reopen the app."
    var uninstallerFDARelaunch: String = "Relaunch now"
    var uninstallerScanning: String = "Scanning files…"
    var uninstallerRemoving: String = "Moving to the Trash…"
    var uninstallerFoundTitle: String = "found"
    var uninstallerSelectedFormat: String = "%d of %d selected"   // + selected, total
    var uninstallerRemove: String = "Move to Trash"
    var uninstallerCancel: String = "Cancel"
    var uninstallerDoneTitle: String = "Done!"
    var uninstallerFreedFormat: String = "Data removed: %@"      // + size string
    var uninstallerSomeFailed: String = "Some items couldn’t be moved to the Trash."
    var uninstallerConfirmationExpired: String = "This confirmation is no longer valid. Review the current items and confirm again."
    var uninstallerFailedNeedsFDA: String = "Sandboxed app data can only be moved with Full Disk Access. The administrator password does not stand in for it."
    var uninstallerFailedMoreFormat: String = "and %d more"
    var uninstallerAnother: String = "Uninstall another"
    var uninstallerCatApp: String = "Application"
    var uninstallerCatSupport: String = "Support"
    var uninstallerCatCaches: String = "Caches"
    var uninstallerCatPreferences: String = "Preferences"
    var uninstallerCatContainers: String = "Containers"
    var uninstallerCatLogs: String = "Logs"
    var uninstallerCatState: String = "Saved state"
    var uninstallerCatOther: String = "Other"
    var uninstallerCommandBarBrowseTitle: String = "Uninstall Application"
    var uninstallerCommandBarToggle: String = "Show in Command Bar"
    var uninstallerCommandBarCaption: String = "Choose and uninstall apps in the Command Bar."
    var uninstallerCommandBarFinderTitle: String = "Uninstall app selected in Finder"
    var uninstallerSelectionUnavailable: String = "Select an app that can be removed in Finder, or choose another from the list."

    // MARK: Feature — URL cleaner
    var urlCleanerName: String = "Clean URL"
    var urlCleanerEnable: String = "Clean URLs automatically on copy"
    var urlCleanerEnableCaption: String = "Removes tracking parameters from a link the moment it reaches the clipboard."
    var urlCleanerActiveNow: String = "Active now"
    var urlCleanerManualTitle: String = "Clean now"
    var urlCleanerInputPlaceholder: String = "Paste a URL"
    var urlCleanerOutputPlaceholder: String = "The clean URL appears here"
    var urlCleanerCleanButton: String = "Clean"
    var urlCleanerPasteButton: String = "Paste"
    var urlCleanerCopyButton: String = "Copy"
    var urlCleanerClearButton: String = "Clear field"
    var urlCleanerNoURL: String = "Paste a valid URL."
    var urlCleanerNoChange: String = "Nothing to clean."
    var urlCleanerCleaned: String = "URL cleaned."
    var urlCleanerCopied: String = "Copied."
    var urlCleanerLocalNote: String = "Local. No network."

    // MARK: Feature — Homebrew manager
    var homebrewName: String = "Homebrew"
    var homebrewMissingTitle: String = "Homebrew not found"
    var homebrewMissingBody: String = "Homebrew is not installed. Once it is, the packages it manages show up here."
    var homebrewRequested: String = "Installed by you"
    var homebrewSharedWithFormat: String = "Shared with %@"      // + one or more package names
    var homebrewOrphans: String = "Left behind"
    var homebrewOrphansNote: String = "Whatever pulled these in is gone, so removing them breaks nothing."
    var homebrewMasApps: String = "App Store"
    var homebrewCopyName: String = "Copy name"
    var homebrewTrustTitle: String = "Tap not trusted yet"
    var homebrewTrustCaption: String = "Homebrew now asks for your confirmation before using third party taps. Trust %@ to continue."
    var homebrewTrustButton: String = "Trust and continue"
    var homebrewNoPackages: String = "No packages found"
    var homebrewUninstall: String = "Uninstall"
    var homebrewUpgrade: String = "Update"
    var homebrewPinnedVersion: String = "Version pinned"
    var homebrewAllPackages: String = "packages"
    var homebrewOpenTerminal: String = "Open Terminal"
    var homebrewCancelOperation: String = "Cancel"
    var homebrewClearLog: String = "Clear log"
    var homebrewHomepage: String = "Open website"
    var homebrewUpdateAvailableBadge: String = "Update available"
    var homebrewConfirmUninstallTitle: String = "Uninstall with Homebrew?"
    var homebrewConfirmUninstallBodyFormat: String = "Homebrew will uninstall %@. Configuration files may remain on the system."
    var homebrewConfirmUpgradeTitle: String = "Update with Homebrew?"
    var homebrewConfirmUpgradeBodyFormat: String = "Homebrew will download and apply the latest version of %@. Dependencies may also be updated."
    var homebrewTerminalFallback: String = "This operation needs Terminal to ask for the administrator password. \(AppInfo.name) does not capture passwords."
    var homebrewLoading: String = "Loading…"
    var homebrewOperationUninstallFormat: String = "Uninstalling %@"
    var homebrewOperationUpgradeFormat: String = "Updating %@"
    var homebrewOperationUpdateHomebrew: String = "Updating Homebrew"
    var homebrewOperationUninstalledFormat: String = "%@ uninstalled."
    var homebrewOperationUpgradedFormat: String = "%@ updated."
    var homebrewOperationUpdatedHomebrew: String = "Homebrew updated."
    var homebrewOperationFailedFormat: String = "Could not finish %@."
    var homebrewOperationCancelled: String = "Operation cancelled."
    var homebrewOperationPreparing: String = "Preparing…"
    var homebrewOperationDownloading: String = "Downloading files…"
    var homebrewOperationUninstalling: String = "Removing files…"
    var homebrewOperationUpgrading: String = "Updating files…"
    var homebrewOperationFinalizing: String = "Finishing…"
    var homebrewOperationRefreshing: String = "Refreshing list…"
    var homebrewOperationTerminal: String = "Continue in Terminal."
    var homebrewOperationElapsedFormat: String = "%@ elapsed"
    var homebrewOperationShowDetails: String = "Show details"
    var homebrewOperationHideDetails: String = "Hide details"
    var homebrewOperationTechnicalLog: String = "Technical details"
    var homebrewOperationProgressUnknown: String = "Homebrew has not reported a percentage yet."

    // MARK: Feature — local media tools
    var mediaName: String = "Media"
    var mediaEnableCaption: String = "Compress videos, convert and process images, make GIFs and extract text locally."
    var mediaLocalNote: String = "Local. No network."
    var mediaToolVideo: String = "Video"
    var mediaToolGIF: String = "GIF"
    var mediaToolImage: String = "Image"
    var mediaToolText: String = "Text"
    var mediaSelectFile: String = "Choose file"
    var mediaDropHint: String = "Drop a file here or click to choose one."
    var mediaOutput: String = "Output"
    var mediaOutputAutomatic: String = "Automatic"
    var mediaChooseOutput: String = "Destination"
    var mediaStartVideo: String = "Compress video"
    var mediaStartGIF: String = "Make GIF"
    var mediaStartImage: String = "Process image"
    var mediaStartConvertPDF: String = "Convert to PDF"
    var mediaStartText: String = "Extract text"
    var mediaCancel: String = "Cancel"
    var mediaStartTime: String = "Start"
    var mediaEndTime: String = "End"
    var mediaQuality: String = "Compression"
    var mediaCompressionLow: String = "Low"
    var mediaCompressionMedium: String = "Medium"
    var mediaCompressionHigh: String = "High"
    var mediaMaxSize: String = "Size"
    var mediaSizingResolution: String = "Resolution"
    var mediaSizingFileSize: String = "File size"
    var mediaTargetSize: String = "Target size"
    var mediaTargetSizeHint: String = "Resolution adapts to stay under the limit."
    var mediaErrorTargetTooSmall: String = "Target size too small for this clip. Trim it or raise the limit."
    var mediaMegabytesSuffix: String = " MB"
    var mediaWidth: String = "Width"
    var mediaFPS: String = "FPS"
    var mediaFormat: String = "Format"
    var mediaStripMetadata: String = "Remove metadata"
    var mediaLoopGIF: String = "Loop GIF"
    var mediaOCRMode: String = "OCR"
    var mediaOCRAccurate: String = "Accurate"
    var mediaOCRFast: String = "Fast"
    var mediaRunning: String = "Processing"
    var mediaCompleted: String = "Done"
    var mediaCancelled: String = "Cancelled."
    var mediaOpenInFinder: String = "Show"
    var mediaCopyText: String = "Copy text"
    var mediaRunAgain: String = "Run again"
    var mediaEmptyText: String = "No text found."
    var mediaResultSavedFormat: String = "Saved as %@"
    var mediaResultSizeFormat: String = "%@ to %@"
    var mediaResultGrewCaption: String = "The converted file came out larger than the original."
    var mediaErrorNoFile: String = "Choose a file first."
    var mediaErrorNoVideo: String = "This file has no video track."
    var mediaErrorSameOutput: String = "Choose a destination different from the original file."
    var mediaErrorUnsupported: String = "Format not supported by macOS."

    // MARK: Feature — temporary shelf
    var shelfName: String = "Shelf"
    var shelfEnable: String = "Temporary area for dragging files"
    var shelfEnableCaption: String = "A floating spot to gather files, images and text, then drag them anywhere later."
    var shelfHowTitle: String = "How to use"
    var shelfStep1: String = "Open it with the shortcut, or by shaking the mouse during a drag."
    var shelfStep2: String = "Drop files, images, links or text onto it to hold them."
    var shelfStep3: String = "Drag each item back out to any app when you need it."
    var shelfShakeToggle: String = "Open by shaking the mouse while dragging"
    var shelfShakeCaption: String = "Shake the pointer quickly while holding an item to summon it near the cursor."
    var shelfDropZoneToggle: String = "Keep dragged files in the menu bar"
    var shelfDropZoneCaption: String = "While you drag a file, the shelf appears below the menu bar icon. Whatever you drop is kept right there, in a button you shrink and open with a click that goes away once the shelf is empty."
    var shelfCollapse: String = "Collapse"
    var shelfBehaviorTitle: String = "After use"
    var shelfCloseAfterDrop: String = "Close after dropping into another app"
    var shelfCloseAfterDropCaption: String = "Closes the shelf when the destination accepts the items. The pin in the panel keeps it open."
    var shelfRemoveAfterDrop: String = "Remove items after dropping"
    var shelfRemoveAfterDropCaption: String = "Items accepted by another app leave the shelf. Turn this off to keep a copy there."
    var shelfExclusionsTitle: String = "Automatic exceptions"
    var shelfExclusionsEmpty: String = "No apps added."
    var shelfExclusionsCaption: String = "Shake and the menu bar drop zone stay off for drags started in these apps. The shortcut and Open now still work."
    var shelfPin: String = "Keep open"
    var shelfUnpin: String = "Allow closing after use"
    var shelfHotkeyLabel: String = "Shortcut"
    var shelfOpenNow: String = "Open now"
    var shelfNoPermission: String = "Requires no permissions."
    var shelfMenuItem: String = "Open shelf"
    var shelfTitle: String = "Shelf"
    var shelfEmpty: String = "Drag items here"
    var shelfClearAll: String = "Clear all"
    var shelfRemoveSelected: String = "Remove selected"
    var shelfSelectedFormat: String = "%d selected"      // + count
    var shelfHint: String = "Click to select. Drag out to use or right-click for more actions."
    var shelfItemImage: String = "Image"
    // Three forms, not two: Russian agrees a noun with the number in front of
    // it as one, as two through four, and as five or more. Every other
    // language here needs only the first and the last, and repeats the last
    // in the middle slot. A pile always holds two or more, so the items count
    // has no singular of its own.
    var shelfTooltipItemsFormat: String = "%d items"      // + count, five or more
    var shelfTooltipItemsFew: String = "%d items"         // + count, two through four
    var shelfTooltipImageSingular: String = "%d image"    // + count == 1
    var shelfTooltipImageFew: String = "%d images"         // + count, two through four
    var shelfTooltipImagePlural: String = "%d images"      // + count
    var shelfTooltipFileSingular: String = "%d file"     // + count == 1
    var shelfTooltipFileFew: String = "%d files"          // + count, two through four
    var shelfTooltipFilePlural: String = "%d files"       // + count
    var shelfTooltipNoteSingular: String = "%d note"     // + count == 1
    var shelfTooltipNoteFew: String = "%d notes"          // + count, two through four
    var shelfTooltipNotePlural: String = "%d notes"       // + count
    var shelfTooltipLinkSingular: String = "%d link"     // + count == 1
    var shelfTooltipLinkFew: String = "%d links"          // + count, two through four
    var shelfTooltipLinkPlural: String = "%d links"       // + count
    var shelfActionOpen: String = "Open"
    var shelfActionOpenWith: String = "Open With"
    var shelfActionShare: String = "Share"

    // MARK: Panel — per-app breakdown
    var breakdownMeasuring: String = "Measuring…"

    // MARK: Panel — volume mixer
    var preciseVolumeRollerEnable: String = "Use finer volume steps"
    var preciseVolumeRollerCaption: String = "Turns volume wheels and keys into smaller system volume steps."
    var preciseVolumeRollerTapFailed: String = "Could not listen for volume keys."

    // MARK: Settings — updates
    var updatesSection: String = "Updates"
    var autoCheckToggle: String = "Check for updates automatically"
    var betaBadgeLabel: String = "Beta"
    var checkNowButton: String = "Check now"
    var updateChecking: String = "Checking…"
    var updateUpToDate: String = "You’re on the latest version."
    var updateAvailablePrefix: String = "Update available:"  // + version
    var updateInstallButton: String = "Download and install"
    var updateDownloading: String = "Downloading update…"
    var updateInstalling: String = "Installing and restarting…"
    var updateFailedPrefix: String = "Couldn’t check:"
    var updateLastChecked: String = "Last checked:"
    var updateNotifyTitle: String = "\(AppInfo.name) update"
    var updateInstallFailedBody: String = "The update was downloaded but could not be applied. Download the latest version from the GitHub releases page and drag the app over the current one."
    var updateNeedsApplicationsTitle: String = "Move \(AppInfo.name) to Applications"
    var updateNeedsApplicationsBody: String = "The app is running from a place that cannot be updated, such as the disk image or a temporary system location. Drag \(AppInfo.name) to the Applications folder, open it from there and try again."
    var menuCheckUpdates: String = "Check for updates…"

    // MARK: Permissions (shared by Settings & onboarding)
    var permissionRequired: String = "Permission required"
    var permissionAccessibility: String = "Accessibility"
    var permissionScreenRecording: String = "Screen Recording"
    var permissionGranted: String = "Granted"
    var permissionMissing: String = "Not granted"
    var permissionOpenSettings: String = "Open System Settings…"
    var permissionRequest: String = "Grant access"
    var permissionRestartNote: String = "macOS may ask to reopen the app after granting."

    // MARK: Secure input
    var secureInputTitle: String = "Secure input is on"
    var secureInputHeldFormat: String = "%@ is holding it, so \(AppInfo.name) cannot type for you. Dismiss its password field, or quit it, to release it."
    var secureInputUnattributed: String = "No running app claims it. Log out and back in to clear it."
    var secureInputUnidentified: String = "The app holding it could not be identified, so \(AppInfo.name) cannot type for you."
    var secureInputRevealFormat: String = "Show %@"

    // MARK: About
    var aboutDescription: String = "A utility hub for your Mac.\nEnergy, system monitor, scrolling and a window switcher, right in the menu bar."
    var versionPrefix: String = "Version"
    var reviewIntro: String = "Review introduction"
    var reviewHighlights: String = "Review highlights"
    var viewOnGitHub: String = "View on GitHub"

    // MARK: Onboarding
    var obContinue: String = "Continue"
    var obBack: String = "Back"
    var obStart: String = "Open \(AppInfo.name)"
    var obStepWelcomeTitle: String = "Welcome to \(AppInfo.name)"
    var obStepWelcomeBody: String = "A discreet menu bar utility that makes everyday macOS more practical."
    var obWelcomeBullet1Title: String = "Energy under control"
    var obWelcomeBullet1Body: String = "Keep the Mac awake for as long as you want, even with the lid closed."
    var obWelcomeBullet2Title: String = "A clear view of the system"
    var obWelcomeBullet2Body: String = "CPU, GPU and battery temperatures, hardware usage and memory pressure in real time."
    var obWelcomeBullet3Title: String = "Mouse and windows, your way"
    var obWelcomeBullet3Body: String = "Reversed mouse scrolling and a window switcher with thumbnails."
    var obLanguageLabel: String = "Language"
    var obStepDoneTitle: String = "All set!"
    var obStepDoneBody: String = "\(AppInfo.name) is already looking after your Mac."
    var obDoneHint: String = "Look for the kururu icon in the menu bar, at the top right of the screen."
    var obWhatsNewTitle: String = "What’s new in this version"
    var obWhatsNewFallback: String = "This update includes the latest fixes and improvements."
    var obPurposeTitle: String = "What brought you here?"
    var obPurposeBody: String = "Select individual features to enable. Your existing options are kept."
    var obPurposeSkip: String = "You can add or remove features later in Settings."

    // MARK: Settings — monitor / menu bar metrics
    var tabMonitor: String = "Monitor"
    var tabMenuBarIcon: String = "Menu bar icon"
    var tabMenuBarPanel: String = "Menu bar panel"
    var monitorMenuBarSection: String = "In the menu bar"
    var monitorCombineTemperatures: String = "Combine usage and temperature"
    var monitorCombineTemperaturesCaption: String = "When usage and temperature for the same item are enabled, show them in one block."
    var monitorSeparateMenuBarMetrics: String = "Separate metrics into their own items"
    var monitorSeparateMenuBarMetricsCaption: String = "Separates active blocks in the menu bar and keeps usage and temperature together when combine is on."
    var monitorNetworkUploadFirst: String = "Upload above download"
    var monitorShowCPU: String = "CPU"
    var monitorShowMemory: String = "Memory"
    var monitorShowNetwork: String = "Network"
    var monitorShowPowerLabel: String = "Power"
    var monitorIntervalLabel: String = "Update every"
    var monitorInterval1: String = "1 second"
    var monitorInterval2: String = "2 seconds"
    var monitorInterval5: String = "5 seconds"
    var monitorPanelSection: String = "In the panel"
    var betaBadge: String = "BETA"
    var betaFeatureWarning: String = "Beta. You may run into some bugs."

    // MARK: Panel — network
    var networkSection: String = "Network"
    var networkIPAddresses: String = "IP addresses"
    var networkLocalIP: String = "Local IPv4"
    var networkDownload: String = "Download"
    var networkUpload: String = "Upload"
    var networkThisSession: String = "This session"
    var networkMeasuring: String = "Measuring…"
    var networkApps: String = "Apps using network"
    var networkAppsIdle: String = "No apps using network now"

    // MARK: Panel — disk
    var diskSection: String = "Disks"
    var diskUsed: String = "used"
    var diskAvailable: String = "available"
    var diskPurgeable: String = "purgeable"
    var diskInternal: String = "Internal"
    var diskExternal: String = "External"
    var diskSelect: String = "Select disk"
    var diskRead: String = "Read"
    var diskWrite: String = "Write"
    var diskSMARTStatus: String = "Status"
    var diskSMARTUnavailable: String = "SMART unavailable for this disk"
    var diskTotalRead: String = "Total read"
    var diskTotalWritten: String = "Total written"
    var diskTemperature: String = "Temperature"
    var diskHealth: String = "Health"
    var diskPowerCycles: String = "Power cycles"
    var diskPowerOnHours: String = "Power on hours"
    var diskEject: String = "Eject"
    var diskEjectAll: String = "Eject all"
    var diskEjecting: String = "Ejecting…"
    var diskReadyToRemove: String = "Ready to remove"
    var diskEjectFailed: String = "Could not eject"
    var diskProtectionCaption: String = "Eject before unplugging."
    var diskNoExternal: String = "No external disk ready to eject."
    var diskOpenInFinder: String = "Open"
    var diskStorageSettings: String = "Storage"
    var diskNoDisks: String = "No mounted disks found."

    // MARK: Panel — power
    var powerSection: String = "Power"
    var powerSystem: String = "System"
    var powerAdapter: String = "Adapter"
    var powerBattery: String = "Battery"
    var powerCharging: String = "Charging"
    var powerOnBattery: String = "On battery"
    var powerPluggedIn: String = "Plugged in"
    var powerUnavailable: String = "Power metrics unavailable on this Mac"
    var powerAdapterMaxFormat: String = "%@ max"   // + rated watts, e.g. "30 W max"
    var monitorShowGPU: String = "GPU"
    var monitorShowCPUTemperature: String = "CPU temperature"
    var monitorShowGPUTemperature: String = "GPU temperature"
    var monitorShowBatteryTemperature: String = "Battery temperature"
    var monitorShowPeripheralBattery: String = "Peripheral battery"
    var peripheralBatteryNoDevices: String = "No devices found"

    // MARK: Update notification + onboarding menu bar setup
    var updateBannerTitle: String = "Update available"
    var updateBannerAction: String = "Update"
    var menuBarSpacingLabel: String = "Menu bar spacing"
    var menuBarSpacingStandard: String = "Standard"
    var menuBarSpacingCompact: String = "Compact"
    var menuBarHideIconToggle: String = "Hide the app icon while metrics are shown"
    var menuBarHideIconCaption: String = "The icon returns by itself when metrics leave the bar and when there is something to signal (an update ready or the microphone muted)."
    var menuBarIconSection: String = "App icon"
    var monitorMemoryPressureDot: String = "Pressure dot"
    // MARK: System uptime, battery health, speed test
    var systemUptime: String = "Up for"
    var batteryCharge: String = "Charge"
    var powerHealth: String = "Battery health"
    var powerCycles: String = "Cycles"
    var speedTestRun: String = "Speed test"
    var speedTestAgain: String = "Test again"
    var speedTestLatency: String = "Latency"
    var speedTestTesting: String = "Testing…"
    var speedTestFailed: String = "Test failed"

    // MARK: Per-item panel config (Settings + onboarding)
    var monitorShowInPanel: String = "Show in panel"
    var disclosureExpanded: String = "Expanded"
    var disclosureCollapsed: String = "Collapsed"
    var panelHideItem: String = "Hide from panel"
    var panelShowItem: String = "Show in panel"
    var panelHiddenItem: String = "Hidden"
    var monitorItemUptime: String = "Uptime"
    var monitorItemNetSpeed: String = "Live speed"
    var monitorItemNetTotals: String = "Session totals"
    var monitorItemNetTest: String = "Speed test"
    var monitorItemDiskUsage: String = "Disk usage"
    var monitorItemDiskActivity: String = "Live activity"
    var monitorItemDiskSMART: String = "SMART"
    var monitorItemDiskProtection: String = "External protection"
    var monitorItemDiskTools: String = "Tools"
    var monitorOrderSection: String = "Section order"
    var monitorOrderHint: String = "Drag to reorder the panel sections and use the eye to show or hide each one."

    // MARK: Cleaning mode
    var cleaningMenuItem: String = "Cleaning Mode"
    var utilitiesSection: String = "Utilities"
    var quickControlsSection: String = "Controls"
    var panelCategoryWindows: String = "Windows"
    var panelCategoryInput: String = "Mouse and keyboard"
    var panelCategoryFiles: String = "Files"
    var windowMaximizeName: String = "Green button maximizes windows"
    var windowMaximizeCaption: String = "Click the green button in the upper-left corner to enlarge the window on the current desktop without entering full screen."
    var keyDebounceName: String = "Debounce"
    var keyDebounceEnable: String = "Filter duplicate keys"
    var keyDebounceCaption: String = "Filters very fast duplicate key presses."
    var keyDebounceActiveNow: String = "Filter active"
    var keyDebounceGlobalWindow: String = "Global window"
    var keyDebouncePerKeySection: String = "Specific keys"
    var keyDebouncePerKeyCaption: String = "Per-key values override the global window. Use 0 ms to stop filtering a key."
    var keyDebounceKeyLabel: String = "Key"
    var keyDebounceAddKey: String = "Add key"
    var keyDebounceNoOverrides: String = "No specific keys configured."
    var keyDebounceRemoveKey: String = "Remove key"
    var cleaningPanelCaption: String = "Locks the keyboard so you can clean safely."
    var cleaningOverlayTitle: String = "Keyboard locked for cleaning"
    var cleaningOverlaySubtitle: String = "Press Escape 5 times to unlock"
    var cleaningOverlayUnlock: String = "Unlock"
    var cleaningOverlayMouseHint: String = "Your mouse and trackpad still work"
    var cleaningKeepScreenVisibleToggle: String = "Keep screen visible"
    var cleaningKeepScreenVisibleCaption: String = "Shows a discreet indicator in the corner of the screen instead of blacking out content."
    var cleaningStartNow: String = "Lock keyboard now"
    var cleaningNeedsAxTitle: String = "Accessibility needed"
    var cleaningNeedsAxBody: String = "To lock the keyboard safely, \(AppInfo.name) needs Accessibility permission. Grant it in System Settings and try again."

    // MARK: Support / donate
    var shortcutsPageCaption: String = "Edit every global shortcut from the features enabled on this Mac. Inactive shortcuts stay saved but do not run."
    var shortcutsPageTitle: String = "Keyboard shortcuts"
    var settingsSearchPlaceholder: String = "Search settings"
    var supportIntroLaterButton: String = "Not now"
    var supportIntroDoneButton: String = "Done"
    var updateShowcaseTitle: String = "What’s new in 3.1.4"
    var updateShowcaseMessage: String = "Take a quick look at the main improvements in this update."
    var updateShowcaseUnavailable: String = "The video could not load right now. You can still continue."
    var updateShowcaseRestart: String = "Restart"
    var showMenuBarIcon: String = "Show menu bar icon"
    var showMenuBarIconCaption: String = "If \(AppInfo.name)’s icon disappears (macOS can hide menu bar icons when the bar runs out of room, common on Macs with a notch), reopen \(AppInfo.name) from Applications or Spotlight: that rebuilds the icon and, if it’s still hidden, opens this window."
    var menuBarIconStillHiddenTitle: String = "The icon is still hidden"
    var menuBarIconStillHiddenBody: String = "The icon was rebuilt, but macOS did not give it a visible spot. The menu bar is probably out of room: remove some menu bar icons (or close apps with long menus) and try again."
    var menuBarIconManagerHintFormat: String = "%@ is open and may be keeping the icon in its hidden section. Look for \(AppInfo.name) there, or set %@ to always show \(AppInfo.name)."  // + manager name (twice)
    var menuBarIconDisallowedBody: String = "macOS is keeping \(AppInfo.name) out of the menu bar. Open System Settings > Menu Bar, find \(AppInfo.name) in the app list and turn on “Allow in the Menu Bar”. The icon appears as soon as the switch is on."

    // MARK: Configurable shortcuts
    var shortcutRecording: String = "Press the new shortcut"
    var shortcutReset: String = "Reset"
    var shortcutNone: String = "None"
    var shortcutClear: String = "Remove shortcut"
    var shortcutInvalid: String = "Use at least Control, Option or Command with a key."
    var shortcutPressKeys: String = "Press keys"
    var shortcutEscapeHint: String = "Escape cancels."
    var shortcutDeleteHint: String = "Delete clears."
    var shortcutNotCaptured: String = "Nothing was captured. macOS or another app already uses that combination. Try another one."
    var shortcutConflictFormat: String = "This shortcut is already used by %@."
    var shortcutTakeOverOffer: String = "macOS uses %@ for one of its own shortcuts."
    var shortcutTakeOverAction: String = "Take over while \(AppInfo.name) runs"
    var shortcutTakeOverCaption: String = "macOS gets the key back whenever \(AppInfo.name) is not running or this feature is off."
    var shortcutTakeOverDismiss: String = "Don’t take over"
    var shortcutUnavailable: String = "macOS rejected this shortcut. Choose another one."
    var shelfShortcutToggle: String = "Shelf shortcut"
    var switcherUsageHintFormat: String = "Hold %@ to navigate; release to activate the window. Shift or ← goes back; W closes the window; Q quits the app; Esc cancels."

    // MARK: Cleaner
    var cleanerName: String = "Cleaner"
    var cleanerIntroTitle: String = "Clean up your Mac"
    var cleanerIntroCaption: String = "Scans for leftovers from uninstalled apps, caches, logs and the Trash. You review everything first and removed items go to the Trash."
    var cleanerScan: String = "Scan"
    var cleanerScanning: String = "Scanning…"
    var cleanerCleaning: String = "Cleaning…"
    var cleanerCatLeftovers: String = "Leftovers from uninstalled apps"
    var cleanerCatLoginItems: String = "Orphaned startup items"
    var cleanerCatCaches: String = "Caches"
    var cleanerCatLogs: String = "Logs"
    var cleanerCatDeveloper: String = "Developer junk"
    var cleanerCatTrash: String = "Trash"
    var cleanerLeftoversNote: String = "Found by analysis and left unchecked. Check the path before ticking."
    var cleanerLoginItemsNote: String = "The entry under Login Items disappears after restarting the Mac."
    var cleanerTrashNote: String = "Emptying the Trash is permanent."
    var cleanerCatDeviceBackups: String = "iPhone backups"
    var cleanerDeviceBackupsCaption: String = "Old iPhone and iPad backups take a big slice of the storage macOS calls Other. Remove only the ones you no longer need; a new backup is made when you plug the device in again."
    var cleanerNothingFound: String = "Nothing to clean. Your Mac is tidy."
    var cleanerIncompleteTitle: String = "Cleanup incomplete"
    var cleanerFailedNote: String = "These items could not be cleaned. Scan again to review what remains."
    var cleanerDoneNote: String = "Items went to the Trash and can be recovered from there."
    var cleanerAgain: String = "Scan again"
    var cleanerRevealInFinder: String = "Reveal in Finder"
    var cleanerPanelCaption: String = "App leftovers, caches and logs"
    var cleanerSafeSection: String = "Safe cleanup"
    var cleanerOptionalSection: String = "Optional, review first"
    var cleanerCatOtherCaches: String = "Other caches"
    var cleanerCachesCaption: String = "Temporary files apps rebuild on their own."
    var cleanerLogsCaption: String = "Old diagnostic logs."
    var cleanerDeveloperCaption: String = "Xcode build and simulator leftovers."
    var cleanerLoginItemsCaption: String = "Startup entries left by apps that no longer exist."
    var cleanerLeftoversCaption: String = "Files left behind by apps you uninstalled."
    var cleanerOtherCachesCaption: String = "Safe to remove, nothing breaks. Apps may open slower once and downloaded content, like offline music, downloads again."
    var cleanerCleanSizeFormat: String = "Clean %@"      // + size string
    var cleanerScheduleTitle: String = "Automatic cleanup"
    var cleanerScheduleOff: String = "Off"
    var cleanerScheduleDaily: String = "Daily"
    var cleanerScheduleWeekly: String = "Weekly"
    var cleanerScheduleCaption: String = "Cleans only the safe part on its own at the chosen time and sends everything to the Trash."
    var cleanerAutoNotificationFormat: String = "%@ freed and sent to the Trash."  // + size string
    var cleanerScheduleNextFormat: String = "Next cleanup %@."   // + relative date and time
    var cleanerScheduleNotifyToggle: String = "Notify when done"
    var cleanerNotifDenied: String = "\(AppInfo.name) notifications are turned off in the system."
    var cleanerNotifOpenSettings: String = "Open Notification Settings…"
    var launchAtLoginNeedsApplications: String = "The app is running from a place that cannot open at login. Drag \(AppInfo.name) to the Applications folder, open it from there and turn this on again."
    var launchAtLoginNeedsApproval: String = "The login item is registered but still switched off in System Settings. Open System Settings › General › Login Items & Extensions and turn \(AppInfo.name) on under Open at Login."
    var ocrRemoveLineBreaksToggle: String = "Remove line breaks"
    var ocrRemoveLineBreaksCaption: String = "Removes line breaks so copied text pastes as one paragraph."
    var ocrQRToggle: String = "Read QR codes"
    var ocrQRCaption: String = "If the area has a QR code, its content is shown to copy or open."
    var ocrQRCopied: String = "QR code copied"
    var qrResultTitle: String = "QR code"
    var qrResultCopy: String = "Copy"
    var qrResultOpen: String = "Open link"
    var highlightsTitle: String = "New in this update"
    var highlightsTitleQuitProtection: String = "Quit and close protection"
    var highlightsTitleRecorderBlur: String = "Recording privacy blur"
    var highlightsCaptionQuitProtection: String = "Avoid quitting apps or closing windows by accident with a hold, a double press or an extra modifier, customizable per app."
    var highlightsCaptionRecorderBlur: String = "Hide private details, passwords and sensitive areas anywhere across your recorded video before sharing or exporting."
    var highlightsConfigure: String = "Set up"
    var highlightsSeeAll: String = "See all changes"
    var switcherCurrentSpaceOnly: String = "Show only the current desktop"
    var switcherCurrentSpaceOnlyCaption: String = "Lists only windows from the desktop you are on. Picking a window never moves you to another desktop."
    var shelfFileMissing: String = "The file no longer exists"
    var monitorOpenActivityMonitor: String = "Open Activity Monitor"
    var monitorMemoryMetricLabel: String = "Measure memory as"
    var memoryMetricUsed: String = "Memory Used"
    var memoryMetricApp: String = "App Memory"
    var keepAwakeRightClickToggle: String = "Right-click the menu bar icon to toggle Keep Awake"
    var keepAwakeRightClickToggleCaption: String = "Replaces the right-click context menu."
    var urlCleanerRulesTitle: String = "Cleaning rules"
    var urlCleanerRulesCaption: String = "A site attaches these parameters to its own share links to track where the link came from. Switched on, a name is removed when a link is cleaned; switched off, it stays. Names you add can be deleted."
    var urlCleanerRulesCoverageCaption: String = "The list covers a site’s different share paths (the web page, the app, a live room), which is why it is long; a real link usually carries only two to four of them."
    var urlCleanerRulesAllSites: String = "All sites"
    var urlCleanerRulesAddSite: String = "Add a site"
    var urlCleanerRulesParameterPlaceholder: String = "Parameter name"
    var urlCleanerRulesMatchCaption: String = "Write the name to the left of the = , like utm_source. A name that matches takes that one parameter out of the link and leaves the rest as it was."
    var urlCleanerRulesAddButton: String = "Add"
    var urlCleanerRemovedFormat: String = "Removed %@"            // + comma separated names
    var switcherSearchPin: String = "Pin search with S"
    var switcherSearchPinCaption: String = "S starts a search and pins the switcher open, so typing no longer produces special characters when your shortcut uses ⌥, and a search starting with Q or W no longer closes the window or quits the app by mistake."
    var invertVerticalScroll: String = "Invert vertical scrolling"
    var invertHorizontalScroll: String = "Invert horizontal scrolling"
    var scrollHorizontalName: String = "Scroll sideways while holding a key"
    var scrollHorizontalModifierLabel: String = "Modifier key"
    var scrollHorizontalCommandKey: String = "Command"
    var scrollHorizontalCaption: String = "Hold only the selected modifier to scroll the vertical mouse wheel horizontally. Other key combinations are unchanged."
    var switcherShowShortcutHints: String = "Show shortcut hints"
    var switcherShowShortcutHintsCaption: String = "Shows the app and window shortcuts below the icons."
    var uninstallerHomebrewPackageFormat: String = "%@ will also be removed from Homebrew."
    var shelfEdgeToggle: String = "Open near a screen edge"
    var shelfEdgeCaption: String = "Drag a file toward the screen edge to peek the shelf in. Drop it there, or pull back and it retreats."
    var focusFollowsMouseName: String = "Focus follows mouse"
    var focusFollowsMouseCaption: String = "Focuses and raises the window under the pointer after a short pause."
    var focusFollowsMouseDelay: String = "Hover delay"
    var switcherMinimizedPlacementLabel: String = "Minimized windows"
    var switcherMinimizedPlacementNormal: String = "Normal ordering"
    var switcherMinimizedPlacementEnd: String = "Place at end"
    var switcherMinimizedPlacementHidden: String = "Hide"
    var switcherShowFullscreenWindows: String = "Show fullscreen windows"
    var switcherScreenPlacementLabel: String = "Show on"
    var switcherScreenPlacementPointer: String = "Screen with the pointer"
    var switcherScreenPlacementMenuBar: String = "Screen with the menu bar"
    var switcherScreenPlacementActiveWindow: String = "Screen with the active window"
    var switcherScreenPlacementCaption: String = "Which display the switcher opens on when more than one is connected."
    var switcherCurrentDisplayOnly: String = "Show only the current display"
    var switcherCurrentDisplayOnlyCaption: String = "Lists only windows on the display under the pointer. If that display has no windows, the switcher does not open."
    var smoothScrollResponseLabel: String = "Response"
    var mouseAccelerationName: String = "Disable mouse acceleration"
    var mouseAccelerationCaption: String = "Removes pointer acceleration for connected mice. Your previous setting returns when this is turned off or \(AppInfo.name) quits."
    var shelfClearOnClose: String = "Clear when closed"
    var shelfClearOnCloseCaption: String = "Empties the shelf only when you click its close button. Automatic hiding and collapsing keep the items."
}

// MARK: - Português (Brasil)

extension Strings {
    static let ptBR = Strings(
        statusIdleTooltip: "\(AppInfo.name): suspensão normal",
        statusActiveUntil: "\(AppInfo.name): ativo até",
        statusActiveIndefinite: "\(AppInfo.name): ativo indefinidamente",
        menuEnableAwake: "Ativar manter acordado",
        menuDisableAwake: "Desativar manter acordado",
        menuActivateFor: "Ativar por…",
        menuSettings: "Ajustes…",
        menuAbout: "Sobre o \(AppInfo.name)",
        menuQuit: "Sair do \(AppInfo.name)",
        menuHide: "Ocultar o \(AppInfo.name)",
        menuHideOthers: "Ocultar Outros",
        menuShowAll: "Mostrar Tudo",
        menuEdit: "Editar",
        menuUndo: "Desfazer",
        menuRedo: "Refazer",
        actionClear: "Limpar",
        actionRemove: "Remover",
        actionBack: "Voltar",
        actionSearch: "Buscar",
        actionMute: "Silenciar",
        actionUnmute: "Reativar som",
        actionPlay: "Reproduzir",
        actionPause: "Pausar",
        menuCut: "Recortar",
        menuCopy: "Copiar",
        menuPaste: "Colar",
        menuSelectAll: "Selecionar Tudo",
        menuWindow: "Janela",
        menuMinimize: "Minimizar",
        menuZoom: "Zoom",
        menuClose: "Fechar",

        minutes15: "15 minutos",
        minutes30: "30 minutos",
        hour1: "1 hora",
        hours2: "2 horas",
        hours4: "4 horas",
        hours8: "8 horas",
        indefinitely: "Indefinidamente",
        indefinite: "Indefinida",

        panelSettings: "Ajustes",
        panelQuit: "Sair",

        keepAwakeTitle: "Manter acordado",
        keepAwakeEndsIn: "Termina em",
        keepAwakeUntilDisabled: "Ativo até você desativar",
        keepAwakeNormalRules: "O Mac segue as regras normais de energia",
        keepAwakeOptions: "Opções",
        keepAwakeMouseJiggle: "Mover cursor levemente",
        keepAwakeMouseJiggleCaption: "Durante uma sessão, move o cursor um pouco no intervalo escolhido.",
        keepAwakeMouseJiggleInterval: "Intervalo",
        keepAwakeActiveIconLabel: "Ícone ativo",
        keepAwakeActiveIconVorssaint: "\(AppInfo.name)",
        keepAwakeActiveIconCoffee: "Café",
        keepAwakeActiveIconEye: "Olho",
        keepAwakeActiveIconMoon: "Lua",
        keepAwakeActiveIconLight: "Lâmpada",
        keepAwakeIconTintLabel: "Cor do ícone ativo",
        keepAwakeIconTintOrange: "Laranja",
        keepAwakeIconTintGreen: "Verde",
        keepAwakeIconTintBlue: "Azul",
        keepAwakeIconTintPurple: "Roxo",
        keepAwakeIconTintPink: "Rosa",
        keepAwakeIconTintNone: "Sem cor",
        durationLabel: "Duração",
        clamshellTitle: "Continuar com a tampa fechada",
        clamshellOnCaption: "Suspensão totalmente desativada. Atenção à energia",
        clamshellNeedsSession: "Será aplicada sempre que “Manter acordado” estiver ativo",
        clamshellReady: "Pronto. Liga e desliga sem senha",
        clamshellNeedsPassword: "Pedirá a senha de administrador uma vez",

        systemSection: "Sistema",
        temperatures: "Temperaturas",
        cpuLabel: "CPU",
        gpuLabel: "GPU",
        batteryLabel: "Bateria",
        usageSection: "Uso de hardware",
        memorySection: "Memória",
        memoryPressure: "Pressão",
        memorySwapUsed: "Swap em uso",
        memoryCompressed: "Comprimida",
        memoryCachedFiles: "Arquivos em cache",
        pressureNormal: "Normal",
        pressureWarning: "Atenção",
        pressureCritical: "Crítico",
        monitorUnavailable: "Sensores indisponíveis neste Mac",
        energyAppsTitle: "Uso significativo de energia",
        energyAppsIdle: "Sem uso significativo de energia",

        notifySessionEndedTitle: "Sessão encerrada",
        notifySessionEndedBody: "O tempo acabou. O Mac voltará a suspender normalmente.",
        notifyBatteryTitle: "\(AppInfo.name) desativado",
        notifyBatteryBody: "Bateria baixa. A suspensão normal foi restaurada para proteger a carga.",
        adminPromptClamshellOff: "O \(AppInfo.name) precisa da sua senha para reativar a suspensão normal do Mac.",
        adminPromptRecover: "O \(AppInfo.name) foi encerrado com a suspensão do Mac desativada. Digite a senha para restaurar a suspensão normal.",
        adminPromptUpdate: "O \(AppInfo.name) precisa da sua senha para instalar a atualização.",
        adminPromptSudoersInstall: "O \(AppInfo.name) vai criar uma regra restrita (somente pmset disablesleep) para alternar a tampa fechada sem pedir senha. Esta é a única vez que a senha será necessária.",
        adminPromptSudoersRemove: "O \(AppInfo.name) vai remover a regra de tampa fechada sem senha.",

        settingsTitle: "Ajustes do \(AppInfo.name)",
        tabGeneral: "Geral",
        tabMouse: "Mouse",
        tabDock: "Dock",
        tabWindowBehavior: "Comportamento das janelas",
        tabKeyboard: "Teclado",
        tabTrackpad: "Trackpad",
        tabAdvanced: "Avançado",
        tabAbout: "Sobre",
        tabReleaseNotes: "Novidades",
        advancedResetSection: "Permissões",
        advancedResetDescription: "Remove todas as permissões que você concedeu ao \(AppInfo.name) (Acessibilidade, Gravação de Tela, Acesso Total ao Disco e outras), o item de início e a regra de tampa fechada. Útil para começar do zero ou antes de desinstalar. O app continua instalado.",
        advancedClearButton: "Limpar todas as permissões",
        advancedCleared: "Permissões limpas.",
        advancedClearConfirmTitle: "Limpar todas as permissões?",
        advancedClearConfirmBody: "Os recursos que dependem de permissão vão parar de funcionar até você conceder de novo. As suas configurações são mantidas.",
        advancedUninstallSection: "Desinstalar",
        advancedUninstallDescription: "Attempts to remove this app’s permissions, login item and password-free closed-lid rule, and clear its preferences and local app data. After the app quits, it attempts to move itself to the Trash. Separately saved backups and exports are not deleted.",
        advancedUninstallButton: "Desinstalar o \(AppInfo.name) completamente",
        advancedUninstallConfirmTitle: "Desinstalar o \(AppInfo.name)?",
        advancedUninstallConfirmBody: "O \(AppInfo.name) vai limpar as permissões, apagar as preferências e ir para a Lixeira, e então fechar. Esta ação não pode ser desfeita pelo app, mas ele fica na Lixeira até você esvaziá-la.",
        advancedUninstallFailedTitle: "A desinstalação parou",
        advancedUninstallFailedBody: "O \(AppInfo.name) não conseguiu restaurar uma configuração do sistema que ele mudou: repouso, velocidade das ventoinhas ou aceleração do mouse. Nada foi removido. Tente de novo e permita o pedido de senha, se ele aparecer.",

        launchAtLogin: "Iniciar junto com o Mac",
        languageLabel: "Idioma",
        showCountdown: "Mostrar tempo restante ao lado do ícone",
        hotkeyToggle: "Ativar atalho para “Manter acordado”",
        hotkeyCaption: "Funciona em qualquer app, sem permissões extras.",

        sessionSection: "Sessão",
        defaultDurationLabel: "Duração padrão",
        keepAwakeAutoStart: "Manter acordado ao abrir o \(AppInfo.name)",
        keepAwakeAutoStartCaption: "Inicia uma sessão com a duração padrão.",
        batteryProtectionSection: "Proteção de bateria",
        batteryDisableBelow: "Desativar com bateria abaixo de",
        batteryNever: "Nunca",
        batteryProtectionCaption: "Evita que uma sessão esquecida drene a bateria do MacBook.",
        clamshellSection: "Tampa fechada",
        configuring: "Configurando…",
        sudoersFailed: "Não foi possível ativar a tampa fechada. Tente de novo.",
        clamshellExplanation: "“Continuar com a tampa fechada” desativa completamente a suspensão enquanto “Manter acordado” estiver ativo e é revertido automaticamente quando a sessão termina ou o app é encerrado. Prefira usá-lo conectado à energia.",

        scrollSection: "Rolagem",
        invertMouseScroll: "Inverter rolagem do mouse",
        invertMouseScrollCaption: "Inverte a direção da roda do mouse.",
        scrollTrackpadNote: "O trackpad não muda: continua com a rolagem natural do macOS.",
        scrollActiveNow: "Invertendo a rolagem do mouse agora",
        mouseNavigationActiveNow: "Botões laterais ativos agora",
        smoothScrollName: "Rolagem suave",
        smoothScrollCaption: "Transforma cada passo da rodinha do mouse em um deslize curto e macio. O trackpad não muda.",
        smoothScrollStepLabel: "Velocidade da rolagem",
        mouseNavigationEnable: "Usar botões laterais para voltar e avançar",
        mouseNavigationCaption: "Converte os botões Voltar e Avançar do mouse em comandos de navegação no Finder, navegadores e apps compatíveis.",
        middleClickSection: "Botão do meio",
        middleClickEnable: "Clique com três dedos vira botão do meio",
        middleClickEnableCaption: "Pressionar o trackpad com três dedos funciona como o clique da rodinha do mouse: abre links em nova aba, fecha abas e tudo mais que o botão do meio faz.",
        middleClickDragConflict: "O arrastar com três dedos do macOS está ativado e usa esse mesmo gesto. Desative-o nos Ajustes do Sistema em Acessibilidade, Controle do Cursor, Opções do Trackpad, e o clique do meio vai funcionar.",
        middleClickTapPicker: "Toque leve também clica",
        middleClickTapOff: "Desligado",
        middleClickTapThreeFingers: "3 dedos",
        middleClickTapFourFingers: "4 dedos",
        middleClickTapCaption: "Um toque leve com esse número de dedos, sem pressionar, também dispara o clique do meio. Deslizar nunca conta. Se o toque de três dedos do macOS estiver atribuído à Busca, desative-o para os dois não abrirem juntos.",
        quickToolShortcutToggle: "Atalho global",
        ocrName: "Copiar texto da tela",
        ocrCaption: "Selecione uma área da tela e o texto reconhecido é copiado, pronto para colar.",
        ocrCopied: "Texto copiado",
        ocrNoText: "Nenhum texto encontrado",
        colorPickerName: "Conta-gotas de cor",
        colorPickerCaption: "Capture a cor de qualquer pixel da tela e copie no formato que preferir.",
        colorPickerFormatLabel: "Formato copiado",
        colorPickerBareHexToggle: "Copiar sem o prefixo #",
        colorPickerPickNow: "Capturar cor",
        pastePlainName: "Colar como texto puro",
        pastePlainCaption: "Cola o que foi copiado sem cores, fontes ou formatação. O conteúdo original continua no clipboard.",

        switcherSection: "Alternador de apps",
        switcherEnable: "Usar o alternador do \(AppInfo.name)",
        switcherEnableCaption: "Troque de app ou janela, inclusive janelas minimizadas e várias janelas do mesmo app.",
        switcherNoWindows: "Nenhuma janela aberta",
        switcherIconRowMode: "Mostrar %@ com ícones grandes",
        switcherIconRowModeCaption: "Mostra um ícone por app com os previews das janelas do app acima.",
        switcherSimpleMode: "Alternador simples",
        switcherSimpleModeCaption: "Mostra ícones de apps e títulos das janelas, sem previews nem captura da tela pelo alternador.",
        switcherShortcutHintApps: "Apps",
        switcherShortcutHintWindows: "Janelas",
        switcherWindowShortcutCaption: "Abre um seletor das janelas do app em primeiro plano. Com o seletor de apps aberto, pula entre as janelas do app selecionado.",
        switcherTakeOverSystemShortcuts: "Substituir ⌘Tab e ⌘` do macOS",
        switcherTakeOverSystemShortcutsCaption: "Desativa os atalhos correspondentes de apps e janelas do macOS somente enquanto o alternador do \(AppInfo.name) estiver ativo. Todos os apps abertos continuam acessíveis.",
        switcherAppearanceDelay: "Atraso de exibição",
        switcherAppearanceDelayCaption: "Quanto tempo o atalho precisa ficar pressionado antes de o alternador aparecer.",
        switcherMergeTabs: "Mostrar uma entrada por app",
        switcherMergeTabsCaption: "Junta todas as janelas de um app em uma só entrada no alternador, em vez de uma por janela.",
        switcherWindowlessApps: "Apps sem janela aberta",
        switcherWindowlessAppsCaption: "Escolhe quais apps que estão abertos sem nenhuma janela aparecem no alternador.",
        switcherWindowlessAppsOff: "Não mostrar",
        switcherWindowlessAppsFinder: "Só o Finder",
        switcherWindowlessAppsAll: "Todos os apps",
        switcherNoOpenWindow: "Sem janela aberta",
        switcherOtherDesktop: "Outra Mesa",

        cutPasteName: "Recortar e colar",
        cutPasteEnable: "Recortar e colar arquivos no Finder",
        cutPasteEnableCaption: "Use ⌘X para recortar e ⌘V para mover arquivos e pastas no Finder.",
        cutPasteShowHUD: "Mostrar painel flutuante",
        cutPasteShowHUDCaption: "Exibe um indicador com os arquivos recortados enquanto o Finder estiver ativo.",
        cutPasteHowTitle: "Como usar",
        cutPasteStep1: "Selecione itens no Finder e pressione ⌘X para recortá-los.",
        cutPasteStep2: "Abra a pasta de destino e pressione ⌘V para movê-los para lá.",
        cutPasteTextNote: "Em campos de texto (como ao renomear), ⌘X e ⌘V continuam funcionando normalmente.",
        cutPasteActiveNow: "Pronto para recortar no Finder",
        cutPasteAutomationNote: "Na primeira vez, o macOS pede permissão para controlar o Finder.",
        cutReadyTitle: "Recortado",
        cutReadyHint: "na pasta de destino para mover",
        cutCancel: "Cancelar recorte",
        cutDoneTitle: "Movido!",
        cutMovedSingular: "1 item movido",
        cutMovedPluralFormat: "%d itens movidos",
        cutSomeFailed: "Alguns itens não puderam ser movidos",
        cutMovingTitle: "Movendo…",
        cutMovingCountFormat: "%d de %d",

        autoQuitName: "Encerrar ao fechar",
        autoQuitEnable: "Encerrar o app ao fechar a última janela",
        autoQuitEnableCaption: "Fechar a última janela de um app também o encerra.",
        autoQuitActiveNow: "Ativo agora",
        autoQuitStep1: "Feche a última janela de um app (⌘W ou o botão vermelho).",
        autoQuitStep2: "O app é encerrado sozinho. Diálogos de “salvar?” continuam aparecendo.",
        autoQuitPredictableNote: "Apps que normalmente rodam sem janela nunca são encerrados.",
        autoQuitExceptionsTitle: "Exceções",
        autoQuitExceptionsCaption: "Apps nesta lista continuam abertos mesmo sem nenhuma janela.",
        autoQuitExceptionsEmpty: "Nenhuma exceção",
        autoQuitAddApp: "Adicionar app…",

        uninstallerName: "Desinstalador",
        uninstallerEnableCaption: "Remove um app junto com os caches, preferências, logs e resíduos que ele deixa para trás.",
        uninstallerMenuItem: "Desinstalar um app…",
        uninstallerDropTitle: "Arraste um app aqui",
        uninstallerDropSubtitle: "ou escolha um para analisar",
        uninstallerChoose: "Escolher app…",
        uninstallerPickerTitle: "Escolher app",
        uninstallerPickerSearch: "Buscar apps",
        uninstallerPickerEmpty: "Nenhum app encontrado",
        uninstallerEmptyNote: "Nada é removido sem a sua confirmação.",
        uninstallerFDANote: "Conceda Acesso Total ao Disco para uma análise mais completa.",
        uninstallerFDAGrant: "Conceder acesso…",
        uninstallerFDAHint: "Ative o \(AppInfo.name) na lista. Se ele não aparecer, clique no + e escolha o \(AppInfo.name) em Aplicativos. O acesso só vale depois de reabrir o app.",
        uninstallerFDARelaunch: "Reabrir agora",
        uninstallerScanning: "Analisando arquivos…",
        uninstallerRemoving: "Movendo para a Lixeira…",
        uninstallerFoundTitle: "encontrado",
        uninstallerSelectedFormat: "%d de %d selecionados",
        uninstallerRemove: "Mover para a Lixeira",
        uninstallerCancel: "Cancelar",
        uninstallerDoneTitle: "Pronto!",
        uninstallerFreedFormat: "Dados removidos: %@",
        uninstallerSomeFailed: "Alguns itens não puderam ser movidos para a Lixeira.",
        uninstallerFailedNeedsFDA: "Os dados de apps em área restrita só podem ser movidos com Acesso Total ao Disco. A senha de administrador não substitui essa permissão.",
        uninstallerFailedMoreFormat: "e mais %d",
        uninstallerAnother: "Desinstalar outro",
        uninstallerCatApp: "Aplicativo",
        uninstallerCatSupport: "Suporte",
        uninstallerCatCaches: "Caches",
        uninstallerCatPreferences: "Preferências",
        uninstallerCatContainers: "Contêineres",
        uninstallerCatLogs: "Logs",
        uninstallerCatState: "Estado salvo",
        uninstallerCatOther: "Outros",

        urlCleanerName: "Limpar URL",
        urlCleanerEnable: "Limpar URLs ao copiar",
        urlCleanerEnableCaption: "Remove os parâmetros de rastreamento de um link assim que ele chega à área de transferência.",
        urlCleanerActiveNow: "Ativo agora",
        urlCleanerManualTitle: "Limpar agora",
        urlCleanerInputPlaceholder: "Cole uma URL",
        urlCleanerOutputPlaceholder: "A URL limpa aparece aqui",
        urlCleanerCleanButton: "Limpar",
        urlCleanerPasteButton: "Colar",
        urlCleanerCopyButton: "Copiar",
        urlCleanerClearButton: "Limpar campo",
        urlCleanerNoURL: "Cole uma URL válida.",
        urlCleanerNoChange: "Nada para limpar.",
        urlCleanerCleaned: "URL limpa.",
        urlCleanerCopied: "Copiado.",
        urlCleanerLocalNote: "Local. Sem rede.",

        homebrewName: "Homebrew",
        homebrewMissingTitle: "Homebrew não encontrado",
        homebrewMissingBody: "O Homebrew não está instalado. Quando estiver, os pacotes que ele gerencia aparecem aqui.",
        homebrewRequested: "Instalados por você",
        homebrewMasApps: "App Store",
        homebrewCopyName: "Copiar nome",
        homebrewTrustTitle: "Tap ainda não confiável",
        homebrewTrustCaption: "O Homebrew agora pede sua confirmação antes de usar taps de terceiros. Confie em %@ para continuar.",
        homebrewTrustButton: "Confiar e continuar",
        homebrewNoPackages: "Nenhum pacote encontrado",
        homebrewUninstall: "Desinstalar",
        homebrewUpgrade: "Atualizar",
        homebrewAllPackages: "pacotes",
        homebrewOpenTerminal: "Abrir Terminal",
        homebrewCancelOperation: "Cancelar",
        homebrewClearLog: "Limpar log",
        homebrewHomepage: "Abrir site",
        homebrewUpdateAvailableBadge: "Atualização disponível",
        homebrewConfirmUninstallTitle: "Desinstalar pelo Homebrew?",
        homebrewConfirmUninstallBodyFormat: "O Homebrew vai desinstalar %@. Arquivos de configuração podem permanecer no sistema.",
        homebrewConfirmUpgradeTitle: "Atualizar pelo Homebrew?",
        homebrewConfirmUpgradeBodyFormat: "O Homebrew vai baixar e aplicar a versão mais recente de %@. Dependências também podem ser atualizadas.",
        homebrewTerminalFallback: "Esta operação precisa do Terminal para pedir a senha de administrador. O \(AppInfo.name) não captura senhas.",
        homebrewLoading: "Carregando…",
        homebrewOperationUninstallFormat: "Desinstalando %@",
        homebrewOperationUpgradeFormat: "Atualizando %@",
        homebrewOperationUpdateHomebrew: "Atualizando Homebrew",
        homebrewOperationUninstalledFormat: "%@ desinstalado.",
        homebrewOperationUpgradedFormat: "%@ atualizado.",
        homebrewOperationUpdatedHomebrew: "Homebrew atualizado.",
        homebrewOperationFailedFormat: "Não foi possível concluir %@.",
        homebrewOperationCancelled: "Operação cancelada.",
        homebrewOperationPreparing: "Preparando…",
        homebrewOperationDownloading: "Baixando arquivos…",
        homebrewOperationUninstalling: "Removendo arquivos…",
        homebrewOperationUpgrading: "Atualizando arquivos…",
        homebrewOperationFinalizing: "Finalizando…",
        homebrewOperationRefreshing: "Atualizando lista…",
        homebrewOperationTerminal: "Continue no Terminal.",
        homebrewOperationElapsedFormat: "%@ decorridos",
        homebrewOperationShowDetails: "Mostrar detalhes",
        homebrewOperationHideDetails: "Ocultar detalhes",
        homebrewOperationTechnicalLog: "Detalhes técnicos",
        homebrewOperationProgressUnknown: "O Homebrew ainda não informou uma porcentagem.",

        mediaName: "Media",
        mediaEnableCaption: "Comprima vídeos, converta e processe imagens, crie GIFs e extraia texto localmente.",
        mediaLocalNote: "Local. Sem rede.",
        mediaToolVideo: "Vídeo",
        mediaToolGIF: "GIF",
        mediaToolImage: "Imagem",
        mediaToolText: "Texto",
        mediaSelectFile: "Escolher arquivo",
        mediaDropHint: "Arraste um arquivo aqui ou clique para escolher.",
        mediaOutput: "Saída",
        mediaOutputAutomatic: "Automática",
        mediaChooseOutput: "Destino",
        mediaStartVideo: "Comprimir vídeo",
        mediaStartGIF: "Criar GIF",
        mediaStartImage: "Processar imagem",
        mediaStartConvertPDF: "Converter em PDF",
        mediaStartText: "Extrair texto",
        mediaCancel: "Cancelar",
        mediaStartTime: "Início",
        mediaEndTime: "Fim",
        mediaQuality: "Compressão",
        mediaCompressionLow: "Baixa",
        mediaCompressionMedium: "Média",
        mediaCompressionHigh: "Alta",
        mediaMaxSize: "Tamanho",
        mediaSizingResolution: "Resolução",
        mediaSizingFileSize: "Tamanho do arquivo",
        mediaTargetSize: "Tamanho alvo",
        mediaTargetSizeHint: "A resolução se ajusta para ficar abaixo do limite.",
        mediaErrorTargetTooSmall: "Tamanho alvo pequeno demais para este clipe. Encurte-o ou aumente o limite.",
        mediaMegabytesSuffix: " MB",
        mediaWidth: "Largura",
        mediaFPS: "FPS",
        mediaFormat: "Formato",
        mediaStripMetadata: "Remover metadados",
        mediaLoopGIF: "Repetir GIF",
        mediaOCRMode: "OCR",
        mediaOCRAccurate: "Preciso",
        mediaOCRFast: "Rápido",
        mediaRunning: "Processando",
        mediaCompleted: "Concluído",
        mediaCancelled: "Cancelado.",
        mediaOpenInFinder: "Mostrar",
        mediaCopyText: "Copiar texto",
        mediaRunAgain: "Rodar de novo",
        mediaEmptyText: "Nenhum texto encontrado.",
        mediaResultSavedFormat: "Salvo como %@",
        mediaResultSizeFormat: "%@ para %@",
        mediaResultGrewCaption: "O arquivo convertido ficou maior que o original.",
        mediaErrorNoFile: "Escolha um arquivo primeiro.",
        mediaErrorNoVideo: "Este arquivo não tem trilha de vídeo.",
        mediaErrorSameOutput: "Escolha um destino diferente do arquivo original.",
        mediaErrorUnsupported: "Formato não suportado pelo macOS.",

        shelfName: "Área temporária",
        shelfEnable: "Área temporária para arrastar arquivos",
        shelfEnableCaption: "Um espaço flutuante para juntar arquivos, imagens e textos e arrastá-los depois para qualquer app.",
        shelfHowTitle: "Como usar",
        shelfStep1: "Abra a área com o atalho ou sacudindo o mouse durante um arraste.",
        shelfStep2: "Solte arquivos, imagens, links ou texto sobre ela para guardá-los.",
        shelfStep3: "Arraste cada item de volta para qualquer app quando precisar.",
        shelfShakeToggle: "Abrir sacudindo o mouse durante o arraste",
        shelfShakeCaption: "Sacuda o ponteiro rapidamente segurando um item para chamar a área perto do cursor.",
        shelfDropZoneToggle: "Guardar arquivos na barra de menus ao arrastar",
        shelfDropZoneCaption: "Ao arrastar um arquivo, a área aparece embaixo do ícone na barra de menus. O que você soltar fica guardado ali, num botão que você encolhe e abre com um clique e que some quando a área fica vazia.",
        shelfCollapse: "Encolher",
        shelfBehaviorTitle: "Depois de usar",
        shelfCloseAfterDrop: "Fechar depois de soltar em outro app",
        shelfCloseAfterDropCaption: "Fecha a área quando o destino aceita os itens. O alfinete no painel a mantém aberta.",
        shelfRemoveAfterDrop: "Remover itens depois de soltar",
        shelfRemoveAfterDropCaption: "Itens aceitos por outro app saem da área. Desative para manter uma cópia nela.",
        shelfExclusionsTitle: "Exceções automáticas",
        shelfExclusionsEmpty: "Nenhum app adicionado.",
        shelfExclusionsCaption: "Sacudir e a área da barra de menus não abrem durante arrastes iniciados nesses apps. O atalho e Abrir agora continuam funcionando.",
        shelfPin: "Manter aberta",
        shelfUnpin: "Deixar fechar após o uso",
        shelfHotkeyLabel: "Atalho",
        shelfOpenNow: "Abrir agora",
        shelfNoPermission: "Não requer nenhuma permissão.",
        shelfMenuItem: "Abrir área temporária",
        shelfTitle: "Área temporária",
        shelfEmpty: "Arraste itens aqui",
        shelfClearAll: "Limpar tudo",
        shelfRemoveSelected: "Remover selecionados",
        shelfSelectedFormat: "%d selecionados",
        shelfHint: "Clique para selecionar. Arraste para usar ou clique com o botão direito para mais ações.",
        shelfItemImage: "Imagem",
        shelfTooltipItemsFormat: "%d itens",
        shelfTooltipItemsFew: "%d itens",
        shelfTooltipImageSingular: "%d imagem",
        shelfTooltipImageFew: "%d imagens",
        shelfTooltipImagePlural: "%d imagens",
        shelfTooltipFileSingular: "%d arquivo",
        shelfTooltipFileFew: "%d arquivos",
        shelfTooltipFilePlural: "%d arquivos",
        shelfTooltipNoteSingular: "%d nota",
        shelfTooltipNoteFew: "%d notas",
        shelfTooltipNotePlural: "%d notas",
        shelfTooltipLinkSingular: "%d link",
        shelfTooltipLinkFew: "%d links",
        shelfTooltipLinkPlural: "%d links",
        shelfActionOpen: "Abrir",
        shelfActionOpenWith: "Abrir com",
        shelfActionShare: "Compartilhar",

        breakdownMeasuring: "Medindo…",

        preciseVolumeRollerEnable: "Volume mais preciso no controle",
        preciseVolumeRollerCaption: "Transforma roletes e teclas de volume em passos menores.",
        preciseVolumeRollerTapFailed: "Não foi possível ouvir as teclas de volume.",

        updatesSection: "Atualizações",
        autoCheckToggle: "Procurar atualizações automaticamente",
        betaBadgeLabel: "Beta",
        checkNowButton: "Procurar agora",
        updateChecking: "Procurando…",
        updateUpToDate: "Você está na versão mais recente.",
        updateAvailablePrefix: "Atualização disponível:",
        updateInstallButton: "Baixar e instalar",
        updateDownloading: "Baixando atualização…",
        updateInstalling: "Instalando e reiniciando…",
        updateFailedPrefix: "Não foi possível verificar:",
        updateLastChecked: "Última verificação:",
        updateNotifyTitle: "Atualização do \(AppInfo.name)",
        updateInstallFailedBody: "A atualização foi baixada, mas não pôde ser aplicada. Baixe a versão mais recente na página de releases do GitHub e arraste o app por cima do atual.",
        updateNeedsApplicationsTitle: "Mova o \(AppInfo.name) para Aplicativos",
        updateNeedsApplicationsBody: "O app está rodando de um lugar que não dá para atualizar, como a imagem de disco ou uma área temporária do sistema. Arraste o \(AppInfo.name) para a pasta Aplicativos, abra de lá e tente de novo.",
        menuCheckUpdates: "Procurar atualizações…",

        permissionRequired: "Permissão necessária",
        permissionAccessibility: "Acessibilidade",
        permissionScreenRecording: "Gravação de Tela",
        permissionGranted: "Concedida",
        permissionMissing: "Não concedida",
        permissionOpenSettings: "Abrir Ajustes do Sistema…",
        permissionRequest: "Conceder acesso",
        permissionRestartNote: "O macOS pode pedir para reabrir o app depois de conceder.",

        aboutDescription: "Central de utilidades para o seu Mac.\nEnergia, monitor do sistema, rolagem e alternador de janelas, direto na barra de menus.",
        versionPrefix: "Versão",
        reviewIntro: "Rever introdução",
        reviewHighlights: "Rever novidades",
        viewOnGitHub: "Ver no GitHub",

        obContinue: "Continuar",
        obBack: "Voltar",
        obStart: "Abrir o \(AppInfo.name)",
        obStepWelcomeTitle: "Bem-vindo ao \(AppInfo.name)",
        obStepWelcomeBody: "Um utilitário discreto na barra de menus que deixa o macOS mais prático no dia a dia.",
        obWelcomeBullet1Title: "Energia sob controle",
        obWelcomeBullet1Body: "Mantenha o Mac acordado por quanto tempo quiser, até com a tampa fechada.",
        obWelcomeBullet2Title: "Visão clara do sistema",
        obWelcomeBullet2Body: "Temperaturas, uso de CPU e GPU e pressão de memória em tempo real.",
        obWelcomeBullet3Title: "Mouse e janelas do seu jeito",
        obWelcomeBullet3Body: "Rolagem invertida no mouse e um alternador de janelas com miniaturas.",
        obLanguageLabel: "Idioma",
        obStepDoneTitle: "Tudo pronto!",
        obStepDoneBody: "O \(AppInfo.name) já está cuidando do seu Mac.",
        obDoneHint: "Look for the kururu icon in the menu bar, at the top right of the screen.",
        obWhatsNewTitle: "Novidades nesta versão",
        obWhatsNewFallback: "Esta atualização inclui as correções e melhorias mais recentes.",
        obPurposeTitle: "O que te trouxe aqui?",
        obPurposeBody: "Selecione os recursos que deseja ativar. Suas opções atuais serão mantidas.",
        obPurposeSkip: "Você pode adicionar ou remover recursos depois nos Ajustes.",

        tabMonitor: "Monitor",
        tabMenuBarIcon: "Ícone da barra de menus",
        tabMenuBarPanel: "Painel da barra de menus",
        monitorMenuBarSection: "Na barra de menus",
        monitorCombineTemperatures: "Combinar uso e temperatura",
        monitorCombineTemperaturesCaption: "Quando uso e temperatura do mesmo item estiverem ativos, mostra tudo em um bloco só.",
        monitorSeparateMenuBarMetrics: "Separar métricas em itens próprios",
        monitorSeparateMenuBarMetricsCaption: "Separa os blocos ativos na barra de menus e mantém uso e temperatura juntos quando combinar estiver ativo.",
        monitorNetworkUploadFirst: "Upload acima do download",
        monitorShowCPU: "CPU",
        monitorShowMemory: "Memória",
        monitorShowNetwork: "Rede",
        monitorShowPowerLabel: "Energia",
        monitorIntervalLabel: "Atualizar a cada",
        monitorInterval1: "1 segundo",
        monitorInterval2: "2 segundos",
        monitorInterval5: "5 segundos",
        monitorPanelSection: "No painel",
        betaBadge: "BETA",
        betaFeatureWarning: "Beta. Você pode encontrar alguns bugs.",

        networkSection: "Rede",
        networkDownload: "Download",
        networkUpload: "Upload",
        networkThisSession: "Nesta sessão",
        networkMeasuring: "Medindo…",
        networkApps: "Apps usando rede",
        networkAppsIdle: "Nenhum app usando rede agora",

        diskSection: "Discos",
        diskUsed: "usado",
        diskAvailable: "disponível",
        diskPurgeable: "purgável",
        diskInternal: "Interno",
        diskExternal: "Externo",
        diskSelect: "Selecionar disco",
        diskRead: "Leitura",
        diskWrite: "Escrita",
        diskSMARTStatus: "Status",
        diskSMARTUnavailable: "SMART indisponível para este disco",
        diskTotalRead: "Total lido",
        diskTotalWritten: "Total escrito",
        diskTemperature: "Temperatura",
        diskHealth: "Saúde",
        diskPowerCycles: "Ciclos",
        diskPowerOnHours: "Horas ligado",
        diskEject: "Ejetar",
        diskEjectAll: "Ejetar todos",
        diskEjecting: "Ejetando…",
        diskReadyToRemove: "Pronto para remover",
        diskEjectFailed: "Não foi possível ejetar",
        diskProtectionCaption: "Ejete antes de desconectar.",
        diskNoExternal: "Nenhum disco externo pronto para ejeção.",
        diskOpenInFinder: "Abrir",
        diskStorageSettings: "Armazenamento",
        diskNoDisks: "Nenhum disco montado encontrado.",

        powerSection: "Energia",
        powerSystem: "Sistema",
        powerAdapter: "Adaptador",
        powerBattery: "Bateria",
        powerCharging: "Carregando",
        powerOnBattery: "Na bateria",
        powerPluggedIn: "Na tomada",
        powerUnavailable: "Métricas de energia indisponíveis neste Mac",
        powerAdapterMaxFormat: "%@ máx.",
        monitorShowGPU: "GPU",
        monitorShowCPUTemperature: "Temperatura da CPU",
        monitorShowGPUTemperature: "Temperatura da GPU",
        monitorShowBatteryTemperature: "Temperatura da bateria",
        monitorShowPeripheralBattery: "Bateria dos periféricos",
        peripheralBatteryNoDevices: "Nenhum periférico encontrado",

        updateBannerTitle: "Atualização disponível",
        updateBannerAction: "Atualizar",
        menuBarSpacingLabel: "Espaçamento na barra",
        menuBarSpacingStandard: "Padrão",
        menuBarSpacingCompact: "Compacto",
        menuBarHideIconToggle: "Ocultar o ícone do app enquanto houver métricas",
        menuBarHideIconCaption: "O ícone volta sozinho quando as métricas saem da barra e quando há algo a avisar (atualização pronta ou microfone silenciado).",
        menuBarIconSection: "Ícone do app",
        monitorMemoryPressureDot: "Ponto de pressão",
        systemUptime: "Ativo há",
        batteryCharge: "Carga",
        powerHealth: "Saúde da bateria",
        powerCycles: "Ciclos",
        speedTestRun: "Testar velocidade",
        speedTestAgain: "Testar de novo",
        speedTestLatency: "Latência",
        speedTestTesting: "Testando…",
        speedTestFailed: "Falha no teste",

        monitorShowInPanel: "Mostrar no painel",
        disclosureExpanded: "Expandido",
        disclosureCollapsed: "Recolhido",
        panelHideItem: "Ocultar do painel",
        panelShowItem: "Mostrar no painel",
        panelHiddenItem: "Oculto",
        monitorItemUptime: "Tempo ativo",
        monitorItemNetSpeed: "Velocidade ao vivo",
        monitorItemNetTotals: "Totais da sessão",
        monitorItemNetTest: "Teste de velocidade",
        monitorItemDiskUsage: "Uso do disco",
        monitorItemDiskActivity: "Atividade ao vivo",
        monitorItemDiskSMART: "SMART",
        monitorItemDiskProtection: "Proteção externa",
        monitorItemDiskTools: "Ferramentas",
        monitorOrderSection: "Ordem das seções",
        monitorOrderHint: "Arraste para reordenar as seções do painel e use o olho para mostrar ou ocultar cada uma.",

        cleaningMenuItem: "Modo de limpeza",
        utilitiesSection: "Utilidades",
        quickControlsSection: "Controles",
        panelCategoryWindows: "Janelas",
        panelCategoryInput: "Mouse e teclado",
        panelCategoryFiles: "Arquivos",
        windowMaximizeName: "Maximizar janelas",
        windowMaximizeCaption: "O botão verde maximiza sem criar outro Espaço.",
        keyDebounceName: "Debounce",
        keyDebounceEnable: "Filtrar teclas duplicadas",
        keyDebounceCaption: "Filtra toques duplicados muito rápidos.",
        keyDebounceActiveNow: "Filtro ativo",
        keyDebounceGlobalWindow: "Janela global",
        keyDebouncePerKeySection: "Teclas específicas",
        keyDebouncePerKeyCaption: "Valores por tecla substituem a janela global. Use 0 ms para não filtrar uma tecla.",
        keyDebounceKeyLabel: "Tecla",
        keyDebounceAddKey: "Adicionar tecla",
        keyDebounceNoOverrides: "Nenhuma tecla específica configurada.",
        keyDebounceRemoveKey: "Remover tecla",
        cleaningPanelCaption: "Bloqueia o teclado para limpar com segurança.",
        cleaningOverlayTitle: "Teclado bloqueado para limpeza",
        cleaningOverlaySubtitle: "Pressione Esc 5 vezes para desbloquear",
        cleaningOverlayUnlock: "Desbloquear",
        cleaningOverlayMouseHint: "O mouse e o trackpad continuam funcionando",
        cleaningKeepScreenVisibleToggle: "Manter a tela visível",
        cleaningKeepScreenVisibleCaption: "Exibe um indicador discreto no canto da tela em vez de escurecer o conteúdo.",
        cleaningStartNow: "Bloquear teclado agora",
        cleaningNeedsAxTitle: "Precisa de Acessibilidade",
        cleaningNeedsAxBody: "Para bloquear o teclado com segurança, o \(AppInfo.name) precisa da permissão de Acessibilidade. Conceda em Ajustes do Sistema e tente de novo.",

        shortcutsPageCaption: "Edite aqui todos os atalhos globais dos recursos ativados neste Mac. Os inativos continuam salvos, mas não funcionam.",
        shortcutsPageTitle: "Atalhos de teclado",
        settingsSearchPlaceholder: "Buscar ajustes",
        supportIntroLaterButton: "Agora não",
        supportIntroDoneButton: "Concluir",
        updateShowcaseTitle: "Novidades da 3.1.4",
        updateShowcaseMessage: "Veja uma prévia rápida das principais melhorias desta atualização.",
        updateShowcaseUnavailable: "Não foi possível carregar o vídeo agora. Você ainda pode continuar.",
        updateShowcaseRestart: "Voltar ao início",
        showMenuBarIcon: "Mostrar ícone na barra de menus",
        showMenuBarIconCaption: "Se o ícone do \(AppInfo.name) sumir (o macOS pode esconder ícones quando a barra de menus fica sem espaço, comum em Macs com notch), reabra o \(AppInfo.name) pela pasta Aplicativos ou pelo Spotlight: isso recria o ícone e, se ele ainda estiver escondido, abre esta janela.",
        menuBarIconStillHiddenTitle: "O ícone continua escondido",
        menuBarIconStillHiddenBody: "O ícone foi recriado, mas o macOS não deu um lugar visível a ele. A barra de menus provavelmente está sem espaço: remova alguns ícones da barra (ou feche apps com menus longos) e tente de novo.",
        menuBarIconManagerHintFormat: "O %@ está aberto e pode estar guardando o ícone na seção oculta dele. Procure o \(AppInfo.name) lá, ou configure o %@ para sempre mostrar o \(AppInfo.name).",
        shortcutRecording: "Pressione o novo atalho",
        shortcutReset: "Redefinir",
        shortcutNone: "Nenhum",
        shortcutClear: "Remover atalho",
        shortcutInvalid: "Use pelo menos Control, Option ou Command junto com uma tecla.",
        shortcutPressKeys: "Pressione",
        shortcutEscapeHint: "Esc cancela.",
        shortcutDeleteHint: "Delete remove.",
        shortcutNotCaptured: "Nada foi capturado. O macOS ou outro app já usa essa combinação. Tente outra.",
        shortcutConflictFormat: "Este atalho já está em uso por %@.",
        shortcutUnavailable: "O macOS recusou este atalho. Escolha outro.",
        shelfShortcutToggle: "Atalho da área temporária",
        switcherUsageHintFormat: "Segure %@ para navegar; solte para ativar a janela. Shift ou ← volta; W fecha a janela; Q encerra o app; Esc cancela.",
        cleanerName: "Limpeza",
        cleanerIntroTitle: "Limpe o lixo do Mac",
        cleanerIntroCaption: "Procura restos de apps desinstalados, caches, registros e a Lixeira. Você revisa tudo antes e os itens removidos vão para a Lixeira.",
        cleanerScan: "Verificar",
        cleanerScanning: "Verificando…",
        cleanerCleaning: "Limpando…",
        cleanerCatLeftovers: "Restos de apps desinstalados",
        cleanerCatLoginItems: "Itens de início órfãos",
        cleanerCatCaches: "Caches",
        cleanerCatLogs: "Registros",
        cleanerCatDeveloper: "Lixo de desenvolvimento",
        cleanerCatTrash: "Lixeira",
        cleanerLeftoversNote: "Encontrados por análise e começam desmarcados. Confira o caminho antes de marcar.",
        cleanerLoginItemsNote: "A entrada em Itens de Início some depois de reiniciar o Mac.",
        cleanerTrashNote: "Esvaziar a Lixeira é permanente.",
        cleanerCatDeviceBackups: "Backups de iPhone",
        cleanerDeviceBackupsCaption: "Backups antigos de iPhone e iPad ocupam boa parte do que o macOS chama de Outros. Remova só os que você não precisa mais; um novo backup é feito quando o aparelho for conectado de novo.",
        cleanerNothingFound: "Nada para limpar. Seu Mac está em ordem.",
        cleanerDoneNote: "Os itens foram para a Lixeira e podem ser recuperados de lá.",
        cleanerAgain: "Verificar de novo",
        cleanerRevealInFinder: "Mostrar no Finder",
        cleanerPanelCaption: "Restos de apps, caches e logs",
        cleanerSafeSection: "Limpeza segura",
        cleanerOptionalSection: "Opcional, revise antes",
        cleanerCatOtherCaches: "Outros caches",
        cleanerCachesCaption: "Arquivos temporários que os apps refazem sozinhos.",
        cleanerLogsCaption: "Registros antigos de diagnóstico.",
        cleanerDeveloperCaption: "Restos de compilações e simuladores do Xcode.",
        cleanerLoginItemsCaption: "Entradas de início deixadas por apps que não existem mais.",
        cleanerLeftoversCaption: "Arquivos deixados por apps que você desinstalou.",
        cleanerOtherCachesCaption: "Seguro apagar, nada quebra. Apps podem abrir mais devagar na primeira vez e conteúdo baixado, como músicas offline, baixa de novo.",
        cleanerCleanSizeFormat: "Limpar %@",
        cleanerScheduleTitle: "Limpeza automática",
        cleanerScheduleOff: "Desativada",
        cleanerScheduleDaily: "Diária",
        cleanerScheduleWeekly: "Semanal",
        cleanerScheduleCaption: "Limpa sozinha só a parte segura no horário escolhido e manda tudo para a Lixeira.",
        cleanerAutoNotificationFormat: "%@ liberados e enviados para a Lixeira.",
        cleanerScheduleNextFormat: "Próxima limpeza %@.",
        cleanerScheduleNotifyToggle: "Avisar quando terminar",
        cleanerNotifDenied: "As notificações do \(AppInfo.name) estão desativadas no sistema.",
        cleanerNotifOpenSettings: "Abrir Ajustes de Notificações…",
        launchAtLoginNeedsApplications: "O app está rodando de um lugar que não permite abrir no login. Arraste o \(AppInfo.name) para a pasta Aplicativos, abra de lá e ligue de novo.",
        launchAtLoginNeedsApproval: "O item de login está registrado, mas continua desligado nos Ajustes do Sistema. Abra Ajustes do Sistema › Geral › Itens de Início e Extensões e ligue o \(AppInfo.name) em “Abrir ao iniciar sessão”.",
        ocrRemoveLineBreaksToggle: "Remover quebras de linha",
        ocrRemoveLineBreaksCaption: "Remove as quebras de linha para que o texto copiado seja colado como um único parágrafo.",
        ocrQRToggle: "Ler QR codes",
        ocrQRCaption: "Se a área tiver um QR code, o conteúdo dele aparece para copiar ou abrir.",
        ocrQRCopied: "QR code copiado",
        qrResultTitle: "QR code",
        qrResultCopy: "Copiar",
        qrResultOpen: "Abrir link",
        highlightsTitle: "Novidades desta versão",
        highlightsTitleQuitProtection: "Proteção de ⌘Q e ⌘W",
        highlightsTitleRecorderBlur: "Desfoque no gravador de tela",
        highlightsCaptionQuitProtection: "Evite fechar aplicativos ou janelas por engano exigindo segurar a tecla, tocar duas vezes ou usar um atalho extra, ajustável por aplicativo.",
        highlightsCaptionRecorderBlur: "Oculte dados confidenciais, senhas e informações privadas em qualquer trecho do seu vídeo gravado antes de salvar ou exportar.",
        highlightsConfigure: "Configurar",
        highlightsSeeAll: "Ver todas as mudanças",
        switcherCurrentSpaceOnly: "Mostrar só a Mesa atual",
        switcherCurrentSpaceOnlyCaption: "Mostra no alternador apenas as janelas da Mesa em que você está. Escolher uma janela nunca leva você para outra Mesa.",
        shelfFileMissing: "O arquivo não existe mais",
        monitorOpenActivityMonitor: "Abrir o Monitor de Atividade",
        monitorMemoryMetricLabel: "Medir memória como",
        memoryMetricUsed: "Memória usada",
        memoryMetricApp: "Memória de apps",
        keepAwakeRightClickToggle: "Clique com o botão direito no ícone da barra de menus para alternar “Manter acordado”",
        keepAwakeRightClickToggleCaption: "Substitui o menu de contexto do clique com o botão direito.",
        urlCleanerRulesTitle: "Regras de limpeza",
        urlCleanerRulesCaption: "Um site anexa estes parâmetros aos próprios links de compartilhamento para rastrear de onde o link veio. Ligado, o nome é removido ao limpar um link; desligado, ele permanece. Os nomes que você adicionar podem ser excluídos.",
        urlCleanerRulesCoverageCaption: "A lista cobre os diferentes caminhos de compartilhamento de um site (a página, o app, uma sala ao vivo), por isso é longa; um link real costuma carregar apenas dois a quatro deles.",
        urlCleanerRulesAllSites: "Todos os sites",
        urlCleanerRulesAddSite: "Adicionar site",
        urlCleanerRulesParameterPlaceholder: "Nome do parâmetro",
        urlCleanerRulesMatchCaption: "Escreva o nome à esquerda do = , como utm_source. Um nome que corresponde tira aquele parâmetro do link e deixa o resto como está.",
        urlCleanerRulesAddButton: "Adicionar",
        urlCleanerRemovedFormat: "Removidos %@",
        switcherSearchPin: "Fixar busca com S",
        switcherSearchPinCaption: "S inicia uma busca e fixa o alternador aberto, assim digitar não produz mais caracteres especiais quando o atalho usa ⌥, e uma busca que comece com Q ou W não fecha a janela nem encerra o app por engano.",
        invertVerticalScroll: "Inverter rolagem vertical",
        invertHorizontalScroll: "Inverter rolagem horizontal",
        switcherShowShortcutHints: "Mostrar dicas de atalhos",
        switcherShowShortcutHintsCaption: "Exibe os atalhos de apps e janelas abaixo dos ícones.",
        uninstallerHomebrewPackageFormat: "%@ também será removido do Homebrew.",
        shelfEdgeToggle: "Abrir perto de uma borda da tela",
        shelfEdgeCaption: "Ao arrastar um arquivo para perto da borda da tela, a área espia para dentro. Solte ali, ou puxe de volta e ela recua.",
        focusFollowsMouseName: "Foco ao passar o mouse",
        focusFollowsMouseCaption: "Coloca em foco e traz para frente a janela sob o ponteiro após uma breve pausa.",
        focusFollowsMouseDelay: "Atraso ao passar o mouse",
        switcherMinimizedPlacementLabel: "Janelas minimizadas",
        switcherMinimizedPlacementNormal: "Ordem normal",
        switcherMinimizedPlacementEnd: "Colocar no final",
        switcherMinimizedPlacementHidden: "Ocultar",
        switcherShowFullscreenWindows: "Mostrar janelas em tela cheia",
        switcherScreenPlacementLabel: "Mostrar em",
        switcherScreenPlacementPointer: "Tela com o ponteiro",
        switcherScreenPlacementMenuBar: "Tela com a barra de menus",
        switcherScreenPlacementActiveWindow: "Tela com a janela ativa",
        switcherScreenPlacementCaption: "Em qual tela o alternador abre quando há mais de uma conectada.",
        smoothScrollResponseLabel: "Resposta",
        mouseAccelerationName: "Desativar aceleração do mouse",
        mouseAccelerationCaption: "Remove a aceleração do cursor para os mouses conectados. A configuração anterior volta ao desligar esta opção ou sair do \(AppInfo.name).",
        shelfClearOnClose: "Limpar ao fechar",
        shelfClearOnCloseCaption: "Esvazia a área somente quando você clica no botão de fechar. Ocultar automaticamente e encolher preservam os itens."
    )
}

// MARK: - English (US)

extension Strings {
    static let enUS = Strings()
}
