// SPDX-License-Identifier: GPL-3.0-or-later

import Foundation

enum BoundedProcessCancellationTests {
    static func run(_ expect: (Bool, String) -> Void) {
        let prelaunch = BoundedProcessCancellation()
        prelaunch.cancel()
        let marker = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent(".build/prelaunch-\(UUID().uuidString)")
        let prelaunchResult = BoundedProcessRunner.run(
            "/usr/bin/touch", [marker.path], timeout: 1, maxOutputBytes: 1_024,
            cancellation: prelaunch)
        expect(prelaunchResult.cancelled && !prelaunchResult.timedOut && prelaunchResult.status == -1,
               "pre-launch cancellation is distinct from timeout and launch failure")
        expect(!FileManager.default.fileExists(atPath: marker.path),
               "pre-launch cancellation prevents the child side effect")

        let running = BoundedProcessCancellation()
        let started = Date()
        DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 0.05) {
            running.cancel()
        }
        let runningResult = BoundedProcessRunner.run(
            "/bin/sleep", ["5"], timeout: 3, maxOutputBytes: 1_024,
            cancellation: running)
        expect(runningResult.cancelled && !runningResult.timedOut && runningResult.status == -1,
               "running cancellation is reported explicitly")
        expect(Date().timeIntervalSince(started) < 1.5,
               "running cancellation terminates the child promptly")

        let timeout = BoundedProcessRunner.run(
            "/bin/sleep", ["5"], timeout: 0.05, maxOutputBytes: 1_024)
        expect(timeout.timedOut && !timeout.cancelled && timeout.status == -1,
               "timeout remains distinct from cancellation")

        let capped = BoundedProcessRunner.run(
            "/bin/sh", ["-c", "/usr/bin/yes x | /usr/bin/head -c 200000"],
            timeout: 2, maxOutputBytes: 1_024)
        expect(capped.status == 0 && !capped.cancelled && capped.output.count == 1_024,
               "output stays bounded without changing a successful result")

        let sequence = BoundedProcessCancellation()
        let secondMarker = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent(".build/second-launch-\(UUID().uuidString)")
        DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 0.05) {
            sequence.cancel()
        }
        let first = BoundedProcessRunner.run(
            "/bin/sleep", ["5"], timeout: 3, maxOutputBytes: 1_024,
            cancellation: sequence)
        let second = BoundedProcessRunner.run(
            "/usr/bin/touch", [secondMarker.path], timeout: 1, maxOutputBytes: 1_024,
            cancellation: sequence)
        expect(first.cancelled && second.cancelled
                && !FileManager.default.fileExists(atPath: secondMarker.path),
               "one token cancels the active read and prevents the next sequential read")
    }
}
