// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

/// Execution state is independent of ranking and panel construction. All calls,
/// including the injected launch completion, run on the main thread.
final class CommandBarExecutor {
    struct Context {
        let presentationID: UUID
        let query: String
        let isVisible: Bool
    }
    private(set) var queryWhenRun = ""
    private(set) var selectionWhenRun = ""
    private var requests = CommandBarDestinationRequests()
    private let context: () -> Context?
    private let exists: (String) -> Bool
    private let open: (URL) -> Bool
    private let launch: (URL, @escaping (Bool) -> Void) -> Void
    private let completed: (CommandBarDestinationOpening.Result, String) -> Void

    init(context: @escaping () -> Context?, exists: @escaping (String) -> Bool,
         open: @escaping (URL) -> Bool, launch: @escaping (URL, @escaping (Bool) -> Void) -> Void,
         completed: @escaping (CommandBarDestinationOpening.Result, String) -> Void) {
        self.context = context
        self.exists = exists
        self.open = open
        self.launch = launch
        self.completed = completed
    }
    func resetInput() { queryWhenRun = ""; selectionWhenRun = "" }
    func execute(query: String, selection: String, value: Int?, keepsBarOpen: Bool,
                 waitsForOpenResult: Bool, dismiss: () -> Void, run: (Int?) -> Void) {
        queryWhenRun = query
        selectionWhenRun = selection
        if !keepsBarOpen && !waitsForOpenResult { dismiss() }
        run(value)
    }
    func begin() -> CommandBarDestinationAttempt? {
        guard let context = context() else { return nil }
        return requests.begin(presentationID: context.presentationID, query: context.query, isVisible: context.isVisible)
    }
    func accepts(_ attempt: CommandBarDestinationAttempt) -> Bool {
        guard let context = context() else { return false }
        return requests.accepts(attempt, presentationID: context.presentationID,
                                query: context.query, isVisible: context.isVisible)
    }
    func invalidate() { requests.invalidate() }
    func openDestination(_ url: URL?, title: String, attempt: CommandBarDestinationAttempt) {
        guard accepts(attempt) else { return }
        complete(attempt, result: CommandBarDestinationOpening.open(url: url, exists: exists, open: open), title: title)
    }
    func openApplication(at url: URL, title: String, attempt: CommandBarDestinationAttempt) {
        guard accepts(attempt) else { return }
        launch(url) { [weak self] succeeded in
            self?.complete(attempt, result: succeeded ? .opened : .failed, title: title)
        }
    }
    func complete(_ attempt: CommandBarDestinationAttempt,
                  result: CommandBarDestinationOpening.Result, title: String) {
        guard accepts(attempt) else { return }
        requests.invalidate()
        completed(result, title)
    }
}
