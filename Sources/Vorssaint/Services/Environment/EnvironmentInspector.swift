// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import Combine
import Foundation

/// One command name, answered the way the shell answers it: the first match in
/// PATH wins, later ones are shadowed. `shimTarget` is set when the file that
/// wins is not the tool it is named after.
struct EnvironmentTool: Identifiable, Hashable {
    let command: String
    let path: String?
    let version: String?
    let shimTarget: String?
    let shadowedPaths: [String]

    var id: String { command }
    var isShim: Bool { shimTarget != nil }
}

struct EnvironmentCache: Identifiable, Hashable {
    let path: String
    let size: Int64

    var id: String { path }
}

struct EnvironmentReport {
    var terminalPath: [String] = []
    var guiPath: [String] = []
    var tools: [EnvironmentTool] = []
    var caches: [EnvironmentCache] = []
    /// Whether the login shell answered. When it did not, `terminalPath` holds
    /// only the system half and the page has to say so rather than present a
    /// short list as the whole truth.
    var readLoginShell = false

    /// Directories a terminal has and a Finder-launched app does not. This is
    /// the answer to "my MCP server works in the terminal but not in the app".
    var terminalOnlyPath: [String] {
        let gui = Set(guiPath)
        return terminalPath.filter { !gui.contains($0) }
    }
}

/// Reads the machine's command environment once, on demand. Nothing here is
/// resident: the page asks, this answers, and the answer is thrown away when
/// the app quits. Every command it runs is bounded by a timeout, because a
/// version check that hangs would otherwise hang the page.
final class EnvironmentInspector: ObservableObject {
    static let shared = EnvironmentInspector()

    /// The commands people hit environment trouble with. `npx` and `bunx` are
    /// on the list because that is what a pasted MCP config runs.
    static let inspectedCommands = ["node", "npm", "npx", "bun", "bunx", "python3", "uv"]

    /// What launchd hands a process when nothing set PATH for it. Apps opened
    /// from Finder or the Dock inherit exactly this.
    static let launchdDefaultPath = ["/usr/bin", "/bin", "/usr/sbin", "/sbin"]

    private static let commandTimeout: TimeInterval = 5
    private static let shellTimeout: TimeInterval = 10
    private static let maxOutputBytes = 64 * 1024

    @Published private(set) var report = EnvironmentReport()
    @Published private(set) var isLoading = false

    private let workQueue = DispatchQueue(label: "com.vorssaint.environment", qos: .userInitiated)

    private init() {}

    func refresh() {
        guard !isLoading else { return }
        isLoading = true
        workQueue.async { [weak self] in
            let report = Self.inspect()
            DispatchQueue.main.async {
                self?.report = report
                self?.isLoading = false
            }
        }
    }

    // MARK: - Reading

    static func inspect() -> EnvironmentReport {
        var report = EnvironmentReport()
        let shellPath = loginShellPath()
        report.readLoginShell = shellPath != nil
        report.terminalPath = shellPath ?? systemPath()
        report.guiPath = guiPath()
        report.tools = inspectedCommands.map { tool(named: $0, in: report.terminalPath) }
        report.caches = caches()
        return report
    }

    /// Asks the user's own login shell what PATH it ends up with. Only the
    /// shell can answer: PATH is assembled by its startup files, and this app
    /// must never read or edit those.
    static func loginShellPath() -> [String]? {
        guard let shell = loginShell(),
              FileManager.default.isExecutableFile(atPath: shell) else { return nil }
        // Login *and* interactive, because that is what a terminal window runs
        // and dotfiles routinely split PATH edits across both kinds.
        for arguments in [["-l", "-i", "-c", "printf %s \"$PATH\""],
                          ["-l", "-c", "printf %s \"$PATH\""]] {
            let result = BoundedProcessRunner.run(shell, arguments,
                                                  timeout: shellTimeout,
                                                  maxOutputBytes: maxOutputBytes)
            guard result.status == 0, !result.timedOut,
                  let text = String(data: result.output, encoding: .utf8) else { continue }
            let entries = splitPath(text)
            if !entries.isEmpty { return entries }
        }
        return nil
    }

