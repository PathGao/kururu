// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import Foundation

struct CommandBarDestinationAttempt: Equatable {
    let id = UUID()
    let presentationID: UUID
    let query: String
    let wasVisible: Bool
}

struct CommandBarDestinationRequests {
    private var currentID: UUID?

    mutating func begin(presentationID: UUID, query: String, isVisible: Bool) -> CommandBarDestinationAttempt {
        let attempt = CommandBarDestinationAttempt(presentationID: presentationID, query: query, wasVisible: isVisible)
        currentID = attempt.id
        return attempt
    }

    mutating func invalidate() { currentID = nil }

    func accepts(_ attempt: CommandBarDestinationAttempt, presentationID: UUID,
                 query: String, isVisible: Bool) -> Bool {
        currentID == attempt.id && attempt.presentationID == presentationID
            && attempt.query == query && attempt.wasVisible == isVisible
    }
}

enum CommandBarDestinationOpening {
    enum Result { case opened, unavailable, invalid, failed }

    static func open(url: URL?, exists: (String) -> Bool, open: (URL) -> Bool) -> Result {
        guard let url else { return .invalid }
        if url.isFileURL, !exists(url.path) { return .unavailable }
        return open(url) ? .opened : .failed
    }
}

struct CommandBarDestinationFailure {
    let target: String
    let message: String
}
