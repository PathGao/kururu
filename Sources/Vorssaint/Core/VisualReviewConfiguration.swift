// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

enum VisualReviewConfiguration {
    static func variant(bundleID: String?, value: String?) -> String? {
        guard let value, ["A", "B", "C", "D"].contains(value) else { return nil }
        let original = "com.pathgao.kururu.visual.\(value.lowercased()).dev"
        guard bundleID == original || (value == "B" && bundleID == "com.pathgao.kururu.visual.b.ux.dev") else { return nil }
        return value
    }

    static var current: String? {
#if VORSSAINT_DEVELOPMENT
        variant(bundleID: Bundle.main.bundleIdentifier,
                value: Bundle.main.object(forInfoDictionaryKey: "KururuVisualVariant") as? String)
#else
        nil
#endif
    }
}
