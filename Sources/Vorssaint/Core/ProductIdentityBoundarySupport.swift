// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

/// Destructive operations require an explicit identity belonging to this product.
enum ProductIdentityBoundarySupport {
    static func ownedBundleID(_ candidate: String?) -> String? {
        guard let candidate, candidate == ProductIdentity.releaseBundleID
            || candidate == ProductIdentity.developmentBundleID else { return nil }
        return candidate
    }

    static func sudoersRulePath(development: Bool) -> String {
        "/etc/sudoers.d/" + (development ? "kururu-dev-clamshell" : "kururu-clamshell")
    }

    static let invalidIdentityMessage = "kururu cannot remove settings or permissions: this process has no verified kururu application identity."
}
