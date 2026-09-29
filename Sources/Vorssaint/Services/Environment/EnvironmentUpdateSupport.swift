// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

enum EnvironmentUpdateSource: Hashable {
    case standalone(String)
    case homebrew(prefix: String, formula: String, version: String)
    case managed(String)
    case system, appleDeveloperTools, forwarded, unknown

    var supportsUpdateCheck: Bool {
        switch self {
        case .standalone, .homebrew: return true
        default: return false
        }
    }
}

enum EnvironmentUpdateStatus: Equatable {
    case available(String)
    case current(String)
    case ahead(String)
    case unsupported, failed
}

struct EnvironmentUpdateResult {
    var status: EnvironmentUpdateStatus
    var isPinned = false
    var isDependency = false
    var package: HomebrewPackage?
}

struct EnvironmentHomebrewSnapshot {
    let packages: [HomebrewPackage]
    let updates: [String: HomebrewPackageUpdate]
}

struct EnvironmentUpdateRecord {
    let source: EnvironmentUpdateSource
    var result: EnvironmentUpdateResult?
    var checkedAt: Date?

    var isVisible: Bool {
        source.supportsUpdateCheck && result?.status != .unsupported
            && result?.isPinned != true && result?.isDependency != true
    }
}

enum EnvironmentUpdateSupport {
    static func source(command: String, path: String, resolvedPath: String,
                       home: String, isWrapper: Bool) -> EnvironmentUpdateSource {
        let paths = [path, resolvedPath]
        // This macOS entry point dispatches to the selected Apple developer toolchain.
        if paths.contains("/usr/bin/python3") { return .appleDeveloperTools }
        if paths.contains(where: { $0.hasPrefix("/usr/bin/") || $0.hasPrefix("/System/") }) {
            return .system
        }
        if paths.contains(where: {
            $0.hasPrefix("/Library/Developer/CommandLineTools/")
                || $0.hasPrefix("/Applications/Xcode.app/Contents/Developer/")
        }) {
            return .appleDeveloperTools
        }
        let managers = [
            ("mise", [home + "/.local/share/mise", home + "/.config/mise"]),
            ("asdf", [home + "/.asdf"]), ("nvm", [home + "/.nvm"]),
            ("fnm", [home + "/.local/share/fnm", home + "/Library/Application Support/fnm"]),
            ("Volta", [home + "/.volta"]), ("pyenv", [home + "/.pyenv"]),
            ("Conda", [home + "/miniforge3", home + "/miniconda3", home + "/anaconda3",
                       "/opt/anaconda3", "/opt/miniconda3", "/opt/miniforge3"])
        ]
        for (manager, roots) in managers {
            if roots.contains(where: { path.hasPrefix($0 + "/") || resolvedPath.hasPrefix($0 + "/") }) {
                return .managed(manager)
            }
        }
        for prefix in ["/opt/homebrew", "/usr/local"] {
            let cellar = prefix + "/Cellar/"
            guard resolvedPath.hasPrefix(cellar) else { continue }
            let parts = resolvedPath.dropFirst(cellar.count).split(separator: "/")
            if parts.count >= 3, HomebrewCommandBuilder.isValidToken(String(parts[0])) {
                return .homebrew(prefix: prefix, formula: String(parts[0]), version: String(parts[1]))
            }
        }
        if isWrapper || (resolvedPath as NSString).lastPathComponent != command { return .forwarded }
        if command == "bun", resolvedPath == home + "/.bun/bin/bun" { return .standalone("bun") }
        if command == "uv", resolvedPath == home + "/.local/bin/uv" { return .standalone("uv") }
        return .unknown
    }

    // Validate at this boundary: the app updater's legacy parser accepts partial versions.
    static func stableVersion(_ raw: String) -> UpdateServiceSupport.SemanticVersion? {
        guard raw.range(of: #"^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)(\+[0-9A-Za-z.-]+)?$"#,
                        options: .regularExpression) != nil else { return nil }
        let numbers = raw.split(separator: "+")[0].split(separator: ".").compactMap { Int($0) }
        guard numbers.count == 3 else { return nil }
        return UpdateServiceSupport.SemanticVersion(major: numbers[0], minor: numbers[1], patch: numbers[2])
    }

    static func comparison(current: String, latest: String) -> EnvironmentUpdateStatus {
        let raw = current.hasPrefix("uv ")
            ? String(current.dropFirst(3).split(separator: " ").first ?? "") : current
        guard let installed = stableVersion(raw) else { return .unsupported }
        guard let available = stableVersion(latest) else { return .failed }
        if available > installed { return .available(latest) }
        return available == installed ? .current(latest) : .ahead(latest)
    }

    static func releaseVersion(_ data: Data, tool: String) -> String? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              json["draft"] as? Bool == false, json["prerelease"] as? Bool == false,
              let tag = json["tag_name"] as? String else { return nil }
        let prefix = tool == "bun" ? "bun-v" : ""
        guard tag.hasPrefix(prefix) else { return nil }
        let version = String(tag.dropFirst(prefix.count))
        return stableVersion(version) == nil ? nil : version
    }

    static func homebrewResult(source: EnvironmentUpdateSource, packages: [HomebrewPackage],
                               updates: [String: HomebrewPackageUpdate]) -> EnvironmentUpdateResult {
        guard case let .homebrew(_, formula, version) = source else {
            return EnvironmentUpdateResult(status: .unsupported)
        }
        let matches = packages.filter {
            $0.kind == .formula && ($0.name as NSString).lastPathComponent == formula
                && ($0.installedVersion?.components(separatedBy: ", ").contains(version) == true)
        }
        guard matches.count == 1, var package = matches.first else {
            return EnvironmentUpdateResult(status: .unsupported)
        }
        let update = updates[package.id] ?? updates["formula:" + formula]
        let status: EnvironmentUpdateStatus
        if let update {
            status = .available(update.currentVersion)
        } else if let stable = package.stableVersion, !stable.isEmpty {
            status = .current(stable)
        } else {
            status = .unsupported
        }
        package.update = update
        return EnvironmentUpdateResult(status: status,
                                       isPinned: update?.isPinned ?? false,
                                       isDependency: !package.installedOnRequest, package: package)
    }
}
