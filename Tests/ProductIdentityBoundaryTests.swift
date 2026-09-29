// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

enum ProductIdentityBoundaryTests {
    static func run(_ expect: (Bool, String) -> Void) {
        expect(DockClickSupport.isOwnBundleIdentifier(ProductIdentity.releaseBundleID), "release kururu is protected from its Dock interception")
        expect(DockClickSupport.isOwnBundleIdentifier(ProductIdentity.developmentBundleID), "developer kururu is protected from its Dock interception")
        expect(!DockClickSupport.isOwnBundleIdentifier("com.vorssaint.utils"), "upstream release is not classified as this product")
        expect(!DockClickSupport.isOwnBundleIdentifier("com.vorssaint.utils.dev"), "upstream developer is not classified as this product")
        expect(!DockClickSupport.isOwnBundleIdentifier(nil), "missing bundle identity is never owned")
        expect(ProductIdentityBoundarySupport.ownedBundleID(nil) == nil, "unbundled process cannot authorize removal")
        expect(ProductIdentityBoundarySupport.ownedBundleID("com.example.foreign") == nil, "foreign process cannot authorize removal")
        for development in [false, true] {
            let rule = ProductIdentityBoundarySupport.sudoersRulePath(development: development)
            expect(!URL(fileURLWithPath: rule).lastPathComponent.contains("."), "sudoers filename is eligible for includedir")
            expect(rule == (development ? "/etc/sudoers.d/kururu-dev-clamshell" : "/etc/sudoers.d/kururu-clamshell"), "variant rule is isolated")
        }
        for id in [ProductIdentity.releaseBundleID, ProductIdentity.developmentBundleID, ProductIdentity.releaseBundleID + ".fan-control", "group." + ProductIdentity.releaseBundleID, "com.vorssaint.utils"] {
            expect(CleanerSupport.isProtectedBundleID(id), "cleaner retains own and upstream domains: " + id)
        }
        expect(!CleanerSupport.isProtectedBundleID("com.pathgao.kururux"), "cleaner protection respects component boundaries")
        expect(CleanerPolicy.isExcludedCacheEntry(ProductIdentity.releaseBundleID), "release cache is hidden from cleaning")
        expect(CleanerPolicy.isExcludedCacheEntry(ProductIdentity.developmentBundleID), "developer cache is hidden from cleaning")
        expect(!CleanerPolicy.isExcludedCacheEntry("com.pathgao.kururux"), "unrelated cache remains eligible")
        expect(ProductIdentityBoundarySupport.ownedBundleID(ProductIdentity.unbundledStorageID) == nil, "unbundled storage cannot authorize application removal")
        expect(ProductIdentity.unbundledStorageID != ProductIdentity.releaseBundleID && ProductIdentity.unbundledStorageID != ProductIdentity.developmentBundleID && !ProductIdentity.unbundledStorageID.hasPrefix("com.vorssaint."), "standalone storage stays outside both installed variants and upstream")
        let fm = FileManager.default
        let fixtureRoot = fm.temporaryDirectory.appendingPathComponent("kururu-identity-tests-" + UUID().uuidString)
        defer { try? fm.removeItem(at: fixtureRoot) }
        do {
            try fm.createDirectory(at: fixtureRoot, withIntermediateDirectories: true)
            let script = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("Tools/uninstall.sh")
            func fixture(_ name: String, id: String, executable: String) throws -> URL {
                let app = fixtureRoot.appendingPathComponent(name + ".app")
                let macOS = app.appendingPathComponent("Contents/MacOS")
                try fm.createDirectory(at: macOS, withIntermediateDirectories: true)
                let plist = try PropertyListSerialization.data(fromPropertyList: ["CFBundleIdentifier": id, "CFBundleExecutable": executable], format: .xml, options: 0)
                try plist.write(to: app.appendingPathComponent("Contents/Info.plist"))
                let binary = macOS.appendingPathComponent(executable)
                try Data("#!/bin/sh\nexit 97\n".utf8).write(to: binary)
                try fm.setAttributes([.posixPermissions: 0o700], ofItemAtPath: binary.path)
                return app
            }
            func validate(_ app: URL, development: Bool) throws -> (Int32, String) {
                let process = Process(), pipe = Pipe()
                process.executableURL = URL(fileURLWithPath: "/bin/zsh")
                process.arguments = [script.path, "--dry-run", "--app", app.path] + (development ? ["--dev"] : [])
                process.standardOutput = pipe
                process.standardError = pipe
                try process.run()
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                process.waitUntilExit()
                return (process.terminationStatus, String(decoding: data, as: UTF8.self))
            }
            for development in [false, true] {
                let app = try fixture(development ? "dev" : "release", id: ProductIdentity.bundleID(development: development), executable: ProductIdentity.executableName(development: development))
                let result = try validate(app, development: development)
                expect(result.0 == 0, "verified variant dry validation succeeds without executing app")
                expect(result.1.contains("BUNDLE=" + ProductIdentity.bundleID(development: development)), "uninstaller uses canonical variant identity")
                expect(result.1.contains("RULE=" + ProductIdentityBoundarySupport.sudoersRulePath(development: development)), "script and service rule paths agree")
                expect(fm.fileExists(atPath: app.path), "dry validation retains application")
                expect(try validate(app, development: !development).0 != 0, "opposite variant cannot authorize removal")
            }
            let upstream = try fixture("upstream", id: "com.vorssaint.utils", executable: ProductIdentity.executableName(development: false))
            expect(try validate(upstream, development: false).0 != 0, "upstream bundle cannot authorize removal")
            expect(fm.fileExists(atPath: upstream.path), "rejected upstream remains untouched")
            expect(try validate(fixtureRoot.appendingPathComponent("missing.app"), development: false).0 != 0, "missing application fails closed")
            let link = fixtureRoot.appendingPathComponent("linked.app")
            try fm.createSymbolicLink(at: link, withDestinationURL: upstream)
            expect(try validate(link, development: false).0 != 0, "symbolic application path fails closed")
        } catch {
            expect(false, "identity fixture validation error: \(error)")
        }
    }
}
