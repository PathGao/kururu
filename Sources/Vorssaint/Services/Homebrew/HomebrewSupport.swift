// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import Foundation

enum HomebrewPackageKind: String, CaseIterable, Identifiable {
    case cask
    case formula
    case masApp

    var id: String { rawValue }

    /// Whether `brew` owns the package, so only those get a brew command
    /// built for them. App Store apps are listed but never acted on.
    var isBrew: Bool { self != .masApp }
}

struct HomebrewPackage: Identifiable, Hashable {
    let kind: HomebrewPackageKind
    let name: String
    var displayName: String
    var desc: String?
    var installedVersion: String?
    var stableVersion: String?
    var homepage: String?
    var update: HomebrewPackageUpdate?
    /// False for a formula something else pulled in. Casks and App Store apps
    /// have no dependency concept, so they are always requested.
    var installedOnRequest: Bool = true
    /// What this package needs, by the name those packages carry here. For a
    /// formula it is brew's own record of what the installed keg links against,
    /// which is already the whole closure; for a cask it is the formulae it
    /// declares, whose own needs are one hop further out.
    var requires: [String] = []
    /// Filled in by `HomebrewDependencyGraph`: the packages the person asked
    /// for that reach this one. Empty on a dependency means nothing installed
    /// needs it any more.
    var requiredBy: [String] = []

    var id: String { "\(kind.rawValue):\(name)" }
    var isInstalled: Bool { installedVersion != nil }
    var hasUpdateAvailable: Bool { update != nil }
    var versionText: String? { installedVersion ?? stableVersion }
}

struct HomebrewPackageUpdate: Hashable {
    let kind: HomebrewPackageKind
    let name: String
    let installedVersions: [String]
    let currentVersion: String
    let isPinned: Bool

    var id: String { "\(kind.rawValue):\(name)" }

    var installedText: String {
        installedVersions.joined(separator: ", ")
    }

    var versionSummary: String {
        let installed = installedText
        return installed.isEmpty ? currentVersion : "\(installed) -> \(currentVersion)"
    }
}

/// An installed cask as the catalog describes it, including which app
/// bundles it drops into the Applications folder. The app update check needs
/// that link to read the version the app itself reports.
struct HomebrewCaskRecord: Hashable {
    let token: String
    let displayName: String
    let installedVersion: String?
    let appFileNames: [String]
    let appPaths: [String]

    init(token: String,
         displayName: String,
         installedVersion: String?,
         appFileNames: [String],
         appPaths: [String] = []) {
        self.token = token
        self.displayName = displayName
        self.installedVersion = installedVersion
        self.appFileNames = appFileNames
        self.appPaths = appPaths
    }
}

enum HomebrewOwnershipSupport {
    /// Resolves a package only when its catalog points at this exact app. A
    /// same-named copy elsewhere must never make an unrelated package eligible
    /// for a destructive command.
    static func packageManagingApplication(atPath rawPath: String,
                                           installed: [HomebrewCaskRecord]) -> HomebrewPackage? {
        let path = URL(fileURLWithPath: rawPath).standardizedFileURL.path
        let exact = installed.filter { record in
            record.appPaths.contains {
                URL(fileURLWithPath: $0).standardizedFileURL.path == path
            }
        }
        if exact.count == 1 {
            return package(from: exact[0])
        }
        return nil
    }

    private static func package(from record: HomebrewCaskRecord) -> HomebrewPackage {
        HomebrewPackage(kind: .cask,
                        name: record.token,
                        displayName: record.displayName,
                        desc: nil,
                        installedVersion: record.installedVersion,
                        stableVersion: nil,
                        homepage: nil)
    }
}

