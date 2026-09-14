// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

enum ShelfPromiseCleanupTests {
    static func run(_ expect: (Bool, String) -> Void) {
        let fm = FileManager.default
        let root = fm.temporaryDirectory.appendingPathComponent("shelf-promise-cleanup-\(UUID())")
        defer { try? fm.removeItem(at: root) }
        do {
            let old = Date(timeIntervalSince1970: 1_600_000_000)
            let cutoff = old.addingTimeInterval(10)
            let parent = root.appendingPathComponent(UUID().uuidString)
            let fresh = root.appendingPathComponent(UUID().uuidString)
            let other = root.appendingPathComponent("ordinary-folder")
            for dir in [parent, fresh, other] {
                try fm.createDirectory(at: dir, withIntermediateDirectories: true)
                let file = dir.appendingPathComponent("attachment.txt")
                try Data("bytes".utf8).write(to: file)
                try fm.setAttributes([.modificationDate: old], ofItemAtPath: file.path)
            }
            try fm.setAttributes([.modificationDate: old], ofItemAtPath: parent.path)
            let file = parent.appendingPathComponent("attachment.txt")
            let candidates = ShelfPayloadCleanup.collect(in: [root], writtenBefore: cutoff)
            expect(candidates.map(\.url) == [file], "startup collects only old UUID-owned attachments")
            _ = ShelfPayloadCleanup.remove(candidates, keeping: [file.path], roots: [root])
            expect(fm.fileExists(atPath: file.path), "committed attachment survives startup cleanup")
            _ = ShelfPayloadCleanup.remove(candidates, keeping: [], roots: [root])
            expect(!fm.fileExists(atPath: parent.path), "orphan attachment and its empty UUID parent are removed")
            expect(fm.fileExists(atPath: fresh.appendingPathComponent("attachment.txt").path),
                   "in-flight copy with old source mtime survives startup cutoff")
            expect(fm.fileExists(atPath: other.appendingPathComponent("attachment.txt").path),
                   "unrecognized directories remain outside startup sweep")
        } catch { expect(false, "promise cleanup fixture: \(error)") }
    }
}
