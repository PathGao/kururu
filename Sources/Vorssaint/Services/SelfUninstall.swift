// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import AppKit
import ServiceManagement

/// Clears the app's own footprint on the system, for a clean uninstall.
///
/// Security note: every operation here is scoped to THIS app and nothing else.
/// The bundle id is a constant identifier (never user input), so the `tccutil`
/// call cannot be steered elsewhere; the login item and sudoers rule are the
/// app's own; the preference and saved-state paths are built from the app's own
/// bundle id. Complete removal deletes those app-owned data paths permanently;
/// only the app bundle is moved to the Trash. Nothing leaves the machine.
enum SelfUninstall {
    enum Failure {
        case preparation, rule, permissions
        case files([String]), handoff(String, dataRemovalStarted: Bool)
    }

    private static var bundleID: String? { ProductIdentityBoundarySupport.ownedBundleID(Bundle.main.bundleIdentifier) }

    /// Resets every TCC permission the app holds, drops the login item and the
    /// optional closed-lid sudoers rule, and leaves the app in place. Calls back
    /// on the main queue. Used by "Clear all permissions".
    static func clearPermissions(completion: @escaping (PermissionResetResult) -> Void) {
        guard bundleID != nil else {
            NSLog("%@", ProductIdentityBoundarySupport.invalidIdentityMessage)
            DispatchQueue.main.async { completion(.preparationFailed) }
            return
        }
        // Stop every input interceptor FIRST (on the main thread), then revoke.
        // Revoking Accessibility while a tap is live makes the tap callback hang
        // on an AX call and freezes the whole machine's input — see the note on
        // `suspendInputInterceptors`.
        DispatchQueue.main.async {
            let suspended = suspendInputInterceptors()
            DispatchQueue.global(qos: .userInitiated).async {
                PermissionResetSupport.run(
                    prepare: { suspended && detachFromSystem(verifyLoginRemoval: true) },
                    removeRule: removeSudoersRuleIfPresent,
                    reset: resetTCC
                ) { result in
                    DispatchQueue.main.async {
                        BrightnessService.shared.resumeInputTaps()
                        completion(result)
                    }
                }
            }
        }
    }

