// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

enum ShelfImportTests {
    static func run(_ expect: (Bool, String) -> Void) {
        func complete(_ value: Any) -> Any {
            if let rows = value as? [Any] { return rows.map(complete) }
            guard var row = value as? [String: Any] else { return value }
            if row["id"] == nil { row["id"] = UUID().uuidString }; if row["title"] == nil { row["title"] = "" }
            if let children = row["children"] { row["children"] = complete(children) }; return row
        }
        func rejects(_ rows: Any, _ message: String, error expected: ShelfImportError = .invalidDocument) {
            do { _ = try ShelfImportSupport.decode(JSONSerialization.data(withJSONObject: complete(rows))); expect(false, message) }
            catch { expect((error as? ShelfImportError) == expected, message) }
        }
        do {
            let text: [String: Any] = ["id": UUID().uuidString, "title": "", "kind": "text", "text": "  original\n"]
            let decoded = try ShelfImportSupport.decode(JSONSerialization.data(withJSONObject: [text]))
            expect(decoded.count == 1 && decoded[0].text == "  original\n" && decoded[0].title == "", "JSON fields and whitespace preserved")
            let file = ShelfPersistedItem(id: UUID(), kind: .file, title: "file", path: "/unmounted/example", bookmark: Data([1, 2]))
            let link = ShelfPersistedItem(id: UUID(), kind: .link, title: "link", url: "mailto:example@example.com")
            let batch = ShelfPersistedItem(id: UUID(), kind: .batch, title: "pile", children: [file, link, decoded[0]])
            let json = try JSONEncoder().encode([batch])
            expect(try ShelfImportSupport.decode(json) == [batch], "all four kinds round trip retaining tree and bookmarks")
            for format in [PropertyListSerialization.PropertyListFormat.xml, .binary] {
                let plist = try PropertyListSerialization.data(fromPropertyList: ["shelfItems": json, "unrelated": true], format: format, options: 0)
                expect(try ShelfImportSupport.decode(plist, legacy: true) == [batch], "plist extracts shelfItems Data")
            }
            let historical = try JSONSerialization.data(withJSONObject: [["kind": "text", "text": "old"]])
            let historicalPlist = try PropertyListSerialization.data(fromPropertyList: ["shelfItems": historical], format: .binary, options: 0)
            let old = try ShelfImportSupport.decode(historicalPlist, legacy: true)
            expect(old.count == 1 && old[0].title.isEmpty && old[0].text == "old", "legacy defaults missing id and title")
            do { _ = try ShelfImportSupport.decode(historical); expect(false, "JSON requires id and title") }
            catch ShelfImportError.invalidDocument { expect(true, "JSON requires id and title") }
            let wrongPlist = try PropertyListSerialization.data(fromPropertyList: ["shelfItems": "[]"], format: .binary, options: 0)
            do { _ = try ShelfImportSupport.decode(wrongPlist, legacy: true); expect(false, "plist requires Data") }
            catch ShelfImportError.invalidDocument { expect(true, "plist requires Data") }
            let encodedFile = try JSONSerialization.jsonObject(with: JSONEncoder().encode(file)) as? [String: Any]
            expect(encodedFile?["text"] == nil && encodedFile?["children"] == nil, "real encoder omits irrelevant optionals")
            rejects([["kind": "text", "text": "ok", "path": NSNull()]], "irrelevant null is not a writer field")
            rejects([["kind": "file", "path": "/x", "bookmark": "not base64"]], "bookmark must decode as Data")
            let boundary = ShelfPersistedItem(id: UUID(), kind: .text, title: "", text: String(repeating: "x", count: ShelfPersistenceSupport.maxTextLength))
            expect(try ShelfImportSupport.decode(JSONEncoder().encode([boundary])) == [boundary], "exact text limit fits unchanged")
            for row in [["kind": "future"], ["kind": "text", "text": " "], ["kind": "text", "text": "ok", "path": "/mixed"], ["kind": "file", "path": "relative"], ["kind": "file", "path": "/bad\0path"], ["kind": "link", "url": "relative"], ["kind": "link", "url": "file:///tmp/x"], ["kind": "text", "text": "ok", "extra": "unknown"], ["kind": "text", "text": "ok", "id": "bad"]] {
                rejects([row], "reject malformed or conflicting payload: \(row)")
            }
            rejects([text, ["kind": "future"]], "unknown sibling cannot disappear")
            rejects([["kind": "batch", "children": [text, ["kind": "future"]]]], "unknown child cannot disappear")
            rejects([["kind": "batch", "children": []]], "empty batch cannot disappear")
            let single = ShelfPersistedItem(id: UUID(), kind: .batch, title: "single", children: decoded)
            expect(try ShelfImportSupport.decode(JSONEncoder().encode([single])) == [single], "single child batch retains tree")
            rejects([["kind": "text", "text": String(repeating: "x", count: ShelfPersistenceSupport.maxTextLength + 1)]], "long text cannot truncate")
            let repeated = ["id": UUID().uuidString, "title": "", "kind": "text", "text": "same"]
            rejects([repeated, ["kind": "batch", "children": [text, repeated]]], "duplicate identity across depths rejected")
            var nested: [String: Any] = text
            for _ in 1..<ShelfPersistenceSupport.maxDepth { nested = ["id": UUID().uuidString, "title": "", "kind": "batch", "children": [["id": UUID().uuidString, "title": "", "kind": "text", "text": "x"], nested]] }
            expect(try ShelfImportSupport.decode(JSONSerialization.data(withJSONObject: [nested])).count == 1, "leaf at depth three fits")
            rejects([["kind": "batch", "children": [["kind": "text", "text": "outer"], nested]]], "leaf at depth four rejected")
            let full = (0..<ShelfPersistenceSupport.maxLeaves).map { _ in ShelfPersistedItem(id: UUID(), kind: .text, title: "", text: "x") }
            expect(try ShelfImportSupport.decode(JSONEncoder().encode(full)) == full, "exact leaf capacity fits")
            rejects(Array(repeating: ["kind": "text", "text": "x"], count: ShelfPersistenceSupport.maxLeaves + 1), "excess leaves cannot truncate", error: .capacityExceeded)
            let copies = try ShelfImportSupport.selectedCopies([batch], excluding: [batch.id, file.id])
            expect(copies[0].id != batch.id && copies[0].children?[0].id != file.id && copies[0].children?[0].bookmark == file.bookmark, "copies refresh every identity and retain payload")
            func allIDs(_ items: [ShelfPersistedItem]) -> [UUID] { items.flatMap { [$0.id] + allIDs($0.children ?? []) } }
            func payload(_ item: ShelfPersistedItem) -> ShelfPersistedItem {
                ShelfPersistedItem(id: UUID(uuidString: "00000000-0000-0000-0000-000000000000")!, kind: item.kind, title: item.title,
                    text: item.text, url: item.url, path: item.path, bookmark: item.bookmark, children: item.children?.map(payload))
            }
            let merged = try ShelfImportSupport.merging(selected: [batch], current: [single])
            let generated = allIDs(Array(merged.dropFirst()))
            expect(merged[0] == single && merged[1...].map(payload) == [batch].map(payload), "merge preserves current exactly and every selected payload")
            expect(Set(generated).count == generated.count && Set(generated).isDisjoint(with: allIDs([single, batch])), "all generated descendants avoid source and current identities")
            expect(try ShelfImportSupport.decode(json) == [batch], "copy and merge leave source unchanged")
            expect(try ShelfImportSupport.merging(selected: [batch], current: []).count == 1, "merge preserves selected root tree")
            do { _ = try ShelfImportSupport.merging(selected: decoded, current: full); expect(false, "merge refuses capacity overflow") }
            catch ShelfImportError.capacityExceeded { expect(true, "merge refuses capacity overflow") }
            do { _ = try ShelfImportSupport.merging(selected: [], current: []); expect(false, "empty selection rejected") }
            catch ShelfImportError.emptySelection { expect(true, "empty selection rejected") }
        } catch { expect(false, "shelf import fixture error: \(error)") }
    }
}