    static func loginShell() -> String? {
        if let shell = getpwuid(getuid())?.pointee.pw_shell {
            let value = String(cString: shell)
            if !value.isEmpty { return value }
        }
        return ProcessInfo.processInfo.environment["SHELL"]
    }

    /// The system half of PATH, and the only half this app could ever add to.
    static func systemPath() -> [String] {
        var entries: [String] = []
        if let contents = try? String(contentsOfFile: "/etc/paths", encoding: .utf8) {
            entries += contents.split(whereSeparator: \.isNewline).map(String.init)
        }
        let fragments = (try? FileManager.default.contentsOfDirectory(atPath: "/etc/paths.d")) ?? []
        for fragment in fragments.sorted() {
            guard let contents = try? String(contentsOfFile: "/etc/paths.d/\(fragment)",
                                             encoding: .utf8) else { continue }
            entries += contents.split(whereSeparator: \.isNewline).map(String.init)
        }
        return dedupe(entries.map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty })
    }

    /// What a Finder- or Dock-launched app gets. `launchctl getenv PATH` is
    /// normally unset, and then launchd's own default is the honest answer —
    /// not this process's PATH, which depends on how the app was started.
    static func guiPath() -> [String] {
        let result = BoundedProcessRunner.run("/bin/launchctl", ["getenv", "PATH"],
                                              timeout: commandTimeout,
                                              maxOutputBytes: maxOutputBytes)
        if result.status == 0, !result.timedOut,
           let text = String(data: result.output, encoding: .utf8) {
            let entries = splitPath(text)
            if !entries.isEmpty { return entries }
        }
        return launchdDefaultPath
    }

    static func tool(named command: String, in path: [String]) -> EnvironmentTool {
        let matches = path
            .map { ($0 as NSString).appendingPathComponent(command) }
            .filter { FileManager.default.isExecutableFile(atPath: $0) }
        let winner = dedupe(matches)
        guard let first = winner.first else {
            return EnvironmentTool(command: command, path: nil, version: nil,
                                   shimTarget: nil, shadowedPaths: [])
        }
        return EnvironmentTool(command: command,
                               path: first,
                               version: version(of: first),
                               shimTarget: shimTarget(of: first, command: command),
                               shadowedPaths: Array(winner.dropFirst()))
    }

    static func version(of path: String) -> String? {
        let result = BoundedProcessRunner.run(path, ["--version"],
                                              timeout: commandTimeout,
                                              maxOutputBytes: maxOutputBytes)
        // A wrapper that refuses `--version` still prints something and exits
        // non-zero; printing its complaint as a version would be a lie.
        guard result.status == 0, !result.timedOut,
              let text = String(data: result.output, encoding: .utf8) else { return nil }
        let line = text.split(whereSeparator: \.isNewline).first.map(String.init) ?? ""
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        return trimmed.isEmpty ? nil : trimmed
    }

    /// What the file actually runs, when that is something other than the tool
    /// it is named after. A symlink says so directly; a wrapper script has to
    /// be read, and the `exec` line is where it names its target.
    static func shimTarget(of path: String, command: String) -> String? {
        if let destination = try? FileManager.default.destinationOfSymbolicLink(atPath: path) {
            let resolved = destination.hasPrefix("/")
                ? destination
                : ((path as NSString).deletingLastPathComponent as NSString)
                    .appendingPathComponent(destination)
            let target = (resolved as NSString).lastPathComponent
            return target == command ? nil : resolved
        }
        guard let handle = FileHandle(forReadingAtPath: path),
              let head = try? handle.read(upToCount: 8 * 1024) else { return nil }
        try? handle.close()
        guard let text = String(data: head, encoding: .utf8), text.hasPrefix("#!") else { return nil }
        for rawLine in text.split(whereSeparator: \.isNewline) {
            // `exec` is not always the first word: a dispatch table puts it
            // after the case label, as `install|i) exec "$HOME/.bun/bin/bun" …`.
            guard let target = execTarget(in: String(rawLine)) else { continue }
            let name = (target as NSString).lastPathComponent
            guard !name.isEmpty, name != command, name != "env" else { continue }
            return target
        }
        return nil
    }

    /// The first thing an `exec` on this line hands control to, with the
    /// quoting the script wrote around it removed.
    static func execTarget(in line: String) -> String? {
        var search = line.startIndex..<line.endIndex
        while let found = line.range(of: "exec ", range: search) {
            search = found.upperBound..<line.endIndex
            let before = found.lowerBound == line.startIndex
                ? nil
                : line[line.index(before: found.lowerBound)]
            // Anything else in front means a longer word ending in "exec".
            guard before == nil || before == " " || before == "\t"
                    || before == ";" || before == "&" || before == "|" || before == ")" else { continue }
            var token = ""
            var skipNext = false
            for word in line[found.upperBound...].split(separator: " ") where !word.isEmpty {
                if skipNext { skipNext = false; continue }
                // `exec -a NAME cmd` renames the process: NAME is not the target.
                if word == "-a" { skipNext = true; continue }
                if word.hasPrefix("-") { continue }
                token = String(word)
                break
            }
            let unquoted = token.trimmingCharacters(in: CharacterSet(charactersIn: "\"'"))
            if !unquoted.isEmpty { return unquoted }
        }
        return nil
    }

    /// Only the caches `npx` and `bunx` leave behind. A sweep for stray
    /// `node_modules` folders belongs to the cleaner, which already walks the
    /// disk; this page reads two known paths and stops.
    static func caches() -> [EnvironmentCache] {
        let home = NSHomeDirectory()
        return [".npm/_npx", ".bun/install/cache"]
            .map { (home as NSString).appendingPathComponent($0) }
            .filter { FileManager.default.fileExists(atPath: $0) }
            .map { EnvironmentCache(path: $0, size: DirectorySize.of(URL(fileURLWithPath: $0))) }
    }

    // MARK: - Report

    /// Plain text for a bug report: everything the page shows, in the order it
    /// shows it, so a person can paste it instead of answering ten questions.
    static func diagnosticText(_ report: EnvironmentReport) -> String {
        var lines: [String] = []
        lines.append("macOS \(ProcessInfo.processInfo.operatingSystemVersionString)")
        lines.append("shell: \(loginShell() ?? "unknown")")
        lines.append("")
        lines.append("commands")
        for tool in report.tools {
            guard let path = tool.path else {
                lines.append("  \(tool.command): not found")
                continue
            }
            var line = "  \(tool.command): \(path)"
            if let version = tool.version { line += "  [\(version)]" }
            if let shim = tool.shimTarget { line += "  -> \(shim)" }
            lines.append(line)
            for shadowed in tool.shadowedPaths {
                lines.append("    shadowed: \(shadowed)")
            }
        }
        lines.append("")
        lines.append("terminal PATH\(report.readLoginShell ? "" : " (login shell did not answer; system entries only)")")
        report.terminalPath.forEach { lines.append("  \($0)") }
        lines.append("")
        lines.append("GUI app PATH")
        report.guiPath.forEach { lines.append("  \($0)") }
        lines.append("")
        lines.append("in terminal but not in GUI apps")
        let missing = report.terminalOnlyPath
        if missing.isEmpty {
            lines.append("  (none)")
        } else {
            missing.forEach { lines.append("  \($0)") }
        }
        lines.append("")
        lines.append("caches")
        if report.caches.isEmpty {
            lines.append("  (none)")
        } else {
            for cache in report.caches {
                let size = ByteCountFormatter.string(fromByteCount: cache.size, countStyle: .file)
                lines.append("  \(cache.path): \(size)")
            }
        }
        return lines.joined(separator: "\n")
    }

    // MARK: - Helpers

    static func splitPath(_ value: String) -> [String] {
        dedupe(value.trimmingCharacters(in: .whitespacesAndNewlines)
            .split(separator: ":")
            .map(String.init)
            .filter { !$0.isEmpty })
    }

    private static func dedupe(_ values: [String]) -> [String] {
        var seen: Set<String> = []
        return values.filter { seen.insert($0).inserted }
    }
}
