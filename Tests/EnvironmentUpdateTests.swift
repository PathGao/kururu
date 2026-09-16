import Foundation

enum EnvironmentUpdateTests {
    static func run(_ expect: (Bool, String) -> Void) {
        let home = "/Users/example"
        func source(_ command: String, _ path: String, resolved: String? = nil,
                    wrapper: Bool = false) -> EnvironmentUpdateSource {
            EnvironmentUpdateSupport.source(command: command, path: path,
                resolvedPath: resolved ?? path, home: home, isWrapper: wrapper)
        }
        expect(source("bun", home + "/.bun/bin/bun") == .standalone("bun"),
               "standalone Bun is eligible for a stable release check")
        expect(source("uv", home + "/.local/bin/uv") == .standalone("uv"),
               "standalone uv location offers release information")
        expect(source("bun", home + "/.bun/bin/bun", resolved: home + "/.local/share/mise/installs/bun/1.3.0/bin/bun") == .managed("mise"),
               "a symlink into a managed version must not offer standalone updates")
        expect(source("bun", home + "/.asdf/shims/bun", wrapper: true) == .managed("asdf"),
               "manager shims retain the manager identity")
        expect(source("node", home + "/.nvm/versions/node/v24.0.0/bin/node") == .managed("nvm"),
               "versioned Node stays with its manager")
        expect(source("python3", "/usr/bin/python3") == .appleDeveloperTools,
               "Apple's Python entry point retains its developer-tool origin")
        expect(source("true", "/usr/bin/true") == .system,
               "an ordinary macOS executable retains its system origin")
        expect(source("python3", "/Library/Developer/CommandLineTools/usr/bin/python3") == .appleDeveloperTools,
               "Apple developer tools are identified separately from user-managed Python")
        expect(source("python3", "/usr/local/bin/python3", resolved: "/Library/Developer/CommandLineTools/usr/bin/python3") == .appleDeveloperTools,
               "a user bin symlink to Apple Python retains its bundled origin")
        expect(source("node", home + "/.local/bin/node", resolved: home + "/.bun/bin/bun") == .forwarded,
               "Node forwarding to Bun must not be compared with Node releases")
        expect(source("bun", home + "/.bun/bin/bun", wrapper: true) == .forwarded,
               "a wrapper in a standalone location is not an independent installation")
        expect(source("uv", "/opt/homebrew/bin/uv", resolved: "/opt/homebrew/Cellar/uv/0.12.9/bin/uv")
                == .homebrew(prefix: "/opt/homebrew", formula: "uv", version: "0.12.9"),
               "Homebrew ownership is matched to the resolved keg, not the command name")
        expect(source("uv", "/opt/homebrew/bin/uv") == .unknown,
               "merely being inside a Homebrew bin directory does not establish ownership")
        expect(source("bun", "/elsewhere/bun") == .unknown,
               "unknown installations do not get a guessed update channel")
        expect(EnvironmentUpdateSupport.comparison(current: "1.4.0", latest: "1.4.2") == .available("1.4.2"),
               "older stable Bun reports the available version")
        expect(EnvironmentUpdateSupport.comparison(current: "uv 0.9.9 (build)", latest: "0.10.0") == .available("0.10.0"),
               "versions are compared numerically, with uv's version prefix removed")
        expect(EnvironmentUpdateSupport.comparison(current: "1.4.2", latest: "1.4.2") == .current("1.4.2"),
               "equal stable versions report no update")
        expect(EnvironmentUpdateSupport.comparison(current: "1.5.0", latest: "1.4.2") == .ahead("1.4.2"),
               "a newer installed version must not be presented as a downgrade target")
        expect(EnvironmentUpdateSupport.comparison(current: "1.5.0-canary.1", latest: "1.4.2") == .unsupported,
               "prerelease installations do not silently switch to the stable channel")
        for invalid in ["unknown", "1.oops.2", "1.2", "1.2.3.4", "", "999999999999999999999.0.0"] {
            expect(EnvironmentUpdateSupport.comparison(current: invalid, latest: "1.4.2") == .unsupported,
                   "unparseable installed version must not look up to date: \(invalid)")
        }
        let release = Data(#"{"tag_name":"bun-v1.4.2","draft":false,"prerelease":false}"#.utf8)
        expect(EnvironmentUpdateSupport.releaseVersion(release, tool: "bun") == "1.4.2",
               "Bun's official tag prefix is normalized")
        for body in [#"{"tag_name":"bun-v1.4.2","prerelease":true,"draft":false}"#,
                     #"{"tag_name":"bun-v1.4.2","prerelease":false,"draft":true}"#,
                     #"{"message":"API rate limit exceeded"}"#,
                     #"{"tag_name":"bun-v1.x.2","prerelease":false,"draft":false}"#] {
            expect(EnvironmentUpdateSupport.releaseVersion(Data(body.utf8), tool: "bun") == nil,
                   "invalid releases and API failures never become a successful version check")
        }
        let brew = EnvironmentUpdateSource.homebrew(prefix: "/opt/homebrew", formula: "uv", version: "0.12.9")
        let package = HomebrewPackage(kind: .formula, name: "uv", displayName: "uv",
            installedVersion: "0.12.9", stableVersion: "0.12.10", installedOnRequest: false)
        let update = HomebrewPackageUpdate(kind: .formula, name: "uv", installedVersions: ["0.12.9"],
            currentVersion: "0.12.10", isPinned: true)
        let result = EnvironmentUpdateSupport.homebrewResult(source: brew, packages: [package], updates: [update.id: update])
        expect(result.status == .available("0.12.10") && result.isPinned && result.isDependency,
               "pinned dependencies keep both restrictions alongside the available update")
        expect(EnvironmentUpdateSupport.homebrewResult(source: brew, packages: [], updates: [:]).status == .unsupported,
               "an unverified keg cannot be declared up to date")
        expect(EnvironmentUpdateSupport.homebrewResult(source: brew, packages: [package], updates: [:]).status == .current("0.12.10"),
               "a successful Homebrew check uses Homebrew's decision, not upstream stableVersion")
        for invalid in ["{}", "[]", #"{"formulae":"invalid","casks":[]}"#,
                        #"{"formulae":[{"name":"uv"}],"casks":[]}"#] {
            expect((try? HomebrewParser.parseOutdatedCommandOutput(invalid)) == nil,
                   "malformed Homebrew output must fail rather than become no updates: \(invalid)")
        }
        expect((try? HomebrewParser.parseOutdatedCommandOutput(#"{"formulae":[],"casks":[]}"#))?.isEmpty == true,
               "a valid empty Homebrew response still means no updates")
        var headOnly = package
        headOnly.stableVersion = nil
        expect(EnvironmentUpdateSupport.homebrewResult(source: brew, packages: [headOnly], updates: [:]).status == .unsupported,
               "missing stable metadata must not be replaced by an invented stable version")
        let tapped = HomebrewPackage(kind: .formula, name: "owner/tap/uv", displayName: "uv",
            installedVersion: "0.12.9", stableVersion: "0.12.10")
        let tappedResult = EnvironmentUpdateSupport.homebrewResult(source: brew, packages: [tapped], updates: [update.id: update])
        expect(tappedResult.package?.name == "owner/tap/uv" && tappedResult.package?.update?.isPinned == true,
               "upgrade target preserves full tap identity and pin metadata")
        let report = EnvironmentReport(tools: [EnvironmentTool(command: "bun", path: home + "/.bun/bin/bun",
            version: "1.5.0", shimTarget: nil, shadowedPaths: [])])
        let records = ["bun": EnvironmentUpdateRecord(source: .standalone("bun"),
            result: EnvironmentUpdateResult(status: .ahead("1.4.2")), checkedAt: Date(timeIntervalSince1970: 0))]
        let diagnostic = EnvironmentInspector.diagnosticText(report, updates: records)
        expect(diagnostic.contains("1.5.0") && diagnostic.contains("1.4.2") && diagnostic.contains("1970-01-01"),
               "diagnostics retain installed version, queried stable version and check time")
        for language in [AppLanguage.enUS, .zhHans, .de, .fr, .es, .ja] {
            let strings = EnvironmentUpdateStrings(language: language)
            expect(strings.status(.ahead("1.4.2")).contains("1.4.2")
                && strings.status(.current("1.4.2")).contains("1.4.2"),
                   "equal and newer installations retain the queried version in \(language)")
        }
        for origin in [EnvironmentUpdateSource.system, .appleDeveloperTools, .managed("Conda"), .forwarded, .unknown] {
            expect(!origin.supportsUpdateCheck, "non-independent sources must not enter update checks: \(origin)")
            expect(!EnvironmentUpdateRecord(source: origin, result: EnvironmentUpdateResult(status: .available("9.0.0"))).isVisible,
                   "even a stale update result must not show an upgrade prompt for \(origin)")
        }
        expect(EnvironmentUpdateRecord(source: .standalone("bun"), result: EnvironmentUpdateResult(status: .available("1.4.2"))).isVisible,
               "user-installed Bun keeps its useful update prompt")
        expect(EnvironmentUpdateRecord(source: brew, result: EnvironmentUpdateResult(status: .failed)).isVisible,
               "a supported tool's failed check remains visible rather than looking current")
        for excluded in [EnvironmentUpdateResult(status: .unsupported), result] {
            expect(!EnvironmentUpdateRecord(source: brew, result: excluded).isVisible,
                   "unsupported installations, pinned versions and dependencies do not produce upgrade clutter")
        }
        let systemTool = EnvironmentInspector.tool(named: "python3", in: ["/usr/bin"])
        expect(systemTool.source == .appleDeveloperTools, "local inspection identifies Apple's Python without a network update check")
        let systemReport = EnvironmentInspector.diagnosticText(EnvironmentReport(tools: [systemTool]),
            updates: ["python3": EnvironmentUpdateRecord(source: .appleDeveloperTools,
                result: EnvironmentUpdateResult(status: .available("9.0.0")))])
        expect(systemReport.contains("source: Included with Apple developer tools") && !systemReport.contains("update:"),
               "system Python retains its source in reports but cannot inherit an upgrade prompt")
    }
}
