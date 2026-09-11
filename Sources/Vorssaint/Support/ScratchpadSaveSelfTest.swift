// SPDX-License-Identifier: GPL-3.0-or-later
#if VORSSAINT_DEVELOPMENT
import Foundation

enum ScratchpadSaveSelfTest {
    static func run(_ expect: (Bool, String) -> Void) {
        let fm = FileManager.default
        let root = fm.temporaryDirectory.appendingPathComponent("kururu-scratchpad-save-\(UUID())", isDirectory: true)
        let suite = "com.vorssaint.tests.scratchpad-save.\(UUID())"
        guard let defaults = UserDefaults(suiteName: suite) else {
            expect(false, "scratchpad save fixture suite created")
            return
        }
        defaults.set("never", forKey: DefaultsKey.scratchpadRetention)
        defer {
            defaults.removePersistentDomain(forName: suite)
            try? fm.removeItem(at: root)
        }
        let date = Date(timeIntervalSince1970: 1_000)
        let first = ScratchpadPad(id: UUID(), name: "First", text: "Saved first", modifiedAt: date)
        let second = ScratchpadPad(id: UUID(), name: "Second", text: "Saved second", modifiedAt: date)
        let original = ScratchpadDocument(pads: [first, second], selectedID: first.id)
        func index(_ directory: URL) -> URL { directory.appendingPathComponent("Scratchpad.json") }
        func read(_ directory: URL) throws -> ScratchpadDocument {
            try JSONDecoder().decode(ScratchpadDocument.self, from: Data(contentsOf: index(directory)))
        }
        func fixture(_ name: String) throws -> URL {
            let directory = root.appendingPathComponent(name, isDirectory: true)
            try fm.createDirectory(at: directory, withIntermediateDirectories: true)
            try JSONEncoder().encode(original).write(to: index(directory))
            return directory
        }
        func block(_ directory: URL) throws {
            try fm.removeItem(at: index(directory))
            try fm.createDirectory(at: index(directory), withIntermediateDirectories: false)
            try Data("keep blocker".utf8).write(to: index(directory).appendingPathComponent("block"))
        }
        func recover(_ directory: URL) throws {
            try fm.removeItem(at: index(directory))
            try JSONEncoder().encode(original).write(to: index(directory))
        }
        func unchanged(_ service: ScratchpadService) -> Bool {
            service.pads == original.pads && service.selectedPadID == first.id && service.text == first.text
        }
        do {
            let directory = try fixture("edited")
            let service = ScratchpadService(fixtureDirectory: directory, defaults: defaults)
            defer { service.prepareForSettingsRestore() }
            service.prepareForSettingsBackup()
            expect(unchanged(service) && service.saveIssue == nil, "save fixture loads clean durable document")
            service.text = "Unsaved 中文 edit"
            let editedPads = service.pads
            expect(try read(directory) == original, "text edit remains pending before explicit flush")
            try block(directory)
            service.hide()
            expect(service.saveIssue == .unsavedChanges, "failed hide save exposes unsaved changes")
            expect(service.pads == editedPads && service.text == "Unsaved 中文 edit" && service.selectedPadID == first.id,
                   "failed hide preserves complete live edit and selection")
            expect(!service.prepareForTermination(), "termination refuses to discard an unsaved edit")
            expect(!service.retrySave() && service.saveIssue == .unsavedChanges,
                   "retry against blocked destination remains visibly unsuccessful")
            expect(try Data(contentsOf: index(directory).appendingPathComponent("block")) == Data("keep blocker".utf8),
                   "failed saves leave destination blocker untouched")
            try recover(directory)
            expect(service.retrySave() && service.saveIssue == nil, "recovered retry succeeds and clears issue")
            let durable = try read(directory)
            expect(durable.pads == editedPads && durable.selectedID == first.id,
                   "retry durably writes exact pending document")
            expect(service.prepareForTermination(), "termination succeeds after pending edit becomes durable")
            let reopened = ScratchpadService(fixtureDirectory: directory, defaults: defaults)
            defer { reopened.prepareForSettingsRestore() }
            reopened.prepareForSettingsBackup()
            expect(reopened.pads == editedPads && reopened.text == service.text && reopened.selectedPadID == first.id,
                   "fresh service restores retried edit and selection")

            for action in ["create", "select", "rename", "close"] {
                let target = try fixture(action)
                let subject = ScratchpadService(fixtureDirectory: target, defaults: defaults)
                defer { subject.prepareForSettingsRestore() }
                subject.prepareForSettingsBackup()
                try block(target)
                func perform() -> Bool {
                    switch action {
                    case "create": subject.createPad(defaultName: "Created"); return subject.pads.count == 3
                    case "select": subject.selectPad(second.id); return subject.selectedPadID == second.id
                    case "rename": return subject.renamePad(first.id, to: "Renamed")
                    default: return subject.closePad(second.id)
                    }
                }
                expect(!perform(), "failed \(action) does not report success")
                expect(subject.saveIssue == .operationFailed, "clean failed \(action) exposes operation failure")
                expect(unchanged(subject), "failed \(action) preserves pads, selection and text")
                try recover(target)
                expect(subject.retrySave(), "current-document retry succeeds after failed \(action)")
                expect(try read(target) == original && unchanged(subject),
                       "save retry cannot silently execute previously failed \(action)")
                expect(perform(), "explicit \(action) succeeds after destination recovery")
                let result = try read(target)
                expect(result.pads == subject.pads && result.selectedID == subject.selectedPadID && result != original,
                       "successful \(action) publishes the durable changed document")
                switch action {
                case "create":
                    expect(Array(result.pads.prefix(2)) == original.pads && result.pads.last?.text == ""
                           && result.selectedID == result.pads.last?.id, "create preserves existing pads and selects new empty pad")
                case "select":
                    expect(result.pads == original.pads && result.selectedID == second.id && subject.text == second.text,
                           "select changes only selection and displayed text")
                case "rename":
                    expect(result.pads.first?.name == "Renamed" && result.pads.first?.text == first.text
                           && result.pads.last == second && result.selectedID == first.id,
                           "rename preserves text, other pad and selection")
                default:
                    expect(result.pads == [first] && result.selectedID == first.id && subject.text == first.text,
                           "close removes only requested pad")
                }
                expect(subject.saveIssue == nil, "successful \(action) clears prior save issue")
                subject.hide()
                expect(try read(target) == result, "hide preserves successful \(action) result")
            }

            let dirtyDirectory = try fixture("dirty-transaction")
            let dirty = ScratchpadService(fixtureDirectory: dirtyDirectory, defaults: defaults)
            defer { dirty.prepareForSettingsRestore() }
            dirty.prepareForSettingsBackup()
            dirty.text = "Pending edit before rename"
            let dirtyPads = dirty.pads
            try block(dirtyDirectory)
            expect(!dirty.renamePad(first.id, to: "Not committed") && dirty.saveIssue == .unsavedChanges,
                   "failed transaction prioritizes unsaved text over operation-only message")
            expect(dirty.pads == dirtyPads && dirty.selectedPadID == first.id && dirty.text == "Pending edit before rename",
                   "failed dirty transaction preserves edit without publishing rename")
            dirty.prepareForSettingsRestore()
            expect(dirty.saveIssue == nil, "settings restore clears stale save issue")
            try recover(dirtyDirectory)
            dirty.hide()
            expect(dirty.prepareForTermination(), "restored unloaded service does not block termination for stale edit")
            expect(try read(dirtyDirectory) == original, "restore, hide and termination cannot overwrite replacement JSON")
            dirty.prepareForSettingsBackup()
            expect(unchanged(dirty) && dirty.saveIssue == nil, "settings restore reloads replacement data with no stale issue")
        } catch { expect(false, "scratchpad save fixture failed: \(error)") }
    }
}
#endif
