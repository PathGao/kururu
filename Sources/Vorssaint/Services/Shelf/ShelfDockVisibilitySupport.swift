// SPDX-License-Identifier: GPL-3.0-or-later

enum ShelfDockVisibilitySupport {
    static func isWanted(featureOn: Bool, floatingShelfVisible: Bool, itemCount: Int,
                         dragging: Bool, forcedOpen: Bool, notesAvailable: Bool,
                         notesVisible: Bool) -> Bool {
        featureOn && !floatingShelfVisible && !notesVisible
            && (itemCount > 0 || dragging || forcedOpen || notesAvailable)
    }
}
