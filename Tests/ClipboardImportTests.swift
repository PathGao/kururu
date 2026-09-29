// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation
import CryptoKit
import Darwin

enum ClipboardImportTests {
    static func run(_ expect: (Bool, String) -> Void) {
        runLegacy(expect)
        let fm = FileManager.default
        let root = fm.temporaryDirectory.appendingPathComponent("kururu-clipboard-import-\(UUID())", isDirectory: true)
        func rejects(_ label: String, _ expected: ClipboardImportError? = nil, _ action: () throws -> Void) {
            do { try action(); expect(false, label) }
            catch let error as ClipboardImportError { expect(expected == nil || error == expected, label) }
            catch { expect(false, label + " unexpected error") }
        }
        do {
            try fm.createDirectory(at: root, withIntermediateDirectories: true)
            defer { try? fm.removeItem(at: root) }
            let date = Date(timeIntervalSinceReferenceDate: 0)
            let text = ClipboardHistoryEntry(text: " original \n", copiedAt: date, pinnedAt: date)
            let file = ClipboardHistoryEntry(text: "", copiedAt: date, kind: .files, filePaths: ["/does-not-exist/leave-alone"])
            let png = Data(base64Encoded: "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+jXioAAAAASUVORK5CYII=")!
            let hash = SHA256.hash(data: png).map { String(format: "%02x", $0) }.joined()
            let image = ClipboardHistoryEntry(text: "", copiedAt: date, kind: .image, imageFile: "image.png", imageHash: hash, imageWidth: 1, imageHeight: 1)
            let source = root.appendingPathComponent("ClipboardHistory.json")
            func write(_ entries: [ClipboardHistoryEntry]) throws { try JSONEncoder().encode(entries).write(to: source) }
            try write([text, file])
            let plain = try ClipboardImportSupport.read(source)
            expect(plain.entries == [text, file] && plain.images.isEmpty, "text/files import does not require image directory or target files")
            let imageDir = root.appendingPathComponent("ClipboardImages", isDirectory: true)
            try fm.createDirectory(at: imageDir, withIntermediateDirectories: true)
            try png.write(to: imageDir.appendingPathComponent("image.png"))
            try write([text, image, file])
            let sourceBefore = try Data(contentsOf: source)
            let snapshot = try ClipboardImportSupport.read(source)
            expect(snapshot.entries == [text,image,file] && snapshot.images == ["image.png":png], "real JSON and PNG snapshot preserves exact records")
            expect(snapshot.sourceName == "ClipboardHistory.json", "snapshot carries source basename")
            let existing = ClipboardHistoryEntry(text: "existing", copiedAt: date)
            let candidate = try ClipboardImportSupport.prepare(selected: snapshot.entries, images:snapshot.images, current:[existing], recentLimit:0)
            expect(candidate.entries.map(\.text) == [text.text,existing.text,"",""], "pinned group first and current before imported within group")
            expect(candidate.entries[0].pinnedAt == date && candidate.entries.allSatisfy { $0.copiedAt == date }, "source timestamps and pin retained")
            expect(candidate.entries[1] == existing, "existing entry retained unchanged")
            expect(Set(candidate.entries.map(\.id)).count == 4 && !candidate.entries.contains { snapshot.entries.map(\.id).contains($0.id) }, "all imported IDs are fresh")
            expect(candidate.images.count == 1 && candidate.images.keys.first != "image.png" && candidate.images.values.first == png, "image copied under fresh UUID basename")
            expect(try JSONDecoder().decode([ClipboardHistoryEntry].self,from:candidate.json) == candidate.entries, "candidate JSON contains complete result")
            let textOnly = try ClipboardImportSupport.prepare(selected:[text],images:snapshot.images,current:[],recentLimit:0)
            expect(textOnly.images.isEmpty, "unselected PNG not copied")
            let repeatCopy = try ClipboardImportSupport.prepare(selected:[text],images:[:],current:[text],recentLimit:0)
            expect(repeatCopy.entries.count == 2 && repeatCopy.entries[0] == text, "equal content explicitly imports a copy")
            rejects("empty selection refused", .emptySelection) { _ = try ClipboardImportSupport.prepare(selected:[],images:[:],current:[],recentLimit:0) }
            rejects("recent capacity rejects whole batch", .capacityExceeded) { _ = try ClipboardImportSupport.prepare(selected:[file,image],images:snapshot.images,current:[existing],recentLimit:2) }
            rejects("missing selected PNG refused", .missingImage) { _ = try ClipboardImportSupport.prepare(selected:[image],images:[:],current:[],recentLimit:0) }
            rejects("duplicate selected IDs refused", .invalidDocument) { _ = try ClipboardImportSupport.prepare(selected:[text,text],images:[:],current:[],recentLimit:0) }
            rejects("invalid current history reports unavailable", .unavailable) { _ = try ClipboardImportSupport.prepare(selected:[text],images:[:],current:[text,text],recentLimit:0) }
            let largeText = String(repeating:"x",count:1_000_000)
            let textBudget = (0..<68).map { _ in ClipboardHistoryEntry(text:largeText,copiedAt:date,pinnedAt:date) }
            rejects("64 MiB text budget rejects whole candidate",.capacityExceeded) { _ = try ClipboardImportSupport.prepare(selected:textBudget,images:[:],current:[],recentLimit:0) }
            let escapedText = String(repeating:"\u{0001}",count:1_000_000)
            let encodedBudget = (0..<17).map { _ in ClipboardHistoryEntry(text:escapedText,copiedAt:date,pinnedAt:date) }
            rejects("96 MiB JSON budget rejects whole candidate",.capacityExceeded) { _ = try ClipboardImportSupport.prepare(selected:encodedBudget,images:[:],current:[],recentLimit:0) }
            let objects = try JSONSerialization.jsonObject(with: JSONEncoder().encode([text])) as! [[String:Any]]
            func invalid(_ label: String, _ transform: (inout [String:Any]) -> Void) throws {
                var row = objects[0];transform(&row)
                try JSONSerialization.data(withJSONObject:[row]).write(to:source)
                rejects(label,.invalidDocument) { _ = try ClipboardImportSupport.read(source) }
            }
            try invalid("unknown field refused") { $0["future"] = 1 }
            try invalid("missing UUID refused") { $0.removeValue(forKey:"id") }
            try invalid("missing date refused") { $0.removeValue(forKey:"copiedAt") }
            try invalid("boolean date refused") { $0["copiedAt"] = true }
            try invalid("unknown kind refused") { $0["kind"] = "future" }
            try invalid("text with image field refused") { $0["imageFile"] = "image.png" }
            var legacy = objects[0];legacy.removeValue(forKey:"kind")
            try JSONSerialization.data(withJSONObject:[legacy]).write(to:source)
            expect(try ClipboardImportSupport.read(source).entries == [text], "legacy missing kind remains text")
            try write([text,text]);rejects("duplicate JSON IDs refused",.invalidDocument) { _ = try ClipboardImportSupport.read(source) }
            try Data("{}".utf8).write(to:source);rejects("nonarray JSON refused",.invalidDocument) { _ = try ClipboardImportSupport.read(source) }
            try write([image]);try fm.removeItem(at:imageDir.appendingPathComponent("image.png"))
            rejects("missing referenced PNG refused",.missingImage) { _ = try ClipboardImportSupport.read(source) }
            try Data("not PNG".utf8).write(to:imageDir.appendingPathComponent("image.png"))
            rejects("invalid PNG/hash refused",.invalidDocument) { _ = try ClipboardImportSupport.read(source) }
            try png.write(to:imageDir.appendingPathComponent("image.png"))
            let traversal = ClipboardHistoryEntry(text:"",copiedAt:date,kind:.image,imageFile:"../image.png",imageHash:hash,imageWidth:1,imageHeight:1)
            try write([traversal]);rejects("image traversal refused",.invalidDocument) { _ = try ClipboardImportSupport.read(source) }
            let wrongDimensions = ClipboardHistoryEntry(text:"",copiedAt:date,kind:.image,imageFile:"image.png",imageHash:hash,imageWidth:2,imageHeight:1)
            try write([wrongDimensions]);rejects("PNG metadata must match entry",.invalidDocument) { _ = try ClipboardImportSupport.read(source) }
            let wrongHash = ClipboardHistoryEntry(text:"",copiedAt:date,kind:.image,imageFile:"image.png",imageHash:String(repeating:"0",count:64),imageWidth:1,imageHeight:1)
            try write([wrongHash]);rejects("PNG digest must match entry",.invalidDocument) { _ = try ClipboardImportSupport.read(source) }
            let hugePixels = ClipboardHistoryEntry(text:"",copiedAt:date,kind:.image,imageFile:"image.png",imageHash:hash,imageWidth:Int.max,imageHeight:2)
            try write([hugePixels]);rejects("pixel multiplication cannot overflow",.invalidDocument) { _ = try ClipboardImportSupport.read(source) }
            let badDate = ClipboardHistoryEntry(text:"valid",copiedAt:Date(timeIntervalSinceReferenceDate:.infinity))
            rejects("nonfinite candidate date refused",.invalidDocument) { _ = try ClipboardImportSupport.prepare(selected:[badDate],images:[:],current:[],recentLimit:0) }
            try write([image])
            try fm.removeItem(at:imageDir.appendingPathComponent("image.png"))
            let externalImage = root.appendingPathComponent("outside.png");try png.write(to:externalImage)
            try fm.createSymbolicLink(at:imageDir.appendingPathComponent("image.png"),withDestinationURL:externalImage)
            rejects("referenced PNG symlink refused",.missingImage) { _ = try ClipboardImportSupport.read(source) }
            try fm.removeItem(at:imageDir.appendingPathComponent("image.png"));try png.write(to:imageDir.appendingPathComponent("image.png"))
            let large = root.appendingPathComponent("oversized.json")
            _ = fm.createFile(atPath:large.path,contents:nil)
            let largeHandle = try FileHandle(forWritingTo:large)
            try largeHandle.truncate(atOffset:UInt64(ClipboardHistoryEditing.maxEncodedHistoryBytes+1));try largeHandle.close()
            rejects("oversized sparse JSON rejected before allocation",.tooLarge) { _ = try ClipboardImportSupport.read(large) }
            try sourceBefore.write(to:source)
            let link = root.appendingPathComponent("alias.json")
            try fm.createSymbolicLink(at:link,withDestinationURL:source)
            rejects("source symlink refused",.unreadable) { _ = try ClipboardImportSupport.read(link) }
            rejects("same source destination refused",.sameDestination) { try ClipboardImportSupport.validateSource(source,destination:source) }
            let hard = root.appendingPathComponent("hard.json");try fm.linkItem(at:source,to:hard)
            rejects("same inode refused",.sameDestination) { try ClipboardImportSupport.validateSource(hard,destination:source) }
            rejects("nonlocal file URL refused",.unreadable) { _ = try ClipboardImportSupport.read(URL(string:"file://remote.invalid"+source.path)!) }
            let fifo = root.appendingPathComponent("fifo.json")
            guard mkfifo(fifo.path,0o600) == 0 else { expect(false,"FIFO creation");return }
            rejects("FIFO nonblocking rejection",.unreadable) { _ = try ClipboardImportSupport.read(fifo) }
            expect(try Data(contentsOf:source) == sourceBefore && Data(contentsOf:imageDir.appendingPathComponent("image.png")) == png, "valid source JSON and PNG remain unchanged by reads/prepare")
        } catch { expect(false,"clipboard import fixture failed: \(error)") }
    }
}

