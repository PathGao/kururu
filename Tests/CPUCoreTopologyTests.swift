// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

enum CPUCoreTopologyTests {
    static func run(_ expect: (Bool, String) -> Void) {
        for width in [160.0, 240, 280, 304, 340, 500] {
            for counts in [[4, 6], [2, 4, 6], [32, 16], [64, 32, 24], [1], [12, 0, 4]] {
                var start = 0
                let groups = counts.enumerated().map { index, count in
                    defer { start += count }
                    return CPUCoreGroup(name: ["Super", "Performance", "Efficiency"][index % 3], indices: Array(start..<(start + count)))
                }
                let rows = CPUCoreLayout.rows(groups: groups, width: width)
                expect(rows.flatMap { $0 }.flatMap(\.group.indices) == Array(0..<start), "adaptive layout preserves every core exactly once")
                expect(rows.allSatisfy { row in row.reduce(0, { $0 + $1.width }) + Double(max(0, row.count - 1)) * 12 <= width + 0.01 }, "adaptive rows stay inside their available width")
                let readable = rows.flatMap { $0 }.allSatisfy { segment in
                    let count = Double(segment.group.indices.count)
                    let barWidth = (segment.width - (count - 1) * 4) / count
                    return barWidth >= 13.99
                }
                expect(readable, "dense layouts keep each core readable")
            }
        }
        let many = CPUCoreGroup(name: "Super", indices: Array(0..<32))
        let chunks = CPUCoreLayout.rows(groups: [many], width: 264).flatMap { $0 }.map { $0.group.indices.count }
        expect((chunks.max() ?? 0) - (chunks.min() ?? 0) <= 1, "high-core layouts balance rows instead of stretching a tiny last row")
        expect(CPUCoreLayout.rows(groups: [], width: 0).isEmpty, "empty layouts have no synthetic cores")
        let levels = [CPUPerformanceLevel(name: "Super", count: 4), CPUPerformanceLevel(name: "Efficiency", count: 6)]
        let cores = (0..<10).map { CPURegistryCore(id: $0, type: $0 < 6 ? "E" : "P") }
        let result = CPUCoreTopologySupport.groups(levels: levels, cores: cores.reversed(), slots: Array(0..<10))
        expect(result == [CPUCoreGroup(name: "Super", indices: Array(6..<10)), CPUCoreGroup(name: "Efficiency", indices: Array(0..<6))],
               "M5 groups use logical IDs, not registry iteration or perflevel order")
        let shuffled = CPUCoreTopologySupport.groups(levels: levels, cores: cores, slots: [6, 0, 7, 1, 8, 2, 9, 3, 4, 5])
        expect(shuffled.first?.indices == [0, 2, 4, 6], "group indices address the original sampler order")
        let triple = [CPUPerformanceLevel(name: "Super", count: 2), CPUPerformanceLevel(name: "Performance", count: 4), CPUPerformanceLevel(name: "Efficiency", count: 6)]
        let tripleCores = (0..<12).map { CPURegistryCore(id: $0, type: $0 < 6 ? "E" : ($0 < 10 ? "P" : "S")) }
        let three = CPUCoreTopologySupport.groups(levels: triple, cores: tripleCores, slots: Array(0..<12))
        expect(three.map(\.name) == ["Super", "Performance", "Efficiency"], "three reported core classes stay separate")
        expect(three.map(\.indices) == [Array(10..<12), Array(6..<10), Array(0..<6)], "three-class membership remains exact")
        for invalid in [Array(cores.dropLast()), cores + [cores[0]], cores.map { CPURegistryCore(id: $0.id, type: "?") }] {
            expect(CPUCoreTopologySupport.groups(levels: levels, cores: invalid, slots: Array(0..<10)).map(\.name) == ["CPU"],
                   "missing, duplicated or unknown registry identities never invent a class")
        }
        expect(CPUCoreTopologySupport.groups(levels: triple, cores: cores, slots: Array(0..<10)).map(\.name) == ["CPU"], "class counts must agree with registry")
        expect(CPUCoreTopologySupport.groups(levels: levels, cores: cores, slots: Array(repeating: 0, count: 10)).map(\.name) == ["CPU"], "duplicate processor slots fail closed")
    }
}
