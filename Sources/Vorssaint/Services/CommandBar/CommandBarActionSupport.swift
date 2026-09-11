// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import Foundation

struct CommandBarRowAction: Identifiable {
    enum Group { case primary, organize, operation }

    let id: String
    let title: String
    let symbolName: String
    let group: Group
    let isDestructive: Bool
    let run: () -> Void

    init(id: String,
         title: String,
         symbolName: String,
         isDestructive: Bool = false,
         group: Group = .organize,
         run: @escaping () -> Void) {
        self.id = id
        self.title = title
        self.symbolName = symbolName
        self.isDestructive = isDestructive
        self.group = group
        self.run = run
    }
}

extension CommandBarRowAction {
    static func menu(primary: CommandBarRowAction,
                     additional: [CommandBarRowAction]) -> [CommandBarRowAction] {
        [primary] + additional.filter { $0.group == .organize }
            + additional.filter { $0.group == .operation }
    }

    static func primary(title: String, restoreSearch: @escaping () -> Void,
                        run: @escaping () -> Void) -> CommandBarRowAction {
        CommandBarRowAction(id: "primary", title: title, symbolName: "return", group: .primary) {
            restoreSearch()
            run()
        }
    }
}

enum CommandBarRunDecision: Equatable {
    case setup, confirm, argument
    case execute(Int?)

    static func resolve(needsSetup: Bool, needsConfirmation: Bool,
                        numericRange: ClosedRange<Int>?, numericIsOptional: Bool,
                        typedNumber: Int?) -> CommandBarRunDecision {
        if needsSetup { return .setup }
        if needsConfirmation { return .confirm }
        if let range = numericRange {
            if let typedNumber { return .execute(min(max(typedNumber, range.lowerBound), range.upperBound)) }
            return numericIsOptional ? .execute(nil) : .argument
        }
        return .execute(nil)
    }
}

struct CommandBarArgumentSubmission {
    private(set) var isRejected = false

    mutating func submit(_ text: String, in range: ClosedRange<Int>) -> Int? {
        let value = CommandBarSearch.argumentValue(text, in: range)
        isRejected = value == nil
        return value
    }

    mutating func reset() { isRejected = false }
}

enum CommandBarActionPresentation {
    static func title(id: String, title: String, isAnswer: Bool,
                      decision: CommandBarRunDecision, opensDestination: Bool,
                      needsTextArgument: Bool, strings: CommandBarFeatureStrings) -> String {
        switch decision {
        case .setup: return strings.actionOpenSettings
        case .confirm: return strings.actionReviewConfirmation
        case .argument: return strings.actionEnterValue
        case .execute(let value):
            if let value { return String(format: strings.actionApplyValueFormat, value) }
        }
        if isAnswer || id.hasPrefix("answer.") || id == "selection.copy" || id == "selection.count" {
            return strings.selectionCopy
        }
        if id.hasPrefix("clipboard.") { return strings.kindClipboard }
        if id.hasPrefix("snippet.") { return strings.kindSnippet + " · " + title }
        if id.hasPrefix("emoji.") { return strings.actionInsert + " · " + title }
        if id.hasPrefix("settings.") { return strings.actionOpenSettings + " · " + title }
        if needsTextArgument { return strings.actionEnterText }
        if id == "action.openURL" { return strings.openInBrowser }
        if (id.hasPrefix("link.") && opensDestination)
            || ["app.", "file.", "folder.", "macsettings."].contains(where: id.hasPrefix) {
            return String(format: strings.actionOpenFormat, title)
        }
        return title
    }
}
