// SPDX-License-Identifier: GPL-3.0-or-later

enum ShelfDockVisibilityTests {
    static func run(_ expect: (Bool, String) -> Void) {
        let cases: [(Bool, Bool, Int, Bool, Bool, Bool, Bool, Bool, String)] = [
            (true, false, 0, false, false, true, false, true, "empty top entry keeps notes reachable"),
            (true, false, 3, false, false, true, true, false, "top notes own the visible workspace"),
            (true, false, 0, true, true, true, true, false, "drag cannot replace editing notes"),
            (false, false, 3, true, true, true, false, false, "paused dock stays hidden"),
            (true, true, 3, true, true, true, false, false, "floating shelf owns its presentation"),
            (true, false, 0, false, false, false, false, false, "empty original dock remains hidden"),
            (true, false, 1, false, false, false, false, true, "original dock keeps contents visible"),
            (true, false, 0, true, false, false, false, true, "original dock catches drag"),
            (true, false, 0, false, true, false, false, true, "explicit empty shelf remains open")
        ]
        for c in cases {
            expect(ShelfDockVisibilitySupport.isWanted(featureOn: c.0, floatingShelfVisible: c.1,
                itemCount: c.2, dragging: c.3, forcedOpen: c.4, notesAvailable: c.5,
                notesVisible: c.6) == c.7, c.8)
        }
    }
}
