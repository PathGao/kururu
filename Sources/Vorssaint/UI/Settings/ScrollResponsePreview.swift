// SPDX-License-Identifier: GPL-3.0-or-later
import SwiftUI

/// Runs the same engine as live scrolling; this is cumulative distance, not
/// a decorative Bézier approximation or a pointer acceleration graph.
struct ScrollResponsePreview: View {
    let step: Int
    let response: Int
    let title: String

    private var samples: [Double] {
        var engine = SmoothScrollSupport.Engine()
        engine.add(vertical: Double(SmoothScrollSupport.sanitizedStep(step)), horizontal: 0)
        var distance = 0.0
        return [0] + (1...60).map { _ in
            distance += engine.advance(elapsed: 0.01, response: response).vertical
            return distance
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(SettingsTypography.caption).foregroundStyle(.secondary)
            Canvas { context, size in
                var grid = Path()
                for fraction in [0.0, 0.5, 1.0] {
                    let y = size.height * fraction
                    grid.move(to: CGPoint(x: 0, y: y)); grid.addLine(to: CGPoint(x: size.width, y: y))
                }
                context.stroke(grid, with: .color(.secondary.opacity(0.2)))
                var path = Path()
                for (index, distance) in samples.enumerated() {
                    let point = CGPoint(x: size.width * Double(index) / 60,
                                        y: size.height * (1 - distance / 100))
                    if index == 0 { path.move(to: point) } else { path.addLine(to: point) }
                }
                context.stroke(path, with: .color(.accentColor), lineWidth: 2)
            }
            .frame(height: 90)
            .accessibilityLabel(title)
            .accessibilityValue("\(SmoothScrollSupport.sanitizedStep(step)) pt, \(SmoothScrollSupport.sanitizedResponse(response))%")
            HStack {
                Text("0 ms · 0–100 pt")
                Spacer()
                Text("600 ms")
            }.font(.caption2.monospacedDigit()).foregroundStyle(.secondary)
        }
    }
}
