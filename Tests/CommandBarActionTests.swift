// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import Foundation

enum CommandBarActionTests {
    static func run(_ expect: (Bool, String) -> Void) {
        var events: [String] = []
        var query = "changed while browsing actions"
        let savedQuery = "brightness 40"
        let primary = CommandBarRowAction.primary(title: "Open Example", restoreSearch: {
            query = savedQuery
            events.append("restore")
        }, run: { events.append("dispatch:" + query) })
        let quit = CommandBarRowAction(id: "quit", title: "Quit", symbolName: "xmark", group: .operation) {
            events.append("quit")
        }
        let pin = CommandBarRowAction(id: "pin", title: "Pin", symbolName: "pin") {}
        let restart = CommandBarRowAction(id: "restart", title: "Restart", symbolName: "arrow.clockwise", group: .operation) {}
        let hide = CommandBarRowAction(id: "hide", title: "Hide", symbolName: "eye.slash") {}
        let menu = CommandBarRowAction.menu(primary: primary, additional: [quit, pin, restart, hide])
        expect(menu.map(\.id) == ["primary", "pin", "hide", "quit", "restart"],
               "primary precedes organization, with app operations last")
        expect(menu.map(\.group) == [.primary, .organize, .organize, .operation, .operation],
               "primary and operations are separated by the organization group")
        menu.first?.run()
        expect(events == ["restore", "dispatch:brightness 40"],
               "first action restores the exact search before dispatching once, without quitting")
        expect(CommandBarRowAction.menu(primary: primary, additional: []).map(\.id) == ["primary"],
               "a menu without secondary actions still offers its primary action")

        query = ""
        events = []
        menu.first?.run()
        expect(query == savedQuery && events == ["restore", "dispatch:brightness 40"],
               "returning from naming with an empty field restores the search before primary dispatch")
        let many = (0..<12).map { index in
            CommandBarRowAction(id: "item.\(index)", title: "Item \(index)", symbolName: "circle",
                group: index < 5 ? .operation : .organize) {}
        }
        let longMenu = CommandBarRowAction.menu(primary: primary, additional: many)
        expect(longMenu.count == 13 && Set(longMenu.map(\.id)).count == 13,
               "a long action menu retains every item exactly once")
        expect(longMenu.suffix(5).map(\.id) == (0..<5).map { "item.\($0)" },
               "operations retain their relative order at the end of a long menu")

        let cases: [(Bool, Bool, ClosedRange<Int>?, Bool, Int?, CommandBarRunDecision)] = [
            (true, true, 0...100, false, 40, .setup),
            (false, true, 0...100, false, 40, .confirm),
            (false, true, nil, false, nil, .confirm),
            (false, false, 0...100, false, nil, .argument),
            (false, false, 0...100, true, nil, .execute(nil)),
            (false, false, 0...100, false, 40, .execute(40)),
            (false, false, 0...100, false, 200, .execute(100)),
            (false, false, 0...100, false, -1, .execute(0)),
            (false, false, nil, false, 40, .execute(nil))
        ]
        for (setup, confirmation, range, optional, number, expected) in cases {
            expect(CommandBarRunDecision.resolve(needsSetup: setup, needsConfirmation: confirmation,
                numericRange: range, numericIsOptional: optional, typedNumber: number) == expected,
                "shared dispatch preserves setup, confirmation and numeric rules: \(expected)")
        }
        for (setup, confirmation, expected) in [(true, true, CommandBarRunDecision.setup),
                                               (false, true, .confirm)] {
            var executed = false
            var decision: CommandBarRunDecision?
            let guarded = CommandBarRowAction.primary(title: "Guarded", restoreSearch: {}, run: {
                decision = CommandBarRunDecision.resolve(needsSetup: setup, needsConfirmation: confirmation,
                    numericRange: nil, numericIsOptional: false, typedNumber: nil)
                if case .execute = decision { executed = true }
            })
            CommandBarRowAction.menu(primary: guarded, additional: []).first?.run()
            expect(decision == expected && !executed,
                   "primary dispatch reaches the guard without executing the protected operation: \(expected)")
        }
        var submission = CommandBarArgumentSubmission()
        for input in ["", "   ", "abc", "4.5", "-1", "40%%", "12345", "99999999999999999999"] {
            let value = submission.submit(input, in: 0...100)
            expect(value == nil && submission.isRejected,
                   "invalid argument stays unexecuted and gains visible rejection: \(input)")
            submission.reset()
            expect(!submission.isRejected, "editing or leaving the argument clears its rejection")
        }
        for (input, range, expected): (String, ClosedRange<Int>, Int) in [
            ("40", 0...100, 40), (" 35% ", 0...100, 35),
            ("140", 0...100, 100), ("0", 1...480, 1), ("9999", 0...100, 100)
        ] {
            _ = submission.submit("abc", in: range)
            expect(submission.submit(input, in: range) == expected && !submission.isRejected,
                   "valid retry uses the existing parser and range clamp: \(input)")
        }
        let english = CommandBarFeatureStrings.enUS
        let presentations: [(String, String, Bool, CommandBarRunDecision, Bool, Bool, String)] = [
            ("app.example", "Example", false, .execute(nil), true, false, "Open Example"),
            ("action.openURL", "https://example.com", false, .execute(nil), true, false, english.openInBrowser),
            ("selection.cleanLink", "Clean link", false, .execute(nil), true, false, "Clean link"),
            ("action.volume", "Volume", false, .argument, false, false, "Enter a value…"),
            ("action.volume", "Volume", false, .execute(40), false, false, "Apply 40"),
            ("action.emptyTrash", "Empty Trash", false, .confirm, false, false, "Review confirmation…"),
            ("action.emptyTrash", "Empty Trash", false, .setup, false, false, "Open Settings"),
            ("math.result", "42", true, .execute(nil), false, false, "Copy it"),
            ("answer.battery", "Battery", false, .execute(nil), false, false, "Copy it"),
            ("selection.count", "Count", false, .execute(nil), false, false, "Copy it"),
            ("clipboard.example", "Copied content", false, .execute(nil), false, false, "Paste from history"),
            ("snippet.example", "Greeting", false, .execute(nil), false, false, "Insert snippet · Greeting"),
            ("emoji.example", "Octopus", false, .execute(nil), false, false, "Insert · Octopus"),
            ("action.darkMode", "Toggle dark mode", false, .execute(nil), false, false, "Toggle dark mode"),
            ("link.example", "Search", false, .execute(nil), true, true, "Enter text…"),
            ("link.example", "Search", false, .execute(nil), true, false, "Open Search"),
            ("link.script", "Script", false, .execute(nil), false, false, "Script"),
            ("link.script", "Script result", true, .execute(nil), false, false, "Copy it")
        ]
        for (id, title, answer, decision, destination, needsText, expected) in presentations {
            expect(CommandBarActionPresentation.title(id: id, title: title, isAnswer: answer,
                decision: decision, opensDestination: destination, needsTextArgument: needsText,
                strings: english) == expected, "Return presentation follows the actual action: \(id), \(decision)")
        }
        let labels: [(AppLanguage, String)] = [
            (.enUS, "Open Example"), (.zhHans, "打开 Example"), (.de, "Example öffnen"),
            (.fr, "Ouvrir Example"), (.es, "Abrir Example"), (.ja, "Exampleを開く")
        ]
        for (language, expected) in labels {
            let strings = FeatureStrings.commandBar(language)
            expect(String(format: strings.actionOpenFormat, "Example") == expected,
                   "primary open action names its target in \(language)")
            expect(!strings.copyFailed.isEmpty, "copy failure remains visible in \(language)")
            expect(!strings.argumentInvalid.isEmpty && strings.argumentInvalid != strings.argumentHint,
                   "invalid input has a distinct instruction in \(language)")
            expect(strings.actionReviewConfirmation != strings.confirmButton
                && !strings.actionEnterValue.isEmpty && !strings.actionEnterText.isEmpty
                && !strings.actionSaveName.isEmpty && !strings.actionInsert.isEmpty
                && String(format: strings.actionApplyValueFormat, 40).contains("40"),
                "Return labels distinguish review from confirmation and retain numeric values in \(language)")
        }
        for language: AppLanguage in [.ptBR, .tr, .ru, .it, .ko, .zhTW, .zhHK] {
            let strings = FeatureStrings.commandBar(language)
            expect(strings.actionOpenFormat == CommandBarFeatureStrings.enUS.actionOpenFormat
                && strings.copyFailed == CommandBarFeatureStrings.enUS.copyFailed
                && strings.argumentInvalid == CommandBarFeatureStrings.enUS.argumentInvalid
                && strings.actionEnterValue == english.actionEnterValue
                && strings.actionReviewConfirmation == english.actionReviewConfirmation
                && strings.actionApplyValueFormat == english.actionApplyValueFormat
                && strings.actionSaveName == english.actionSaveName
                && strings.actionInsert == english.actionInsert
                && strings.actionEnterText == english.actionEnterText,
                "new action labels use the English fallback in \(language)")
        }
    }
}
