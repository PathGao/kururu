// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import Foundation

enum SettingsActionTests {
    static func run(_ expect: (Bool, String) -> Void) {
        backup(expect)
        permissions(expect)
        profiles(expect)
    }

    private static func backup(_ expect: (Bool, String) -> Void) {
        let fm = FileManager.default
        let root = URL(fileURLWithPath: fm.currentDirectoryPath)
            .appendingPathComponent(".build/backup-action-" + UUID().uuidString)
        defer { try? fm.removeItem(at: root) }
        do {
            try fm.createDirectory(at: root, withIntermediateDirectories: true)
            let target = root.appendingPathComponent("settings.plist")
            expect(SettingsBackupExport.write(["choice": "original"], to: nil) == .cancelled,
                   "cancelling export never attempts a write")
            expect(!fm.fileExists(atPath: target.path), "cancelled export leaves no backup file")
            expect(SettingsBackupExport.write(["choice": "original"], to: target) == .saved,
                   "export reports a completed file write")
            let data = try Data(contentsOf: target)
            let saved = try PropertyListSerialization.propertyList(from: data, format: nil) as? [String: String]
            expect(saved == ["choice": "original"], "exported backup contains the requested values")
            let invalid = SettingsBackupExport.write(["choice": NSObject()], to: target)
            if case .failed(let reason) = invalid {
                expect(!reason.isEmpty, "serialization failure carries an actionable reason")
            } else { expect(false, "serialization failure is not cancellation or success") }
            expect((try Data(contentsOf: target)) == data, "failed replacement preserves the previous backup")
            let missing = SettingsBackupExport.write(["choice": "new"],
                to: root.appendingPathComponent("missing/settings.plist"))
            if case .failed(let reason) = missing {
                expect(!reason.isEmpty, "unwritable destination carries a failure reason")
            } else { expect(false, "a failed file write is not cancellation or success") }
        } catch { expect(false, "backup action fixture failed: \(error)") }
    }

    private static func permissions(_ expect: (Bool, String) -> Void) {
        let cases: [(Bool, Bool, Bool, PermissionResetResult, [String])] = [
            (false, true, true, .preparationFailed, ["prepare"]),
            (true, false, true, .ruleRemovalFailed, ["prepare", "rule"]),
            (true, true, false, .resetFailed, ["prepare", "rule", "reset"]),
            (true, true, true, .completed, ["prepare", "rule", "reset"])
        ]
        for (prepared, removed, reset, expected, expectedSteps) in cases {
            var steps: [String] = []
            var result: PermissionResetResult?
            PermissionResetSupport.run(prepare: { steps.append("prepare"); return prepared },
                removeRule: { completion in steps.append("rule"); completion(removed) },
                reset: { steps.append("reset"); return reset },
                completion: { result = $0 })
            expect(result == expected, "permission reset reports the actual failed step: \(expected)")
            expect(steps == expectedSteps, "permission reset never runs later destructive steps after failure: \(expected)")
        }
        var finishRule: ((Bool) -> Void)?
        var result: PermissionResetResult?
        var resetCalls = 0
        PermissionResetSupport.run(prepare: { true }, removeRule: { finishRule = $0 },
            reset: { resetCalls += 1; return true }, completion: { result = $0 })
        expect(result == nil && resetCalls == 0, "permission reset waits for the administrator result")
        finishRule?(false)
        expect(result == .ruleRemovalFailed && resetCalls == 0,
               "a cancelled or failed administrator step cannot report success or reset TCC")
    }

    private static func profiles(_ expect: (Bool, String) -> Void) {
        let first = UUID(), target = UUID(), last = UUID(), missing = UUID()
        expect(RadialMenuProfileDeletion.index(of: target, in: [first, target, last]) == 1,
               "deletion identifies the confirmed profile, not the first profile")
        expect(RadialMenuProfileDeletion.index(of: target, in: [target, last, first]) == 0,
               "reordering before confirmation keeps the same deletion target")
        expect(RadialMenuProfileDeletion.index(of: missing, in: [first, target]) == nil,
               "a vanished confirmation target never falls back to another profile")
        expect(RadialMenuProfileDeletion.index(of: target, in: [target]) == nil,
               "the final profile remains protected at confirmation time")
        expect(RadialMenuProfileDeletion.index(of: target, in: []) == nil,
               "an empty profile list cannot be deleted")
    }
}
