// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation
import Darwin

enum ShelfIndexStoreTests {
    static func run(_ expect: (Bool, String) -> Void) {
        let fm = FileManager.default
        let root = fm.temporaryDirectory.appendingPathComponent("vorssaint-tests-shelf-index-\(UUID())")
        let suite = "com.vorssaint.tests.shelf-index.\(UUID())"
        guard let prefs = UserDefaults(suiteName: suite) else { expect(false, "fixture preferences"); return }
        defer { prefs.removePersistentDomain(forName: suite); try? fm.removeItem(at: root) }
        func success(_ result: Result<Void, ShelfIndexError>) -> Bool { if case .success = result { return true }; return false }
        func failure(_ result: Result<Void, ShelfIndexError>, _ error: ShelfIndexError) -> Bool { if case let .failure(actual) = result { return actual == error }; return false }
        do {
            try fm.createDirectory(at: root, withIntermediateDirectories: true)
            let item = ShelfPersistedItem(id: UUID(), kind: .text, title: "kept", text: "original")
            let blob = try JSONEncoder().encode([item])
            let file = root.appendingPathComponent("ShelfItems.json")
            let store = ShelfIndexStore(directory: root, legacyDefaults: prefs)
            expect(failure(store.save([]), .unreadable), "save before load cannot erase existing data")
            let empty = store.load()
            expect(empty.store == .items([]) && empty.source == .empty && empty.canWrite, "first launch is writable empty")
            prefs.set(blob, forKey: "shelfItems")
            let legacy = store.load()
            expect(legacy.source == .legacy && legacy.store == .items([item]) && legacy.canWrite, "legacy blob loads without mutation")
            expect(prefs.data(forKey: "shelfItems") == blob && !fm.fileExists(atPath: file.path), "load leaves legacy intact and does not create index")
            expect(success(store.save([item])), "atomic save succeeds")
            expect((try? Data(contentsOf: file)).map(ShelfPersistenceSupport.load) == .items([item]), "committed JSON reopens with complete items")
            expect(prefs.object(forKey: "shelfItems") == nil, "legacy removed only after successful save")
            prefs.set(blob, forKey: "shelfItems")
            try Data("[]".utf8).write(to: file)
            let preferred = store.load()
            expect(preferred.source == .json && preferred.store == .items([]), "empty JSON wins over nonempty legacy")
            expect(success(store.save([])) && (try? Data(contentsOf: file)) == Data("[]".utf8), "empty save persists explicit array")
            for broken in [Data("broken".utf8), Data("[{\"kind\":\"future\"},{\"kind\":\"text\",\"text\":\"visible\"}]".utf8)] {
                try broken.write(to: file); prefs.set(blob, forKey: "shelfItems")
                let loaded = store.load()
                expect(loaded.source == .json && !loaded.canWrite, "bad or partial index prevents fallback and write")
                expect(failure(store.save([]), .unreadable), "bad or partial data cannot be overwritten")
                expect((try? Data(contentsOf: file)) == broken && prefs.data(forKey: "shelfItems") == blob, "bad source and old blob remain byte identical")
            }
            try fm.removeItem(at: file)
            prefs.set("invalid type", forKey: "shelfItems")
            expect(!store.load().canWrite && failure(store.save([]), .unreadable), "non-Data legacy does not become empty")
            for broken in [Data("bad".utf8), Data("[{\"kind\":\"text\",\"text\":\"ok\"},{\"kind\":\"future\"}]".utf8)] {
                prefs.set(broken, forKey: "shelfItems")
                expect(!store.load().canWrite && failure(store.save([]), .unreadable), "malformed or partial legacy cannot migrate")
                expect(prefs.data(forKey: "shelfItems") == broken && !fm.fileExists(atPath: file.path), "unreadable legacy remains intact")
            }
            prefs.set(blob, forKey: "shelfItems")
            _ = store.load()
            try fm.createDirectory(at: file, withIntermediateDirectories: false)
            try Data("sentinel".utf8).write(to: file.appendingPathComponent("keep"))
            expect(failure(store.save([]), .saveFailed), "nonempty destination directory reports real write failure")
            expect(prefs.data(forKey: "shelfItems") == blob && fm.fileExists(atPath: file.appendingPathComponent("keep").path), "failed atomic save preserves old preferences and target")
            expect(!store.load().canWrite, "nonregular index is not missing")
            try fm.removeItem(at: file)
            try fm.createSymbolicLink(at: file, withDestinationURL: root.appendingPathComponent("absent"))
            expect(!store.load().canWrite, "dangling index symlink cannot fall back")
            try fm.removeItem(at: file)
            _ = fm.createFile(atPath: file.path, contents: nil)
            let handle = try FileHandle(forWritingTo: file)
            try handle.truncate(atOffset: UInt64(ShelfIndexStore.maximumBytes + 1)); try handle.close()
            expect(!store.load().canWrite && failure(store.save([]), .unreadable), "oversized sparse index cannot be replaced")
            try fm.removeItem(at: file)
            _ = store.load()
            expect(success(store.save([item])), "recovered complete legacy can retry save")
            let attrs = try fm.attributesOfItem(atPath: file.path)
            expect((attrs[.posixPermissions] as? NSNumber)?.intValue == 0o600, "index file is private")
            expect(ShelfIndexStore(directory: root, legacyDefaults: prefs).load().store == .items([item]), "fresh store reads committed JSON after legacy retirement")
            let before = try Data(contentsOf: file)
            prefs.set(blob, forKey: "shelfItems")
            let oversized = ShelfPersistedItem(id: UUID(), kind: .text, title: "escaped", text: String(repeating: "\u{0001}", count: ShelfIndexStore.maximumBytes / 6 + 1))
            expect(failure(store.save([oversized]), .tooLarge), "actual escaped encoding exceeding byte budget refuses save")
            expect((try? Data(contentsOf: file)) == before && prefs.data(forKey: "shelfItems") == blob, "oversized save preserves committed JSON and legacy")

        } catch { expect(false, "shelf index fixture error: \(error)") }
    }
}
