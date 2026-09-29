// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import Foundation

/// A failed read must never authorize a later autosave or migration cleanup.
struct ScratchpadStore {
    let directoryURL: URL?
    let defaults: UserDefaults
    private(set) var lastSavedDocument: ScratchpadDocument?
    private var canSave = false

    init(directoryURL: URL?, defaults: UserDefaults) {
        self.directoryURL = directoryURL
        self.defaults = defaults
    }

    /// Import confirmation reads the complete owned document without retention
    /// or migration. Only a subsequent explicit save may change the JSON file.
    mutating func loadForImport(defaultName: String) throws -> ScratchpadDocument {
        canSave = false
        lastSavedDocument = nil
        guard let directoryURL else { throw ScratchpadImportError.unreadable }
        let url = directoryURL.appendingPathComponent("Scratchpad.json")
        let legacyURL = directoryURL.appendingPathComponent("Scratchpad.txt")
        let document: ScratchpadDocument
        if let data = try Self.readImportSourceIfPresent(at: url) {
            document = try ScratchpadImportSupport.decodeDocument(data)
            lastSavedDocument = document
        } else if let preference = defaults.object(forKey: DefaultsKey.scratchpadDocument) {
            guard let data = preference as? Data else { throw ScratchpadImportError.invalidDocument }
            document = try ScratchpadImportSupport.decodeDocument(data)
        } else if let data = try Self.readImportSourceIfPresent(at: legacyURL) {
            guard let text = String(data: data, encoding: .utf8) else { throw ScratchpadImportError.invalidUTF8 }
            let attributes = try FileManager.default.attributesOfItem(atPath: legacyURL.path)
            document = .initial(defaultName: defaultName, text: text,
                                modifiedAt: attributes[.modificationDate] as? Date)
        } else {
            document = .initial(defaultName: defaultName)
        }
        canSave = true
        return document
    }

    private static func readImportSourceIfPresent(at url: URL) throws -> Data? {
        do {
            _ = try FileManager.default.attributesOfItem(atPath: url.path)
        } catch let error as CocoaError where error.code == .fileReadNoSuchFile {
            return nil
        }
        return try ScratchpadImportSupport.readData(url)
    }

    mutating func load(defaultName: String,
                       retention: ScratchpadRetention,
                       now: Date) throws -> ScratchpadDocument {
        canSave = false
        lastSavedDocument = nil
        guard let directoryURL else { throw CocoaError(.fileReadUnknown) }
        let url = directoryURL.appendingPathComponent("Scratchpad.json")
        let legacyURL = directoryURL.appendingPathComponent("Scratchpad.txt")
        let storedData = try Self.readIfPresent(at: url)
        let preference = defaults.object(forKey: DefaultsKey.scratchpadDocument)
        let decoded: ScratchpadDocument
        var migratedLegacyFile = false

        if let storedData {
            decoded = try JSONDecoder().decode(ScratchpadDocument.self, from: storedData)
            lastSavedDocument = decoded
        } else if let preference {
            guard let data = preference as? Data else { throw CocoaError(.fileReadCorruptFile) }
            decoded = try JSONDecoder().decode(ScratchpadDocument.self, from: data)
        } else if let data = try Self.readIfPresent(at: legacyURL) {
            guard let text = String(data: data, encoding: .utf8) else {
                throw CocoaError(.fileReadInapplicableStringEncoding)
            }
            let attributes = try FileManager.default.attributesOfItem(atPath: legacyURL.path)
            decoded = .initial(defaultName: defaultName, text: text,
                               modifiedAt: attributes[.modificationDate] as? Date)
            migratedLegacyFile = true
        } else {
            decoded = .initial(defaultName: defaultName)
        }

        var loaded = decoded.sanitized(defaultName: defaultName)
        loaded.applyRetention(retention, now: now)
        canSave = true
        if save(loaded) {
            if preference != nil { defaults.removeObject(forKey: DefaultsKey.scratchpadDocument) }
            if migratedLegacyFile { try? FileManager.default.removeItem(at: legacyURL) }
        }
        return loaded
    }

    @discardableResult
    mutating func save(_ document: ScratchpadDocument) -> Bool {
        guard canSave else { return false }
        if document == lastSavedDocument { return true }
        guard let directoryURL, let data = document.encoded() else { return false }
        let url = directoryURL.appendingPathComponent("Scratchpad.json")
        guard PrivateFileStore.createDirectory(at: directoryURL),
              PrivateFileStore.write(data, to: url),
              (try? Data(contentsOf: url)) == data else { return false }
        lastSavedDocument = document
        return true
    }

    private static func readIfPresent(at url: URL) throws -> Data? {
        do {
            return try Data(contentsOf: url)
        } catch let error as CocoaError where error.code == .fileReadNoSuchFile {
            return nil
        }
    }
}
