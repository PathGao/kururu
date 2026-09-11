// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

enum WhatsAppOrganizerPolicy {
    static func allowsRun(manual: Bool, automaticEnabled: Bool, accessConfirmed: Bool) -> Bool {
        accessConfirmed && (manual || automaticEnabled)
    }
}
