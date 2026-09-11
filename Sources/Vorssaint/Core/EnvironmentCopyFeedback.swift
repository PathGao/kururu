// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

struct EnvironmentCopyFeedback {
    private var target: String?
    private var succeeded: Bool?

    mutating func copy(_ value: String, target: String, writer: (String) -> Bool) {
        self.target = target
        succeeded = writer(value)
    }

    func result(for target: String) -> Bool? {
        self.target == target ? succeeded : nil
    }

    mutating func clear() {
        target = nil
        succeeded = nil
    }
}
