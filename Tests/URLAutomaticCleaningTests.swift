import AppKit

/// Named pasteboards only: these tests never read or write the system clipboard.
enum URLAutomaticCleaningTests {
    static func run(_ expect: (Bool, String) -> Void) {
        let board = NSPasteboard(name: NSPasteboard.Name("kururu-url-test-" + UUID().uuidString))
        defer { board.releaseGlobally() }
        let original = "https://www.youtube.com/watch?v=1&si=x&t=42"
        let expected = "https://www.youtube.com/watch?v=1&t=42"
        func item(_ text: String = "https://www.youtube.com/watch?v=1&si=x&t=42",
                  extra: NSPasteboard.PasteboardType? = nil) -> NSPasteboardItem {
            let item = NSPasteboardItem()
            item.setString(text, forType: .string)
            if extra == .html {
                item.setString("<a href=\"" + text + "\">" + text + "</a>", forType: .html)
            } else if extra == .rtf {
                item.setString("{\\rtf1\\ansi " + text + "}", forType: .rtf)
            } else if let extra {
                item.setData(Data("fixture payload".utf8), forType: extra)
            }
            return item
        }
        func install(_ items: [NSPasteboardItem]) {
            board.clearContents()
            expect(board.writeObjects(items), "named board accepts fixture")
        }
        func snapshot() -> [[String: Data]] {
            (board.pasteboardItems ?? []).map { item in
                Dictionary(uniqueKeysWithValues: item.types.map { ($0.rawValue, item.data(forType: $0) ?? Data()) })
            }
        }
        for rich: NSPasteboard.PasteboardType? in [nil, .html, .rtf] {
            install([item(extra: rich)])
            let result = URLAutomaticCleaning.poll(board, sinceChangeCount: -1, rules: .none)
            expect(result?.cleaned?.url == expected, "single plain/rich URL cleans si")
            expect(board.string(forType: .string) == expected && board.string(forType: .URL) == expected,
                   "cleaned plain and URL representations agree")
            expect(!(board.types ?? []).contains(.html) && !(board.types ?? []).contains(.rtf), "stale rich representations removed")
        }
        // A browser's or a messaging app's private note next to the link is
        // dropped by the rewrite, like the formatted copies above.
        for note in ["org.chromium.source-url", "com.apple.WebKit.custom-pasteboard-data", "custom.payload"] {
            install([item(extra: NSPasteboard.PasteboardType(note))])
            let result = URLAutomaticCleaning.poll(board, sinceChangeCount: -1, rules: .none)
            expect(result?.cleaned?.url == expected && board.string(forType: .string) == expected,
                   "a link copied with a private note is cleaned: " + note)
        }
        let urlOnly = NSPasteboardItem()
        urlOnly.setString(original, forType: .URL)
        install([urlOnly])
        expect(URLAutomaticCleaning.poll(board, sinceChangeCount: -1, rules: .none)?.cleaned?.url == expected
               && board.string(forType: .string) == expected,
               "a link copied only as a URL is cleaned")
        let blockedTypes: [NSPasteboard.PasteboardType] = [.png, .tiff, .fileURL, .pdf,
                                                           NSPasteboard.PasteboardType("org.nspasteboard.ConcealedType")]
        for type in blockedTypes {
            install([item(extra: type)])
            let before = snapshot(), count = board.changeCount
            let result = URLAutomaticCleaning.poll(board, sinceChangeCount: -1, rules: .none)
            expect(result?.cleaned == nil && snapshot() == before && board.changeCount == count,
                   "non-link payload retained byte-for-byte: " + type.rawValue)
        }
        for text in [original + "\nhttps://example.com", original + " more", "not a URL", "file:///tmp/a?si=x", "https://example.com/no-tracker"] {
            install([item(text, extra: .html)])
            let before = snapshot(), count = board.changeCount
            _ = URLAutomaticCleaning.poll(board, sinceChangeCount: -1, rules: .none)
            expect(snapshot() == before && board.changeCount == count, "non-single/unchanged URL untouched")
        }
        install([item(), item("https://youtu.be/second?si=x")])
        let multiple = snapshot(), multipleCount = board.changeCount
        _ = URLAutomaticCleaning.poll(board, sinceChangeCount: -1, rules: .none)
        expect(snapshot() == multiple && board.changeCount == multipleCount, "multiple items untouched")
        install([item()])
        var reads = 0
        var replacement: [[String: Data]] = []
        let raced = URLAutomaticCleaning.poll(board, sinceChangeCount: -1, rules: .none, isCancelled: {
            reads += 1
            if reads == 2 {
                board.clearContents()
                board.writeObjects([item("new user copy", extra: .html)])
                replacement = snapshot()
            }
            return false
        })
        expect(raced?.cleaned == nil && snapshot() == replacement, "new copy before write is not overwritten")
        install([item()])
        let beforeCancel = snapshot(), count = board.changeCount
        expect(URLAutomaticCleaning.poll(board, sinceChangeCount: -1, rules: .none, isCancelled: { true }) == nil,
               "cancelled poll returns no result")
        expect(snapshot() == beforeCancel && board.changeCount == count, "cancel leaves all bytes and types unchanged")
        var cancellationChecks = 0
        let lateCancelled = URLAutomaticCleaning.poll(board, sinceChangeCount: -1, rules: .none, isCancelled: {
            cancellationChecks += 1
            return cancellationChecks == 2
        })
        expect(lateCancelled == nil && snapshot() == beforeCancel && board.changeCount == count,
               "cancellation immediately before write preserves all representations")
    }
}
