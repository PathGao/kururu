// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import Foundation

enum CleanerPackageCaches {
    struct Entry {
        let url: URL
        let size: Int64
    }

    static func scan(home: URL, isCancelled: () -> Bool = { false }) -> [Entry] {
        let fm = FileManager.default
        return [".npm/_npx", ".bun/install/cache"].compactMap { relativePath in
            guard !isCancelled() else { return nil }
            let url = home.appendingPathComponent(relativePath).standardizedFileURL
            guard url.resolvingSymlinksInPath().path == url.path,
                  let attributes = try? fm.attributesOfItem(atPath: url.path),
                  attributes[.type] as? FileAttributeType == .typeDirectory,
                  (try? fm.contentsOfDirectory(atPath: url.path)) != nil else { return nil }
            let size = DirectorySize.of(url, isCancelled: isCancelled)
            return size > 0 ? Entry(url: url, size: size) : nil
        }
    }
}
