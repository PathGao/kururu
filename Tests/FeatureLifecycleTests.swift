// SPDX-License-Identifier: GPL-3.0-or-later

enum FeatureLifecycleTests {
    static func run(_ expect: (Bool, String) -> Void) {
        enum Feature: Hashable { case brightness, environment, screenshot, recorder }
        final class Service {
            var running = false
            var syncs = 0
            var stops = 0
            var terminations = 0
            func sync(enabled: Bool) {
                syncs += 1
                if running && !enabled { stops += 1 }
                running = enabled
            }
            func terminate() { running = false; terminations += 1 }
        }
        var available: Set<Feature> = [.brightness, .screenshot, .recorder]
        var accessibilityAllowed = true
        let brightness = Service(), environment = Service(), capture = Service()
        let lifecycle = FeatureLifecycle<Feature>([
            .init(members: [.brightness], permissions: [.accessibility],
                  synchronize: { brightness.sync(enabled: available.contains(.brightness) && accessibilityAllowed) },
                  terminate: { brightness.terminate() }),
            .init(members: [.environment],
                  synchronize: { environment.sync(enabled: available.contains(.environment)) },
                  terminate: { environment.terminate() }),
            .init(members: [.screenshot, .recorder], permissions: [.screenRecording],
                  synchronize: { capture.sync(enabled: !available.isDisjoint(with: [.screenshot, .recorder])) },
                  terminate: { capture.terminate() })
        ])
        lifecycle.sync(changed: available, available: available)
        expect(brightness.running && capture.running, "available services start")
        expect(capture.syncs == 1, "shared members synchronize their owner once at launch")
        expect(environment.syncs == 0, "unavailable on-demand service is not created")
        lifecycle.permissionChanged(.accessibility, available: available)
        expect(brightness.syncs == 2 && capture.syncs == 1, "permission change reaches only its registered owners")
        accessibilityAllowed = false
        lifecycle.permissionChanged(.accessibility, available: available)
        expect(!brightness.running && brightness.stops == 1, "revoking permission suspends dependent work")
        accessibilityAllowed = true
        lifecycle.permissionChanged(.accessibility, available: available)
        expect(brightness.running, "granting permission restores enabled work")
        lifecycle.sync(changed: [.environment], available: available)
        expect(brightness.syncs == 4 && environment.syncs == 0,
               "an unrelated inactive owner cannot trigger service work")
        available.remove(.screenshot)
        lifecycle.sync(changed: [.screenshot], available: available)
        expect(capture.running && capture.stops == 0, "removing one member preserves a shared service")
        available.remove(.recorder)
        lifecycle.sync(changed: [.recorder], available: available)
        expect(!capture.running && capture.stops == 1, "removing the last member stops the shared service")
        lifecycle.permissionChanged(.screenRecording, available: available)
        expect(capture.syncs == 3, "permission callbacks do not revive disabled resources")
        lifecycle.sync(changed: [.recorder], available: available)
        expect(capture.syncs == 3, "repeated stop does not instantiate an inactive resource")
        available.insert(.environment)
        lifecycle.sync(changed: [.environment], available: available)
        expect(environment.running, "installing an on-demand owner registers its lifecycle")
        available.remove(.environment)
        lifecycle.sync(changed: [.environment], available: available)
        expect(environment.stops == 1, "uninstall cancels on-demand work")
        available.insert(.recorder)
        lifecycle.sync(changed: [.recorder], available: available)
        expect(capture.running && capture.syncs == 4, "a shared resource can be reenabled")
        lifecycle.terminate()
        expect(!brightness.running && !capture.running, "termination stops running owners")
        expect(environment.terminations == 1, "previously loaded owners retain their final flush hook")
        expect(capture.terminations == 1, "shared termination runs once")
        lifecycle.terminate()
        lifecycle.sync(changed: available, available: available)
        lifecycle.permissionChanged(.accessibility, available: available)
        expect(brightness.terminations == 1 && brightness.syncs == 4,
               "termination is idempotent and later callbacks cannot restart work")
        let neverLoaded = Service()
        let empty = FeatureLifecycle<Feature>([
            .init(members: [.environment], synchronize: { neverLoaded.sync(enabled: false) },
                  terminate: { neverLoaded.terminate() })
        ])
        empty.sync(changed: [.environment], available: [])
        empty.terminate()
        expect(neverLoaded.syncs == 0 && neverLoaded.terminations == 0,
               "disabled-at-launch owners are never constructed even on exit")
    }
}
