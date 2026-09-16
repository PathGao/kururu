// SPDX-License-Identifier: GPL-3.0-or-later

/// Main-thread lifecycle routing. Registrations describe resource owners, so a
/// service shared by several features is synchronized once per change.
enum FeaturePermission: Hashable {
    case accessibility, screenRecording
}

final class FeatureLifecycle<Feature: Hashable> {
    struct Registration {
        let members: Set<Feature>
        var permissions: Set<FeaturePermission> = []
        let synchronize: () -> Void
        var terminate: () -> Void = {}
    }

    private let registrations: [Registration]
    private var active = Set<Int>()
    private var loaded = Set<Int>()
    private var terminated = false

    init(_ registrations: [Registration]) { self.registrations = registrations }
    func sync(changed: Set<Feature>, available: Set<Feature>) {
        guard !terminated else { return }
        for (index, registration) in registrations.enumerated()
            where !registration.members.isDisjoint(with: changed) {
            let enabled = !registration.members.isDisjoint(with: available)
            guard enabled || active.contains(index) else { continue }
            if enabled {
                active.insert(index)
                loaded.insert(index)
            } else {
                active.remove(index)
            }
            registration.synchronize()
        }
    }
    func permissionChanged(_ permission: FeaturePermission, available: Set<Feature>) {
        guard !terminated else { return }
        for (index, registration) in registrations.enumerated()
            where registration.permissions.contains(permission)
                && !registration.members.isDisjoint(with: available) {
            active.insert(index)
            loaded.insert(index)
            registration.synchronize()
        }
    }
    func terminate() {
        guard !terminated else { return }
        terminated = true
        for index in registrations.indices where loaded.contains(index) {
            registrations[index].terminate()
        }
        active.removeAll()
    }
}
