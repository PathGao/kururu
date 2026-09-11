// SPDX-License-Identifier: GPL-3.0-or-later
import SwiftUI
import AppKit

enum MonitorThemeRenderingTests {
    @MainActor static func run(_ expect: (Bool, String) -> Void) {
        func render(_ palette: ImportedTheme?, contrast: ColorSchemeContrast = .standard) -> Data? {
            let view = VStack(spacing: 16) {
                CPUCoreMatrix(usage: [0, 0.45, 1, nil], palette: palette, increasedContrast: contrast == .increased,
                              coreGroups: [CPUCoreGroup(name: "CPU", indices: [0, 1, 2, 3])])
                MonitorTrendPlot(samples: [.init(id: 0, time: 0, value: 15, segment: 0),
                                           .init(id: 1, time: 30, value: 55, segment: 0)],
                                 now: 60, window: 1, ymax: 100, palette: palette)
                    .frame(height: 90)
            }.padding(20).frame(width: 420).background(.white)
                .environment(\.colorScheme, .light)
            let renderer = ImageRenderer(content: view)
            renderer.scale = 1
            guard let image = renderer.cgImage else { return nil }
            return NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:])
        }
        let primary = ImportedTheme(name: "primary", colors: [.primaryText: ThemeRGBA(hex: "#008040")!])
        let border = ImportedTheme(name: "border", colors: [.border: ThemeRGBA(hex: "#D00080")!])
        let secondary = ImportedTheme(name: "secondary", colors: [.secondaryText: ThemeRGBA(hex: "#D00080")!])
        let unused = ImportedTheme(name: "accent only", colors: [.accent: ThemeRGBA(hex: "#008040")!])
        let suite = "kururu.theme-render-test." + UUID().uuidString
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let preferences = ThemePreferences(defaults: defaults)
        do {
            try preferences.apply(primary)
            let saved = defaults.data(forKey: ThemePreferences.storageKey)
            _ = render(border)
            expect(preferences.applied == primary && defaults.data(forKey: ThemePreferences.storageKey) == saved,
                   "rendering candidate preserves applied theme and persistent bytes")
            try preferences.apply(border)
            expect(preferences.applied == border, "explicit application accepts candidate")
            preferences.restoreDefault()
            expect(preferences.applied == nil && defaults.data(forKey: ThemePreferences.storageKey) == nil,
                   "restore returns to default and clears saved theme")
        } catch { expect(false, "theme preference fixture failed: \(error)") }
        let baseline = render(nil)
        expect(baseline != nil, "production monitor views render offscreen")
        expect(render(nil) == baseline, "fixed samples render deterministically")
        expect(render(unused) == baseline, "missing monitor roles preserve exact default output")
        expect(render(primary) != baseline, "primary theme color changes real core and curve rendering")
        expect(render(border) != baseline, "border theme color changes real core rendering")
        expect(render(secondary) != baseline, "secondary theme color changes core group and missing label rendering")
        expect(render(nil, contrast: .increased) != baseline, "increased contrast retains distinct core boundaries")
        expect(render(primary) == render(primary), "explicit candidate rendering is repeatable")
    }
}