/// Answers "who pulled this in". brew records a runtime dependency list per
/// installed keg, so the edges are read, never guessed — and because a package
/// can be reached from several roots at once, the answer is a list.
enum HomebrewDependencyGraph {
    /// Walks out from the packages the person asked for and marks everything
    /// they reach. A dependency nothing reaches is left with no roots: that is
    /// the leftover `brew autoremove` would take.
    static func attributingRoots(_ packages: [HomebrewPackage]) -> [HomebrewPackage] {
        var byName: [String: HomebrewPackage] = [:]
        for package in packages where package.kind.isBrew {
            byName[package.name] = package
            // Dependency lists name a formula by its short token even when the
            // package itself is known here by its full tapped name.
            let short = (package.name as NSString).lastPathComponent
            if byName[short] == nil { byName[short] = package }
        }

        var roots: [String: [String]] = [:]
        for root in packages where root.kind.isBrew && root.installedOnRequest {
            var seen: Set<String> = [root.name]
            var queue = root.requires
            while let next = queue.popLast() {
                guard let reached = byName[next], seen.insert(reached.name).inserted else { continue }
                if !reached.installedOnRequest {
                    roots[reached.name, default: []].append(root.displayName)
                }
                queue += reached.requires
            }
        }

        return packages.map { package in
            guard package.kind.isBrew, !package.installedOnRequest else { return package }
            var copy = package
            copy.requiredBy = (roots[package.name] ?? []).sorted {
                $0.localizedCaseInsensitiveCompare($1) == .orderedAscending
            }
            return copy
        }
    }
}

enum HomebrewPackageOrdering {
    static func updatesFirst(_ packages: [HomebrewPackage]) -> [HomebrewPackage] {
        packages.filter(\.hasUpdateAvailable) + packages.filter { !$0.hasUpdateAvailable }
    }
}

struct HomebrewCommand: Equatable {
    let executable: String
    let arguments: [String]
}

struct HomebrewOperation {
    enum Action {
        case uninstall
        case upgrade
        case updateHomebrew

        var clearsSelectionOnSuccess: Bool {
            switch self {
            case .uninstall:
                return true
            case .upgrade, .updateHomebrew:
                return false
            }
        }

        var runningSystemImage: String {
            switch self {
            case .uninstall:
                return "trash.circle.fill"
            case .upgrade:
                return "arrow.up.circle.fill"
            case .updateHomebrew:
                return "arrow.triangle.2.circlepath"
            }
        }
    }

    let action: Action
    let package: HomebrewPackage?
}

enum HomebrewOperationPhase: Equatable {
    case preparing
    case downloading
    case uninstalling
    case upgrading
    case finalizing
    case refreshing
}

enum HomebrewOperationResult: Equatable {
    case running
    case succeeded
    case failed
    case cancelled
    case needsTerminal
}

struct HomebrewOperationStatus: Equatable {
    var action: HomebrewOperation.Action
    var package: HomebrewPackage?
    var phase: HomebrewOperationPhase
    var result: HomebrewOperationResult
    var progressFraction: Double?
    var startedAt: Date
    var finishedAt: Date?
    var lastActivity: String?

    var isActive: Bool {
        result == .running
    }

    var targetID: String {
        package?.id ?? "homebrew:\(action)"
    }
}

struct HomebrewPendingAction {
    let action: HomebrewOperation.Action
    let package: HomebrewPackage?

    init(action: HomebrewOperation.Action, package: HomebrewPackage? = nil) {
        self.action = action
        self.package = package
    }
}

enum HomebrewCommandBuilder {
    static let candidatePaths = ["/opt/homebrew/bin/brew", "/usr/local/bin/brew"]
    /// `mas` is itself a Homebrew formula, so it sits next to `brew`.
    static let masCandidatePaths = ["/opt/homebrew/bin/mas", "/usr/local/bin/mas"]

    static func installed(brewPath: String) -> HomebrewCommand {
        HomebrewCommand(executable: brewPath, arguments: ["info", "--json=v2", "--installed"])
    }

    static func outdated(brewPath: String) -> HomebrewCommand {
        HomebrewCommand(executable: brewPath, arguments: ["outdated", "--json=v2"])
    }

    static func masList(masPath: String) -> HomebrewCommand {
        HomebrewCommand(executable: masPath, arguments: ["list"])
    }

    static func update(brewPath: String) -> HomebrewCommand {
        HomebrewCommand(executable: brewPath, arguments: ["update"])
    }

    static func uninstall(brewPath: String, package: HomebrewPackage) -> HomebrewCommand? {
        guard package.kind.isBrew, isValidToken(package.name) else { return nil }
        var args = ["uninstall"]
        if package.kind == .cask { args.append("--cask") }
        args.append(package.name)
        return HomebrewCommand(executable: brewPath, arguments: args)
    }

