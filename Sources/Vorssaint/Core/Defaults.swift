// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import CoreGraphics
import Carbon.HIToolbox
import Foundation

/// Every UserDefaults key used by the app, in one place.
enum DefaultsKey {
    static let language = "appLanguage"                   // AppLanguage.rawValue
    static let appearance = "appAppearance"               // AppAppearance.rawValue
    static let clamshellPreferred = "clamshellPreferred"  // apply closed-lid mode to every session
    static let onboardingStep = "onboardingStep"          // resume point if onboarding is interrupted
    static let featuresOnboardingVersion = "featuresOnboardingVersion" // last feature-tour marker handled
    static let lastUpdateIntroVersion = "lastUpdateIntroVersion"
    static let supportUpdateIntroVersion = "supportUpdateIntroVersion"
    static let updateHighlightsSeenVersion = "updateHighlightsSeenVersion"
    static let updateShowcaseIntroVersion = "updateShowcaseIntroVersion"
    static let updateShowcaseMediaOverride = "updateShowcaseMediaOverride"
    static let defaultDuration = "defaultDurationMinutes" // 0 = indefinite
    static let batteryLimit = "batteryLimitPercent"       // 0 = never
    static let keepAwakeAutoStart = "keepAwakeAutoStart"  // start Keep Awake when the app launches
    static let keepAwakeRightClickToggle = "keepAwakeRightClickToggle"
    static let keepAwakeAllowDisplaySleep = "keepAwakeAllowDisplaySleep"
    static let keepAwakeExternalDisplay = "keepAwakeExternalDisplay"
    static let keepAwakeConnectedToPower = "keepAwakeConnectedToPower"
    static let keepAwakeRunningApps = "keepAwakeRunningApps"
    static let keepAwakeRunningAppBundleIDs = "keepAwakeRunningAppBundleIDs"
    static let keepAwakePauseWhenLocked = "keepAwakePauseWhenLocked"
    static let keepAwakeMouseJiggleEnabled = "keepAwakeMouseJiggleEnabled"
    static let keepAwakeMouseJiggleInterval = "keepAwakeMouseJiggleIntervalMinutes"
    static let hotkeyEnabled = "hotkeyEnabled"
    static let launchAtLoginWanted = "launchAtLoginWanted"  // the user's choice; the system record can be lost
    static let keepAwakeShortcut = "keepAwakeShortcut"    // GlobalShortcut storage value
    static let keepAwakeIconTint = "keepAwakeIconTint"    // KeepAwakeIconTint.rawValue
    static let keepAwakeActiveIcon = "keepAwakeActiveIcon" // KeepAwakeActiveIcon.rawValue
    static let showCountdown = "showCountdownInMenuBar"
    static let statusItemPlacementGeneration = "statusItemPlacementGeneration"
    static let hasOnboarded = "hasOnboarded"
    static let sleepDisabledFlag = "vorssDisabledSleep"   // internal guard for pmset disablesleep
    static let scrollInverterEnabled = "scrollInverterEnabled"
    static let scrollInverterHorizontalEnabled = "scrollInverterHorizontalEnabled"
    static let scrollHorizontalEnabled = "scrollHorizontalEnabled"
    static let scrollHorizontalModifier = "scrollHorizontalModifier"
    static let focusFollowsMouseEnabled = "focusFollowsMouseEnabled"
    static let focusFollowsMouseDelay = "focusFollowsMouseDelayMilliseconds"
    static let focusFollowsMouseExceptions = "focusFollowsMouseExceptions"
    static let smoothScrollEnabled = "smoothScrollEnabled"
    static let smoothScrollStep = "smoothScrollStep"      // pixels per wheel tick
    static let mouseAccelerationDisabled = "mouseAccelerationDisabled" // sets HIDMouseAcceleration to -1 for mice
    static let smoothScrollResponse = "smoothScrollResponse" // 0...100, higher follows the wheel sooner
    static let mouseNavigationEnabled = "mouseNavigationEnabled" // side buttons trigger Back and Forward
    static let mouseButtonShortcutsEnabled = "mouseButtonShortcutsEnabled" // extra buttons press a key combination (issue #282)
    static let mouseButtonShortcuts = "mouseButtonShortcuts" // [button number: GlobalShortcut storage value]
    static let mouseSpacesGestureEnabled = "mouseSpacesGestureEnabled" // hold a button and drag to switch Spaces (issue #1012)
    static let mouseSpacesGestureButton = "mouseSpacesGestureButton"   // button number, 0 while none is chosen
    static let mouseSpacesGestureFollowsDrag = "mouseSpacesGestureFollowsDrag" // the Space moves with the hand, the way natural scrolling does
    static let mouseClickDebounceEnabled = "mouseClickDebounceEnabled"
    static let mouseClickDebounceWindowMs = "mouseClickDebounceWindowMs"
    static let superKeyEnabled = "superKeyEnabled"        // chosen key holds the configured modifiers (issue #330)
    static let superKeySource = "superKeySource"           // SuperKeySource raw value
    static let superKeyModifiers = "superKeyModifiers"     // GlobalShortcutModifiers storage tokens
    static let superKeySoloAction = "superKeySoloAction"  // SuperKeySoloAction raw value
    // Machine state, never exported: whether the keyboard mapping is in place
    // and which source to take back after a crash.
    static let superKeyMappingApplied = "superKeyMappingApplied"
    static let superKeyMappedSource = "superKeyMappedSource"
    // One list of bundle ids per mouse feature: apps it leaves alone (issue #358).
    static let smoothScrollExceptions = "smoothScrollExceptions"
    static let scrollInverterExceptions = "scrollInverterExceptions"
    static let mouseNavigationExceptions = "mouseNavigationExceptions"
    static let mouseButtonExceptions = "mouseButtonExceptions"
    static let middleClickExceptions = "middleClickExceptions"
    static let superKeyExceptions = "superKeyExceptions"
    static let switcherEnabled = "switcherEnabled"
    static let switcherTakeOverSystemShortcuts = "switcherTakeOverSystemShortcuts"
    // Machine state, never exported: the system shortcuts this process owns,
    // so a launch after a crash can restore them. The switcher-only key is
    // what builds before the take-over was shared wrote; it is read once,
    // folded into the shared one, and then retired.
    static let switcherNativeHotkeysSuppressed = "switcherNativeHotkeysSuppressed"
    static let systemShortcutsSuppressed = "systemShortcutsSuppressed"
    // Storage keys of shortcuts the user chose to take over from macOS. A
    // preference, exported.
    static let systemShortcutTakeOverKeys = "systemShortcutTakeOverKeys"
    static let switcherShortcut = "switcherShortcut"      // GlobalShortcut storage value
    static let switcherWindowShortcut = "switcherWindowShortcut" // GlobalShortcut storage value
    static let switcherIconRowMode = "switcherIconRowMode"
    static let switcherSimpleMode = "switcherSimpleMode"  // app-only row without window captures
    static let switcherMergeTabs = "switcherMergeTabs"     // show one switcher entry per app (collapse all of an app's windows)
    static let switcherShowWindowlessFinder = "switcherShowWindowlessFinder" // replaced by switcherWindowlessApps, kept so the migration can read it
    static let switcherWindowlessApps = "switcherWindowlessApps" // SwitcherWindowlessApps raw value
    static let switcherMinimizedPlacement = "switcherMinimizedPlacement"
    static let switcherShowFullscreenWindows = "switcherShowFullscreenWindows"
    static let switcherAppRules = "switcherAppRules" // [bundle id: SwitcherAppRule raw value]
    static let switcherCurrentSpaceOnly = "switcherCurrentSpaceOnly" // list only windows on the desktop the user is in (issue #337)
    static let switcherSearchPinEnabled = "switcherSearchPinEnabled" // S pins the search field open, off by default so existing users typing S as a search letter see no change
    static let switcherShowShortcutHints = "switcherShowShortcutHints" // show the shortcut bar under the large-icon switcher
    static let switcherAppearanceDelay = "switcherAppearanceDelay" // milliseconds the shortcut must be held before the panel appears (SwitcherSupport.appearanceDelayMillisecondsRange)
    static let switcherScreenPlacement = "switcherScreenPlacement" // SwitcherScreenPlacement raw value: which display the panel opens on
    static let switcherCurrentDisplayOnly = "switcherCurrentDisplayOnly" // list only windows on the display under the pointer (issue #1391)
    static let dockPreviewEnabled = "dockPreviewEnabled"
    static let dockPreviewKeepDockVisible = "dockPreviewKeepDockVisible"
    static let dockPreviewRestoreAutohide = "dockPreviewRestoreAutohide" // local crash recovery; never backed up
    static let dockPreviewBackgroundOpacity = "dockPreviewBackgroundOpacity" // how solid the preview panel's material is drawn (DockPreviewSupport.backgroundOpacityRange)
    static let dockPreviewOpenDelay = "dockPreviewOpenDelay" // milliseconds the cursor must rest on a Dock icon before its panel opens (DockPreviewSupport.openDelayMillisecondsRange)
    static let dockPreviewQuitAppOnClose = "dockPreviewQuitAppOnClose" // the preview card's close button quits the owning app instead of closing one window
    static let dockClickMinimize = "dockClickMinimize"    // click the active app's Dock icon to minimize its windows
    static let dockClickHide = "dockClickHide"            // click the active app's Dock icon to hide the app
    static let dockClickCycleWindows = "dockClickCycleWindows" // click the active app's Dock icon to cycle through its windows
    static let middleClickEnabled = "middleClickEnabled"  // three-finger PHYSICAL click on the trackpad acts as a middle click
    static let middleClickTapFingers = "middleClickTapFingers"  // 0 = off (default); 3 or 4 = a light tap with that many fingers also middle-clicks (issue #161)
    static let previewSize = "previewSize"                // legacy: split into the two keys below, read only by migration
    static let switcherPreviewSize = "switcherPreviewSize" // app switcher thumbnail size
    static let dockPreviewSize = "dockPreviewSize"        // dock preview thumbnail size
    static let autoCheckUpdates = "autoCheckUpdates"
    static let releaseNotesOnUpdate = "releaseNotesOnUpdate" // show What's New after an update
    static let appVolumes = "appVolumes"                  // [bundle id: 0...2]
    static let appOutputDevices = "appOutputDevices"      // [bundle id: audio device UID]
    static let mixerShowFinder = "mixerShowFinder"
    static let mixerHideInactiveApps = "mixerHideInactiveApps"
    static let mixerHiddenApps = "mixerHiddenApps"        // [persistence id: display name] kept out of the mixer list (issue #300)
    static let mixerLowerVolumeOnHeadphonesDisconnect = "mixerLowerVolumeOnHeadphonesDisconnect"
    static let mixerHeadphonesDisconnectVolumePercent = "mixerHeadphonesDisconnectVolumePercent"
    static let preciseVolumeRollerEnabled = "preciseVolumeRollerEnabled"
    static let soundOutputSwitcherEnabled = "soundOutputSwitcherEnabled"
    static let soundOutputSwitcherShortcut = "soundOutputSwitcherShortcut"
    static let soundOutputSwitcherDeviceUIDs = "soundOutputSwitcherDeviceUIDs"
    static let preferredInputDevice = "preferredInputDevice" // audio input device UID
    static let finderCutPasteEnabled = "finderCutPasteEnabled"
    static let finderCutPasteShowHUD = "finderCutPasteShowHUD"
    static let finderRenameEnabled = "finderRenameEnabled"
    static let finderRenameShortcut = "finderRenameShortcut"
    static let finderPasteImageAsFile = "finderPasteImageAsFile"
    static let autoQuitEnabled = "autoQuitEnabled"
    static let autoQuitExceptions = "autoQuitExceptions"  // [bundle id] kept running
    // Quit/close protection: each shortcut owns its full configuration and app list.
    static let quitProtectionQuitEnabled = "quitProtectionQuitEnabled"
    static let quitProtectionQuitMode = "quitProtectionQuitMode"
    static let quitProtectionQuitHoldDurationMs = "quitProtectionQuitHoldDurationMs"
    static let quitProtectionQuitDoubleIntervalMs = "quitProtectionQuitDoubleIntervalMs"
    static let quitProtectionQuitExtraModifier = "quitProtectionQuitExtraModifier"
    static let quitProtectionQuitScope = "quitProtectionQuitScope"
    static let quitProtectionQuitExceptions = "quitProtectionQuitExceptions"
    static let quitProtectionQuitShowFeedback = "quitProtectionQuitShowFeedback"
    static let quitProtectionCloseEnabled = "quitProtectionCloseEnabled"
    static let quitProtectionCloseMode = "quitProtectionCloseMode"
    static let quitProtectionCloseHoldDurationMs = "quitProtectionCloseHoldDurationMs"
    static let quitProtectionCloseDoubleIntervalMs = "quitProtectionCloseDoubleIntervalMs"
    static let quitProtectionCloseExtraModifier = "quitProtectionCloseExtraModifier"
    static let quitProtectionCloseScope = "quitProtectionCloseScope"
    static let quitProtectionCloseExceptions = "quitProtectionCloseExceptions"
    static let quitProtectionCloseShowFeedback = "quitProtectionCloseShowFeedback"
    static let shelfEnabled = "shelfEnabled"
    static let shelfShortcutEnabled = "shelfShortcutEnabled"
    static let shelfShortcut = "shelfShortcut"            // GlobalShortcut storage value
    static let shelfShakeToOpen = "shelfShakeToOpen"
    static let shelfDropZoneEnabled = "shelfDropZoneEnabled"
    static let shelfDockPlacement = "shelfDockPlacement"
    static let shelfEdgeDragEnabled = "shelfEdgeDragEnabled"
    static let shelfCloseAfterDrop = "shelfCloseAfterDrop"
    static let shelfRemoveAfterDrop = "shelfRemoveAfterDrop"
    static let shelfClearOnClose = "shelfClearOnClose"
    static let shelfAutomaticExclusions = "shelfAutomaticExclusions" // [bundle id] blocks automatic opening only
    static let brightnessControlEnabled = "brightnessControlEnabled" // legacy, consumed by migration only
    static let brightnessModuleGateMigrated = "brightnessModuleGateMigrated"
    static let brightnessKeysEnabled = "brightnessKeysEnabled" // brightness keys act on the display under the pointer
    static let brightnessOSDEnabled = "brightnessOSDEnabled" // brightness adjustment overlay
    static let keyboardBrightnessShortcutsEnabled = "keyboardBrightnessShortcutsEnabled"
    static let keyboardBrightnessDecreaseShortcut = "keyboardBrightnessDecreaseShortcut"
    static let keyboardBrightnessIncreaseShortcut = "keyboardBrightnessIncreaseShortcut"
    // Per-monitor connection paths that accept brightness writes but never
    // answer reads. Kept local so wake handling does not repeatedly probe a
    // sensitive display path.
    static let brightnessDDCWriteOnlyPaths = "brightnessDDCWriteOnlyPaths"
    // Displays this app switched off, so a run that ends without putting them
    // back can be repaired on the next start instead of needing a replug.
    static let displaysSwitchedOff = "displaysSwitchedOff"
    // Set while a start is under way and cleared once the app has run
    // healthily for a while, or when it is quit properly. Found still set at
    // the next start, it means the previous one died on the way up.
    static let startupDidNotFinish = "startupDidNotFinish"
    static let bluetoothSleepEnabled = "bluetoothSleepEnabled"
    static let bluetoothSleepRestoreOnWake = "bluetoothSleepRestoreOnWake"
    // Set only while Vorssaint owes a Bluetooth restore, so a Mac shut down
    // while asleep still gets it back on the next launch.
    static let bluetoothSleepRestorePending = "bluetoothSleepRestorePending"
    static let musicBlockEnabled = "musicBlockEnabled"
    static let musicBlockBundleIDs = "musicBlockBundleIDs"
    static let musicBlockReplacementPath = "musicBlockReplacementPath"  // app bundle path ("" = none)
    static let cleanerScheduleFrequency = "cleanerScheduleFrequency"    // off | daily | weekly
    static let cleanerScheduleHour = "cleanerScheduleHour"
    static let cleanerScheduleMinute = "cleanerScheduleMinute"
    static let cleanerScheduleWeekday = "cleanerScheduleWeekday"        // 1 Sunday ... 7 Saturday
    static let cleanerScheduleNotify = "cleanerScheduleNotify"
    static let cleanerLastAutoRun = "cleanerLastAutoRun"                // Double, epoch seconds
    static let cleanerLastAutoFreed = "cleanerLastAutoFreed"            // Int bytes
    // Confirmed WhatsApp downloads in the top level of ~/Downloads.
    static let whatsAppDownloadsEnabled = "whatsAppDownloadsEnabled"
    static let whatsAppDownloadsAutomaticEnabled = "whatsAppDownloadsAutomaticEnabled"
    static let whatsAppDownloadsCategories = "whatsAppDownloadsCategories" // comma-joined category ids
    static let whatsAppDownloadsRetentionDays = "whatsAppDownloadsRetentionDays"
    static let whatsAppDownloadsNotify = "whatsAppDownloadsNotify"
    static let whatsAppDownloadsIncludeExisting = "whatsAppDownloadsIncludeExisting"
    static let whatsAppDownloadsAutomaticStartDate = "whatsAppDownloadsAutomaticStartDate"
    static let whatsAppDownloadsLastAutoRun = "whatsAppDownloadsLastAutoRun"
    static let whatsAppDownloadsLastCleanup = "whatsAppDownloadsLastCleanup"
    static let whatsAppDownloadsLastCleanupCount = "whatsAppDownloadsLastCleanupCount"
    static let whatsAppDownloadsLastCleanupBytes = "whatsAppDownloadsLastCleanupBytes"
    static let whatsAppDownloadsLastCleanupFailed = "whatsAppDownloadsLastCleanupFailed"
    static let whatsAppDownloadsLastCleanupAutomatic = "whatsAppDownloadsLastCleanupAutomatic"
    static let whatsAppDownloadsExclusions = "whatsAppDownloadsExclusions" // device:inode ids
    static let whatsAppDownloadsAccessConfirmed = "whatsAppDownloadsAccessConfirmed"
    // Experimental organizer for confirmed WhatsApp downloads.
    static let whatsAppOrganizerEnabled = "whatsAppOrganizerEnabled"
    static let whatsAppOrganizerDestinationPath = "whatsAppOrganizerDestinationPath"
    static let whatsAppOrganizerDelayMinutes = "whatsAppOrganizerDelayMinutes"
    static let whatsAppOrganizerCategories = "whatsAppOrganizerCategories"
    static let whatsAppOrganizerLayout = "whatsAppOrganizerLayout"
    static let whatsAppOrganizerDuplicateAction = "whatsAppOrganizerDuplicateAction"
    static let whatsAppOrganizerRecords = "whatsAppOrganizerRecords"
    static let whatsAppOrganizerUndoTransaction = "whatsAppOrganizerUndoTransaction"
    static let whatsAppOrganizerLastRun = "whatsAppOrganizerLastRun"
    static let whatsAppOrganizerLastMoved = "whatsAppOrganizerLastMoved"
    static let whatsAppOrganizerLastDuplicates = "whatsAppOrganizerLastDuplicates"
    static let whatsAppOrganizerLastFailed = "whatsAppOrganizerLastFailed"
    static let settingsWindowWidth = "settingsWindowWidth"     // last user-chosen content size (0 = unset)
    static let settingsWindowHeight = "settingsWindowHeight"
    static let shelfItems = "shelfItems"                  // Data: [ShelfPersistedItem] JSON
    static let urlCleanerEnabled = "urlCleanerEnabled"
    static let urlCleanerCustomParameters = "urlCleanerCustomParameters"
    static let urlCleanerSiteParameters = "urlCleanerSiteParameters"       // host|name pairs added to one site
    static let urlCleanerDisabledParameters = "urlCleanerDisabledParameters" // built-in host|name pairs switched off
    static let windowMaximizeEnabled = "windowMaximizeEnabled"
    static let windowLayoutHiddenActions = "windowLayoutHiddenActions" // comma-separated action ids hidden from the grid
    static let windowLayoutWindowGap = "windowLayoutWindowGap" // px between adjacent snapped windows
    static let windowLayoutScreenGap = "windowLayoutScreenGap" // px between a snapped window and the visible frame edge
    static let windowLayoutShortcutsEnabled = "windowLayoutShortcutsEnabled"
    static let windowDirectionalEnabled = "windowDirectionalEnabled"
    static let windowDirectionalShortcut = "windowDirectionalShortcut"
    static let windowEdgeSnapEnabled = "windowEdgeSnapEnabled"
    static let windowEdgeSnapDisabledZones = "windowEdgeSnapDisabledZones" // comma-separated visual zone ids
    static let windowGestureEnabled = "windowGestureEnabled"
    static let windowGestureModifiers = "windowGestureModifiers"
    static let windowGestureRaiseWindow = "windowGestureRaiseWindow"
    static let windowLayoutShortcutLeft = "windowLayoutShortcutLeft"
    static let windowLayoutShortcutRight = "windowLayoutShortcutRight"
    static let windowLayoutShortcutTop = "windowLayoutShortcutTop"
    static let windowLayoutShortcutBottom = "windowLayoutShortcutBottom"
    static let windowLayoutShortcutCenterHalf = "windowLayoutShortcutCenterHalf"
    static let windowLayoutShortcutTopLeft = "windowLayoutShortcutTopLeft"
    static let windowLayoutShortcutTopRight = "windowLayoutShortcutTopRight"
    static let windowLayoutShortcutBottomLeft = "windowLayoutShortcutBottomLeft"
    static let windowLayoutShortcutBottomRight = "windowLayoutShortcutBottomRight"
    static let windowLayoutShortcutMaximize = "windowLayoutShortcutMaximize"
    static let windowLayoutShortcutMarginMaximize = "windowLayoutShortcutMarginMaximize"
    static let windowLayoutShortcutCenter = "windowLayoutShortcutCenter"
    static let windowLayoutShortcutRestore = "windowLayoutShortcutRestore"
    static let windowLayoutShortcutLeftThird = "windowLayoutShortcutLeftThird"
    static let windowLayoutShortcutCenterThird = "windowLayoutShortcutCenterThird"
    static let windowLayoutShortcutRightThird = "windowLayoutShortcutRightThird"
    static let windowLayoutShortcutLeftTwoThirds = "windowLayoutShortcutLeftTwoThirds"
    static let windowLayoutShortcutRightTwoThirds = "windowLayoutShortcutRightTwoThirds"
    static let windowLayoutShortcutCenterTwoThirds = "windowLayoutShortcutCenterTwoThirds"
    static let windowLayoutShortcutPreviousDisplay = "windowLayoutShortcutPreviousDisplay"
    static let windowLayoutShortcutNextDisplay = "windowLayoutShortcutNextDisplay"
    static let windowLayoutShortcutFullScreen = "windowLayoutShortcutFullScreen"
    static let windowLayoutShortcutTopLeftSixth = "windowLayoutShortcutTopLeftSixth"
    static let windowLayoutShortcutTopCenterSixth = "windowLayoutShortcutTopCenterSixth"
    static let windowLayoutShortcutTopRightSixth = "windowLayoutShortcutTopRightSixth"
    static let windowLayoutShortcutBottomLeftSixth = "windowLayoutShortcutBottomLeftSixth"
    static let windowLayoutShortcutBottomCenterSixth = "windowLayoutShortcutBottomCenterSixth"
    static let windowLayoutShortcutBottomRightSixth = "windowLayoutShortcutBottomRightSixth"
    static let keyboardDebounceEnabled = "keyboardDebounceEnabled"
    static let keyboardDebounceWindowMs = "keyboardDebounceWindowMs"
    static let keyboardDebounceKeyWindows = "keyboardDebounceKeyWindows" // comma-separated keyCode:ms
    static let panelUtilityCleaning = "panelUtilityCleaning"
    static let cleaningModeKeepScreenVisible = "cleaningModeKeepScreenVisible"
    static let panelUtilityURLCleaner = "panelUtilityURLCleaner"
    static let panelUtilityUninstaller = "panelUtilityUninstaller"
    static let killProcessGroupRelated = "killProcessGroupRelated"
    static let killProcessSortBy = "killProcessSortBy" // cpu | memory | name | pid
    static let killProcessSortAscending = "killProcessSortAscending"
    static let panelUtilityCleaner = "panelUtilityCleaner"
    static let panelUtilityMedia = "panelUtilityMedia"
    static let panelUtilityClipboard = "panelUtilityClipboard"
    static let panelUtilityWindowLayout = "panelUtilityWindowLayout"
    static let panelControlMouseScroll = "panelControlMouseScroll"
    static let panelControlFocusFollowsMouse = "panelControlFocusFollowsMouse"
    static let panelControlMouseNavigation = "panelControlMouseNavigation"
    static let panelControlSwitcher = "panelControlSwitcher"
    static let panelControlDockPreview = "panelControlDockPreview"
    static let panelControlCutPaste = "panelControlCutPaste"
    static let panelControlAutoQuit = "panelControlAutoQuit"
    static let panelControlShelf = "panelControlShelf"
    static let panelControlWindowMaximize = "panelControlWindowMaximize"
    static let panelControlKeyDebounce = "panelControlKeyDebounce"
    static let panelControlDockClick = "panelControlDockClick"
    static let panelControlDockClickHide = "panelControlDockClickHide"
    static let panelControlDockClickCycle = "panelControlDockClickCycle"
    static let panelControlMiddleClick = "panelControlMiddleClick"
    static let panelControlTextSnippets = "panelControlTextSnippets"
    static let panelControlSuperKey = "panelControlSuperKey"
    static let panelControlRadialMenu = "panelControlRadialMenu"
    static let panelControlMouseButtonShortcuts = "panelControlMouseButtonShortcuts"
    static let panelControlMouseAcceleration = "panelControlMouseAcceleration"
    static let panelControlMouseClickDebounce = "panelControlMouseClickDebounce"
    // Quick-control categories start collapsed and remember being opened.
    static let panelControlWindowsExpanded = "panelControlWindowsExpanded"
    static let panelControlInputExpanded = "panelControlInputExpanded"
    static let panelControlFilesExpanded = "panelControlFilesExpanded"
    // Show/hide whole panel sections that have no monitorShow* key of their own.
    static let panelShowKeepAwake = "panelShowKeepAwake"
    static let panelShowBrightness = "panelShowBrightness"
    static let panelShowUtilities = "panelShowUtilities"
    static let panelShowControls = "panelShowControls"

