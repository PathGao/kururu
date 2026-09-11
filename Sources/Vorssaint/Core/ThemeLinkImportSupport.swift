// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import Foundation

enum ThemeLinkImportError: Error {
    case invalidLink, downloadFailed, tooLarge, invalidArchive, themeNotFound, ambiguousTheme, invalidTheme
}

enum ThemeLinkImportSupport {
    struct Link {
        let publisher: String
        let extensionName: String
        let slug: String
        var downloadURL: URL {
            URL(string: "https://\(publisher).gallery.vsassets.io/_apis/public/gallery/publisher/\(publisher)/extension/\(extensionName)/latest/assetbyname/Microsoft.VisualStudio.Services.VSIXPackage")!
        }
    }

    static func parse(_ input: String) throws -> Link {
        guard let url = URLComponents(string: input.trimmingCharacters(in: .whitespacesAndNewlines)),
              url.scheme?.lowercased() == "https", url.host?.lowercased() == "vscodethemes.com",
              url.user == nil, url.password == nil, url.port == nil,
              url.query == nil, url.fragment == nil else { throw ThemeLinkImportError.invalidLink }
        let parts = url.path.split(separator: "/", omittingEmptySubsequences: false)
        guard parts.count == 4, parts[0].isEmpty, parts[1] == "e" else { throw ThemeLinkImportError.invalidLink }
        let identifier = parts[2].split(separator: ".", omittingEmptySubsequences: false)
        func valid(_ value: Substring) -> Bool {
            !value.isEmpty && value.count <= 128 && value.utf8.allSatisfy {
                (48...57).contains($0) || (65...90).contains($0) || (97...122).contains($0) || $0 == 45
            }
        }
        guard identifier.count == 2, identifier.allSatisfy(valid), valid(parts[3]) else { throw ThemeLinkImportError.invalidLink }
        return Link(publisher: String(identifier[0]), extensionName: String(identifier[1]), slug: String(parts[3]).lowercased())
    }

    static func selection(manifest: Data, slug: String) throws -> (path: String, name: String) {
        guard let object = try? JSONSerialization.jsonObject(with: manifest) as? [String: Any],
              let contributes = object["contributes"] as? [String: Any],
              let themes = contributes["themes"] as? [[String: Any]] else { throw ThemeLinkImportError.invalidArchive }
        func normalized(_ value: String) -> String {
            value.lowercased().components(separatedBy: CharacterSet.alphanumerics.inverted)
                .filter { !$0.isEmpty }.joined(separator: "-")
        }
        let matches = themes.filter { theme in
            [theme["label"], theme["id"]].compactMap { $0 as? String }.contains { normalized($0) == slug }
        }
        guard !matches.isEmpty else { throw ThemeLinkImportError.themeNotFound }
        guard matches.count == 1 else { throw ThemeLinkImportError.ambiguousTheme }
        guard var path = matches[0]["path"] as? String else { throw ThemeLinkImportError.invalidArchive }
        if path.hasPrefix("./") { path.removeFirst(2) }
        guard !path.isEmpty, !path.hasPrefix("/"), !path.contains("\\"),
              !path.contains("*"), !path.contains("?"), !path.contains("["),
              path.split(separator: "/", omittingEmptySubsequences: false).allSatisfy({ !$0.isEmpty && $0 != "." && $0 != ".." })
        else { throw ThemeLinkImportError.invalidArchive }
        return ("extension/" + path, (matches[0]["label"] as? String) ?? (matches[0]["id"] as? String) ?? slug)
    }
}
