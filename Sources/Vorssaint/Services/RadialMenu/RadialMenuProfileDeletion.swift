// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import Foundation

enum RadialMenuProfileDeletion {
    static func index(of confirmedID: UUID, in profileIDs: [UUID]) -> Int? {
        guard profileIDs.count > 1 else { return nil }
        return profileIDs.firstIndex(of: confirmedID)
    }
}
