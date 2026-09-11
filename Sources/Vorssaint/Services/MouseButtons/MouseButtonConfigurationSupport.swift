// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

/// Configuration ownership survives a paused behavior. Runtime ownership is
/// still decided separately by MouseButtonShortcutSupport.
enum MouseButtonConfigurationSupport {
    static func spacesButtonAfterToggle(enabled: Bool, savedButton: Int) -> Int {
        savedButton
    }

    static func conflictsWithSpaces(_ button: Int64, savedButton: Int) -> Bool {
        savedButton != 0 && Int64(savedButton) == button
    }
}