    // System monitor — live metrics shown next to the menu bar icon (opt-in).
    static let menuBarCPU = "menuBarCPU"
    static let menuBarGPU = "menuBarGPU"
    static let menuBarMemory = "menuBarMemory"
    static let menuBarCPUTemperature = "menuBarCPUTemperature"
    static let menuBarGPUTemperature = "menuBarGPUTemperature"
    static let menuBarBatteryTemperature = "menuBarBatteryTemperature"
    static let menuBarTemperature = "menuBarTemperature" // legacy Developer key for the old generic temperature metric
    static let menuBarNetwork = "menuBarNetwork"
    static let menuBarDiskUsage = "menuBarDiskUsage"
    static let menuBarDiskActivity = "menuBarDiskActivity"
    static let menuBarBattery = "menuBarBattery"
    static let menuBarBatteryTime = "menuBarBatteryTime"
    static let menuBarPeripheralBattery = "menuBarPeripheralBattery"
    static let menuBarPower = "menuBarPower"
    static let menuBarFanSpeed = "menuBarFanSpeed"
    static let menuBarPreset = "menuBarPreset"           // dense
    static let menuBarMetricSpacing = "menuBarMetricSpacing" // standard | compact
    static let menuBarMetricAppearance = "menuBarMetricAppearance" // values | bars
    static let menuBarUsageBarNormalColor = "menuBarUsageBarNormalColor" // #RRGGBB
    static let menuBarUsageBarElevatedColor = "menuBarUsageBarElevatedColor" // #RRGGBB
    static let menuBarUsageBarCriticalColor = "menuBarUsageBarCriticalColor" // #RRGGBB
    static let menuBarUsageBarMediumThreshold = "menuBarUsageBarMediumThreshold" // percent
    static let menuBarUsageBarHighThreshold = "menuBarUsageBarHighThreshold" // percent
    static let menuBarHideIconWithMetrics = "menuBarHideIconWithMetrics" // glyph hides while metrics render in the main item
    static let menuBarMetricOrder = "menuBarMetricOrder" // comma-separated MenuBarMetric raw values
    static let menuBarCombineTemperatures = "menuBarCombineTemperatures" // usage/charge + temperature in one block when possible
    static let menuBarSeparateMetrics = "menuBarSeparateMetrics" // one status item per active metric
    static let menuBarNetworkUploadFirst = "menuBarNetworkUploadFirst" // network menu bar block shows upload above download
    static let menuBarLabelStyle = "menuBarLabelStyle"     // compact | classic
    static let menuBarMemoryStyle = "menuBarMemoryStyle"   // dot | percent | both
    static let monitorMemoryMetric = "monitorMemoryMetric" // used | app
    static let monitorInterval = "monitorIntervalSeconds"  // sampling cadence: 1...5
    static let temperatureUnit = "temperatureUnit"          // celsius | fahrenheit
    // System monitor — which blocks appear in the panel.
    static let monitorShowSystem = "monitorShowSystem"
    static let monitorShowNetwork = "monitorShowNetwork"
    static let monitorShowDisk = "monitorShowDisk"
    static let monitorShowPower = "monitorShowPower"
    static let monitorShowMixer = "monitorShowMixer"
    static let panelShowFanControl = "panelShowFanControl"
    static let fanControlMode = "fanControlMode"
    static let fanControlCoolingLevel = "fanControlCoolingLevel"
    static let fanControlCurves = "fanControlCurves"
    // Previous panel visibility key, read once by the migration below.
    static let monitorShowFanControlBeta = "monitorShowFanControlBeta"
    // Machine-only recovery state. A true value means the helper must confirm
    // automatic fan control before this marker can be cleared.
    static let fanControlRecoveryNeeded = "fanControlRecoveryNeeded"
    static let fanControlHelperVersion = "fanControlHelperVersion"
    // System monitor — per-metric history graphs (each independently toggleable).
    static let monitorGraphCPU = "monitorGraphCPU"
    static let monitorGraphGPU = "monitorGraphGPU"
    static let monitorGraphMemory = "monitorGraphMemory"
    static let monitorGraphNetwork = "monitorGraphNetwork"
    static let monitorGraphDisk = "monitorGraphDisk"
    static let monitorGraphPower = "monitorGraphPower"
    static let monitorGraphBattery = "monitorGraphBattery"
    // System monitor — per-item visibility inside each panel section.
    static let monitorSysTemps = "monitorSysTemps"
    static let monitorSysCPU = "monitorSysCPU"
    static let monitorSysGPU = "monitorSysGPU"
    static let monitorSysBattery = "monitorSysBattery"
    static let monitorSysMemory = "monitorSysMemory"
    static let monitorSysAlerts = "monitorSysAlerts"
    static let monitorSysUptime = "monitorSysUptime"
    static let monitorNetSpeed = "monitorNetSpeed"
    static let monitorNetApps = "monitorNetApps"
    static let monitorNetTotals = "monitorNetTotals"
    static let monitorNetAddresses = "monitorNetAddresses"
    static let monitorNetTest = "monitorNetTest"
    static let monitorDiskUsage = "monitorDiskUsage"
    static let monitorDiskActivity = "monitorDiskActivity"
    static let monitorDiskSMART = "monitorDiskSMART"
    static let monitorDiskProtection = "monitorDiskProtection"
    static let monitorDiskTools = "monitorDiskTools"
    static let monitorPwrTemperature = "monitorPwrTemperature"
    static let monitorPwrSystem = "monitorPwrSystem"
    static let monitorPwrAdapter = "monitorPwrAdapter"
    static let monitorPwrBattery = "monitorPwrBattery"
    static let monitorPwrTimeRemaining = "monitorPwrTimeRemaining"
    static let monitorPwrHealth = "monitorPwrHealth"
    // System monitor — optional notifications for sustained or actionable conditions.
    static let monitorAlertCPU = "monitorAlertCPU"
    static let monitorAlertCPUTemperature = "monitorAlertCPUTemperature"
    static let monitorAlertBatteryTemperature = "monitorAlertBatteryTemperature"
    static let monitorAlertMemory = "monitorAlertMemory"
    static let monitorAlertDisk = "monitorAlertDisk"
    static let monitorAlertBattery = "monitorAlertBattery"
    static let monitorAlertCPUThreshold = "monitorAlertCPUThreshold"
    static let monitorAlertCPUTemperatureThreshold = "monitorAlertCPUTemperatureThreshold"
    static let monitorAlertBatteryTemperatureThreshold = "monitorAlertBatteryTemperatureThreshold"
    static let monitorAlertDiskFreePercent = "monitorAlertDiskFreePercent"
    static let monitorAlertBatteryPercent = "monitorAlertBatteryPercent"
    static let monitorAlertCooldownMinutes = "monitorAlertCooldownMinutes"
    // Menu panel layout — the order the major sections appear in and which are
    // collapsed, both comma-joined section ids (see PanelSectionID). Absent keys
    // mean the canonical order and nothing collapsed, so no defaults registration.
    static let panelSectionOrder = "panelSectionOrder"
    static let panelUtilityOrder = "panelUtilityOrder"
    static let panelControlOrder = "panelControlOrder"
    static let panelSystemOrder = "panelSystemOrder"
    static let panelNetworkOrder = "panelNetworkOrder"
    static let panelDiskOrder = "panelDiskOrder"
    static let panelPowerOrder = "panelPowerOrder"
    static let panelNavigationEnabled = "panelNavigationEnabled" // legacy: the panel always navigates by sections since 3.1.8
    static let updateLastInstallFailure = "updateLastInstallFailure" // last installer step that failed (fail-copy etc.)
    static let panelCollapsedSections = "panelCollapsedSections"
    static let panelCollapsedResetVersion = "panelCollapsedResetVersion"

