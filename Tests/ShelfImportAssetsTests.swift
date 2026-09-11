// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation
import Darwin

enum ShelfImportAssetsTests {
    static func run(_ expect: (Bool, String) -> Void) {
        let fm = FileManager.default
        let root = URL(fileURLWithPath: fm.currentDirectoryPath).appendingPathComponent(".shelf-assets-test-" + UUID().uuidString)
        defer { try? fm.removeItem(at: root) }
        func rejects(_ message: String, _ body: () throws -> Void) {
            do { try body(); expect(false, message) } catch { expect(true, message) }
        }
        do {
            try fm.createDirectory(at: root, withIntermediateDirectories: true)
            let assets = root.appendingPathComponent("assets")
            try fm.createDirectory(at: assets, withIntermediateDirectories: true)
            let file = assets.appendingPathComponent("photo.png"), bytes = Data([1, 2, 3, 4])
            try bytes.write(to: file)
            let first = ShelfPersistedItem(id: UUID(), kind: .file, title: "original", path: "/old/photo.png", bookmark: Data([9]))
            var second = ShelfPersistedItem(id: UUID(), kind: .file, title: "duplicate", path: first.path)
            let source = root.appendingPathComponent("source.json"), current = root.appendingPathComponent("current.json")
            let json = try JSONEncoder().encode([first])
            try json.write(to: source)
            let snapshot = try ShelfImportAssets.read(source: source, currentIndex: current)
            expect(snapshot.items == [first] && snapshot.sourceName == "source.json", "source snapshot preserves every field")
            let mapping = ShelfImportMapping(originalDirectory: "/old", selectedDirectory: assets, copyFiles: true)
            let prepared = try ShelfImportAssets.prepare(items: [first, second], mappings: [mapping], destinationDirectory: root)
            expect(prepared.files.count == 1 && prepared.files.values.first == bytes, "duplicate asset copies once")
            expect(prepared.items[0].path == prepared.items[1].path && prepared.items[0].path!.hasPrefix(root.appendingPathComponent("ShelfFiles").path + "/"), "copies target ShelfFiles")
            expect(prepared.items[0].bookmark == nil && prepared.items[0].id == first.id, "copied bookmark cannot resolve to old asset and identity stays stable")
            expect(try Data(contentsOf: source) == json && Data(contentsOf: file) == bytes, "source index and asset bytes unchanged")
            try ShelfImportAssets.validateSource(source: source, currentIndex: current)
            expect(true, "commit preflight accepts explicit independent source")
            rejects("commit preflight rejects current source") { try ShelfImportAssets.validateSource(source: source, currentIndex: source) }
            rejects("current source rejected") { _ = try ShelfImportAssets.read(source: source, currentIndex: source) }
            let hard = root.appendingPathComponent("hard.json")
            try fm.linkItem(at: source, to: hard)
            rejects("current index hardlink rejected") { _ = try ShelfImportAssets.read(source: hard, currentIndex: source) }
            let symlink = root.appendingPathComponent("link.json")
            try fm.createSymbolicLink(at: symlink, withDestinationURL: source)
            rejects("source symlink rejected") { _ = try ShelfImportAssets.read(source: symlink, currentIndex: current) }
            rejects("overlapping roots rejected") { _ = try ShelfImportAssets.prepare(items: [first], mappings: [mapping, ShelfImportMapping(originalDirectory: "/old/nested", selectedDirectory: assets, copyFiles: false)], destinationDirectory: root) }
            rejects("similar prefix unmapped") { second.path = "/older/photo.png"; _ = try ShelfImportAssets.prepare(items: [second], mappings: [mapping], destinationDirectory: root) }
            rejects("traversal rejected") { second.path = "/old/../assets/photo.png"; _ = try ShelfImportAssets.prepare(items: [second], mappings: [mapping], destinationDirectory: root) }
            second.path = "/old/missing"
            do { _ = try ShelfImportAssets.prepare(items: [second], mappings: [mapping], destinationDirectory: root); expect(false, "missing asset reports exact path") }
            catch { expect((error as? ShelfImportAssetError) == .missingFile(assets.appendingPathComponent("missing").path), "missing asset reports exact path") }
            let escape = assets.appendingPathComponent("escape")
            try fm.createSymbolicLink(at: escape, withDestinationURL: root)
            rejects("intermediate symlink escape rejected") { second.path = "/old/escape/source.json"; _ = try ShelfImportAssets.prepare(items: [second], mappings: [mapping], destinationDirectory: root) }
            let reference = ShelfImportMapping(originalDirectory: "/old", selectedDirectory: assets, copyFiles: false)
            second.path = "/old"
            let refs = try ShelfImportAssets.prepare(items: [first, second], mappings: [reference], destinationDirectory: root)
            expect(refs.files.isEmpty && refs.items[1].path == assets.path && refs.items.allSatisfy { $0.bookmark != nil && $0.bookmark != Data([9]) }, "external file and directory only referenced with fresh bookmarks")
            rejects("directory cannot be copied as asset") { _ = try ShelfImportAssets.prepare(items: [second], mappings: [mapping], destinationDirectory: root) }
            let leafLink = assets.appendingPathComponent("leaf.png")
            try fm.createSymbolicLink(at: leafLink, withDestinationURL: file)
            rejects("final asset symlink rejected") { second.path = "/old/leaf.png"; _ = try ShelfImportAssets.prepare(items: [second], mappings: [mapping], destinationDirectory: root) }
            rejects("selected root symlink rejected") { _ = try ShelfImportAssets.prepare(items: [first], mappings: [ShelfImportMapping(originalDirectory: "/old", selectedDirectory: escape, copyFiles: true)], destinationDirectory: root) }
            rejects("mapping traversal rejected") { _ = try ShelfImportAssets.prepare(items: [first], mappings: [ShelfImportMapping(originalDirectory: "/old/../old", selectedDirectory: assets, copyFiles: true)], destinationDirectory: root) }
            let large = assets.appendingPathComponent("large.png")
            _ = fm.createFile(atPath: large.path, contents: nil)
            let handle = try FileHandle(forWritingTo: large)
            try handle.truncate(atOffset: UInt64(ShelfImportAssets.maximumFileBytes + 1)); try handle.close()
            rejects("oversized attachment rejected before allocation") { second.path = "/old/large.png"; _ = try ShelfImportAssets.prepare(items: [second], mappings: [mapping], destinationDirectory: root) }
            let hugeJSON = root.appendingPathComponent("large.json")
            _ = fm.createFile(atPath: hugeJSON.path, contents: nil)
            let jsonHandle = try FileHandle(forWritingTo: hugeJSON)
            try jsonHandle.truncate(atOffset: UInt64(ShelfImportSupport.maximumBytes + 1)); try jsonHandle.close()
            rejects("oversized source rejected before allocation") { _ = try ShelfImportAssets.read(source: hugeJSON, currentIndex: current) }
            let corrupt = root.appendingPathComponent("bad.json")
            try Data("[{\"kind\":\"future\"}]".utf8).write(to: corrupt)
            rejects("unsupported source cannot become empty snapshot") { _ = try ShelfImportAssets.read(source: corrupt, currentIndex: current) }
            let temporary = fm.temporaryDirectory.appendingPathComponent("shelf-assets-alias-\(UUID())")
            try fm.createDirectory(at: temporary, withIntermediateDirectories: true)
            defer { try? fm.removeItem(at: temporary) }
            let temporarySource = temporary.appendingPathComponent("source.json")
            try json.write(to: temporarySource)
            expect(try ShelfImportAssets.read(source: temporarySource, currentIndex: current).items == [first],
                   "standard macOS temporary root alias accepts explicit source")
            let temporaryAsset = temporary.appendingPathComponent("photo.png")
            try bytes.write(to: temporaryAsset)
            let temporaryMapping = ShelfImportMapping(originalDirectory: "/old", selectedDirectory: temporary, copyFiles: true)
            expect(try ShelfImportAssets.prepare(items: [first], mappings: [temporaryMapping], destinationDirectory: root).files.values.first == bytes,
                   "standard macOS temporary root alias accepts selected assets")
            let userAlias = assets.appendingPathComponent("var")
            try fm.createSymbolicLink(at: userAlias, withDestinationURL: temporary)
            rejects("user directory var symlink is not a system alias") {
                second.path = "/old/var/photo.png"
                _ = try ShelfImportAssets.prepare(items: [second], mappings: [mapping], destinationDirectory: root)
            }
            let plist = root.appendingPathComponent("source.plist")
            try PropertyListSerialization.data(fromPropertyList: ["shelfItems": json], format: .binary, options: 0).write(to: plist)
            expect(try ShelfImportAssets.read(source: plist, currentIndex: current, legacy: true).items == [first], "explicit plist source read")
        } catch { expect(false, "asset fixture: \(error)") }
    }
}
