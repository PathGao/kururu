// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import AppKit

extension QuickToggleAction {
    /// What a menu calls the action right now: the three switches name the
    /// direction they are about to flip, read on demand like everything else
    /// here.
    var title: String {
        let strings = FeatureStrings.systemActions(L10n.shared.language)
        let toggles = QuickTogglesService.shared
        switch self {
        case .darkMode:
            return toggles.systemAppearanceIsDark == true ? strings.darkModeToLight : strings.darkModeToDark
        case .emptyTrash: return strings.emptyTrashTitle
        case .ejectDisks: return strings.ejectTitle
        case .hiddenFiles: return toggles.hiddenFilesShown ? strings.hiddenFilesHide : strings.hiddenFilesShow
        case .desktopIcons: return toggles.desktopIconsShown ? strings.desktopIconsHide : strings.desktopIconsShow
        case .lockScreen: return strings.lockScreenTitle
        case .displayOff: return strings.displayOffTitle
        case .screenSaver: return strings.screenSaverTitle
        }
    }
}

/// One-click system actions, all on demand: nothing runs, observes or polls
/// while nobody asks for one. Each action keeps a short-lived run state so a
/// second click while it works is ignored.
final class QuickTogglesService {
    static let shared = QuickTogglesService()

    /// Actions with work in flight, touched on the main thread only.
    private var running: Set<QuickToggleAction> = []

    private let workQueue = DispatchQueue(label: "com.vorssaint.utils.quick-toggles", qos: .userInitiated)

    private init() {}

    // MARK: - Current system state (read on demand, never observed)

    var hiddenFilesShown: Bool {
        finderFlag(QuickTogglesSupport.showAllFilesKey, default: false)
    }

    /// Current system appearance, read from the same WindowServer switch the
    /// toggle flips; nil when the symbol is unavailable.
    var systemAppearanceIsDark: Bool? {
        Self.appearanceTheme?.get()
    }

    var desktopIconsShown: Bool {
        finderFlag(QuickTogglesSupport.createDesktopKey, default: true)
    }

    func ejectableVolumeCount() -> Int {
        Self.ejectableVolumeURLs().count
    }

    // MARK: - Appearance (issue #205)

    /// Flips the system between light and dark mode through the WindowServer,
    /// the same switch System Settings flips: instant, system wide and with
    /// no Automation consent involved. The symbol is resolved lazily and
    /// guarded; without it the action beeps instead of crashing.
    func toggleDarkMode() {
        guard available, beginRun(.darkMode) else { return }
        defer { finishRun(.darkMode) }
        guard let theme = Self.appearanceTheme else {
            NSSound.beep()
            return
        }
        theme.set(!theme.get())
    }

    // MARK: - Trash

    /// Emptying is permanent, so every caller confirms in its own words
    /// first; the command bar does it inline.
    /// Asks first, for a caller with no confirmation of its own: the wheel
    /// runs a slice the moment it is released.
    func emptyTrashAfterConfirming() {
        guard available else { return }
        let strings = FeatureStrings.systemActions(L10n.shared.language)
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = strings.emptyTrashConfirmTitle
        alert.addButton(withTitle: strings.emptyTrashTitle)
        alert.addButton(withTitle: L10n.shared.s.uninstallerCancel)
        NSApp.activate(ignoringOtherApps: true)
        guard alert.runModal() == .alertFirstButtonReturn else { return }
        emptyTrashConfirmed()
    }

    func emptyTrashConfirmed() {
        runAppleScript(.emptyTrash,
                       target: .finder,
                       source: QuickTogglesSupport.emptyTrashSource)
    }

    // MARK: - Finder flags

    /// Writes the Finder preference and restarts the Finder to apply it;
    /// launchd brings it right back with the new value in effect.
    func toggleHiddenFiles() {
        toggleFinderFlag(.hiddenFiles,
                         key: QuickTogglesSupport.showAllFilesKey,
                         to: !hiddenFilesShown)
    }

    func toggleDesktopIcons() {
        toggleFinderFlag(.desktopIcons,
                         key: QuickTogglesSupport.createDesktopKey,
                         to: !desktopIconsShown)
    }

    // MARK: - Disks

