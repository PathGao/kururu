import Foundation

enum MediaCancellationTests {
    static func run(_ expect: (Bool, String) -> Void) {
        let cancelled = MediaCancellationToken()
        expect(!cancelled.isCancelled, "new media operation can start")
        expect(cancelled.cancel() && cancelled.isCancelled, "cancellation before commit stops work")
        expect(!cancelled.markCommitted() && cancelled.isCancelled, "cancelled operation cannot claim a committed output")
        let committed = MediaCancellationToken()
        expect(committed.markCommitted(), "active operation can commit its output")
        expect(!committed.cancel() && !committed.isCancelled, "late cancel preserves an already committed result")
        let replacement = MediaCancellationToken()
        expect(replacement.cancel() && replacement.isCancelled && !committed.isCancelled,
               "replacement operation cancellation cannot change an older committed result")
    }
}
