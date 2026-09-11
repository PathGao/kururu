// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import SwiftUI

/// The three things that happen while you type: a filter on repeated presses,
/// abbreviations that expand, and a held key that becomes a modifier layer.
struct KeyboardSettings: View {
    var body: some View {
        SettingsForm {
            if AppFeature.keyboardDebounce.isAvailable {
                KeyboardDebounceSections()
            }
            if AppFeature.textSnippets.isAvailable {
                TextSnippetsSections()
            }
            if AppFeature.superKey.isAvailable {
                SuperKeySections()
            }
        }
        .formStyle(.grouped)
    }
}
