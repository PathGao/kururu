// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import AppKit
import Foundation

typealias ProductionInputSourceSelection = InputSourceSelection

/// Production borrow/restore methods with an inert input source and controlled
/// next-turn delivery; the machine's keyboard layout is never changed.
enum CommandBarInputSourceContract {
    enum Preferences {
        static var standard: Preferences.Type { Self.self }
        static var enabled = true
        static func bool(forKey: String) -> Bool { enabled }
    }
    enum Sources {
        static var current = "original"
        static var acceptsSelection = true
        static var selected: [String] = []
        static func currentSourceID() -> String? { current }
        static func snapshots() -> [ProductionInputSourceSelection.Snapshot] {
            [.init(id: "original", isLayout: true, isASCIICapable: false),
             .init(id: "ascii", isLayout: true, isASCIICapable: true)]
        }
        static func asciiLayoutID(currentID: String?,
                                  snapshots: [ProductionInputSourceSelection.Snapshot]) -> String? {
            ProductionInputSourceSelection.asciiLayoutID(currentID: currentID, snapshots: snapshots)
        }
        static func select(sourceID: String) -> Bool {
            guard acceptsSelection else { return false }
            current = sourceID
            selected.append(sourceID)
            return true
        }
    }
    enum Queue {
        static var main: Queue.Type { Self.self }
        static var jobs: [() -> Void] = []
        static func async(execute action: @escaping () -> Void) { jobs.append(action) }
        static func sync(execute action: () -> Void) { action() }
        static func drain() { while !jobs.isEmpty { jobs.removeFirst()() } }
    }
    class Fixture {
        typealias UserDefaults = Preferences
        typealias InputSourceSelection = Sources
        typealias DispatchQueue = Queue
        var suspendedInputSourceID: String?
        var presentationID = UUID()
    }
    static func run(_ suite: TestSuite) {
        defer { Queue.jobs = []; Sources.selected = []; Sources.acceptsSelection = true; Preferences.enabled = true }
        func reset() -> Service {
            Queue.jobs = []
            Sources.current = "original"
            Sources.selected = []
            Sources.acceptsSelection = true
            Preferences.enabled = true
            return Service()
        }
        let normal = reset()
        normal.adoptASCIIInputSource()
        normal.restoreSuspendedInputSource()
        suite.expect(Sources.current == "ascii", "closing inside a key event defers keyboard restoration")
        Queue.drain()
        suite.expect(Sources.selected == ["ascii", "original"] && normal.suspendedInputSourceID == nil,
                     "ordinary close restores the original layout exactly once")
        let reopened = reset()
        reopened.adoptASCIIInputSource()
        reopened.restoreSuspendedInputSource()
        reopened.presentationID = UUID()
        reopened.adoptASCIIInputSource()
        Queue.drain()
        suite.expect(Sources.current == "ascii", "a stale close cannot switch the layout under the reopened bar")
        reopened.restoreSuspendedInputSource()
        reopened.restoreSuspendedInputSource()
        Queue.drain()
        suite.expect(Sources.selected == ["ascii", "original"] && reopened.suspendedInputSourceID == nil,
                     "closing after a fast reopen restores the original layout without duplicate switches")
        for alreadyASCII in [false, true] {
            let untouched = reset()
            if alreadyASCII { Sources.current = "ascii" } else { Preferences.enabled = false }
            untouched.adoptASCIIInputSource()
            untouched.restoreSuspendedInputSource()
            Queue.drain()
            suite.expect(Sources.selected.isEmpty, "an ASCII or opted-out opening leaves the keyboard alone")
        }
        let disabledOnReopen = reset()
        disabledOnReopen.adoptASCIIInputSource()
        disabledOnReopen.restoreSuspendedInputSource()
        Preferences.enabled = false
        disabledOnReopen.presentationID = UUID()
        disabledOnReopen.adoptASCIIInputSource()
        Queue.drain()
        suite.expect(Sources.current == "original" && disabledOnReopen.suspendedInputSourceID == nil,
                     "reopening with borrowing disabled completes the previous restoration")
        let refusedRestore = reset()
        refusedRestore.adoptASCIIInputSource()
        Sources.acceptsSelection = false
        refusedRestore.restoreSuspendedInputSource()
        Queue.drain()
        suite.expect(Sources.current == "ascii" && refusedRestore.suspendedInputSourceID == "original",
                     "a rejected restoration keeps its original source available for retry")
        Sources.acceptsSelection = true
        refusedRestore.restoreSuspendedInputSource()
        Queue.drain()
        suite.expect(Sources.current == "original" && refusedRestore.suspendedInputSourceID == nil,
                     "a later accepted restoration releases the borrowing obligation")
        let terminating = reset()
        terminating.adoptASCIIInputSource()
        terminating.restoreSuspendedInputSource()
        terminating.restoreBorrowedInputSource()
        suite.expect(Sources.current == "original" && terminating.suspendedInputSourceID == nil,
                     "termination restores the borrowed source without waiting for the run loop")
        Queue.drain()
        suite.expect(Sources.selected == ["ascii", "original"],
                     "a pending normal close cannot repeat a completed termination restoration")
        let refused = reset()
        Sources.acceptsSelection = false
        refused.adoptASCIIInputSource()
        refused.restoreSuspendedInputSource()
        Queue.drain()
        suite.expect(Sources.current == "original" && refused.suspendedInputSourceID == nil,
                     "a refused source switch never creates a restoration obligation")
    }
}

