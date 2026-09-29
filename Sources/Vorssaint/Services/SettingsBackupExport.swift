// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import Foundation

enum SettingsBackupExport: Equatable {
    case cancelled, saved, failed(String)

    static func write(_ payload: [String: Any], to url: URL?) -> Self {
        guard let url else { return .cancelled }
        do {
            let data = try PropertyListSerialization.data(fromPropertyList: payload,
                                                         format: .xml, options: 0)
            try data.write(to: url, options: .atomic)
            return .saved
        } catch {
            return .failed(error.localizedDescription)
        }
    }
}
