// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation
import Darwin

final class ShelfImportPrepared {
    let items: [ShelfPersistedItem]
    let files: [String: Data]
    let stagingURL: URL
    private(set) var cleanupFailed = false
    private(set) var committed = false
    fileprivate let destination: URL
    fileprivate let destinationFD: Int32
    fileprivate let stageFD: Int32
    fileprivate let stageName: String
    fileprivate var identities: [String: ShelfImportTransaction.Identity] = [:]
    fileprivate var consumed = false

    fileprivate init(items: [ShelfPersistedItem], files: [String: Data], destination: URL, destinationFD: Int32,
                     stagingURL: URL, stageFD: Int32) {
        self.items = items
        self.files = files
        self.destination = destination
        self.destinationFD = destinationFD
        self.stagingURL = stagingURL
        self.stageName = stagingURL.lastPathComponent
        self.stageFD = stageFD
    }
    fileprivate func markCommitted() { committed = true }
    fileprivate func markCleanupFailed() {
        guard !cleanupFailed else { return }
        cleanupFailed = true
        NSLog("Shelf import cleanup incomplete; owned staging retained for diagnosis.")
    }
    deinit { close(stageFD); close(destinationFD) }
}

enum ShelfImportTransactionError: Error, Equatable { case invalidDocument, saveFailed, tooLarge }

enum ShelfImportTransaction {
    fileprivate struct Identity: Equatable {
        let device: Int32
        let inode: UInt64
    }
    private static let jsonName = "ShelfItems.json"
    private static let filesName = "ShelfFiles"

    static func prepare(items: [ShelfPersistedItem], files: [String: Data], in directory: URL) throws -> ShelfImportPrepared {
        guard validDirectoryURL(directory), files.keys.allSatisfy(validFileName) else {
            throw ShelfImportTransactionError.invalidDocument
        }
        let destination = directory.standardizedFileURL
        let targets = referencedPaths(items)
        guard files.keys.allSatisfy({ targets.contains(destination.appendingPathComponent(filesName).appendingPathComponent($0).path) }) else { throw ShelfImportTransactionError.invalidDocument }
        let json = try JSONEncoder().encode(items)
        guard json.count <= ShelfIndexStore.maximumBytes else { throw ShelfImportTransactionError.tooLarge }
        var existing = stat()
        if lstat(destination.path, &existing) == 0 {
            guard existing.st_mode & S_IFMT == S_IFDIR, existing.st_uid == getuid() else {
                throw ShelfImportTransactionError.saveFailed
            }
        } else if errno != ENOENT { throw ShelfImportTransactionError.saveFailed }
        // Only the requested container is tightened, never its ancestors.
        guard PrivateFileStore.createDirectory(at: destination, container: destination) else { throw ShelfImportTransactionError.saveFailed }
        let parent = open(destination.path, O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC)
        guard parent >= 0 else { throw ShelfImportTransactionError.saveFailed }
        let name = ".shelf-import-" + UUID().uuidString
        guard mkdirat(parent, name, 0o700) == 0 else { close(parent); throw ShelfImportTransactionError.saveFailed }
        let stage = openat(parent, name, O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC)
        guard stage >= 0 else { unlinkat(parent, name, AT_REMOVEDIR); close(parent); throw ShelfImportTransactionError.saveFailed }
        let prepared = ShelfImportPrepared(items: items, files: files, destination: destination, destinationFD: parent,
                                               stagingURL: destination.appendingPathComponent(name), stageFD: stage)
        do {
            guard ownedDirectory(parent), ownedDirectory(stage), fchmod(stage, 0o700) == 0,
                  bound(prepared, to: destination) else { throw ShelfImportTransactionError.saveFailed }
            for (filename, data) in prepared.files.sorted(by: { $0.key < $1.key }) {
                try write(data, named: filename, into: prepared)
            }
            try write(json, named: jsonName, into: prepared)
            return prepared
        } catch {
            discard(prepared)
            throw ShelfImportTransactionError.saveFailed
        }
    }