    /// Only a package the person asked for by name is upgradable from here.
    /// A formula something else pulled in gets upgraded when its dependant
    /// does, and offering its own button hides that.
    static func upgrade(brewPath: String, package: HomebrewPackage) -> HomebrewCommand? {
        guard package.kind.isBrew, package.installedOnRequest, isValidToken(package.name) else { return nil }
        var args = ["upgrade"]
        if package.kind == .cask { args.append("--cask") }
        args.append(package.name)
        return HomebrewCommand(executable: brewPath, arguments: args)
    }

    static func isValidToken(_ token: String) -> Bool {
        guard !token.isEmpty,
              !token.hasPrefix("-"),
              !token.contains(".."),
              !token.contains("//") else { return false }
        return token.range(of: #"^[A-Za-z0-9][A-Za-z0-9._+@/-]*$"#,
                           options: .regularExpression) != nil
    }

    static func shellCommand(_ command: HomebrewCommand) -> String {
        ([command.executable] + command.arguments).map(shellQuote).joined(separator: " ")
    }

    /// Homebrew 6 refuses to load packages from taps the user never
    /// confirmed ("Refusing to load formula x from untrusted tap owner/repo")
    /// and only offers an interactive prompt in a terminal. The tap name is
    /// extracted here so the app can offer the trust step as one click.
    static func untrustedTapName(fromOutput output: String) -> String? {
        guard let range = output.range(of: #"from untrusted tap ([A-Za-z0-9._-]+/[A-Za-z0-9._-]+)"#,
                                       options: .regularExpression) else { return nil }
        let name = String(output[range])
            .replacingOccurrences(of: "from untrusted tap ", with: "")
            // The refusal ends the sentence right after the name.
            .trimmingCharacters(in: CharacterSet(charactersIn: "."))
        return isValidToken(name) ? name : nil
    }

    static func trustTap(brewPath: String, tap: String) -> HomebrewCommand {
        HomebrewCommand(executable: brewPath, arguments: ["trust", "--tap", tap])
    }

    static func needsTerminalFallback(output: String) -> Bool {
        let lower = output.lowercased()
        return lower.contains("sudo:")
            || lower.contains("a terminal is required")
            || lower.contains("password is required")
            || lower.contains("password:")
            || lower.contains("administrator privileges")
    }

    static func shellQuote(_ value: String) -> String {
        if value.range(of: #"^[A-Za-z0-9._+@%/=:,-]+$"#, options: .regularExpression) != nil {
            return value
        }
        return "'" + value.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }

}

