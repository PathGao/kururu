// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

/// Product-owned identity shared by the app, helper and build tooling.
enum ProductIdentity {
    static let name = "kururu"
    /// Standalone probes must not read or write a real application’s data domain.
    static let unbundledStorageID = "com.pathgao.kururu.unbundled"
    static let releaseBundleID = "com.pathgao.kururu"
    static let developmentBundleID = "com.pathgao.kururu.dev"
    static let repositoryURL = URL(string: "https://github.com/PathGao/kururu")!
    /// Changelog entry describing this product build; numbered entries retain upstream history.
    static let currentReleaseNotesVersion = "0.1.2"
    static let allowsSelfUpdates = true
    static let signingTeamID: String? = "GN56VLVTJ6"

    static func bundleID(development: Bool) -> String {
        development ? developmentBundleID : releaseBundleID
    }

    static func appName(development: Bool) -> String {
        development ? name + " (Developer)" : name
    }

    static func executableName(development: Bool) -> String {
        development ? name + "Developer" : name
    }
}