    /// Safely ejects every external volume, the on-demand cousin of the disk
    /// monitor's "Eject all". Enumerated fresh on each click, so the action
    /// never keeps a disk list alive.
    func ejectAllDisks() {
        guard available, beginRun(.ejectDisks) else { return }
        workQueue.async {
            defer { self.finishRun(.ejectDisks) }
            let volumes = Self.ejectableVolumeURLs()
            guard !volumes.isEmpty else { return }
            var failures = 0
            for url in volumes {
                do {
                    try NSWorkspace.shared.unmountAndEjectDevice(at: url)
                } catch {
                    // A drive that carries more than one volume leaves whole on
                    // the first eject, so the ones still on the list are gone
                    // before their turn comes and refuse an eject of their own.
                    // Only a volume that is still mounted really failed.
                    if Self.isMounted(url) { failures += 1 }
                }
            }
            if failures > 0 { DispatchQueue.main.async { NSSound.beep() } }
        }
    }

    // MARK: - Screen

    /// The same immediate lock as the system's own shortcut. The symbol is
    /// resolved lazily and guarded; when it is unavailable the screen saver
    /// path stands in (with a password required, it locks too).
    func lockScreen() {
        guard available else { return }
        if let lock = Self.lockScreenFunction {
            _ = lock()
        } else {
            startScreenSaver()
        }
    }

    func turnDisplayOff() {
        guard available, beginRun(.displayOff) else { return }
        workQueue.async {
            let result = Shell.run("/usr/bin/pmset", ["displaysleepnow"])
            self.finishRun(.displayOff)
            if result.status != 0 { DispatchQueue.main.async { NSSound.beep() } }
        }
    }

    func startScreenSaver() {
        guard available else { return }
        let url = URL(fileURLWithPath: "/System/Library/CoreServices/ScreenSaverEngine.app")
        NSWorkspace.shared.openApplication(at: url,
                                           configuration: NSWorkspace.OpenConfiguration())
    }

    // MARK: - Internals

    /// The command bar is the only surface these actions reach today, so its
    /// hub switch is what installs them.
    /// Both surfaces that can run one of these: the command bar's rows and
    /// the wheel slices the user puts there.
    private var available: Bool {
        AppFeature.commandBar.isAvailable || AppFeature.radialMenu.isAvailable
    }

    private func runAppleScript(_ action: QuickToggleAction,
                                target: Permissions.AutomationTarget,
                                source: String) {
        guard available, beginRun(action) else { return }
        workQueue.async {
            defer { self.finishRun(action) }
            // Denied consent never re-prompts by itself, so running the script
            // would fail silently. Undetermined runs straight into it, which
            // is what triggers the system prompt.
            guard Permissions.automationStatus(for: target) != .denied else {
                DispatchQueue.main.async { NSSound.beep() }
                return
            }
            if !AppleScriptRunner.runDetailed(source).ok {
                DispatchQueue.main.async { NSSound.beep() }
            }
        }
    }

    private func toggleFinderFlag(_ action: QuickToggleAction, key: String, to value: Bool) {
        guard available, beginRun(action) else { return }
        workQueue.async {
            CFPreferencesSetAppValue(key as CFString,
                                     value as CFBoolean,
                                     QuickTogglesSupport.finderDomain as CFString)
            CFPreferencesAppSynchronize(QuickTogglesSupport.finderDomain as CFString)
            let restarted = self.restartFinder()
            self.finishRun(action)
            if !restarted { DispatchQueue.main.async { NSSound.beep() } }
        }
    }

    /// The Finder only reads these preferences at launch, so it has to
    /// restart. When the Finder Automation grant is already in (the Trash
    /// and cut and paste share it), the restart is polite: a regular quit
    /// followed by our own relaunch, which keeps launchd out of it and
    /// avoids its "running in background" churn. Without the grant, or when
    /// the Finder will not quit (an operation in progress), the classic
    /// killall does it; never prompts either way. Work-queue only: the exit
    /// poll blocks.
    private func restartFinder() -> Bool {
        if Permissions.automationStatus(for: .finder) == .granted,
           AppleScriptRunner.runDetailed(QuickTogglesSupport.quitFinderSource).ok,
           waitForFinderExit() {
            let url = URL(fileURLWithPath: "/System/Library/CoreServices/Finder.app")
            let configuration = NSWorkspace.OpenConfiguration()
            configuration.activates = false
            NSWorkspace.shared.openApplication(at: url, configuration: configuration)
            return true
        }
        return Shell.run("/usr/bin/killall", ["Finder"]).status == 0
    }

    /// A quit Finder stays quit (nothing relaunches it), so the poll only
    /// confirms the exit before the relaunch; a Finder that is still around
    /// after the timeout is busy and falls back to killall.
    private func waitForFinderExit() -> Bool {
        for _ in 0..<30 {
            if Shell.run("/usr/bin/pgrep", ["-x", "Finder"]).status != 0 {
                return true
            }
            usleep(100_000)
        }
        return false
    }

