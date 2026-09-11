// SPDX-License-Identifier: GPL-3.0-or-later
#if VORSSAINT_DEVELOPMENT
import Foundation

enum ScratchpadImportSelfTest {
    static func run(_ expect: (Bool, String) -> Void) {
        let fm = FileManager.default
        let root = fm.temporaryDirectory.appendingPathComponent("kururu-scratchpad-import-\(UUID())", isDirectory: true)
        let suiteName = "com.vorssaint.tests.scratchpad-import.\(UUID())"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            expect(false, "scratchpad import fixture suite created")
            return
        }
        defaults.set("never", forKey: DefaultsKey.scratchpadRetention)
        defer {
            defaults.removePersistentDomain(forName: suiteName)
            try? fm.removeItem(at: root)
        }
        func index(_ directory: URL) -> URL { directory.appendingPathComponent("Scratchpad.json") }
        func read(_ directory: URL) throws -> ScratchpadDocument {
            try JSONDecoder().decode(ScratchpadDocument.self, from: Data(contentsOf: index(directory)))
        }
        func fixture(_ name: String, document: ScratchpadDocument? = nil) throws -> URL {
            let directory = root.appendingPathComponent(name, isDirectory: true)
            try fm.createDirectory(at: directory, withIntermediateDirectories: true)
            if let document { try JSONEncoder().encode(document).write(to: index(directory)) }
            return directory
        }
        func refuses(_ expected: ScratchpadImportError, _ message: String, _ action: () throws -> Int) {
            do { _ = try action(); expect(false, message) }
            catch { expect(error as? ScratchpadImportError == expected, "\(message): \(error)") }
        }
        let oldDate = Date(timeIntervalSince1970: 1_000)
        let kept = ScratchpadPad(id: UUID(), name: "Existing", text: "Original text", modifiedAt: oldDate)
        let other = ScratchpadPad(id: UUID(), name: "Other", text: "Other text", modifiedAt: oldDate)
        let original = ScratchpadDocument(pads: [other, kept], selectedID: kept.id)
        let incoming = ScratchpadPad(id: UUID(), name: "Imported", text: "Imported\n中文 text", modifiedAt: oldDate)
        do {
            let sourceDirectory = try fixture("source")
            let source = sourceDirectory.appendingPathComponent("import.json")
            let sourceBytes = try JSONEncoder().encode(ScratchpadDocument(pads: [incoming], selectedID: incoming.id))
            try sourceBytes.write(to: source)
            let selected = try ScratchpadImportSupport.read(source).pads
            let coldDirectory = try fixture("cold", document: original)
            let cold = ScratchpadService(fixtureDirectory: coldDirectory, defaults: defaults)
            defer { cold.prepareForSettingsRestore() }
            expect(cold.pads.isEmpty && cold.selectedPadID == nil, "cold fixture starts without loading")
            expect(try cold.importPads(selected, sourceURL: source) == 1, "cold import returns one committed copy")
            let committed = try read(coldDirectory)
            expect(Array(committed.pads.prefix(2)) == original.pads, "cold import immediately persists existing records unchanged")
            expect(committed.selectedID == kept.id && cold.selectedPadID == kept.id && cold.text == kept.text,
                   "cold import preserves existing selection and displayed text")
            expect(committed.pads.count == 3 && cold.pads == committed.pads, "cold import publishes the complete durable document")
            let copy = committed.pads[2]
            expect(!Set(original.pads.map(\.id) + selected.map(\.id)).contains(copy.id), "cold import assigns a new ID")
            expect(copy.name == incoming.name && copy.text == incoming.text && (copy.modifiedAt ?? oldDate) > oldDate,
                   "cold import preserves content and refreshes nonempty copy date")
            let reopened = ScratchpadService(fixtureDirectory: coldDirectory, defaults: defaults)
            defer { reopened.prepareForSettingsRestore() }
            reopened.prepareForSettingsBackup()
            expect(reopened.pads == committed.pads && reopened.selectedPadID == kept.id && reopened.text == kept.text,
                   "new service restores all committed records with retention never")

            cold.text = "Latest edit before autosave"
            expect(try read(coldDirectory) == committed, "warm edit is still pending before import")
            expect(try cold.importPads([incoming, incoming], sourceURL: source) == 1, "duplicate source selection counts one copy")
            let warm = try read(coldDirectory)
            expect(warm.pads.count == 4 && warm.pads.last?.id != copy.id && warm.pads.last?.id != incoming.id,
                   "warm duplicate selection appends exactly one fresh copy")
            expect(warm.pads.first(where: { $0.id == kept.id })?.text == "Latest edit before autosave"
                   && cold.text == "Latest edit before autosave" && warm.selectedID == kept.id,
                   "warm import commits latest pending edit and preserves selection")
            cold.hide()
            expect(try read(coldDirectory) == warm, "hide cannot overwrite the imported document with an older pending save")

            let empty = ScratchpadDocument.initial(defaultName: "Note")
            let appendDirectory = try fixture("append-empty", document: empty)
            let append = ScratchpadService(fixtureDirectory: appendDirectory, defaults: defaults)
            defer { append.prepareForSettingsRestore() }
            expect(try append.importPads(selected, sourceURL: source) == 1, "default import into an empty pad succeeds")
            expect(append.pads.count == 2 && append.pads.first == empty.pads.first && append.selectedPadID == empty.selectedID,
                   "default import retains the empty pad and selection")
            let twelve = (0..<ScratchpadDocument.maximumPadCount).map {
                ScratchpadPad(id: UUID(), name: "Import \($0)", text: "Text \($0)", modifiedAt: oldDate)
            }
            let replacementDirectory = try fixture("replace-empty", document: empty)
            let replacement = ScratchpadService(fixtureDirectory: replacementDirectory, defaults: defaults)
            defer { replacement.prepareForSettingsRestore() }
            let emptyBytes = try Data(contentsOf: index(replacementDirectory))
            refuses(.capacityExceeded, "default import refuses twelve copies beside an existing empty pad") {
                try replacement.importPads(twelve, sourceURL: source)
            }
            expect(try Data(contentsOf: index(replacementDirectory)) == emptyBytes && replacement.pads.isEmpty,
                   "cold capacity refusal preserves bytes and unloaded memory")
            expect(try replacement.importPads(twelve, sourceURL: source, replaceOnlyEmpty: true) == twelve.count,
                   "explicit replacement fits twelve copies in the sole empty pad")
            let full = try read(replacementDirectory)
            expect(full.pads.count == ScratchpadDocument.maximumPadCount && full.selectedID == full.pads.first?.id
                   && !full.pads.contains(where: { $0.id == empty.selectedID }),
                   "explicit empty replacement removes old pad and selects the first copy")
            let fullBytes = try Data(contentsOf: index(replacementDirectory))
            refuses(.capacityExceeded, "full document refuses another import") {
                try replacement.importPads(selected, sourceURL: source, replaceOnlyEmpty: true)
            }
            expect(try Data(contentsOf: index(replacementDirectory)) == fullBytes && replacement.pads == full.pads
                   && replacement.selectedPadID == full.selectedID && replacement.text == full.pads[0].text,
                   "warm capacity refusal preserves bytes, pads, selection and text")

            let badDirectory = try fixture("bad-index")
            let badBytes = Data("{\"unknown\":\"do not overwrite\"}".utf8)
            try badBytes.write(to: index(badDirectory))
            let bad = ScratchpadService(fixtureDirectory: badDirectory, defaults: defaults)
            defer { bad.prepareForSettingsRestore() }
            do { _ = try bad.importPads(selected, sourceURL: source); expect(false, "bad index refuses import") }
            catch ScratchpadImportActionError.unavailable { expect(true, "bad index refuses import") }
            catch { expect(false, "bad index reports unexpected error: \(error)") }
            bad.hide()
            expect(try Data(contentsOf: index(badDirectory)) == badBytes && bad.pads.isEmpty
                   && bad.selectedPadID == nil && bad.text.isEmpty, "bad index refusal and hide preserve bytes and unloaded memory")

            let alias = sourceDirectory.appendingPathComponent("current-hardlink.json")
            try fm.linkItem(at: index(coldDirectory), to: alias)
            for url in [index(coldDirectory), alias] {
                refuses(.sameDestination, "service refuses current JSON or hardlink alias") {
                    try cold.importPads(selected, sourceURL: url)
                }
            }
            expect(try read(coldDirectory) == warm && cold.pads == warm.pads && cold.selectedPadID == warm.selectedID,
                   "self-import refusals preserve durable and live document")

            let failureDirectory = try fixture("write-failure", document: original)
            let failure = ScratchpadService(fixtureDirectory: failureDirectory, defaults: defaults)
            defer { failure.prepareForSettingsRestore() }
            failure.prepareForSettingsBackup()
            failure.text = "Pending edit survives failed import"
            let pendingPads = failure.pads
            let savedBytes = try Data(contentsOf: index(failureDirectory))
            try fm.removeItem(at: index(failureDirectory))
            try fm.createDirectory(at: index(failureDirectory), withIntermediateDirectories: false)
            let blocker = index(failureDirectory).appendingPathComponent("block")
            let blockerBytes = Data("blocked destination".utf8)
            try blockerBytes.write(to: blocker)
            do { _ = try failure.importPads(selected, sourceURL: source); expect(false, "failed write cannot report import success") }
            catch ScratchpadImportActionError.saveFailed { expect(true, "failed write reports saveFailed") }
            catch { expect(false, "failed write reports unexpected error: \(error)") }
            expect(failure.pads == pendingPads && failure.selectedPadID == kept.id && failure.text == "Pending edit survives failed import",
                   "failed write does not publish imported pads or discard pending text")
            expect(try Data(contentsOf: blocker) == blockerBytes, "failed write leaves destination blocker untouched")
            try fm.removeItem(at: index(failureDirectory))
            try savedBytes.write(to: index(failureDirectory))
            expect(try failure.importPads(selected, sourceURL: source) == 1, "import retry succeeds after destination recovery")
            let retried = try read(failureDirectory)
            expect(retried.pads.count == 3 && retried.pads.first(where: { $0.id == kept.id })?.text == failure.text
                   && failure.pads == retried.pads, "successful retry durably commits pending edit and one imported copy")
            failure.hide()
            expect(try read(failureDirectory) == retried, "post-retry hide preserves committed result")

            failure.text = "Stale pending edit before settings restore"
            failure.prepareForSettingsRestore()
            let restored = ScratchpadDocument(pads: [incoming], selectedID: incoming.id)
            let restoredBytes = try JSONEncoder().encode(restored)
            try restoredBytes.write(to: index(failureDirectory))
            failure.hide()
            expect(try Data(contentsOf: index(failureDirectory)) == restoredBytes,
                   "settings restore invalidates pending memory so hide preserves external JSON bytes")
            failure.prepareForSettingsBackup()
            expect(failure.pads == restored.pads && failure.selectedPadID == restored.selectedID && failure.text == incoming.text,
                   "settings restore reloads the same isolated fixture store")
            expect(try Data(contentsOf: source) == sourceBytes, "all import outcomes leave source bytes unchanged")
        } catch { expect(false, "scratchpad import fixture failed: \(error)") }
    }
}
#endif
