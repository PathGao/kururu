import Foundation

enum EnvironmentCopyTests {
    static func run(_ expect: (Bool, String) -> Void) {
        var feedback = EnvironmentCopyFeedback()
        let path = "/Users/example/Library/Application Support/tools/node"
        var written = ""
        feedback.copy(path, target: "node") { written = $0; return true }
        expect(written == path, "copy preserves the complete absolute path including spaces")
        expect(feedback.result(for: "node") == true, "successful write displays success for the copied row")
        expect(feedback.result(for: "python") == nil, "another row must not inherit success")
        feedback.copy("diagnostic\nreport", target: "report") { written = $0; return false }
        expect(written == "diagnostic\nreport", "report retains its full multiline content")
        expect(feedback.result(for: "report") == false, "failed write displays failure instead of success")
        expect(feedback.result(for: "node") == nil, "a later copy clears stale feedback on the previous row")
        feedback.copy(path, target: "report") { _ in true }
        expect(feedback.result(for: "report") == true, "retry replaces a failure with the latest successful result")
        feedback.clear()
        expect(feedback.result(for: "report") == nil, "refresh clears prior copy feedback")
    }
}
