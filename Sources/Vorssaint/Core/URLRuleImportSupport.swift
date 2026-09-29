// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import Foundation
import CoreFoundation

/// File-only interchange. No preferences, clipboard access or service activation.
enum URLRuleImportSupport {
    static let maximumBytes = 256 * 1024
    static let maximumRules = 2048

    enum Failure: Error, Equatable {
        case tooLarge, tooManyRules, unsupportedFormat, unsupportedVersion, invalidDocument
        case invalidRule(Int), duplicateRule(Int)
    }

    struct Rule: Equatable {
        let host: String
        let name: String
        let enabled: Bool
    }

    struct Document {
        let rows: [Rule]
        fileprivate init(rows: [Rule]) { self.rows = rows }
    }

    struct Preview {
        let baseRules: URLCleaning.Rules
        let rules: URLCleaning.Rules
        let addedCount: Int
        let changedCount: Int
        let duplicateCount: Int
    }

    static func decode(_ data: Data) throws -> Document {
        guard data.count <= maximumBytes else { throw Failure.tooLarge }
        guard let object = try? JSONSerialization.jsonObject(with: data),
              let root = object as? [String: Any] else { throw Failure.invalidDocument }
        guard unambiguousMembers(data) else { throw Failure.invalidDocument }
        if root["providers"] != nil { throw Failure.unsupportedFormat }
        guard root["format"] as? String == "kururu-url-rules" else { throw Failure.unsupportedFormat }
        guard Set(root.keys) == ["format", "version", "rules"],
              let version = root["version"] as? NSNumber,
              CFGetTypeID(version) != CFBooleanGetTypeID() else { throw Failure.invalidDocument }
        guard version == 1 else { throw Failure.unsupportedVersion }
        guard let values = root["rules"] as? [[String: Any]] else { throw Failure.invalidDocument }
        guard values.count <= maximumRules else { throw Failure.tooManyRules }
        var rows: [Rule] = []
        var seen = Set<String>()
        for (offset, value) in values.enumerated() {
            let index = offset + 1
            guard Set(value.keys) == ["host", "name", "enabled"],
                  let rawHost = value["host"] as? String,
                  let rawName = value["name"] as? String,
                  let enabled = value["enabled"] as? NSNumber,
                  CFGetTypeID(enabled) == CFBooleanGetTypeID() else { throw Failure.invalidRule(index) }
            let host = rawHost.lowercased()
            let name = rawName.lowercased()
            guard validHost(host), validName(name, host: host) else { throw Failure.invalidRule(index) }
            guard seen.insert(host + "|" + name).inserted else { throw Failure.duplicateRule(index) }
            rows.append(Rule(host: host, name: name, enabled: enabled.boolValue))
        }
        return Document(rows: rows)
    }

    static func preview(_ document: Document, current: URLCleaning.Rules) -> Preview {
        var result = current
        var added = 0, changed = 0, duplicates = 0
        for row in document.rows {
            // Explicit local choices win, including a disabled entry no longer in the built-in table.
            if current.added[row.host]?.contains(row.name) == true || current.disabled[row.host]?.contains(row.name) == true {
                duplicates += 1
                continue
            }
            let builtIn = isBuiltIn(row.name, host: row.host)
            if builtIn && row.enabled {
                duplicates += 1
                continue
            }
            if builtIn { changed += 1 }
            else {
                result.added[row.host, default: []].insert(row.name)
                added += 1
            }
            if !row.enabled { result.disabled[row.host, default: []].insert(row.name) }
        }
        return Preview(baseRules: current, rules: result, addedCount: added, changedCount: changed, duplicateCount: duplicates)
    }

    static func export(current: URLCleaning.Rules) throws -> Data {
        var rows: [[String: Any]] = []
        for host in Set(current.added.keys).union(current.disabled.keys).sorted() {
            for name in (current.added[host] ?? []).union(current.disabled[host] ?? []).sorted() {
                rows.append(["host": host, "name": name, "enabled": !(current.disabled[host]?.contains(name) ?? false)])
            }
        }
        let data = try JSONSerialization.data(withJSONObject: ["format": "kururu-url-rules", "version": 1, "rules": rows], options: [.sortedKeys, .prettyPrinted, .withoutEscapingSlashes])
        // Never emit a file the importer cannot read, including legacy invalid custom entries.
        _ = try decode(data)
        return data
    }

    /// Foundation accepts repeated keys (last wins) and trailing commas. Neither is part of this file format.
    /// Syntax validation stays with Foundation; this bounded lexical pass only rejects those extensions.
    private static func unambiguousMembers(_ data: Data) -> Bool {
        let bytes = Array(data)
        var index = 0
        var objects: [Set<String>] = []
        func nextNonWhitespace(_ start: Int) -> Int {
            var cursor = start
            while cursor < bytes.count && [9, 10, 13, 32].contains(bytes[cursor]) { cursor += 1 }
            return cursor
        }
        while index < bytes.count {
            switch bytes[index] {
            case 123: objects.append([])
            case 125:
                guard !objects.isEmpty else { return false }
                objects.removeLast()
            case 44:
                let next = nextNonWhitespace(index + 1)
                if next < bytes.count && (bytes[next] == 125 || bytes[next] == 93) { return false }
            case 34:
                let start = index
                index += 1
                while index < bytes.count && bytes[index] != 34 {
                    if bytes[index] == 92 { index += 1 }
                    index += 1
                }
                guard index < bytes.count else { return false }
                let next = nextNonWhitespace(index + 1)
                if next < bytes.count && bytes[next] == 58 {
                    guard !objects.isEmpty,
                          let key = try? JSONDecoder().decode(String.self, from: Data(bytes[start...index])),
                          objects[objects.count - 1].insert(key).inserted else { return false }
                }
            default: break
            }
            index += 1
        }
        return objects.isEmpty
    }

    private static let builtInNames = Dictionary(uniqueKeysWithValues: URLCleaning.ruleGroups(rules: .none).map { ($0.site, Set($0.entries.map(\.name))) })

    private static func isBuiltIn(_ name: String, host: String) -> Bool {
        builtInNames[host]?.contains(name) == true
    }

    private static func validHost(_ host: String) -> Bool {
        if host.isEmpty { return true }
        guard host.utf8.count <= 253, host.contains(".") else { return false }
        return host.split(separator: ".", omittingEmptySubsequences: false).allSatisfy { label in
            !label.isEmpty && label.utf8.count <= 63 && label.first != "-" && label.last != "-" &&
                label.utf8.allSatisfy { (97...122).contains($0) || (48...57).contains($0) || $0 == 45 }
        }
    }

    private static func validName(_ name: String, host: String) -> Bool {
        guard !name.isEmpty, name.utf8.count <= 256,
              URLCleaning.parameterName(from: name) == name,
              !name.unicodeScalars.contains(where: { CharacterSet.controlCharacters.contains($0) }) else { return false }
        // The engine supports only its global UTM prefix token, never arbitrary wildcard patterns.
        return !name.contains("*") || (host.isEmpty && name == URLCleaning.utmWildcard)
    }
}
