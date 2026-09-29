// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint
import Foundation

enum URLRuleImportTests {
    static func run(_ expect: (Bool, String) -> Void) {
        func data(_ rows: String) -> Data { Data(("{\"format\":\"kururu-url-rules\",\"version\":1,\"rules\":[" + rows + "]}").utf8) }
        func row(_ host: String, _ name: String, _ enabled: Bool = true) -> String {
            "{\"host\":\"\(host)\",\"name\":\"\(name)\",\"enabled\":\(enabled)}"
        }
        func rejected(_ value: Data) -> Bool { (try? URLRuleImportSupport.decode(value)) == nil }
        for name in ["shareRedId", "exSource"] {
            expect(URLCleaning.clean("https://www.xiaohongshu.com/?\(name)=tracking&keep=1")?.url == "https://www.xiaohongshu.com/?keep=1", "built-in mixed case parameter cleans: \(name)")
        }
        if let known = try? URLRuleImportSupport.decode(data(row("xiaohongshu.com", "shareRedId", false) + "," + row("xiaohongshu.com", "exSource", false))) {
            let preview = URLRuleImportSupport.preview(known, current: .none)
            expect(preview.addedCount == 0 && preview.changedCount == 2, "mixed case built-ins are state changes, not custom duplicates")
            expect(preview.rules.added.isEmpty, "mixed case built-ins do not create explicit added rows")
            let restored = (try? URLRuleImportSupport.export(current: preview.rules)).flatMap { try? URLRuleImportSupport.decode($0) }.map { URLRuleImportSupport.preview($0, current: .none).rules }
            expect(restored == preview.rules, "normalized built-in states roundtrip")
        } else { expect(false, "mixed case built-in import decodes") }
        let original = URLCleaning.Rules(added: ["": ["mine"], "example.com": ["off"]], disabled: ["example.com": ["off"]])
        if let document = try? URLRuleImportSupport.decode(data(row("", "mine", false) + "," + row("example.com", "off") + "," + row("example.com", "new", false) + "," + row("", "utm_*", false))) {
            let result = URLRuleImportSupport.preview(document, current: original)
            expect(result.baseRules == original, "preview retains base snapshot")
            expect(result.rules.added[""] == ["mine"], "existing enabled preserved")
            expect(result.rules.disabled["example.com"] == ["off", "new"], "existing disabled preserved, new disabled inserted")
            expect(result.rules.added["example.com"] == ["off", "new"], "new disabled custom remains visible")
            expect(result.rules.disabled[""] == ["utm_*"], "import may disable default built-in")
            expect(result.addedCount == 1 && result.changedCount == 1 && result.duplicateCount == 2, "preview counts reflect actual effect")
        } else { expect(false, "valid document decodes") }
        expect(original.disabled[""] == nil, "preview has no mutation")
        let builtinEnabled = try? URLRuleImportSupport.decode(data(row("", "utm_*")))
        expect(builtinEnabled.map { URLRuleImportSupport.preview($0, current: .none).duplicateCount } == 1, "default enabled is unchanged")
        let encoded = try? URLRuleImportSupport.export(current: original)
        expect(encoded != nil, "export succeeds")
        expect(encoded == (try? URLRuleImportSupport.export(current: original)), "export deterministic")
        let decoded = encoded.flatMap { try? URLRuleImportSupport.decode($0) }
        expect(decoded.map { URLRuleImportSupport.preview($0, current: .none).rules } == original, "explicit delta roundtrip")
        expect(decoded?.rows.count == 2, "export excludes default built-ins")
        let disabledBuiltin = URLCleaning.Rules(disabled: ["": ["utm_*"]])
        let restored = (try? URLRuleImportSupport.export(current: disabledBuiltin)).flatMap { try? URLRuleImportSupport.decode($0) }.map { URLRuleImportSupport.preview($0, current: .none).rules }
        expect(restored == disabledBuiltin, "disabled built-in roundtrip")
        let cleanRules = decoded.map { URLRuleImportSupport.preview($0, current: .none).rules } ?? .none
        expect(URLCleaning.clean("https://sub.example.com/?mine=1&off=2&keep=3", rules: cleanRules)?.url == "https://sub.example.com/?off=2&keep=3", "real cleaner consumes restored rules")
        for invalid in [Data(), Data("[]".utf8), Data("{\"providers\":{}}".utf8), data(row("example.com/path", "x")), data(row("example.com:80", "x")), data(row("-bad.com", "x")), data(row("x..com", "x")), data(row("example.com", "a|b")), data(row("example.com", "a,b")), data(row("example.com", "a=b")), data(row("example.com", "a b")), data(row("example.com", "foo*")), data(row("example.com", "utm_*")), data(row("", "x") + "," + row("", "X", false)), data(row("", "x") + "," + row("", "x")), Data("{\"format\":\"kururu-url-rules\",\"version\":2,\"rules\":[]}".utf8), Data("{\"format\":\"kururu-url-rules\",\"version\":true,\"rules\":[]}".utf8), data("{\"host\":\"\",\"name\":\"x\",\"enabled\":1}"), data("{\"host\":\"\",\"name\":\"x\",\"enabled\":true,\"unknown\":1}"), data(row("", String(repeating: "a", count: 257)))] {
            expect(rejected(invalid), "reject malformed or unsupported rule: \(String(data: invalid, encoding: .utf8)?.prefix(80) ?? "")")
        }
        expect(rejected(Data(#"{"format":"kururu-url-rules","version":1,"version":1,"rules":[]}"#.utf8)), "duplicate object member rejected")
        expect(rejected(data(#"{"host":"","name":"x","name":"y","enabled":true}"#)), "duplicate rule member rejected")
        expect(rejected(Data(#"{"format":"kururu-url-rules","version":1,"rules":[],}"#.utf8)), "trailing comma rejected")
        expect(!rejected(data(row(String(repeating: "a", count: 63) + ".com", "x"))), "host label 63 accepted")
        expect(rejected(data(row(String(repeating: "a", count: 64) + ".com", "x"))), "host label 64 rejected")
        let longHost = [63,63,63,61].map { String(repeating: "a", count: $0) }.joined(separator: ".")
        expect(!rejected(data(row(longHost, "x"))), "host 253 bytes accepted")
        expect(rejected(data(row(longHost + "a", "x"))), "host 254 bytes rejected")
        expect(!rejected(data((0..<2048).map { row("", "p\($0)") }.joined(separator: ","))), "2048 entries accepted")
        expect(rejected(data(row("", String(repeating: "中", count: 86)))), "name bound counts UTF8 bytes")
        expect(!rejected(data(row("xn--fsqu00a.xn--0zwm56d", "x"))), "IDN uses explicit punycode host")
        expect(!rejected(data(row("EXAMPLE.COM", "Campaign"))), "canonicalize ASCII case")
        expect(!rejected(data(row("", String(repeating: "a", count: 256)))), "name limit inclusive")
        let small = data("")
        expect(!rejected(small + Data(repeating: 32, count: 262144 - small.count)), "256 KiB accepted")
        expect(rejected(small + Data(repeating: 32, count: 262145 - small.count)), "over 256 KiB rejected")
        expect(rejected(data((0...2048).map { row("", "p\($0)") }.joined(separator: ","))), "entry count bounded")
    }
}
