// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import Darwin
import Foundation

/// Called only from the monitor's serial queue while CPU monitoring is enabled.
final class CPUCoreSampler {
    /// Discard a delta baseline across an explicit pause, preserving session totals and metadata.
    func resetBaseline() {
        previous = nil
    }

    private var previous: (ticks: [CPUCoreTicks], time: TimeInterval)?

    func sample(now: TimeInterval, maxInterval: TimeInterval) -> [Double?] {
        guard let ticks = Self.readTicks() else {
            previous = nil
            return []
        }
        defer { previous = (ticks, now) }
        guard let previous, previous.ticks.count == ticks.count,
              now > previous.time, now - previous.time <= maxInterval else {
            return Array(repeating: nil, count: ticks.count)
        }
        return zip(ticks, previous.ticks).map { $0.usage(since: $1) }
    }

    private static func readTicks() -> [CPUCoreTicks]? {
        var processorCount: natural_t = 0
        var info: processor_info_array_t?
        var count: mach_msg_type_number_t = 0
        let host = mach_host_self()
        defer { mach_port_deallocate(mach_task_self_, host) }
        let result = host_processor_info(host, PROCESSOR_CPU_LOAD_INFO,
                                         &processorCount, &info, &count)
        guard result == KERN_SUCCESS, let info else { return nil }
        defer {
            vm_deallocate(mach_task_self_, vm_address_t(UInt(bitPattern: info)),
                          vm_size_t(count) * vm_size_t(MemoryLayout<integer_t>.stride))
        }
        let stride = Int(CPU_STATE_MAX)
        guard processorCount > 0, Int(processorCount) <= Int(count) / stride else { return nil }
        return (0..<Int(processorCount)).map { index in
            let base = index * stride
            return CPUCoreTicks(user: UInt32(bitPattern: info[base + Int(CPU_STATE_USER)]),
                                system: UInt32(bitPattern: info[base + Int(CPU_STATE_SYSTEM)]),
                                idle: UInt32(bitPattern: info[base + Int(CPU_STATE_IDLE)]),
                                nice: UInt32(bitPattern: info[base + Int(CPU_STATE_NICE)]))
        }
    }
}
