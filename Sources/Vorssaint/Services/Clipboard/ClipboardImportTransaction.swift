// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation
import Darwin

final class ClipboardImportPrepared {
    let candidate: ClipboardImportCandidate
    let stagingURL: URL
    private(set) var cleanupFailed = false
    private(set) var committed = false
    fileprivate let destination: URL
    fileprivate let destinationFD: Int32
    fileprivate let stageFD: Int32
    fileprivate let stageName: String
    fileprivate var identities: [String: ClipboardImportTransaction.Identity] = [:]
    fileprivate var consumed = false

    fileprivate init(candidate: ClipboardImportCandidate, destination: URL, destinationFD: Int32,
                     stagingURL: URL, stageFD: Int32) {
        self.candidate = candidate
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
        NSLog("Clipboard import cleanup incomplete; owned staging retained for diagnosis.")
    }
    deinit { close(stageFD); close(destinationFD) }
}

enum ClipboardImportTransaction {
    fileprivate struct Identity: Equatable {
        let device: Int32
        let inode: UInt64
    }
    private static let jsonName = "ClipboardHistory.json"
    private static let imagesName = "ClipboardImages"

    static func prepare(_ candidate: ClipboardImportCandidate, in directory: URL) throws -> ClipboardImportPrepared {
        guard validDirectoryURL(directory), candidate.images.keys.allSatisfy(validImageName) else {
            throw ClipboardImportError.invalidDocument
        }
        let destination = directory.standardizedFileURL
        var existing = stat()
        if lstat(destination.path, &existing) == 0 {
            guard existing.st_mode & S_IFMT == S_IFDIR, existing.st_uid == getuid() else {
                throw ClipboardImportError.saveFailed
            }
        } else if errno != ENOENT { throw ClipboardImportError.saveFailed }
        // Only the requested container is tightened, never its ancestors.
        guard PrivateFileStore.createDirectory(at: destination, container: destination) else { throw ClipboardImportError.saveFailed }
        let parent = open(destination.path, O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC)
        guard parent >= 0 else { throw ClipboardImportError.saveFailed }
        let name = ".clipboard-import-" + UUID().uuidString
        guard mkdirat(parent, name, 0o700) == 0 else { close(parent); throw ClipboardImportError.saveFailed }
        let stage = openat(parent, name, O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC)
        guard stage >= 0 else { unlinkat(parent, name, AT_REMOVEDIR); close(parent); throw ClipboardImportError.saveFailed }
        let prepared = ClipboardImportPrepared(candidate: candidate, destination: destination, destinationFD: parent,
                                               stagingURL: destination.appendingPathComponent(name), stageFD: stage)
        do {
            guard ownedDirectory(parent), ownedDirectory(stage), fchmod(stage, 0o700) == 0,
                  bound(prepared, to: destination) else { throw ClipboardImportError.saveFailed }
            for (filename, data) in candidate.images.sorted(by: { $0.key < $1.key }) {
                try write(data, named: filename, into: prepared)
            }
            try write(candidate.json, named: jsonName, into: prepared)
            return prepared
        } catch {
            discard(prepared)
            throw ClipboardImportError.saveFailed
        }
    }

    static func commit(_ prepared: ClipboardImportPrepared, to directory: URL) throws {
        guard !prepared.consumed, bound(prepared, to: directory),
              stageMatches(prepared) else { throw ClipboardImportError.saveFailed }
        prepared.consumed = true
        let parent = prepared.destinationFD
        if mkdirat(parent, imagesName, 0o700) != 0 && errno != EEXIST {
            cleanup(prepared); throw ClipboardImportError.saveFailed
        }
        let images = openat(parent, imagesName, O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC)
        guard images >= 0 else { cleanup(prepared); throw ClipboardImportError.saveFailed }
        defer { close(images) }
        var installed: [String] = []
        do {
            guard ownedDirectory(images) else { throw ClipboardImportError.saveFailed }
            for name in prepared.candidate.images.keys.sorted() {
                guard regularIdentity(at: prepared.stageFD, name: name) == prepared.identities[name],
                      renameatx_np(prepared.stageFD, name, images, name, UInt32(RENAME_EXCL)) == 0 else {
                    throw ClipboardImportError.saveFailed
                }
                installed.append(name)
            }
            // Revalidate paths before the single commit point. No source file is removed.
            guard bound(prepared, to: directory),
                  directoryIdentity(at: parent, name: imagesName) == identity(images),
                  regularIdentity(at: prepared.stageFD, name: jsonName) == prepared.identities[jsonName],
                  renameat(prepared.stageFD, jsonName, parent, jsonName) == 0 else {
                throw ClipboardImportError.saveFailed
            }
            prepared.markCommitted()
            cleanup(prepared)
        } catch {
            var rolledBack = true
            for name in installed.reversed() {
                // A replacement by another actor is never ours to delete.
                guard regularIdentity(at: images, name: name) == prepared.identities[name] else {
                    rolledBack = false; continue
                }
                if unlinkat(images, name, 0) != 0 { rolledBack = false }
            }
            if rolledBack { cleanup(prepared) } else { prepared.markCleanupFailed() }
            throw ClipboardImportError.saveFailed
        }
    }

    static func discard(_ prepared: ClipboardImportPrepared) {
        guard !prepared.committed, !prepared.cleanupFailed else { return }
        prepared.consumed = true
        cleanup(prepared)
    }

    private static func write(_ data: Data, named name: String, into prepared: ClipboardImportPrepared) throws {
        guard bound(prepared, to: prepared.destination), stageMatches(prepared),
              PrivateFileStore.write(data, to: prepared.stagingURL.appendingPathComponent(name)),
              let value = regularIdentity(at: prepared.stageFD, name: name) else { throw ClipboardImportError.saveFailed }
        let fd = openat(prepared.stageFD, name, O_RDONLY | O_NOFOLLOW | O_CLOEXEC)
        guard fd >= 0 else { throw ClipboardImportError.saveFailed }
        defer { close(fd) }
        guard fchmod(fd, 0o600) == 0 else { throw ClipboardImportError.saveFailed }
        prepared.identities[name] = value
    }

    private static func cleanup(_ prepared: ClipboardImportPrepared) {
        // Delete known stage files only, using the held directory descriptor.
        for name in prepared.candidate.images.keys.sorted() + [jsonName] {
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

    private static func validImageName(_ name: String) -> Bool {
        guard name.hasSuffix(".png") else { return false }
        return UUID(uuidString: String(name.dropLast(4))) != nil
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
    private static func stageMatches(_ prepared: ClipboardImportPrepared) -> Bool {
        directoryIdentity(at: prepared.destinationFD, name: prepared.stageName) == identity(prepared.stageFD)
    }
    private static func bound(_ prepared: ClipboardImportPrepared, to directory: URL) -> Bool {
        guard validDirectoryURL(directory), directory.standardizedFileURL.path == prepared.destination.path else { return false }
        let fd = open(directory.path, O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC)
        guard fd >= 0 else { return false }
        defer { close(fd) }
        return identity(fd) == identity(prepared.destinationFD)
    }
}
