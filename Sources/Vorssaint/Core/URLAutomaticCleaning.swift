// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import AppKit

/// A single copied link may have rich representations and an app's private
/// notes about the copy. Files, pictures and composite copies stay untouched.
enum URLAutomaticCleaning {
    struct Result {
        let changeCount: Int
        let cleaned: URLCleaning.Result?
    }

    static func poll(_ pasteboard: NSPasteboard, sinceChangeCount: Int,
                     rules: URLCleaning.Rules, isCancelled: () -> Bool = { false }) -> Result? {
        let count = pasteboard.changeCount
        guard !isCancelled() else { return nil }
        func unchanged() -> Result { Result(changeCount: count, cleaned: nil) }
        guard count != sinceChangeCount,
              let items = pasteboard.pasteboardItems, items.count == 1,
              let item = items.first,
              // The types decide before any content is read: a picture or a
              // file is never fetched only to be left alone. Some "copy link"
              // commands put the link on the pasteboard only as a URL, with no
              // text next to it.
              URLCleaning.canRewritePasteboard(types: (pasteboard.types ?? []).map(\.rawValue)),
              let text = item.string(forType: .string) ?? item.string(forType: .URL) else { return unchanged() }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed.rangeOfCharacter(from: .whitespacesAndNewlines) == nil,
              let cleaned = URLCleaning.clean(trimmed, rules: rules), cleaned.url != trimmed else { return unchanged() }
        guard !isCancelled() else { return nil }
        // This narrows the external-copy race; NSPasteboard has no cross-process compare-and-swap.
        guard pasteboard.changeCount == count else { return unchanged() }
        pasteboard.clearContents()
        let plainWritten = pasteboard.setString(cleaned.url, forType: .string)
        let urlWritten = pasteboard.setString(cleaned.url, forType: .URL)
        return Result(changeCount: pasteboard.changeCount,
                      cleaned: plainWritten && urlWritten ? cleaned : nil)
    }
}
