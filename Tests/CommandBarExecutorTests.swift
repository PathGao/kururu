// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

enum CommandBarExecutorTests {
    static func run(_ expect: (Bool, String) -> Void) {
        var context: CommandBarExecutor.Context? = .init(presentationID: UUID(), query: "original", isVisible: true)
        var launchCompletions: [(Bool) -> Void] = []
        var opened: [URL] = []
        var results: [(CommandBarDestinationOpening.Result, String)] = []
        let executor = CommandBarExecutor(context: { context }, exists: { _ in false },
            open: { opened.append($0); return true },
            launch: { _, completion in launchCompletions.append(completion) },
            completed: { results.append(($0, $1)) })
        var events: [String] = []
        executor.execute(query: "typed", selection: "selected", value: 42,
                         keepsBarOpen: false, waitsForOpenResult: false,
                         dismiss: {
                             events.append("hide")
                             expect(executor.queryWhenRun == "typed" && executor.selectionWhenRun == "selected",
                                    "action input is captured before dismissal clears the search")
                         }, run: {
                             events.append("run")
                             expect($0 == 42, "execution preserves the validated numeric argument")
                         })
        expect(events == ["hide", "run"], "ordinary actions run after the panel dismisses")
        for (keep, wait) in [(true, false), (false, true), (true, true)] {
            events = []
            executor.execute(query: "next", selection: "", value: nil, keepsBarOpen: keep,
                             waitsForOpenResult: wait, dismiss: { events.append("hide") },
                             run: { _ in events.append("run") })
            expect(events == ["run"], "keep-open and pending-destination actions retain the panel")
        }
        executor.resetInput()
        expect(executor.queryWhenRun.isEmpty && executor.selectionWhenRun.isEmpty,
               "a new presentation discards previous execution input")
        let missing = executor.begin()!
        executor.openDestination(URL(fileURLWithPath: "/missing"), title: "file", attempt: missing)
        expect(results.last?.0 == .unavailable && opened.isEmpty,
               "missing destinations never reach the platform opener")
        expect(!executor.accepts(missing), "completion consumes the request once")
        let app = URL(fileURLWithPath: "/Applications/Test.app")
        let first = executor.begin()!
        executor.openApplication(at: app, title: "old", attempt: first)
        let second = executor.begin()!
        executor.openApplication(at: app, title: "new", attempt: second)
        expect(launchCompletions.count == 2, "application launches use the asynchronous boundary")
        // Keep the remaining tests runnable against the intentionally incomplete implementation.
        guard launchCompletions.count == 2 else { return }
        let before = results.count
        launchCompletions[0](false)
        expect(results.count == before, "an older launch failure cannot replace a newer attempt")
        launchCompletions[1](true)
        expect(results.last?.0 == .opened && results.last?.1 == "new", "the current launch completion is reported")
        launchCompletions[1](false)
        expect(results.count == before + 1, "duplicate completions cannot overwrite the consumed result")
        for change in 0..<4 {
            context = .init(presentationID: UUID(), query: "same", isVisible: true)
            let attempt = executor.begin()!
            executor.openApplication(at: app, title: "late", attempt: attempt)
            let original = context!
            switch change {
            case 0: context = .init(presentationID: original.presentationID, query: "changed", isVisible: true)
            case 1: context = .init(presentationID: original.presentationID, query: "same", isVisible: false)
            case 2: context = .init(presentationID: UUID(), query: "same", isVisible: true)
            default: executor.invalidate()
            }
            let count = results.count
            launchCompletions.last!(false)
            expect(results.count == count, "changed query, hide, reopen, and cancel reject late results: \(change)")
        }
        context = .init(presentationID: UUID(), query: "", isVisible: false)
        let hidden = executor.begin()!
        executor.openApplication(at: app, title: "shortcut", attempt: hidden)
        launchCompletions.last!(false)
        expect(results.last?.0 == .failed && results.last?.1 == "shortcut",
               "hidden shortcut failures remain reportable without opening a panel")
        context = nil
        expect(executor.begin() == nil, "a released search cannot start a destination request")
    }
}
