// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import AppKit

/// Production destination methods run against controlled delivery results.
/// Native transport and payload integrity have separate transfer tests.
enum ShelfDropRoutingContract {
    enum AppFeature {
        static var shelf = Feature()
        struct Feature { var isAvailable = true }
    }
    enum UserDefaults {
        static var standard = Store()
        struct Store {
            var enabled = true
            func bool(forKey key: String) -> Bool { enabled }
        }
    }
    final class Window {}
    struct NSDraggingInfo {
        let draggingPasteboard: NSPasteboard
        let draggingDestinationWindow: Window?
    }
    class ShelfState {
        var dockedPanel = Window()
        var dockCompletions = 0
        var promises: [Int] = []
        var ordinaryItems: [String] = []
        var accepts = true
        var ordinaryAccepts = 0
        var promisedAccepts = 0
        var deliveredItems: [String] = []
        func filePromiseReceivers(from board: NSPasteboard) -> [Int] { promises }
        func nonPromisedItems(from board: NSPasteboard) -> (items: [String], positions: [Int], promises: [Int]) { (ordinaryItems, [0, 2], [1, 3]) }
        func accept(pasteboard: NSPasteboard) -> Bool { ordinaryAccepts += 1; return accepts }
        func beginPromisedFileReceive(_ receivers: [Int], additions: [String], companionPositions: [Int], promisePositions: [Int], mergeInto target: UUID?) -> Bool {
            promisedAccepts += 1
            deliveredItems = additions
            return accepts
        }
        func dockDidAccept() { dockCompletions += 1 }
    }

}

enum ShelfDropRoutingTests {
    private typealias Context = ShelfDropRoutingContract

    static func run(expect: (Bool, String) -> Void) {
        expect(ShelfPasteboardSupport.mergedItemIndices(companionPositions: [1, 3],
               receiverIndices: [0, 1], promisePositions: [0, 2]) == [2, 0, 3, 1],
               "mixed ordinary and promised items retain pasteboard order")
        expect(ShelfPasteboardSupport.mergedItemIndices(companionPositions: [1],
               receiverIndices: [0, 0], promisePositions: [0]) == [1, 2, 0],
               "multi-file legacy receiver retains internal order before its ordinary companion")
        let board = NSPasteboard.withUniqueName()
        defer { board.releaseGlobally() }
        for promised in [false, true] {
            for accepted in [false, true] {
                Context.AppFeature.shelf.isAvailable = true
                Context.UserDefaults.standard.enabled = true
                Context.ShelfService.shared = Context.ShelfService()
                let shelf = Context.ShelfService.shared
                shelf.promises = promised ? [1, 2] : []
                shelf.ordinaryItems = ["file", "note"]
                shelf.accepts = accepted
                expect(shelf.acceptDrop(pasteboard: board) == accepted,
                       "native destination reports the actual shelf admission result")
                expect(shelf.promisedAccepts == (promised ? 1 : 0)
                       && shelf.ordinaryAccepts == (promised ? 0 : 1),
                       "promised attachments use native delivery, ordinary drops keep their path")
                expect(!promised || shelf.deliveredItems == ["file", "note"],
                       "mixed drops retain ordinary companions")
                let dockDrop = Context.NSDraggingInfo(draggingPasteboard: board,
                                                     draggingDestinationWindow: shelf.dockedPanel)
                expect(shelf.accept(draggingInfo: dockDrop) == accepted
                       && shelf.dockCompletions == (accepted ? 1 : 0),
                       "the separate dock keeps its completion behavior through the shared receiver")
            }
        }
        for disabled in [false, true] {
            Context.AppFeature.shelf.isAvailable = !disabled
            Context.UserDefaults.standard.enabled = disabled
            Context.ShelfService.shared = Context.ShelfService()
            let shelf = Context.ShelfService.shared
            shelf.promises = [1]
            expect(!shelf.acceptDrop(pasteboard: board) && shelf.promisedAccepts == 0,
                   "disabled shelf rejects delayed drops")
        }
    }
}
