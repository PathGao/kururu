// SPDX-License-Identifier: GPL-3.0-or-later
import AppKit
import SwiftUI

enum PlainTextEditorLifecycleTests {
    private final class UndoTextView: NSTextView {
        let localUndo = UndoManager()
        override var undoManager: UndoManager? { localUndo }
    }
    private final class UndoTarget: NSObject { var value = 0 }

    @MainActor static func run(_ expect: (Bool, String) -> Void) {
        var oldText = "same", newText = "same"
        var oldSelection: Range<Int>?, newSelection: Range<Int>?
        let first = PlainTextEditor(text: Binding(get: { oldText }, set: { oldText = $0 }),
                                    selectedRange: Binding(get: { oldSelection }, set: { oldSelection = $0 }))
        let second = PlainTextEditor(text: Binding(get: { newText }, set: { newText = $0 }),
                                     selectedRange: Binding(get: { newSelection }, set: { newSelection = $0 }))
        let coordinator = first.makeCoordinator()
        let scroll = NSTextView.scrollableTextView()
        let editor = scroll.documentView as! NSTextView
        editor.string = "same"
        second.update(scroll, coordinator: coordinator)
        editor.string = "changed"
        editor.setSelectedRange(NSRange(location: 2, length: 0))
        coordinator.textDidChange(Notification(name: NSText.didChangeNotification, object: editor))
        expect(oldText == "same", "rebound editor never writes old text binding")
        expect(newText == "changed", "same-string update refreshes active text binding")
        expect(oldSelection == nil && newSelection == 2..<2, "same-string update refreshes selection binding")
        var oldDestroyed = 0, newDestroyed = 0
        var destroyedCorrectEditor = false
        var markedText = "replacement", markedSelection: Range<Int>?
        let before = PlainTextEditor(text: .constant("initial"), onDestroy: { _ in oldDestroyed += 1 })
        let markedCoordinator = before.makeCoordinator()
        let markedScroll = NSTextView.scrollableTextView()
        let markedEditor = markedScroll.documentView as! NSTextView
        markedEditor.string = "initial"
        markedEditor.setMarkedText("入力", selectedRange: NSRange(location: 2, length: 0),
                                   replacementRange: NSRange(location: 0, length: 7))
        expect(markedEditor.hasMarkedText(), "fixture has real AppKit marked text")
        let composition = markedEditor.string
        let latest = PlainTextEditor(text: Binding(get: { markedText }, set: { markedText = $0 }),
                                     selectedRange: Binding(get: { markedSelection }, set: { markedSelection = $0 }),
                                     onDestroy: { view in
                                         destroyedCorrectEditor = view === markedEditor
                                         newDestroyed += 1
                                     })
        latest.update(markedScroll, coordinator: markedCoordinator)
        expect(markedEditor.string == composition && markedEditor.hasMarkedText(), "binding refresh leaves active composition untouched")
        markedCoordinator.textDidChange(Notification(name: NSText.didChangeNotification, object: markedEditor))
        expect(markedText == composition, "marked-text early return still refreshes binding")
        markedEditor.delegate = markedCoordinator
        PlainTextEditor.dismantleNSView(markedScroll, coordinator: markedCoordinator)
        PlainTextEditor.dismantleNSView(markedScroll, coordinator: markedCoordinator)
        expect(markedEditor.delegate == nil, "dismantle clears native delegate")
        expect(destroyedCorrectEditor, "destroy callback receives actual editor")
        expect(oldDestroyed == 0 && newDestroyed == 1, "latest destruction callback fires exactly once")
        let savedText = markedText, savedSelection = markedSelection
        markedEditor.unmarkText()
        markedEditor.string = "late notification"
        markedEditor.setSelectedRange(NSRange(location: 1, length: 0))
        markedCoordinator.textDidChange(Notification(name: NSText.didChangeNotification, object: markedEditor))
        markedCoordinator.textViewDidChangeSelection(Notification(name: NSTextView.didChangeSelectionNotification, object: markedEditor))
        expect(markedText == savedText && markedSelection == savedSelection, "late text and selection notifications are inert")
        latest.update(markedScroll, coordinator: markedCoordinator)
        expect(!markedCoordinator.isActive && markedEditor.string == "late notification", "update cannot resurrect dismantled coordinator")
        let undoEditor = UndoTextView(frame: .zero)
        let undoScroll = NSScrollView()
        undoScroll.documentView = undoEditor
        undoEditor.string = "identical"
        let firstDocument = PlainTextEditor(text: .constant("identical"), documentID: "pad-a")
        let undoCoordinator = firstDocument.makeCoordinator()
        firstDocument.update(undoScroll, coordinator: undoCoordinator)
        let target = UndoTarget()
        undoEditor.localUndo.registerUndo(withTarget: target) { $0.value = 1 }
        expect(undoEditor.localUndo.canUndo, "fixture registers actual undo action")
        firstDocument.update(undoScroll, coordinator: undoCoordinator)
        expect(undoEditor.localUndo.canUndo, "same document layout update retains undo")
        let secondDocument = PlainTextEditor(text: .constant("identical"), documentID: "pad-b")
        secondDocument.update(undoScroll, coordinator: undoCoordinator)
        expect(!undoEditor.localUndo.canUndo, "different document with identical text clears old undo")
    }
}