    // Media utility — local video, GIF, image and OCR tools.
    static let mediaLastTool = "mediaLastTool"
    static let mediaVideoStart = "mediaVideoStart"
    static let mediaVideoEnd = "mediaVideoEnd"
    static let mediaVideoQuality = "mediaVideoQuality"
    static let mediaVideoMaxDimension = "mediaVideoMaxDimension"
    static let mediaVideoFPS = "mediaVideoFPS"
    static let mediaVideoKeepAudio = "mediaVideoKeepAudio"
    static let mediaVideoCodec = "mediaVideoCodec"
    static let mediaVideoSizing = "mediaVideoSizing"
    static let mediaVideoTargetMegabytes = "mediaVideoTargetMegabytes"
    static let mediaGIFStart = "mediaGIFStart"
    static let mediaGIFEnd = "mediaGIFEnd"
    static let mediaGIFQuality = "mediaGIFQuality"
    static let mediaGIFWidth = "mediaGIFWidth"
    static let mediaGIFFPS = "mediaGIFFPS"
    static let mediaGIFLoops = "mediaGIFLoops"
    static let mediaGIFSizing = "mediaGIFSizing"
    static let mediaGIFTargetMegabytes = "mediaGIFTargetMegabytes"
    static let mediaImageQuality = "mediaImageQuality"
    static let mediaImageMaxDimension = "mediaImageMaxDimension"
    static let mediaImageFormat = "mediaImageFormat"
    static let mediaImageStripMetadata = "mediaImageStripMetadata"
    static let mediaImageResizeKind = "mediaImageResizeKind"
    static let mediaImageResizeWidth = "mediaImageResizeWidth"
    static let mediaImageResizeHeight = "mediaImageResizeHeight"
    static let mediaImageExactResizeMode = "mediaImageExactResizeMode"
    static let mediaImageWatermarkKind = "mediaImageWatermarkKind"
    static let mediaImageWatermarkText = "mediaImageWatermarkText"
    static let mediaImageWatermarkLogoPath = "mediaImageWatermarkLogoPath"
    static let mediaImageWatermarkPosition = "mediaImageWatermarkPosition"
    static let mediaImageWatermarkOpacity = "mediaImageWatermarkOpacity"
    static let mediaImageWatermarkMargin = "mediaImageWatermarkMargin"
    static let mediaImageWatermarkScale = "mediaImageWatermarkScale"
    static let mediaImageRenamePattern = "mediaImageRenamePattern"
    static let mediaImageBackground = "mediaImageBackground"
    static let mediaImagePreserveModificationDate = "mediaImagePreserveModificationDate"
    static let mediaImageSaveInSubfolder = "mediaImageSaveInSubfolder"
    static let mediaImageProfiles = "mediaImageProfiles"
    static let mediaImageSelectedProfileID = "mediaImageSelectedProfileID"
    static let mediaTextAccurate = "mediaTextAccurate"
    static let mediaTextLanguageCorrection = "mediaTextLanguageCorrection"

    // Clipboard history — text only, opt-in and local.
    static let clipboardHistoryEnabled = "clipboardHistoryEnabled"
    static let clipboardHistoryEntries = "clipboardHistoryEntries"
    static let clipboardHistoryLimit = "clipboardHistoryLimit"
    static let clipboardHistorySkipSensitive = "clipboardHistorySkipSensitive"
    static let clipboardHistoryIncludeImagesFiles = "clipboardHistoryIncludeImagesFiles" // capture copied images and files too
    static let clipboardHistoryIgnoredApps = "clipboardHistoryIgnoredApps" // apps whose copies are never saved
    static let clipboardHistoryQuickPreview = "clipboardHistoryQuickPreview"

    // Auto clear: wipes the system pasteboard on a delay or on sleep and lock.
    // Deliberately outside the clipboardHistory family, since it clears the
    // pasteboard without touching saved entries, and runs with capture off.
    static let clipboardAutoClearOnDelay = "clipboardAutoClearOnDelay"
    static let clipboardAutoClearDelay = "clipboardAutoClearDelaySeconds" // seconds since the last copy
    static let clipboardAutoClearOnSleep = "clipboardAutoClearOnSleep"
    static let clipboardAutoClearOnDisplaySleep = "clipboardAutoClearOnDisplaySleep"
    static let clipboardAutoClearOnScreenLock = "clipboardAutoClearOnScreenLock"

    static let windowPreviewExcludedApps = "windowPreviewExcludedApps" // legacy: split into the two keys below, read only by migration
    static let switcherPreviewExcludedApps = "switcherPreviewExcludedApps" // pause switcher thumbnail capture while these apps are in front
    static let dockPreviewExcludedApps = "dockPreviewExcludedApps" // pause dock preview thumbnail capture while these apps are in front
    static let diskEjectExcludedVolumes = "diskEjectExcludedVolumes" // volume names/UUIDs excluded from Eject all disks
    // Quick tools: paste as plain text, color picker, screen OCR, mic mute.
    static let pastePlainEnabled = "pastePlainEnabled"
    static let pastePlainShortcut = "pastePlainShortcut"
    static let colorPickerShortcutEnabled = "colorPickerShortcutEnabled"
    static let colorPickerShortcut = "colorPickerShortcut"
    static let colorPickerFormat = "colorPickerFormat"       // hex | rgb | hsl | swiftui
    static let colorPickerBareHex = "colorPickerBareHex"     // copy HEX without the leading #
    static let screenOCRShortcutEnabled = "screenOCRShortcutEnabled"
    static let screenOCRShortcut = "screenOCRShortcut"
    static let screenOCRRemoveLineBreaks = "screenOCRRemoveLineBreaks"
    static let screenOCRDetectQRCodes = "screenOCRDetectQRCodes" // QR content wins over OCR text
    static let micMuteShortcutEnabled = "micMuteShortcutEnabled"
    static let micMuteShortcut = "micMuteShortcut"
    static let scratchpadShortcutEnabled = "scratchpadShortcutEnabled"
    static let scratchpadShortcut = "scratchpadShortcut"
    static let cameraPreviewShortcutEnabled = "cameraPreviewShortcutEnabled"
    static let cameraPreviewShortcut = "cameraPreviewShortcut"
    static let commandBarShortcutEnabled = "commandBarShortcutEnabled"
    static let commandBarShortcut = "commandBarShortcut"
    /// Compact mode: an empty field shows nothing but itself. Off by default
    static let commandBarCompactMode = "commandBarCompactMode"
    /// The ASCII layout borrowed while the bar is open, restored on close. Off by default
    static let commandBarASCIILayoutEnabled = "commandBarASCIILayoutEnabled"
    static let commandBarUsage = "commandBarUsage"           // per-command run counts, never queries
    static let commandBarQueryHabits = "commandBarQueryHabits" // keyed query digests → app row ids
    static let commandBarDisabledSources = "commandBarDisabledSources" // kinds of result switched off
    static let commandBarAliases = "commandBarAliases"       // {row id: the name the person gave it}
    static let commandBarPins = "commandBarPins"             // row keys kept at the top, in order
    static let commandBarHidden = "commandBarHidden"         // row keys the person never wants offered
    static let commandBarLinks = "commandBarLinks"           // Data: [CommandBarLink] JSON
    static let commandBarRowShortcuts = "commandBarRowShortcuts" // {row key: shortcut}
    static let commandBarPositionOffset = "commandBarPositionOffset" // "dx,dy" from the default spot
    // The folders a file search looks in, one per line, written with a tilde
    // so an exported list still points somewhere on another Mac. Empty means
    // the bar looks for no files at all, which is the setting out of the box.
    static let commandBarFileScopes = "commandBarFileScopes"
    static let commandBarFileIgnores = "commandBarFileIgnores" // names a file search never shows
    static let panelUtilityCommandBar = "panelUtilityCommandBar"
    static let scratchpadRetention = "scratchpadRetention"   // never | day | week | month
    static let scratchpadCloseOnClickOutside = "scratchpadCloseOnClickOutside"
    static let scratchpadBackgroundOpacity = "scratchpadBackgroundOpacity" // opaque fill over the pad material (ScratchpadSupport.backgroundOpacityRange)
    static let scratchpadDocument = "scratchpadDocument"     // Data: ScratchpadDocument JSON, including named tabs
    static let micMuteActive = "micMuteActive"               // mic muted by the app (survives relaunch)
    static let micMuteSavedVolume = "micMuteSavedVolume"     // input volume to restore on unmute (pre 3.2.0 state)
    static let micMuteSavedVolumes = "micMuteSavedVolumes"   // [device uid: input volume] to restore on unmute
    static let micMuteMutedDevices = "micMuteMutedDevices"   // uids of the devices this app muted
    static let micMuteMenuBarIndicator = "micMuteMenuBarIndicator" // badge the status icon while muted
    static let panelUtilityMicMute = "panelUtilityMicMute"
    static let panelUtilityColorPicker = "panelUtilityColorPicker"
    static let panelUtilityScreenOCR = "panelUtilityScreenOCR"
    static let panelUtilityScratchpad = "panelUtilityScratchpad"
    static let panelUtilityCameraPreview = "panelUtilityCameraPreview"
    static let clipboardHistoryShortcutEnabled = "clipboardHistoryShortcutEnabled"
    static let clipboardHistoryShortcut = "clipboardHistoryShortcut"
    // Mode chooser visibility for dedicated capture shortcuts.
    static let screenshotShowCaptureMenuOnShortcut = "screenshotShowCaptureMenuOnShortcut"
    static let recorderShowCaptureMenuOnShortcut = "recorderShowCaptureMenuOnShortcut"
    static let screenOCRShowCaptureMenuOnShortcut = "screenOCRShowCaptureMenuOnShortcut"
    static let colorPickerShowCaptureMenuOnShortcut = "colorPickerShowCaptureMenuOnShortcut"
    // Screenshot capture and editor.
    static let screenshotShortcutEnabled = "screenshotShortcutEnabled"
    static let screenshotShortcut = "screenshotShortcut"
    static let unifiedScreenCaptureShortcutMigrated = "unifiedScreenCaptureShortcutMigrated"
    static let windowBehaviorUnitMigrated = "windowBehaviorUnitMigrated"
    static let keyboardUnitMigrated = "keyboardUnitMigrated"
    static let urlCleanerUnitMigrated = "urlCleanerUnitMigrated"
    static let metricPlacementMigrated = "metricPlacementMigrated"
    static let restoredScreenCaptureShortcutsMigrated = "restoredScreenCaptureShortcutsMigrated"
    static let orphanedCaptureShortcutMigrated = "orphanedCaptureShortcutMigrated"
    static let screenshotFullScreenShortcutEnabled = "screenshotFullScreenShortcutEnabled"
    static let screenshotFullScreenShortcut = "screenshotFullScreenShortcut"
    static let screenshotLastCaptureShortcutEnabled = "screenshotLastCaptureShortcutEnabled"
    static let screenshotLastCaptureShortcut = "screenshotLastCaptureShortcut"
    static let recentCapturesShortcutEnabled = "recentCapturesShortcutEnabled"
    static let recentCapturesShortcut = "recentCapturesShortcut"
    static let screenshotClipboardShortcutEnabled = "screenshotClipboardShortcutEnabled"
    static let screenshotClipboardShortcut = "screenshotClipboardShortcut"
    static let screenshotFreeze = "screenshotFreeze"
    static let screenshotHideVorssaintWindows = "screenshotHideVorssaintWindows"
    static let screenshotSaveFolder = "screenshotSaveFolder"
    static let screenshotSaveSubfolder = "screenshotSaveSubfolder"
    static let screenshotFileNamePattern = "screenshotFileNamePattern"
    static let screenshotFileNumberStart = "screenshotFileNumberStart"
    static let screenshotFileNumberNext = "screenshotFileNumberNext"
    static let screenshotDefaultAction = "screenshotDefaultAction"
    static let screenshotIncludePointer = "screenshotIncludePointer"
    static let screenshotShowLastRegion = "screenshotShowLastRegion"
    static let screenshotLoupeStartsOn = "screenshotLoupeStartsOn"
    static let screenshotLoupeRememberZoom = "screenshotLoupeRememberZoom"
    static let screenshotLoupeDefaultZoom = "screenshotLoupeDefaultZoom"
    static let screenshotLoupeLastZoom = "screenshotLoupeLastZoom"
    static let screenshotLoupeSteppedZoomByDefault = "screenshotLoupeSteppedZoomByDefault"
    static let screenshotDownscale = "screenshotDownscale"
    static let screenshotDelay = "screenshotDelay"
    static let screenshotLastTool = "screenshotLastTool"
    static let screenshotLastColor = "screenshotLastColor"
    static let screenshotLastStroke = "screenshotLastStroke"
    static let screenshotLastArrowStyle = "screenshotLastArrowStyle"
    static let screenshotLastSticker = "screenshotLastSticker"
    static let screenshotAnnotationShadows = "screenshotAnnotationShadows"
    static let screenshotToolOrder = "screenshotToolOrder"
    static let screenshotToolShortcutsEnabled = "screenshotToolShortcutsEnabled"
    static let screenshotBackdropStyle = "screenshotBackdropStyle"
    static let screenshotBackdropPresets = "screenshotBackdropPresets"
    static let screenshotWatermarkStyle = "screenshotWatermarkStyle"
    static let screenshotWatermarkPresets = "screenshotWatermarkPresets"
    static let screenshotOpenEditorDirectly = "screenshotOpenEditorDirectly"
    static let screenshotCopyToClipboard = "screenshotCopyToClipboard"
    static let screenshotPreviewPosition = "screenshotPreviewPosition"
    static let screenshotPreviewTakesFocus = "screenshotPreviewTakesFocus"
    static let screenshotSharingEnabled = "screenshotSharingEnabled"
    // Retired upload preferences remain named only for migration and backup filtering.
    static let screenshotSharingDeveloperEndpoint = "screenshotSharingDeveloperEndpoint"
    static let panelUtilityScreenshot = "panelUtilityScreenshot"

    // Screen recorder - records the picked area, keeps the untouched master
    // in Application Support until retention sweeps it.
    static let recorderShortcutEnabled = "recorderShortcutEnabled"
    static let recorderShortcut = "recorderShortcut"
    static let recorderCountdown = "recorderCountdown"
    static let recorderQuality = "recorderQuality"
    static let recorderFrameRate = "recorderFrameRate"
    static let recorderSystemAudio = "recorderSystemAudio"
    static let recorderMicrophone = "recorderMicrophone"
    // Machine state, never exported: whether this Mac's audio system has let
    // a recording hear the Mac's sound through a process tap.
    static let recorderSystemAudioTapVerified = "recorderSystemAudioTapVerified"
    static let recorderSaveFolder = "recorderSaveFolder"
    static let recorderOpenEditor = "recorderOpenEditor"
    static let recorderAutomaticZoom = "recorderAutomaticZoom"
    static let recorderGIFSize = "recorderGIFSize"
    static let recorderGIFFrameRate = "recorderGIFFrameRate"
    static let recorderEditorPresets = "recorderEditorPresets"
    static let panelUtilityScreenRecorder = "panelUtilityScreenRecorder"
    static let panelUtilityPortManager = "panelUtilityPortManager"


    // Text snippets: type a trigger, get the expansion.
    static let textSnippetsEnabled = "textSnippetsEnabled"
    static let textSnippets = "textSnippets"              // Data: [TextSnippet] JSON
    static let snippetLibraryEnabled = "snippetLibraryEnabled"
    static let snippetLibraryShortcut = "snippetLibraryShortcut"
    static let snippetSoundEnabled = "snippetSoundEnabled"
    static let snippetSoundName = "snippetSoundName"

    // Radial menu: a wheel of actions on a shortcut.
    static let radialMenuEnabled = "radialMenuEnabled"
    static let radialMenuShortcut = "radialMenuShortcut"
    static let radialMenuAtPointer = "radialMenuAtPointer" // false: screen center
    static let radialMenuMouseButton = "radialMenuMouseButton" // RadialMenuMouseTrigger.rawValue
    static let radialMenuActivationMode = "radialMenuActivationMode" // RadialMenuActivationMode.rawValue
    static let radialMenuItems = "radialMenuItems"        // Data: [RadialMenuItem] JSON
    static let trackpadSpreadProfile = "trackpadSpreadProfile" // UUID string; empty disables the gesture
    static let mouseLinearSpeed = "mouseLinearSpeed" // 0 preserves the device setting; otherwise 0.1...10
    static let radialMenuProfiles = "radialMenuProfiles"  // Data: [RadialMenuProfile] JSON

    // Dev-build only: force the "update available" UI for local testing.
    static let simulateUpdate = "simulateUpdate"
    static let simulateBetaUI = "simulateBetaUI"

