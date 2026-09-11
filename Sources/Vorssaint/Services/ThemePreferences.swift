// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import Foundation
import Combine

final class ThemePreferences: ObservableObject {
    static let shared = ThemePreferences(defaults: .standard)
    static let storageKey = DefaultsKey.importedInterfaceTheme
    @Published private(set) var applied: ImportedTheme?
    private let defaults: UserDefaults

    init(defaults: UserDefaults) {
        self.defaults = defaults
        applied = defaults.data(forKey: Self.storageKey).flatMap { try? ThemeImportSupport.parse($0) }
    }

    func apply(_ theme: ImportedTheme) throws {
        let data = try ThemeImportSupport.savedData(theme)
        let validated = try ThemeImportSupport.parse(data)
        defaults.set(data, forKey: Self.storageKey)
        applied = validated
    }

    func restoreDefault() {
        defaults.removeObject(forKey: Self.storageKey)
        applied = nil
    }
}
