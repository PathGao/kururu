// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint
import AppKit
import Darwin

enum UpstreamPolicyTests {
    static func run(_ expect: (Bool, String) -> Void) {
        // A failed lookup is not necessarily absence, and links can remain
        // even after their destination has disappeared.
        let absentFixture = FileManager.default.temporaryDirectory
            .appendingPathComponent("vorssaint-absent-\(UUID().uuidString)", isDirectory: true)
        try? FileManager.default.createDirectory(at: absentFixture, withIntermediateDirectories: true)
        let presentChild = absentFixture.appendingPathComponent("StillHere.app")
        try? "bundle".write(to: presentChild, atomically: true, encoding: .utf8)
        expect(!UninstallerSupport.isConfirmedAbsent(at: presentChild),
               "a path that still exists is not confirmed absent")
        try? FileManager.default.removeItem(at: presentChild)
        expect(UninstallerSupport.isConfirmedAbsent(at: presentChild),
               "a missing child under a readable parent is confirmed absent")
        let danglingLink = absentFixture.appendingPathComponent("Dangling.app")
        let danglingMade = symlink("/tmp/vorssaint-missing-target-\(UUID().uuidString)",
                                   danglingLink.path) == 0
        expect(danglingMade
               && !UninstallerSupport.isConfirmedAbsent(at: danglingLink),
               "a dangling symlink still occupies an entry and is not confirmed absent")
        try? FileManager.default.removeItem(at: danglingLink)
        let nestedParent = absentFixture.appendingPathComponent("NestedParent", isDirectory: true)
        let nestedChild = nestedParent.appendingPathComponent("Gone.app")
        try? FileManager.default.createDirectory(at: nestedParent, withIntermediateDirectories: true)
        try? "x".write(to: nestedChild, atomically: true, encoding: .utf8)
        try? FileManager.default.removeItem(at: nestedParent)
        expect(UninstallerSupport.isConfirmedAbsent(at: nestedChild),
               "when the item and its parent folder are both gone, absence is confirmed")
        let inaccessibleParent = absentFixture.appendingPathComponent("Restricted", isDirectory: true)
        let inaccessibleChild = inaccessibleParent.appendingPathComponent("StillHere.app")
        try? FileManager.default.createDirectory(at: inaccessibleParent, withIntermediateDirectories: true)
        let restrictedCreated = FileManager.default.createFile(atPath: inaccessibleChild.path, contents: Data("x".utf8))
        expect(restrictedCreated, "the permission fixture exists before access changes")
        if geteuid() != 0 {
            let accessRestricted = chmod(inaccessibleParent.path, 0) == 0
            expect(accessRestricted && !UninstallerSupport.isConfirmedAbsent(at: inaccessibleChild),
                   "a file that becomes inaccessible after selection remains a failure")
            let missingInRestrictedParent = inaccessibleParent.appendingPathComponent("Absent.app")
            expect(!UninstallerSupport.isConfirmedAbsent(at: missingInRestrictedParent),
                   "absence below an inaccessible parent is not assumed")
            expect(chmod(inaccessibleParent.path, 0o700) == 0,
                   "the permission fixture restores access")
        }
        expect(UninstallerSupport.fileIdentity(at: inaccessibleChild) != nil,
               "the inaccessible file remains present")
        let invalidChild = inaccessibleChild.appendingPathComponent("Child")
        expect(!UninstallerSupport.isConfirmedAbsent(at: invalidChild),
               "a parent replaced by a regular file is not treated as a confirmed removal")
        let loop = absentFixture.appendingPathComponent("Loop")
        let loopCreated = symlink("Loop", loop.path) == 0
        expect(loopCreated && !UninstallerSupport.isConfirmedAbsent(at: loop.appendingPathComponent("Child")),
               "a symbolic link loop is an error, not confirmed absence")
        try? FileManager.default.removeItem(at: inaccessibleChild)
        expect(UninstallerSupport.isConfirmedAbsent(at: inaccessibleChild),
               "the previously inaccessible file is recognized as absent only after removal")
        try? FileManager.default.removeItem(at: absentFixture)
        let name = "vorss.tests.upstream-placement.\(UUID())"
        let defaults = UserDefaults(suiteName: name)!
        defer { defaults.removePersistentDomain(forName: name) }
        let first = StatusItemPlacementSupport.autosaveName(forGeneration: 0)
        let metric = "NSStatusItem Preferred Position kururuMetric.cpu"
        defaults.set(42, forKey: metric)
        defaults.set(2, forKey: DefaultsKey.statusItemPlacementGeneration)
        defaults.set(50, forKey: StatusItemPlacementSupport.preferredPositionKey(for: first))
        StatusItemPlacementSupport.bumpPlacementGeneration(in: defaults)
        expect(defaults.object(forKey: StatusItemPlacementSupport.preferredPositionKey(for: first)) == nil,
               "reset removes stale main icon placement")
        expect(defaults.integer(forKey: metric) == 42, "reset preserves metric icon positions")
        expect(StatusItemAnchorSupport.isSettlingStatusFrame(nil), "missing frame may still be settling")
        expect(StatusItemAnchorSupport.isSettlingStatusFrame(CGRect(x: 0, y: 0, width: 30, height: 0)),
               "zero-height status item gets settlement grace")
        for grace in [0, 1, 8] {
            for onScreen in [false, true] {
                for settling in [false, true] {
                    expect(StatusItemPlacementSupport.shouldKeepWaitingForSettlement(
                        isOnScreen: onScreen, isSettling: settling, settlingGraceLeft: grace)
                        == (!onScreen && settling && grace > 0), "settlement grace is bounded and only for unsettled items")
                }
            }
        }
    }
}
