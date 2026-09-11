// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

enum ShelfImportTransactionTests {
    static func run(_ expect: (Bool, String) -> Void) {
        let fm = FileManager.default
        let root = fm.temporaryDirectory.appendingPathComponent("vorssaint-tests-shelf-transaction-\(UUID())")
        defer { try? fm.removeItem(at: root) }
        let a = "00000000-0000-0000-0000-000000000001.png"
        let b = "00000000-0000-0000-0000-000000000002.pdf"
        let bytes = Data("fixture PNG bytes".utf8)
        let old = Data("old JSON untouched".utf8)
        func make(_ name: String) throws -> URL {
            let dir = root.appendingPathComponent(name)
            try fm.createDirectory(at: dir.appendingPathComponent("ShelfFiles"), withIntermediateDirectories: true)
            try old.write(to: dir.appendingPathComponent("ShelfItems.json"))
            return dir
        }
        func prepare(_ files: [String: Data], in dir: URL) throws -> ShelfImportPrepared {
            var items = files.keys.sorted().map { ShelfPersistedItem(id: UUID(), kind: .file, title: $0, path: dir.standardizedFileURL.appendingPathComponent("ShelfFiles/\($0)").path) }
            items.append(ShelfPersistedItem(id: UUID(), kind: .batch, title: "batch", children: [
                ShelfPersistedItem(id: UUID(), kind: .text, title: "text", text: "Unicode 全文\nsecond line"),
                ShelfPersistedItem(id: UUID(), kind: .link, title: "link", url: "https://example.org/?a=b"),
                ShelfPersistedItem(id: UUID(), kind: .file, title: "existing", path: "/existing/external.txt", bookmark: Data([0, 1, 2]))
            ]))
            return try ShelfImportTransaction.prepare(items: items, files: files, in: dir)
        }
        func mode(_ url: URL) throws -> Int { (try fm.attributesOfItem(atPath: url.path)[.posixPermissions] as! NSNumber).intValue & 0o777 }
        do {
            let dir = try make("success")
            let input = [a: bytes, b: bytes]
            let prepared = try prepare(input, in: dir)
            expect(try Data(contentsOf: dir.appendingPathComponent("ShelfItems.json")) == old, "prepare preserves live JSON")
            expect(!fm.fileExists(atPath: dir.appendingPathComponent("ShelfFiles/\(a)").path), "prepare installs no live images")
            expect(prepared.stagingURL.deletingLastPathComponent().path == dir.standardizedFileURL.path, "stage lives outside swept asset directory")
            expect(try mode(prepared.stagingURL) == 0o700, "stage directory private")
            try ShelfImportTransaction.commit(prepared, to: dir)
            expect(try JSONDecoder().decode([ShelfPersistedItem].self, from: Data(contentsOf: dir.appendingPathComponent("ShelfItems.json"))) == prepared.items, "commit replaces JSON completely")
            expect(try Data(contentsOf: dir.appendingPathComponent("ShelfFiles/\(a)")) == bytes, "commit installs image bytes")
            expect(try Data(contentsOf: dir.appendingPathComponent("ShelfFiles/\(b)")) == bytes, "commit installs arbitrary extension attachment")
            expect(try mode(dir.appendingPathComponent("ShelfItems.json")) == 0o600 && mode(dir.appendingPathComponent("ShelfFiles/\(a)")) == 0o600, "committed files private")
            expect(!fm.fileExists(atPath: prepared.stagingURL.path), "successful commit removes stage")
            expect(input[a] == bytes, "candidate remains immutable")
            do { try ShelfImportTransaction.commit(prepared, to: dir); expect(false, "repeat commit rejects") }
            catch { expect(true, "repeat commit rejects") }
            for collision in [a, b] {
                let target = try make("collision-\(collision)")
                let existing = target.appendingPathComponent("ShelfFiles/\(collision)")
                try old.write(to: existing)
                let stage = try prepare(input, in: target)
                do { try ShelfImportTransaction.commit(stage, to: target); expect(false, "collision rejects") }
                catch { expect(true, "collision rejects") }
                expect(try Data(contentsOf: existing) == old, "collision never overwrites existing asset")
                expect(try Data(contentsOf: target.appendingPathComponent("ShelfItems.json")) == old, "collision preserves previous JSON")
                let other = collision == a ? b : a
                expect(!fm.fileExists(atPath: target.appendingPathComponent("ShelfFiles/\(other)").path), "failed later asset rolls back earlier new asset")
                expect(!fm.fileExists(atPath: stage.stagingURL.path), "handled collision cleans own stage")
            }
            let failed = try make("json-failure")
            let json = failed.appendingPathComponent("ShelfItems.json")
            try fm.removeItem(at: json)
            try fm.createDirectory(at: json, withIntermediateDirectories: false)
            try old.write(to: json.appendingPathComponent("keep"))
            let failedStage = try prepare(input, in: failed)
            do { try ShelfImportTransaction.commit(failedStage, to: failed); expect(false, "JSON failure rejects") }
            catch { expect(true, "JSON failure rejects") }
            expect(try Data(contentsOf: json.appendingPathComponent("keep")) == old, "JSON failure preserves prior target")
            expect(!fm.fileExists(atPath: failed.appendingPathComponent("ShelfFiles/\(a)").path) && !fm.fileExists(atPath: failed.appendingPathComponent("ShelfFiles/\(b)").path), "JSON failure rolls back only new images")
            let symlinkDir = try make("index-symlink")
            let symlinkIndex = symlinkDir.appendingPathComponent("ShelfItems.json")
            try fm.removeItem(at: symlinkIndex)
            try fm.createSymbolicLink(at: symlinkIndex, withDestinationURL: dir.appendingPathComponent("ShelfItems.json"))
            let symlinkStage = try prepare(input, in: symlinkDir)
            do { try ShelfImportTransaction.commit(symlinkStage, to: symlinkDir); expect(false, "index symlink rejects") }
            catch { expect(true, "index symlink rejects") }
            expect((try? fm.destinationOfSymbolicLink(atPath: symlinkIndex.path)) != nil, "index symlink preserved")
            expect(!fm.fileExists(atPath: symlinkDir.appendingPathComponent("ShelfFiles/\(a)").path), "index symlink failure rolls back assets")
            let replacedFileDir = try make("stage-file-replaced")
            let replacedFile = try prepare(input, in: replacedFileDir)
            let replacementURL = replacedFile.stagingURL.appendingPathComponent(a)
            try old.write(to: replacementURL, options: .atomic)
            ShelfImportTransaction.discard(replacedFile)
            expect(try Data(contentsOf: replacementURL) == old, "discard preserves replaced foreign stage file")
            expect(replacedFile.cleanupFailed, "replacement cleanup conflict observable")
            let cancel = try prepare(input, in: dir)
            ShelfImportTransaction.discard(cancel)
            ShelfImportTransaction.discard(cancel)
            expect(!fm.fileExists(atPath: cancel.stagingURL.path), "discard is idempotent and removes own stage")
            for name in ["../escape.png", "nested/file.png", "/absolute.png", "bad\0.png", "", "00000000-0000-0000-0000-000000000001.a/b", "00000000-0000-0000-0000-000000000001.", "00000000-0000-0000-0000-000000000001.bad\\ext", "00000000-0000-0000-0000-000000000001.bad\0ext", "00000000-0000-0000-0000-000000000001." + String(repeating: "a", count: 219)] {
                do { _ = try prepare([name: bytes], in: dir); expect(false, "unsafe image name rejected") }
                catch { expect(true, "unsafe image name rejected") }
            }
            for suffix in [".gif", "", ".DOCX", ".日本語", ".extensionlongerthan16characters", "." + String(repeating: "a", count: 218)] {
                let name = UUID().uuidString + suffix
                let accepted = try prepare([name: bytes], in: dir)
                ShelfImportTransaction.discard(accepted)
                expect(!fm.fileExists(atPath: accepted.stagingURL.path), "safe GIF, extensionless, Unicode and long extension accepted")
            }
            do { _ = try ShelfImportTransaction.prepare(items: [], files: [a: bytes], in: dir); expect(false, "unreferenced attachment rejects") }
            catch { expect(true, "unreferenced attachment rejects") }
            let bound = try prepare(input, in: dir)
            let different = try make("different")
            do { try ShelfImportTransaction.commit(bound, to: different); expect(false, "different destination rejects") }
            catch { expect(true, "different destination rejects") }
            expect(try Data(contentsOf: different.appendingPathComponent("ShelfItems.json")) == old, "wrong destination unchanged")
            ShelfImportTransaction.discard(bound)
            let alias = root.appendingPathComponent("alias")
            try fm.createSymbolicLink(at: alias, withDestinationURL: dir)
            do { _ = try prepare(input, in: alias); expect(false, "symlink destination rejects") }
            catch { expect(true, "symlink destination rejects") }
            let replacement = try make("replacement")
            let replacedStage = try prepare(input, in: replacement)
            let moved = root.appendingPathComponent("moved-original")
            try fm.moveItem(at: replacement, to: moved)
            try fm.createDirectory(at: replacement, withIntermediateDirectories: false)
            try old.write(to: replacement.appendingPathComponent("ShelfItems.json"))
            do { try ShelfImportTransaction.commit(replacedStage, to: replacement); expect(false, "replaced directory identity rejects") }
            catch { expect(true, "replaced directory identity rejects") }
            expect(try Data(contentsOf: replacement.appendingPathComponent("ShelfItems.json")) == old, "replaced target is not touched")
            ShelfImportTransaction.discard(replacedStage)
            expect(!fm.fileExists(atPath: moved.appendingPathComponent(replacedStage.stagingURL.lastPathComponent).path), "descriptor cleanup removes only original owned stage after directory move")
            let imageAliasDir = try make("image-alias")
            try fm.removeItem(at: imageAliasDir.appendingPathComponent("ShelfFiles"))
            try fm.createSymbolicLink(at: imageAliasDir.appendingPathComponent("ShelfFiles"), withDestinationURL: dir.appendingPathComponent("ShelfFiles"))
            let imageAliasStage = try prepare(input, in: imageAliasDir)
            do { try ShelfImportTransaction.commit(imageAliasStage, to: imageAliasDir); expect(false, "image directory symlink rejects") }
            catch { expect(true, "image directory symlink rejects") }
            expect(try Data(contentsOf: dir.appendingPathComponent("ShelfFiles/\(a)")) == bytes, "image symlink never modifies external assets")
            let diagnosticDir = try make("cleanup-diagnostic")
            let diagnostic = try prepare(input, in: diagnosticDir)
            let foreign = diagnostic.stagingURL.appendingPathComponent("unexpected-file")
            try old.write(to: foreign)
            try ShelfImportTransaction.commit(diagnostic, to: diagnosticDir)
            expect(diagnostic.committed && diagnostic.cleanupFailed, "post-commit cleanup failure is observable without reporting transaction failure")
            expect(try Data(contentsOf: foreign) == old, "cleanup leaves unowned stage entries for diagnosis")
            ShelfImportTransaction.discard(diagnostic)
            expect(try JSONDecoder().decode([ShelfPersistedItem].self, from: Data(contentsOf: diagnosticDir.appendingPathComponent("ShelfItems.json"))) == diagnostic.items, "discard after committed cleanup warning cannot undo JSON")
        } catch { expect(false, "transaction fixture failed: \(error)") }
    }
}