    /// Features hub availability layer, one key per FeatureUnit raw value.
    /// Registered true: an uninstalled unit vanishes from every surface and
    /// holds no resources, without ever touching its members' enable keys.
    static func unitAvailable(_ id: String) -> String { "unitAvailable.\(id)" }
    /// The per-feature availability that units replaced; read once by
    /// `Defaults.migrateFeatureUnits` and deleted.
    static func featureAvailable(_ id: String) -> String { "featureAvailable.\(id)" }

    // Resource-owning members that can stop independently of their unit.
    static let fanControlEnabled = "fanControlEnabled"
    static let mixerEnabled = "mixerEnabled"
    // Retired availability gates, accepted only for upgrades and old backups.
    static let screenshotEnabled = "screenshotEnabled"
    static let recorderEnabled = "recorderEnabled"
    static let colorPickerEnabled = "colorPickerEnabled"
    static let screenOCREnabled = "screenOCREnabled"
    static let scrollInverterSwitchEnabled = "scrollInverterSwitchEnabled"
    static let mouseButtonShortcutsSwitchEnabled = "mouseButtonShortcutsSwitchEnabled"
    static let finderCutPasteSwitchEnabled = "finderCutPasteSwitchEnabled"
    static let quitProtectionSwitchEnabled = "quitProtectionSwitchEnabled"
    static let textSnippetsSwitchEnabled = "textSnippetsSwitchEnabled"
    static let dockClickEnabled = "dockClickEnabled"
}

/// Bump `currentFeatureSet` when first-run feature defaults need a quiet marker.
enum OnboardingInfo {
    // 2: system monitor, configurable panel and menu bar metrics.
    // 3: app languages and support settings.
    // 4: navigable menu panel sections.
    static let currentFeatureSet = 4
}

/// The one-time tour of a release's headline features, shown right after the
/// update. Each row deep links to the exact Settings page or opens the tool
/// itself, so a new feature is one click from being tried instead of buried.
enum UpdateHighlightsInfo {
    /// The release whose first launch shows the tour. A patch of that release
    /// shows the same tour to whoever skipped it and to nobody who already saw
    /// it; any other version never shows it. Bump deliberately for releases
    /// with headline features worth a tour.
    static let releaseVersion = "3.3.3"

    static func shouldShow(appVersion: String, lastSeenVersion: String?) -> Bool {
        let matches = appVersion == releaseVersion
            || appVersion.hasPrefix("\(releaseVersion)-")
            || (AppInfo.isDeveloperBuild && appVersion.hasPrefix(releaseVersion))
            || isPatch(appVersion, of: releaseVersion)
        return matches && lastSeenVersion != releaseVersion
    }

    /// Same major and minor with a later patch: 3.3.4 patches 3.3.3, 3.4.0 does not.
    private static func isPatch(_ version: String, of release: String) -> Bool {
        guard let version = UpdateServiceSupport.SemanticVersion(raw: version),
              let release = UpdateServiceSupport.SemanticVersion(raw: release) else { return false }
        return (version.major, version.minor) == (release.major, release.minor)
            && version.patch > release.patch
    }
}

enum SupportUpdateIntroInfo {
    /// The single release whose first launch shows the update intro. It used
    /// to track AppInfo.version, which re-showed the ask on every update; now a
    /// release only shows it when this constant is deliberately bumped.
    static let releaseVersion = "3.3.2"

    static func shouldShow(appVersion: String, lastSeenVersion: String?) -> Bool {
        appVersion == releaseVersion && lastSeenVersion != releaseVersion
    }
}

enum SupportUpdateIntroStep: CaseIterable, Hashable {
    case support
    case social

    var next: SupportUpdateIntroStep? {
        switch self {
        case .support: return .social
        case .social: return nil
        }
    }

    var previous: SupportUpdateIntroStep? {
        switch self {
        case .support: return nil
        case .social: return .support
        }
    }
}

enum KeepAwakeIconTint: String, CaseIterable, Identifiable {
    case orange, green, blue, purple, pink, none

    var id: String { rawValue }

    static var current: KeepAwakeIconTint {
        Defaults.sanitizedKeepAwakeIconTint(
            UserDefaults.standard.string(forKey: DefaultsKey.keepAwakeIconTint)
        )
    }

    func title(_ strings: Strings) -> String {
        switch self {
        case .orange: return strings.keepAwakeIconTintOrange
        case .green: return strings.keepAwakeIconTintGreen
        case .blue: return strings.keepAwakeIconTintBlue
        case .purple: return strings.keepAwakeIconTintPurple
        case .pink: return strings.keepAwakeIconTintPink
        case .none: return strings.keepAwakeIconTintNone
        }
    }
}

enum KeepAwakeActiveIcon: String, CaseIterable, Identifiable {
    case vorssaint, coffee, eye, moon, light

    var id: String { rawValue }

    static var current: KeepAwakeActiveIcon {
        Defaults.sanitizedKeepAwakeActiveIcon(
            UserDefaults.standard.string(forKey: DefaultsKey.keepAwakeActiveIcon)
        )
    }

    var systemSymbolName: String? {
        switch self {
        case .vorssaint: return nil
        case .coffee: return "cup.and.saucer.fill"
        case .eye: return "eye.fill"
        case .moon: return "moon.fill"
        case .light: return "lightbulb.fill"
        }
    }

    /// Nudge down the menu bar canvas, in points. Symbols carrying their mass
    /// above the shape's middle — steam over a cup, a bulb over its base — read
    /// as sitting high when their ink is centered geometrically.
    var menuBarDrop: CGFloat {
        switch self {
        case .coffee: return 1
        case .light: return 0.5
        case .vorssaint, .eye, .moon: return 0
        }
    }

    func title(_ strings: Strings) -> String {
        switch self {
        case .vorssaint: return strings.keepAwakeActiveIconVorssaint
        case .coffee: return strings.keepAwakeActiveIconCoffee
        case .eye: return strings.keepAwakeActiveIconEye
        case .moon: return strings.keepAwakeActiveIconMoon
        case .light: return strings.keepAwakeActiveIconLight
        }
    }
}

/// Thumbnail size for the app switcher and Dock preview, each from its own
/// preference. Captures scale by the same factor, so larger previews stay
/// sharp.
enum PreviewSizing {
    static func sanitized(_ value: String) -> String {
        Defaults.allowedPreviewSizes.contains(value) ? value : "normal"
    }

    static func scale(for value: String) -> CGFloat {
        switch sanitized(value) {
        case "small": return 0.75
        case "large": return 1.4
        case "xlarge": return 1.8
        default: return 1.0
        }
    }

    static var switcherScale: CGFloat { scale(forKey: DefaultsKey.switcherPreviewSize) }
    static var dockScale: CGFloat { scale(forKey: DefaultsKey.dockPreviewSize) }

    static func scale(forKey key: String) -> CGFloat {
        scale(for: UserDefaults.standard.string(forKey: key) ?? "normal")
    }
}

enum Defaults {
    static let finderBundleIdentifier = "com.apple.finder"
    // Quitting Phone during a window-less incoming Continuity call disconnects it.
    static let phoneBundleIdentifier = "com.apple.mobilephone"
    static let mandatoryAutoQuitExceptionBundleIDs = [finderBundleIdentifier, phoneBundleIdentifier]

    static let allowedDurations = [0, 15, 30, 60, 120, 240, 480]
    static let allowedKeepAwakeMouseJiggleIntervals = [1, 2, 5, 10, 15]
    static let allowedBatteryLimits = [0, 5, 10, 15, 20]
    static let allowedMonitorIntervals = [1, 2, 3, 4, 5]
    static let defaultKeyboardDebounceWindowMs = 5
    static let defaultSnippetSoundName = "Tink"
    static let allowedKeyboardDebounceWindowRange = 0...500
    /// Stepper increment for the keyboard debounce window. Kept at 1 ms so
    /// magnetic-keyboard users can pick values below the old 5 ms UI step
    /// without changing the stored range (issue #1551).
    static let keyboardDebounceWindowStep = 1
    static let defaultMouseClickDebounceWindowMs = 25
    static let allowedMouseClickDebounceWindowRange = 5...100
    static let allowedMenuBarPresets = ["dense"]
    static let allowedMenuBarMetricSpacings = ["standard", "compact"]
    static let allowedMenuBarMetricAppearances = ["values", "bars"]
    static let defaultMenuBarMetricOrder = [
        "cpu", "cpuTemperature",
        "gpu", "gpuTemperature",
        "memory",
        "battery", "batteryTime", "batteryTemperature", "peripheralBattery",
        "network", "diskUsage", "diskActivity", "power", "fanSpeed",
    ]
    static let allowedMenuBarLabelStyles = ["compact", "classic"]
    static let allowedMenuBarMemoryStyles = ["dot", "percent", "both"]
    static let allowedMonitorMemoryMetrics = ["used", "app"]
    static let allowedPreviewSizes = ["small", "normal", "large", "xlarge"]
    static let allowedClipboardHistoryLimits = [20, 50, 100, 250, 500, 1_000, 10_000, 0]
    static let allowedClipboardAutoClearDelayRange = 5...3_600
    static let defaultClipboardAutoClearDelay = 20
    static let allowedMonitorAlertCooldowns = [2, 5, 15, 30, 60]

