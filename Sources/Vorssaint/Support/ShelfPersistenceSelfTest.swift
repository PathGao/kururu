// SPDX-License-Identifier: GPL-3.0-or-later
#if VORSSAINT_DEVELOPMENT
import Foundation

enum ShelfPersistenceSelfTest {
    static func run(_ expect: (Bool, String) -> Void) {
        let fm = FileManager.default
        let root = fm.temporaryDirectory.appendingPathComponent("kururu-shelf-persistence-\(UUID())", isDirectory: true)
        let suiteName = "com.vorssaint.tests.shelf-persistence.\(UUID())"
        guard let defaults = UserDefaults(suiteName: suiteName) else { expect(false,"shelf fixture suite created");return }
        defer { defaults.removePersistentDomain(forName:suiteName) }
        func wait(_ condition: () -> Bool) -> Bool {
            let deadline = Date().addingTimeInterval(5)
            while !condition() && Date() < deadline {
                _ = RunLoop.main.run(mode:.default,before:min(deadline,Date().addingTimeInterval(0.01)))
            }
            return condition()
        }
        func drain(_ service: ShelfService) -> Bool {
            var done = false
            service.whenPersistenceDrained { done = true }
            return wait { done }
        }
        func index(_ directory: URL) -> URL { directory.appendingPathComponent("ShelfItems.json") }
        func read(_ directory: URL) throws -> [ShelfPersistedItem] {
            let loaded = ShelfPersistenceSupport.load(try Data(contentsOf: index(directory)))
            guard case let .items(records) = loaded else { throw ShelfIndexError.unreadable }
            return records
        }
        func fixture(_ name: String) throws -> URL {
            let directory = root.appendingPathComponent(name,isDirectory:true)
            try fm.createDirectory(at:directory.appendingPathComponent("ShelfFiles"),withIntermediateDirectories:true)
            return directory
        }
        let text = ShelfPersistedItem(id:UUID(),kind:.text,title:"kept",text:"original")
        let newer = ShelfPersistedItem(id:UUID(),kind:.text,title:"new",text:"new content")
        do {
            try fm.createDirectory(at:root,withIntermediateDirectories:true)
            defer { try? fm.removeItem(at:root) }
            let roundtripDirectory = try fixture("roundtrip")
            func fileRecord(_ name: String, title: String) throws -> ShelfPersistedItem {
                let file = roundtripDirectory.appendingPathComponent("ShelfFiles/\(name)")
                try Data("roundtrip payload \(name)".utf8).write(to:file)
                return ShelfPersistedItem(id:UUID(),kind:.file,title:title,path:file.path,
                                          bookmark:try file.bookmarkData())
            }
            let roundtripRecords = [
                ShelfPersistedItem(id:UUID(),kind:.batch,title:"Custom group",children:[
                    ShelfPersistedItem(id:UUID(),kind:.text,title:"",text:"First line\nSecond line"),
                    ShelfPersistedItem(id:UUID(),kind:.link,title:"",url:"https://example.com/empty-title"),
                    try fileRecord("empty-title.txt",title:""),
                ]),
                ShelfPersistedItem(id:UUID(),kind:.batch,title:"Custom single group",children:[
                    ShelfPersistedItem(id:UUID(),kind:.text,title:"Custom note",text:"Single child content"),
                ]),
                ShelfPersistedItem(id:UUID(),kind:.batch,title:"Custom outer group",children:[
                    ShelfPersistedItem(id:UUID(),kind:.batch,title:"Custom inner group",children:[
                        ShelfPersistedItem(id:UUID(),kind:.link,title:"Custom link",url:"https://example.com/custom-title?q=1#fragment"),
                        try fileRecord("named.txt",title:"Custom file"),
                    ]),
                    ShelfPersistedItem(id:UUID(),kind:.text,title:"Nested note",text:"Nested content"),
                ]),
            ]
            try JSONEncoder().encode(roundtripRecords).write(to:index(roundtripDirectory))
            for launch in 1...2 {
                let service = ShelfService(fixtureDirectory:roundtripDirectory,legacyDefaults:defaults)
                service.flushBeforeTermination()
                expect(service.hasRestoredForFixture && service.persistenceIssue == nil,
                       "roundtrip launch \(launch) restores and flushes successfully")
                expect(try read(roundtripDirectory) == roundtripRecords,
                       "roundtrip launch \(launch) preserves every ID, title, tree and payload")
                expect(drain(service), "roundtrip launch \(launch) late callbacks drain")
            }

            let partialDirectory = try fixture("partial")
            let partialAsset = partialDirectory.appendingPathComponent("ShelfFiles/unknown.png")
            let assetBytes = Data("private fixture payload".utf8)
            try assetBytes.write(to:partialAsset)
            let row = try JSONSerialization.jsonObject(with:JSONEncoder().encode(text))
            let partialData = try JSONSerialization.data(withJSONObject:[row,["id":UUID().uuidString,"kind":"future","title":"unknown","path":partialAsset.path]])
            try partialData.write(to:index(partialDirectory))
            let partial = ShelfService(fixtureDirectory:partialDirectory,legacyDefaults:defaults)
            expect(wait { partial.hasRestoredForFixture } && drain(partial), "partial restore and queued work finish")
            expect(try Data(contentsOf:index(partialDirectory)) == partialData, "partial restore leaves original JSON bytes")
            if case .unreadable? = partial.persistenceIssue { expect(true,"partial raises unreadable issue") }
            else { expect(false,"partial raises unreadable issue") }
            partial.replaceItemsForFixture([newer])
            partial.cleanupForFixture(ShelfPayloadCleanup.capture([partialAsset],roots:[partialDirectory.appendingPathComponent("ShelfFiles")]))
            expect(drain(partial), "partial postmutation drain finishes")
            expect(try Data(contentsOf:index(partialDirectory)) == partialData, "partial mutation cannot overwrite unknown data")
            expect(try Data(contentsOf:partialAsset) == assetBytes, "partial state cannot delete owned asset")
            partial.flushBeforeTermination()

            let migrationDirectory = try fixture("migration")
            defaults.set(try JSONEncoder().encode([text]),forKey:"shelfItems")
            let migration = ShelfService(fixtureDirectory:migrationDirectory,legacyDefaults:defaults)
            expect(wait { migration.hasRestoredForFixture } && drain(migration), "legacy restore migration drains")
            expect(try read(migrationDirectory) == [text], "legacy blob moves to exact atomic JSON")
            expect(defaults.object(forKey:"shelfItems") == nil, "legacy blob retired after JSON success")
            migration.replaceItemsForFixture([text,newer])
            expect(drain(migration), "current mutation persistence drains")
            expect(try read(migrationDirectory) == [text,newer], "current records persist in order")
            migration.flushBeforeTermination()

            let failureDirectory = try fixture("failure")
            let ownedRoot = failureDirectory.appendingPathComponent("ShelfFiles")
            let asset = ownedRoot.appendingPathComponent("owned.png")
            try assetBytes.write(to:asset)
            let record = ShelfPersistedItem(id:UUID(),kind:.file,title:"asset",path:asset.path)
            try JSONEncoder().encode([record]).write(to:index(failureDirectory))
            let failing = ShelfService(fixtureDirectory:failureDirectory,legacyDefaults:defaults)
            expect(wait { failing.hasRestoredForFixture } && drain(failing), "file restore drains before failure test")
            let candidates = ShelfPayloadCleanup.capture([asset],roots:[ownedRoot])
            try fm.removeItem(at:index(failureDirectory))
            try fm.createDirectory(at:index(failureDirectory),withIntermediateDirectories:false)
            try assetBytes.write(to:index(failureDirectory).appendingPathComponent("block"))
            failing.replaceItemsForFixture([])
            expect(drain(failing), "failed index write completes")
            if case .saveFailed? = failing.persistenceIssue { expect(true,"failed atomic write exposes saveFailed") }
            else { expect(false,"failed atomic write exposes saveFailed") }
            failing.cleanupForFixture(candidates)
            expect(try Data(contentsOf:asset) == assetBytes, "failed save blocks deletion of durable owned asset")
            try fm.removeItem(at:index(failureDirectory))
            failing.retryPersistence()
            expect(drain(failing), "retry persistence completes")
            expect(try read(failureDirectory).isEmpty, "retry commits intended empty index")
            expect(!fm.fileExists(atPath:asset.path), "retry success finally cleans retired owned asset")
            expect(failing.persistenceIssue == nil, "successful retry clears issue")
            failing.flushBeforeTermination()

            let referenceDirectory = try fixture("reference")
            let referenceRoot = referenceDirectory.appendingPathComponent("ShelfFiles")
            let referencedAsset = referenceRoot.appendingPathComponent("again.png")
            try assetBytes.write(to:referencedAsset)
            let referencedRecord = ShelfPersistedItem(id:UUID(),kind:.file,title:"again",path:referencedAsset.path)
            try JSONEncoder().encode([referencedRecord]).write(to:index(referenceDirectory))
            let referenced = ShelfService(fixtureDirectory:referenceDirectory,legacyDefaults:defaults)
            expect(wait { referenced.hasRestoredForFixture } && drain(referenced), "reference fixture restoration drains")
            let retired = ShelfPayloadCleanup.capture([referencedAsset],roots:[referenceRoot])
            referenced.replaceItemsForFixture([])
            referenced.replaceItemsForFixture([referencedRecord])
            expect(drain(referenced), "readded reference becomes durable")
            referenced.cleanupForFixture(retired)
            expect(try Data(contentsOf:referencedAsset) == assetBytes, "stale retirement preserves readded reference")
            referenced.flushBeforeTermination()

            let startupDirectory = try fixture("startup-flush")
            defaults.set(try JSONEncoder().encode([text]),forKey:"shelfItems")
            let startup = ShelfService(fixtureDirectory:startupDirectory,legacyDefaults:defaults)
            startup.replaceItemsForFixture([newer])
            startup.flushBeforeTermination()
            expect(try read(startupDirectory) == [text,newer], "startup flush merges restored and early live records without runloop")
            expect(defaults.object(forKey:"shelfItems") == nil, "startup flush retires migrated legacy blob")
            expect(drain(startup), "late startup callbacks drain after termination flush")
            expect(try read(startupDirectory) == [text,newer], "late startup callbacks cannot overwrite flushed index")
            let capacityDirectory = try fixture("startup-capacity")
            let full = (0..<ShelfPersistenceSupport.maxLeaves).map { index in
                ShelfPersistedItem(id:UUID(),kind:.text,title:"Old \(index)",text:"old content \(index)")
            }
            let fullData = try JSONEncoder().encode(full)
            defaults.set(fullData,forKey:"shelfItems")
            let capacity = ShelfService(fixtureDirectory:capacityDirectory,legacyDefaults:defaults)
            capacity.replaceItemsForFixture([newer])
            capacity.flushBeforeTermination()
            expect(capacity.itemCount == full.count + 1, "startup capacity preserves all old and early live items in memory")
            if case .tooLarge? = capacity.persistenceIssue { expect(true,"startup capacity reports tooLarge") }
            else { expect(false,"startup capacity reports tooLarge") }
            expect(defaults.data(forKey:"shelfItems") == fullData, "startup capacity preserves exact legacy bytes")
            expect(!fm.fileExists(atPath:index(capacityDirectory).path), "startup capacity does not publish truncated JSON")
            expect(drain(capacity), "startup capacity late callbacks drain")
            expect(defaults.data(forKey:"shelfItems") == fullData
                   && !fm.fileExists(atPath:index(capacityDirectory).path)
                   && capacity.itemCount == full.count + 1, "late capacity callbacks preserve both memory and original durable blob")
            let removalDirectory = try fixture("removal-stop")
            let removalBlob = try JSONEncoder().encode([text])
            defaults.set(removalBlob,forKey:"shelfItems")
            let removal = ShelfService(fixtureDirectory:removalDirectory,legacyDefaults:defaults)
            removal.replaceItemsForFixture([newer])
            removal.stopPersistenceForRemoval()
            expect(defaults.data(forKey:"shelfItems") == removalBlob, "removal stop does not migrate pending legacy restore")
            try fm.removeItem(at:removalDirectory)
            removal.flushBeforeTermination()
            expect(!fm.fileExists(atPath:removalDirectory.path), "post-removal flush cannot recreate fixture directory")
            expect(drain(removal), "removal late callbacks drain")
            expect(!fm.fileExists(atPath:removalDirectory.path) && !removal.isSaving,
                   "late callbacks keep removed storage absent and saving inactive")
        } catch { expect(false,"shelf persistence fixture failed: \(error)") }
    }
}
#endif
