// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import Foundation

struct CPUCoreGroup: Equatable {
    let name: String
    let indices: [Int]
    var weight: Double {
        switch name.lowercased() {
        case "super": return 1.5
        case "performance": return 1.25
        default: return 1
        }
    }
}

struct CPUPerformanceLevel {
    let name: String
    let count: Int
}

struct CPURegistryCore {
    let id: Int
    let type: String
}

enum CPUCoreTopologySupport {
    static func groups(levels: [CPUPerformanceLevel], cores: [CPURegistryCore], slots: [Int]) -> [CPUCoreGroup] {
        let fallback = slots.isEmpty ? [] : [CPUCoreGroup(name: "CPU", indices: Array(slots.indices))]
        guard !levels.isEmpty, levels.allSatisfy({ $0.count > 0 }),
              Set(levels.map(\.name)).count == levels.count,
              levels.reduce(0, { $0 + $1.count }) == slots.count,
              Set(slots).count == slots.count,
              cores.count == slots.count, Set(cores.map(\.id)) == Set(slots)
        else { return fallback }
        // XNU orders perflevels by cluster performance, not by logical CPU ID.
        let order = ["S", "P", "E"]
        let types = Set(cores.map(\.type))
        guard types.isSubset(of: Set(order)), types.count == levels.count else { return fallback }
        let orderedTypes = order.filter { types.contains($0) }
        let byID = Dictionary(uniqueKeysWithValues: cores.map { ($0.id, $0.type) })
        var groups: [CPUCoreGroup] = []
        for (level, type) in zip(levels, orderedTypes) {
            let indices = slots.indices.filter { byID[slots[$0]] == type }
            guard indices.count == level.count else { return fallback }
            groups.append(CPUCoreGroup(name: level.name, indices: indices))
        }
        return groups
    }
}

struct CPUCoreSegment {
    let group: CPUCoreGroup
    let width: Double
}

enum CPUCoreLayout {
    static func rows(groups: [CPUCoreGroup], width: Double) -> [[CPUCoreSegment]] {
        guard width.isFinite, width >= 70 else { return [] }
        func minimum(_ group: CPUCoreGroup) -> Double {
            max(70, Double(group.indices.count) * 14 * group.weight + Double(group.indices.count - 1) * 4)
        }
        var packed: [[CPUCoreGroup]] = []
        var row: [CPUCoreGroup] = []
        var used = 0.0
        for group in groups where !group.indices.isEmpty {
            let limit = min(12, max(1, Int((width + 4) / (14 * group.weight + 4))))
            let chunkCount = (group.indices.count + limit - 1) / limit
            let baseCount = group.indices.count / chunkCount
            let remainder = group.indices.count % chunkCount
            var offset = 0
            for part in 0..<chunkCount {
                let count = baseCount + (part < remainder ? 1 : 0)
                let chunk = CPUCoreGroup(name: group.name, indices: Array(group.indices[offset..<(offset + count)]))
                offset += count
                let required = minimum(chunk)
                if !row.isEmpty, used + 12 + required > width {
                    packed.append(row)
                    row = []
                    used = 0
                }
                used += (row.isEmpty ? 0 : 12) + required
                row.append(chunk)
            }
        }
        if !row.isEmpty { packed.append(row) }
        return packed.map { row in
            let available = width - Double(row.count - 1) * 12
            let minimums = row.map(minimum)
            let extra = max(0, available - minimums.reduce(0, +))
            let weights = row.map { Double($0.indices.count) * $0.weight }
            let total = weights.reduce(0, +)
            return row.indices.map { index in
                CPUCoreSegment(group: row[index], width: minimums[index] + extra * weights[index] / total)
            }
        }
    }
}
