// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint
import Foundation

enum BuildCapabilityPolicy {
    static func allowsPrivilegedHelper(teamID: String?) -> Bool {
        guard let teamID else { return false }
        return teamID.range(of: "^[A-Z0-9]{10}$", options: .regularExpression) != nil
    }
    static func teamCodeRequirement(teamID: String?) -> String {
        guard allowsPrivilegedHelper(teamID: teamID), let teamID else { return "never" }
        return "anchor apple generic and certificate leaf[subject.OU] = \"\(teamID)\""
    }
    static func codeRequirement(teamID: String?, identifier: String) -> String {
        guard allowsPrivilegedHelper(teamID: teamID), let teamID,
              identifier.range(of: "^[A-Za-z0-9]+(?:[.-][A-Za-z0-9]+)*$", options: .regularExpression) != nil else { return "never" }
        return teamCodeRequirement(teamID: teamID) + " and identifier \"\(identifier)\""
    }
    static func allowsUpdates(configured: Bool, development: Bool) -> Bool {
        return configured && !development
    }
    static func helperUnavailable(languageCode: String) -> String {
        switch languageCode {
        case "zh-Hans": return "此构建未配置受信任的风扇控制器。仍可查看风扇读数。"
        case "zh-TW", "zh-HK": return "此版本尚未設定受信任的風扇控制器，仍可查看風扇讀數。"
        default: return "A trusted fan controller is not configured for this build. Fan readings remain available."
        }
    }
    static func updatesUnavailable(languageCode: String) -> String {
        switch languageCode {
        case "zh-Hans": return "此构建未配置更新。"
        case "de": return "Für diesen Build sind keine Updates eingerichtet."
        case "fr": return "Les mises à jour ne sont pas configurées pour cette version."
        case "es": return "Las actualizaciones no están configuradas para esta compilación."
        case "ja": return "このビルドではアップデートが設定されていません。"
        case "zh-TW", "zh-HK": return "此版本尚未設定更新。"
        default: return "Updates are not configured for this build."
        }
    }
}