    static let registeredDefaults: [String: Any] = [
        DefaultsKey.appearance: AppAppearance.fallback.rawValue,
        DefaultsKey.clamshellPreferred: false,
        DefaultsKey.defaultDuration: 0,
        DefaultsKey.batteryLimit: 10,
        DefaultsKey.keepAwakeAutoStart: false,
        DefaultsKey.keepAwakeRightClickToggle: false,
        DefaultsKey.keepAwakeAllowDisplaySleep: false,
        DefaultsKey.keepAwakeExternalDisplay: false,
        DefaultsKey.keepAwakeConnectedToPower: false,
        DefaultsKey.keepAwakeRunningApps: false,
        DefaultsKey.keepAwakeRunningAppBundleIDs: [String](),
        DefaultsKey.keepAwakePauseWhenLocked: false,
        DefaultsKey.keepAwakeMouseJiggleEnabled: false,
        DefaultsKey.keepAwakeMouseJiggleInterval: 5,
        DefaultsKey.hotkeyEnabled: true,
        DefaultsKey.launchAtLoginWanted: false,
        DefaultsKey.keepAwakeShortcut: "control+option+command:40",
        DefaultsKey.keepAwakeIconTint: KeepAwakeIconTint.orange.rawValue,
        DefaultsKey.keepAwakeActiveIcon: KeepAwakeActiveIcon.vorssaint.rawValue,
        DefaultsKey.showCountdown: false,
        DefaultsKey.scrollInverterEnabled: false,
        DefaultsKey.scrollInverterHorizontalEnabled: false,
        DefaultsKey.scrollHorizontalEnabled: false,
        DefaultsKey.scrollHorizontalModifier: ScrollHorizontalModifier.shift.rawValue,
        DefaultsKey.focusFollowsMouseEnabled: false,
        DefaultsKey.focusFollowsMouseDelay: FocusFollowsMouseSupport.defaultDelayMilliseconds,
        DefaultsKey.smoothScrollEnabled: false,
        DefaultsKey.smoothScrollStep: 40,
        DefaultsKey.mouseAccelerationDisabled: false,
        DefaultsKey.mouseLinearSpeed: 0.0,
        DefaultsKey.trackpadSpreadProfile: "",
        DefaultsKey.smoothScrollResponse: SmoothScrollSupport.defaultResponse,
        DefaultsKey.mouseNavigationEnabled: false,
        DefaultsKey.mouseButtonShortcutsEnabled: false,
        DefaultsKey.mouseButtonShortcuts: [String: String](),
        DefaultsKey.mouseSpacesGestureEnabled: false,
        DefaultsKey.mouseSpacesGestureButton: 0,
        DefaultsKey.mouseSpacesGestureFollowsDrag: false,
        DefaultsKey.mouseClickDebounceEnabled: false,
        DefaultsKey.mouseClickDebounceWindowMs: defaultMouseClickDebounceWindowMs,
        DefaultsKey.superKeyEnabled: false,
        DefaultsKey.superKeySource: SuperKeySource.capsLock.rawValue,
        DefaultsKey.superKeyModifiers: SuperKeySupport.defaultModifierStorageValue,
        DefaultsKey.superKeySoloAction: SuperKeySoloAction.none.rawValue,
        DefaultsKey.smoothScrollExceptions: [String](),
        DefaultsKey.scrollInverterExceptions: [String](),
        DefaultsKey.focusFollowsMouseExceptions: [String](),
        DefaultsKey.mouseNavigationExceptions: [String](),
        DefaultsKey.mouseButtonExceptions: [String](),
        DefaultsKey.middleClickExceptions: [String](),
        DefaultsKey.superKeyExceptions: [String](),
        DefaultsKey.switcherEnabled: true,
        DefaultsKey.switcherTakeOverSystemShortcuts: false,
        DefaultsKey.switcherShortcut: "command:48",
        DefaultsKey.switcherWindowShortcut: GlobalShortcut.switcherWindowDefault.storageValue,
        DefaultsKey.switcherIconRowMode: false,
        DefaultsKey.switcherSimpleMode: false,
        DefaultsKey.switcherMergeTabs: false,
        DefaultsKey.switcherShowWindowlessFinder: true,
        DefaultsKey.switcherWindowlessApps: SwitcherWindowlessApps.fallback.rawValue,
        DefaultsKey.switcherMinimizedPlacement: WindowSwitchMinimizedPlacement.normal.rawValue,
        DefaultsKey.switcherShowFullscreenWindows: true,
        DefaultsKey.switcherAppRules: [String: String](),
        DefaultsKey.switcherCurrentSpaceOnly: false,
        DefaultsKey.switcherSearchPinEnabled: false,
        DefaultsKey.switcherShowShortcutHints: true,
        DefaultsKey.switcherAppearanceDelay: SwitcherSupport.defaultAppearanceDelayMilliseconds,
        DefaultsKey.switcherScreenPlacement: SwitcherScreenPlacement.fallback.rawValue,
        DefaultsKey.switcherCurrentDisplayOnly: false,
        DefaultsKey.dockPreviewEnabled: false,
        DefaultsKey.dockPreviewKeepDockVisible: false,
        DefaultsKey.dockPreviewBackgroundOpacity: 1.0,
        DefaultsKey.dockPreviewOpenDelay: DockPreviewSupport.defaultOpenDelayMilliseconds,
        DefaultsKey.dockPreviewQuitAppOnClose: false,
        DefaultsKey.dockClickMinimize: false,
        DefaultsKey.dockClickHide: false,
        DefaultsKey.dockClickCycleWindows: false,
        DefaultsKey.middleClickEnabled: false,
        DefaultsKey.middleClickTapFingers: 0,
        DefaultsKey.switcherPreviewSize: "normal",
        DefaultsKey.dockPreviewSize: "normal",
        DefaultsKey.autoCheckUpdates: true,
        DefaultsKey.releaseNotesOnUpdate: true,
        DefaultsKey.updateShowcaseIntroVersion: "",
        DefaultsKey.updateShowcaseMediaOverride: "",
        DefaultsKey.mixerShowFinder: true,
        DefaultsKey.mixerHideInactiveApps: false,
        DefaultsKey.mixerLowerVolumeOnHeadphonesDisconnect: false,
        DefaultsKey.mixerHeadphonesDisconnectVolumePercent: defaultMixerHeadphonesDisconnectVolumePercent,
        DefaultsKey.preciseVolumeRollerEnabled: false,
        DefaultsKey.soundOutputSwitcherEnabled: false,
        DefaultsKey.soundOutputSwitcherShortcut: GlobalShortcut.soundOutputSwitcherDefault.storageValue,
        // Finder never benefits from being "quit" (it just relaunches), so
        // it's excepted out of the box.
        DefaultsKey.autoQuitExceptions: mandatoryAutoQuitExceptionBundleIDs,
        DefaultsKey.quitProtectionQuitEnabled: false,
        DefaultsKey.quitProtectionQuitMode: QuitProtectionMode.hold.rawValue,
        DefaultsKey.quitProtectionQuitHoldDurationMs: QuitProtectionSupport.defaultHoldDurationMilliseconds,
        DefaultsKey.quitProtectionQuitDoubleIntervalMs: QuitProtectionSupport.defaultDoublePressIntervalMilliseconds,
        DefaultsKey.quitProtectionQuitExtraModifier: QuitProtectionExtraModifier.shift.rawValue,
        DefaultsKey.quitProtectionQuitScope: QuitProtectionScope.all.rawValue,
        DefaultsKey.quitProtectionQuitExceptions: [String](),
        DefaultsKey.quitProtectionQuitShowFeedback: true,
        DefaultsKey.quitProtectionCloseEnabled: false,
        DefaultsKey.quitProtectionCloseMode: QuitProtectionMode.hold.rawValue,
        DefaultsKey.quitProtectionCloseHoldDurationMs: QuitProtectionSupport.defaultHoldDurationMilliseconds,
        DefaultsKey.quitProtectionCloseDoubleIntervalMs: QuitProtectionSupport.defaultDoublePressIntervalMilliseconds,
        DefaultsKey.quitProtectionCloseExtraModifier: QuitProtectionExtraModifier.shift.rawValue,
        DefaultsKey.quitProtectionCloseScope: QuitProtectionScope.all.rawValue,
        DefaultsKey.quitProtectionCloseExceptions: [String](),
        DefaultsKey.quitProtectionCloseShowFeedback: true,
        // When the shelf is on, the shake gesture is on too (still toggleable).
        DefaultsKey.shelfShortcutEnabled: true,
        DefaultsKey.shelfShortcut: "control+option+command:2",
        DefaultsKey.shelfShakeToOpen: true,
        // On by default (owner's call): it costs nothing until the shelf itself
        // is on, and then the shelf lives handily under the menu bar icon.
        DefaultsKey.shelfDropZoneEnabled: true,
        DefaultsKey.shelfDockPlacement: "menuBar",
        // New Shelf behavior stays opt-in for existing users.
        DefaultsKey.shelfEdgeDragEnabled: false,
        // Closing after a drop is new behavior, so it arrives OFF for people
        // who already rely on the panel staying put; removing after a drop
        // keeps the value shipped releases always had.
        DefaultsKey.shelfCloseAfterDrop: false,
        DefaultsKey.shelfRemoveAfterDrop: true,
        DefaultsKey.shelfClearOnClose: false,
        DefaultsKey.shelfAutomaticExclusions: [String](),
        DefaultsKey.brightnessKeysEnabled: false,
        DefaultsKey.brightnessOSDEnabled: false,
        BrightnessShortcutPreferenceKey.enabled: false,
        BrightnessShortcutPreferenceKey.decrease: "shift+command:27",
        BrightnessShortcutPreferenceKey.increase: "shift+command:24",
        DefaultsKey.keyboardBrightnessShortcutsEnabled: false,
        DefaultsKey.keyboardBrightnessDecreaseShortcut: "option+command:27",
        DefaultsKey.keyboardBrightnessIncreaseShortcut: "option+command:24",
        DefaultsKey.bluetoothSleepEnabled: false,
        DefaultsKey.bluetoothSleepRestoreOnWake: true,
        DefaultsKey.bluetoothSleepRestorePending: false,
        DefaultsKey.musicBlockEnabled: false,
        DefaultsKey.musicBlockBundleIDs: MusicLaunchSupport.defaultBlockedBundleIDs,
        DefaultsKey.musicBlockReplacementPath: "",
        DefaultsKey.cleanerScheduleFrequency: "off",
        DefaultsKey.cleanerScheduleHour: 9,
        DefaultsKey.cleanerScheduleMinute: 0,
        DefaultsKey.cleanerScheduleWeekday: 2,
        DefaultsKey.cleanerScheduleNotify: true,
        DefaultsKey.cleanerLastAutoRun: 0.0,
        DefaultsKey.cleanerLastAutoFreed: 0,
        DefaultsKey.whatsAppDownloadsEnabled: false,
        DefaultsKey.whatsAppDownloadsAutomaticEnabled: false,
        DefaultsKey.whatsAppDownloadsCategories: "image,video,audio",
        DefaultsKey.whatsAppDownloadsRetentionDays: 7,
        DefaultsKey.whatsAppDownloadsNotify: true,
        DefaultsKey.whatsAppDownloadsIncludeExisting: false,
        DefaultsKey.whatsAppDownloadsAutomaticStartDate: 0.0,
        DefaultsKey.whatsAppDownloadsLastAutoRun: 0.0,
        DefaultsKey.whatsAppDownloadsLastCleanup: 0.0,
        DefaultsKey.whatsAppDownloadsLastCleanupCount: 0,
        DefaultsKey.whatsAppDownloadsLastCleanupBytes: 0,
        DefaultsKey.whatsAppDownloadsLastCleanupFailed: 0,
        DefaultsKey.whatsAppDownloadsLastCleanupAutomatic: false,
        DefaultsKey.whatsAppDownloadsExclusions: [String](),
        DefaultsKey.whatsAppDownloadsAccessConfirmed: false,
        DefaultsKey.whatsAppOrganizerEnabled: false,
        DefaultsKey.whatsAppOrganizerDestinationPath: "",
        DefaultsKey.whatsAppOrganizerDelayMinutes: 5,
        DefaultsKey.whatsAppOrganizerCategories: "image,video,audio,document,archive,other",
        DefaultsKey.whatsAppOrganizerLayout: "flat",
        DefaultsKey.whatsAppOrganizerDuplicateAction: "trashNew",
        DefaultsKey.whatsAppOrganizerRecords: Data(),
        DefaultsKey.whatsAppOrganizerUndoTransaction: Data(),
        DefaultsKey.whatsAppOrganizerLastRun: 0.0,
        DefaultsKey.whatsAppOrganizerLastMoved: 0,
        DefaultsKey.whatsAppOrganizerLastDuplicates: 0,
        DefaultsKey.whatsAppOrganizerLastFailed: 0,
        DefaultsKey.urlCleanerEnabled: false,
        DefaultsKey.urlCleanerCustomParameters: "",
        DefaultsKey.urlCleanerSiteParameters: "",
        DefaultsKey.urlCleanerDisabledParameters: "",
        DefaultsKey.textSnippetsEnabled: false,
        DefaultsKey.snippetLibraryEnabled: false,
        DefaultsKey.snippetLibraryShortcut: GlobalShortcut.snippetLibraryDefault.storageValue,
        DefaultsKey.snippetSoundEnabled: false,
        DefaultsKey.snippetSoundName: defaultSnippetSoundName,
        DefaultsKey.radialMenuEnabled: false,
        DefaultsKey.radialMenuShortcut: GlobalShortcut.radialMenuDefault.storageValue,
        DefaultsKey.radialMenuAtPointer: true,
        DefaultsKey.radialMenuMouseButton: RadialMenuMouseTrigger.off.rawValue,
        DefaultsKey.radialMenuActivationMode: RadialMenuActivationMode.pressOrHold.rawValue,
        DefaultsKey.windowMaximizeEnabled: false,
        DefaultsKey.windowLayoutHiddenActions: "",
        DefaultsKey.windowLayoutWindowGap: 0,
        DefaultsKey.windowLayoutScreenGap: 0,
        DefaultsKey.windowLayoutShortcutsEnabled: false,
        DefaultsKey.windowDirectionalEnabled: false,
        DefaultsKey.windowDirectionalShortcut: GlobalShortcut.windowDirectionalDefault.storageValue,
        DefaultsKey.windowEdgeSnapEnabled: false,
        DefaultsKey.windowEdgeSnapDisabledZones: "",
        DefaultsKey.windowGestureEnabled: false,
        DefaultsKey.windowGestureModifiers: WindowGestureSupport.defaultModifierStorageValue,
        DefaultsKey.windowGestureRaiseWindow: false,
        DefaultsKey.windowLayoutShortcutLeft: GlobalShortcut.windowLayoutLeftDefault.storageValue,
        DefaultsKey.windowLayoutShortcutRight: GlobalShortcut.windowLayoutRightDefault.storageValue,
        DefaultsKey.windowLayoutShortcutTop: GlobalShortcut.windowLayoutTopDefault.storageValue,
        DefaultsKey.windowLayoutShortcutBottom: GlobalShortcut.windowLayoutBottomDefault.storageValue,
        DefaultsKey.windowLayoutShortcutCenterHalf: WindowLayoutAction.clearedShortcutStorageValue,
        DefaultsKey.windowLayoutShortcutTopLeft: GlobalShortcut.windowLayoutTopLeftDefault.storageValue,
        DefaultsKey.windowLayoutShortcutTopRight: GlobalShortcut.windowLayoutTopRightDefault.storageValue,
        DefaultsKey.windowLayoutShortcutBottomLeft: GlobalShortcut.windowLayoutBottomLeftDefault.storageValue,
        DefaultsKey.windowLayoutShortcutBottomRight: GlobalShortcut.windowLayoutBottomRightDefault.storageValue,
        DefaultsKey.windowLayoutShortcutMaximize: GlobalShortcut.windowLayoutMaximizeDefault.storageValue,
        DefaultsKey.windowLayoutShortcutMarginMaximize: WindowLayoutAction.clearedShortcutStorageValue,
        DefaultsKey.windowLayoutShortcutCenter: GlobalShortcut.windowLayoutCenterDefault.storageValue,
        DefaultsKey.windowLayoutShortcutRestore: GlobalShortcut.windowLayoutRestoreDefault.storageValue,
        DefaultsKey.windowLayoutShortcutLeftThird: GlobalShortcut.windowLayoutLeftThirdDefault.storageValue,
        DefaultsKey.windowLayoutShortcutCenterThird: GlobalShortcut.windowLayoutCenterThirdDefault.storageValue,
        DefaultsKey.windowLayoutShortcutRightThird: GlobalShortcut.windowLayoutRightThirdDefault.storageValue,
        DefaultsKey.windowLayoutShortcutLeftTwoThirds: GlobalShortcut.windowLayoutLeftTwoThirdsDefault.storageValue,
        DefaultsKey.windowLayoutShortcutRightTwoThirds: GlobalShortcut.windowLayoutRightTwoThirdsDefault.storageValue,
        DefaultsKey.windowLayoutShortcutCenterTwoThirds: WindowLayoutAction.clearedShortcutStorageValue,
        DefaultsKey.windowLayoutShortcutPreviousDisplay: WindowLayoutAction.clearedShortcutStorageValue,
        DefaultsKey.windowLayoutShortcutNextDisplay: GlobalShortcut.windowLayoutNextDisplayDefault.storageValue,
        DefaultsKey.windowLayoutShortcutTopLeftSixth: WindowLayoutAction.clearedShortcutStorageValue,
        DefaultsKey.windowLayoutShortcutTopCenterSixth: WindowLayoutAction.clearedShortcutStorageValue,
        DefaultsKey.windowLayoutShortcutTopRightSixth: WindowLayoutAction.clearedShortcutStorageValue,
        DefaultsKey.windowLayoutShortcutBottomLeftSixth: WindowLayoutAction.clearedShortcutStorageValue,
        DefaultsKey.windowLayoutShortcutBottomCenterSixth: WindowLayoutAction.clearedShortcutStorageValue,
        DefaultsKey.windowLayoutShortcutBottomRightSixth: WindowLayoutAction.clearedShortcutStorageValue,
        DefaultsKey.windowLayoutShortcutFullScreen: WindowLayoutAction.clearedShortcutStorageValue,
        DefaultsKey.keyboardDebounceEnabled: false,
        DefaultsKey.keyboardDebounceWindowMs: defaultKeyboardDebounceWindowMs,
        DefaultsKey.keyboardDebounceKeyWindows: "",
        DefaultsKey.panelUtilityCleaning: true,
        DefaultsKey.cleaningModeKeepScreenVisible: false,
        DefaultsKey.panelUtilityURLCleaner: true,
        DefaultsKey.panelUtilityUninstaller: true,
        DefaultsKey.killProcessGroupRelated: true,
        DefaultsKey.killProcessSortBy: "cpu",
        DefaultsKey.killProcessSortAscending: false,
        DefaultsKey.panelUtilityCleaner: true,
        DefaultsKey.panelUtilityMedia: true,
        DefaultsKey.panelUtilityClipboard: true,
        DefaultsKey.panelUtilityWindowLayout: true,
        DefaultsKey.panelControlMouseScroll: true,
        DefaultsKey.panelControlFocusFollowsMouse: true,
        DefaultsKey.panelControlMouseNavigation: true,
        DefaultsKey.panelControlSwitcher: true,
        DefaultsKey.panelControlDockPreview: true,
        DefaultsKey.panelControlCutPaste: true,
        DefaultsKey.panelControlAutoQuit: true,
        DefaultsKey.panelControlShelf: true,
        DefaultsKey.panelControlWindowMaximize: true,
        DefaultsKey.panelControlKeyDebounce: true,
        DefaultsKey.panelControlDockClick: true,
        DefaultsKey.panelControlDockClickHide: true,
        DefaultsKey.panelControlDockClickCycle: true,
        DefaultsKey.panelControlMiddleClick: true,
        DefaultsKey.panelControlTextSnippets: true,
        DefaultsKey.panelControlSuperKey: true,
        DefaultsKey.panelControlRadialMenu: true,
        DefaultsKey.panelControlMouseButtonShortcuts: true,
        DefaultsKey.panelControlMouseAcceleration: true,
        DefaultsKey.panelControlMouseClickDebounce: true,
        DefaultsKey.panelControlWindowsExpanded: false,
        DefaultsKey.panelControlInputExpanded: false,
        DefaultsKey.panelControlFilesExpanded: false,
        DefaultsKey.panelShowKeepAwake: true,
        DefaultsKey.panelShowBrightness: true,
        DefaultsKey.panelShowUtilities: true,
        DefaultsKey.panelShowControls: true,
        // Menu bar metrics start off (the icon stays clean) and are opt-in.
        // The panel shows every monitoring block by default; users hide what
        // they don't want.
        DefaultsKey.monitorInterval: 2,
        "monitorHistoryMinutes": 1,
        "monitorGraphFan": true,
        DefaultsKey.temperatureUnit: TemperatureUnit.celsius.rawValue,
        DefaultsKey.menuBarCPUTemperature: false,
        DefaultsKey.menuBarGPUTemperature: false,
        DefaultsKey.menuBarBatteryTemperature: false,
        DefaultsKey.menuBarBatteryTime: false,
        DefaultsKey.menuBarDiskUsage: false,
        DefaultsKey.menuBarDiskActivity: false,
        DefaultsKey.menuBarPeripheralBattery: false,
        DefaultsKey.menuBarFanSpeed: false,
        DefaultsKey.menuBarPreset: "dense",
        DefaultsKey.menuBarMetricSpacing: "compact",  // owner's call: compact by default in 3.1.8
        DefaultsKey.menuBarMetricAppearance: "values",
        DefaultsKey.menuBarUsageBarNormalColor: "#64D2FF",
        DefaultsKey.menuBarUsageBarElevatedColor: "#FFD60A",
        DefaultsKey.menuBarUsageBarCriticalColor: "#FF453A",
        DefaultsKey.menuBarUsageBarMediumThreshold: 70,
        DefaultsKey.menuBarUsageBarHighThreshold: 90,
        DefaultsKey.menuBarHideIconWithMetrics: false,
        DefaultsKey.menuBarMetricOrder: defaultMenuBarMetricOrder.joined(separator: ","),
        DefaultsKey.menuBarCombineTemperatures: true,
        DefaultsKey.menuBarSeparateMetrics: false,
        DefaultsKey.menuBarNetworkUploadFirst: false,
        DefaultsKey.menuBarLabelStyle: "compact",
        DefaultsKey.menuBarMemoryStyle: "percent",
        DefaultsKey.monitorMemoryMetric: "used",
        DefaultsKey.monitorShowSystem: true,
        DefaultsKey.monitorShowNetwork: true,
        DefaultsKey.monitorShowDisk: true,
        DefaultsKey.monitorShowPower: true,
        DefaultsKey.monitorShowMixer: true,
        DefaultsKey.panelShowFanControl: true,
        // Each switch ships as the feature's former availability did: on,
        // except the fan control opt-in.
        DefaultsKey.fanControlEnabled: false,
        DefaultsKey.fanControlMode: FanControlMode.system.rawValue,
        DefaultsKey.fanControlCoolingLevel: FanControlPolicy.defaultCoolingLevel,
        DefaultsKey.fanControlCurves: FanControlConfiguration.defaultCurvesStorage,
        DefaultsKey.fanControlRecoveryNeeded: false,
        DefaultsKey.fanControlHelperVersion: "",
        DefaultsKey.panelNavigationEnabled: true,
        DefaultsKey.monitorGraphCPU: true,
        DefaultsKey.monitorGraphGPU: true,
        DefaultsKey.monitorGraphMemory: true,
        DefaultsKey.monitorGraphNetwork: true,
        DefaultsKey.monitorGraphDisk: true,
        DefaultsKey.monitorGraphPower: true,
        DefaultsKey.monitorGraphBattery: true,
        // Every per-item block shows by default; users hide what they don't want.
        DefaultsKey.monitorSysTemps: true,
        DefaultsKey.monitorSysCPU: true,
        DefaultsKey.monitorSysGPU: true,
        DefaultsKey.monitorSysBattery: true,
        DefaultsKey.monitorSysMemory: true,
        DefaultsKey.monitorSysAlerts: true,
        DefaultsKey.monitorSysUptime: true,
        DefaultsKey.monitorNetSpeed: true,
        DefaultsKey.monitorNetApps: true,
        DefaultsKey.monitorNetTotals: true,
        DefaultsKey.monitorNetAddresses: true,
        DefaultsKey.monitorNetTest: true,
        DefaultsKey.monitorDiskUsage: true,
        DefaultsKey.monitorDiskActivity: true,
        DefaultsKey.monitorDiskSMART: true,
        DefaultsKey.monitorDiskProtection: true,
        DefaultsKey.monitorDiskTools: true,
        DefaultsKey.monitorPwrTemperature: true,
        DefaultsKey.monitorPwrSystem: true,
        DefaultsKey.monitorPwrAdapter: true,
        DefaultsKey.monitorPwrBattery: true,
        DefaultsKey.monitorPwrTimeRemaining: true,
        DefaultsKey.monitorPwrHealth: true,
        DefaultsKey.monitorAlertCPU: false,
        DefaultsKey.monitorAlertCPUTemperature: false,
        DefaultsKey.monitorAlertBatteryTemperature: false,
        DefaultsKey.monitorAlertMemory: false,
        DefaultsKey.monitorAlertDisk: false,
        DefaultsKey.monitorAlertBattery: false,
        DefaultsKey.monitorAlertCPUThreshold: 90,
        DefaultsKey.monitorAlertCPUTemperatureThreshold: 90,
        DefaultsKey.monitorAlertBatteryTemperatureThreshold: 40,
        DefaultsKey.monitorAlertDiskFreePercent: 10,
        DefaultsKey.monitorAlertBatteryPercent: 15,
        DefaultsKey.monitorAlertCooldownMinutes: 15,
        DefaultsKey.mediaLastTool: MediaTool.videoCompressor.rawValue,
        DefaultsKey.mediaVideoStart: 0.0,
        DefaultsKey.mediaVideoEnd: 0.0,
        DefaultsKey.mediaVideoQuality: 0.68,
        DefaultsKey.mediaVideoMaxDimension: 1280,
        DefaultsKey.mediaVideoFPS: 30.0,
        DefaultsKey.mediaVideoKeepAudio: true,
        DefaultsKey.mediaVideoCodec: MediaVideoCodec.h264.rawValue,
        DefaultsKey.mediaVideoSizing: MediaSizingMode.resolution.rawValue,
        DefaultsKey.mediaVideoTargetMegabytes: 20,
        DefaultsKey.mediaGIFStart: 0.0,
        DefaultsKey.mediaGIFEnd: 0.0,
        DefaultsKey.mediaGIFQuality: 0.74,
        DefaultsKey.mediaGIFWidth: 720,
        DefaultsKey.mediaGIFFPS: 12.0,
        DefaultsKey.mediaGIFLoops: true,
        DefaultsKey.mediaGIFSizing: MediaSizingMode.resolution.rawValue,
        DefaultsKey.mediaGIFTargetMegabytes: 10,
        DefaultsKey.mediaImageQuality: 0.72,
        DefaultsKey.mediaImageMaxDimension: 1600,
        DefaultsKey.mediaImageFormat: MediaImageFormat.jpeg.rawValue,
        DefaultsKey.mediaImageStripMetadata: true,
        DefaultsKey.mediaImageResizeKind: MediaImageResizeKind.maxDimension.rawValue,
        DefaultsKey.mediaImageResizeWidth: 1600,
        DefaultsKey.mediaImageResizeHeight: 1200,
        DefaultsKey.mediaImageExactResizeMode: MediaImageExactResizeMode.stretch.rawValue,
        DefaultsKey.mediaImageWatermarkKind: MediaImageWatermarkKind.off.rawValue,
        DefaultsKey.mediaImageWatermarkText: "",
        DefaultsKey.mediaImageWatermarkLogoPath: "",
        DefaultsKey.mediaImageWatermarkPosition: MediaImageWatermarkPosition.bottomRight.rawValue,
        DefaultsKey.mediaImageWatermarkOpacity: 0.45,
        DefaultsKey.mediaImageWatermarkMargin: 32,
        DefaultsKey.mediaImageWatermarkScale: 0.18,
        DefaultsKey.mediaImageRenamePattern: "",
        DefaultsKey.mediaImageBackground: MediaImageBackground.transparent.rawValue,
        DefaultsKey.mediaImagePreserveModificationDate: false,
        DefaultsKey.mediaImageSaveInSubfolder: false,
        DefaultsKey.mediaImageProfiles: "[]",
        DefaultsKey.mediaImageSelectedProfileID: "",
        DefaultsKey.mediaTextAccurate: true,
        DefaultsKey.mediaTextLanguageCorrection: true,
        DefaultsKey.clipboardHistoryEnabled: false,
        DefaultsKey.clipboardHistoryLimit: 50,
        DefaultsKey.clipboardHistorySkipSensitive: true,
        DefaultsKey.clipboardHistoryIncludeImagesFiles: true,
        DefaultsKey.clipboardHistoryIgnoredApps: [String](),
        DefaultsKey.clipboardHistoryQuickPreview: false,
        DefaultsKey.clipboardAutoClearOnDelay: false,
        DefaultsKey.clipboardAutoClearDelay: Defaults.defaultClipboardAutoClearDelay,
        DefaultsKey.clipboardAutoClearOnSleep: false,
        DefaultsKey.clipboardAutoClearOnDisplaySleep: false,
        DefaultsKey.clipboardAutoClearOnScreenLock: false,
        DefaultsKey.finderCutPasteShowHUD: true,
        DefaultsKey.finderPasteImageAsFile: false,
        DefaultsKey.switcherPreviewExcludedApps: [String](),
        DefaultsKey.dockPreviewExcludedApps: [String](),
        DefaultsKey.diskEjectExcludedVolumes: [String](),
        DefaultsKey.pastePlainEnabled: false,
        DefaultsKey.pastePlainShortcut: GlobalShortcut.pastePlainDefault.storageValue,
        DefaultsKey.finderRenameEnabled: false,
        DefaultsKey.finderRenameShortcut: GlobalShortcut.finderRenameDefault.storageValue,
        DefaultsKey.colorPickerShortcutEnabled: false,
        DefaultsKey.colorPickerShortcut: GlobalShortcut.colorPickerDefault.storageValue,
        DefaultsKey.colorPickerFormat: "hex",
        DefaultsKey.colorPickerBareHex: false,
        DefaultsKey.screenOCRShortcutEnabled: false,
        DefaultsKey.screenOCRShortcut: GlobalShortcut.screenOCRDefault.storageValue,
        DefaultsKey.screenOCRRemoveLineBreaks: false,
        DefaultsKey.screenOCRDetectQRCodes: true,
        DefaultsKey.micMuteShortcutEnabled: false,
        DefaultsKey.micMuteShortcut: GlobalShortcut.micMuteDefault.storageValue,
        DefaultsKey.scratchpadShortcutEnabled: false,
        DefaultsKey.scratchpadShortcut: GlobalShortcut.scratchpadDefault.storageValue,
        DefaultsKey.cameraPreviewShortcutEnabled: false,
        DefaultsKey.cameraPreviewShortcut: GlobalShortcut.cameraPreviewDefault.storageValue,
        DefaultsKey.commandBarShortcutEnabled: false,
        DefaultsKey.commandBarCompactMode: false,
        DefaultsKey.commandBarASCIILayoutEnabled: false,
        DefaultsKey.commandBarDisabledSources: "",
        DefaultsKey.commandBarAliases: "",
        DefaultsKey.commandBarPins: "",
        DefaultsKey.commandBarHidden: "",
        DefaultsKey.commandBarFileScopes: "",
        DefaultsKey.commandBarFileIgnores: "",
        DefaultsKey.commandBarShortcut: GlobalShortcut.commandBarDefault.storageValue,
        DefaultsKey.commandBarPositionOffset: "",
        DefaultsKey.panelUtilityCommandBar: true,
        DefaultsKey.scratchpadRetention: ScratchpadRetention.never.rawValue,
        DefaultsKey.scratchpadCloseOnClickOutside: true,
        DefaultsKey.scratchpadBackgroundOpacity: 0.0,
        DefaultsKey.micMuteActive: false,
        DefaultsKey.micMuteSavedVolume: 0.75,
        DefaultsKey.micMuteMenuBarIndicator: true,  // owner's call: on by default in 3.1.8 (badge only shows while muted)
        DefaultsKey.panelUtilityMicMute: true,
        DefaultsKey.panelUtilityColorPicker: true,
        DefaultsKey.panelUtilityScreenOCR: true,
        DefaultsKey.panelUtilityScratchpad: true,
        DefaultsKey.panelUtilityCameraPreview: true,
        DefaultsKey.clipboardHistoryShortcutEnabled: true,
        DefaultsKey.clipboardHistoryShortcut: GlobalShortcut.clipboardDefault.storageValue,
        DefaultsKey.recorderShortcutEnabled: false,
        DefaultsKey.recorderShortcut: GlobalShortcut.screenRecorderDefault.storageValue,
        DefaultsKey.recorderCountdown: 3,
        DefaultsKey.recorderQuality: RecorderSupport.Quality.balanced.rawValue,
        DefaultsKey.recorderFrameRate: 60,
        DefaultsKey.recorderSystemAudio: true,
        DefaultsKey.recorderMicrophone: false,
        DefaultsKey.recorderSaveFolder: "",
        DefaultsKey.recorderOpenEditor: true,
        DefaultsKey.recorderAutomaticZoom: true,
        DefaultsKey.recorderGIFSize: RecorderSupport.GIFSize.medium.rawValue,
        DefaultsKey.recorderGIFFrameRate: 12,
        DefaultsKey.recorderEditorPresets: Data(),
        DefaultsKey.panelUtilityScreenRecorder: true,
        DefaultsKey.panelUtilityPortManager: true,
        DefaultsKey.screenshotShowCaptureMenuOnShortcut: true,
        DefaultsKey.recorderShowCaptureMenuOnShortcut: true,
        DefaultsKey.screenOCRShowCaptureMenuOnShortcut: true,
        DefaultsKey.colorPickerShowCaptureMenuOnShortcut: true,
        DefaultsKey.screenshotShortcutEnabled: false,
        DefaultsKey.screenshotShortcut: GlobalShortcut.screenshotDefault.storageValue,
        DefaultsKey.unifiedScreenCaptureShortcutMigrated: false,
        DefaultsKey.windowBehaviorUnitMigrated: false,
        DefaultsKey.keyboardUnitMigrated: false,
        DefaultsKey.urlCleanerUnitMigrated: false,
        DefaultsKey.metricPlacementMigrated: false,
        DefaultsKey.restoredScreenCaptureShortcutsMigrated: false,
        DefaultsKey.screenshotFullScreenShortcutEnabled: false,
        DefaultsKey.screenshotFullScreenShortcut: GlobalShortcut.screenshotFullScreenDefault.storageValue,
        DefaultsKey.screenshotLastCaptureShortcutEnabled: false,
        DefaultsKey.screenshotLastCaptureShortcut: GlobalShortcut.screenshotLastCaptureDefault.storageValue,
        DefaultsKey.recentCapturesShortcutEnabled: false,
        DefaultsKey.recentCapturesShortcut: GlobalShortcut.recentCapturesDefault.storageValue,
        DefaultsKey.screenshotClipboardShortcutEnabled: false,
        DefaultsKey.screenshotClipboardShortcut: GlobalShortcut.screenshotClipboardDefault.storageValue,
        DefaultsKey.screenshotFreeze: true,
        DefaultsKey.screenshotHideVorssaintWindows: true,
        DefaultsKey.screenshotSaveFolder: "",
        DefaultsKey.screenshotSaveSubfolder: "",
        DefaultsKey.screenshotFileNamePattern: "",
        DefaultsKey.screenshotFileNumberStart: 1,
        DefaultsKey.screenshotFileNumberNext: 1,
        DefaultsKey.screenshotDefaultAction: "",
        DefaultsKey.screenshotIncludePointer: false,
        DefaultsKey.screenshotShowLastRegion: true,
        DefaultsKey.screenshotLoupeStartsOn: false,
        DefaultsKey.screenshotLoupeRememberZoom: false,
        DefaultsKey.screenshotLoupeDefaultZoom: 1.0,
        DefaultsKey.screenshotLoupeLastZoom: 1.0,
        DefaultsKey.screenshotLoupeSteppedZoomByDefault: false,
        DefaultsKey.screenshotDownscale: false,
        DefaultsKey.screenshotDelay: 0,
        DefaultsKey.screenshotLastTool: "arrow",
        DefaultsKey.screenshotLastColor: "red",
        DefaultsKey.screenshotLastStroke: "medium",
        DefaultsKey.screenshotLastArrowStyle: "filled",
        DefaultsKey.screenshotLastSticker: "check",
        DefaultsKey.screenshotAnnotationShadows: false,
        DefaultsKey.screenshotToolOrder: ScreenshotSupport.Tool.defaultOrderStorage,
        DefaultsKey.screenshotToolShortcutsEnabled: true,
        DefaultsKey.screenshotBackdropStyle: "",
        DefaultsKey.screenshotBackdropPresets: "[]",
        DefaultsKey.screenshotWatermarkStyle: "",
        DefaultsKey.screenshotWatermarkPresets: "[]",
        DefaultsKey.screenshotOpenEditorDirectly: false,
        DefaultsKey.screenshotCopyToClipboard: false,
        DefaultsKey.screenshotPreviewPosition: ScreenshotSupport.QuickPreviewPosition.automatic.rawValue,
        DefaultsKey.screenshotPreviewTakesFocus: true,
        DefaultsKey.panelUtilityScreenshot: true,
    ]

