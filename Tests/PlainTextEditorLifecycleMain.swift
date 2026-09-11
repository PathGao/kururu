// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

@main
struct PlainTextEditorLifecycleMain {
    @MainActor static func main() {
        var checks = 0
        var failures = 0
        PlainTextEditorLifecycleTests.run { ok, message in
            checks += 1
            if !ok { failures += 1; print("FAIL: " + message) }
        }
        print("EDITOR LIFECYCLE: \(checks) checks, \(failures) failures")
        exit(failures == 0 ? 0 : 1)
    }
}
