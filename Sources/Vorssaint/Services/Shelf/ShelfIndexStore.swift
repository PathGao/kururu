// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation
import Darwin

enum ShelfIndexSource { case json, legacy, empty }
struct ShelfIndexLoad {
    let store: ShelfStoreLoad
    let source: ShelfIndexSource
    let canWrite: Bool
}
enum ShelfIndexError: Error, Equatable { case unreadable, tooLarge, saveFailed }
final class ShelfIndexStore {
    // Explicit encoded-byte budget; grapheme-count limits do not bound UTF-8 bytes.
    static let maximumBytes = 256 * 1024 * 1024
    let directory: URL
    private let legacyDefaults: UserDefaults
    private var canWrite = false
    private var indexURL: URL { directory.appendingPathComponent("ShelfItems.json") }
    init(directory: URL, legacyDefaults: UserDefaults) { self.directory = directory; self.legacyDefaults = legacyDefaults }
    // Confined to the owning service's persistence queue.
    func load() -> ShelfIndexLoad {
        canWrite = false
        guard directory.isFileURL, directory.host == nil || directory.host == "" || directory.host == "localhost",
              !directory.path.contains("\0") else { return result(.unreadable, source: .json) }
        let fd = open(indexURL.path, O_RDONLY | O_NOFOLLOW | O_NONBLOCK | O_CLOEXEC)
        if fd < 0 {
            guard errno == ENOENT else { return result(.unreadable, source: .json) }
            guard let value = legacyDefaults.object(forKey: "shelfItems") else { return result(.items([]), source: .empty) }
            guard let data = value as? Data, data.count <= Self.maximumBytes else { return result(.unreadable, source: .legacy) }
            return result(ShelfPersistenceSupport.load(data), source: .legacy)
        }
        let file = FileHandle(fileDescriptor: fd, closeOnDealloc: true)
        defer { try? file.close() }
        var before = stat()
        guard fstat(fd, &before) == 0, before.st_mode & S_IFMT == S_IFREG,
              before.st_size >= 0, before.st_size <= Self.maximumBytes else { return result(.unreadable, source: .json) }
        var data = Data()
        do {
            while data.count <= Self.maximumBytes {
                guard let chunk = try file.read(upToCount: min(65536, Self.maximumBytes + 1 - data.count)), !chunk.isEmpty else { break }
                data.append(chunk)
            }
        } catch { return result(.unreadable, source: .json) }
        var after = stat(), path = stat()
        guard data.count <= Self.maximumBytes, fstat(fd, &after) == 0,
              lstat(indexURL.path, &path) == 0, path.st_ino == before.st_ino, path.st_dev == before.st_dev,
              data.count == before.st_size, after.st_size == before.st_size,
              after.st_mtimespec.tv_sec == before.st_mtimespec.tv_sec,
              after.st_mtimespec.tv_nsec == before.st_mtimespec.tv_nsec,
              after.st_ctimespec.tv_sec == before.st_ctimespec.tv_sec,
              after.st_ctimespec.tv_nsec == before.st_ctimespec.tv_nsec else { return result(.unreadable, source: .json) }
        return result(ShelfPersistenceSupport.load(data), source: .json)
    }

    private func result(_ store: ShelfStoreLoad, source: ShelfIndexSource) -> ShelfIndexLoad {
        if case .items = store { canWrite = true }
        return ShelfIndexLoad(store: store, source: source, canWrite: canWrite)
    }

    func save(_ items: [ShelfPersistedItem]) -> Result<Void, ShelfIndexError> {
        guard canWrite else { return .failure(.unreadable) }
        guard let data = try? JSONEncoder().encode(items) else { return .failure(.saveFailed) }
        guard data.count <= Self.maximumBytes else { return .failure(.tooLarge) }
        var info = stat()
        let status = lstat(indexURL.path, &info)
        guard (status == 0 && info.st_mode & S_IFMT == S_IFREG) || (status < 0 && errno == ENOENT),
              PrivateFileStore.createDirectory(at: directory, container: directory),
              PrivateFileStore.write(data, to: indexURL) else { return .failure(.saveFailed) }
        legacyDefaults.removeObject(forKey: "shelfItems")
        return .success(())
    }

    // Called on the persistence queue only after the import's atomic commit.
    func didCommitImportedStore() {
        legacyDefaults.removeObject(forKey: "shelfItems")
    }
}
