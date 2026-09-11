// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint
import Foundation
import Darwin

struct ScratchpadImportSnapshot: Equatable {
    let sourceName: String
    let pads: [ScratchpadPad]
}

enum ScratchpadImportError: Error, Equatable {
    case unsupportedFile, unreadable, tooLarge, invalidUTF8, invalidDocument, invalidSelection, capacityExceeded, sameDestination
}

enum ScratchpadImportSupport {
    static func validateSource(_ source: URL, destination: URL) throws {
        try validateLocalURL(source)
        try validateLocalURL(destination)
        guard source.standardizedFileURL.resolvingSymlinksInPath().path
                != destination.standardizedFileURL.resolvingSymlinksInPath().path else {
            throw ScratchpadImportError.sameDestination
        }
        // The same inode is the current document even through a case alias
        // or hard link. Import accepts a different source, not an alias of itself.
        var sourceInfo = stat()
        var destinationInfo = stat()
        if stat(source.path, &sourceInfo) == 0, stat(destination.path, &destinationInfo) == 0,
           sourceInfo.st_dev == destinationInfo.st_dev, sourceInfo.st_ino == destinationInfo.st_ino {
            throw ScratchpadImportError.sameDestination
        }
    }

    private static func validateLocalURL(_ url: URL) throws {
        guard url.isFileURL,
              url.host == nil || url.host == "" || url.host?.lowercased() == "localhost",
              !url.path.contains("\0"),
              !url.absoluteString.lowercased().contains("%00") else {
            throw ScratchpadImportError.unsupportedFile
        }
    }

    static let maximumBytes = 8 * 1024 * 1024

    /// Opens only a regular file and reads at most the limit plus one byte.
    /// NOFOLLOW refuses a final symlink; NONBLOCK prevents FIFOs from waiting.
    static func read(_ url: URL) throws -> ScratchpadImportSnapshot {
        try decode(readData(url), fileName: url.lastPathComponent)
    }

    static func readData(_ url: URL) throws -> Data {
        try validateLocalURL(url)
        let fd = open(url.path, O_RDONLY | O_NOFOLLOW | O_NONBLOCK | O_CLOEXEC)
        guard fd >= 0 else { throw ScratchpadImportError.unreadable }
        let handle = FileHandle(fileDescriptor: fd, closeOnDealloc: true)
        defer { try? handle.close() }
        var info = stat()
        guard fstat(fd, &info) == 0, (info.st_mode & S_IFMT) == S_IFREG else { throw ScratchpadImportError.unreadable }
        guard info.st_size >= 0, info.st_size <= maximumBytes else { throw ScratchpadImportError.tooLarge }
        var data = Data()
        do {
            while data.count <= maximumBytes {
                let amount = min(64 * 1024, maximumBytes + 1 - data.count)
                guard let part = try handle.read(upToCount: amount), !part.isEmpty else { break }
                data.append(part)
            }
        } catch { throw ScratchpadImportError.unreadable }
        guard data.count <= maximumBytes else { throw ScratchpadImportError.tooLarge }
        var after = stat()
        guard fstat(fd, &after) == 0,
              after.st_size == info.st_size, data.count == info.st_size,
              after.st_mtimespec.tv_sec == info.st_mtimespec.tv_sec,
              after.st_mtimespec.tv_nsec == info.st_mtimespec.tv_nsec,
              after.st_ctimespec.tv_sec == info.st_ctimespec.tv_sec,
              after.st_ctimespec.tv_nsec == info.st_ctimespec.tv_nsec else {
            throw ScratchpadImportError.unreadable
        }
        return data
    }

    static func decode(_ data: Data, fileName: String) throws -> ScratchpadImportSnapshot {
        guard data.count <= maximumBytes else { throw ScratchpadImportError.tooLarge }
        let name = (fileName as NSString).lastPathComponent
        switch (name as NSString).pathExtension.lowercased() {
        case "json": return ScratchpadImportSnapshot(sourceName: name, pads: try decodeDocument(data).pads)
        case "txt":
            guard let text = String(data: data, encoding: .utf8) else { throw ScratchpadImportError.invalidUTF8 }
            let proposed = ScratchpadSupport.sanitizedPadName((name as NSString).deletingPathExtension)
            let pad = ScratchpadPad(id: UUID(), name: proposed.isEmpty ? "Imported note" : proposed,
                                    text: text, modifiedAt: nil)
            return ScratchpadImportSnapshot(sourceName: name, pads: [pad])
        default: throw ScratchpadImportError.unsupportedFile
        }
    }

