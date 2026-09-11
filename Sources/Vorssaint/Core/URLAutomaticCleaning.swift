// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import AppKit

/// A single copied link may have rich representations. Files and composite copies stay untouched.
enum URLAutomaticCleaning {
    struct Result {
        let changeCount: Int
        let cleaned: URLCleaning.Result?
    }

    private static let allowedTypes: Set<NSPasteboard.PasteboardType> = [
        .string, .URL, .html, .rtf,
        // AppKit exposes these legacy aliases and the RTF plain-text conversion alongside UTIs.
        NSPasteboard.PasteboardType("Apple HTML pasteboard type"),
        NSPasteboard.PasteboardType("NeXT Rich Text Format v1.0 pasteboard type"),
        NSPasteboard.PasteboardType("public.utf16-external-plain-text"),
        NSPasteboard.PasteboardType("CorePasteboardFlavorType 0x75743136"),
        NSPasteboard.PasteboardType("public.url-name"),
        NSPasteboard.PasteboardType("NSStringPboardType"),
        NSPasteboard.PasteboardType("NSURLPboardType"),
    ]

    static func poll(_ pasteboard: NSPasteboard, sinceChangeCount: Int,
                     rules: URLCleaning.Rules, isCancelled: () -> Bool = { false }) -> Result? {
        let count = pasteboard.changeCount
        guard !isCancelled() else { return nil }
        func unchanged() -> Result { Result(changeCount: count, cleaned: nil) }
        guard count != sinceChangeCount,
              let items = pasteboard.pasteboardItems, items.count == 1,
              let item = items.first,
              !item.types.isEmpty, Set(item.types).isSubset(of: allowedTypes),
              let types = pasteboard.types, Set(types).isSubset(of: allowedTypes),
              let text = item.string(forType: .string),
              pasteboard.string(forType: .string) == text else { return unchanged() }
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
