// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

enum ShelfImportError: Error, Equatable {
    case invalidDocument, tooLarge, capacityExceeded, emptySelection
}

enum ShelfImportSupport {
    static let maximumBytes = ShelfIndexStore.maximumBytes
    // XML plists base64-encode the JSON and may include other preferences.
    static let maximumPropertyListBytes = maximumBytes * 2

    static func decode(_ data: Data, legacy: Bool = false) throws -> [ShelfPersistedItem] {
        guard data.count <= (legacy ? maximumPropertyListBytes : maximumBytes) else { throw ShelfImportError.tooLarge }
        do {
            let json: Data
            if legacy {
                guard let plist = try PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any],
                      let blob = plist["shelfItems"] as? Data else { throw ShelfImportError.invalidDocument }
                json = blob
            } else { json = data }
            guard json.count <= maximumBytes else { throw ShelfImportError.tooLarge }
            guard let rows = try JSONSerialization.jsonObject(with: json) as? [[String: Any]] else { throw ShelfImportError.invalidDocument }
            var ids = Set<UUID>(), leaves = 0
            func read(_ rows: [[String: Any]], depth: Int) throws -> [ShelfPersistedItem] {
                guard depth < ShelfPersistenceSupport.maxDepth else { throw ShelfImportError.invalidDocument }
                return try rows.map { row in
                    guard let rawKind = row["kind"] as? String, let kind = ShelfPersistedItem.Kind(rawValue: rawKind) else { throw ShelfImportError.invalidDocument }
                    let payload: Set<String>
                    switch kind {
                    case .file: payload = ["path", "bookmark"]
                    case .text: payload = ["text"]
                    case .link: payload = ["url"]
                    case .batch: payload = ["children"]
                    }
                    guard Set(row.keys).isSubset(of: payload.union(["id", "title", "kind"])) else { throw ShelfImportError.invalidDocument }
                    let id: UUID
                    if let raw = row["id"] as? String, let parsed = UUID(uuidString: raw) { id = parsed }
                    else if legacy && row["id"] == nil { id = UUID() }
                    else { throw ShelfImportError.invalidDocument }
                    let title: String
                    if let value = row["title"] as? String { title = value }
                    else if legacy && row["title"] == nil { title = "" }
                    else { throw ShelfImportError.invalidDocument }
                    guard ids.insert(id).inserted else { throw ShelfImportError.invalidDocument }
                    var item = ShelfPersistedItem(id: id, kind: kind, title: title)
                    switch kind {
                    case .file:
                        guard let path = row["path"] as? String, path.hasPrefix("/"), !path.contains("\0") else { throw ShelfImportError.invalidDocument }
                        item.path = path
                        if let value = row["bookmark"] {
                            guard let raw = value as? String, let bookmark = Data(base64Encoded: raw) else { throw ShelfImportError.invalidDocument }
                            item.bookmark = bookmark
                        }
                    case .text:
                        guard let text = row["text"] as? String, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                              text.count <= ShelfPersistenceSupport.maxTextLength else { throw ShelfImportError.invalidDocument }
                        item.text = text
                    case .link:
                        guard let raw = row["url"] as? String, !raw.contains("\0"), !raw.lowercased().contains("%00"),
                              let url = URL(string: raw), url.scheme != nil, !url.isFileURL else { throw ShelfImportError.invalidDocument }
                        item.url = raw
                    case .batch:
                        guard let children = row["children"] as? [[String: Any]], !children.isEmpty else { throw ShelfImportError.invalidDocument }
                        item.children = try read(children, depth: depth + 1)
                    }
                    if kind != .batch {
                        leaves += 1
                        guard leaves <= ShelfPersistenceSupport.maxLeaves else { throw ShelfImportError.capacityExceeded }
                    }
                    return item
                }
            }
            return try read(rows, depth: 0)
        } catch let error as ShelfImportError { throw error }
        catch { throw ShelfImportError.invalidDocument }
    }

    static func selectedCopies(_ items: [ShelfPersistedItem], excluding: Set<UUID> = []) throws -> [ShelfPersistedItem] {
        guard !items.isEmpty else { throw ShelfImportError.emptySelection }
        _ = try decode(JSONEncoder().encode(items))
        var used = excluding
        func collect(_ items: [ShelfPersistedItem]) { for item in items { used.insert(item.id); collect(item.children ?? []) } }
        collect(items)
        func copy(_ item: ShelfPersistedItem) -> ShelfPersistedItem {
            var id = UUID()
            while !used.insert(id).inserted { id = UUID() }
            return ShelfPersistedItem(id: id, kind: item.kind, title: item.title, text: item.text, url: item.url,
                path: item.path, bookmark: item.bookmark, children: item.children?.map(copy))
        }
        return items.map(copy)
    }

    static func merging(selected: [ShelfPersistedItem], current: [ShelfPersistedItem]) throws -> [ShelfPersistedItem] {
        _ = try decode(JSONEncoder().encode(current))
        var ids = Set<UUID>()
        func collect(_ items: [ShelfPersistedItem]) { for item in items { ids.insert(item.id); collect(item.children ?? []) } }
        collect(current)
        let merged = current + (try selectedCopies(selected, excluding: ids))
        _ = try decode(JSONEncoder().encode(merged))
        return merged
    }
}