    /// Clears permissions, removes preferences and saved state, sends the app
    /// bundle to the Trash and quits. Used by "Uninstall Vorssaint completely".
    static func uninstallCompletely(onFailure: @escaping (Failure) -> Void) {
        guard bundleID != nil else {
            DispatchQueue.main.async { onFailure(.preparation) }
            return
        }
        DispatchQueue.main.async {
            guard suspendInputInterceptors() else {
                BrightnessService.shared.resumeInputTaps()
                onFailure(.preparation)
                return
            }
            DispatchQueue.global(qos: .userInitiated).async {
                PermissionResetSupport.run(
                    prepare: { detachFromSystem(verifyLoginRemoval: true) },
                    removeRule: removeSudoersRuleIfPresent,
                    reset: resetTCC
                ) { result in
                    guard result == .completed else {
                        let failure: Failure = result == .ruleRemovalFailed ? .rule
                            : result == .resetFailed ? .permissions : .preparation
                        DispatchQueue.main.async {
                            BrightnessService.shared.resumeInputTaps()
                            onFailure(failure)
                        }
                        return
                    }
                    let helper: UninstallHandoff
                    do { helper = try prepareTrashHandoff() }
                    catch {
                        DispatchQueue.main.async { onFailure(.handoff(error.localizedDescription, dataRemovalStarted: false)) }
                        return
                    }
                    DispatchQueue.main.async {
                        ClipboardHistoryService.shared.stopPersistenceForRemoval()
                        ScratchpadService.shared.stopPersistenceForRemoval()
                        ShelfService.shared.stopPersistenceForRemoval()
                        DispatchQueue.global(qos: .userInitiated).async {
                            let failed = removePreferences()
                            guard failed.isEmpty else {
                                helper.cancel()
                                DispatchQueue.main.async { onFailure(.files(failed)) }
                                return
                            }
                            do { try helper.commit() }
                            catch {
                                helper.cancel()
                                DispatchQueue.main.async { onFailure(.handoff(error.localizedDescription, dataRemovalStarted: true)) }
                                return
                            }
                            DispatchQueue.main.async { NSApp.terminate(nil) }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Steps (each scoped to this app only)

    /// Tears down every Accessibility-backed input interceptor. MUST run on the
    /// main thread and BEFORE permissions are reset: otherwise revoking
    /// Accessibility while an event tap is still live makes the tap's callback
    /// block on an AX call, which stalls the OS input queue and freezes the
    /// keyboard and clicks (only the mouse cursor keeps moving). Each `stop`/
    /// `suspend`/`deactivate` is idempotent, so calling it when a service is
    /// already off is a no-op.
    private static func suspendInputInterceptors() -> Bool {
        // Deactivating Cleaning Mode re-syncs the services it paused back to
        // their preferences, so it has to happen before the suspends below,
        // or it would re-arm the very taps this teardown just stopped.
        CleaningModeManager.shared.deactivate()
        ScrollInverter.shared.suspend()
        FocusFollowsMouseService.shared.stop()
        SmoothScrollService.shared.suspend()
        // Its machine-local recovery journal is deleted by a full uninstall,
        // so the uninstall cannot continue until every HID value is restored.
        let mouseAccelerationRestored = MouseAccelerationService.shared.stop()
        MouseNavigationService.shared.suspend()
        MouseButtonShortcutService.shared.suspend()
        WindowMaximizer.shared.stop()
        WindowLayoutService.shared.suspend()
        AppSwitcher.shared.suspend()
        DockPreviewService.shared.stop()
        BrightnessService.shared.suspendInputTaps()
        AutoQuitService.shared.suspend()
        FinderCutPaste.shared.suspend()
        FinderRenameService.shared.suspend()
        KeyboardDebounceService.shared.suspend()
        MouseClickDebounceService.shared.suspend()
        // Also takes the Super key mapping back out, synchronously, so the
        // key is never left remapped behind a tap that is about to die.
        SuperKeyService.shared.suspend()
        DockClickService.shared.suspend()
        MiddleClickService.shared.suspend()
        QuitProtectionService.shared.suspend()
        PastePlainService.shared.suspend()
        SnippetLibraryService.shared.suspend()
        TextSnippetService.shared.suspend()
        ScreenCaptureService.shared.suspend()
        RecentCaptureService.shared.suspend()
        ScreenTextService.shared.suspend()
        CameraPreviewService.shared.suspend()
        RadialMenuService.shared.suspend()
        ScratchpadService.shared.suspend()
        CommandBarService.shared.suspend()
        PreciseVolumeRollerService.shared.suspend()
        // Leaving the mic cut after the app is gone would strand the user
        // with a silent input and no indicator anywhere.
        let microphonesRestored = MicMuteService.shared.unmuteForTeardown()
        MicMuteService.shared.suspend()
        return mouseAccelerationRestored && microphonesRestored
    }

    @discardableResult
    private static func detachFromSystem(verifyLoginRemoval: Bool = false) -> Bool {
        if UserDefaults.standard.bool(forKey: DefaultsKey.sleepDisabledFlag),
           !restoreSleepBeforeRemoval() {
            return false
        }
        guard FanControlService.restoreAndUnregisterForRemoval() else { return false }
        // Unregister the login item (scoped to our bundle id). The stored
        // intent goes with it, or the startup repair would quietly register
        // the item again after the user asked for a clean detach.
        UserDefaults.standard.set(false, forKey: DefaultsKey.launchAtLoginWanted)
        if verifyLoginRemoval {
            if SMAppService.mainApp.status != .notRegistered {
                do { try SMAppService.mainApp.unregister() }
                catch { return false }
            }
        } else {
            try? SMAppService.mainApp.unregister()
        }
        return true
    }

    /// Puts normal sleep back before the app goes.
    ///
    /// `KeepAwakeManager` is allowed to give up on a failed revert when the app
    /// is merely quitting, because "the next start repairs a revert that was
    /// missed". Removal is the one exit with no next start, and the flag that
    /// would trigger that repair is deleted with the rest of the preferences a
    /// moment later — so a reinstall does not fix it either, since recovery
    /// reads the flag before it reads the setting. This is the last chance
    /// anything has, which is why it may ask for the password the launch-time
    /// recovery would have asked for.
    private static func restoreSleepBeforeRemoval() -> Bool {
        // The flag can outlive the setting, so a stale one must not put a
        // password dialog in front of someone uninstalling. Only a reading that
        // answered, and answered "off", is allowed to skip the rest: a probe
        // that failed says nothing. Going on then costs a no-op call, and a
        // dialog only if that call fails too — the case where sleep really may
        // still be off with nothing else left to put it back.
        let probe = Shell.run("/usr/bin/pmset", ["-g"])
        if probe.status == 0, !SudoersSupport.sleepDisabled(inPmsetOutput: probe.output) {
            return true
        }
        if Sudoers.pmsetDisableSleep(false) { return true }
        guard AdminShell.runSync("pmset disablesleep 0",
                                 prompt: L10n.shared.s.adminPromptRecover) else { return false }
        let verification = Shell.run("/usr/bin/pmset", ["-g"])
        return verification.status == 0
            && !SudoersSupport.sleepDisabled(inPmsetOutput: verification.output)
    }

    private static func removeSudoersRuleIfPresent(then: @escaping (Bool) -> Void) {
        guard Sudoers.ruleFilesPresent || Sudoers.isConfigured() else { then(true); return }
        Sudoers.remove { success in then(success) }            // shows the admin password prompt
    }

    /// `tccutil reset All <bundle id>` clears Accessibility, Screen Recording,
    /// Full Disk Access, Automation and the rest, for this app only. The bundle
    /// id is a constant, so there is nothing to inject.
    @discardableResult
    private static func resetTCC() -> Bool {
        guard let bundleID else { return false }
        return Shell.run("/usr/bin/tccutil", ["reset", "All", bundleID]).status == 0
    }

    private static func removePreferences() -> [String] {
        guard let id = bundleID else { return [ProductIdentityBoundarySupport.invalidIdentityMessage] }
        CommandBarQueryHabits.removeInstallationKey()
        UserDefaults.standard.removePersistentDomain(forName: id)
        let home = NSHomeDirectory()
        let paths = [
            "\(home)/Library/Preferences/\(id).plist",
            "\(home)/Library/Saved Application State/\(id).savedState",
            "\(home)/Library/Application Support/\(id)",
            "\(home)/Library/Caches/\(id)",
            "\(home)/Library/HTTPStorages/\(id)",
            "\(home)/Library/HTTPStorages/\(id).binarycookies"
        ]
        return paths.filter { path in
            do { try FileManager.default.removeItem(atPath: path); return false }
            catch {
                return (error as NSError).domain != NSCocoaErrorDomain
                    || (error as NSError).code != NSFileNoSuchFileError
            }
        }
    }

    /// Prepares a helper that waits for an explicit commit and then process exit. The
    /// path is the running app's own location, checked to be an `.app`, so this
    /// can only ever remove this app. A detached helper does the move so the
    /// bundle is not mutated while it is running.
    private static func prepareTrashHandoff() throws -> UninstallHandoff {
        let app = Bundle.main.bundlePath
        guard app.hasSuffix(".app"), app != "/" else {
            throw NSError(domain: NSCocoaErrorDomain, code: NSFileReadUnsupportedSchemeError)
        }
        let pid = ProcessInfo.processInfo.processIdentifier
        let script = """
        #!/bin/sh
        APP="$1"; PID="$2"
        trap '/bin/rm -f "$0"' EXIT
        IFS= read -r COMMIT || exit 0
        [ "$COMMIT" = "commit" ] || exit 0
        while kill -0 "$PID" 2>/dev/null; do sleep 0.3; done
        TRASH="$HOME/.Trash"
        /bin/mkdir -p "$TRASH" 2>/dev/null || true
        BASE="$(basename "$APP")"
        DEST="$TRASH/$BASE"
        n=2
        while [ -e "$DEST" ]; do DEST="$TRASH/${BASE%.app} $n.app"; n=$((n+1)); done
        # Reversible move to the Trash. If a direct move fails, ask Finder to do
        # the same Trash operation so it can present the standard admin prompt.
        if ! /bin/mv "$APP" "$DEST" 2>/dev/null; then
            /usr/bin/osascript - "$APP" <<'APPLESCRIPT'
        on run argv
            tell application "Finder" to delete POSIX file (item 1 of argv)
        end run
        APPLESCRIPT
        fi
        if [ -d "$APP" ]; then /usr/bin/open "$APP" 2>/dev/null; fi
        /bin/rm -f "$0"
        """
        let scriptURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("vorssaint-uninstall-\(pid)-\(UUID().uuidString).sh")
        try script.write(to: scriptURL, atomically: true, encoding: .utf8)
        var descriptors: [Int32] = [-1, -1]
        guard pipe(&descriptors) == 0 else {
            try? FileManager.default.removeItem(at: scriptURL)
            throw NSError(domain: NSPOSIXErrorDomain, code: Int(errno))
        }
        defer { close(descriptors[0]) }
        do {
            guard fcntl(descriptors[1], F_SETNOSIGPIPE, 1) != -1 else {
                throw NSError(domain: NSPOSIXErrorDomain, code: Int(errno))
            }
            try DetachedProcess.spawn("/bin/sh", [scriptURL.path, app, "\(pid)"],
                                      standardInput: descriptors[0])
            return UninstallHandoff(input: descriptors[1])
        } catch {
            close(descriptors[1])
            try? FileManager.default.removeItem(at: scriptURL)
            throw error
        }
    }

    /// The helper cannot move anything until this pipe receives the full commit line.
    private final class UninstallHandoff {
        private var input: Int32
        init(input: Int32) { self.input = input }
        deinit { cancel() }
        func cancel() {
            guard input >= 0 else { return }
            close(input)
            input = -1
        }
        func commit() throws {
            let bytes = Array("commit\n".utf8)
            var offset = 0
            while offset < bytes.count {
                let written = bytes.withUnsafeBytes {
                    write(input, $0.baseAddress!.advanced(by: offset), bytes.count - offset)
                }
                if written < 0, errno == EINTR { continue }
                guard written > 0 else { throw NSError(domain: NSPOSIXErrorDomain, code: Int(errno)) }
                offset += written
            }
            cancel()
        }
    }
}