    static func register(in defaults: UserDefaults = .standard) {
        migrateFanControlVisibility(in: defaults)
        migrateMetricPlacementSwitches(in: defaults)
        migrateFeatureUnits(in: defaults)
        migrateBrightnessModuleGate(in: defaults)
        migrateMixerSwitch(in: defaults)
        migrateWindowBehaviorUnit(in: defaults)
        migrateKeyboardUnit(in: defaults)
        migrateURLCleanerUnit(in: defaults)
        migrateDroppedFeatures(in: defaults)
        migrateScrollInverterAxes(in: defaults)
        migrateWhatsAppDownloadsEnabled(in: defaults)
        migrateBatteryTemperatureVisibility(in: defaults)
        defaults.register(defaults: registeredDefaults)
        defaults.register(defaults: FeatureUnit.availabilityDefaults)
        migrateLegacyMenuBarTemperatureMetric(in: defaults)
        migrateLegacySwitcherWindowShortcut(in: defaults)
        migrateLegacyKeyboardDebounceWindow(in: defaults)
        migrateUtilityOrderForScreenshot(in: defaults)
        migrateScreenshotOpenEditorDirectly(in: defaults)
        migrateUnifiedScreenCaptureShortcut(in: defaults)
        migrateRestoredScreenCaptureShortcuts(in: defaults)
        migrateOrphanedCaptureShortcut(in: defaults)
        migrateRetiredFeatureSwitches(in: defaults)
        migrateSilentHeadphonesDisconnectVolume(in: defaults)
        migrateSwitcherWindowlessFinder(in: defaults)
        migrateSplitWindowPreviewPreferences(in: defaults)
    }

    static func migrateBrightnessModuleGate(in defaults: UserDefaults) {
        let legacy = defaults.object(forKey: DefaultsKey.brightnessControlEnabled) as? Bool
        guard legacy != nil || !defaults.bool(forKey: DefaultsKey.brightnessModuleGateMigrated) else { return }
        let available = defaults.object(forKey: FeatureUnit.brightness.availabilityKey) as? Bool ?? true
        defaults.set(available && (legacy ?? false), forKey: FeatureUnit.brightness.availabilityKey)
        defaults.removeObject(forKey: DefaultsKey.brightnessControlEnabled)
        defaults.set(true, forKey: DefaultsKey.brightnessModuleGateMigrated)
    }

    /// The mixer's own switch duplicated its unit: the output switcher cannot work
    /// without the mixer, so switching the mixer off already left the unit idle.
    /// A saved off becomes an uninstalled unit. The key is kept for old backups.
    static func migrateMixerSwitch(in defaults: UserDefaults) {
        if defaults.object(forKey: DefaultsKey.mixerEnabled) as? Bool == false {
            defaults.set(false, forKey: FeatureUnit.mixer.availabilityKey)
        }
        defaults.removeObject(forKey: DefaultsKey.mixerEnabled)
    }

    static func migrateBatteryTemperatureVisibility(in defaults: UserDefaults) {
        guard defaults.object(forKey: DefaultsKey.monitorPwrTemperature) == nil else { return }
        defaults.set(defaults.object(forKey: DefaultsKey.monitorSysTemps) as? Bool ?? true,
                     forKey: DefaultsKey.monitorPwrTemperature)
    }

    /// The downloads cleanup for a messaging app used to sit in Cleaner for
    /// everyone. Keep it visible only when someone already turned automatic
    /// cleanup or the organizer on; everyone else gets the new off-by-default
    /// choice.
    static func migrateWhatsAppDownloadsEnabled(in defaults: UserDefaults) {
        guard defaults.object(forKey: DefaultsKey.whatsAppDownloadsEnabled) == nil else {
            return
        }
        let alreadyUsing = defaults.bool(forKey: DefaultsKey.whatsAppDownloadsAutomaticEnabled)
            || defaults.bool(forKey: DefaultsKey.whatsAppOrganizerEnabled)
        if alreadyUsing {
            defaults.set(true, forKey: DefaultsKey.whatsAppDownloadsEnabled)
        }
    }