extension ClipboardImportTests {
    private static func runLegacy(_ expect: (Bool, String) -> Void) {
        let fm = FileManager.default
        let root = fm.temporaryDirectory.appendingPathComponent("vorssaint-tests-clipboard-legacy-\(UUID())")
        defer { try? fm.removeItem(at: root) }
        func rejects(_ label: String, _ code: ClipboardImportError, _ body: () throws -> Void) {
            do { try body(); expect(false, label) }
            catch let error as ClipboardImportError { expect(error == code, label) }
            catch { expect(false, label + " unexpected error") }
        }
        do {
            try fm.createDirectory(at: root, withIntermediateDirectories: true)
            let source = root.appendingPathComponent("old-app.plist")
            let date = Date(timeIntervalSinceReferenceDate: 700000000)
            let entry = ClipboardHistoryEntry(text: "saved text", copiedAt: date, pinnedAt: date)
            let data = try JSONEncoder().encode([entry])
            for format in [PropertyListSerialization.PropertyListFormat.xml, .binary] {
                let outer = try PropertyListSerialization.data(fromPropertyList: ["clipboardHistoryEntries": data, "launchAtLoginWanted": true, "unrelatedSecret": "not imported"], format: format, options: 0)
                try outer.write(to: source)
                do {
                    let snapshot = try ClipboardImportSupport.read(source)
                    expect(snapshot.entries == [entry] && snapshot.images.isEmpty, "plist extracts only clipboard Data in \(format)")
                    expect(try Data(contentsOf: source) == outer, "plist source bytes unchanged in \(format)")
                } catch { expect(false, "valid \(format) plist rejected: \(error)") }
            }
            func plist(_ value: Any) throws {
                try PropertyListSerialization.data(fromPropertyList: value, format: .binary, options: 0).write(to: source)
            }
            for value: Any in [[:], ["clipboardHistoryEntries": "[]"], ["clipboardHistoryEntries": []], ["not a dictionary"]] {
                try plist(value)
                rejects("wrong plist root/key/type rejects", .invalidDocument) { _ = try ClipboardImportSupport.read(source) }
            }
            let legacy = Data("[{\"text\":\"hello\",\"copiedAt\":700000000},{\"text\":\"second\",\"copiedAt\":700000000}]".utf8)
            try plist(["clipboardHistoryEntries": legacy])
            do {
                let snapshot = try ClipboardImportSupport.read(source)
                expect(snapshot.entries.map(\.text) == ["hello", "second"] && snapshot.entries.allSatisfy { $0.kind == .text && $0.copiedAt == date }, "legacy missing id/kind keeps text and real dates")
                expect(Set(snapshot.entries.map(\.id)).count == 2, "legacy generated IDs are unique within immutable snapshot")
                let first = try ClipboardImportSupport.prepare(selected: snapshot.entries, images: [:], current: [], recentLimit: 0)
                expect(first.entries.count == 2 && snapshot.entries.map(\.text) == ["hello", "second"], "legacy snapshot can flow through existing merge unchanged")
            } catch { expect(false, "legacy missing IDs rejected: \(error)") }
            for json in ["[{\"text\":\"missing date\"}]", "[{\"id\":null,\"text\":\"x\",\"copiedAt\":1}]", "[{\"text\":\"x\",\"copiedAt\":1,\"unknown\":true}]"] {
                try plist(["clipboardHistoryEntries": Data(json.utf8)])
                rejects("legacy missing date or malformed fields reject", .invalidDocument) { _ = try ClipboardImportSupport.read(source) }
            }
            let jsonURL = root.appendingPathComponent("strict.json")
            try legacy.write(to: jsonURL)
            rejects("JSON missing IDs stays strict", .invalidDocument) { _ = try ClipboardImportSupport.read(jsonURL) }
            let png = Data(base64Encoded: "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+jXioAAAAASUVORK5CYII=")!
            let hash = SHA256.hash(data: png).map { String(format: "%02x", $0) }.joined()
            let image = ClipboardHistoryEntry(text: "", copiedAt: date, kind: .image, imageFile: "image.png", imageHash: hash, imageWidth: 1, imageHeight: 1)
            try plist(["clipboardHistoryEntries": JSONEncoder().encode([image])])
            let imageDir = root.appendingPathComponent("ClipboardImages")
            try fm.createDirectory(at: imageDir, withIntermediateDirectories: false)
            try png.write(to: imageDir.appendingPathComponent("image.png"))
            rejects("plist cannot infer adjacent images", .imageDirectoryRequired) { _ = try ClipboardImportSupport.read(source) }
            let withImages = try ClipboardImportSupport.read(source, imageDirectory: imageDir)
            expect(withImages.entries == [image] && withImages.images["image.png"] == png, "explicit image directory imports validated image")
            expect(try Data(contentsOf: imageDir.appendingPathComponent("image.png")) == png, "explicit image source remains unchanged")
            rejects("nonlocal image directory rejects before access", .unreadable) { _ = try ClipboardImportSupport.read(source, imageDirectory: URL(string: "https://example.invalid/images")!) }
            let alias = root.appendingPathComponent("alias")
            try fm.createSymbolicLink(at: alias, withDestinationURL: imageDir)
            rejects("symlink image directory rejected", .missingImage) { _ = try ClipboardImportSupport.read(source, imageDirectory: alias) }
            try Data("bad".utf8).write(to: imageDir.appendingPathComponent("image.png"))
            rejects("explicit image mismatch rejects", .invalidDocument) { _ = try ClipboardImportSupport.read(source, imageDirectory: imageDir) }
            let oversized = root.appendingPathComponent("large.plist")
            _ = fm.createFile(atPath: oversized.path, contents: nil)
            let handle = try FileHandle(forWritingTo: oversized)
            try handle.truncate(atOffset: UInt64(160 * 1024 * 1024 + 1)); try handle.close()
            rejects("outer plist size preflight", .tooLarge) { _ = try ClipboardImportSupport.read(oversized) }
            try plist(["clipboardHistoryEntries": Data(count: ClipboardHistoryEditing.maxEncodedHistoryBytes + 1)])
            rejects("inner clipboard JSON retains size limit", .tooLarge) { _ = try ClipboardImportSupport.read(source) }
            try Data("not plist".utf8).write(to: source)
            rejects("corrupt plist rejects", .invalidDocument) { _ = try ClipboardImportSupport.read(source) }
        } catch { expect(false, "legacy fixture failed: \(error)") }
    }
}
