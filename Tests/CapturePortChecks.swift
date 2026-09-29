// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import CoreGraphics
import Foundation

/// Checks this fork adds on top of the ported screenshot and recorder tests,
/// for behavior those tests leave uncovered. Kept apart from the upstream
/// assertions so the next sync diffs cleanly.
enum CapturePortChecks {
    static func run(_ suite: TestSuite) {
        arrowStyles(suite)
        exportSpeedBlur(suite)
        wiring(suite)
    }

    private static func arrowStyles(_ suite: TestSuite) {
        let pickedArrow = ScreenshotSupport.Annotation(tool: .arrow, arrowStyle: .doubleEnded)
        suite.expect(ScreenshotSupport.selectionStyle(for: pickedArrow).arrowStyle == .doubleEnded,
                     "selecting an arrow exposes its own style in the editor controls")
        func path(_ style: ScreenshotSupport.ArrowStyleID) -> CGPath? {
            ScreenshotSupport.arrowStrokePath(from: .zero, to: CGPoint(x: 100, y: 0),
                                              strokeWidth: 4, style: style, seed: 17)
        }
        suite.expect(path(.doubleEnded) != nil && path(.doubleEnded) != path(.open),
                     "a double-ended arrow draws a second head at its tail")
    }

    /// A retimed frame can fall between two plan samples. The rendering test
    /// passes with the floor sample alone, so pin the two-sample coverage.
    private static func exportSpeedBlur(_ suite: TestSuite) {
        let composer = (try? String(
            contentsOfFile: "Sources/Vorssaint/Services/Recorder/RecorderComposer.swift",
            encoding: .utf8)) ?? ""
        suite.expect(composer.contains("let lower = min(last, Int(position.rounded(.down)))")
                        && composer.contains("let upper = min(last, Int(position.rounded(.up)))")
                        && composer.contains("(lower...upper).contains(where: {"),
                     "a privacy blur covers both plan samples around a retimed frame")
    }

    /// Two call sites the fixtures stub out: the window list must hand the
    /// owner to the border check, and a preview rebuild must wait while a
    /// zoom focus is being chosen.
    private static func wiring(_ suite: TestSuite) {
        func source(_ path: String) -> String {
            (try? String(contentsOfFile: path, encoding: .utf8)) ?? ""
        }
        suite.expect(source("Sources/Vorssaint/Services/QuickTools/ScreenshotCaptureEngine.swift")
                        .contains("ownerName: entry[kCGWindowOwnerName as String] as? String)"),
                     "window picking passes each window's owner to the border overlay check")
        suite.expect(source("Sources/Vorssaint/Services/Recorder/RecorderEditorController.swift")
                        .contains("guard duration > 0, sourceSize.width > 0, !isPickingBlurArea, !isAimingZoom else { return }"),
                     "the edited preview is not rebuilt while a zoom focus is being chosen")
    }
}
