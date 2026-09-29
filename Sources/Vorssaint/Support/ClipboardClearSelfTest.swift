// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

#if VORSSAINT_DEVELOPMENT
import Foundation

/// Tests real service mutations with an in-memory persistence sink. Does not
/// initialize the shared service, read preferences, access the pasteboard, or
/// exercise asynchronous file persistence and image cleanup.
enum ClipboardClearSelfTest {
    static func run(_ expect: (Bool, String) -> Void) {
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        let pinnedText = ClipboardHistoryEntry(text: "pinned text", copiedAt: date, pinnedAt: date)
        let pinnedImage = ClipboardHistoryEntry(text: "", copiedAt: date, pinnedAt: date,
                                                kind: .image, imageFile: "fixture-only.png",
                                                imageHash: "fixture", imageWidth: 4, imageHeight: 3)
        let pinnedFiles = ClipboardHistoryEntry(text: "", copiedAt: date, pinnedAt: date,
                                                kind: .files, filePaths: ["/fixture-only/file.txt"])
        let recentText = ClipboardHistoryEntry(text: "recent text", copiedAt: date)
        let recentImage = ClipboardHistoryEntry(text: "", copiedAt: date, kind: .image,
                                                imageFile: "never-read.png", imageHash: "fixture-2")
        let recentFiles = ClipboardHistoryEntry(text: "", copiedAt: date, kind: .files,
                                                filePaths: ["/fixture-only/recent.txt"])
        let staleID = UUID()
        let fixtures: [(String, [ClipboardHistoryEntry], Set<UUID>, [ClipboardHistoryEntry], Set<UUID>)] = [
            ("mixed", [recentText, pinnedImage, recentImage, pinnedText, recentFiles, pinnedFiles],
             [recentText.id, pinnedText.id, pinnedFiles.id, staleID],
             [pinnedImage, pinnedText, pinnedFiles], [pinnedText.id, pinnedFiles.id]),
            ("only pinned", [pinnedFiles, pinnedText, pinnedImage],
             [pinnedImage.id, staleID], [pinnedFiles, pinnedText, pinnedImage], [pinnedImage.id]),
            ("empty", [], [staleID], [], []),
            ("only recent", [recentText, recentImage, recentFiles],
             [recentText.id, recentFiles.id], [], [])
        ]
        let missing = ClipboardHistoryEntry(text: "", kind: .files,
                                            filePaths: ["/ux63-fixture-does-not-exist/file.txt"])
        let failedCopy = ClipboardHistoryService(initialEntries: [missing], selectedIDs: [missing.id]) { _ in }
        failedCopy.copyOnlyQuickEntry(missing)
        expect(failedCopy.quickBatchEntryIDs == [missing.id],
               "failed quick copy preserves selection for recovery")
        expect(failedCopy.actionMessage != nil, "failed quick copy reports recovery guidance")
        let selection = ClipboardHistoryService(initialEntries: [recentText, recentImage, recentFiles], selectedIDs: []) { _ in }
        selection.selectQuickEntry(recentImage)
        expect(selection.selectedQuickEntryID == recentImage.id && selection.quickSelectionIsVisible,
               "single click selects the inspected target")
        selection.move(recentImage, .up)
        expect(selection.selectedQuickEntryID == recentImage.id,
               "reordering retains the inspected object")
        selection.moveQuickSelection(1)
        expect(selection.selectedQuickEntryID == recentText.id,
               "keyboard advances from the same inspected target after reorder")
        let hiddenSelection = ClipboardHistoryService(initialEntries: [recentText, recentImage], selectedIDs: []) { _ in }
        hiddenSelection.toggleQuickBatchSelection(recentImage)
        hiddenSelection.move(recentImage, .up)
        hiddenSelection.moveQuickSelection(1)
        expect(hiddenSelection.selectedQuickEntryID == recentImage.id,
               "revealing keyboard selection resolves the retained ID after reorder")
        let snapshotClear = ClipboardHistoryService(initialEntries: [pinnedText, recentText, recentImage], selectedIDs: []) { _ in }
        snapshotClear.clearRecent(confirmedIDs: [pinnedText.id, recentText.id])
        expect(snapshotClear.entries == [pinnedText, recentImage],
               "confirmation clears only counted IDs and preserves pinned or unconfirmed records")
        for (name, input, selected, remaining, remainingSelection) in fixtures {
            var snapshots: [[ClipboardHistoryEntry]] = []
            let service = ClipboardHistoryService(initialEntries: input, selectedIDs: selected) {
                snapshots.append($0)
            }
            expect(snapshots.isEmpty, "clear \(name): initialization does not persist")
            service.clearRecent()
            expect(service.entries == remaining, "clear \(name): exact retained entries, metadata and order")
            expect(service.quickBatchEntryIDs == remainingSelection,
                   "clear \(name): batch selection retains only surviving IDs")
            expect(snapshots == [remaining], "clear \(name): one save receives the retained snapshot")
            service.clearRecent()
            expect(service.entries == remaining && service.quickBatchEntryIDs == remainingSelection
                   && snapshots == [remaining, remaining], "clear \(name): repeated clear stays safe")
        }
    }
}
#endif