    static func commit(_ prepared: ShelfImportPrepared, to directory: URL) throws {
        guard !prepared.consumed, bound(prepared, to: directory),
              stageMatches(prepared) else { throw ShelfImportTransactionError.saveFailed }
        prepared.consumed = true
        let parent = prepared.destinationFD
        if mkdirat(parent, filesName, 0o700) != 0 && errno != EEXIST {
            cleanup(prepared); throw ShelfImportTransactionError.saveFailed
        }
        let filesFD = openat(parent, filesName, O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC)
        guard filesFD >= 0 else { cleanup(prepared); throw ShelfImportTransactionError.saveFailed }
        defer { close(filesFD) }
        var installed: [String] = []
        do {
            guard ownedDirectory(filesFD), fchmod(filesFD, 0o700) == 0 else { throw ShelfImportTransactionError.saveFailed }
            for name in prepared.files.keys.sorted() {
                guard regularIdentity(at: prepared.stageFD, name: name) == prepared.identities[name],
                      renameatx_np(prepared.stageFD, name, filesFD, name, UInt32(RENAME_EXCL)) == 0 else {
                    throw ShelfImportTransactionError.saveFailed
                }
                installed.append(name)
            }
            // Revalidate paths before the single commit point. The source is never touched.
            guard bound(prepared, to: directory),
                  directoryIdentity(at: parent, name: filesName) == identity(filesFD),
                  regularIdentity(at: prepared.stageFD, name: jsonName) == prepared.identities[jsonName],
                  validIndex(at: parent),
                  renameat(prepared.stageFD, jsonName, parent, jsonName) == 0 else {
                throw ShelfImportTransactionError.saveFailed
            }
            prepared.markCommitted()
            cleanup(prepared)
        } catch {
            var rolledBack = true
            for name in installed.reversed() {
                // A replacement by another actor is never ours to delete.
                guard regularIdentity(at: filesFD, name: name) == prepared.identities[name] else {
                    rolledBack = false; continue
                }
                if unlinkat(filesFD, name, 0) != 0 { rolledBack = false }
            }
            if rolledBack { cleanup(prepared) } else { prepared.markCleanupFailed() }
            throw ShelfImportTransactionError.saveFailed
        }
    }

    static func discard(_ prepared: ShelfImportPrepared) {
        guard !prepared.committed, !prepared.cleanupFailed else { return }
        prepared.consumed = true
        cleanup(prepared)
    }

    private static func write(_ data: Data, named name: String, into prepared: ShelfImportPrepared) throws {
        guard bound(prepared, to: prepared.destination), stageMatches(prepared) else { throw ShelfImportTransactionError.saveFailed }
        let fd = openat(prepared.stageFD, name, O_WRONLY | O_CREAT | O_EXCL | O_NOFOLLOW | O_CLOEXEC, 0o600)
        guard fd >= 0 else { throw ShelfImportTransactionError.saveFailed }
        defer { close(fd) }
        guard let value = regularIdentity(at: prepared.stageFD, name: name), identity(fd) == value else { throw ShelfImportTransactionError.saveFailed }
        prepared.identities[name] = value
        guard fchmod(fd, 0o600) == 0 else { throw ShelfImportTransactionError.saveFailed }
        try data.withUnsafeBytes { buffer in
            var offset = 0
            while offset < buffer.count {
                let written = Darwin.write(fd, buffer.baseAddress!.advanced(by: offset), buffer.count - offset)
                if written < 0 && errno == EINTR { continue }
                guard written > 0 else { throw ShelfImportTransactionError.saveFailed }
                offset += written
            }
        }
    }

