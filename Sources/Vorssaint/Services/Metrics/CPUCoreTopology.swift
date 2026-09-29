// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import Darwin
import Foundation
import IOKit

/// Read once; registry logical IDs are matched to Mach slots rather than guessed from counts.
enum CPUCoreTopology {
    static let groups: [CPUCoreGroup] = read()

    static func groups(for count: Int) -> [CPUCoreGroup] {
        guard groups.reduce(0, { $0 + $1.indices.count }) == count else {
            return count == 0 ? [] : [CPUCoreGroup(name: "CPU", indices: Array(0..<count))]
        }
        return groups
    }

    private static func read() -> [CPUCoreGroup] {
        #if arch(arm64)
        guard let levelCount = integer("hw.nperflevels"), (1...8).contains(levelCount),
              let slots = processorSlots() else { return [] }
        var levels: [CPUPerformanceLevel] = []
        for level in 0..<levelCount {
            guard let name = string("hw.perflevel\(level).name"),
                  let count = integer("hw.perflevel\(level).logicalcpu_max") else { return [] }
            levels.append(CPUPerformanceLevel(name: name, count: count))
        }
        let root = IORegistryEntryFromPath(kIOMainPortDefault, "IODeviceTree:/cpus")
        guard root != 0 else { return [] }
        defer { IOObjectRelease(root) }
        var iterator: io_iterator_t = 0
        guard IORegistryEntryGetChildIterator(root, kIODeviceTreePlane, &iterator) == KERN_SUCCESS else { return [] }
        defer { IOObjectRelease(iterator) }
        var cores: [CPURegistryCore] = []
        while case let entry = IOIteratorNext(iterator), entry != 0 {
            defer { IOObjectRelease(entry) }
            guard let id = IORegistryEntryCreateCFProperty(entry, "logical-cpu-id" as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue() as? NSNumber,
                  let data = IORegistryEntryCreateCFProperty(entry, "cluster-type" as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue() as? Data,
                  let type = String(data: data.prefix(while: { $0 != 0 }), encoding: .utf8) else { continue }
            cores.append(CPURegistryCore(id: id.intValue, type: type))
        }
        return CPUCoreTopologySupport.groups(levels: levels, cores: cores, slots: slots)
        #else
        return []
        #endif
    }

    private static func processorSlots() -> [Int]? {
        var processors: natural_t = 0
        var info: processor_info_array_t?
        var count: mach_msg_type_number_t = 0
        let host = mach_host_self()
        defer { mach_port_deallocate(mach_task_self_, host) }
        guard host_processor_info(host, PROCESSOR_BASIC_INFO, &processors, &info, &count) == KERN_SUCCESS,
              let info else { return nil }
        defer { vm_deallocate(mach_task_self_, vm_address_t(UInt(bitPattern: info)), vm_size_t(count) * vm_size_t(MemoryLayout<integer_t>.stride)) }
        let stride = MemoryLayout<processor_basic_info>.stride / MemoryLayout<integer_t>.stride
        guard processors > 0, Int(processors) <= Int(count) / stride else { return nil }
        let records = UnsafeRawPointer(info).assumingMemoryBound(to: processor_basic_info.self)
        return (0..<Int(processors)).map { Int(records[$0].slot_num) }
    }

    private static func integer(_ key: String) -> Int? {
        var value: Int32 = 0
        var size = MemoryLayout<Int32>.size
        return sysctlbyname(key, &value, &size, nil, 0) == 0 ? Int(value) : nil
    }

    private static func string(_ key: String) -> String? {
        var size = 0
        guard sysctlbyname(key, nil, &size, nil, 0) == 0, size > 0, size < 256 else { return nil }
        var bytes = [UInt8](repeating: 0, count: size)
        guard sysctlbyname(key, &bytes, &size, nil, 0) == 0 else { return nil }
        return String(bytes: bytes.prefix(while: { $0 != 0 }), encoding: .utf8)
    }
}
