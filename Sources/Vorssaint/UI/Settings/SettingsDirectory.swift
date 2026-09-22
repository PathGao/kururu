// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import Foundation

/// One Settings page as the sidebar and the command bar present it.
struct SettingsDirectoryItem: Identifiable {
    let page: SettingsPage
    let title: String
    let icon: String
    /// Labels of options living inside the page, so a search finds a page by
    /// what it contains, in the user's language.
    var keywords: [String] = []
    /// Feature ownership for keyword rows on shared pages. `nil` means the
    /// setting belongs to the page itself and remains searchable whenever the
    /// page is visible.
    var keywordFeatures: [AppFeature?] = []
    var id: SettingsPage { page }

    init(page: SettingsPage, s: Strings, language: AppLanguage, icon: String,
         keywords: [String] = [],
         featureKeywords: [(feature: AppFeature, titles: [String])] = []) {
        self.page = page
        title = page.title(s, language: language)
        self.icon = icon
        self.keywords = keywords + featureKeywords.flatMap(\.titles)
        keywordFeatures = Array(repeating: nil, count: keywords.count)
            + featureKeywords.flatMap { entry in
                Array(repeating: Optional(entry.feature), count: entry.titles.count)
            }
    }
}

/// The single map of the Settings window: sections, pages, icons and search
/// keywords. The sidebar renders it; the command bar searches it. One list,
/// so a page added here is findable everywhere at once.
enum SettingsDirectory {
    /// Destination-aware rows for focused Settings search. The regular
    /// directory remains page-based so blank-query sidebar identity and
    /// command-bar behavior do not change.
    static func searchItems(_ s: Strings,
                            language: AppLanguage) -> [SettingsSearchItem] {
        let pageItems = sections(s, language: language).flatMap(\.items).map { item in
            SettingsSearchItem(id: .page(item.page),
                               destination: FeatureSettingsDestination(item.page),
                               title: item.title,
                               icon: item.icon,
                               keywords: item.keywords,
                               keywordFeatures: item.keywordFeatures)
        }
        let featureItems = SettingsSearchSupport.featureItems(language: language) { feature in
            feature.name(s, language: language)
        }
        return SettingsSearchSupport.combinedItems(pageItems: pageItems,
                                                   featureItems: featureItems)
    }

