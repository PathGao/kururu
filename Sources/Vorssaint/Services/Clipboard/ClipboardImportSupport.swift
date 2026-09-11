// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation
import Darwin
import CryptoKit
import ImageIO
import UniformTypeIdentifiers

struct ClipboardImportSnapshot {
    let sourceName: String
    let entries: [ClipboardHistoryEntry]
    let images: [String: Data]
}
struct ClipboardImportCandidate {
    let entries: [ClipboardHistoryEntry]
    let images: [String: Data]
    let json: Data
}
enum ClipboardImportError: Error, Equatable {
    case invalidDocument, unreadable, tooLarge, missingImage, capacityExceeded
    case emptySelection, sameDestination, saveFailed, changed, unavailable, imageDirectoryRequired
}

enum ClipboardImportSupport {
    static let maximumPropertyListBytes = 160 * 1024 * 1024
    static let maximumImageBytes = 16 * 1024 * 1024
    static let maximumTotalImageBytes = 256 * 1024 * 1024
    // Import inspects metadata only; bound potential decoded RGBA storage too.
    static let maximumImagePixels = 64 * 1024 * 1024

    static func validateSource(_ url: URL, destination: URL) throws {
        try validateURL(url)
        try validateURL(destination)
        guard url.standardizedFileURL.resolvingSymlinksInPath().path != destination.standardizedFileURL.resolvingSymlinksInPath().path else {
            throw ClipboardImportError.sameDestination
        }
        var sourceInfo = stat(), targetInfo = stat()
        if stat(url.path, &sourceInfo) == 0, stat(destination.path, &targetInfo) == 0,
           sourceInfo.st_dev == targetInfo.st_dev, sourceInfo.st_ino == targetInfo.st_ino {
            throw ClipboardImportError.sameDestination
        }
    }

    private static func validateURL(_ url: URL) throws {
        guard url.isFileURL, url.host == nil || url.host == "" || url.host?.lowercased() == "localhost",
              !url.path.contains("\0"), !url.absoluteString.lowercased().contains("%00") else {
            throw ClipboardImportError.unreadable
        }
    }

    private static func readData(_ url: URL, limit: Int, parentFD: Int32? = nil) throws -> Data {
        try validateURL(url)
        let flags = O_RDONLY | O_NOFOLLOW | O_NONBLOCK | O_CLOEXEC
        let fd = parentFD.map { openat($0, url.lastPathComponent, flags) } ?? open(url.path, flags)
        guard fd >= 0 else { throw ClipboardImportError.unreadable }
        let file = FileHandle(fileDescriptor: fd, closeOnDealloc: true)
        defer { try? file.close() }
        var before = stat()
        guard fstat(fd, &before) == 0, before.st_mode & S_IFMT == S_IFREG else { throw ClipboardImportError.unreadable }
        guard before.st_size >= 0, before.st_size <= limit else { throw ClipboardImportError.tooLarge }
        var data = Data()
        do {
            while data.count <= limit {
                guard let part = try file.read(upToCount: min(65536, limit + 1 - data.count)), !part.isEmpty else { break }
                data.append(part)
            }
        } catch { throw ClipboardImportError.unreadable }
        guard data.count <= limit else { throw ClipboardImportError.tooLarge }
        var after = stat(), pathInfo = stat()
        let pathStatus = parentFD.map { fstatat($0, url.lastPathComponent, &pathInfo, AT_SYMLINK_NOFOLLOW) }
            ?? lstat(url.path, &pathInfo)
        guard fstat(fd, &after) == 0, pathStatus == 0,
              pathInfo.st_dev == before.st_dev, pathInfo.st_ino == before.st_ino,
              pathInfo.st_mode & S_IFMT == S_IFREG,
              after.st_size == before.st_size, data.count == before.st_size,
              after.st_mtimespec.tv_sec == before.st_mtimespec.tv_sec,
              after.st_mtimespec.tv_nsec == before.st_mtimespec.tv_nsec,
              after.st_ctimespec.tv_sec == before.st_ctimespec.tv_sec,
              after.st_ctimespec.tv_nsec == before.st_ctimespec.tv_nsec else { throw ClipboardImportError.changed }
        return data
    }

