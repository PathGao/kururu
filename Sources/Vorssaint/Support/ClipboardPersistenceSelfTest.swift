// SPDX-License-Identifier: GPL-3.0-or-later
#if VORSSAINT_DEVELOPMENT
import Foundation

enum ClipboardPersistenceSelfTest {
    static func run(_ expect: (Bool, String) -> Void) {
        let manager = FileManager.default
        let root = manager.temporaryDirectory
            .appendingPathComponent("kururu-clipboard-persist-fixture-\(UUID())", isDirectory: true)
        func drain(_ service: ClipboardHistoryService) -> Bool {
            var finished = false
            service.whenPersistenceDrained { finished = true }
            let deadline = Date().addingTimeInterval(5)
            while !finished && Date() < deadline {
                _ = RunLoop.main.run(mode: .default, before: min(deadline, Date().addingTimeInterval(0.01)))
            }
            return finished
        }
        func read(_ directory: URL) throws -> [ClipboardHistoryEntry] {
            try JSONDecoder().decode([ClipboardHistoryEntry].self,
                from: Data(contentsOf: directory.appendingPathComponent("ClipboardHistory.json")))
        }
        do {
            try manager.createDirectory(at: root, withIntermediateDirectories: true)
            defer { try? manager.removeItem(at: root) }
            let external = root.appendingPathComponent("external-original.txt")
            let original = Data("untouched external fixture".utf8)
            try original.write(to: external)
            let date = Date(timeIntervalSince1970: 1_700_000_000)
            let pinned = ClipboardHistoryEntry(text: "", copiedAt: date, pinnedAt: date,
                kind: .image, imageFile: "pinned.png", imageHash: "fixture", imageWidth: 1, imageHeight: 1)
            let recent = ClipboardHistoryEntry(text: "", copiedAt: date, kind: .image,
                imageFile: "recent.png", imageHash: "fixture-recent", imageWidth: 1, imageHeight: 1)
            let files = ClipboardHistoryEntry(text: "", copiedAt: date, kind: .files, filePaths: [external.path])
            let png = Data(base64Encoded: "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+jXioAAAAASUVORK5CYII=")!
            func fixture(_ name: String) throws -> (URL, URL) {
                let directory = root.appendingPathComponent(name, isDirectory: true)
                let images = directory.appendingPathComponent("ClipboardImages", isDirectory: true)
                try manager.createDirectory(at: images, withIntermediateDirectories: true)
                try png.write(to: images.appendingPathComponent("pinned.png"))
                try png.write(to: images.appendingPathComponent("recent.png"))
                return (directory, images)
            }
            let (directory, images) = try fixture("success")
            let service = ClipboardHistoryService(initialEntries: [pinned, recent, files],
                selectedIDs: [recent.id, pinned.id], fixtureDirectory: directory)
            expect(!manager.fileExists(atPath: directory.appendingPathComponent("ClipboardHistory.json").path), "persist fixture initialization does not write")
            service.clearRecent()
            expect(drain(service), "coalesced persist and main cleanup complete before deadline")
            expect(try read(directory) == [pinned], "persisted JSON retains exact pinned metadata")
            expect(try Data(contentsOf: images.appendingPathComponent("pinned.png")) == png, "fixed image bytes survive cleanup")
            expect(!manager.fileExists(atPath: images.appendingPathComponent("recent.png").path), "unfixed image swept after successful JSON")
            expect(try Data(contentsOf: external) == original, "external referenced file remains unchanged")
            expect(service.quickBatchEntryIDs == [pinned.id], "persist mutation retains only valid batch selection")

            let (failedDirectory, failedImages) = try fixture("failed")
            let blocked = failedDirectory.appendingPathComponent("ClipboardHistory.json", isDirectory: true)
            try manager.createDirectory(at: blocked, withIntermediateDirectories: true)
            try original.write(to: blocked.appendingPathComponent("prevent-replacement"))
            let failed = ClipboardHistoryService(initialEntries: [pinned, recent], selectedIDs: [], fixtureDirectory: failedDirectory)
            failed.clearRecent()
            expect(drain(failed), "failed persistence queue drains before deadline")
            expect(manager.fileExists(atPath: blocked.appendingPathComponent("prevent-replacement").path), "write failure preserves blocking target")
            expect(try Data(contentsOf: failedImages.appendingPathComponent("recent.png")) == png, "write failure does not sweep uncommitted image")
            expect(try Data(contentsOf: failedImages.appendingPathComponent("pinned.png")) == png, "write failure preserves pinned image")

            let (flushDirectory, _) = try fixture("flush")
            let flush = ClipboardHistoryService(initialEntries: [pinned, recent], selectedIDs: [], fixtureDirectory: flushDirectory)
            flush.clearRecent()
            flush.flushBeforeTermination()
            expect(try read(flushDirectory) == [pinned], "termination flush lands JSON before returning without runloop")
            expect(drain(flush), "flush pending callbacks drained before fixture removal")

            let (raceDirectory, raceImages) = try fixture("race")
            let race = ClipboardHistoryService(initialEntries: [pinned, recent], selectedIDs: [], fixtureDirectory: raceDirectory)
            race.clearRecent()
            race.flushBeforeTermination()
            let release = race.holdPersistenceForFixture()
            do {
                defer { release() }
                race.remove(pinned)
                var marker = false
                DispatchQueue.main.async { marker = true }
                let deadline = Date().addingTimeInterval(2)
                while !marker && Date() < deadline {
                    _ = RunLoop.main.run(mode: .default, before: min(deadline, Date().addingTimeInterval(0.01)))
                }
                expect(marker && Date() < deadline, "race reaches main marker before write gate timeout")
                expect(try read(raceDirectory) == [pinned], "race disk still contains last committed image entry")
                expect(manager.fileExists(atPath: raceImages.appendingPathComponent("pinned.png").path),
                       "old completion cannot sweep image referenced by committed JSON")
            }
            race.flushBeforeTermination()
            expect(drain(race), "released race writes and cleanup finish")
            expect(try read(raceDirectory).isEmpty, "released race commits newest empty history")
            expect(!manager.fileExists(atPath: raceImages.appendingPathComponent("pinned.png").path),
                   "latest successful race commit cleans now-unreferenced image")

            let (latestDirectory, _) = try fixture("latest")
            let latest = ClipboardHistoryService(initialEntries: [pinned, recent], selectedIDs: [], fixtureDirectory: latestDirectory)
            latest.clearRecent()
            latest.flushBeforeTermination()
            latest.remove(pinned)
            expect(drain(latest), "successive mutation queue and cleanup drain")
            expect(try read(latestDirectory).isEmpty, "successive persistence ends with latest JSON")
            expect(latest.entries.isEmpty, "old persistence completion does not restore removed entries")
        } catch { expect(false, "persistence fixture error: \(type(of: error))") }
    }
}
#endif
