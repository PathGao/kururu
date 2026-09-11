// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint
import Foundation
import Security

enum BuildCapabilityPolicyTests {
    static func run(_ expect: (Bool, String) -> Void) {
        let installer = UpdateInstallerSupport.installerScript()
        expect(installer.contains("DMG_VERIFY_REQ='never'"), "generated installer refuses disk images without product signing identity")
        expect(installer.contains("VERIFY_REQ='never'"), "generated installer refuses application bundles without product signing identity")
        expect(!installer.contains("3D485NHW29") && !installer.contains("com.vorssaint.utils"), "generated installer never trusts upstream identity")
        expect(ProductIdentity.bundleID(development: false) == "com.pathgao.kururu", "release identity belongs to kururu")
        expect(ProductIdentity.bundleID(development: true) == "com.pathgao.kururu.dev", "development has independent identity")
        expect(!ProductIdentity.allowsSelfUpdates && ProductIdentity.signingTeamID == nil, "current identity does not claim configured updater or signing team")
        #if VORSSAINT_DEVELOPMENT
        expect(FanControlIdentifiers.appBundleID == ProductIdentity.developmentBundleID, "development helper matches development app")
        #else
        expect(FanControlIdentifiers.appBundleID == ProductIdentity.releaseBundleID, "release helper matches release app")
        #endif
        expect(FanControlIdentifiers.helperID == FanControlIdentifiers.appBundleID + ".fan-control", "helper service uses product-owned namespace")
        expect(!FanControlIdentifiers.isConfigured, "actual fan helper stays disabled without product team")
        expect(FanControlIdentifiers.appCodeRequirement == "never" && FanControlIdentifiers.helperCodeRequirement == "never", "both actual helper authentication directions fail closed")
        expect(!BuildCapabilityPolicy.allowsPrivilegedHelper(teamID: nil), "missing team disables helper")
        expect(!BuildCapabilityPolicy.allowsPrivilegedHelper(teamID: ""), "empty team disables helper")
        expect(!BuildCapabilityPolicy.allowsPrivilegedHelper(teamID: "bad\" or true"), "invalid team cannot inject requirement")
        let denied = BuildCapabilityPolicy.codeRequirement(teamID: nil, identifier: "com.pathgao.kururu")
        expect(denied == "never", "missing team creates explicitly unsatisfiable requirement")
        var requirement: SecRequirement?
        expect(SecRequirementCreateWithString(denied as CFString, [], &requirement) == errSecSuccess, "deny requirement parses with actual Security framework")
        var current: SecCode?
        let loaded = SecCodeCopySelf([], &current) == errSecSuccess
        if let current, let requirement {
            expect(SecCodeCheckValidity(current, [], requirement) != errSecSuccess, "deny requirement rejects actual running executable")
        } else { expect(!loaded, "Security identity setup unavailable") }
        let allowed = BuildCapabilityPolicy.codeRequirement(teamID: "ABCDEFGHIJ", identifier: "com.pathgao.kururu")
        expect(allowed.contains("ABCDEFGHIJ") && allowed.contains("identifier \"com.pathgao.kururu\""), "configured requirement binds team and product ID")
        expect(BuildCapabilityPolicy.codeRequirement(teamID: "ABCDEFGHIJ", identifier: "bad\" or true") == "never", "invalid identifier fails closed")
        expect(!BuildCapabilityPolicy.allowsUpdates(configured: false, development: false), "release build with no updater cannot update")
        expect(!BuildCapabilityPolicy.allowsUpdates(configured: false, development: true), "development build with no updater cannot update")
        expect(!BuildCapabilityPolicy.allowsUpdates(configured: true, development: true), "development still cannot self replace")
        expect(BuildCapabilityPolicy.allowsUpdates(configured: true, development: false), "explicitly configured release can use existing update validation")
        expect(BuildCapabilityPolicy.updatesUnavailable(languageCode: "zh-Hans").contains("未配置"), "unavailable explanation is configuration based")
    }
}
