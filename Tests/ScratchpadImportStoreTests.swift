// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

enum ScratchpadImportStoreTests {
    static func run(_ expect: (Bool, String) -> Void) {
        let fm = FileManager.default
        let root = fm.temporaryDirectory.appendingPathComponent("vorssaint-tests-import-store-\(UUID())")
        let suite = "vorssaint-tests-import-store-\(UUID())"
        let defaults = UserDefaults(suiteName: suite)!
        defer { try? fm.removeItem(at: root); defaults.removePersistentDomain(forName: suite) }
        do {
            try fm.createDirectory(at: root, withIntermediateDirectories: true)
            let json = root.appendingPathComponent("Scratchpad.json")
            let legacy = root.appendingPathComponent("Scratchpad.txt")
            let old = ScratchpadDocument.initial(defaultName: "old", text: "expired but intact", modifiedAt: Date(timeIntervalSince1970: 1))
            let data = old.encoded()!
            try data.write(to: json)
            try Data("legacy intact".utf8).write(to: legacy)
            defaults.set(data, forKey: DefaultsKey.scratchpadDocument)
            let before = defaults.persistentDomain(forName: suite)! as NSDictionary
            var store = ScratchpadStore(directoryURL: root, defaults: defaults)
            expect(try store.loadForImport(defaultName: "new") == old, "import reads expired text without retention")
            expect(store.lastSavedDocument == old, "JSON read records saved identity")
            expect(try Data(contentsOf: json) == data, "read leaves JSON bytes unchanged")
            expect(before == (defaults.persistentDomain(forName: suite) ?? [:]) as NSDictionary, "read leaves preferences unchanged")
            expect(try String(contentsOf: legacy, encoding: .utf8) == "legacy intact", "read leaves legacy file unchanged")
            try Data("{".utf8).write(to: json)
            do { _ = try store.loadForImport(defaultName: "new"); expect(false, "bad current JSON rejects") }
            catch { expect(true, "bad current JSON rejects without fallback") }
            expect(store.lastSavedDocument == nil && !store.save(old), "failed read revokes prior save authorization")
            expect(try Data(contentsOf: json) == Data("{".utf8), "failed save preserves corrupt source")
            try fm.removeItem(at: json)
            expect(try store.loadForImport(defaultName: "new") == old, "preferences precede legacy text")
            expect(store.lastSavedDocument == nil, "preferences require a future JSON write")
            let next = ScratchpadDocument.initial(defaultName: "imported", text: "new result")
            expect(store.save(next), "confirmed import writes new JSON")
            expect(try JSONDecoder().decode(ScratchpadDocument.self, from: Data(contentsOf: json)) == next, "saved JSON reopens as complete document")
            expect(try String(contentsOf: legacy, encoding: .utf8) == "legacy intact" && defaults.data(forKey: DefaultsKey.scratchpadDocument) == data, "save preserves both legacy sources")
            try fm.removeItem(at: json)
            defaults.removeObject(forKey: DefaultsKey.scratchpadDocument)
            let modified = Date(timeIntervalSince1970: 1234)
            try fm.setAttributes([.modificationDate: modified], ofItemAtPath: legacy.path)
            let textDoc = try store.loadForImport(defaultName: "Legacy")
            expect(textDoc.pads.first?.text == "legacy intact" && textDoc.pads.first?.modifiedAt == modified, "legacy text retains original date and text")
            expect(store.lastSavedDocument == nil, "legacy text requires JSON save")
            try Data([0xff]).write(to: legacy)
            do { _ = try store.loadForImport(defaultName: "new"); expect(false, "invalid legacy UTF8 rejects") }
            catch { expect(!store.save(next), "invalid legacy UTF8 blocks save") }
            try Data(count: 8 * 1024 * 1024 + 1).write(to: legacy)
            do { _ = try store.loadForImport(defaultName: "new"); expect(false, "oversized legacy rejects") }
            catch { expect(!store.save(next), "oversized legacy blocks save") }
            try fm.removeItem(at: legacy)
            let initial = try store.loadForImport(defaultName: "New")
            expect(initial.pads.count == 1 && initial.pads[0].name == "New 1" && initial.pads[0].text.isEmpty, "missing sources return initial document")
            expect(!fm.fileExists(atPath: json.path), "initial read does not create JSON")
            defaults.set("wrong type", forKey: DefaultsKey.scratchpadDocument)
            do { _ = try store.loadForImport(defaultName: "new"); expect(false, "bad preference rejects") }
            catch { expect(!store.save(next), "bad preference blocks save without fallback") }
            defaults.set(data, forKey: DefaultsKey.scratchpadDocument)
            var future = try JSONSerialization.jsonObject(with: data) as! [String: Any]
            future["futureSchema"] = 2
            try JSONSerialization.data(withJSONObject: future).write(to: json)
            do { _ = try store.loadForImport(defaultName: "new"); expect(false, "unknown JSON schema rejects") }
            catch { expect(!store.save(next), "unknown current schema cannot fall back to valid preference") }
            try fm.removeItem(at: json)
            try fm.createSymbolicLink(at: json, withDestinationURL: legacy)
            do { _ = try store.loadForImport(defaultName: "new"); expect(false, "dangling JSON symlink rejects") }
            catch { expect(!store.save(next), "dangling current symlink cannot fall back or authorize save") }
        } catch { expect(false, "store fixture failed: \(error)") }
    }
}
