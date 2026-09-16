// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

enum ProductSettingsTests {
    static func run(_ expect: (Bool, String) -> Void) {
        let changelog = """
        ## [Unreleased]
        ## [0.1.2] - 2026-09-16
        ### Added
        - Input tuning and graph controls.
        ## [0.1.0] - 2026-09-11
        ### kururu integration
        - Workspace settings retained.
        ## [3.3.5] - 2026-09-06
        ### Summary
        Upstream historical scope.
        """
        let current = ReleaseNotes.current(changelog: changelog)
        expect(current.version == ProductIdentity.currentReleaseNotesVersion, "current notes use product identity")
        expect(current.version == "0.1.2", "current kururu build selects the new release")
        expect(current.sections.first?.bulletItems == ["Input tuning and graph controls."], "real parser selects the new product body")
        let localized = ["en", "zh-Hans", "de", "fr", "es", "ja"].map {
            ReleaseNotes.current(languageCode: $0, changelog: changelog)
        }
        expect(localized.allSatisfy { $0.sections.first?.bulletItems == ["Input tuning and graph controls."] }, "current English release notes are retained across locales")
        expect(Set(localized.compactMap { $0.sections.first?.bulletItems.first }).count == 1, "locale does not replace the current release with older translated notes")
        expect(ReleaseNotes.notes(for: "0.1.0", changelog: changelog).sections.first?.bulletItems == ["Workspace settings retained."], "previous product release remains available in history")
        expect(localized.allSatisfy { !$0.sections.flatMap(\.bulletItems).joined().contains("Upstream historical scope") }, "current localized notes never show upstream history")
        let historical = ReleaseNotes.notes(for: "3.3.5", changelog: changelog)
        expect(historical.date == "2026-09-06" && historical.sections.first?.paragraphItems == ["Upstream historical scope."], "numbered history still parses")
        expect(ReleaseNotes.allVersions(changelog: changelog) == ["0.1.2", "0.1.0", "3.3.5"], "product release precedes upstream history; unreleased is omitted")
        expect(ReleaseNotes.current(changelog: nil).sections.isEmpty, "missing product notes do not fall back to upstream")
        let labels = ["en", "zh-Hans", "de", "fr", "es", "ja"].map { current.versionLabel(languageCode: $0) }
        expect(labels.allSatisfy { $0 == "v0.1.2 · 2026-09-16" }, "all locales show the product release version and date")
        expect(historical.versionLabel(languageCode: "en") == "v3.3.5 · 2026-09-06", "published label retained")
        expect(!BuildCapabilityPolicy.allowsUpdates(configured: false, development: false), "unconfigured release cannot update")
        expect(!BuildCapabilityPolicy.allowsUpdates(configured: true, development: true), "development cannot update")
        expect(BuildCapabilityPolicy.allowsUpdates(configured: true, development: false), "configured release behavior retained")
    }
}