enum HomebrewProgressParser {
    private static let percentageRegex = try? NSRegularExpression(pattern: #"([0-9]{1,3}(?:\.[0-9]+)?)%"#)
    private static let ansiRegex = try? NSRegularExpression(pattern: #"\u001B\[[0-9;?]*[ -/]*[@-~]"#)

    static func progressFraction(in output: String) -> Double? {
        var latest: Double?
        guard let regex = percentageRegex else { return nil }
        let range = NSRange(output.startIndex..<output.endIndex, in: output)
        regex.enumerateMatches(in: output, range: range) { match, _, _ in
            guard let match,
                  let valueRange = Range(match.range(at: 1), in: output),
                  let value = Double(output[valueRange]) else { return }
            latest = min(max(value / 100, 0), 1)
        }
        return latest
    }

    static func phase(in output: String,
                      action: HomebrewOperation.Action) -> HomebrewOperationPhase? {
        let lower = stripANSI(output).lowercased()
        if lower.contains("downloading")
            || lower.contains("fetching")
            || lower.contains("downloaded") {
            return .downloading
        }
        if lower.contains("uninstalling")
            || lower.contains("zap")
            || lower.contains("purging") {
            return .uninstalling
        }
        if lower.contains("upgrading")
            || lower.contains("upgraded") {
            return .upgrading
        }
        if action == .updateHomebrew,
           (lower.contains("updating")
            || lower.contains("updated")
            || lower.contains("already up-to-date")
            || lower.contains("already up to date")) {
            return .refreshing
        }
        if lower.contains("installing")
            || lower.contains("pouring")
            || lower.contains("moving app")
            || lower.contains("linking") {
            switch action {
            case .uninstall:
                return .uninstalling
            case .upgrade:
                return .upgrading
            case .updateHomebrew:
                return .refreshing
            }
        }
        if lower.contains("cleanup")
            || lower.contains("cleaning")
            || lower.contains("caveats")
            || lower.contains("summary")
            || lower.contains("installed!")
            || lower.contains("uninstalled") {
            return .finalizing
        }
        return nil
    }

    static func activity(in output: String) -> String? {
        lines(in: output).reversed().first { line in
            let stripped = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !stripped.isEmpty,
                  !stripped.hasPrefix("$ "),
                  !isMostlyProgressSymbols(stripped) else { return false }
            return true
        }
    }

    static func visibleError(from output: String) -> String {
        let candidates = lines(in: output).filter { line in
            let stripped = line.trimmingCharacters(in: .whitespacesAndNewlines)
            return !stripped.isEmpty
                && !stripped.hasPrefix("$ ")
                && !isMostlyProgressSymbols(stripped)
        }
        return candidates.suffix(3).joined(separator: "\n")
    }

    private static func lines(in output: String) -> [String] {
        stripANSI(output)
            .replacingOccurrences(of: "\r", with: "\n")
            .split(whereSeparator: \.isNewline)
            .map(cleanLine)
    }

    private static func cleanLine(_ line: Substring) -> String {
        var value = String(line).trimmingCharacters(in: .whitespacesAndNewlines)
        while value.hasPrefix("==>") {
            value.removeFirst(3)
            value = value.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        while value.hasPrefix("->") {
            value.removeFirst(2)
            value = value.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return value
    }

    private static func stripANSI(_ value: String) -> String {
        guard let regex = ansiRegex else {
            return value
        }
        let range = NSRange(value.startIndex..<value.endIndex, in: value)
        return regex.stringByReplacingMatches(in: value, range: range, withTemplate: "")
    }

    private static func isMostlyProgressSymbols(_ value: String) -> Bool {
        let allowed = CharacterSet(charactersIn: "#=-> .:%0123456789")
        let scalars = value.unicodeScalars.filter { !$0.properties.isWhitespace }
        guard !scalars.isEmpty else { return true }
        let progressCount = scalars.filter { allowed.contains($0) }.count
        return Double(progressCount) / Double(scalars.count) > 0.85
    }
}

enum HomebrewParser {
    static func parseInfoJSON(_ data: Data) throws -> [HomebrewPackage] {
        guard let root = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return []
        }
        let formulae = (root["formulae"] as? [[String: Any]] ?? []).compactMap(parseFormula)
        let casks = (root["casks"] as? [[String: Any]] ?? []).compactMap(parseCask)
        return (formulae + casks).sorted { lhs, rhs in
            if lhs.kind != rhs.kind { return lhs.kind == .cask }
            return lhs.displayName.localizedCaseInsensitiveCompare(rhs.displayName) == .orderedAscending
        }
    }

    static func parseInfoCommandOutput(_ output: String) throws -> [HomebrewPackage] {
        let data = Data(output.utf8)
        do {
            return try parseInfoJSON(data)
        } catch {
            for json in balancedJSONObjects(in: output) {
                let jsonData = Data(json.utf8)
                guard isInfoJSONObject(jsonData) else { continue }
                if let packages = try? parseInfoJSON(jsonData) {
                    return packages
                }
            }
            throw error
        }
    }

    /// Installed casks with the app bundles they install, so a package token
    /// can be traced back to the app on disk.
    static func parseInstalledCaskRecords(_ output: String) -> [HomebrewCaskRecord] {
        for json in [output] + balancedJSONObjects(in: output) {
            let data = Data(json.utf8)
            guard let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let casks = root["casks"] as? [[String: Any]] else { continue }
            return casks.compactMap(parseCaskRecord)
        }
        return []
    }

    private static func parseCaskRecord(_ item: [String: Any]) -> HomebrewCaskRecord? {
        guard let token = item["token"] as? String,
              HomebrewCommandBuilder.isValidToken(token) else { return nil }
        let displayName = (item["name"] as? [String])?.first(where: { !$0.isEmpty }) ?? token
        let installed = item["installed"] as? String
        var appFileNames: [String] = []
        var appPaths: [String] = []
        for artifact in (item["artifacts"] as? [Any] ?? []) {
            guard let entry = artifact as? [String: Any],
                  let apps = entry["app"] as? [Any] else { continue }
            // A package can rename the bundle it installs. Prefer that target
            // name, then keep the source name as a fallback for older output.
            var targets: [String] = []
            var sources: [String] = []
            if let target = entry["target"] as? String { targets.append(target) }
            for app in apps {
                if let source = app as? String {
                    sources.append(source)
                } else if let mapping = app as? [String: Any],
                          let target = mapping["target"] as? String {
                    targets.append(target)
                }
            }
            for candidate in targets.isEmpty ? sources : targets {
                let fileName = URL(fileURLWithPath: candidate).lastPathComponent
                if fileName.hasSuffix(".app"), !appFileNames.contains(fileName) {
                    appFileNames.append(fileName)
                }
            }
            for candidate in targets + sources where candidate.hasPrefix("/") {
                let path = URL(fileURLWithPath: candidate).standardizedFileURL.path
                if path.hasSuffix(".app"), !appPaths.contains(path) {
                    appPaths.append(path)
                }
            }
        }
        return HomebrewCaskRecord(token: token,
                                  displayName: displayName,
                                  installedVersion: installed?.isEmpty == false ? installed : nil,
                                  appFileNames: appFileNames,
                                  appPaths: appPaths)
    }

    static func parseOutdatedJSON(_ data: Data) throws -> [String: HomebrewPackageUpdate] {
        guard let root = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return [:]
        }
        let formulae = (root["formulae"] as? [[String: Any]] ?? [])
            .compactMap { parseOutdatedItem($0, kind: .formula) }
        let casks = (root["casks"] as? [[String: Any]] ?? [])
            .compactMap { parseOutdatedItem($0, kind: .cask) }
        return Dictionary(uniqueKeysWithValues: (formulae + casks).map { ($0.id, $0) })
    }

    static func parseOutdatedCommandOutput(_ output: String) throws -> [String: HomebrewPackageUpdate] {
        let data = Data(output.utf8)
        do {
            return try parseOutdatedJSON(data)
        } catch {
            for json in balancedJSONObjects(in: output) {
                let jsonData = Data(json.utf8)
                guard isOutdatedJSONObject(jsonData) else { continue }
                if let updates = try? parseOutdatedJSON(jsonData) {
                    return updates
                }
            }
            throw error
        }
    }

    private static func parseFormula(_ item: [String: Any]) -> HomebrewPackage? {
        guard let name = item["name"] as? String,
              HomebrewCommandBuilder.isValidToken(name) else { return nil }
        let fullName = item["full_name"] as? String
        let identifier = fullName.flatMap { fullName in
            HomebrewCommandBuilder.isValidToken(fullName) ? fullName : nil
        } ?? name
        let installed = item["installed"] as? [[String: Any]] ?? []
        let installedVersions = installed.compactMap { $0["version"] as? String }
        let stable = (item["versions"] as? [String: Any])?["stable"] as? String
        // Brew records the flag per installed version. Any version the person
        // asked for by name makes the package theirs; only when every version
        // arrived as someone else's dependency is it a dependency here.
        let onRequest = installed.contains { $0["installed_on_request"] as? Bool == true }
        // brew records this per installed version, already transitive. Reading
        // it beats walking `dependencies`, which describes the catalog today
        // rather than what this keg was actually built against.
        let requires = installed
            .flatMap { $0["runtime_dependencies"] as? [[String: Any]] ?? [] }
            .compactMap { $0["full_name"] as? String }
            .filter(HomebrewCommandBuilder.isValidToken)
        return HomebrewPackage(kind: .formula,
                               name: identifier,
                               displayName: fullName ?? name,
                               desc: item["desc"] as? String,
                               installedVersion: installedVersions.isEmpty ? nil : installedVersions.joined(separator: ", "),
                               stableVersion: stable,
                               homepage: item["homepage"] as? String,
                               installedOnRequest: onRequest,
                               requires: dedupe(requires))
    }

    private static func parseCask(_ item: [String: Any]) -> HomebrewPackage? {
        guard let token = item["token"] as? String,
              HomebrewCommandBuilder.isValidToken(token) else { return nil }
        let displayName: String
        if let names = item["name"] as? [String], let first = names.first, !first.isEmpty {
            displayName = first
        } else {
            displayName = token
        }
        let installed = item["installed"] as? String
        let dependsOn = item["depends_on"] as? [String: Any] ?? [:]
        let requires = ((dependsOn["formula"] as? [String]) ?? [])
            .filter(HomebrewCommandBuilder.isValidToken)
        return HomebrewPackage(kind: .cask,
                               name: token,
                               displayName: displayName,
                               desc: item["desc"] as? String,
                               installedVersion: installed?.isEmpty == false ? installed : nil,
                               stableVersion: item["version"] as? String,
                               homepage: item["homepage"] as? String,
                               requires: dedupe(requires))
    }

    private static func dedupe(_ values: [String]) -> [String] {
        var seen: Set<String> = []
        return values.filter { seen.insert($0).inserted }
    }

    private static func parseOutdatedItem(_ item: [String: Any],
                                          kind: HomebrewPackageKind) -> HomebrewPackageUpdate? {
        guard let name = (item["name"] as? String) ?? (item["token"] as? String),
              HomebrewCommandBuilder.isValidToken(name),
              let currentVersion = item["current_version"] as? String,
              !currentVersion.isEmpty else { return nil }
        let installedVersions = (item["installed_versions"] as? [String]) ?? []
        return HomebrewPackageUpdate(kind: kind,
                                     name: name,
                                     installedVersions: installedVersions,
                                     currentVersion: currentVersion,
                                     isPinned: item["pinned"] as? Bool ?? false)
    }

    private static func isInfoJSONObject(_ data: Data) -> Bool {
        guard let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return false
        }
        return root["formulae"] != nil || root["casks"] != nil
    }

    private static func isOutdatedJSONObject(_ data: Data) -> Bool {
        guard let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return false
        }
        let formulae = root["formulae"] as? [[String: Any]]
        let casks = root["casks"] as? [[String: Any]]
        guard formulae != nil || casks != nil else { return false }
        let items = (formulae ?? []) + (casks ?? [])
        return items.isEmpty || items.contains { item in
            item["current_version"] != nil || item["installed_versions"] != nil
        }
    }

