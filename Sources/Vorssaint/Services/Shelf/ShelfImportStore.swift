// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

enum ShelfImportServiceError: Error { case unavailable, changed, managedReference(String) }

/// Owns staged imports on the shelf persistence queue. Live UI revisions and
/// item conversion remain the caller's gate before committing any transaction.
final class ShelfImportStore {
    private let directory: URL
    private var pending: [URL: (prepared: ShelfImportPrepared, source: URL)] = [:]

    init(directory: URL) { self.directory = directory }

    func prepare(selected: [ShelfPersistedItem], current: [ShelfPersistedItem],
                 mappings: [ShelfImportMapping], sourceURL: URL,
                 managedRoots: [URL]) throws -> ShelfImportPrepared {
        let access = sourceURL.startAccessingSecurityScopedResource()
        let scoped = mappings.map { $0.selectedDirectory.startAccessingSecurityScopedResource() }
        defer {
            if access { sourceURL.stopAccessingSecurityScopedResource() }
            for (mapping, acquired) in zip(mappings, scoped) where acquired {
                mapping.selectedDirectory.stopAccessingSecurityScopedResource()
            }
        }
        try validateSource(sourceURL)
        // Reject capacity before reading attachments, preserving all-or-nothing import.
        let merged = try ShelfImportSupport.merging(selected: selected, current: current)
        let copies = Array(merged.dropFirst(current.count))
        let assets = try ShelfImportAssets.prepare(items: copies, mappings: mappings,
                                                   destinationDirectory: directory)
        let copiedPaths = Set(assets.files.keys.map {
            directory.appendingPathComponent("ShelfFiles").appendingPathComponent($0).path
        })
        let roots = managedRoots.map { $0.standardizedFileURL.resolvingSymlinksInPath().path + "/" }
        func validateReferences(_ items: [ShelfPersistedItem]) throws {
            for item in items {
                if let path = item.path, !copiedPaths.contains(path) {
                    let canonical = URL(fileURLWithPath: path).standardizedFileURL.resolvingSymlinksInPath().path
                    guard !roots.contains(where: { canonical.hasPrefix($0) || canonical + "/" == $0 }) else {
                        throw ShelfImportServiceError.managedReference(path)
                    }
                }
                try validateReferences(item.children ?? [])
            }
        }
        try validateReferences(assets.items)
        let prepared = try ShelfImportTransaction.prepare(items: current + assets.items,
                                                          files: assets.files, in: directory)
        pending[prepared.stagingURL] = (prepared, sourceURL)
        return prepared
    }

    func commit(_ prepared: ShelfImportPrepared) throws {
        guard let transaction = pending[prepared.stagingURL], transaction.prepared === prepared else {
            throw ShelfImportServiceError.unavailable
        }
        defer { discard(prepared) }
        let access = transaction.source.startAccessingSecurityScopedResource()
        defer { if access { transaction.source.stopAccessingSecurityScopedResource() } }
        try validateSource(transaction.source)
        try ShelfImportTransaction.commit(prepared, to: directory)
    }

    func discard(_ prepared: ShelfImportPrepared) {
        guard pending[prepared.stagingURL]?.prepared === prepared else { return }
        pending.removeValue(forKey: prepared.stagingURL)
        ShelfImportTransaction.discard(prepared)
    }

    func discardAll() {
        let transactions = pending.values.map(\.prepared)
        for transaction in transactions { discard(transaction) }
    }

    private func validateSource(_ source: URL) throws {
        try ShelfImportAssets.validateSource(source: source,
            currentIndex: directory.appendingPathComponent("ShelfItems.json"))
    }
}