    static func read(_ url: URL, imageDirectory: URL? = nil) throws -> ClipboardImportSnapshot {
        let legacy = url.pathExtension.lowercased() == "plist"
        let source = try readData(url, limit: legacy ? maximumPropertyListBytes : ClipboardHistoryEditing.maxEncodedHistoryBytes)
        let data: Data
        if legacy {
            do {
                guard let dictionary = try PropertyListSerialization.propertyList(from: source, options: [], format: nil) as? [String: Any],
                      let clipboard = dictionary["clipboardHistoryEntries"] as? Data else { throw ClipboardImportError.invalidDocument }
                data = clipboard
            } catch { throw ClipboardImportError.invalidDocument }
        } else { data = source }
        let entries = try decode(data, legacy: legacy)
        if let imageDirectory { try validateURL(imageDirectory) }
        if legacy && entries.contains(where: { $0.kind == .image }) && imageDirectory == nil {
            throw ClipboardImportError.imageDirectoryRequired
        }
        var images: [String: Data] = [:]
        var total = 0
        for entry in entries where entry.kind == .image {
            guard let name = entry.imageFile else { throw ClipboardImportError.invalidDocument }
            if let image = images[name] { try validateImage(image, entry: entry); continue }
            let directory = imageDirectory ?? url.deletingLastPathComponent().appendingPathComponent("ClipboardImages", isDirectory: true)
            let directoryFD = open(directory.path, O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC)
            guard directoryFD >= 0 else { throw ClipboardImportError.missingImage }
            defer { close(directoryFD) }
            let imageURL = directory.appendingPathComponent(name)
            let image: Data
            do { image = try readData(imageURL, limit: maximumImageBytes, parentFD: directoryFD) }
            catch ClipboardImportError.unreadable { throw ClipboardImportError.missingImage }
            total += image.count
            guard total <= maximumTotalImageBytes else { throw ClipboardImportError.tooLarge }
            try validateImage(image, entry: entry)
            images[name] = image
        }
        return ClipboardImportSnapshot(sourceName: url.lastPathComponent, entries: entries, images: images)
    }

