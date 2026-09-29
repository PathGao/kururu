// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

enum ShelfPayloadCleanupTests {
    static func run(_ expect: (Bool, String) -> Void) {
        let fm = FileManager.default
        let base = fm.temporaryDirectory.appendingPathComponent("kururu-shelf-cleanup-\(UUID())", isDirectory: true)
        do {
            try fm.createDirectory(at: base, withIntermediateDirectories: true)
            defer { try? fm.removeItem(at: base) }
            let root = base.appendingPathComponent("owned", isDirectory: true)
            let nested = root.appendingPathComponent("nested", isDirectory: true)
            try fm.createDirectory(at: nested, withIntermediateDirectories: true)
            func file(_ url: URL) throws -> URL { try Data("fixture".utf8).write(to:url);return url }
            let normal = try file(root.appendingPathComponent("normal.png"))
            let external = try file(base.appendingPathComponent("external.png"))
            let deep = try file(nested.appendingPathComponent("deep.png"))
            let link = root.appendingPathComponent("link.png")
            try fm.createSymbolicLink(at:link,withDestinationURL:external)
            let directoryLink = root.appendingPathComponent("alias")
            try fm.createSymbolicLink(at:directoryLink,withDestinationURL:nested)
            expect(ShelfPayloadCleanup.capture([external,nested,link,directoryLink.appendingPathComponent("deep.png")],roots:[root]).isEmpty,
                   "external directory and symlink paths never become deletion candidates")
            let valid = ShelfPayloadCleanup.capture([normal,deep,normal],roots:[root])
            expect(valid.count == 2, "capture accepts owned nested regular files and deduplicates paths")
            let oldDate = Date(timeIntervalSince1970:1_600_000_000)
            try fm.setAttributes([.modificationDate:oldDate],ofItemAtPath:normal.path)
            let cutoff = oldDate.addingTimeInterval(1)
            expect(ShelfPayloadCleanup.capture([normal,deep],roots:[root],writtenBefore:cutoff).map(\.url) == [normal], "cutoff retains only older candidates")
            expect(ShelfPayloadCleanup.capture([normal],roots:[root],writtenBefore:oldDate).isEmpty, "cutoff is strictly before")
            let collected = ShelfPayloadCleanup.collect(in:[root],writtenBefore:Date().addingTimeInterval(10))
            expect(collected.map(\.url) == [normal], "collect enumerates direct regular files only")
            let kept = ShelfPayloadCleanup.capture([normal],roots:[root])
            expect(ShelfPayloadCleanup.remove(kept,keeping:[normal.path],roots:[root]).isEmpty && fm.fileExists(atPath:normal.path), "referenced asset survives and is not retried")
            let changed = ShelfPayloadCleanup.capture([deep],roots:[root])
            let original = nested.appendingPathComponent("old-inode.png")
            try fm.moveItem(at:deep,to:original)
            try Data("replacement".utf8).write(to:deep)
            expect(ShelfPayloadCleanup.remove(changed,keeping:[],roots:[root]).isEmpty && fm.fileExists(atPath:deep.path), "replacement inode is never deleted")
            let symlinkCandidate = ShelfPayloadCleanup.capture([deep],roots:[root])
            try fm.removeItem(at:deep);try fm.createSymbolicLink(at:deep,withDestinationURL:external)
            expect(ShelfPayloadCleanup.remove(symlinkCandidate,keeping:[],roots:[root]).isEmpty && fm.fileExists(atPath:external.path), "replacement symlink cannot delete external target")
            expect(ShelfPayloadCleanup.remove(kept,keeping:[],roots:[nested]).isEmpty && fm.fileExists(atPath:normal.path), "candidate outside current roots is refused")
            expect(ShelfPayloadCleanup.remove(kept,keeping:[],roots:[root]).isEmpty && !fm.fileExists(atPath:normal.path), "normal unreferenced owned asset is removed")
            expect(ShelfPayloadCleanup.remove(kept,keeping:[],roots:[root]).isEmpty, "already removed candidate is not retried")
            let locked = root.appendingPathComponent("locked", isDirectory:true)
            try fm.createDirectory(at:locked,withIntermediateDirectories:false)
            let lockedFile = try file(locked.appendingPathComponent("retry.png"))
            let retryCandidate = ShelfPayloadCleanup.capture([lockedFile],roots:[root])
            try fm.setAttributes([.posixPermissions:0o500],ofItemAtPath:locked.path)
            let retry = ShelfPayloadCleanup.remove(retryCandidate,keeping:[],roots:[root])
            try fm.setAttributes([.posixPermissions:0o700],ofItemAtPath:locked.path)
            expect(retry.count == 1 && fm.fileExists(atPath:lockedFile.path), "real unlink permission failure returns candidate for retry")
            expect(ShelfPayloadCleanup.remove(retry,keeping:[],roots:[root]).isEmpty && !fm.fileExists(atPath:lockedFile.path), "retry succeeds when directory permission restored")
            expect(try Data(contentsOf:external) == Data("fixture".utf8), "external file content remains unchanged")
        } catch { expect(false,"shelf cleanup fixture failed: \(error)") }
    }
}
