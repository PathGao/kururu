// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

enum PermissionResetResult: Equatable {
    case completed, preparationFailed, ruleRemovalFailed, resetFailed
}

enum PermissionResetSupport {
    static func run(prepare: () -> Bool,
                    removeRule: (@escaping (Bool) -> Void) -> Void,
                    reset: @escaping () -> Bool,
                    completion: @escaping (PermissionResetResult) -> Void) {
        guard prepare() else { completion(.preparationFailed); return }
        removeRule { removed in
            guard removed else { completion(.ruleRemovalFailed); return }
            completion(reset() ? .completed : .resetFailed)
        }
    }
}
