// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import Foundation

enum FinderArrangementRule: Int, CaseIterable {
    case none, grid, name, modified, created, size, kind, label

    var scriptValue: String {
        switch self {
        case .none: return "not arranged"
        case .grid: return "snap to grid"
        case .name: return "arranged by name"
        case .modified: return "arranged by modification date"
        case .created: return "arranged by creation date"
        case .size: return "arranged by size"
        case .kind: return "arranged by kind"
        case .label: return "arranged by label"
        }
    }
}

struct FinderArrangementSnapshot: Equatable {
    let windowID: Int
    let path: String
    let rule: FinderArrangementRule
}

enum FinderArrangementFailure: Error, Equatable {
    case permission, canceled, unsupported, changed, timedOut, failed
}

enum FinderArrangementSupport {
    // Only the first two separators delimit fields. File names may contain newlines.
    static func parse(_ output: String) -> FinderArrangementSnapshot? {
        let parts = output.split(separator: "\n", maxSplits: 2, omittingEmptySubsequences: false)
        guard parts.count == 3, let id = Int(parts[0]), id > 0,
              let raw = Int(parts[1]), let rule = FinderArrangementRule(rawValue: raw),
              parts[2].hasPrefix("/") else { return nil }
        return FinderArrangementSnapshot(windowID: id, path: String(parts[2]), rule: rule)
    }

    static func literal(_ value: String) -> String {
        "\"" + value.replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"") + "\""
    }

    static func samePath(_ lhs: String, _ rhs: String) -> Bool {
        URL(fileURLWithPath: lhs).standardizedFileURL.path
            == URL(fileURLWithPath: rhs).standardizedFileURL.path
    }

    static let captureScript = """
    tell application "Finder"
        if (count of Finder windows) is 0 then error number 1701
        set w to front Finder window
        \(validation)
        \(readback)
    end tell
    """

    static func acquireScript(path: String) -> String {
        """
        tell application "Finder"
            set requestedFolder to POSIX file \(literal(path)) as alias
            open requestedFolder
            set matchedWindow to missing value
            repeat with attempt from 1 to 20
                repeat with candidate in Finder windows
                    try
                        considering case, diacriticals, hyphens, punctuation, white space
                            if (POSIX path of (target of candidate as alias)) is \(literal(path)) then
                                set matchedWindow to candidate
                                exit repeat
                            end if
                        end considering
                    end try
                end repeat
                if matchedWindow is not missing value then exit repeat
                delay 0.05
            end repeat
            if matchedWindow is missing value then error number -1712
            set w to matchedWindow
            \(validation)
            \(readback)
        end tell
        """
    }

    static func changeScript(_ snapshot: FinderArrangementSnapshot, to rule: FinderArrangementRule) -> String {
        """
        tell application "Finder"
            if not (exists Finder window id \(snapshot.windowID)) then error number 1702
            set w to Finder window id \(snapshot.windowID)
            \(validation)
            considering case, diacriticals, hyphens, punctuation, white space
                if (POSIX path of (target of w as alias)) is not \(literal(snapshot.path)) then error number 1702
            end considering
            if (arrangement of icon view options of w) is not \(snapshot.rule.scriptValue) then error number 1702
            set arrangement of icon view options of w to \(rule.scriptValue)
            \(readback)
        end tell
        """
    }

    private static let validation = """
    if (class of w) is desktop window then error number 1701
    if (current view of w) is not icon view then error number 1701
    if (class of target of w) is not folder then error number 1701
    """

    private static var readback: String {
        let rules = FinderArrangementRule.allCases.map {
            "if a is \($0.scriptValue) then set r to \($0.rawValue)"
        }.joined(separator: "\n")
        return """
        set a to arrangement of icon view options of w
        set r to -1
        \(rules)
        return (id of w as text) & linefeed & (r as text) & linefeed & (POSIX path of (target of w as alias))
        """
    }

    static func failure(_ number: Int?) -> FinderArrangementFailure {
        switch number {
        case -1743, -1744: return .permission
        case -128: return .canceled
        case -1712: return .timedOut
        case 1701: return .unsupported
        case 1702: return .changed
        default: return .failed
        }
    }
}

/// The only system boundary: one script request and a local-directory check.
struct FinderArrangementClient {
    typealias Reply = (ok: Bool, errorNumber: Int?, message: String, output: String)
    var run: (String) -> Reply
    var acceptsPath: (String) -> Bool

    func capture() -> Result<FinderArrangementSnapshot, FinderArrangementFailure> {
        decode(run(FinderArrangementSupport.captureScript))
    }

    func acquire(path: String) -> Result<FinderArrangementSnapshot, FinderArrangementFailure> {
        guard acceptsPath(path) else { return .failure(.unsupported) }
        let result = decode(run(FinderArrangementSupport.acquireScript(path: path)))
        guard case .success(let snapshot) = result else { return result }
        return FinderArrangementSupport.samePath(snapshot.path, path) ? result : .failure(.changed)
    }

    func change(_ snapshot: FinderArrangementSnapshot, to rule: FinderArrangementRule)
        -> Result<FinderArrangementSnapshot, FinderArrangementFailure> {
        guard acceptsPath(snapshot.path) else { return .failure(.unsupported) }
        let result = decode(run(FinderArrangementSupport.changeScript(snapshot, to: rule)))
        if case .success(let current) = result,
           current != FinderArrangementSnapshot(windowID: snapshot.windowID, path: snapshot.path, rule: rule) {
            return .failure(.changed)
        }
        return result
    }

    private func decode(_ reply: Reply) -> Result<FinderArrangementSnapshot, FinderArrangementFailure> {
        guard reply.ok else { return .failure(FinderArrangementSupport.failure(reply.errorNumber)) }
        guard let snapshot = FinderArrangementSupport.parse(reply.output), acceptsPath(snapshot.path) else {
            return .failure(.unsupported)
        }
        return .success(snapshot)
    }
}