    /// The former single switch also reversed vertical wheel events redirected
    /// sideways with Shift. Mirror that choice once so updates and older
    /// settings backups keep the same behavior until the user separates axes.
    static func migrateScrollInverterAxes(in defaults: UserDefaults) {
        guard defaults.object(forKey: DefaultsKey.scrollInverterHorizontalEnabled) == nil else {
            return
        }
        defaults.set(defaults.bool(forKey: DefaultsKey.scrollInverterEnabled),
                     forKey: DefaultsKey.scrollInverterHorizontalEnabled)
    }

    static func migrateFanControlVisibility(in defaults: UserDefaults) {
        if let oldValue = defaults.object(forKey: DefaultsKey.monitorShowFanControlBeta) as? Bool {
            if defaults.object(forKey: DefaultsKey.panelShowFanControl) == nil {
                defaults.set(oldValue, forKey: DefaultsKey.panelShowFanControl)
            }
            if oldValue,
               defaults.object(forKey: DefaultsKey.fanControlEnabled) == nil {
                defaults.set(true, forKey: DefaultsKey.fanControlEnabled)
            }
        }
        defaults.removeObject(forKey: DefaultsKey.monitorShowFanControlBeta)
    }

    /// One preview size and one exclusion list used to serve both the App
    /// Switcher and Dock Preview. Each now has its own pair; a stored value is
    /// copied to both so neither changes under the user, and the old keys go
    /// so this runs once.
    static func migrateSplitWindowPreviewPreferences(in defaults: UserDefaults) {
        if let size = defaults.string(forKey: DefaultsKey.previewSize) {
            defaults.set(size, forKey: DefaultsKey.switcherPreviewSize)
            defaults.set(size, forKey: DefaultsKey.dockPreviewSize)
        }
        if let excluded = defaults.stringArray(forKey: DefaultsKey.windowPreviewExcludedApps) {
            defaults.set(excluded, forKey: DefaultsKey.switcherPreviewExcludedApps)
            defaults.set(excluded, forKey: DefaultsKey.dockPreviewExcludedApps)
        }
        defaults.removeObject(forKey: DefaultsKey.previewSize)
        defaults.removeObject(forKey: DefaultsKey.windowPreviewExcludedApps)
    }

    /// Availability moved from features to units. A unit is installed when
    /// any member was. A member that was uninstalled on its own inside a
    /// unit that stays installed keeps that as its switch or, lacking one,
    /// has its enable keys cleared: installs never touch those, so it would
    /// otherwise come back to life. A switch above enable keys is on only
    /// when one of them is, so it reads as what it does. Deleting the old
    /// keys is what makes this run once; a setup with none (clean, or older
    /// than the hub) keeps the registered unit defaults.
    /// Preferences of features this app no longer has. Nothing reads them, so
    /// removing them changes no behavior; leaving them would keep the
    /// preferences file and every settings backup carrying dead weight.
    static let droppedFeatureKeys: [String] = [
        // Disk image installer
        DefaultsKey.featureAvailable("diskImageInstaller"),
        DefaultsKey.unitAvailable("diskImageInstaller"),
        "diskImageInstallerTrashesDownload",
        "diskImageInstallerRevealsApp",
        // Retired capture uploads.
        "recorderSharingEnabled",
        DefaultsKey.screenshotSharingEnabled,
        DefaultsKey.screenshotSharingDeveloperEndpoint,
        // App updates (other apps', never this one's)
        DefaultsKey.featureAvailable("appUpdates"),
        DefaultsKey.unitAvailable("appUpdates"),
        "panelUtilityAppUpdates",
        "appUpdatesCheckFrequency",
        "appUpdatesIncludeHomebrewApps",
        "appUpdatesIncludeAppStore",
        "appUpdatesIncludeOnlineCatalog",
        "appUpdatesNotify",
        "appUpdatesLastCheck",
        "appUpdatesLastCount",
        "appUpdatesNotifiedIDs",
        // Extra brightness (its unit was shared with brightness, which stays)
        DefaultsKey.featureAvailable("extraBrightness"),
        "extraBrightnessEnabled",
        "extraBrightnessLevel",
        // Minimal window previews
        "minimalWindowPreviews",
        // The packages page is a read-only list now, so it has no panel tile.
        "panelUtilityHomebrew",
    ]

    /// The six read-only metrics lost their switch: where they are placed is
    /// the switch now. Someone who had one switched off keeps not seeing it,
    /// so its placement and its alerts travel to off with it.
    static func migrateMetricPlacementSwitches(in defaults: UserDefaults) {
        guard !defaults.bool(forKey: DefaultsKey.metricPlacementMigrated) else { return }
        defaults.set(true, forKey: DefaultsKey.metricPlacementMigrated)
        let retired: [(feature: AppFeature, switchKey: String, placement: [String])] = [
            (.monitorCPU, "monitorCPUEnabled", [DefaultsKey.menuBarCPU, DefaultsKey.menuBarCPUTemperature,
                                   DefaultsKey.monitorSysCPU, DefaultsKey.monitorAlertCPU,
                                   DefaultsKey.monitorAlertCPUTemperature]),
            (.monitorGPU, "monitorGPUEnabled", [DefaultsKey.menuBarGPU, DefaultsKey.menuBarGPUTemperature,
                                   DefaultsKey.monitorSysGPU]),
            (.monitorMemory, "monitorMemoryEnabled", [DefaultsKey.menuBarMemory, DefaultsKey.monitorSysMemory,
                                      DefaultsKey.monitorAlertMemory]),
            (.monitorNetwork, "monitorNetworkEnabled", [DefaultsKey.menuBarNetwork, DefaultsKey.monitorShowNetwork]),
            (.monitorDisk, "monitorDiskEnabled", [DefaultsKey.menuBarDiskUsage, DefaultsKey.menuBarDiskActivity,
                                    DefaultsKey.monitorShowDisk, DefaultsKey.monitorAlertDisk]),
            (.monitorPower, "monitorPowerEnabled", [DefaultsKey.menuBarPower, DefaultsKey.menuBarBattery,
                                     DefaultsKey.menuBarBatteryTime, DefaultsKey.menuBarBatteryTemperature,
                                     DefaultsKey.menuBarPeripheralBattery, DefaultsKey.monitorShowPower,
                                     DefaultsKey.monitorSysBattery, DefaultsKey.monitorAlertBattery,
                                     DefaultsKey.monitorAlertBatteryTemperature]),
        ]
        for entry in retired {
            // Two generations answer for "the user had this off": the switch
            // this migration retires, and the per-feature availability key
            // `migrateFeatureUnits` retires right after. Read both before
            // either is gone.
            let legacyKey = DefaultsKey.featureAvailable(entry.feature.rawValue)
            let wasOff = defaults.object(forKey: entry.switchKey) as? Bool == false
                || defaults.object(forKey: legacyKey) as? Bool == false
            if wasOff {
                for key in entry.placement { defaults.set(false, forKey: key) }
            }
            defaults.removeObject(forKey: entry.switchKey)
        }
    }

    static func migrateDroppedFeatures(in defaults: UserDefaults) {
        for key in droppedFeatureKeys { defaults.removeObject(forKey: key) }
    }

    static func migrateFeatureUnits(in defaults: UserDefaults) {
        let former = AppFeature.allCases.compactMap { feature in
            (defaults.object(forKey: DefaultsKey.featureAvailable(feature.rawValue)) as? Bool)
                .map { (feature: feature, wasAvailable: $0) }
        }
        for unit in FeatureUnit.allCases {
            let members = former.filter { $0.feature.unit == unit }
            guard !members.isEmpty else { continue }
            defaults.set(members.contains(where: \.wasAvailable), forKey: unit.availabilityKey)
        }
        for (feature, wasAvailable) in former {
            if let key = feature.switchKey ?? retiredFeatureSwitchKeys[feature] {
                defaults.set(wasAvailable && feature.isEngaged(in: defaults), forKey: key)
            } else if !wasAvailable, defaults.bool(forKey: feature.unit.availabilityKey) {
                feature.enabledKeys.forEach { defaults.set(false, forKey: $0) }
            }
            defaults.removeObject(forKey: DefaultsKey.featureAvailable(feature.rawValue))
        }
    }

    /// Legacy state is consumed again when an old backup is imported. No
    /// version flag can replace removing the keys: a restored off gate must
    /// still stop actions after this Mac has already upgraded once.
    static let retiredFeatureSwitchKeys: [AppFeature: String] = [
        .scrollInverter: DefaultsKey.scrollInverterSwitchEnabled,
        .mouseButtonShortcuts: DefaultsKey.mouseButtonShortcutsSwitchEnabled,
        .finderCutPaste: DefaultsKey.finderCutPasteSwitchEnabled,
        .quitWindowProtection: DefaultsKey.quitProtectionSwitchEnabled,
        .textSnippets: DefaultsKey.textSnippetsSwitchEnabled,
        .dockClick: DefaultsKey.dockClickEnabled,
        .screenshot: DefaultsKey.screenshotEnabled,
        .screenRecorder: DefaultsKey.recorderEnabled,
        .screenOCR: DefaultsKey.screenOCREnabled,
        .colorPicker: DefaultsKey.colorPickerEnabled,
    ]

    static func migrateRetiredFeatureSwitches(in defaults: UserDefaults) {
        let disabled = Set(retiredFeatureSwitchKeys.compactMap { feature, key in
            (defaults.object(forKey: key) as? Bool) == false ? feature : nil
        })
        for feature in disabled {
            let keys: [String]
            switch feature {
            case .screenshot:
                keys = [DefaultsKey.screenshotShortcutEnabled,
                        DefaultsKey.screenshotFullScreenShortcutEnabled,
                        DefaultsKey.screenshotLastCaptureShortcutEnabled,
                        DefaultsKey.screenshotClipboardShortcutEnabled]
            case .screenRecorder: keys = [DefaultsKey.recorderShortcutEnabled]
            case .screenOCR: keys = [DefaultsKey.screenOCRShortcutEnabled]
            case .colorPicker: keys = [DefaultsKey.colorPickerShortcutEnabled]
            default: keys = feature.enabledKeys
            }
            for key in keys { defaults.set(false, forKey: key) }
        }
        if disabled.contains(.screenshot), disabled.contains(.screenRecorder) {
            defaults.set(false, forKey: DefaultsKey.recentCapturesShortcutEnabled)
        }
        for key in retiredFeatureSwitchKeys.values { defaults.removeObject(forKey: key) }
    }

    /// Window maximizer and quit/close protection became one unit, Window
    /// behaviour. The merged unit is installed when either half was, and the
    /// protection carries its own former state on the member switch its
    /// shared page gave it. A maximizer that was uninstalled has its enable
    /// key cleared, the way `migrateFeatureUnits` clears one, so it cannot
    /// come back to life inside a unit that stays installed. Deleting the two
    /// old keys is what makes this run once.
    static func migrateWindowBehaviorUnit(in defaults: UserDefaults) {
        guard !defaults.bool(forKey: DefaultsKey.windowBehaviorUnitMigrated) else { return }
        defaults.set(true, forKey: DefaultsKey.windowBehaviorUnitMigrated)
        let quitKey = DefaultsKey.unitAvailable("quitProtection")
        let maximizerKey = DefaultsKey.unitAvailable("windowMaximizer")
        let autoQuitKey = DefaultsKey.unitAvailable("autoQuit")
        let quit = defaults.object(forKey: quitKey) as? Bool
        let maximizer = defaults.object(forKey: maximizerKey) as? Bool
        let autoQuit = defaults.object(forKey: autoQuitKey) as? Bool
        // Any of the three installed installs the merged unit. A member that
        // was uninstalled has its enable key cleared, the way
        // `migrateFeatureUnits` clears one, so it cannot come back to life
        // inside a unit that stays.
        if quit != nil || maximizer != nil || autoQuit != nil {
            defaults.set(quit == true || maximizer == true || autoQuit == true,
                         forKey: FeatureUnit.windowBehavior.availabilityKey)
            if maximizer == false { defaults.set(false, forKey: DefaultsKey.windowMaximizeEnabled) }
            if autoQuit == false { defaults.set(false, forKey: DefaultsKey.autoQuitEnabled) }
            defaults.removeObject(forKey: quitKey)
            defaults.removeObject(forKey: maximizerKey)
            defaults.removeObject(forKey: autoQuitKey)
        }
        // Protection had no member switch before, so it gets one that reads as
        // what it does: on for a setup that had ⌘Q or ⌘W protected, off for
        // everyone else. A setup that never touched the hub has no unit key,
        // and the shortcuts still answer for it.
        if quit == false {
            defaults.set(false, forKey: DefaultsKey.quitProtectionSwitchEnabled)
        } else if defaults.object(forKey: DefaultsKey.quitProtectionSwitchEnabled) == nil {
            defaults.set(AppFeature.quitWindowProtection.isEngaged(in: defaults),
                         forKey: DefaultsKey.quitProtectionSwitchEnabled)
        }
    }

    /// Key debounce, snippets and the super key each had a unit and a page of
    /// their own; they are now the three members of one keyboard page. Any of
    /// them installed installs the merged unit, and a member that was
    /// uninstalled has its enable keys cleared so it cannot come back to life
    /// inside a unit that stays.
    static func migrateKeyboardUnit(in defaults: UserDefaults) {
        guard !defaults.bool(forKey: DefaultsKey.keyboardUnitMigrated) else { return }
        defaults.set(true, forKey: DefaultsKey.keyboardUnitMigrated)
        let legacy: [(key: String, enableKeys: [String])] = [
            (DefaultsKey.unitAvailable("keyDebounce"), [DefaultsKey.keyboardDebounceEnabled]),
            (DefaultsKey.unitAvailable("textSnippets"),
             [DefaultsKey.textSnippetsEnabled, DefaultsKey.snippetLibraryEnabled]),
            (DefaultsKey.unitAvailable("superKey"), [DefaultsKey.superKeyEnabled]),
        ]
        let stored = legacy.map { defaults.object(forKey: $0.key) as? Bool }
        if stored.contains(where: { $0 != nil }) {
            defaults.set(stored.contains(true), forKey: FeatureUnit.keyboard.availabilityKey)
            for (index, entry) in legacy.enumerated() where stored[index] == false {
                for key in entry.enableKeys { defaults.set(false, forKey: key) }
            }
            for entry in legacy { defaults.removeObject(forKey: entry.key) }
        }
        // Snippets had no member switch before, because it was a page of its
        // own: it gets one that reads as what it was doing, with its two
        // toggles staying as the options underneath.
        if stored[1] == false {
            defaults.set(false, forKey: DefaultsKey.textSnippetsSwitchEnabled)
        } else if defaults.object(forKey: DefaultsKey.textSnippetsSwitchEnabled) == nil {
            defaults.set(AppFeature.textSnippets.isEngaged(in: defaults),
                         forKey: DefaultsKey.textSnippetsSwitchEnabled)
        }
    }

    /// Cleaning a copied link joined the clipboard page. Uninstalling it used
    /// to mean uninstalling its unit; now it is the page's third member.
    static func migrateURLCleanerUnit(in defaults: UserDefaults) {
        guard !defaults.bool(forKey: DefaultsKey.urlCleanerUnitMigrated) else { return }
        defaults.set(true, forKey: DefaultsKey.urlCleanerUnitMigrated)
        let legacyKey = DefaultsKey.unitAvailable("urlCleaner")
        guard let installed = defaults.object(forKey: legacyKey) as? Bool else { return }
        if installed {
            defaults.set(true, forKey: FeatureUnit.clipboard.availabilityKey)
        } else {
            defaults.set(false, forKey: DefaultsKey.urlCleanerEnabled)
        }
        defaults.removeObject(forKey: legacyKey)
    }

    /// The "show the desktop app without windows" toggle became one choice of
    /// the windowless apps picker. Only an explicit off has to travel: the
    /// picker ships on the same choice the toggle shipped on, so a setup that
    /// never touched it keeps the switcher it already had. Clearing the old
    /// toggle is what makes this run once and never fight a later choice.
    static func migrateSwitcherWindowlessFinder(in defaults: UserDefaults) {
        let showsWindowlessFinder = defaults.bool(forKey: DefaultsKey.switcherShowWindowlessFinder)
        guard !showsWindowlessFinder else { return }
        defaults.set(true, forKey: DefaultsKey.switcherShowWindowlessFinder)
        let mode = SwitcherWindowlessApps.migrated(showsWindowlessFinder: showsWindowlessFinder)
        defaults.set(mode.rawValue, forKey: DefaultsKey.switcherWindowlessApps)
    }

