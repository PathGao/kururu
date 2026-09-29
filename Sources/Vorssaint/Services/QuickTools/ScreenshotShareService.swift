// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import AppKit
import Foundation

enum ScreenshotShareError: Error, Equatable {
    case invalidImage
    case invalidEndpoint
    case unavailable
    case rejected
    case invalidResponse
    case localStorage
}

/// Temporary sharing was removed. Keep callers compatible without retaining
/// an upload client, old deletion-token storage or background cleanup work.
@MainActor
final class ScreenshotShareService: ObservableObject {
    static let shared = ScreenshotShareService()
    @Published private(set) var records: [ScreenshotShareRecord] = []
    private init() {}

    func refresh(now: Date = Date()) { records = [] }

    func createLink(pngData: Data,
                    duration: ScreenshotShareDuration) async throws -> ScreenshotShareRecord {
        throw ScreenshotShareError.unavailable
    }

    func delete(_ record: ScreenshotShareRecord) async throws {
        throw ScreenshotShareError.unavailable
    }

    @discardableResult
    func copy(_ url: URL) -> Bool { false }
}
