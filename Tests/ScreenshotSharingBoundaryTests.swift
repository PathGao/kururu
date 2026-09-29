// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint
import Foundation

enum ScreenshotSharingBoundaryTests {
    static func run(_ expect: (Bool, String) -> Void) {
        for identity in ["com.pathgao.kururu", "com.pathgao.kururu.dev", "com.vorssaint.utils", "com.vorssaint.utils.dev"] {
            let endpoint: URL? = ScreenshotSharingSupport.endpoint(bundleIdentifier: identity, developerOverride: "https://example.com")
            expect(endpoint == nil, "removed share service has no endpoint for \(identity)")
        }
        expect(ScreenshotSharingSupport.uploadURL(endpoint: URL(string: "https://example.com")!, duration: .oneHour) == nil,
               "caller supplied endpoint cannot recreate upload route")
    }

    @MainActor
    static func runService(_ expect: (Bool, String) -> Void) async {
        let service = ScreenshotShareService.shared
        service.refresh()
        expect(service.records.isEmpty, "refresh cannot revive removed sharing records")
        do {
            _ = try await service.createLink(pngData: Data([137,80,78,71,13,10,26,10]), duration: .oneHour)
            expect(false, "create reports unavailable")
        } catch { expect((error as? ScreenshotShareError) == .unavailable, "create reports unavailable") }
        for expiration in [Date.distantPast, Date.distantFuture] {
            let record = ScreenshotShareRecord(id: String(repeating: "a", count: 32), endpoint: URL(string: "https://screenshots.vorssaint.com")!,
                expiresAt: expiration, deleteToken: String(repeating: "b", count: 43))
            do { try await service.delete(record); expect(false, "legacy cleanup reports unavailable") }
            catch { expect((error as? ScreenshotShareError) == .unavailable, "legacy cleanup reports unavailable without contacting endpoint") }
        }
        service.refresh(now: .distantFuture)
        expect(service.records.isEmpty, "retry/expiry refresh remains inactive")
    }
}
