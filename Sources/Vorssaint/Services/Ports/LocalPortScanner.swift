// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import Foundation

enum LocalPortScanner {
    struct Result {
        let rows: [LocalPort]
        let isSuccess: Bool
    }
    static let outputLimit = 2 * 1024 * 1024

    static func snapshot() -> Result {
        let result = BoundedProcessRunner.run("/usr/sbin/lsof",
            ["-nP", "-iTCP", "-sTCP:LISTEN", "-iUDP", "-F0pcftPnT"],
            timeout: 5, maxOutputBytes: outputLimit)
        return classify(status: result.status, timedOut: result.timedOut, output: result.output)
    }

    static func classify(status: Int32, timedOut: Bool, output: Data) -> Result {
        let text = String(decoding: output, as: UTF8.self)
        let successful = !timedOut && output.count < outputLimit
            && ((status == 0 && !text.contains("lsof:")) || (status == 1 && output.isEmpty))
        return Result(rows: LocalPortSupport.parse(output), isSuccess: successful)
    }
}
