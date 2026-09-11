// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import Foundation

enum CommandBarDestinationTests {
    static func run(_ expect: (Bool, String) -> Void) {
        let file = URL(fileURLWithPath: "/isolated/example.txt")
        let website = URL(string: "https://example.invalid/search?q=Case")!
        var opened: [URL] = []
        var checked: [String] = []
        let missing = CommandBarDestinationOpening.open(url: file, exists: {
            checked.append($0); return false
        }, open: { opened.append($0); return true })
        expect(missing == .unavailable && opened.isEmpty && checked == [file.path],
               "missing files report unavailable without invoking the opener")
        let failed = CommandBarDestinationOpening.open(url: file, exists: { _ in true }, open: {
            opened.append($0); return false
        })
        expect(failed == .failed && opened == [file], "an existing file can still fail to open")
        expect(CommandBarDestinationOpening.open(url: file, exists: { _ in true }, open: { _ in true }) == .opened,
               "only the opener's true result reports an opened destination")
        opened = []
        expect(CommandBarDestinationOpening.open(url: nil, exists: { _ in
            expect(false, "an invalid address cannot reach filesystem checks"); return true
        }, open: { opened.append($0); return true }) == .invalid && opened.isEmpty,
               "an invalid destination does not attempt an open")
        expect(CommandBarDestinationOpening.open(url: website, exists: { _ in
            expect(false, "web destinations do not use local file checks"); return false
        }, open: { opened.append($0); return true }) == .opened && opened == [website],
               "web URLs retain their prepared query and bypass local existence checks")

        let presentation = UUID()
        var requests = CommandBarDestinationRequests()
        let first = requests.begin(presentationID: presentation, query: "search Case", isVisible: true)
        expect(requests.accepts(first, presentationID: presentation, query: "search Case", isVisible: true),
               "a live destination attempt belongs to its original visible query")
        expect(!requests.accepts(first, presentationID: presentation, query: "new input", isVisible: true),
               "a pending result cannot replace different input")
        expect(!requests.accepts(first, presentationID: UUID(), query: "search Case", isVisible: true),
               "a pending result cannot reach a newer presentation")
        expect(!requests.accepts(first, presentationID: presentation, query: "search Case", isVisible: false),
               "a closed visible request cannot reopen the panel")
        let second = requests.begin(presentationID: presentation, query: "search Case", isVisible: true)
        expect(!requests.accepts(first, presentationID: presentation, query: "search Case", isVisible: true)
            && requests.accepts(second, presentationID: presentation, query: "search Case", isVisible: true),
               "identical repeated queries still supersede older attempts")
        requests.invalidate()
        expect(!requests.accepts(second, presentationID: presentation, query: "search Case", isVisible: true),
               "changing a query away and back cannot revive an invalidated attempt")
        let invisible = requests.begin(presentationID: presentation, query: "", isVisible: false)
        expect(requests.accepts(invisible, presentationID: presentation, query: "", isVisible: false),
               "a row shortcut can open a destination without showing a panel")
        expect(!requests.accepts(invisible, presentationID: presentation, query: "", isVisible: true),
               "a hidden shortcut's completion cannot close a newly visible panel")
        requests.invalidate()
        expect(!requests.accepts(invisible, presentationID: presentation, query: "", isVisible: false),
               "completion consumption also invalidates hidden attempts")

        let text = CommandBarFeatureStrings.enUS
        for language: AppLanguage in [.enUS, .zhHans, .de, .fr, .es, .ja] {
            let localized = FeatureStrings.commandBar(language)
            expect(!localized.destinationUnavailable.isEmpty && !localized.destinationInvalid.isEmpty
                && !localized.destinationOpenFailed.isEmpty, "destination failures explain recovery in \(language)")
            if language != .enUS {
                expect(localized.destinationUnavailable != text.destinationUnavailable
                    && localized.destinationInvalid != text.destinationInvalid
                    && localized.destinationOpenFailed != text.destinationOpenFailed,
                    "official destination failure messages are translated in \(language)")
            }
        }
        for language: AppLanguage in [.ptBR, .tr, .ru, .it, .ko, .zhTW, .zhHK] {
            let localized = FeatureStrings.commandBar(language)
            expect(localized.destinationUnavailable == text.destinationUnavailable
                && localized.destinationInvalid == text.destinationInvalid
                && localized.destinationOpenFailed == text.destinationOpenFailed,
                "community languages use English fallback for new destination failures: \(language)")
        }
    }
}
