// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import Foundation

/// Runs the production closed-lid bodies without touching power state. Native
/// transport and queues are controlled; the restore policy itself is production.
enum KeepAwakeClamshellContract {
    enum DispatchQueue {
        static let main = Queue()
        static let background = Queue()
        static let native = Queue()
        enum QoS { case utility, userInitiated }
        static func global(qos: QoS) -> Queue { background }
        final class Queue {
            var immediate: [() -> Void] = []
            func async(execute: @escaping () -> Void) { immediate.append(execute) }
            func sync<T>(execute: () -> T) -> T { flush(); return execute() }
            func flush() {
                while !immediate.isEmpty {
                    let ready = immediate
                    immediate.removeAll()
                    ready.forEach { $0() }
                }
            }
        }
    }
    static func reset() -> Service {
        for queue in [DispatchQueue.main, DispatchQueue.background, DispatchQueue.native] {
            queue.immediate.removeAll()
        }
        UserDefaults.standard.values.removeAll()
        Sudoers.calls = []; Sudoers.results = [true]; Sudoers.disabled = false
        Sudoers.configured = true; Sudoers.installCompletions = []
        Sudoers.sleepStateProbeSuspensions = 0; Sudoers.probeWrites = []
        AdminShell.completions = []; AdminShell.prompts = 0; AdminShell.syncResult = false
        Shell.status = 0; Shell.output = nil
        return Service()
    }
}

extension KeepAwakeClamshellContract {
    enum EndReason { case manual, timer, battery, quit }
    enum SessionTrigger { case manual, automation }
    enum AppFeature {
        enum keepAwake { static let isAvailable = true }
    }
    enum DefaultsKey {
        static let clamshellPreferred = "preferred"
        static let sleepDisabledFlag = "disabled"
        static let keepAwakePauseWhenLocked = "pause"
    }
    enum UserDefaults {
        static let standard = Store()
        final class Store {
            var values: [String: Bool] = [:]
            func bool(forKey key: String) -> Bool { values[key] ?? false }
            func set(_ value: Bool, forKey key: String) { values[key] = value }
        }
    }
    enum Sudoers {
        // Extracted methods live in a qualified extension, whose lookup must
        // stay inside the fixture rather than finding application transports.
        typealias DispatchQueue = KeepAwakeClamshellContract.DispatchQueue
        typealias Shell = KeepAwakeClamshellContract.Shell
        typealias AdminShell = KeepAwakeClamshellContract.AdminShell
        static var calls: [Bool] = []
        static var results = [true]
        static var disabled = false
        static var configured = true
        static var installCompletions: [(Bool) -> Void] = []
        static let sleepStateQueue = DispatchQueue.native
        static var sleepStateProbeSuspensions = 0
        static var probeWrites: [Bool] = []
        static func pmsetDisableSleepOnQueue(_ on: Bool) -> Bool {
            probeWrites.append(on)
            if configured { disabled = on }
            return configured
        }
        static func install(completion: @escaping (Bool) -> Void) {
            installCompletions.append { ok in completion(ok && isConfigured()) }
        }
        static func execute(_ on: Bool) -> Bool {
            calls.append(on)
            let ok = results.count > 1 ? results.removeFirst() : results[0]
            if ok { disabled = on }
            return ok
        }
        static func pmsetDisableSleep(_ on: Bool) -> Bool {
            DispatchQueue.native.flush()
            return execute(on)
        }
        static func pmsetDisableSleep(_ on: Bool, completion: @escaping (Bool) -> Void) {
            DispatchQueue.native.async { completion(execute(on)) }
        }
    }
    enum AdminShell {
        static var completions: [(Bool) -> Void] = []
        static var prompts = 0
        static var syncResult = false
        static func run(_ command: String, prompt: String, completion: @escaping (Bool) -> Void) {
            prompts += 1; completions.append(completion)
        }
        static func runSync(_ command: String, prompt: String) -> Bool {
            prompts += 1
            if syncResult { Sudoers.disabled = false }
            return syncResult
        }
        static func answer(_ ok: Bool) {
            if ok { Sudoers.disabled = false }
            let ready = completions; completions.removeAll()
            ready.forEach { $0(ok) }
        }
    }
    enum L10n {
        static let shared = Localized()
        struct Localized { let s = Strings() }
        struct Strings {
            let adminPromptClamshellOff = "restore"
            let adminPromptRecover = "recover"
        }
    }
    enum Shell {
        static var status: Int32 = 0
        static var output: String?
        static func run(_ executable: String, _ arguments: [String]) -> (status: Int32, output: String) {
            (status, output ?? "SleepDisabled \(Sudoers.disabled ? 1 : 0)")
        }
    }
    static func drain() {
        for _ in 0..<30 {
            let queues = [DispatchQueue.background, DispatchQueue.native, DispatchQueue.main]
            if queues.allSatisfy({ $0.immediate.isEmpty }) { return }
            queues.forEach { $0.flush() }
        }
    }
}

