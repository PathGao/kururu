// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import Foundation

enum FinderArrangementTests {
    static func run(_ expect: (Bool, String) -> Void) {
        expect(FinderArrangementSupport.failure(-1712) == .timedOut, "event timeout is not generic failure")
        let snapshot = FinderArrangementSnapshot(windowID: 42, path: "/tmp/example", rule: .none)
        let script = FinderArrangementSupport.changeScript(snapshot, to: .name)
        expect(script.contains("Finder window id 42"), "fixed window identity")
        expect(script.contains("/tmp/example"), "fixed folder identity")
        expect(script.contains("current view") && script.contains("icon view"), "view recheck")
        expect(script.contains("arrangement") && script.contains("arranged by name"), "persistent property")
        expect(!script.contains("clean up"), "no one-shot cleanup")
        expect(FinderArrangementSupport.parse("42\n0\n/tmp/example") == snapshot, "snapshot decode")
        expect(FinderArrangementSupport.parse("42\n0\n/tmp/line\nname")?.path == "/tmp/line\nname", "newline path preserved")
        expect(FinderArrangementSupport.parse("42\n99\n/tmp/example") == nil, "unknown rule rejected")
        expect(FinderArrangementSupport.parse("0\n0\n/tmp/example") == nil, "invalid identity rejected")


        var calls = 0
        var reply: FinderArrangementClient.Reply = (true, nil, "", "42\n0\n/tmp/example")
        var client = FinderArrangementClient(run: { _ in calls += 1; return reply }, acceptsPath: { $0.hasPrefix("/tmp/") })
        expect(client.capture() == .success(snapshot), "capture actual client")
        reply.output = "42\n2\n/tmp/example"
        expect(client.change(snapshot, to: .name) == .success(FinderArrangementSnapshot(windowID: 42, path: snapshot.path, rule: .name)), "successful readback")
        reply.output = "43\n2\n/tmp/example"
        expect(client.change(snapshot, to: .name) == .failure(.changed), "wrong window reply")
        reply.output = "42\n2\n/tmp/other"
        expect(client.change(snapshot, to: .name) == .failure(.changed), "wrong folder reply")
        reply.output = "42\n0\n/tmp/example"
        expect(client.change(snapshot, to: .name) == .failure(.changed), "write did not stick")
        for (number, error) in [(-1743, FinderArrangementFailure.permission), (-1744, .permission), (-128, .canceled), (-1712, .timedOut), (1701, .unsupported), (1702, .changed), (-1, .failed)] {
            reply = (false, number, "", "")
            expect(client.capture() == .failure(error), "capture error \(number)")
            expect(client.change(snapshot, to: .name) == .failure(error), "write error \(number)")
        }
        let before = calls
        client.acceptsPath = { _ in false }
        expect(client.change(snapshot, to: .name) == .failure(.unsupported) && calls == before, "unsafe path never sends write")
        expect(script.contains("is not not arranged"), "external rule precondition")
        expect(!FinderArrangementSupport.captureScript.contains("set arrangement"), "capture cannot write")
        expect(script.contains("desktop window") && script.contains("class of target"), "special view rejection")
        expect(FinderArrangementSupport.literal("a\"b\\c") == "\"a\\\"b\\\\c\"", "script path quoting")
        for rule in FinderArrangementRule.allCases {
            expect(FinderArrangementSupport.changeScript(snapshot, to: rule).contains("set arrangement of icon view options of w to " + rule.scriptValue), "restore enum \(rule)")
        }
        let languages: [AppLanguage] = [.enUS, .zhHans, .de, .fr, .es, .ja, .ptBR, .tr, .ru, .it, .ko, .zhTW, .zhHK]
        for language in languages {
            let strings = FinderArrangementStrings.localized(language)
            expect(strings.rules.count == 8 && !strings.caption.isEmpty && !strings.failure(.failed).isEmpty && !strings.failure(.timedOut).isEmpty, "strings \(language)")
        }
    }
}
