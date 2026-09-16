// SPDX-License-Identifier: GPL-3.0-or-later

import Foundation

@main
struct HomebrewEnvironmentCheckSettlementTests {
    static func main() {
        var failures: [String] = []
        func expect(_ condition: Bool, _ message: String) {
            if !condition { failures.append(message) }
        }

        var cancellations = 0
        let cancelled = HomebrewEnvironmentCheckSettlement { snapshot in
            cancellations += 1
            expect(snapshot == nil, "cancellation settles with no snapshot")
        }
        cancelled.settle(nil)
        cancelled.settle(EnvironmentHomebrewSnapshot(packages: [], updates: [:]))
        expect(cancellations == 1, "a late read cannot settle a cancelled check twice")

        var successes = 0
        let successful = HomebrewEnvironmentCheckSettlement { snapshot in
            successes += 1
            expect(snapshot != nil, "a current check delivers its snapshot")
        }
        successful.settle(EnvironmentHomebrewSnapshot(packages: [], updates: [:]))
        successful.settle(nil)
        expect(successes == 1, "a completed check ignores later cancellation")

        var racedValue: EnvironmentHomebrewSnapshot??
        let raced = HomebrewEnvironmentCheckSettlement { racedValue = $0 }
        let queued = DispatchSemaphore(value: 0)
        DispatchQueue.global(qos: .userInitiated).async {
            raced.settle(EnvironmentHomebrewSnapshot(packages: [], updates: [:]))
            queued.signal()
        }
        _ = queued.wait(timeout: .now() + 1)
        raced.settle(nil)
        RunLoop.main.run(until: Date().addingTimeInterval(0.05))
        expect(racedValue != nil, "cancel settles while a worker result waits for the main thread")
        expect(racedValue! == nil, "cancel wins over an already queued late worker result")

        if failures.isEmpty {
            print("6 Homebrew settlement checks passed")
        } else {
            failures.forEach { fputs("FAIL: \($0)\n", stderr) }
            exit(1)
        }
    }
}
