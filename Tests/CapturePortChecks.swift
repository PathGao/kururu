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
}