    static func sections(_ s: Strings,
                         language: AppLanguage)
        -> [(title: String, items: [SettingsDirectoryItem])] {
        let hub = FeatureStrings.hub(language)
        let quitProtection = FeatureStrings.quitProtection(language)
        return [
            ("", [
                // Searching any feature name lands here even when the feature
                // is hidden, so the hub is always the way back.
                SettingsDirectoryItem(page: .features, s: s, language: language,
                                       icon: "square.grid.2x2",
                                       featureKeywords: AppFeature.allCases.map {
                                        ($0, [$0.name(s, language: language)])
                                       }),
                SettingsDirectoryItem(page: .menuBarIcon, s: s, language: language,
                                      icon: "menubar.arrow.up.rectangle",
                                      keywords: [s.showMenuBarIcon, s.menuBarHideIconToggle,
                                                 s.menuBarSpacingLabel,
                                                 s.monitorSeparateMenuBarMetrics,
                                                 FeatureStrings.menuBarAppearance(language).label],
                                      featureKeywords: [
                                        (.micMute, [FeatureStrings.micMute(language).menuBarToggle]),
                                       ]),
                SettingsDirectoryItem(page: .menuBarPanel, s: s, language: language, icon: "menubar.rectangle",
                                       keywords: [s.monitorOrderSection, s.monitorPanelSection]),
                // The panel, the shortcut table, the wheel and the bar are the
                // four ways into everything below: they hold whatever is
                // installed and nothing of their own.
                SettingsDirectoryItem(page: .shortcuts, s: s, language: language, icon: "command",
                                      keywords: [s.hotkeyToggle]),
                SettingsDirectoryItem(page: .radialMenu, s: s, language: language,
                                      icon: "circle.grid.cross",
                                      keywords: [FeatureStrings.radialMenu(language).addButton,
                                                 FeatureStrings.radialMenu(language).kindApp,
                                                 FeatureStrings.radialMenu(language).kindSystemAction,
                                                 FeatureStrings.radialMenu(language).kindMedia,
                                                 FeatureStrings.radialMenu(language).kindSubmenu,
                                                 FeatureStrings.radialMenu(language).mouseTriggerRequirement]),
                SettingsDirectoryItem(page: .commandBar, s: s, language: language,
                                      icon: "command.square",
                                      keywords: [FeatureStrings.commandBar(language).openButton,
                                                 FeatureStrings.commandBar(language).searchPlaceholder,
                                                 FeatureStrings.commandBar(language).appCenterTitle,
                                                 FeatureStrings.commandBar(language).appAliasLabel]),
            ]),
            (hub.groupMonitor, [
                SettingsDirectoryItem(page: .monitor, s: s, language: language, icon: "chart.line.uptrend.xyaxis",
                                       featureKeywords: [
                                        (.monitorMemory, [s.monitorMemoryPressureDot]),
                                        (.fanControl, [FeatureStrings.fanControl(language).menuBarTitle]),
                                        (.killProcess, [FeatureStrings.killProcess(language).forceKillButton]),
                                       ]),
            ]),
            (hub.groupFocusEnergy, [
                SettingsDirectoryItem(page: .keepAwake, s: s, language: language, icon: "bolt.fill",
                                       featureKeywords: [
                                        (.keepAwake, [s.keepAwakeTitle, s.clamshellTitle,
                                                      s.defaultDurationLabel, s.showCountdown,
                                                      s.keepAwakeActiveIconLabel,
                                                      s.keepAwakeActiveIconCoffee,
                                                      s.keepAwakeActiveIconEye,
                                                      FeatureStrings.keepAwakeAutomation(language)
                                                        .externalDisplayToggle,
                                                      FeatureStrings.keepAwakeAutomation(language)
                                                        .powerToggle,
                                                      FeatureStrings.keepAwakeAutomation(language)
                                                        .pauseWhenLockedToggle,
                                                      FeatureStrings.keepAwakeDisplaySleep(language)
                                                        .allowDisplaySleep]),
                                       ]),
                SettingsDirectoryItem(page: .brightness, s: s, language: language,
                                      icon: AppFeature.brightness.symbolName,
                                       featureKeywords: [
                                        (.brightness, [FeatureStrings.brightness(language).pageTitle,
                                                       FeatureStrings.brightness(language).osdToggle]),
                                       ]),
                SettingsDirectoryItem(page: .bluetoothSleep, s: s, language: language,
                                      icon: AppFeature.bluetoothSleep.symbolName,
                                       featureKeywords: [
                                        (.bluetoothSleep, [FeatureStrings.bluetoothSleep(language).pageTitle,
                                                           FeatureStrings.bluetoothSleep(language).enable]),
                                       ]),
                SettingsDirectoryItem(page: .cleaningMode, s: s, language: language,
                                      icon: AppFeature.cleaningMode.symbolName,
                                       featureKeywords: [
                                        (.cleaningMode, [s.cleaningMenuItem, s.cleaningKeepScreenVisibleToggle]),
                                       ]),
            ]),
            (hub.groupWindowsDesktop, [
                SettingsDirectoryItem(page: .switcher, s: s, language: language, icon: "rectangle.on.rectangle",
                                       keywords: [FeatureStrings.windowPreviewExclusions(language).listTitle],
                                       featureKeywords: [
                                        (.switcher, [s.switcherEnable, s.switcherWindowlessApps,
                                                     s.switcherShowShortcutHints,
                                                     FeatureStrings.switcherAppRules(language).listTitle,
                                                     FeatureStrings.switcherAppRules(language)
                                                        .showWithoutWindows,
                                                     FeatureStrings.switcherAppRules(language).windowsOnly,
                                                     FeatureStrings.switcherAppRules(language).hidden]),
                                       ]),
                SettingsDirectoryItem(page: .dock, s: s, language: language,
                                      icon: AppFeature.dockPreview.symbolName,
                                      keywords: [FeatureStrings.windowPreviewExclusions(language).listTitle],
                                      featureKeywords: [
                                        (.dockClick, [FeatureStrings.dockClick(language).minimize,
                                                      FeatureStrings.dockClick(language).hide,
                                                      FeatureStrings.dockClick(language).cycleWindows]),
                                       ]),
                SettingsDirectoryItem(page: .windowBehavior, s: s, language: language,
                                      icon: "shield.lefthalf.filled",
                                      keywords: [quitProtection.description, "⌘Q", "⌘W",
                                                 quitProtection.hold, quitProtection.doublePress,
                                                 quitProtection.extraModifier,
                                                 s.windowMaximizeName, s.autoQuitEnable]),
            ]),
            (hub.groupInputDevices, [
                SettingsDirectoryItem(page: .mouse, s: s, language: language, icon: "computermouse",
                                       featureKeywords: [
                                        (.scrollInverter, [s.invertMouseScroll, s.invertVerticalScroll,
                                                           s.invertHorizontalScroll]),
                                        (.scrollHorizontal, [s.scrollHorizontalName,
                                                             s.scrollHorizontalModifierLabel]),
                                        (.focusFollowsMouse, [s.focusFollowsMouseName,
                                                              s.focusFollowsMouseDelay]),
                                        (.smoothScroll, [s.smoothScrollName]),
                                        (.mouseAcceleration, [s.mouseAccelerationName]),
                                        (.mouseNavigation, [s.mouseNavigationEnable]),
                                        (.mouseButtonShortcuts,
                                         [FeatureStrings.mouseButtons(language).pageTitle,
                                          FeatureStrings.mouseButtons(language).sideWheelLeftName,
                                          FeatureStrings.mouseButtons(language).sideWheelRightName,
                                          FeatureStrings.mouseExceptions(language).listTitle]),
                                        (.mouseClickDebounce,
                                         [FeatureStrings.mouseClickDebounce(language).title,
                                          FeatureStrings.mouseClickDebounce(language).windowLabel,
                                          "debounce"]),
                                       ]),
                SettingsDirectoryItem(page: .trackpad, s: s, language: language,
                                      icon: "rectangle.and.hand.point.up.left",
                                      featureKeywords: [(.middleClick, [s.middleClickTapPicker])]),
                SettingsDirectoryItem(page: .keyboard, s: s, language: language, icon: "keyboard",
                                      featureKeywords: [
                                        (.keyboardDebounce, [s.keyDebounceName, s.keyDebounceEnable]),
                                        (.textSnippets, [FeatureStrings.snippets(language).pageTitle,
                                                         FeatureStrings.snippets(language).triggerLabel,
                                                         FeatureStrings.snippets(language).addButton]),
                                        (.superKey, [FeatureStrings.superKey(language).pageTitle]
                                            + SuperKeySource.allCases.map {
                                                FeatureStrings.superKey(language).sourceLabel($0)
                                            }),
                                       ]),
            ]),
            (hub.groupClipboardFiles, [
                SettingsDirectoryItem(page: .clipboard, s: s, language: language,
                                       icon: "doc.on.clipboard",
                                       featureKeywords: [
                                        (.clipboardHistory, [FeatureStrings.clipboard(language).limit,
                                                             FeatureStrings.clipboard(language).skipSensitive,
                                                             FeatureStrings.clipboard(language).autoClearEnable,
                                                             FeatureStrings.clipboard(language).autoClearOnSleep,
                                                             FeatureStrings.clipboard(language)
                                                                .autoClearOnDisplaySleep,
                                                             FeatureStrings.clipboard(language)
                                                                .autoClearOnScreenLock,
                                                             FeatureStrings.clipboardIgnoredApps(language)
                                        .listTitle]),
                                       ]),
                SettingsDirectoryItem(page: .urlCleaner, s: s, language: language,
                                      icon: AppFeature.urlCleaner.symbolName,
                                      featureKeywords: [
                                        (.urlCleaner, [s.urlCleanerEnable, s.urlCleanerManualTitle,
                                                       s.urlCleanerRulesTitle]),
                                      ]),
                SettingsDirectoryItem(page: .cutPaste, s: s, language: language,
                                       icon: "filemenu.and.selection",
                                       featureKeywords: [
                                        (.finderCutPaste, [s.cutPasteEnable,
                                                           FeatureStrings.clipboard(language).pasteImageAsFile]),
                                        (.finderRename,
                                         [FeatureStrings.finderRename(language).enableLabel]),
                                       ]),
                SettingsDirectoryItem(page: .shelf, s: s, language: language, icon: "tray.full",
                                      keywords: [s.shelfEnable, s.shelfDropZoneToggle, s.shelfEdgeToggle,
                                                 s.shelfClearOnClose]),
                SettingsDirectoryItem(page: .scratchpad, s: s, language: language,
                                      icon: AppFeature.scratchpad.symbolName),
            ]),
            (hub.groupCapture, [
                SettingsDirectoryItem(page: .screenshot, s: s, language: language,
                                       icon: "camera.viewfinder",
                                       featureKeywords: SettingsSearchSupport
                                        .screenCaptureFeatureKeywords(s, language: language)),
                SettingsDirectoryItem(page: .media, s: s, language: language, icon: "photo.on.rectangle.angled",
                                      keywords: ["PDF", "GIF", "PNG", "JPEG", "convert", "resize", "watermark",
                                                 "rename", "profile", "fit", "fill", "crop",
                                                 s.mediaStartConvertPDF, s.ocrName]),
            ]),
            (hub.groupSoundDevices, [
                SettingsDirectoryItem(page: .mixer, s: s, language: language,
                                       icon: "speaker.wave.2",
                                       featureKeywords: [
                                        (.mixer, [FeatureStrings.mixer(language).hideInactiveApps,
                                                  FeatureStrings.mixer(language).lowerOnHeadphonesDisconnect,
                                                  FeatureStrings.mixer(language).visibleApps,
                                                  s.preciseVolumeRollerEnable]),
                                        (.soundOutputSwitcher, [FeatureStrings.soundOutputSwitcher(language).pageTitle]),
                                       ]),
                SettingsDirectoryItem(page: .micMute, s: s, language: language,
                                       icon: AppFeature.micMute.symbolName,
                                       featureKeywords: [
                                        (.micMute, [FeatureStrings.micMute(language).pageTitle]),
                                       ]),
                SettingsDirectoryItem(page: .musicBlock, s: s, language: language,
                                       icon: AppFeature.musicBlock.symbolName,
                                       featureKeywords: [
                                        (.musicBlock, [FeatureStrings.musicBlock(language).title,
                                                       FeatureStrings.musicBlock(language).section]),
                                       ]),
            ]),
            (hub.groupAppManagement, [
                SettingsDirectoryItem(page: .cleaner, s: s, language: language, icon: "sparkles",
                                      keywords: [s.cleanerScheduleTitle,
                                                 FeatureStrings.whatsAppDownloads(language).title,
                                                 FeatureStrings.whatsAppDownloads(language).automatic,
                                                 FeatureStrings.whatsAppDownloads(language).fileTypes]),
                SettingsDirectoryItem(page: .homebrew, s: s, language: language, icon: "shippingbox"),
                SettingsDirectoryItem(page: .environment, s: s, language: language, icon: "terminal"),
                SettingsDirectoryItem(page: .uninstaller, s: s, language: language, icon: "trash"),
                SettingsDirectoryItem(page: .killProcess, s: s, language: language,
                                      icon: AppFeature.killProcess.symbolName,
                                      keywords: [FeatureStrings.killProcess(language).forceKillButton,
                                                 FeatureStrings.killProcess(language).killTreeButton,
                                                 FeatureStrings.killProcess(language).restartButton,
                                                 FeatureStrings.killProcess(language).groupToggle]),
            ]),
            (AppInfo.name, [
                SettingsDirectoryItem(page: .advanced, s: s, language: language, icon: "wrench.and.screwdriver",
                                      keywords: [s.tabAdvanced, s.launchAtLogin, s.languageLabel,
                                                 FeatureStrings.appearance(language).label,
                                                 FeatureStrings.appearance(language).dark]),
                SettingsDirectoryItem(page: .about, s: s, language: language, icon: "info.circle",
                                      keywords: [s.reviewIntro, s.reviewHighlights, s.viewOnGitHub]),
                SettingsDirectoryItem(page: .releaseNotes, s: s, language: language, icon: "sparkles"),
            ]),
        ]
    }
}
