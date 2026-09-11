// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import Foundation

enum FinderTargetAcquisitionTests {
    static func run(_ expect: (Bool, String) -> Void) {
        let selected = FinderArrangementSnapshot(windowID: 73, path: "/tmp/chosen", rule: .grid)
        var scripts: [String] = []
        var client = FinderArrangementClient(
            run: { script in
                scripts.append(script)
                return (true, nil, "", "73\n1\n/tmp/chosen")
            },
            acceptsPath: { $0 == "/tmp/chosen" }
        )

        expect(client.acquire(path: "/tmp/chosen") == .success(selected),
               "an explicit valid path acquires its Finder window snapshot")
        expect(scripts.count == 1 && scripts[0].contains("POSIX file \"/tmp/chosen\""),
               "acquisition asks Finder to open the selected path")
        expect(scripts[0].contains("POSIX path of (target of candidate as alias)"),
               "acquisition matches a Finder window by its exact target path")
        expect(FinderArrangementSupport.samePath("/tmp/chosen/", "/tmp/chosen"),
               "Finder's optional trailing directory slash keeps the selected target identity")

        let beforeUnsafe = scripts.count
        expect(client.acquire(path: "/tmp/other") == .failure(.unsupported)
                   && scripts.count == beforeUnsafe,
               "an unsupported selected path never reaches Finder")

        client.run = { script in
            scripts.append(script)
            return (true, nil, "", "73\n2\n/tmp/chosen")
        }
        expect(client.change(selected, to: .none) == .failure(.changed),
               "restore refuses a target whose arrangement changed since apply")
    }
}