    private static func balancedJSONObjects(in output: String) -> [String] {
        var objects: [String] = []
        var start: String.Index?
        var depth = 0
        var inString = false
        var escaping = false

        var index = output.startIndex
        while index < output.endIndex {
            let character = output[index]

            if start == nil {
                if character == "{" {
                    start = index
                    depth = 1
                    inString = false
                    escaping = false
                }
                index = output.index(after: index)
                continue
            }

            if inString {
                if escaping {
                    escaping = false
                } else if character == "\\" {
                    escaping = true
                } else if character == "\"" {
                    inString = false
                }
            } else if character == "\"" {
                inString = true
            } else if character == "{" {
                depth += 1
            } else if character == "}" {
                depth -= 1
                if depth == 0, let objectStart = start {
                    let end = output.index(after: index)
                    objects.append(String(output[objectStart..<end]))
                    start = nil
                    depth = 0
                }
                if depth < 0 {
                    start = nil
                    depth = 0
                }
            }

            index = output.index(after: index)
        }

        return objects
    }
}

/// `mas list` prints `<id>  <name>  (<version>)`, and app names carry spaces
/// and non-Latin characters, so the id and the trailing version are peeled off
/// the ends and whatever remains is the name.
enum MasParser {
    static func parseList(_ output: String) -> [HomebrewPackage] {
        var seen: Set<String> = []
        return output.split(whereSeparator: \.isNewline).compactMap { rawLine -> HomebrewPackage? in
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            guard let idEnd = line.firstIndex(of: " ") else { return nil }
            let id = String(line[line.startIndex..<idEnd])
            guard !id.isEmpty, id.allSatisfy(\.isNumber), seen.insert(id).inserted else { return nil }

            var rest = line[idEnd...].trimmingCharacters(in: .whitespaces)
            var version: String?
            if rest.hasSuffix(")"), let open = rest.lastIndex(of: "(") {
                let inner = rest[rest.index(after: open)..<rest.index(before: rest.endIndex)]
                version = inner.isEmpty ? nil : String(inner)
                rest = String(rest[rest.startIndex..<open]).trimmingCharacters(in: .whitespaces)
            }
            guard !rest.isEmpty else { return nil }

            return HomebrewPackage(kind: .masApp,
                                   name: id,
                                   displayName: rest,
                                   desc: nil,
                                   installedVersion: version,
                                   stableVersion: nil,
                                   homepage: "https://apps.apple.com/app/id\(id)")
        }
    }
}
