// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

enum ClipboardEncodingTests {
    static func run(_ expect: (Bool, String) -> Void) {
        let date = Date(timeIntervalSinceReferenceDate: 0)
        let pinned = ClipboardHistoryEntry(text: String(repeating: "\u{01}", count: 100), copiedAt: date, pinnedAt: date)
        let secondPin = ClipboardHistoryEntry(text: pinned.text, copiedAt: date, pinnedAt: date)
        expect(ClipboardHistoryEditing.encodedHistory([pinned, secondPin], byteLimit: 1000) == nil,
               "encoding refuses to discard pinned entries")
        expect(ClipboardHistoryEditing.entriesWithinEncodedLimit([pinned, secondPin], byteLimit: 1000) == nil,
               "preflight refuses the same pinned overflow")
        let recent = ClipboardHistoryEntry(text: pinned.text, copiedAt: date)
        let image = ClipboardHistoryEntry(text: "", copiedAt: date, kind: .image, imageFile: "kept.png")
        let entries = [recent, pinned, image]
        let encoded = ClipboardHistoryEditing.encodedHistory(entries, byteLimit: 1000)
        expect(encoded?.entries == [pinned, image], "ordinary overflow can be skipped while pin and later image remain")
        expect(ClipboardHistoryEditing.entriesWithinEncodedLimit(entries, byteLimit: 1000) == encoded?.entries,
               "preflight and persistence choose identical entries")
        expect(encoded.flatMap { try? JSONDecoder().decode([ClipboardHistoryEntry].self, from: $0.data) } == encoded?.entries,
               "encoded JSON round trip preserves selected entries and image reference")
        let size = (try! JSONEncoder().encode(pinned)).count + 2
        expect(ClipboardHistoryEditing.encodedHistory([pinned], byteLimit: size)?.entries == [pinned],
               "exact encoded boundary accepts a pinned entry")
        expect(ClipboardHistoryEditing.encodedHistory([pinned], byteLimit: size - 1) == nil,
               "one byte below boundary rejects pin instead of dropping it")
        expect(ClipboardHistoryEditing.encodedHistory([], byteLimit: 2)?.data == Data("[]".utf8),
               "empty JSON respects two byte boundary")
    }
}
