// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation
import Darwin

struct ShelfImportSnapshot {
    let sourceName: String
    let items: [ShelfPersistedItem]
}

struct ShelfImportMapping {
    let originalDirectory: String
    let selectedDirectory: URL
    let copyFiles: Bool
}

struct ShelfImportAssetSnapshot {
    let items: [ShelfPersistedItem]
    let files: [String: Data]
}

enum ShelfImportAssetError: Error, Equatable {
    case invalidPath(String), mappingConflict, unmappedFile(String), missingFile(String)
    case unreadableFile(String), changedFile(String), tooLarge, currentIndex
}

enum ShelfImportAssets {
    static let maximumFileBytes = 64 * 1024 * 1024
    static let maximumTotalBytes = 256 * 1024 * 1024

    static func validateSource(source: URL, currentIndex: URL) throws {
        let path = try localPath(source)
        let fd = try openPath(path)
        defer { close(fd) }
        try validateSource(fd: fd, path: path, currentIndex: currentIndex)
    }

    static func read(source: URL, currentIndex: URL, legacy: Bool = false) throws -> ShelfImportSnapshot {
        let path = try localPath(source)
        let fd = try openPath(path)
        defer { close(fd) }
        try validateSource(fd: fd, path: path, currentIndex: currentIndex)
        let bytes = try readFile(fd, path: path, limit: legacy ? ShelfImportSupport.maximumPropertyListBytes : ShelfImportSupport.maximumBytes)
        return ShelfImportSnapshot(sourceName: source.lastPathComponent, items: try ShelfImportSupport.decode(bytes, legacy: legacy))
    }

    private static func validateSource(fd: Int32, path: String, currentIndex: URL) throws {
        let currentPath = try localPath(currentIndex)
        guard path != currentPath else { throw ShelfImportAssetError.currentIndex }
        var sourceInfo = stat(), currentInfo = stat()
        guard fstat(fd, &sourceInfo) == 0, sourceInfo.st_mode & S_IFMT == S_IFREG else { throw ShelfImportAssetError.unreadableFile(path) }
        if stat(currentPath, &currentInfo) == 0 && sameIdentity(sourceInfo, currentInfo) {
            throw ShelfImportAssetError.currentIndex
        }
    }

    static func prepare(items: [ShelfPersistedItem], mappings: [ShelfImportMapping], destinationDirectory: URL) throws -> ShelfImportAssetSnapshot {
        _ = try ShelfImportSupport.decode(JSONEncoder().encode(items))
        let destination = URL(fileURLWithPath: try localPath(destinationDirectory)).appendingPathComponent("ShelfFiles")
        let roots = try mappings.map { try components($0.originalDirectory) }
        for i in roots.indices {
            for j in roots.indices where j < i {
                guard !roots[i].starts(with: roots[j]), !roots[j].starts(with: roots[i]) else { throw ShelfImportAssetError.mappingConflict }
            }
        }
        var directories: [Int32] = []
        defer { directories.forEach { close($0) } }
        for mapping in mappings {
            directories.append(try openPath(localPath(mapping.selectedDirectory), directory: true))
        }
        var files: [String: Data] = [:], copied: [String: (name: String, info: stat)] = [:], total = 0
        func prepareItem(_ input: ShelfPersistedItem) throws -> ShelfPersistedItem {
            var item = input
            if input.kind == .batch { item.children = try input.children?.map(prepareItem); return item }
            guard input.kind == .file, let original = input.path else { return item }
            let parts = try components(original)
            guard let index = roots.firstIndex(where: { parts.starts(with: $0) }) else { throw ShelfImportAssetError.unmappedFile(original) }
            let relative = Array(parts.dropFirst(roots[index].count))
            let mapping = mappings[index]
            let path = relative.reduce(mapping.selectedDirectory) { $0.appendingPathComponent($1) }.path
            let fd = try openRelative(relative, root: directories[index], path: path)
            defer { close(fd) }
            var before = stat()
            guard fstat(fd, &before) == 0 else { throw ShelfImportAssetError.unreadableFile(path) }
            if mapping.copyFiles {
                guard before.st_mode & S_IFMT == S_IFREG else { throw ShelfImportAssetError.unreadableFile(path) }
                let key = "\(before.st_dev):\(before.st_ino)"
                let name: String
                if let existing = copied[key] {
                    guard unchanged(existing.info, before) else { throw ShelfImportAssetError.changedFile(path) }
                    name = existing.name
                }
                else {
                    let data = try readFile(fd, path: path, limit: min(maximumFileBytes, maximumTotalBytes - total))
                    let ext = URL(fileURLWithPath: path).pathExtension
                    name = UUID().uuidString + (ext.isEmpty ? "" : "." + ext)
                    files[name] = data; copied[key] = (name, before); total += data.count
                }
                item.path = destination.appendingPathComponent(name).path
                item.bookmark = nil
            } else {
                guard [S_IFREG, S_IFDIR].contains(before.st_mode & S_IFMT) else { throw ShelfImportAssetError.unreadableFile(path) }
                item.path = path
                item.bookmark = try URL(fileURLWithPath: path).bookmarkData()
            }
            // Reopening the entire selected path detects directory and leaf replacement.
            let verification = try openPath(path)
            defer { close(verification) }
            var after = stat()
            guard fstat(verification, &after) == 0, unchanged(before, after) else { throw ShelfImportAssetError.changedFile(path) }
            return item
        }
        return ShelfImportAssetSnapshot(items: try items.map(prepareItem), files: files)
    }

