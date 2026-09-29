// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

enum MouseButtonConfigurationTests {
    static func run(_ expect: (Bool, String) -> Void) {
        let saved = 5
        let paused = MouseButtonConfigurationSupport.spacesButtonAfterToggle(enabled: false, savedButton: saved)
        expect(paused == saved, "pausing Spaces preserves its saved physical button")
        expect(MouseButtonConfigurationSupport.conflictsWithSpaces(5, savedButton: paused),
               "a paused Spaces binding cannot be reassigned to a shortcut")
        expect(!MouseButtonConfigurationSupport.conflictsWithSpaces(6, savedButton: paused),
               "another physical button remains assignable")
        let resumed = MouseButtonConfigurationSupport.spacesButtonAfterToggle(enabled: true, savedButton: paused)
        expect(resumed == saved, "resuming restores the same binding after pause")
        expect(!MouseButtonConfigurationSupport.conflictsWithSpaces(5, savedButton: 0),
               "explicitly removing a Spaces binding releases it for reassignment")
        expect(MouseButtonConfigurationSupport.spacesButtonAfterToggle(enabled: false, savedButton: 0) == 0,
               "pausing an unbound behavior does not invent a binding")
    }
}
