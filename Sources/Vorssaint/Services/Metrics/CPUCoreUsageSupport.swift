// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

struct CPUCoreTicks {
    let user: UInt32
    let system: UInt32
    let idle: UInt32
    let nice: UInt32

    func usage(since previous: Self) -> Double? {
        let current = [user, system, idle, nice]
        let earlier = [previous.user, previous.system, previous.idle, previous.nice]
        var deltas: [UInt64] = []
        for (new, old) in zip(current, earlier) {
            // A small backwards step is a reset; a large one is UInt32 rollover.
            guard new >= old || old - new > UInt32.max / 2 else { return nil }
            deltas.append(UInt64(new &- old))
        }
        let total = deltas.reduce(0, +)
        guard total > 0 else { return nil }
        return Double(total - deltas[2]) / Double(total)
    }
}