    private static func components(_ path: String) throws -> [String] {
        let parts = path.split(separator: "/").map(String.init)
        guard path.hasPrefix("/"), !path.contains("\0"), !parts.contains(".."), !parts.contains(".") else { throw ShelfImportAssetError.invalidPath(path) }
        return parts
    }

    private static func localPath(_ url: URL) throws -> String {
        guard url.isFileURL, url.host == nil || url.host == "" || url.host?.lowercased() == "localhost" else { throw ShelfImportAssetError.invalidPath(url.absoluteString) }
        _ = try components(url.path)
        return url.path
    }

    private static func openPath(_ path: String, directory: Bool = false) throws -> Int32 {
        let root = open("/", O_RDONLY | O_DIRECTORY | O_CLOEXEC)
        guard root >= 0 else { throw ShelfImportAssetError.unreadableFile(path) }
        defer { close(root) }
        var parts = try components(path)
        // Foundation retains macOS's root aliases even after resolvingSymlinksInPath.
        if let alias = parts.first, ["var", "tmp", "etc"].contains(alias) {
            var info = stat()
            var target = [UInt8](repeating: 0, count: Int(MAXPATHLEN))
            if fstatat(root, alias, &info, AT_SYMLINK_NOFOLLOW) == 0,
               info.st_mode & S_IFMT == S_IFLNK, info.st_uid == 0 {
                let count = readlinkat(root, alias, &target, target.count)
                if count > 0 {
                    let value = String(decoding: target.prefix(count), as: UTF8.self)
                    if value == "private/" + alias || value == "/private/" + alias { parts.insert("private", at: 0) }
                }
            }
        }
        return try openRelative(parts, root: root, path: path, directory: directory)
    }

    private static func openRelative(_ parts: [String], root: Int32, path: String, directory: Bool = false) throws -> Int32 {
        var fd = dup(root)
        guard fd >= 0 else { throw ShelfImportAssetError.unreadableFile(path) }
        for (index, part) in parts.enumerated() {
            let flags = O_RDONLY | O_NOFOLLOW | O_CLOEXEC | O_NONBLOCK | ((index < parts.count - 1 || directory) ? O_DIRECTORY : 0)
            let next = openat(fd, part, flags)
            let code = errno
            close(fd)
            guard next >= 0 else {
                if code == ENOENT { throw ShelfImportAssetError.missingFile(path) }
                throw ShelfImportAssetError.unreadableFile(path)
            }
            fd = next
        }
        return fd
    }

    private static func readFile(_ fd: Int32, path: String, limit: Int) throws -> Data {
        var before = stat()
        guard fstat(fd, &before) == 0, before.st_mode & S_IFMT == S_IFREG, before.st_size >= 0 else { throw ShelfImportAssetError.unreadableFile(path) }
        guard before.st_size <= limit else { throw ShelfImportAssetError.tooLarge }
        var data = Data(), buffer = [UInt8](repeating: 0, count: 64 * 1024)
        while true {
            let count = Darwin.read(fd, &buffer, buffer.count)
            if count < 0 && errno == EINTR { continue }
            guard count >= 0 else { throw ShelfImportAssetError.unreadableFile(path) }
            if count == 0 { break }
            guard count <= limit - data.count else { throw ShelfImportAssetError.tooLarge }
            data.append(contentsOf: buffer.prefix(count))
        }
        var after = stat()
        guard fstat(fd, &after) == 0, unchanged(before, after), data.count == before.st_size else { throw ShelfImportAssetError.changedFile(path) }
        let verification = try openPath(path)
        defer { close(verification) }
        var atPath = stat()
        guard fstat(verification, &atPath) == 0, unchanged(before, atPath) else { throw ShelfImportAssetError.changedFile(path) }
        return data
    }

    private static func sameIdentity(_ a: stat, _ b: stat) -> Bool { a.st_dev == b.st_dev && a.st_ino == b.st_ino }
    private static func unchanged(_ a: stat, _ b: stat) -> Bool {
        sameIdentity(a, b) && a.st_mode == b.st_mode && a.st_size == b.st_size
            && a.st_mtimespec.tv_sec == b.st_mtimespec.tv_sec && a.st_mtimespec.tv_nsec == b.st_mtimespec.tv_nsec
            && a.st_ctimespec.tv_sec == b.st_ctimespec.tv_sec && a.st_ctimespec.tv_nsec == b.st_ctimespec.tv_nsec
    }
}