    private static func cleanup(_ prepared: ShelfImportPrepared) {
        // Delete known stage files only, using the held directory descriptor.
        for name in prepared.files.keys.sorted() + [jsonName] {
            var info = stat()
            if fstatat(prepared.stageFD, name, &info, AT_SYMLINK_NOFOLLOW) != 0 {
                if errno != ENOENT { prepared.markCleanupFailed() }
                continue
            }
            guard regularIdentity(at: prepared.stageFD, name: name) == prepared.identities[name] else {
                prepared.markCleanupFailed(); continue
            }
            if unlinkat(prepared.stageFD, name, 0) != 0 { prepared.markCleanupFailed() }
        }
        guard stageMatches(prepared) else {
            var info = stat()
            if fstatat(prepared.destinationFD, prepared.stageName, &info, AT_SYMLINK_NOFOLLOW) != 0 && errno == ENOENT { return }
            prepared.markCleanupFailed(); return
        }
        if unlinkat(prepared.destinationFD, prepared.stageName, AT_REMOVEDIR) != 0 && errno != ENOENT {
            prepared.markCleanupFailed()
        }
    }

    private static func validFileName(_ name: String) -> Bool {
        let parts = name.split(separator: ".", omittingEmptySubsequences: false)
        guard name.utf8.count <= 255, !parts.isEmpty, parts.count <= 2,
              UUID(uuidString: String(parts[0])) != nil else { return false }
        return parts.count == 1 || !parts[1].isEmpty
            && !parts[1].contains(where: { $0 == "/" || $0 == "\\" || $0 == "\0" })
    }

    private static func referencedPaths(_ items: [ShelfPersistedItem]) -> Set<String> {
        Set(items.compactMap(\.path)).union(items.reduce(into: Set<String>()) { $0.formUnion(referencedPaths($1.children ?? [])) })
    }
    private static func validIndex(at parent: Int32) -> Bool {
        var value = stat()
        if fstatat(parent, jsonName, &value, AT_SYMLINK_NOFOLLOW) != 0 { return errno == ENOENT }
        return value.st_mode & S_IFMT == S_IFREG && value.st_uid == getuid()
    }
    private static func validDirectoryURL(_ url: URL) -> Bool {
        url.isFileURL && (url.host == nil || url.host == "" || url.host?.lowercased() == "localhost")
            && !url.path.contains("\0") && !url.absoluteString.lowercased().contains("%00")
    }
    private static func identity(_ fd: Int32) -> Identity? {
        var value = stat()
        guard fstat(fd, &value) == 0 else { return nil }
        return Identity(device: value.st_dev, inode: value.st_ino)
    }
    private static func ownedDirectory(_ fd: Int32) -> Bool {
        var value = stat()
        return fstat(fd, &value) == 0 && value.st_mode & S_IFMT == S_IFDIR && value.st_uid == getuid()
    }
    private static func directoryIdentity(at fd: Int32, name: String) -> Identity? {
        var value = stat()
        guard fstatat(fd, name, &value, AT_SYMLINK_NOFOLLOW) == 0,
              value.st_mode & S_IFMT == S_IFDIR else { return nil }
        return Identity(device: value.st_dev, inode: value.st_ino)
    }
    private static func regularIdentity(at fd: Int32, name: String) -> Identity? {
        var value = stat()
        guard fstatat(fd, name, &value, AT_SYMLINK_NOFOLLOW) == 0,
              value.st_mode & S_IFMT == S_IFREG, value.st_uid == getuid() else { return nil }
        return Identity(device: value.st_dev, inode: value.st_ino)
    }
    private static func stageMatches(_ prepared: ShelfImportPrepared) -> Bool {
        directoryIdentity(at: prepared.destinationFD, name: prepared.stageName) == identity(prepared.stageFD)
    }
    private static func bound(_ prepared: ShelfImportPrepared, to directory: URL) -> Bool {
        guard validDirectoryURL(directory), directory.standardizedFileURL.path == prepared.destination.path else { return false }
        let fd = open(directory.path, O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC)
        guard fd >= 0 else { return false }
        defer { close(fd) }
        return identity(fd) == identity(prepared.destinationFD)
    }
}
