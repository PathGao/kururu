// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import Darwin
import Foundation

/// How big is this folder, on disk. Symlinks count as nothing and are never
/// followed, so a link into another tree cannot make a folder look enormous
/// or let the walk loop.
enum DirectorySize {
    static func of(_ url: URL, fm: FileManager = .default) -> Int64 {
        if isSymbolicLink(url) { return 0 }
        var isDir: ObjCBool = false
        guard fm.fileExists(atPath: url.path, isDirectory: &isDir) else { return 0 }
        if !isDir.boolValue { return fileSize(url) }
        var total: Int64 = 0
        if let enumerator = fm.enumerator(at: url,
                                          includingPropertiesForKeys: [.totalFileAllocatedSizeKey,
                                                                       .fileAllocatedSizeKey],
                                          options: [], errorHandler: nil) {
            for case let item as URL in enumerator {
                if isSymbolicLink(item) {
                    enumerator.skipDescendants()
                    continue
                }
                total += fileSize(item)
            }
        }
        return total
    }

    static func fileSize(_ url: URL) -> Int64 {
        let values = try? url.resourceValues(forKeys: [.totalFileAllocatedSizeKey, .fileAllocatedSizeKey])
        return Int64(values?.totalFileAllocatedSize ?? values?.fileAllocatedSize ?? 0)
    }

    static func isSymbolicLink(_ url: URL) -> Bool {
        var info = stat()
        guard lstat(url.path, &info) == 0 else { return false }
        return (info.st_mode & S_IFMT) == S_IFLNK
    }
}
