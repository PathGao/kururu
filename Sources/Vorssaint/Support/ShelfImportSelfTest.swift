// SPDX-License-Identifier: GPL-3.0-or-later
#if VORSSAINT_DEVELOPMENT
import Foundation

enum ShelfImportSelfTest {
    static func run(_ expect: (Bool, String) -> Void) {
        let fm = FileManager.default
        let root = fm.temporaryDirectory.resolvingSymlinksInPath()
            .appendingPathComponent("kururu-shelf-import-\(UUID())", isDirectory: true)
        let suiteName = "com.vorssaint.tests.shelf-import.\(UUID())"
        guard let defaults = UserDefaults(suiteName: suiteName) else { expect(false, "shelf import fixture defaults"); return }
        defer { defaults.removePersistentDomain(forName: suiteName) }
        var services: [ShelfService] = []
        func wait(_ condition: () -> Bool) -> Bool {
            let deadline = Date().addingTimeInterval(5)
            while !condition(), Date() < deadline {
                _ = RunLoop.main.run(mode: .default, before: min(deadline, Date().addingTimeInterval(0.01)))
            }
            return condition()
        }
        func drain(_ service: ShelfService) -> Bool {
            var finished = false
            service.whenPersistenceDrained { finished = true }
            return wait { finished }
        }
        func index(_ directory: URL) -> URL { directory.appendingPathComponent("ShelfItems.json") }
        func read(_ directory: URL) throws -> [ShelfPersistedItem] {
            let loaded = ShelfPersistenceSupport.load(try Data(contentsOf: index(directory)))
            guard case let .items(records) = loaded else { throw ShelfIndexError.unreadable }
            return records
        }
        func record(_ item: ShelfService.Item) -> ShelfPersistedItem {
            switch item.payload {
            case let .text(text): return ShelfPersistedItem(id: item.id, kind: .text, title: item.storedTitle, text: text)
            case let .link(url): return ShelfPersistedItem(id: item.id, kind: .link, title: item.storedTitle, url: url.absoluteString)
            case let .file(url): return ShelfPersistedItem(id: item.id, kind: .file, title: item.storedTitle, path: url.path, bookmark: item.bookmark)
            case let .batch(children): return ShelfPersistedItem(id: item.id, kind: .batch, title: item.storedTitle, children: children.map(record))
            }
        }
        func withoutBookmarks(_ item: ShelfPersistedItem) -> ShelfPersistedItem {
            var copy = item; copy.bookmark = nil; copy.children = item.children?.map(withoutBookmarks); return copy
        }
        func ids(_ items: [ShelfPersistedItem]) -> [UUID] { items.flatMap { [$0.id] + ids($0.children ?? []) } }
        func hasNoPreparedFiles(_ directory: URL) throws -> Bool {
            let names = try fm.contentsOfDirectory(atPath: directory.path)
            let files = directory.appendingPathComponent("ShelfFiles")
            return try names.allSatisfy { ["ShelfItems.json", "ShelfFiles", "TemporaryShelf"].contains($0) }
                && (!fm.fileExists(atPath: files.path) || (try fm.contentsOfDirectory(atPath: files.path)).isEmpty)
        }
        let current = ShelfPersistedItem(id: UUID(), kind: .text, title: "Existing", text: "current content")
        func fixture(_ name: String, records: [ShelfPersistedItem]? = nil, raw: Data? = nil) throws -> (ShelfService, URL, Data) {
            let directory = root.appendingPathComponent(name, isDirectory: true)
            try fm.createDirectory(at: directory, withIntermediateDirectories: true)
            try (raw ?? JSONEncoder().encode(records ?? [current])).write(to: index(directory))
            let service = ShelfService(fixtureDirectory: directory, legacyDefaults: defaults)
            services.append(service)
            expect(wait { service.hasRestoredForFixture } && drain(service), "\(name): fixture restore drains")
            return (service, directory, try Data(contentsOf: index(directory)))
        }
        func failed(_ result: Result<Int, Error>?) -> Bool { if case .failure? = result { return true }; return false }
        do {
            try fm.createDirectory(at: root, withIntermediateDirectories: true, attributes: [.posixPermissions: 0o700])
            defer {
                for service in services { service.flushBeforeTermination(); _ = drain(service) }
                try? fm.removeItem(at: root)
            }
            let source = root.appendingPathComponent("source", isDirectory: true)
            let oldAssets = source.appendingPathComponent("attachments", isDirectory: true)
            let external = source.appendingPathComponent("external", isDirectory: true)
            try fm.createDirectory(at: oldAssets, withIntermediateDirectories: true)
            try fm.createDirectory(at: external, withIntermediateDirectories: true)
            let attachment = oldAssets.appendingPathComponent("old.png")
            let original = external.appendingPathComponent("document.txt")
            let folder = external.appendingPathComponent("folder", isDirectory: true)
            try fm.createDirectory(at: folder, withIntermediateDirectories: true)
            let png = Data(base64Encoded: "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+jXioAAAAASUVORK5CYII=")!
            let originalBytes = Data("external source unchanged".utf8)
            try png.write(to: attachment); try originalBytes.write(to: original)
            let text = ShelfPersistedItem(id: UUID(), kind: .text, title: "", text: "  first line\nsecond line  ")
            let link = ShelfPersistedItem(id: UUID(), kind: .link, title: "Named link", url: "https://example.com/a?q=1#anchor")
            let incoming = [ShelfPersistedItem(id: UUID(), kind: .batch, title: "Custom outer group", children: [
                text,
                ShelfPersistedItem(id: UUID(), kind: .batch, title: "Custom single child", children: [link]),
                ShelfPersistedItem(id: UUID(), kind: .file, title: "External document", path: "/old/external/document.txt"),
                ShelfPersistedItem(id: UUID(), kind: .file, title: "External folder", path: "/old/external/folder"),
                ShelfPersistedItem(id: UUID(), kind: .file, title: "Copied image", path: "/old/attachments/old.png", bookmark: try attachment.bookmarkData())
            ])]
            let sourceURL = source.appendingPathComponent("ShelfItems.json")
            let sourceBytes = try JSONEncoder().encode(incoming)
            try sourceBytes.write(to: sourceURL)
            let mappings = [
                ShelfImportMapping(originalDirectory: "/old/attachments", selectedDirectory: oldAssets, copyFiles: true),
                ShelfImportMapping(originalDirectory: "/old/external", selectedDirectory: external, copyFiles: false)
            ]
            let (success, destination, _) = try fixture("success")
            var successResult: Result<Int, Error>?, successCompletions = 0
            let request = success.importItems(incoming, mappings: mappings, sourceURL: sourceURL) { successResult = $0; successCompletions += 1 }
            expect(request != nil && success.isImporting, "mixed import becomes active")
            expect(wait { successResult != nil }, "mixed import completion arrives")
            expect((try? successResult?.get()) == 5 && successCompletions == 1 && !success.isImporting,
                   "mixed import completes once with all five leaves: \(String(describing: successResult))")
            let published = success.items.map(record)
            let committed = try read(destination)
            expect(committed.map(withoutBookmarks) == published.map(withoutBookmarks), "completion observes immediately durable published index")
            expect(published.first == current && published.count == 2, "mixed import keeps existing root and appends complete tree")
            let generated = ids(Array(published.dropFirst()))
            expect(generated.count == ids(incoming).count && Set(generated).count == generated.count
                && Set(generated).isDisjoint(with: ids(incoming) + [current.id]), "every imported descendant receives an independent identity")
            if let imported = published.last, let children = imported.children, children.count == 5 {
                expect(imported.title == "Custom outer group" && children[0].text == text.text && children[0].title.isEmpty,
                       "group title and text whitespace remain exact")
                expect(children[1].title == "Custom single child" && children[1].kind == .batch
                    && children[1].children?.count == 1 && children[1].children?.first?.url == link.url,
                       "single child group remains a named group")
                expect(children[2].path == original.path && children[3].path == folder.path
                    && children[2].bookmark != nil && children[3].bookmark != nil, "file and directory are external references with bookmarks")
                if let path = children[4].path {
                    expect(try path.hasPrefix(destination.appendingPathComponent("ShelfFiles").path + "/")
                        && path != attachment.path && (try Data(contentsOf: URL(fileURLWithPath: path))) == png,
                           "copied attachment has independent destination bytes")
                    expect(children[4].bookmark != incoming[0].children?[4].bookmark, "copied item does not retain old attachment bookmark")
                } else { expect(false, "copied attachment path exists") }
            } else { expect(false, "mixed imported tree contains all children") }
            expect(try Data(contentsOf: sourceURL) == sourceBytes && Data(contentsOf: attachment) == png
                && Data(contentsOf: original) == originalBytes, "mixed import preserves source index and original files")
            expect(drain(success), "successful import queue drains")
            success.flushBeforeTermination()
            expect(try read(destination).map(withoutBookmarks) == published.map(withoutBookmarks), "termination flush preserves imported tree")
            let reload = ShelfService(fixtureDirectory: destination, legacyDefaults: defaults)
            services.append(reload)
            expect(wait { reload.hasRestoredForFixture } && drain(reload), "imported index reload drains")
            expect(reload.items.map(record).map(withoutBookmarks) == published.map(withoutBookmarks), "restart preserves hierarchy titles order and payloads")
            reload.flushBeforeTermination()
            expect(try read(destination).map(withoutBookmarks) == published.map(withoutBookmarks), "restart flush preserves complete import")

            let (cancelled, cancelDirectory, cancelBytes) = try fixture("cancel")
            var cancelCompletions = 0
            if let request = cancelled.importItems(incoming, mappings: mappings, sourceURL: sourceURL, completion: { _ in cancelCompletions += 1 }) {
                cancelled.cancelImport(request)
            } else { expect(false, "cancel request created") }
            expect(drain(cancelled), "cancel preparation and callback drain")
            expect(!cancelled.isImporting && cancelCompletions == 0 && cancelled.items.map(record) == [current], "cancel never publishes obsolete completion or items")
            expect(try Data(contentsOf: index(cancelDirectory)) == cancelBytes && hasNoPreparedFiles(cancelDirectory), "cancel preserves exact index and reclaims staging plus copies")

            let (terminating, terminationDirectory, _) = try fixture("termination")
            var terminationCompletions = 0
            let terminationRequest = terminating.importItems(incoming, mappings: mappings, sourceURL: sourceURL) { _ in terminationCompletions += 1 }
            expect(terminationRequest != nil && terminating.isImporting, "termination starts pending preparation")
            // No main-loop turn: termination must discard work owned by the persistence queue.
            terminating.flushBeforeTermination()
            expect(!terminating.isImporting && terminating.items.map(record) == [current], "termination synchronously cancels import")
            // Termination legitimately rewrites JSON; key order is not a data change.
            expect(try read(terminationDirectory) == [current] && hasNoPreparedFiles(terminationDirectory), "termination returns with original records and no staged assets")
            expect(drain(terminating) && terminationCompletions == 0, "late callback cannot complete terminated import")
            expect(try read(terminationDirectory) == [current] && hasNoPreparedFiles(terminationDirectory), "late callback cannot commit or leave assets")

            let full = (0..<ShelfPersistenceSupport.maxLeaves).map { ShelfPersistedItem(id: UUID(), kind: .text, title: "\($0)", text: "item \($0)") }
            let (capacity, capacityDirectory, capacityBytes) = try fixture("capacity", records: full)
            var capacityResult: Result<Int, Error>?
            _ = capacity.importItems([text], mappings: [], sourceURL: sourceURL) { capacityResult = $0 }
            expect(wait { capacityResult != nil } && drain(capacity), "capacity rejection completes")
            expect(failed(capacityResult) && capacity.itemCount == full.count, "capacity refuses overflow without truncation")
            expect(try Data(contentsOf: index(capacityDirectory)) == capacityBytes && hasNoPreparedFiles(capacityDirectory), "capacity rejection preserves durable index and creates no payloads")

            let unknown = try JSONSerialization.data(withJSONObject: [["id": UUID().uuidString, "kind": "future", "title": "Unknown record"]])
            let (partial, partialDirectory, partialBytes) = try fixture("partial", raw: unknown)
            var partialResult: Result<Int, Error>?
            let partialRequest = partial.importItems([text], mappings: [], sourceURL: sourceURL) { partialResult = $0 }
            expect(partialRequest == nil && failed(partialResult) && !partial.isImporting, "unreadable partial index refuses import")
            expect(drain(partial), "partial refusal callbacks drain")
            expect(try Data(contentsOf: index(partialDirectory)) == partialBytes, "partial index retains unknown bytes")

            let (race, raceDirectory, _) = try fixture("revision-race")
            let concurrent = ShelfPersistedItem(id: UUID(), kind: .text, title: "Concurrent edit", text: "newer current value")
            var raceResult: Result<Int, Error>?
            _ = race.importItems(incoming, mappings: mappings, sourceURL: sourceURL) { raceResult = $0 }
            // The commit callback cannot run until this main-thread mutation has changed the revision.
            race.replaceItemsForFixture([concurrent])
            expect(wait { raceResult != nil } && drain(race), "revision mismatch retry finishes")
            expect((try? raceResult?.get()) == 5 && race.items.map(record).first == concurrent && race.items.count == 2,
                   "retry preserves concurrent current replacement and adds complete selection")
            expect(try read(raceDirectory).map(withoutBookmarks) == race.items.map(record).map(withoutBookmarks), "retry index matches latest current memory")
            expect((try? fm.contentsOfDirectory(atPath: raceDirectory.appendingPathComponent("ShelfFiles").path).count) == 1,
                   "retry discards superseded attachment copy")

            let (queued, queuedDirectory, _) = try fixture("queued-save")
            var queuedResult: Result<Int, Error>?
            do {
                let release = queued.holdPersistenceForFixture()
                defer { release() }
                _ = queued.importItems(incoming, mappings: mappings, sourceURL: sourceURL) { queuedResult = $0 }
                queued.retryPersistence()
            }
            expect(wait { queuedResult != nil } && drain(queued), "save queued during prepare drains with import")
            expect((try? queuedResult?.get()) == 5 && queued.items.count == 2,
                   "same revision retry save does not prevent complete import")
            expect(try read(queuedDirectory).map(withoutBookmarks) == queued.items.map(record).map(withoutBookmarks),
                   "queued old save cannot overwrite committed imported index")

            let (managed, managedDirectory, managedBytes) = try fixture("managed-reference")
            let managedFiles = managedDirectory.appendingPathComponent("ShelfFiles")
            try fm.createDirectory(at: managedFiles, withIntermediateDirectories: true)
            let managedSource = managedFiles.appendingPathComponent("existing.txt")
            try originalBytes.write(to: managedSource)
            let managedItem = ShelfPersistedItem(id: UUID(), kind: .file, title: "Reference", path: "/old/managed/existing.txt")
            var managedResult: Result<Int, Error>?
            _ = managed.importItems([managedItem], mappings: [ShelfImportMapping(originalDirectory: "/old/managed", selectedDirectory: managedFiles, copyFiles: false)], sourceURL: sourceURL) { managedResult = $0 }
            expect(wait { managedResult != nil } && drain(managed) && failed(managedResult), "managed payload root refuses ordinary reference import")
            expect(try Data(contentsOf: managedSource) == originalBytes && Data(contentsOf: index(managedDirectory)) == managedBytes
                && managed.items.map(record) == [current], "managed reference rejection preserves original asset index and memory")

            let (same, sameDirectory, sameBytes) = try fixture("same-index")
            var sameResult: Result<Int, Error>?
            _ = same.importItems([text], mappings: [], sourceURL: index(sameDirectory)) { sameResult = $0 }
            expect(wait { sameResult != nil } && drain(same) && failed(sameResult), "current index cannot be its own import source")
            expect(try Data(contentsOf: index(sameDirectory)) == sameBytes && same.items.map(record) == [current], "same-source refusal keeps index and memory")

            let (blocked, blockedDirectory, _) = try fixture("blocked-commit")
            try fm.removeItem(at: index(blockedDirectory))
            try fm.createDirectory(at: index(blockedDirectory), withIntermediateDirectories: false)
            let sentinel = index(blockedDirectory).appendingPathComponent("keep")
            try originalBytes.write(to: sentinel)
            var blockedResult: Result<Int, Error>?
            _ = blocked.importItems(incoming, mappings: mappings, sourceURL: sourceURL) { blockedResult = $0 }
            expect(wait { blockedResult != nil } && drain(blocked) && failed(blockedResult), "blocked JSON commit reports failure")
            expect(blocked.items.map(record) == [current] && !blocked.isImporting, "failed commit never publishes additions")
            expect(try Data(contentsOf: sentinel) == originalBytes && hasNoPreparedFiles(blockedDirectory), "failed commit preserves blocker and rolls back staged copies")
        } catch { expect(false, "shelf import integration fixture failed: \(error)") }
    }
}
#endif