    private static func decode(_ data: Data, legacy: Bool = false) throws -> [ClipboardHistoryEntry] {
        guard data.count <= ClipboardHistoryEditing.maxEncodedHistoryBytes else { throw ClipboardImportError.tooLarge }
        do {
            guard var rows = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] else { throw ClipboardImportError.invalidDocument }
            // The old preference decoder generated absent IDs and defaulted kind to text.
            // Materialize IDs once in the preview snapshot; dates remain required.
            if legacy {
                for index in rows.indices where rows[index]["id"] == nil { rows[index]["id"] = UUID().uuidString }
            }
            let required: Set<String> = ["id", "text", "copiedAt"]
            let allowed = required.union(["pinnedAt", "kind", "filePaths", "imageFile", "imageHash", "imageWidth", "imageHeight"])
            guard rows.allSatisfy({ required.isSubset(of: Set($0.keys)) && Set($0.keys).isSubset(of: allowed)
                && $0["id"] is String && $0["copiedAt"] is NSNumber
                && ($0["kind"] == nil || $0["kind"] is String) }) else { throw ClipboardImportError.invalidDocument }
            let normalized = legacy ? try JSONSerialization.data(withJSONObject: rows) : data
            let entries = try JSONDecoder().decode([ClipboardHistoryEntry].self, from: normalized)
            try validate(entries)
            return entries
        } catch let error as ClipboardImportError { throw error }
        catch { throw ClipboardImportError.invalidDocument }
    }

    private static func validate(_ entries: [ClipboardHistoryEntry]) throws {
        guard Set(entries.map(\.id)).count == entries.count else { throw ClipboardImportError.invalidDocument }
        for entry in entries {
            guard entry.copiedAt.timeIntervalSinceReferenceDate.isFinite,
                  entry.pinnedAt?.timeIntervalSinceReferenceDate.isFinite ?? true else { throw ClipboardImportError.invalidDocument }
            switch entry.kind {
            case .text:
                guard ClipboardHistoryEditing.storableText(entry.text) != nil, entry.filePaths.isEmpty,
                      entry.imageFile == nil, entry.imageHash == nil, entry.imageWidth == nil, entry.imageHeight == nil else { throw ClipboardImportError.invalidDocument }
            case .files:
                guard entry.text.isEmpty, !entry.filePaths.isEmpty, entry.filePaths.count <= 100,
                      entry.filePaths.allSatisfy({ $0.hasPrefix("/") && !$0.contains("\0") }),
                      entry.imageFile == nil, entry.imageHash == nil, entry.imageWidth == nil, entry.imageHeight == nil else { throw ClipboardImportError.invalidDocument }
            case .image:
                guard entry.text.isEmpty, entry.filePaths.isEmpty,
                      let name = entry.imageFile, !name.isEmpty, name != ".", name != "..",
                      (name as NSString).lastPathComponent == name, !name.contains("/"), !name.contains("\\"), !name.contains("\0"),
                      let hash = entry.imageHash, hash.count == 64, hash.allSatisfy({ $0.isASCII && $0.isHexDigit }),
                      let width = entry.imageWidth, let height = entry.imageHeight,
                      width > 0, height > 0, width <= maximumImagePixels / height else { throw ClipboardImportError.invalidDocument }
            }
        }
    }

    private static func validateImage(_ data: Data, entry: ClipboardHistoryEntry) throws {
        guard data.count <= maximumImageBytes else { throw ClipboardImportError.tooLarge }
        guard let source = CGImageSourceCreateWithData(data as CFData, [kCGImageSourceShouldCache: false] as CFDictionary),
              CGImageSourceGetType(source) as String? == UTType.png.identifier,
              CGImageSourceGetCount(source) == 1,
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
              let width = (properties[kCGImagePropertyPixelWidth] as? NSNumber)?.intValue,
              let height = (properties[kCGImagePropertyPixelHeight] as? NSNumber)?.intValue,
              width > 0, height > 0, width <= maximumImagePixels / height,
              width == entry.imageWidth, height == entry.imageHeight,
              SHA256.hash(data: data).map({ String(format: "%02x", $0) }).joined() == entry.imageHash?.lowercased() else {
            throw ClipboardImportError.invalidDocument
        }
    }

    static func prepare(selected: [ClipboardHistoryEntry], images: [String: Data],
                        current: [ClipboardHistoryEntry], recentLimit: Int) throws -> ClipboardImportCandidate {
        guard !selected.isEmpty else { throw ClipboardImportError.emptySelection }
        try validate(selected)
        do { try validate(current) }
        catch { throw ClipboardImportError.unavailable }
        var usedIDs = Set(current.map(\.id)); usedIDs.formUnion(selected.map(\.id))
        var usedNames = Set(current.compactMap(\.imageFile)); usedNames.formUnion(images.keys)
        var copiedImages: [String: Data] = [:]
        var total = 0
        let copies = try selected.map { item -> ClipboardHistoryEntry in
            var id = UUID()
            while !usedIDs.insert(id).inserted { id = UUID() }
            var name: String?
            if item.kind == .image {
                guard let originalName = item.imageFile, let data = images[originalName] else { throw ClipboardImportError.missingImage }
                try validateImage(data, entry: item)
                total += data.count
                guard total <= maximumTotalImageBytes else { throw ClipboardImportError.tooLarge }
                var newName = UUID().uuidString + ".png"
                while !usedNames.insert(newName).inserted { newName = UUID().uuidString + ".png" }
                name = newName
                copiedImages[newName] = data
            }
            return ClipboardHistoryEntry(id: id, text: item.text, copiedAt: item.copiedAt, pinnedAt: item.pinnedAt,
                kind: item.kind, filePaths: item.filePaths, imageFile: name, imageHash: item.imageHash,
                imageWidth: item.imageWidth, imageHeight: item.imageHeight)
        }
        let all = current.filter(\.isPinned) + copies.filter(\.isPinned)
            + current.filter { !$0.isPinned } + copies.filter { !$0.isPinned }
        guard ClipboardHistoryEditing.retainedEntries(all, recentLimit: recentLimit) == all,
              let encoded = ClipboardHistoryEditing.encodedHistory(all), encoded.entries == all else { throw ClipboardImportError.capacityExceeded }
        return ClipboardImportCandidate(entries: all, images: copiedImages, json: encoded.data)
    }
}
