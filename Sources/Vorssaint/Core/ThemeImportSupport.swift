// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import Foundation

enum ThemeColorRole: String, CaseIterable {
    case background, card, primaryText, secondaryText, border, accent

    var sourceKeys: [String] {
        switch self {
        case .background: return ["editor.background"]
        case .card: return ["editorWidget.background", "sideBar.background"]
        case .primaryText: return ["editor.foreground", "foreground"]
        case .secondaryText: return ["descriptionForeground"]
        case .border: return ["panel.border", "contrastBorder"]
        case .accent: return ["focusBorder", "button.background"]
        }
    }
}

struct ThemeRGBA: Equatable {
    let red: Double
    let green: Double
    let blue: Double
    let alpha: Double

    init?(hex: String) {
        let digits = Array(hex.utf8)
        guard digits.first == 35, [4, 5, 7, 9].contains(digits.count),
              digits.dropFirst().allSatisfy({ (48...57).contains($0) || (65...70).contains($0) || (97...102).contains($0) })
        else { return nil }
        let short = digits.count < 6
        let expanded = short ? digits.dropFirst().flatMap { [$0, $0] } : Array(digits.dropFirst())
        guard let value = UInt32(String(decoding: expanded, as: UTF8.self), radix: 16) else { return nil }
        let rgba = expanded.count == 6 ? (value << 8) | 255 : value
        red = Double((rgba >> 24) & 255) / 255
        green = Double((rgba >> 16) & 255) / 255
        blue = Double((rgba >> 8) & 255) / 255
        alpha = Double(rgba & 255) / 255
    }

    var hex: String {
        String(format: "#%02X%02X%02X%02X", Int((red * 255).rounded()),
               Int((green * 255).rounded()), Int((blue * 255).rounded()), Int((alpha * 255).rounded()))
    }
}

struct ImportedTheme: Equatable {
    let name: String
    let colors: [ThemeColorRole: ThemeRGBA]
}

enum ThemeImportError: Error, Equatable {
    case tooLarge, invalidJSON, invalidColors, noColors, invalidColor(String), unreadable
}

enum ThemeImportSupport {
    static let maximumBytes = 256 * 1024

    static func parse(_ data: Data) throws -> ImportedTheme {
        guard data.count <= maximumBytes else { throw ThemeImportError.tooLarge }
        guard String(data: data, encoding: .utf8) != nil else { throw ThemeImportError.invalidJSON }
        let json = try normalizedJSONC(data)
        guard let object = try? JSONSerialization.jsonObject(with: json),
              let root = object as? [String: Any] else { throw ThemeImportError.invalidJSON }
        guard let colors = root["colors"] as? [String: Any] else { throw ThemeImportError.invalidColors }
        var mapped: [ThemeColorRole: ThemeRGBA] = [:]
        for role in ThemeColorRole.allCases {
            for key in role.sourceKeys {
                guard let value = colors[key] else { continue }
                guard let text = value as? String, let color = ThemeRGBA(hex: text)
                else { throw ThemeImportError.invalidColor(key) }
                if mapped[role] == nil { mapped[role] = color }
            }
        }
        guard !mapped.isEmpty else { throw ThemeImportError.noColors }
        let rawName = root["name"] as? String ?? ""
        let name = String(rawName.unicodeScalars.filter { !CharacterSet.controlCharacters.contains($0) }.prefix(80))
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return ImportedTheme(name: name, colors: mapped)
    }

    static func savedData(_ theme: ImportedTheme) throws -> Data {
        let colors = Dictionary(uniqueKeysWithValues: theme.colors.map { ($0.key.sourceKeys[0], $0.value.hex) })
        let data = try JSONSerialization.data(withJSONObject: ["name": theme.name, "colors": colors], options: [.sortedKeys])
        _ = try parse(data)
        return data
    }

    static func read(_ url: URL) throws -> ImportedTheme {
        guard url.isFileURL else { throw ThemeImportError.unreadable }
        do {
            guard try url.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile == true else {
                throw ThemeImportError.unreadable
            }
            let handle = try FileHandle(forReadingFrom: url)
            defer { try? handle.close() }
            let data = try handle.read(upToCount: maximumBytes + 1) ?? Data()
            return try parse(data)
        } catch let error as ThemeImportError {
            throw error
        } catch {
            throw ThemeImportError.unreadable
        }
    }

    // JSONC adds comments and trailing commas, not JSON5's unquoted keys or single quotes.
    private static func normalizedJSONC(_ data: Data) throws -> Data {
        var bytes = Array(data)
        var index = 0
        var inString = false
        var escaped = false
        while index < bytes.count {
            let byte = bytes[index]
            if inString {
                if escaped { escaped = false }
                else if byte == 92 { escaped = true }
                else if byte == 34 { inString = false }
                index += 1
                continue
            }
            if byte == 34 { inString = true; index += 1; continue }
            if byte == 47, index + 1 < bytes.count {
                let next = bytes[index + 1]
                if next == 47 {
                    bytes[index] = 32; bytes[index + 1] = 32; index += 2
                    while index < bytes.count, bytes[index] != 10, bytes[index] != 13 {
                        bytes[index] = 32; index += 1
                    }
                    continue
                }
                if next == 42 {
                    bytes[index] = 32; bytes[index + 1] = 32; index += 2
                    var closed = false
                    while index < bytes.count {
                        if bytes[index] == 42, index + 1 < bytes.count, bytes[index + 1] == 47 {
                            bytes[index] = 32; bytes[index + 1] = 32; index += 2; closed = true; break
                        }
                        if bytes[index] != 10, bytes[index] != 13 { bytes[index] = 32 }
                        index += 1
                    }
                    guard closed else { throw ThemeImportError.invalidJSON }
                    continue
                }
            }
            index += 1
        }
        guard !inString else { throw ThemeImportError.invalidJSON }
        inString = false; escaped = false
        for position in bytes.indices {
            let byte = bytes[position]
            if inString {
                if escaped { escaped = false }
                else if byte == 92 { escaped = true }
                else if byte == 34 { inString = false }
            } else if byte == 34 {
                inString = true
            } else if byte == 44 {
                var previous = position - 1
                while previous >= 0, [9, 10, 13, 32].contains(bytes[previous]) { previous -= 1 }
                guard previous >= 0, ![44, 91, 123].contains(bytes[previous]) else { throw ThemeImportError.invalidJSON }
                var next = position + 1
                while next < bytes.count, [9, 10, 13, 32].contains(bytes[next]) { next += 1 }
                if next < bytes.count, bytes[next] == 93 || bytes[next] == 125 { bytes[position] = 32 }
            }
        }
        return Data(bytes)
    }
}
