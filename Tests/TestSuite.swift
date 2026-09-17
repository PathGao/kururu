// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import Foundation

/// Shared assertions for both the full run and selected suites. Recording a
/// failure never stops the remaining assertions; the runner owns the exit code.
final class TestSuite {
    private let lock = NSLock()
    private(set) var checks = 0
    private(set) var failures: [String] = []

    func expect(_ condition: Bool, _ message: @autoclosure () -> String,
                file: StaticString = #filePath, line: UInt = #line) {
        let failure = condition ? nil : "\(file):\(line): \(message())"
        lock.withLock {
            checks += 1
            if let failure { failures.append(failure) }
        }
    }

    func expectClose(_ actual: Double, _ expected: Double, _ label: String,
                     tol: Double = 0.0001, file: StaticString = #filePath, line: UInt = #line) {
        expect(actual.isFinite && expected.isFinite && tol.isFinite && tol >= 0
                   && abs(actual - expected) <= tol,
               "\(label): got \(actual), expected \(expected) within \(tol)", file: file, line: line)
    }

    func run(_ name: String, _ body: () -> Void) {
        let before = checks
        let previousFailures = failures.count
        let started = ProcessInfo.processInfo.systemUptime
        body()
        if checks == before { expect(false, "\(name) executed no assertions") }
        let elapsed = ProcessInfo.processInfo.systemUptime - started
        let status = failures.count == previousFailures ? "OK" : "FAILED"
        print("\(name): \(status) (\(checks - before) checks, \(String(format: "%.2f", elapsed))s)")
    }

    func finish() -> Never {
        if failures.isEmpty {
            print("TESTS OK (\(checks) checks)")
            exit(0)
        }
        print("TESTS FAILED (\(failures.count) of \(checks)):")
        failures.forEach { print("  - \($0)") }
        exit(1)
    }
}