    /// Marks the action as in flight; a second click while it runs is
    /// ignored. Called on the main thread, so the guard reads what it just
    /// wrote.
    private func beginRun(_ action: QuickToggleAction) -> Bool {
        guard !running.contains(action) else { return false }
        running.insert(action)
        return true
    }

    private func finishRun(_ action: QuickToggleAction) {
        DispatchQueue.main.async { self.running.remove(action) }
    }

    private func finderFlag(_ key: String, default defaultValue: Bool) -> Bool {
        let value = CFPreferencesCopyAppValue(key as CFString,
                                              QuickTogglesSupport.finderDomain as CFString)
        return QuickTogglesSupport.finderFlag(value, default: defaultValue)
    }

    private static func ejectableVolumeURLs() -> [URL] {
        let keys: Set<URLResourceKey> = [
            .volumeIsInternalKey, .volumeIsRemovableKey,
            .volumeIsEjectableKey, .volumeIsLocalKey,
            .volumeIsRootFileSystemKey,
            .volumeNameKey,
            .volumeLocalizedNameKey,
            .volumeUUIDStringKey,
        ]
        guard let urls = FileManager.default.mountedVolumeURLs(
            includingResourceValuesForKeys: Array(keys),
            options: [.skipHiddenVolumes]) else { return [] }
        let excludedList = UserDefaults.standard.stringArray(forKey: DefaultsKey.diskEjectExcludedVolumes) ?? []
        let excludedSet = Set(excludedList.map { $0.lowercased() })
        return urls.filter { url in
            guard let values = try? url.resourceValues(forKeys: keys) else { return false }
            // A volume with no bus of its own, a mounted image for one, states
            // no internal flag at all, so only a stated internal bus counts as
            // internal. The local flag stays strict: a volume that will not say
            // it is local is left alone. The volume the Mac started from falls
            // back to its mount point, so a missing flag cannot expose it.
            let name = values.volumeLocalizedName ?? values.volumeName ?? url.lastPathComponent
            return QuickTogglesSupport.shouldOfferEject(isInternal: values.volumeIsInternal ?? false,
                                                        isRemovable: values.volumeIsRemovable ?? false,
                                                        isEjectable: values.volumeIsEjectable ?? false,
                                                        isLocal: values.volumeIsLocal ?? false,
                                                        isRootFileSystem: values.volumeIsRootFileSystem
                                                            ?? (url.path == "/"),
                                                        volumeName: name,
                                                        volumeUUID: values.volumeUUIDString,
                                                        mountPath: url.path,
                                                        excludedVolumes: excludedSet)
        }
    }

    /// Whether a volume is still on the mount table, asked only after an eject
    /// reported a problem. A list we cannot read answers yes, so a real failure
    /// is never swallowed.
    private static func isMounted(_ url: URL) -> Bool {
        guard let urls = FileManager.default.mountedVolumeURLs(includingResourceValuesForKeys: nil,
                                                               options: []) else { return true }
        return urls.contains { $0.path == url.path }
    }

    /// SACLockScreenImmediate from the login framework, resolved once and
    /// guarded: a missing symbol just means the screen saver fallback.
    private static let lockScreenFunction: (@convention(c) () -> Int32)? = {
        let path = "/System/Library/PrivateFrameworks/login.framework/login"
        guard let handle = dlopen(path, RTLD_LAZY),
              let symbol = dlsym(handle, "SACLockScreenImmediate") else { return nil }
        return unsafeBitCast(symbol, to: (@convention(c) () -> Int32).self)
    }()

    private typealias AppearanceGet = @convention(c) () -> Bool
    private typealias AppearanceSet = @convention(c) (Bool) -> Void

    /// The WindowServer's appearance switch (SkyLight), resolved once and
    /// guarded like the lock above. Stable across many macOS releases; if it
    /// ever leaves, toggleDarkMode degrades to a visible failure.
    private static let appearanceTheme: (get: AppearanceGet, set: AppearanceSet)? = {
        let path = "/System/Library/PrivateFrameworks/SkyLight.framework/SkyLight"
        guard let handle = dlopen(path, RTLD_LAZY),
              let getSymbol = dlsym(handle, "SLSGetAppearanceThemeLegacy"),
              let setSymbol = dlsym(handle, "SLSSetAppearanceThemeLegacy") else { return nil }
        return (unsafeBitCast(getSymbol, to: AppearanceGet.self),
                unsafeBitCast(setSymbol, to: AppearanceSet.self))
    }()
}