    /// Import never sanitizes away unknown fields, duplicate pads or bad selection.
    static func decodeDocument(_ data: Data) throws -> ScratchpadDocument {
        guard data.count <= maximumBytes else { throw ScratchpadImportError.tooLarge }
        do {
            guard let object = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  Set(object.keys) == ["pads", "selectedID"],
                  let pads = object["pads"] as? [[String: Any]],
                  (1...ScratchpadDocument.maximumPadCount).contains(pads.count) else { throw ScratchpadImportError.invalidDocument }
            let required: Set<String> = ["id", "name", "text"]
            let allowed = required.union(["modifiedAt"])
            guard pads.allSatisfy({ required.isSubset(of: Set($0.keys)) && Set($0.keys).isSubset(of: allowed) }) else {
                throw ScratchpadImportError.invalidDocument
            }
            let document = try JSONDecoder().decode(ScratchpadDocument.self, from: data)
            try validatePads(document.pads)
            guard document.pads.contains(where: { $0.id == document.selectedID }) else { throw ScratchpadImportError.invalidDocument }
            return document
        } catch let error as ScratchpadImportError { throw error }
        catch { throw ScratchpadImportError.invalidDocument }
    }

    private static func validatePads(_ pads: [ScratchpadPad]) throws {
        guard (1...ScratchpadDocument.maximumPadCount).contains(pads.count),
              Set(pads.map(\.id)).count == pads.count,
              pads.allSatisfy({ !$0.name.isEmpty && $0.name.count <= ScratchpadDocument.maximumNameLength
                  && ScratchpadSupport.sanitizedPadName($0.name) == $0.name
                  && ($0.modifiedAt?.timeIntervalSinceReferenceDate.isFinite ?? true) }) else {
            throw ScratchpadImportError.invalidDocument
        }
    }

    static func canReplaceOnlyEmpty(in document: ScratchpadDocument) -> Bool {
        document.pads.count == 1 && document.pads[0].text.isEmpty
    }

    static func availableCount(in document: ScratchpadDocument, replaceOnlyEmpty: Bool) -> Int {
        let retained = replaceOnlyEmpty && canReplaceOnlyEmpty(in: document) ? 0 : document.pads.count
        return max(0, ScratchpadDocument.maximumPadCount - retained)
    }

    static func merge(selected: [ScratchpadPad], into document: ScratchpadDocument,
                      now: Date, replaceOnlyEmpty: Bool = false) throws -> ScratchpadDocument {
        try validatePads(document.pads)
        guard document.pads.contains(where: { $0.id == document.selectedID }) else { throw ScratchpadImportError.invalidDocument }
        var seen = Set<UUID>()
        let unique = selected.filter { seen.insert($0.id).inserted }
        guard !unique.isEmpty else { return document }
        try validatePads(unique)
        let replacesEmpty = replaceOnlyEmpty && canReplaceOnlyEmpty(in: document)
        let retained = replacesEmpty ? [] : document.pads
        guard unique.count <= availableCount(in: document, replaceOnlyEmpty: replaceOnlyEmpty) else {
            throw ScratchpadImportError.capacityExceeded
        }
        var used = Set(document.pads.map(\.id))
        used.formUnion(unique.map(\.id))
        let copies = unique.map { pad -> ScratchpadPad in
            var id = UUID()
            while !used.insert(id).inserted { id = UUID() }
            return ScratchpadPad(id: id, name: pad.name, text: pad.text,
                                 modifiedAt: pad.text.isEmpty ? nil : now)
        }
        return ScratchpadDocument(pads: retained + copies, selectedID: replacesEmpty ? copies[0].id : document.selectedID)
    }
}