/// The delegate's real termination callback runs in real default and modal
/// run-loop modes, with inert replies and input sources. No app quits or layout changes.
enum CommandBarTerminationContract {
    final class Application {
        enum TerminateReply { case terminateNow, terminateLater, terminateCancel }
        var replies: [Bool] = []
        var sourceAtReply: [String] = []
        func reply(toApplicationShouldTerminate accepted: Bool) {
            sourceAtReply.append(CommandBarInputSourceContract.Sources.current)
            replies.append(accepted)
        }
    }
    enum Bar {
        static var shared = CommandBarInputSourceContract.Service()
    }
    class Fixture {
        typealias NSApplication = Application
        typealias CommandBarService = Bar
        var inputSourceRestorationPending = false
        /// The unsaved notes prompt runs before the layout is given back.
        var discardsUnsavedNotes = true
        func mayDiscardUnsavedNotes(_ sender: Application) -> Bool { discardsUnsavedNotes }
    }
    static func run(_ suite: TestSuite) {
        func reset(borrowed: Bool) -> (Host, Application) {
            Bar.shared = CommandBarInputSourceContract.Service()
            Bar.shared.suspendedInputSourceID = borrowed ? "original" : nil
            CommandBarInputSourceContract.Sources.current = borrowed ? "ascii" : "original"
            CommandBarInputSourceContract.Sources.selected = []
            CommandBarInputSourceContract.Sources.acceptsSelection = true
            return (Host(), Application())
        }
        func awaitReply(_ app: Application, mode: RunLoop.Mode = .default) {
            let deadline = ProcessInfo.processInfo.systemUptime + 2
            while app.replies.isEmpty && ProcessInfo.processInfo.systemUptime < deadline {
                _ = RunLoop.current.run(mode: mode, before: Date(timeIntervalSinceNow: 0.005))
            }
        }
        defer {
            Bar.shared = CommandBarInputSourceContract.Service()
            CommandBarInputSourceContract.Sources.current = "original"
            CommandBarInputSourceContract.Sources.selected = []
            CommandBarInputSourceContract.Sources.acceptsSelection = true
        }
        let (idle, idleApp) = reset(borrowed: false)
        suite.expect(idle.applicationShouldTerminate(idleApp) == .terminateNow
                     && idleApp.replies.isEmpty,
                     "termination without a borrowed layout does not create an asynchronous reply")
        let (host, app) = reset(borrowed: true)
        suite.expect(host.applicationShouldTerminate(app) == .terminateLater
                     && CommandBarInputSourceContract.Sources.selected.isEmpty && app.replies.isEmpty,
                     "a quit request returns before restoring its input source or replying")
        suite.expect(host.applicationShouldTerminate(app) == .terminateLater,
                     "a repeated quit waits for the same pending restoration")
        awaitReply(app)
        suite.expect(app.replies == [true] && app.sourceAtReply == ["original"]
                     && CommandBarInputSourceContract.Sources.selected == ["original"],
                     "the next run-loop turn restores once before sending the single quit reply")
        suite.expect(!host.inputSourceRestorationPending && !Bar.shared.hasBorrowedInputSource,
                     "completed termination preparation releases its pending state")
        let (restoredHost, restoredApp) = reset(borrowed: true)
        _ = restoredHost.applicationShouldTerminate(restoredApp)
        Bar.shared.restoreBorrowedInputSource()
        suite.expect(restoredHost.applicationShouldTerminate(restoredApp) == .terminateLater,
                     "a repeated quit cannot bypass an already queued reply after another path restored")
        awaitReply(restoredApp)
        suite.expect(restoredApp.replies == [true]
                     && CommandBarInputSourceContract.Sources.selected == ["original"],
                     "an earlier successful restoration is not selected again before the pending reply")
        let (refusedHost, refusedApp) = reset(borrowed: true)
        CommandBarInputSourceContract.Sources.acceptsSelection = false
        _ = refusedHost.applicationShouldTerminate(refusedApp)
        awaitReply(refusedApp)
        suite.expect(refusedApp.replies == [true] && Bar.shared.hasBorrowedInputSource
                     && !refusedHost.inputSourceRestorationPending,
                     "an unavailable original layout cannot strand termination waiting for a reply")
        let (keptHost, keptApp) = reset(borrowed: true)
        keptHost.discardsUnsavedNotes = false
        suite.expect(keptHost.applicationShouldTerminate(keptApp) == .terminateCancel
                     && CommandBarInputSourceContract.Sources.selected.isEmpty
                     && Bar.shared.hasBorrowedInputSource && !keptHost.inputSourceRestorationPending,
                     "a quit cancelled at the unsaved notes prompt keeps the borrowed layout and pends nothing")

        // AppKit's terminate-later loop can be nested inside a main-queue
        // callback. That queue cannot drain another block until the modal
        // loop returns, so the restoration must be serviced by the loop itself.
        let (modalHost, modalApp) = reset(borrowed: true)
        var modalLoopFinished = false
        var repliedInsideModalLoop = false
        DispatchQueue.main.async {
            let decision = modalHost.applicationShouldTerminate(modalApp)
            suite.expect(decision == .terminateLater && modalApp.replies.isEmpty,
                         "a main-queue quit defers its reply before entering the modal loop")
            awaitReply(modalApp, mode: .modalPanel)
            repliedInsideModalLoop = modalApp.replies == [true]
                && modalApp.sourceAtReply == ["original"]
                && !modalHost.inputSourceRestorationPending
            modalLoopFinished = true
        }
        let modalDeadline = ProcessInfo.processInfo.systemUptime + 3
        while !modalLoopFinished && ProcessInfo.processInfo.systemUptime < modalDeadline {
            _ = RunLoop.current.run(mode: .default, before: Date(timeIntervalSinceNow: 0.005))
        }
        suite.expect(modalLoopFinished && repliedInsideModalLoop,
                     "restoration and reply finish inside a modal loop nested in the main queue")
        // A regression may only deliver after leaving the modal mode; drain
        // that reply before fixture cleanup while retaining the failed verdict.
        awaitReply(modalApp)
    }
}
