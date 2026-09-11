// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation
import CoreGraphics

enum FeedbackDraftTests {
    static func run(_ expect: (Bool, String) -> Void) {
        expect(LocalFeedbackCopy.strings(language: "zh-Hans").copied.contains("尚未发送"), "simplified success describes copying only")
        expect(LocalFeedbackCopy.strings(language: "zh-TW").copied.contains("尚未傳送"), "traditional success describes copying only")
        expect(LocalFeedbackCopy.strings(language: "ja").copied.contains("Nothing has been sent"), "other locales fall back to accurate English copy")
        let sourceScreen = CGRect(x: -1440, y: 200, width: 1440, height: 900)
        let otherScreen = CGRect(x: 2000, y: 0, width: 1600, height: 1000)
        let draftSize = CGSize(width: 600, height: 650)
        expect(FeedbackDraftSupport.initialWindowOrigin(size: draftSize, sourceVisibleFrame: sourceScreen,
                                                        fallback: otherScreen) == CGPoint(x: -1020, y: 325),
               "new feedback follows its triggering screen, including negative screen coordinates")
        expect(FeedbackDraftSupport.initialWindowOrigin(size: draftSize, sourceVisibleFrame: nil,
                                                        fallback: otherScreen) == CGPoint(x: 2500, y: 175),
               "feedback uses the fallback screen only without a triggering screen")
        let smallScreen = CGRect(x: 20, y: 30, width: 500, height: 400)
        let oversizedOrigin = FeedbackDraftSupport.initialWindowOrigin(size: draftSize,
            sourceVisibleFrame: smallScreen, fallback: otherScreen)
        expect(oversizedOrigin.x == smallScreen.minX && oversizedOrigin.y + draftSize.height == smallScreen.maxY,
               "an oversized fixed draft keeps its title bar at the chosen screen's top")
        let message = "  My draft & private text\nsecond line  "
        let omitted = FeedbackDraftSupport.text(category: "Bug", message: message, diagnostics: ["macOS": "TEST-OS"], includeDiagnostics: false)
        expect(omitted.contains(message), "copy preserves original draft text")
        expect(omitted.contains("Bug"), "copy contains selected category")
        expect(!omitted.contains("TEST-OS") && !omitted.contains("macOS"), "unchecked diagnostics never enter copied text")
        let included = FeedbackDraftSupport.text(category: "Idea", message: message, diagnostics: ["macOS": "TEST-OS"], includeDiagnostics: true)
        expect(included.contains("macOS: TEST-OS"), "checked diagnostics enter copied text")
        expect(FeedbackDraftSupport.issuesURL.query == nil && FeedbackDraftSupport.issuesURL.fragment == nil, "project URL never embeds draft or diagnostics")
        expect(FeedbackDraftSupport.issuesURL == ProductIdentity.repositoryURL.appendingPathComponent("issues"), "feedback destination belongs to this project")
    }
}