    /// The "open the editor right after capturing" toggle became the Edit
    /// choice of the after-capture action picker. A setup that jumped
    /// straight into the editor keeps doing exactly that, unless a newer
    /// picker choice already exists.
    static func migrateScreenshotOpenEditorDirectly(in defaults: UserDefaults) {
        guard defaults.bool(forKey: DefaultsKey.screenshotOpenEditorDirectly) else { return }
        defaults.set(false, forKey: DefaultsKey.screenshotOpenEditorDirectly)
        let action = defaults.string(forKey: DefaultsKey.screenshotDefaultAction) ?? ""
        guard action.isEmpty else { return }
        defaults.set(ScreenshotDefaultAction.edit.rawValue,
                     forKey: DefaultsKey.screenshotDefaultAction)
    }

    /// The four screen tools now share the screenshot shortcut. Preserve the
    /// first dedicated shortcut an existing setup had enabled, while fresh
    /// installs keep the combined shortcut off by default.
    static func migrateUnifiedScreenCaptureShortcut(in defaults: UserDefaults) {
        guard !defaults.bool(forKey: DefaultsKey.unifiedScreenCaptureShortcutMigrated) else {
            return
        }
        defer {
            defaults.set(true, forKey: DefaultsKey.unifiedScreenCaptureShortcutMigrated)
        }
        guard !defaults.bool(forKey: DefaultsKey.screenshotShortcutEnabled) else { return }

        let legacyChoices: [(enabled: String, shortcut: String, fallback: GlobalShortcut)] = [
            (DefaultsKey.recorderShortcutEnabled,
             DefaultsKey.recorderShortcut,
             .screenRecorderDefault),
            (DefaultsKey.screenOCRShortcutEnabled,
             DefaultsKey.screenOCRShortcut,
             .screenOCRDefault),
            (DefaultsKey.colorPickerShortcutEnabled,
             DefaultsKey.colorPickerShortcut,
             .colorPickerDefault),
        ]
        guard let choice = legacyChoices.first(where: {
            defaults.bool(forKey: $0.enabled)
        }) else { return }
        let shortcut = defaults.string(forKey: choice.shortcut) ?? choice.fallback.storageValue
        defaults.set(true, forKey: DefaultsKey.screenshotShortcutEnabled)
        defaults.set(shortcut, forKey: DefaultsKey.screenshotShortcut)
    }

    /// The unified-capture migration copied an enabled dedicated shortcut to
    /// the general capture role. Now that dedicated shortcuts are back, keep
    /// the original role instead of registering the same combination twice.
    static func migrateRestoredScreenCaptureShortcuts(in defaults: UserDefaults) {
        guard !defaults.bool(forKey: DefaultsKey.restoredScreenCaptureShortcutsMigrated) else {
            return
        }
        defer {
            defaults.set(true, forKey: DefaultsKey.restoredScreenCaptureShortcutsMigrated)
        }
        guard defaults.bool(forKey: DefaultsKey.screenshotShortcutEnabled),
              let generalShortcut = defaults.string(forKey: DefaultsKey.screenshotShortcut)
        else { return }

        let dedicatedKeys = [
            (DefaultsKey.recorderShortcutEnabled, DefaultsKey.recorderShortcut),
            (DefaultsKey.screenOCRShortcutEnabled, DefaultsKey.screenOCRShortcut),
            (DefaultsKey.colorPickerShortcutEnabled, DefaultsKey.colorPickerShortcut),
        ]
        guard dedicatedKeys.contains(where: { enabledKey, shortcutKey in
            defaults.bool(forKey: enabledKey)
                && defaults.string(forKey: shortcutKey) == generalShortcut
        }) else { return }
        defaults.set(false, forKey: DefaultsKey.screenshotShortcutEnabled)
    }

    /// The general capture shortcut now belongs to the screenshot tool, so on
    /// an install without that tool a saved combination would register
    /// nothing. Move it once onto the first available tool that has no
    /// shortcut of its own, so the combination keeps opening the chooser.
    /// A tool whose shortcut is switched off but was customized still counts
    /// as having its own, so its saved combination is never overwritten.
    /// Availability is read from the passed defaults — the same key
    /// `isAvailable` reads from the standard ones — to stay testable.
    static func migrateOrphanedCaptureShortcut(in defaults: UserDefaults) {
        guard !defaults.bool(forKey: DefaultsKey.orphanedCaptureShortcutMigrated) else {
            return
        }
        defer {
            defaults.set(true, forKey: DefaultsKey.orphanedCaptureShortcutMigrated)
        }
        guard defaults.bool(forKey: DefaultsKey.screenshotShortcutEnabled),
              !captureWasAvailable(.screenshot, in: defaults)
        else { return }
        let shortcut = defaults.string(forKey: DefaultsKey.screenshotShortcut)
            ?? GlobalShortcut.screenshotDefault.storageValue

        let candidates: [(feature: AppFeature, enabled: String,
                          shortcut: String, unset: String)] = [
            (.screenRecorder, DefaultsKey.recorderShortcutEnabled,
             DefaultsKey.recorderShortcut,
             GlobalShortcut.screenRecorderDefault.storageValue),
            (.screenOCR, DefaultsKey.screenOCRShortcutEnabled,
             DefaultsKey.screenOCRShortcut,
             GlobalShortcut.screenOCRDefault.storageValue),
            (.colorPicker, DefaultsKey.colorPickerShortcutEnabled,
             DefaultsKey.colorPickerShortcut,
             GlobalShortcut.colorPickerDefault.storageValue),
        ]
        guard let target = candidates.first(where: {
            captureWasAvailable($0.feature, in: defaults)
                && !defaults.bool(forKey: $0.enabled)
                && (defaults.string(forKey: $0.shortcut) ?? $0.unset) == $0.unset
        }) else { return }
        defaults.set(true, forKey: target.enabled)
        defaults.set(shortcut, forKey: target.shortcut)
        defaults.set(false, forKey: DefaultsKey.screenshotShortcutEnabled)
    }

    private static func captureWasAvailable(_ feature: AppFeature, in defaults: UserDefaults) -> Bool {
        defaults.bool(forKey: feature.unit.availabilityKey)
            && (retiredFeatureSwitchKeys[feature].flatMap { defaults.object(forKey: $0) as? Bool } ?? true)
    }

    static func migrateLegacySwitcherWindowShortcut(in defaults: UserDefaults) {
        let wrongDeveloperDefault = GlobalShortcut(keyCode: Int64(kVK_ANSI_Grave),
                                                   modifiers: [.control, .option, .command]).storageValue
        guard defaults.string(forKey: DefaultsKey.switcherWindowShortcut) == wrongDeveloperDefault else {
            return
        }
        defaults.set(GlobalShortcut.switcherWindowDefault.storageValue,
                     forKey: DefaultsKey.switcherWindowShortcut)
    }

    static func migrateLegacyKeyboardDebounceWindow(in defaults: UserDefaults) {
        guard let storedWindow = defaults.object(forKey: DefaultsKey.keyboardDebounceWindowMs) as? Int,
              storedWindow == 30 || storedWindow == 10,
              defaults.bool(forKey: DefaultsKey.keyboardDebounceEnabled) == false,
              (defaults.string(forKey: DefaultsKey.keyboardDebounceKeyWindows) ?? "").isEmpty
        else { return }
        defaults.set(defaultKeyboardDebounceWindowMs, forKey: DefaultsKey.keyboardDebounceWindowMs)
    }

    static func migrateUtilityOrderForScreenshot(in defaults: UserDefaults) {
        guard let storedOrder = defaults.object(forKey: DefaultsKey.panelUtilityOrder) as? String else {
            return
        }
        let ids = storedOrder.split(separator: ",").map(String.init)
        guard !ids.contains("screenshot") else { return }
        defaults.set((["screenshot"] + ids).joined(separator: ","),
                     forKey: DefaultsKey.panelUtilityOrder)
    }

    static func sanitizedDefaultDuration(_ minutes: Int) -> Int {
        allowedDurations.contains(minutes) ? minutes : 0
    }

    static func sanitizedBatteryLimit(_ percent: Int) -> Int {
        allowedBatteryLimits.contains(percent) ? percent : 10
    }

    static func sanitizedKeepAwakeMouseJiggleInterval(_ minutes: Int) -> Int {
        allowedKeepAwakeMouseJiggleIntervals.contains(minutes) ? minutes : 5
    }

    static func sanitizedKeepAwakeIconTint(_ rawValue: String?) -> KeepAwakeIconTint {
        guard let rawValue,
              let tint = KeepAwakeIconTint(rawValue: rawValue) else {
            return .orange
        }
        return tint
    }

    static func sanitizedKeepAwakeActiveIcon(_ rawValue: String?) -> KeepAwakeActiveIcon {
        guard let rawValue,
              let icon = KeepAwakeActiveIcon(rawValue: rawValue) else {
            return .vorssaint
        }
        return icon
    }

    static func sanitizedMonitorInterval(_ seconds: Int) -> Int {
        allowedMonitorIntervals.contains(seconds) ? seconds : 2
    }

    /// Tap-to-middle-click accepts exactly three or four fingers; anything
    /// else means the option is off.
    static func sanitizedMiddleClickTapFingers(_ raw: Int) -> Int {
        raw == 3 || raw == 4 ? raw : 0
    }

    static func sanitizedKeyboardDebounceWindow(_ milliseconds: Int) -> Int {
        allowedKeyboardDebounceWindowRange.contains(milliseconds)
            ? milliseconds
            : defaultKeyboardDebounceWindowMs
    }

    static func sanitizedMouseClickDebounceWindow(_ milliseconds: Int) -> Int {
        allowedMouseClickDebounceWindowRange.contains(milliseconds)
            ? milliseconds
            : defaultMouseClickDebounceWindowMs
    }

    /// Clamps rather than falling back to the default: a typed 4 becoming 5 is
    /// the correction the person meant, a typed 4 becoming 20 is not.
    static func sanitizedClipboardAutoClearDelay(_ seconds: Int) -> Int {
        min(max(seconds, allowedClipboardAutoClearDelayRange.lowerBound),
            allowedClipboardAutoClearDelayRange.upperBound)
    }

    static func sanitizedMenuBarPreset(_ preset: String) -> String {
        allowedMenuBarPresets.contains(preset) ? preset : "dense"
    }

    static func sanitizedMenuBarMetricSpacing(_ spacing: String) -> String {
        // Corrupt values fall back to the registered default (compact).
        allowedMenuBarMetricSpacings.contains(spacing) ? spacing : "compact"
    }

    static func sanitizedMenuBarMetricAppearance(_ appearance: String) -> String {
        allowedMenuBarMetricAppearances.contains(appearance) ? appearance : "values"
    }

    static func sanitizedMenuBarMetricOrder(_ raw: String) -> [String] {
        let defaults = defaultMenuBarMetricOrder
        var seen = Set<String>()
        var result: [String] = []
        for rawValue in raw.split(separator: ",").map({ String($0) }) {
            let values = rawValue == "temperature"
                ? ["cpuTemperature", "gpuTemperature", "batteryTemperature"]
                : [rawValue]
            for value in values {
                guard defaults.contains(value), !seen.contains(value) else { continue }
                seen.insert(value)
                result.append(value)
            }
        }
        for value in defaults where !seen.contains(value) {
            result.append(value)
        }
        return result
    }

    private static func migrateLegacyMenuBarTemperatureMetric(in defaults: UserDefaults) {
        guard let domainName = Bundle.main.bundleIdentifier,
              let domain = defaults.persistentDomain(forName: domainName),
              let legacyEnabled = domain[DefaultsKey.menuBarTemperature] as? Bool
        else { return }

        let newKeys = [
            DefaultsKey.menuBarCPUTemperature,
            DefaultsKey.menuBarGPUTemperature,
            DefaultsKey.menuBarBatteryTemperature,
        ]
        let alreadyMigrated = newKeys.contains { domain[$0] != nil }
        if legacyEnabled, !alreadyMigrated {
            for key in newKeys {
                defaults.set(true, forKey: key)
            }
        }
        if let rawOrder = domain[DefaultsKey.menuBarMetricOrder] as? String {
            defaults.set(sanitizedMenuBarMetricOrder(rawOrder).joined(separator: ","),
                         forKey: DefaultsKey.menuBarMetricOrder)
        }
        defaults.removeObject(forKey: DefaultsKey.menuBarTemperature)
    }

    static func sanitizedMenuBarLabelStyle(_ style: String) -> String {
        allowedMenuBarLabelStyles.contains(style) ? style : "compact"
    }

    static func sanitizedMenuBarMemoryStyle(_ style: String) -> String {
        allowedMenuBarMemoryStyles.contains(style) ? style : "percent"
    }

    static func sanitizedMonitorMemoryMetric(_ metric: String) -> String {
        allowedMonitorMemoryMetrics.contains(metric) ? metric : "used"
    }

    static func sanitizedClipboardHistoryLimit(_ value: Int) -> Int {
        allowedClipboardHistoryLimits.contains(value) ? value : 50
    }

    static func sanitizedMonitorAlertCooldown(_ value: Int) -> Int {
        allowedMonitorAlertCooldowns.contains(value) ? value : 15
    }

    static func sanitizedPercent(_ value: Int, fallback: Int, range: ClosedRange<Int>) -> Int {
        range.contains(value) ? value : fallback
    }

    static func sanitizedBundleIdentifierList(_ bundleIDs: [String]) -> [String] {
        var seen = Set<String>()
        var result: [String] = []
        for raw in bundleIDs {
            // A mouse exception list also carries the path of a program that
            // has no bundle identifier (issue #1009), and a file name may
            // legally end in a space. Trimming one would store a spelling the
            // running program never reports, so only an identifier is trimmed.
            let bundleID = MouseAppExceptionSupport.isExecutablePathIdentity(raw)
                ? raw
                : raw.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !bundleID.isEmpty, !seen.contains(bundleID) else { continue }
            seen.insert(bundleID)
            result.append(bundleID)
        }
        return result
    }

    static func sanitizedAutoQuitExceptions(_ bundleIDs: [String]) -> [String] {
        sanitizedBundleIdentifierList(mandatoryAutoQuitExceptionBundleIDs + bundleIDs)
    }

    static func sanitizedDiskExclusionList(_ list: [String]) -> [String] {
        var seen = Set<String>()
        var result: [String] = []
        for raw in list {
            let item = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            let lower = item.lowercased()
            guard !item.isEmpty, seen.insert(lower).inserted else { continue }
            result.append(item)
        }
        return result
    }

    static func sanitizedPanelItemOrder(_ raw: String, defaultOrder: [String]) -> [String] {
        let allowed = Set(defaultOrder)
        var seen = Set<String>()
        var result: [String] = []
        for id in raw.split(separator: ",").map(String.init) {
            guard allowed.contains(id), seen.insert(id).inserted else { continue }
            result.append(id)
        }
        for id in defaultOrder where seen.insert(id).inserted {
            result.append(id)
        }
        return result
    }

    static func sanitizedAppVolume(_ volume: Double) -> Double {
        guard volume.isFinite else { return 1 }
        return min(max(volume, 0), 2)
    }

    /// The volume the speakers are set to when headphones disconnect. It is a
    /// protection against a sudden blast, not a mute, so it never goes low
    /// enough to leave the sound inaudible.
    static let minimumMixerHeadphonesDisconnectVolumePercent = 10
    static let defaultMixerHeadphonesDisconnectVolumePercent = 25

    static func sanitizedMixerHeadphonesDisconnectVolumePercent(_ percent: Int) -> Int {
        min(max(percent, minimumMixerHeadphonesDisconnectVolumePercent), 100)
    }

    /// The option shipped with a stored value of 0, so ticking the box without
    /// touching the stepper silenced the speakers on the next disconnect. A
    /// value below the floor becomes the sane default.
    static func migrateSilentHeadphonesDisconnectVolume(in defaults: UserDefaults) {
        guard let stored = defaults.object(forKey: DefaultsKey.mixerHeadphonesDisconnectVolumePercent) as? Int,
              stored < minimumMixerHeadphonesDisconnectVolumePercent else { return }
        defaults.set(defaultMixerHeadphonesDisconnectVolumePercent,
                     forKey: DefaultsKey.mixerHeadphonesDisconnectVolumePercent)
    }

    static func sanitizedAppOutputDeviceUID(_ value: Any?) -> String? {
        MixerRoutingSupport.sanitizedDeviceUID(value)
    }

    static func sanitizedAppOutputDevices(_ raw: [String: Any]) -> [String: String] {
        MixerRoutingSupport.sanitizedRouteMap(raw)
    }

    static func sanitizedSoundOutputSwitcherDeviceUIDs(_ raw: [Any]) -> [String] {
        var seen = Set<String>()
        var result: [String] = []
        for value in raw {
            guard let uid = MixerRoutingSupport.sanitizedDeviceUID(value),
                  seen.insert(uid).inserted else { continue }
            result.append(uid)
        }
        return result
    }

    static func sanitizedPreferredInputDeviceUID(_ value: Any?) -> String? {
        MixerRoutingSupport.sanitizedDeviceUID(value)
    }
}
