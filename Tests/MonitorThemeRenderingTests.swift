// SPDX-License-Identifier: GPL-3.0-or-later
import SwiftUI
import AppKit

enum MonitorThemeRenderingTests {
    @MainActor static func run(_ expect: (Bool, String) -> Void) {
        func render(contrast: ColorSchemeContrast = .standard) -> Data? {
            let view = VStack(spacing: 16) {
                CPUCoreMatrix(usage: [0, 0.45, 1, nil], increasedContrast: contrast == .increased,
                              coreGroups: [CPUCoreGroup(name: "CPU", indices: [0, 1, 2, 3])])
                MonitorTrendPlot(samples: [.init(id: 0, time: 0, value: 15, segment: 0),
                                           .init(id: 1, time: 30, value: 55, segment: 0)],
                                 now: 60, window: 1, ymax: 100)
                    .frame(height: 90)
            }.padding(20).frame(width: 420).background(.white)
                .environment(\.colorScheme, .light)
            let renderer = ImageRenderer(content: view)
            renderer.scale = 1
            guard let image = renderer.cgImage else { return nil }
            return NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:])
        }
        let baseline = render()
        expect(baseline != nil, "production monitor views render offscreen")
        expect(render() == baseline, "fixed samples render deterministically")
        expect(render(contrast: .increased) != baseline, "increased contrast retains distinct core boundaries")
    }
}
