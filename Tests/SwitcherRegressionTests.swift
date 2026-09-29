// SPDX-License-Identifier: GPL-3.0-or-later
import AppKit

enum SwitcherRegressionTests {
    static func run(_ expect: (Bool, String) -> Void) {
        for subrole in ["AXUnknown", "AXFloatingWindow"] {
            for excluded in [false, true] {
                #if SWITCHER_BASELINE
                let accepted = SwitcherSupport.isSwitchableNonstandardWindow(
                    role: "AXWindow", subrole: subrole, fillsScreen: true,
                    hasNormalWindowLevel: true, acceptsUndescribedSubroles: true)
                #else
                let accepted = SwitcherSupport.isSwitchableNonstandardWindow(
                    role: "AXWindow", subrole: subrole, fillsScreen: true,
                    hasNormalWindowLevel: true, acceptsUndescribedSubroles: true,
                    isExcludedFromWindowCycle: excluded)
                #endif
                expect(accepted == !excluded, "excluded helper stays out even with fullscreen and normal-level evidence: \(subrole), excluded=\(excluded)")
            }
        }
        func continues(frontmost: pid_t? = 10, minimized: Bool = false,
                       startedMinimized: Bool = false, restored: Bool = false,
                       known: Set<CGWindowID> = [1], windows: Set<CGWindowID> = [1, 2],
                       focused: CGWindowID? = 2) -> Bool {
            #if SWITCHER_BASELINE
            return SwitcherSupport.shouldContinueFocusRetry(targetPID: 10, sourcePID: 20,
                frontmostPID: frontmost, targetIsMinimized: minimized,
                targetStartedMinimized: startedMinimized, targetWasObservedRestored: restored, ownPID: 30)
            #else
            return SwitcherSupport.shouldContinueFocusRetry(targetPID: 10, sourcePID: 20,
                frontmostPID: frontmost, targetIsMinimized: minimized,
                targetStartedMinimized: startedMinimized, targetWasObservedRestored: restored,
                knownWindowIDs: known, targetAppWindowIDs: windows,
                targetAppFocusedWindowID: focused, ownPID: 30)
            #endif
        }
        expect(!continues(), "newly focused window ends retries of the old target")
        expect(continues(focused: 1), "new helper without keyboard focus does not cancel retries")
        expect(continues(focused: nil), "unavailable AX focus preserves retry behavior")
        expect(continues(known: []), "unavailable baseline snapshot preserves retry behavior")
        expect(continues(known: [1, 2]), "existing off-Space window is not newly created")
        expect(continues(windows: [1]), "unchanged window list does not inspect focus")
        expect(continues(frontmost: 20), "source app during transition remains allowed")
        expect(continues(frontmost: 30), "own switcher app during transition remains allowed")
        expect(!continues(frontmost: 40), "another active application cancels retries")
        expect(!continues(minimized: true), "new minimize action cancels retries")
        expect(continues(frontmost: 20, minimized: true, startedMinimized: true), "initial minimized target may restore")
        expect(!continues(minimized: true, startedMinimized: true, restored: true), "minimize after observed restore cancels retries")
        #if !SWITCHER_BASELINE
        var focusReads = 0
        func focus() -> CGWindowID? { focusReads += 1; return 2 }
        expect(SwitcherSupport.shouldContinueFocusRetry(targetPID: 10, sourcePID: 20,
            frontmostPID: 10, targetIsMinimized: false, targetStartedMinimized: false,
            knownWindowIDs: [1], targetAppWindowIDs: [1], targetAppFocusedWindowID: focus()),
            "unchanged windows keep retries active")
        expect(focusReads == 0, "unchanged windows avoid AX focus query")
        var frontmostReads = 0
        func foreground() -> pid_t? { frontmostReads += 1; return frontmostReads == 1 ? 10 : 40 }
        expect(!SwitcherSupport.shouldContinueFocusRetry(targetPID: 10, sourcePID: 20,
            frontmostPID: foreground(), targetIsMinimized: false, targetStartedMinimized: false,
            knownWindowIDs: [1], targetAppWindowIDs: [1, 2], targetAppFocusedWindowID: nil),
            "leaving the app during AX query cancels even when focus lookup fails")
        let state = SwitcherWindowFocusRetryState(targetWindowID: 1, targetStartedMinimized: false, knownWindowIDs: [3])
        expect(state.knownWindowIDs == [1, 3], "target missing from nonempty snapshot remains known")
        expect(!state.shouldContinue(targetPID: 10, sourcePID: 20, frontmostPID: 10,
            targetMinimizedState: false, targetAppWindowIDs: [1, 2, 3], targetAppFocusedWindowID: 2),
            "new focus invalidates shared retry state")
        expect(!state.shouldContinue(targetPID: 10, sourcePID: 20, frontmostPID: 10,
            targetMinimizedState: false, targetAppWindowIDs: [1, 3], targetAppFocusedWindowID: 1),
            "cancelled retries cannot revive when the old window regains focus")
        let raw: [[String: Any]] = [
            [kCGWindowOwnerPID as String: 10, kCGWindowNumber as String: 1, kCGWindowLayer as String: 0],
            [kCGWindowOwnerPID as String: 10, kCGWindowNumber as String: 2, kCGWindowLayer as String: 20],
            [kCGWindowOwnerPID as String: 20, kCGWindowNumber as String: 3],
        ]
        expect(SwitcherSupport.focusRetryWindowIDs(in: raw, ownerPID: 10) == [1, 2],
            "snapshot includes auxiliary layers and excludes other processes")
        #endif
    }
}
