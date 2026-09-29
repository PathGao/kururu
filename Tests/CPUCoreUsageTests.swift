// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

enum CPUCoreUsageTests {
    static func run(_ expect: (Bool, String) -> Void) {
        let zero = CPUCoreTicks(user: 0, system: 0, idle: 0, nice: 0)
        expect(CPUCoreTicks(user: 20, system: 20, idle: 50, nice: 10).usage(since: zero) == 0.5,
               "per-core usage counts user, system and nice as busy")
        expect(CPUCoreTicks(user: 0, system: 0, idle: 100, nice: 0).usage(since: zero) == 0,
               "a fully idle core is a valid zero reading")
        expect(CPUCoreTicks(user: 100, system: 0, idle: 0, nice: 0).usage(since: zero) == 1,
               "a fully busy core is a valid full reading")
        expect(zero.usage(since: zero) == nil,
               "unchanged counters do not invent a zero reading")
        let previous = CPUCoreTicks(user: 100, system: 100, idle: 100, nice: 100)
        expect(CPUCoreTicks(user: 110, system: 110, idle: 120, nice: 100).usage(since: previous) == 0.5,
               "per-core readings use the interval delta, not lifetime totals")
        expect(zero.usage(since: previous) == nil,
               "reset counters require a fresh baseline")
        let beforeWrap = CPUCoreTicks(user: UInt32.max - 4, system: 0, idle: 0, nice: 0)
        expect(CPUCoreTicks(user: 5, system: 0, idle: 10, nice: 0).usage(since: beforeWrap) == 0.5,
               "a 32-bit tick rollover preserves the interval delta")
    }
}
