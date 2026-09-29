// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint
import Foundation
import CryptoKit
import Darwin

enum ScratchpadImportTests {
    static func run(_ expect: (Bool, String) -> Void) {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let one = ScratchpadPad(id: UUID(), name: "Original", text: "exact\ntext", modifiedAt: .distantPast)
        let empty = ScratchpadPad(id: UUID(), name: "Empty", text: "", modifiedAt: nil)
        let doc = ScratchpadDocument(pads: [one, empty], selectedID: empty.id)
        func rejects(_ name: String, _ body: () throws -> Void) {
            do { try body(); expect(false, name) } catch { expect(true, name) }
        }
        do {
            let data = try JSONEncoder().encode(doc)
            let decoded = try ScratchpadImportSupport.decode(data, fileName: "Scratchpad.json")
            expect(decoded.pads == doc.pads && decoded.sourceName == "Scratchpad.json", "JSON preserves complete pads and source label")
            expect(try ScratchpadImportSupport.decodeDocument(data) == doc, "strict document loader preserves selected ID")
            let txt = try ScratchpadImportSupport.decode(Data(" \nhello\n ".utf8), fileName: "  My  note .txt")
            expect(txt.pads[0].name == "My note" && txt.pads[0].text == " \nhello\n ", "txt preserves bytes as text and normalizes only filename")
            let blank = try ScratchpadImportSupport.decode(Data(), fileName: "blank.txt")
            expect(blank.pads.count == 1 && blank.pads[0].text.isEmpty, "blank txt creates honest empty pad")
            rejects("invalid UTF8 rejected") { _ = try ScratchpadImportSupport.decode(Data([0xff]), fileName: "a.txt") }
            rejects("unsupported extension rejected") { _ = try ScratchpadImportSupport.decode(data, fileName: "a.bin") }
            rejects("oversized data rejected") { _ = try ScratchpadImportSupport.decode(Data(count: ScratchpadImportSupport.maximumBytes + 1), fileName: "a.txt") }
            rejects("malformed JSON rejected") { _ = try ScratchpadImportSupport.decode(Data("{".utf8), fileName: "a.json") }
            let object = try JSONSerialization.jsonObject(with: data) as! [String: Any]
            func rejectObject(_ object: [String: Any], _ name: String) {
                rejects(name) { _ = try ScratchpadImportSupport.decode(JSONSerialization.data(withJSONObject: object), fileName: "a.json") }
            }
            var bad = object;bad["future"] = true;rejectObject(bad, "unknown root field rejected")
            bad = object;bad.removeValue(forKey: "selectedID");rejectObject(bad, "missing selection rejected")
            bad = object;bad["selectedID"] = UUID().uuidString;rejectObject(bad, "unknown selection rejected")
            let pads = object["pads"] as! [[String: Any]]
            bad = object;bad["pads"] = [pads[0], pads[0]];bad["selectedID"] = one.id.uuidString;rejectObject(bad, "duplicate pad IDs rejected")
            bad = object;bad["pads"] = [];rejectObject(bad, "empty JSON document rejected")
            bad = object;bad["pads"] = Array(repeating: pads[0], count: 13);rejectObject(bad, "over capacity JSON rejected")
            for (field,value) in [("name", ""), ("name", String(repeating: "x", count: 41)), ("future", "data")] {
                var pad = pads[0];pad[field] = value;bad = object;bad["pads"] = [pad, pads[1]]
                rejectObject(bad, "invalid pad field \(field) rejected")
            }
            let merged = try ScratchpadImportSupport.merge(selected: [one, empty, one], into: doc, now: now)
            expect(merged.pads.count == 4, "selected duplicate IDs imported once")
            expect(Array(merged.pads.prefix(2)) == doc.pads && merged.selectedID == doc.selectedID, "existing pads and selection unchanged")
            expect(Set(merged.pads.map(\.id)).count == 4, "all appended IDs are fresh")
            expect(merged.pads[2].text == one.text && merged.pads[2].modifiedAt == now && merged.pads[3].modifiedAt == nil,
                   "copies preserve text and refresh only nonempty modification date")
            let again = try ScratchpadImportSupport.merge(selected: [one], into: merged, now: now)
            expect(again.pads.count == 5 && again.pads.last?.id != merged.pads[2].id, "repeat import deliberately creates another copy")
            expect(try ScratchpadImportSupport.merge(selected: [], into: doc, now: now) == doc, "empty selection leaves document unchanged")
            let full = ScratchpadDocument(pads: (0..<12).map { _ in ScratchpadPad(id: UUID(), name: "Existing", text: "keep", modifiedAt: now) }, selectedID: one.id)
            var validFull = full;validFull.selectedID = validFull.pads[0].id
            rejects("capacity rejects complete batch") { _ = try ScratchpadImportSupport.merge(selected: [one], into: validFull, now: now) }

            let singleBlank = ScratchpadDocument(pads: [empty], selectedID: empty.id)
            let defaultAppend = try ScratchpadImportSupport.merge(selected: [one], into: singleBlank, now: now)
            expect(defaultAppend.pads.first == empty && defaultAppend.selectedID == empty.id, "default preserves single empty pad")
            do {
                let replacement = try ScratchpadImportSupport.merge(selected: validFull.pads, into: singleBlank, now: now, replaceOnlyEmpty: true)
                expect(replacement.pads.count == 12 && replacement.selectedID == replacement.pads.first?.id,
                       "explicit empty replacement imports twelve and selects first copy")
                expect(!replacement.pads.contains(where: { $0.id == empty.id }) && Set(replacement.pads.map(\.id)).isDisjoint(with: Set(validFull.pads.map(\.id))),
                       "explicit empty replacement contains fresh copies only")
            } catch { expect(false, "explicit empty replacement imports twelve"); expect(false, "explicit empty replacement contains fresh copies only") }
            let nonemptyDoc = ScratchpadDocument(pads: [one], selectedID: one.id)
            let keptNonempty = try ScratchpadImportSupport.merge(selected: [empty], into: nonemptyDoc, now: now, replaceOnlyEmpty: true)
            expect(keptNonempty.pads.first == one && keptNonempty.selectedID == one.id && keptNonempty.pads.count == 2, "replacement option never deletes nonempty existing note")
            let anotherEmpty = ScratchpadPad(id: UUID(), name: "Other", text: "", modifiedAt: nil)
            let multipleEmpty = ScratchpadDocument(pads: [empty, anotherEmpty], selectedID: anotherEmpty.id)
            let keptMultiple = try ScratchpadImportSupport.merge(selected: [one], into: multipleEmpty, now: now, replaceOnlyEmpty: true)
            expect(Array(keptMultiple.pads.prefix(2)) == multipleEmpty.pads && keptMultiple.selectedID == anotherEmpty.id, "replacement option never deletes multiple empty notes")
            expect(try ScratchpadImportSupport.merge(selected: [], into: singleBlank, now: now, replaceOnlyEmpty: true) == singleBlank, "empty import never deletes the single blank")

            let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent(".build/scratchpad-import-fixtures-\(UUID())", isDirectory: true)
            try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
            defer { try? FileManager.default.removeItem(at: root) }
            let source = root.appendingPathComponent("Scratchpad.json");try data.write(to: source)
            rejects("current destination cannot be its own import source") {
                try ScratchpadImportSupport.validateSource(source, destination: source)
            }
            let parentAlias = root.appendingPathComponent("parent-link")
            try FileManager.default.createSymbolicLink(at: parentAlias, withDestinationURL: root)
            rejects("parent symlink alias of destination rejected") {
                try ScratchpadImportSupport.validateSource(parentAlias.appendingPathComponent("Scratchpad.json"), destination: source)
            }
            try ScratchpadImportSupport.validateSource(root.appendingPathComponent("other.json"), destination: source)
            expect(true, "different source remains allowed")
            let hardLink = root.appendingPathComponent("hard-link.json")
            try FileManager.default.linkItem(at: source, to: hardLink)
            rejects("hard link to current destination refused") {
                try ScratchpadImportSupport.validateSource(hardLink, destination: source)
            }
            let caseAlias = root.appendingPathComponent("scratchpad.JSON")
            if FileManager.default.fileExists(atPath: caseAlias.path) {
                rejects("case-insensitive alias of current destination refused") {
                    try ScratchpadImportSupport.validateSource(caseAlias, destination: source)
                }
            } else {
                // On a case-sensitive volume this is a separate, valid source.
                try data.write(to: caseAlias)
                try ScratchpadImportSupport.validateSource(caseAlias, destination: source)
                expect(true, "distinct case-sensitive source remains allowed")
            }
            rejects("nonlocal file URL refused") {
                _ = try ScratchpadImportSupport.readData(URL(string: "file://remote.invalid" + source.path)!)
            }
            rejects("NUL path refused") {
                _ = try ScratchpadImportSupport.readData(URL(fileURLWithPath: source.path + "\0ignored"))
            }
            let hash = SHA256.hash(data: data)
            expect(try ScratchpadImportSupport.read(source).pads == doc.pads, "regular file read reaches strict decoder")
            expect(try SHA256.hash(data: Data(contentsOf: source)) == hash, "read preserves source hash")
            let link = root.appendingPathComponent("link.json");try FileManager.default.createSymbolicLink(at: link, withDestinationURL: source)
            rejects("symlink refused") { _ = try ScratchpadImportSupport.read(link) }
            rejects("directory refused") { _ = try ScratchpadImportSupport.read(root) }
            rejects("nonfile URL refused") { _ = try ScratchpadImportSupport.read(URL(string: "https://example.com/a.txt")!) }
            let fifo = root.appendingPathComponent("pipe.txt");guard mkfifo(fifo.path, 0o600) == 0 else { expect(false, "FIFO fixture created");return }
            rejects("FIFO rejected without blocking") { _ = try ScratchpadImportSupport.read(fifo) }
            let large = root.appendingPathComponent("large.txt");try Data(count: ScratchpadImportSupport.maximumBytes + 1).write(to: large)
            rejects("oversized regular file rejected") { _ = try ScratchpadImportSupport.read(large) }
        } catch { expect(false, "import fixture failed: \(type(of: error))") }
    }
}
