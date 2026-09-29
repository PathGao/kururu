// SPDX-License-Identifier: GPL-3.0-or-later
import SwiftUI
import Charts

/// Monitor history with explicit samples and system semantic colors.
struct MonitorTrendPlot: View {
    struct Sample: Identifiable {
        let id: Int
        let time: Double
        let value: Double
        let segment: Int
    }
    let samples: [Sample]
    let now: Double
    let window: Int
    let ymax: Double
    var hovered: Sample? = nil
    var nowLabel = "Now"
    var axisFormat: (Double) -> String = { String(format: "%.0f", locale: Locale.current, $0) }
    private var segmentCounts: [Int: Int] { Dictionary(grouping: samples, by: \.segment).mapValues(\.count) }
    var body: some View {
            Chart {
                ForEach(samples) { sample in
                    LineMark(x: .value("Time", sample.time - now), y: .value("Value", sample.value),
                             series: .value("Interval", sample.segment))
                        .interpolationMethod(.linear)
                        .lineStyle(StrokeStyle(lineWidth: 1.6, lineCap: .round))
                        .foregroundStyle(Color.primary.opacity(0.78))
                }
                ForEach(samples.filter { segmentCounts[$0.segment] == 1 }) { sample in
                    PointMark(x: .value("Time", sample.time - now), y: .value("Value", sample.value))
                        .foregroundStyle(Color.primary.opacity(0.78)).symbolSize(14)
                }
                if let hovered {
                    RuleMark(x: .value("Time", hovered.time - now))
                        .foregroundStyle(Color.secondary.opacity(0.5))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))
                    PointMark(x: .value("Time", hovered.time - now), y: .value("Value", hovered.value))
                        .foregroundStyle(Color.primary.opacity(0.78)).symbolSize(20)
                }
            }
            .chartXScale(domain: -Double(window * 60)...0)
            .chartYScale(domain: 0...ymax)
            .chartXAxis {
                AxisMarks(values: [-Double(window * 60), 0]) { axis in
                    if let seconds = axis.as(Double.self) {
                        AxisValueLabel(anchor: seconds == 0 ? .topTrailing : (seconds == -Double(window * 60) ? .topLeading : .top),
                                       collisionResolution: .disabled) {
                            Text(seconds == 0 ? nowLabel : relativeTime(seconds)).foregroundStyle(Color.secondary)
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .trailing, values: [0, ymax]) { axis in
                    AxisGridLine().foregroundStyle(Color.secondary.opacity(0.12))
                    AxisValueLabel {
                        if let v = axis.as(Double.self) { Text(axisFormat(v)).foregroundStyle(Color.secondary) }
                    }
                }
            }
    }
    private func relativeTime(_ seconds: Double) -> String {
        let total = Int(abs(seconds))
        let minutes = total / 60
        let seconds = total % 60
        return minutes == 0 ? "−\(seconds)s" : "−\(minutes)m" + (seconds == 0 ? "" : "\(seconds)s")
    }
}
