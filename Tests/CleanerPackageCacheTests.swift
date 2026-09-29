// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import Foundation

enum CleanerPackageCacheTests {
    static func run(_ expect: (Bool, String) -> Void) {
        let fm = FileManager.default
        let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent(".build/cleaner-cache-fixture-" + UUID().uuidString)
        defer { try? fm.removeItem(at: root) }
        do {
            let home = root.appendingPathComponent("home")
            let npx = home.appendingPathComponent(".npm/_npx")
            let bun = home.appendingPathComponent(".bun/install/cache")
            let project = home.appendingPathComponent("project/node_modules")
            for directory in [npx, bun, project] {
                try fm.createDirectory(at: directory, withIntermediateDirectories: true)
                try Data(repeating: 7, count: 16384).write(to: directory.appendingPathComponent("payload"))
            }
            let found = CleanerPackageCaches.scan(home: home)
            expect(Set(found.map { $0.url.path }) == Set([npx.path, bun.path]),
                   "cleaner discovers both package download caches without project node_modules")
            expect(found.count == 2 && found.allSatisfy { $0.size > 0 },
                   "package cache findings include nonzero allocated sizes")
            expect(fm.fileExists(atPath: npx.appendingPathComponent("payload").path)
                   && fm.fileExists(atPath: bun.appendingPathComponent("payload").path),
                   "cache discovery never removes files")
            expect(CleanerPackageCaches.scan(home: root.appendingPathComponent("missing")).isEmpty,
                   "missing cache roots produce no findings")

            let emptyHome = root.appendingPathComponent("empty")
            try fm.createDirectory(at: emptyHome.appendingPathComponent(".npm/_npx"),
                                   withIntermediateDirectories: true)
            expect(CleanerPackageCaches.scan(home: emptyHome).isEmpty,
                   "empty cache directories are not offered")
            let fileHome = root.appendingPathComponent("files")
            try fm.createDirectory(at: fileHome.appendingPathComponent(".npm"),
                                   withIntermediateDirectories: true)
            try Data(repeating: 1, count: 8192).write(to: fileHome.appendingPathComponent(".npm/_npx"))
            expect(CleanerPackageCaches.scan(home: fileHome).isEmpty,
                   "a regular file at a known cache path is never offered")

            let linkHome = root.appendingPathComponent("links")
            try fm.createDirectory(at: linkHome.appendingPathComponent(".npm"),
                                   withIntermediateDirectories: true)
            try fm.createSymbolicLink(at: linkHome.appendingPathComponent(".npm/_npx"),
                                      withDestinationURL: project)
            try fm.createSymbolicLink(at: linkHome.appendingPathComponent(".bun"),
                                      withDestinationURL: home.appendingPathComponent(".bun"))
            expect(CleanerPackageCaches.scan(home: linkHome).isEmpty,
                   "cache paths with a linked root or ancestor are rejected")
            let before = found.first { $0.url.path == npx.path }?.size
            try fm.createSymbolicLink(at: npx.appendingPathComponent("external"),
                                      withDestinationURL: project)
            let after = CleanerPackageCaches.scan(home: home).first { $0.url.path == npx.path }?.size
            expect(before != nil && before == after,
                   "cache size does not follow internal links into project data")

            try fm.setAttributes([.posixPermissions: 0], ofItemAtPath: bun.path)
            defer { try? fm.setAttributes([.posixPermissions: 0o700], ofItemAtPath: bun.path) }
            expect(!CleanerPackageCaches.scan(home: home).contains { $0.url.path == bun.path },
                   "unreadable cache directories are not offered as complete findings")
        } catch {
            expect(false, "package cache fixture failed: \(error)")
        }
    }
}
