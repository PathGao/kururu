// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

struct EnvironmentConfiguration: Identifiable {
    let path: String
    let scope: String
    var id: String { path }
    var name: String { URL(fileURLWithPath: path).lastPathComponent }

    static func discover(home: String = NSHomeDirectory(),
                         environment: [String: String] = ProcessInfo.processInfo.environment,
                         systemRoot: String = "/etc") -> [Self] {
        let xdg = environment["XDG_CONFIG_HOME"].flatMap { $0.hasPrefix("/") ? $0 : nil } ?? home + "/.config"
        let zsh = environment["ZDOTDIR"].flatMap { $0.hasPrefix("/") ? $0 : nil } ?? home
        let user = [".zshenv", ".zprofile", ".zshrc", ".zlogin"].map { zsh + "/" + $0 }
            + [".bash_profile", ".bashrc", ".profile", ".npmrc", ".gitconfig", ".tool-versions", ".condarc", ".bunfig.toml"].map { home + "/" + $0 }
            + ["fish/config.fish", "mise/config.toml", "uv/uv.toml", "pip/pip.conf"].map { xdg + "/" + $0 }
        return existing(user, scope: "user") + existing(
            ["zshenv", "zprofile", "zshrc", "profile", "paths"].map { systemRoot + "/" + $0 }, scope: "system")
    }

    static func discoverProject(_ directory: String) -> [Self] {
        existing([".python-version", ".node-version", ".nvmrc", ".tool-versions", "mise.toml", ".mise.toml", "pyproject.toml", "uv.toml", "package.json", ".npmrc", "bunfig.toml", ".envrc"]
            .map { directory + "/" + $0 }, scope: "project")
    }

    private static func existing(_ paths: [String], scope: String) -> [Self] {
        paths.filter { path in
            (try? URL(fileURLWithPath: path).resourceValues(forKeys: [.isRegularFileKey]).isRegularFile) == true
        }.map { Self(path: $0, scope: scope) }
    }
}