/// Exercises extracted session, restore, setup and retry bodies together.
/// The only substituted pieces are native transports, time and unrelated UI.
enum KeepAwakeClamshellTests {
    private typealias C = KeepAwakeClamshellContract

    private static func active() -> C.Service {
        let service = C.reset()
        service.isActive = true; service.clamshellActive = true; service.assertionsHeld = true
        C.Sudoers.disabled = true
        C.UserDefaults.standard.set(true, forKey: C.DefaultsKey.sleepDisabledFlag)
        return service
    }

    static func run(expect: (Bool, String) -> Void) {
        let staleStatus = C.reset(); staleStatus.isActive = true
        staleStatus.refreshPasswordlessStatus()
        staleStatus.enableClamshell()
        C.DispatchQueue.native.flush(); C.DispatchQueue.main.flush()
        C.Sudoers.configured = false
        C.DispatchQueue.background.flush(); C.DispatchQueue.main.flush()
        expect(staleStatus.passwordlessClamshell,
               "a status request from before a newer enable cannot overwrite that operation's verified result")

        let quitting = active()
        quitting.deactivate(reason: .quit)
        expect(C.Sudoers.calls == [false] && !C.Sudoers.disabled
               && !quitting.isActive && !quitting.assertionsHeld,
               "quit restores the system synchronously and ends the session")
        expect(!C.UserDefaults.standard.bool(forKey: C.DefaultsKey.sleepDisabledFlag) && C.AdminShell.prompts == 0,
               "successful quit clears recovery before returning and never asks for a password")

        let plain = C.reset()
        plain.deactivate(reason: .quit)
        expect(C.Sudoers.calls.isEmpty,
               "quit without an owned override changes no system power state")

        let failed = active(); C.Sudoers.results = [false]
        failed.deactivate(reason: .quit)
        expect(C.UserDefaults.standard.bool(forKey: C.DefaultsKey.sleepDisabledFlag)
               && C.AdminShell.prompts == 0,
               "failed silent quit keeps recovery evidence and never asks for a password")

        let enabling = C.reset(); enabling.isActive = true
        enabling.enableClamshell()
        expect(C.UserDefaults.standard.bool(forKey: C.DefaultsKey.sleepDisabledFlag),
               "an in-flight enable is recorded before its native command or main reply finishes")
        enabling.deactivate(reason: .quit)
        C.DispatchQueue.main.flush()
        expect(C.Sudoers.calls == [true, false] && !C.Sudoers.disabled && !enabling.clamshellActive
               && !C.UserDefaults.standard.bool(forKey: C.DefaultsKey.sleepDisabledFlag),
               "quit drains a pending enable and an obsolete reply cannot resurrect its override or marker")

        let restoring = active(); C.Sudoers.results = [false, true]
        restoring.deactivate(reason: .manual)
        C.drain()
        restoring.activate(minutes: 0, trigger: .manual)
        C.drain()
        expect(C.Sudoers.calls == [false] && C.AdminShell.prompts == 1,
               "a new session waits while the older restore authorization is pending")
        C.AdminShell.answer(true); C.drain()
        expect(C.Sudoers.calls == [false, true] && C.Sudoers.disabled && restoring.clamshellActive,
               "successful delayed restore enables the current session without overwriting it")

        let latePrompt = active(); C.Sudoers.results = [false, true]
        latePrompt.deactivate(reason: .manual)
        C.drain()
        latePrompt.deactivate(reason: .quit)
        C.AdminShell.answer(true); C.DispatchQueue.main.flush()
        expect(C.AdminShell.prompts == 1 && C.Sudoers.calls == [false, false] && !C.Sudoers.disabled,
               "quit never waits for or repeats an existing authorization; its late reply cannot re-enable")

        let setup = C.reset(); setup.isActive = true; C.Sudoers.configured = false
        setup.prepareClamshellPreference(); C.drain()
        setup.deactivate(reason: .quit)
        C.Sudoers.installCompletions.forEach { $0(true) }; C.drain()
        expect(!C.Sudoers.calls.contains(true), "successful setup arriving after quit cannot submit an enable")
        let setupProbe = C.reset(); C.Sudoers.configured = false
        setupProbe.prepareClamshellPreference(); setupProbe.deactivate(reason: .quit)
        C.drain()
        expect(C.Sudoers.installCompletions.isEmpty, "a setup probe returning after quit cannot open an authorization prompt")

        let recovering = C.reset(); C.UserDefaults.standard.set(true, forKey: C.DefaultsKey.sleepDisabledFlag)
        C.Sudoers.disabled = true; C.Sudoers.results = [false, true]
        recovering.recoverIfNeeded()
        C.drain()
        recovering.passwordlessClamshell = false
        recovering.activate(minutes: 0, trigger: .manual)
        C.drain()
        expect(C.Sudoers.calls == [false] && C.Sudoers.installCompletions.isEmpty,
               "launch recovery holds both enable and setup for a new manual session behind its pending off")
        C.AdminShell.answer(true); C.drain()
        expect(C.Sudoers.calls == [false, true] && C.Sudoers.disabled && recovering.clamshellActive,
               "delayed launch recovery completes before the new manual session enables closed-lid mode")

        let unreadable = C.reset(); C.UserDefaults.standard.set(true, forKey: C.DefaultsKey.sleepDisabledFlag)
        C.Shell.status = -1; C.Shell.output = ""; C.Sudoers.results = [false]
        unreadable.recoverIfNeeded(); C.drain()
        C.AdminShell.answer(false); C.DispatchQueue.main.flush()
        expect(C.UserDefaults.standard.bool(forKey: C.DefaultsKey.sleepDisabledFlag),
               "failed power-state reads and refused recovery never erase evidence of an owned override")

        _ = C.reset(); C.Sudoers.disabled = true
        expect(C.Sudoers.isConfigured(), "a probe before authorization verifies the current state")
        let priorWrites = C.Sudoers.probeWrites
        C.Sudoers.restoreSleepWithAuthorization(prompt: "restore", shouldProceed: { true }) { _ in }
        C.drain()
        expect(!C.Sudoers.isConfigured() && C.Sudoers.probeWrites == priorWrites,
               "a pending authorization blocks late probes from reapplying stale disabled-sleep state")
        expect(C.Sudoers.pmsetDisableSleep(false),
               "a silent quit restore can drain the native queue while authorization remains unanswered")
        C.AdminShell.answer(true); C.drain()
        expect(C.Sudoers.isConfigured() && C.Sudoers.probeWrites.last == false && !C.Sudoers.disabled,
               "probes resume only after authorization finishes and then observe the restored state")

        _ = C.reset(); C.Sudoers.disabled = true
        var mayPrompt = true
        C.Sudoers.restoreSleepWithAuthorization(prompt: "restore", shouldProceed: { mayPrompt }) { _ in }
        C.DispatchQueue.native.flush()
        mayPrompt = false
        C.drain()
        expect(C.AdminShell.prompts == 0 && C.Sudoers.sleepStateProbeSuspensions == 0,
               "authorization revalidates on the main thread and releases probe suspension after cancellation")

        let deniedSetup = C.reset(); deniedSetup.isActive = true
        C.Sudoers.results = [false]; C.Sudoers.configured = false
        deniedSetup.enableClamshell(); C.drain()
        expect(C.Sudoers.installCompletions.count == 1,
               "a failed enable offers its one passwordless setup repair")
        C.Sudoers.installCompletions.forEach { $0(false) }; C.drain()
        expect(!deniedSetup.clamshellPreferred && deniedSetup.clamshellSetupFailed
               && C.AdminShell.prompts == 0 && !C.Sudoers.disabled
               && !C.UserDefaults.standard.bool(forKey: C.DefaultsKey.sleepDisabledFlag),
               "denying repair does not ask for another password when the failed enable left sleep enabled")

        _ = C.reset()
        var alreadyRestored = false
        C.Sudoers.restoreSleepWithAuthorization(prompt: "restore", shouldProceed: { true }) { alreadyRestored = $0 }
        C.drain()
        expect(alreadyRestored && C.AdminShell.prompts == 0 && C.Sudoers.sleepStateProbeSuspensions == 0,
               "a confirmed already-restored override succeeds without authorization and releases probes")
        _ = C.reset(); C.Shell.status = -1; C.Shell.output = ""
        C.Sudoers.restoreSleepWithAuthorization(prompt: "restore", shouldProceed: { true }) { _ in }
        C.drain()
        expect(C.AdminShell.prompts == 1 && C.Sudoers.sleepStateProbeSuspensions == 1,
               "an unreadable power report cannot bypass the normal restore authorization")
        C.AdminShell.answer(false); C.drain()

        let staleSetup = active(); C.Sudoers.configured = false
        staleSetup.prepareClamshellPreference(); C.drain()
        C.Sudoers.results = [false]
        staleSetup.deactivate(reason: .manual); C.drain()
        C.Sudoers.configured = true
        C.Sudoers.installCompletions.forEach { $0(true) }; C.drain()
        expect(staleSetup.clamshellPreferred && C.AdminShell.prompts == 1,
               "a setup reply invalidated by restore cannot open another prompt or turn off the saved preference")
        C.AdminShell.answer(true); C.drain()
        expect(!C.Sudoers.disabled && !C.UserDefaults.standard.bool(forKey: C.DefaultsKey.sleepDisabledFlag),
               "late setup probes cannot resurrect the override cleared by authorized restore")
    }
}
