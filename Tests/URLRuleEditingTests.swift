// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

enum URLRuleEditingTests {
    static func run(_ expect: (Bool, String) -> Void) {
        let original = URLCleaning.Rules(added: ["youtube.com": ["custom"], "example.com": ["other"]],
                                         disabled: ["example.com": ["other"]])
        let paused = URLCleaning.settingGroupEnabled(false, site: "youtube.com", rules: original)
        expect(paused.added == original.added, "pausing a site preserves its custom rules")
        expect(paused.disabled["youtube.com"]?.contains("custom") == true, "pausing also disables custom parameters")
        expect(paused.disabled["example.com"] == original.disabled["example.com"], "pausing preserves unrelated site choices")
        let input = "https://youtube.com/watch?v=demo&si=tracking&custom=1&t=30"
        expect(URLCleaning.clean(input, rules: paused)?.url == input, "paused group stops built-in and custom cleaning")
        let resumed = URLCleaning.settingGroupEnabled(true, site: "youtube.com", rules: paused)
        expect(resumed == original, "enable all restores custom definitions and clears this group's disabled entries")
        expect(URLCleaning.clean(input, rules: resumed)?.url == "https://youtube.com/watch?v=demo&t=30", "resumed group cleans both kinds")
        let global = URLCleaning.Rules(added: ["": ["global_custom"]])
        let globalPaused = URLCleaning.settingGroupEnabled(false, site: "", rules: global)
        let globalInput = "https://example.com/?utm_source=demo&global_custom=1&keep=2"
        expect(URLCleaning.clean(globalInput, rules: globalPaused)?.url == globalInput, "global pause covers UTM wildcard and custom rule")
        expect(URLCleaning.settingGroupEnabled(true, site: "", rules: globalPaused) == global, "global custom definitions survive pause and resume")
        expect(URLCleaning.settingGroupEnabled(false, site: "missing.invalid", rules: original) == original, "unknown group is unchanged")
        expect(URLCleaning.settingGroupEnabled(false, site: "youtube.com", rules: paused) == paused, "pause is idempotent")

        var result = URLCleanerResultState()
        let cleaned = URLCleaning.Result(url: "https://example.com/?keep=1", removed: ["utm_source"])
        result.record(cleaned, input: "https://example.com/?utm_source=x&keep=1", rules: original)
        expect(result.canCopy && result.output == cleaned.url,
               "a freshly cleaned result can be copied")
        result.invalidateIfInputChanged(to: "https://example.com/?utm_source=y&keep=1")
        expect(!result.canCopy && result.output.isEmpty,
               "editing the input invalidates the old clean result")
        result.record(cleaned, input: "https://example.com/?utm_source=x&keep=1", rules: original)
        result.invalidateIfRulesChanged(to: paused)
        expect(!result.canCopy && result.output.isEmpty,
               "changing shared rules invalidates the old clean result")

        result.record(nil, input: "not a URL", rules: original)
        expect(result.invalidateIfInputChanged(to: "https://example.com"),
               "editing after an invalid result invalidates its stale status")
        result.record(nil, input: "not a URL", rules: original)
        expect(result.invalidateIfRulesChanged(to: paused),
               "changing rules after an invalid result invalidates its stale status")

        let english = UXTaskFlowStrings(language: .enUS)
        for language: AppLanguage in [.enUS, .zhHans, .de, .fr, .es, .ja] {
            let text = UXTaskFlowStrings(language: language)
            let values = [text.viewClipboard, text.useClipboard, text.automaticCapture,
                          text.recordCopiedContent, text.automaticCaptureCaption,
                          text.captureActive, text.capturePaused, text.dataManagement, text.relatedTools,
                          text.openURLCleaner, text.automaticURLCleaning,
                          text.automaticURLCaption, text.resultExpired, text.emptyCapturePaused,
                          text.emptyWaitingForCopy, text.emptyNoMatches, text.enableCapture, text.clearSearch]
            expect(values.allSatisfy { !$0.isEmpty }, "task-flow labels exist in \(language)")
            if language != .enUS {
                expect(text.resultExpired != english.resultExpired,
                       "official stale-result guidance is translated in \(language)")
            }
        }
    }
}
