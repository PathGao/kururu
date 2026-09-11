// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

/// A manual result is valid only for the exact input and shared rule set that produced it.
struct URLCleanerResultState: Equatable {
    private(set) var output = ""
    private var sourceInput: String?
    private var sourceRules: URLCleaning.Rules?

    var canCopy: Bool { !output.isEmpty && sourceInput != nil && sourceRules != nil }

    mutating func record(_ result: URLCleaning.Result?, input: String, rules: URLCleaning.Rules) {
        output = result?.url ?? ""
        sourceInput = input
        sourceRules = rules
    }

    @discardableResult
    mutating func invalidateIfInputChanged(to input: String) -> Bool {
        guard let sourceInput, sourceInput != input else { return false }
        invalidate()
        return true
    }

    @discardableResult
    mutating func invalidateIfRulesChanged(to rules: URLCleaning.Rules) -> Bool {
        guard let sourceRules, sourceRules != rules else { return false }
        invalidate()
        return true
    }

    mutating func invalidate() {
        output = ""
        sourceInput = nil
        sourceRules = nil
    }
}
