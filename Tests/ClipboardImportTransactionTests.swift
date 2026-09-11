// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

enum ClipboardImportTransactionTests {
    static func run(_ expect: (Bool, String) -> Void) {
        let fm = FileManager.default
        let root = fm.temporaryDirectory.appendingPathComponent("vorssaint-tests-clipboard-transaction-\(UUID())")
        defer { try? fm.removeItem(at: root) }
        let a = "00000000-0000-0000-0000-000000000001.png"
        let b = "00000000-0000-0000-0000-000000000002.png"
        let bytes = Data("fixture PNG bytes".utf8)
        let old = Data("old JSON untouched".utf8)
        func make(_ name: String) throws -> URL {
            let dir = root.appendingPathComponent(name)
            try fm.createDirectory(at: dir.appendingPathComponent("ClipboardImages"), withIntermediateDirectories: true)
            try old.write(to: dir.appendingPathComponent("ClipboardHistory.json"))
            return dir
        }
        func candidate(_ images: [String: Data]) -> ClipboardImportCandidate {
            ClipboardImportCandidate(entries: [], images: images, json: Data("[]".utf8))
        }
        func mode(_ url: URL) throws -> Int { (try fm.attributesOfItem(atPath: url.path)[.posixPermissions] as! NSNumber).intValue & 0o777 }
        do {
            let dir = try make("success")
            let input = candidate([a: bytes, b: bytes])
            let prepared = try ClipboardImportTransaction.prepare(input, in: dir)
            expect(try Data(contentsOf: dir.appendingPathComponent("ClipboardHistory.json")) == old, "prepare preserves live JSON")
            expect(!fm.fileExists(atPath: dir.appendingPathComponent("ClipboardImages/\(a)").path), "prepare installs no live images")
            expect(try mode(prepared.stagingURL) == 0o700, "stage directory private")
            try ClipboardImportTransaction.commit(prepared, to: dir)
            expect(try Data(contentsOf: dir.appendingPathComponent("ClipboardHistory.json")) == input.json, "commit replaces JSON completely")
            expect(try Data(contentsOf: dir.appendingPathComponent("ClipboardImages/\(a)")) == bytes, "commit installs image bytes")
            expect(try mode(dir.appendingPathComponent("ClipboardHistory.json")) == 0o600 && mode(dir.appendingPathComponent("ClipboardImages/\(a)")) == 0o600, "committed files private")
            expect(!fm.fileExists(atPath: prepared.stagingURL.path), "successful commit removes stage")
            expect(input.images[a] == bytes && input.json == Data("[]".utf8), "candidate remains immutable")
            do { try ClipboardImportTransaction.commit(prepared, to: dir); expect(false, "repeat commit rejects") }
            catch { expect(true, "repeat commit rejects") }
            for collision in [a, b] {
                let target = try make("collision-\(collision)")
                let existing = target.appendingPathComponent("ClipboardImages/\(collision)")
                try old.write(to: existing)
                let stage = try ClipboardImportTransaction.prepare(input, in: target)
                do { try ClipboardImportTransaction.commit(stage, to: target); expect(false, "collision rejects") }
                catch { expect(true, "collision rejects") }
                expect(try Data(contentsOf: existing) == old, "collision never overwrites existing asset")
                expect(try Data(contentsOf: target.appendingPathComponent("ClipboardHistory.json")) == old, "collision preserves previous JSON")
                let other = collision == a ? b : a
                expect(!fm.fileExists(atPath: target.appendingPathComponent("ClipboardImages/\(other)").path), "failed later asset rolls back earlier new asset")
                expect(!fm.fileExists(atPath: stage.stagingURL.path), "handled collision cleans own stage")
            }
            let failed = try make("json-failure")
            let json = failed.appendingPathComponent("ClipboardHistory.json")
            try fm.removeItem(at: json)
            try fm.createDirectory(at: json, withIntermediateDirectories: false)
            try old.write(to: json.appendingPathComponent("keep"))
            let failedStage = try ClipboardImportTransaction.prepare(input, in: failed)
            do { try ClipboardImportTransaction.commit(failedStage, to: failed); expect(false, "JSON failure rejects") }
            catch { expect(true, "JSON failure rejects") }
            expect(try Data(contentsOf: json.appendingPathComponent("keep")) == old, "JSON failure preserves prior target")
            expect(!fm.fileExists(atPath: failed.appendingPathComponent("ClipboardImages/\(a)").path) && !fm.fileExists(atPath: failed.appendingPathComponent("ClipboardImages/\(b)").path), "JSON failure rolls back only new images")
            let cancel = try ClipboardImportTransaction.prepare(input, in: dir)
            ClipboardImportTransaction.discard(cancel)
            ClipboardImportTransaction.discard(cancel)
            expect(!fm.fileExists(atPath: cancel.stagingURL.path), "discard is idempotent and removes own stage")
            for name in ["../escape.png", "nested/file.png", "/absolute.png", "bad\0.png"] {
                do { _ = try ClipboardImportTransaction.prepare(candidate([name: bytes]), in: dir); expect(false, "unsafe image name rejected") }
                catch { expect(true, "unsafe image name rejected") }
            }
            let bound = try ClipboardImportTransaction.prepare(input, in: dir)
            let different = try make("different")
            do { try ClipboardImportTransaction.commit(bound, to: different); expect(false, "different destination rejects") }
            catch { expect(true, "different destination rejects") }
            expect(try Data(contentsOf: different.appendingPathComponent("ClipboardHistory.json")) == old, "wrong destination unchanged")
            ClipboardImportTransaction.discard(bound)
            let alias = root.appendingPathComponent("alias")
            try fm.createSymbolicLink(at: alias, withDestinationURL: dir)
            do { _ = try ClipboardImportTransaction.prepare(input, in: alias); expect(false, "symlink destination rejects") }
            catch { expect(true, "symlink destination rejects") }
            let replacement = try make("replacement")
            let replacedStage = try ClipboardImportTransaction.prepare(input, in: replacement)
            let moved = root.appendingPathComponent("moved-original")
            try fm.moveItem(at: replacement, to: moved)
            try fm.createDirectory(at: replacement, withIntermediateDirectories: false)
            try old.write(to: replacement.appendingPathComponent("ClipboardHistory.json"))
            do { try ClipboardImportTransaction.commit(replacedStage, to: replacement); expect(false, "replaced directory identity rejects") }
            catch { expect(true, "replaced directory identity rejects") }
            expect(try Data(contentsOf: replacement.appendingPathComponent("ClipboardHistory.json")) == old, "replaced target is not touched")
            ClipboardImportTransaction.discard(replacedStage)
            expect(!fm.fileExists(atPath: moved.appendingPathComponent(replacedStage.stagingURL.lastPathComponent).path), "descriptor cleanup removes only original owned stage after directory move")
            let imageAliasDir = try make("image-alias")
            try fm.removeItem(at: imageAliasDir.appendingPathComponent("ClipboardImages"))
            try fm.createSymbolicLink(at: imageAliasDir.appendingPathComponent("ClipboardImages"), withDestinationURL: dir.appendingPathComponent("ClipboardImages"))
            let imageAliasStage = try ClipboardImportTransaction.prepare(input, in: imageAliasDir)
            do { try ClipboardImportTransaction.commit(imageAliasStage, to: imageAliasDir); expect(false, "image directory symlink rejects") }
            catch { expect(true, "image directory symlink rejects") }
            expect(try Data(contentsOf: dir.appendingPathComponent("ClipboardImages/\(a)")) == bytes, "image symlink never modifies external assets")
            let diagnosticDir = try make("cleanup-diagnostic")
            let diagnostic = try ClipboardImportTransaction.prepare(input, in: diagnosticDir)
            let foreign = diagnostic.stagingURL.appendingPathComponent("unexpected-file")
            try old.write(to: foreign)
            try ClipboardImportTransaction.commit(diagnostic, to: diagnosticDir)
            expect(diagnostic.committed && diagnostic.cleanupFailed, "post-commit cleanup failure is observable without reporting transaction failure")
            expect(try Data(contentsOf: foreign) == old, "cleanup leaves unowned stage entries for diagnosis")
            ClipboardImportTransaction.discard(diagnostic)
            expect(try Data(contentsOf: diagnosticDir.appendingPathComponent("ClipboardHistory.json")) == input.json, "discard after committed cleanup warning cannot undo JSON")
        } catch { expect(false, "transaction fixture failed: \(error)") }
    }
}
