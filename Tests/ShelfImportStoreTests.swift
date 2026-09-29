// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

enum ShelfImportStoreTests {
    static func run(_ expect: (Bool, String) -> Void) {
        let fm = FileManager.default
        let root = fm.temporaryDirectory.appendingPathComponent("kururu-import-store-\(UUID())")
        defer { try? fm.removeItem(at: root) }
        do {
            try fm.createDirectory(at: root, withIntermediateDirectories: true)
            let source = root.appendingPathComponent("source.json")
            try Data("[]".utf8).write(to: source)
            let destination = root.appendingPathComponent("store")
            let store = ShelfImportStore(directory: destination)
            let selected = [ShelfPersistedItem(id: UUID(), kind: .text, title: "Title", text: "Payload")]
            let first = try store.prepare(selected: selected, current: [], mappings: [], sourceURL: source, managedRoots: [])
            expect(!fm.fileExists(atPath: destination.appendingPathComponent("ShelfItems.json").path), "preparation never publishes live index")
            store.discard(first)
            expect(!fm.fileExists(atPath: first.stagingURL.path), "cancel discards owned staged data")
            do { try store.commit(first); expect(false, "cancelled request cannot commit") } catch { expect(true, "cancelled request cannot commit") }
            let pending = try store.prepare(selected: selected, current: [], mappings: [], sourceURL: source, managedRoots: [])
            store.discardAll()
            expect(!fm.fileExists(atPath: pending.stagingURL.path), "shutdown discards all prepared data")
            let success = try store.prepare(selected: selected, current: [], mappings: [], sourceURL: source, managedRoots: [])
            try store.commit(success)
            let saved = try JSONDecoder().decode([ShelfPersistedItem].self, from: Data(contentsOf: destination.appendingPathComponent("ShelfItems.json")))
            expect(saved == success.items && saved[0].title == "Title", "commit preserves transaction contents and group metadata")
            do { try store.commit(success); expect(false, "transaction is consumed once") } catch { expect(true, "transaction is consumed once") }
            let changedSource = try store.prepare(selected: selected, current: saved, mappings: [], sourceURL: source, managedRoots: [])
            try fm.removeItem(at: source)
            try fm.linkItem(at: destination.appendingPathComponent("ShelfItems.json"), to: source)
            do { try store.commit(changedSource); expect(false, "source becoming current index before commit rejects") } catch { expect(true, "source becoming current index before commit rejects") }
            expect(!fm.fileExists(atPath: changedSource.stagingURL.path), "failed validation cleans prepared transaction")
            let afterFailure = try JSONDecoder().decode([ShelfPersistedItem].self, from: Data(contentsOf: destination.appendingPathComponent("ShelfItems.json")))
            expect(afterFailure == saved, "failed validation leaves existing index intact")
            try fm.removeItem(at: source)
            try Data("[]".utf8).write(to: source)
            let managed = root.appendingPathComponent("managed")
            try fm.createDirectory(at: managed, withIntermediateDirectories: true)
            let asset = managed.appendingPathComponent("owned.txt")
            try Data("owned payload".utf8).write(to: asset)
            let file = [ShelfPersistedItem(id: UUID(), kind: .file, title: "Attachment", path: "/legacy/owned.txt")]
            do {
                _ = try store.prepare(selected: file, current: saved,
                    mappings: [.init(originalDirectory: "/legacy", selectedDirectory: managed, copyFiles: false)],
                    sourceURL: source, managedRoots: [managed])
                expect(false, "managed attachment cannot be imported as external reference")
            } catch ShelfImportServiceError.managedReference { expect(true, "managed attachment cannot be imported as external reference") }
            let copied = try store.prepare(selected: file, current: saved,
                mappings: [.init(originalDirectory: "/legacy", selectedDirectory: managed, copyFiles: true)],
                sourceURL: source, managedRoots: [managed])
            try store.commit(copied)
            let copiedURL = URL(fileURLWithPath: copied.items.last!.path!)
            expect(try Data(contentsOf: copiedURL) == Data("owned payload".utf8), "explicit copy imports managed attachment into new owned payload")
            expect(fm.fileExists(atPath: asset.path), "import preserves source attachment")
        } catch { expect(false, "import store fixture: \(error)") }
    }
}
