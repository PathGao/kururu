// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

enum StableUpdateTests {
    static func run(_ expect: (Bool, String) -> Void) {
        func release(_ tag: String, prerelease: Bool = false, draft: Bool = false,
                     asset: Bool = true) -> UpdateServiceSupport.ReleaseCandidate {
            .init(tagName: tag, isPrerelease: prerelease, isDraft: draft,
                  dmgURL: asset ? URL(string: "https://example.invalid/update.dmg") : nil,
                  dmgExpectedBytes: 100, body: nil)
        }
        let stable = release("v2.0.0")
        let rejected = [release("v9.0.0-beta.1", prerelease: true),
                        release("v9.0.0-beta.2"), release("v9.0.0-rc.1"),
                        release("v9.0.0-alpha.1"), release("v9.0.0", prerelease: true),
                        release("v9.0.0", draft: true), release("v9.0.0", asset: false)]
        for candidate in rejected {
            let result = UpdateServiceSupport.selectUpdate(from: [candidate, stable], currentVersion: "1.0.0")
            expect(result?.tagName == stable.tagName, "only stable eligible updates survive candidate filtering: \(candidate.tagName)")
        }
        expect(UpdateServiceSupport.selectUpdate(from: rejected, currentVersion: "1.0.0") == nil,
               "an all-prerelease/draft/uninstallable response produces no update")
        expect(UpdateServiceSupport.selectUpdate(from: [stable], currentVersion: "2.0.0-rc.1")?.tagName == stable.tagName,
               "an older prerelease installation can move to the corresponding stable version")
        expect(UpdateServiceSupport.selectUpdate(from: [stable], currentVersion: "3.0.0-beta.1") == nil,
               "legacy prerelease installation is never downgraded to an older stable version")
        expect(UpdateServiceSupport.selectUpdate(from: [stable, release("v2.1.0")], currentVersion: "1.0.0")?.tagName == "v2.1.0",
               "the newest eligible stable release wins")
    }
}
