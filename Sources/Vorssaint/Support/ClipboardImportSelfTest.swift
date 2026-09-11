// SPDX-License-Identifier: GPL-3.0-or-later
#if VORSSAINT_DEVELOPMENT
import Foundation
import CryptoKit

enum ClipboardImportSelfTest {
    static func run(_ expect: (Bool, String) -> Void) {
        let fm = FileManager.default
        let root = fm.temporaryDirectory.appendingPathComponent("kururu-clipboard-import-fixture-\(UUID())", isDirectory: true)
        func wait(_ condition: () -> Bool) -> Bool {
            let deadline = Date().addingTimeInterval(5)
            while !condition(), Date() < deadline {
                _ = RunLoop.main.run(mode: .default, before: min(deadline, Date().addingTimeInterval(0.01)))
            }
            return condition()
        }
        func drain(_ service: ClipboardHistoryService) -> Bool {
            var finished = false
            service.whenPersistenceDrained { finished = true }
            return wait { finished }
        }
        func hash(_ data: Data) -> String { SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined() }
        func read(_ directory: URL) throws -> [ClipboardHistoryEntry] {
            try JSONDecoder().decode([ClipboardHistoryEntry].self,
                from: Data(contentsOf: directory.appendingPathComponent("ClipboardHistory.json")))
        }
        do {
            try fm.createDirectory(at: root, withIntermediateDirectories: true, attributes: [.posixPermissions: 0o700])
            defer { try? fm.removeItem(at: root) }
            let source = root.appendingPathComponent("source", isDirectory: true)
            let sourceImages = source.appendingPathComponent("ClipboardImages", isDirectory: true)
            try fm.createDirectory(at: sourceImages, withIntermediateDirectories: true, attributes: [.posixPermissions: 0o700])
            let png = Data(base64Encoded: "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+jXioAAAAASUVORK5CYII=")!
            let image = ClipboardHistoryEntry(text: "", kind: .image, imageFile: "source.png", imageHash: hash(png), imageWidth: 1, imageHeight: 1)
            let incoming = [ClipboardHistoryEntry(text: "imported text"), image]
            let sourceURL = source.appendingPathComponent("ClipboardHistory.json")
            let sourceData = try JSONEncoder().encode(incoming)
            try sourceData.write(to: sourceURL)
            try png.write(to: sourceImages.appendingPathComponent("source.png"))
            let snapshot = try ClipboardImportSupport.read(sourceURL)
            let current = ClipboardHistoryEntry(text: "current text")
            func fixture(_ name: String) throws -> (ClipboardHistoryService, URL, Data) {
                let directory = root.appendingPathComponent(name, isDirectory: true)
                try fm.createDirectory(at: directory, withIntermediateDirectories: true, attributes: [.posixPermissions: 0o700])
                let data = try JSONEncoder().encode([current])
                try data.write(to: directory.appendingPathComponent("ClipboardHistory.json"))
                return (ClipboardHistoryService(initialEntries: [current], selectedIDs: [current.id], fixtureDirectory: directory), directory, data)
            }
            let (success, destination, _) = try fixture("success")
            var successResult: Result<Int, Error>?
            var completions = 0
            let request = success.importEntries(snapshot.entries, images: snapshot.images, sourceURL: sourceURL) {
                successResult = $0; completions += 1
            }
            expect(request != nil && success.isImporting, "import enters active state")
            expect(wait { successResult != nil }, "success completion arrives before deadline")
            expect(drain(success), "success lane drains")
            expect((try? successResult?.get()) == 2 && completions == 1, "success completes exactly once with imported count")
            expect(!success.isImporting, "success clears active state")
            expect(success.entries.count == 3 && success.entries.contains(current), "success retains current memory and appends copies")
            expect(try read(destination) == success.entries, "committed JSON matches published memory")
            if let copiedImage = success.entries.first(where: { $0.kind == .image }), let name = copiedImage.imageFile {
                expect(copiedImage.id != image.id, "imported image gets independent record identity")
                expect(try Data(contentsOf: destination.appendingPathComponent("ClipboardImages").appendingPathComponent(name)) == png,
                       "import copies real image bytes to destination")
            } else { expect(false, "imported image is present") }
            expect(try hash(Data(contentsOf: sourceURL)) == hash(sourceData)
                   && hash(Data(contentsOf: sourceImages.appendingPathComponent("source.png"))) == hash(png), "source JSON and image hashes remain unchanged")

            let (race, raceDirectory, _) = try fixture("race")
            var raceResult: Result<Int, Error>?
            do {
                let release = race.holdPersistenceForFixture()
                defer { release() }
                _ = race.importEntries(snapshot.entries, images: snapshot.images, sourceURL: sourceURL) { raceResult = $0 }
                race.remove(current)
            }
            expect(wait { raceResult != nil }, "generation race completes before deadline")
            expect(drain(race), "generation race lane drains")
            expect((try? raceResult?.get()) == 2, "generation retry imports selected copies")
            expect(!race.entries.contains(where: { $0.id == current.id }) && race.entries.count == 2,
                   "retry preserves deletion made after initial snapshot")
            expect(try read(raceDirectory) == race.entries, "generation retry disk matches latest memory")

            let (cancelled, cancelDirectory, cancelBytes) = try fixture("cancelled")
            var cancelCompletions = 0
            do {
                let release = cancelled.holdPersistenceForFixture()
                defer { release() }
                if let request = cancelled.importEntries(snapshot.entries, images: snapshot.images, sourceURL: sourceURL,
                                                         completion: { _ in cancelCompletions += 1 }) {
                    cancelled.cancelImport(request)
                } else { expect(false, "cancel fixture receives request identity") }
            }
            expect(drain(cancelled), "cancel lane drains and prepared stage is discarded")
            expect(!cancelled.isImporting && cancelCompletions == 0, "cancel clears state without publishing obsolete completion")
            expect(cancelled.entries == [current], "cancel retains current memory")
            expect(try Data(contentsOf: cancelDirectory.appendingPathComponent("ClipboardHistory.json")) == cancelBytes,
                   "cancel retains exact current JSON")
            let cancelNames = try fm.contentsOfDirectory(atPath: cancelDirectory.path)
            expect(cancelNames.allSatisfy { $0 == "ClipboardHistory.json" || $0 == "ClipboardImages" }, "cancel reclaims its staging directory")
            let cancelImages = cancelDirectory.appendingPathComponent("ClipboardImages")
            expect(!fm.fileExists(atPath: cancelImages.path) || (try? fm.contentsOfDirectory(atPath: cancelImages.path))?.isEmpty == true,
                   "cancel leaves no imported image copies")

            let (same, sameDirectory, sameBytes) = try fixture("same-source")
            var sameResult: Result<Int, Error>?
            _ = same.importEntries(snapshot.entries, images: snapshot.images,
                                   sourceURL: sameDirectory.appendingPathComponent("ClipboardHistory.json")) { sameResult = $0 }
            expect(wait { sameResult != nil }, "same-source rejection completes")
            if case .failure? = sameResult { expect(true, "same target source is rejected") }
            else { expect(false, "same target source is rejected") }
            expect(drain(same), "same-source lane drains")
            expect(try same.entries == [current] && Data(contentsOf: sameDirectory.appendingPathComponent("ClipboardHistory.json")) == sameBytes,
                   "same-source rejection preserves current records")

            let (terminating, terminationDirectory, terminationBytes) = try fixture("termination")
            var terminationCompletions = 0
            let terminationRequest = terminating.importEntries(snapshot.entries, images: snapshot.images,
                                                               sourceURL: sourceURL) { _ in terminationCompletions += 1 }
            expect(terminationRequest != nil && terminating.isImporting, "termination fixture starts import")
            // No main-loop turn here: shutdown must discard queue-owned preparation itself.
            terminating.flushBeforeTermination()
            expect(!terminating.isImporting, "termination flush cancels active import synchronously")
            expect(terminating.entries == [current], "termination flush preserves current memory")
            expect(try Data(contentsOf: terminationDirectory.appendingPathComponent("ClipboardHistory.json")) == terminationBytes,
                   "termination flush preserves exact committed JSON")
            let terminationNames = try fm.contentsOfDirectory(atPath: terminationDirectory.path)
            expect(terminationNames.allSatisfy { $0 == "ClipboardHistory.json" || $0 == "ClipboardImages" },
                   "termination flush discards prepared staging directories before returning")
            let terminationImages = terminationDirectory.appendingPathComponent("ClipboardImages")
            expect(!fm.fileExists(atPath: terminationImages.path)
                   || (try? fm.contentsOfDirectory(atPath: terminationImages.path))?.isEmpty == true,
                   "termination flush leaves no imported image copies")
            expect(drain(terminating), "termination late callbacks drain before deadline")
            expect(terminationCompletions == 0 && !terminating.isImporting && terminating.entries == [current],
                   "late preparation callback cannot complete or publish after termination")
            expect(try Data(contentsOf: terminationDirectory.appendingPathComponent("ClipboardHistory.json")) == terminationBytes,
                   "late preparation callback cannot commit after termination")

            let (failed, failedDirectory, _) = try fixture("failed")
            let blocked = failedDirectory.appendingPathComponent("ClipboardHistory.json")
            try fm.removeItem(at: blocked)
            try fm.createDirectory(at: blocked, withIntermediateDirectories: false)
            try Data("block".utf8).write(to: blocked.appendingPathComponent("keep"))
            var failureResult: Result<Int, Error>?
            _ = failed.importEntries(snapshot.entries, images: snapshot.images, sourceURL: sourceURL) { failureResult = $0 }
            expect(wait { failureResult != nil }, "blocked commit completes with failure")
            if case .failure? = failureResult { expect(true, "nonempty directory blocks JSON commit") }
            else { expect(false, "nonempty directory blocks JSON commit") }
            expect(drain(failed), "blocked commit lane drains")
            expect(failed.entries == [current] && !failed.isImporting, "failed commit never publishes imported entries")
            expect(try Data(contentsOf: blocked.appendingPathComponent("keep")) == Data("block".utf8), "blocked target remains intact")
            let externalFile = root.appendingPathComponent("referenced-original.txt")
            let externalBytes = Data("original file remains in place".utf8)
            try externalBytes.write(to: externalFile)
            let fileEntry = ClipboardHistoryEntry(text: "", kind: .files, filePaths: [externalFile.path])
            let plistEntries = incoming + [fileEntry]
            let plistURL = source.appendingPathComponent("legacy-preferences.plist")
            let plistBytes = try PropertyListSerialization.data(fromPropertyList: [
                "clipboardHistoryEntries": try JSONEncoder().encode(plistEntries),
                "launchAtLoginWanted": true,
                "micMuteActive": true,
                "micMuteMutedDevices": ["fixture-device"],
                "featureAvailable.clipboardHistory": false,
            ], format: .binary, options: 0)
            try plistBytes.write(to: plistURL)
            let plistSnapshot = try ClipboardImportSupport.read(plistURL, imageDirectory: sourceImages)
            expect(plistSnapshot.entries.count == 3, "legacy plist snapshot contains only three content records")
            expect(plistSnapshot.entries.contains(where: { $0.kind == .files && $0.filePaths == [externalFile.path] }),
                   "legacy plist preserves external file reference")
            let (plistService, plistDestination, _) = try fixture("legacy-plist")
            var plistResult: Result<Int, Error>?
            var plistCompletions = 0
            _ = plistService.importEntries(plistSnapshot.entries, images: plistSnapshot.images, sourceURL: plistURL) {
                plistResult = $0; plistCompletions += 1
            }
            expect(wait { plistResult != nil }, "legacy plist service import completes before deadline")
            expect(drain(plistService), "legacy plist service persistence drains")
            expect((try? plistResult?.get()) == 3 && plistCompletions == 1, "legacy plist import completes once with mixed record count")
            expect(!plistService.isImporting && plistService.entries.count == 4 && plistService.entries.contains(current),
                   "legacy plist import appends copies and retains current record")
            expect(try read(plistDestination) == plistService.entries, "legacy plist committed JSON matches service memory")
            if let copiedImage = plistService.entries.first(where: { $0.kind == .image }), let name = copiedImage.imageFile {
                expect(try Data(contentsOf: plistDestination.appendingPathComponent("ClipboardImages").appendingPathComponent(name)) == png,
                       "legacy plist explicit image directory supplies real image copy")
            } else { expect(false, "legacy plist imported image exists") }
            expect(try hash(Data(contentsOf: plistURL)) == hash(plistBytes), "legacy source binary plist hash remains unchanged")
            expect(try Data(contentsOf: externalFile) == externalBytes, "legacy file reference does not move or rewrite original")

            let oldTextJSON = Data("[{\"text\":\"legacy text without identity\",\"copiedAt\":0}]".utf8)
            let xmlURL = source.appendingPathComponent("legacy-text.plist")
            let xmlBytes = try PropertyListSerialization.data(fromPropertyList: ["clipboardHistoryEntries": oldTextJSON],
                                                              format: .xml, options: 0)
            try xmlBytes.write(to: xmlURL)
            let xmlSnapshot = try ClipboardImportSupport.read(xmlURL)
            let xmlSelection = xmlSnapshot.entries.map(\.id)
            expect(xmlSnapshot.entries.count == 1 && xmlSnapshot.entries.first?.kind == .text,
                   "XML legacy record without kind decodes as text")
            let (xmlService, xmlDestination, _) = try fixture("legacy-xml")
            let selectedXML = xmlSnapshot.entries.filter { xmlSelection.contains($0.id) }
            var xmlResult: Result<Int, Error>?
            _ = xmlService.importEntries(selectedXML, images: xmlSnapshot.images, sourceURL: xmlURL) { xmlResult = $0 }
            expect(wait { xmlResult != nil }, "legacy XML selected snapshot import completes")
            expect(drain(xmlService), "legacy XML service persistence drains")
            expect((try? xmlResult?.get()) == 1 && xmlService.entries.contains(where: { $0.text == "legacy text without identity" }),
                   "legacy generated identity selection imports the previewed record")
            expect(try read(xmlDestination) == xmlService.entries, "legacy XML selected snapshot persists exact published entries")
            expect(try Data(contentsOf: xmlURL) == xmlBytes, "legacy XML snapshot read leaves source unchanged")
        } catch { expect(false, "clipboard import fixture error: \(type(of: error))") }
    }
}
#endif
