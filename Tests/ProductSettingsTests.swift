// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

enum ProductSettingsTests {
    static func run(_ expect: (Bool, String) -> Void) {
        let changelog = """
        ## [Unreleased]
        ## [0.1.0] - 2026-09-11
        ### kururu integration
        - Workspace settings retained.
        ## [3.3.5] - 2026-09-06
        ### Summary
        Upstream historical scope.
        """
        let current = ReleaseNotes.current(changelog: changelog)
        expect(current.version == ProductIdentity.currentReleaseNotesVersion, "current notes use product identity")
        expect(current.version == "0.1.0", "current kururu build selects its first release")
        expect(current.sections.first?.bulletItems == ["Workspace settings retained."], "real parser does not select upstream body")
        let localized = ["en", "zh-Hans", "de", "fr", "es", "ja"].map {
            ReleaseNotes.current(languageCode: $0, changelog: changelog)
        }
        expect(localized.allSatisfy { $0.sections.first?.bulletItems.count == 6 }, "each official locale has six user-facing current notes")
        expect(Set(localized.compactMap { $0.sections.first?.bulletItems.first }).count == 6, "current note dispatch selects six actual languages")
        expect(localized[1].sections.first?.bulletItems.first?.contains("关闭后保留数据与设置") == true, "Chinese current notes explain closing preserves data and settings")
        expect(localized.allSatisfy { !$0.sections.flatMap(\.bulletItems).joined().contains("Upstream historical scope") }, "current localized notes never show upstream history")
        let historical = ReleaseNotes.notes(for: "3.3.5", changelog: changelog)
        expect(historical.date == "2026-09-06" && historical.sections.first?.paragraphItems == ["Upstream historical scope."], "numbered history still parses")
        expect(ReleaseNotes.allVersions(changelog: changelog) == ["0.1.0", "3.3.5"], "product release precedes upstream history; unreleased is omitted")
        expect(ReleaseNotes.current(changelog: nil).sections.isEmpty, "missing product notes do not fall back to upstream")
        let labels = ["en", "zh-Hans", "de", "fr", "es", "ja"].map { current.versionLabel(languageCode: $0) }
        expect(labels.allSatisfy { $0 == "v0.1.0 · 2026-09-11" }, "all locales show the product release version and date")
        expect(historical.versionLabel(languageCode: "en") == "v3.3.5 · 2026-09-06", "published label retained")
        expect(!BuildCapabilityPolicy.allowsUpdates(configured: false, development: false), "unconfigured release cannot update")
        expect(!BuildCapabilityPolicy.allowsUpdates(configured: true, development: true), "development cannot update")
        expect(BuildCapabilityPolicy.allowsUpdates(configured: true, development: false), "configured release behavior retained")
    }
}
