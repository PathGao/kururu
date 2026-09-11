// SPDX-License-Identifier: GPL-3.0-or-later
import SwiftUI
import Charts

/// Shared trend strips; visibility controls presentation, never acquisition.
struct MonitorTrendView: View {
    let metrics: [MonitorMetric]
    var embedded = false

    var body: some View {
        ForEach(metrics, id: \.self) { metric in
            MonitorMetricTrend(metric: metric, embedded: embedded)
        }
    }
}

private struct MonitorMetricTrend: View {
    @ObservedObject private var palettePreferences = ThemePreferences.shared
    @ObservedObject private var monitor = SystemMonitor.shared
    @ObservedObject private var l10n = L10n.shared
    @AppStorage("monitorHistoryMinutes") private var minutes = 1
    @AppStorage(DefaultsKey.temperatureUnit) private var temperatureUnit = TemperatureUnit.celsius.rawValue
    @AppStorage private var visible: Bool
    @State private var hoveredX: Double?
    let metric: MonitorMetric
    let embedded: Bool

    init(metric: MonitorMetric, embedded: Bool) {
        self.metric = metric
        self.embedded = embedded
        _visible = AppStorage(wrappedValue: true, metric.graphPreferenceKey)
    }

    private var text: MonitorHistoryStrings { .text(l10n.language) }
    private var window: Int { min(5, max(1, minutes)) }

    var body: some View {
        if visible {
            if embedded {
                timeline
            } else {
                timeline.panelCard()
            }
        }
    }

    private var timeline: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            plot(now: context.date.timeIntervalSince1970)
        }
    }

    private func plot(now: TimeInterval) -> some View {
        let samples = monitor.snapshot.history.points(metric, endingAt: now, minutes: window)
        let ymax = ceiling(samples)
        let hovered = hoveredX.flatMap { x -> MonitorSample? in
            guard let nearest = samples.min(by: { abs($0.time - now - x) < abs($1.time - now - x) }),
                  abs(nearest.time - now - x) <= 3 else { return nil }
            return nearest
        }
        return VStack(alignment: .leading, spacing: 6) {
            if !embedded {
                HStack {
                Text(title(metric)).foregroundStyle(.secondary)
                Spacer()
                if let sample = hovered ?? samples.last {
                    Text(hovered == nil ? format(sample.value) : "\(Date(timeIntervalSince1970: sample.time).formatted(date: .omitted, time: .standard))  ·  \(format(sample.value))")
                        .monospacedDigit()
                }
            }
                .font(PanelTypography.meta)
            }
            MonitorTrendPlot(
                samples: samples.enumerated().map { .init(id: $0.offset, time: $0.element.time, value: value($0.element.value), segment: $0.element.segment) },
                now: now, window: window, ymax: ymax,
                hovered: hovered.map { .init(id: -1, time: $0.time, value: value($0.value), segment: $0.segment) },
                palette: palettePreferences.applied, nowLabel: text.now, axisFormat: axisFormat)
            .chartOverlay { proxy in
                GeometryReader { geometry in
                    Color.clear.contentShape(Rectangle())
                        .onContinuousHover { phase in
                            switch phase {
                            case .active(let location):
                                if let frame = proxy.plotFrame {
                                    hoveredX = proxy.value(atX: location.x - geometry[frame].origin.x)
                                }
                            case .ended: hoveredX = nil
                            }
                        }
                }
            }
            .frame(height: 72)
            .overlay(alignment: .topLeading) {
                if embedded, let hovered {
                    Text("\(Date(timeIntervalSince1970: hovered.time).formatted(date: .omitted, time: .standard))  ·  \(format(hovered.value))")
                        .font(PanelTypography.meta).monospacedDigit()
                        .padding(.horizontal, 4)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 3))
                        .allowsHitTesting(false)
                }
            }
            .accessibilityLabel(title(metric) + " " + text.history)
            if samples.count < 2 {
                Text(text.collecting).font(PanelTypography.meta).foregroundStyle(.tertiary)
            }
        }
    }

    private var percentage: Bool { [.cpu, .gpu, .memory, .memoryApp, .battery].contains(metric) }
    private var temperature: Bool { [.cpuTemperature, .gpuTemperature, .batteryTemperature].contains(metric) }
    private var rate: Bool { [.networkDown, .networkUp, .diskRead, .diskWrite].contains(metric) }
    private func value(_ raw: Double) -> Double {
        if percentage { return raw * 100 }
        if temperature, temperatureUnit == TemperatureUnit.fahrenheit.rawValue { return raw * 1.8 + 32 }
        return raw
    }
    private func ceiling(_ samples: [MonitorSample]) -> Double {
        if percentage { return MonitorHistory.percentageCeiling(samples.map { $0.value }) }
        let peak = samples.map { value($0.value) }.max() ?? 0
        if temperature { return max(temperatureUnit == TemperatureUnit.fahrenheit.rawValue ? 212 : 100, ceil(peak / 10) * 10) }
        return max(1, peak * 1.15)
    }
    private func format(_ raw: Double) -> String { axisFormat(value(raw)) }
    private func axisFormat(_ v: Double) -> String {
        if percentage { return String(format: "%.0f%%", locale: MetricFormat.locale, v) }
        if temperature { return String(format: "%.0f %@", locale: MetricFormat.locale, v, temperatureUnit == TemperatureUnit.fahrenheit.rawValue ? "°F" : "°C") }
        if rate { return MetricFormat.bytesPerSec(v) }
        if metric == .fan { return String(format: "%.0f rpm", locale: MetricFormat.locale, v) }
        return MetricFormat.watts(v)
    }
    private func title(_ item: MonitorMetric) -> String {
        switch item {
        case .cpu: return l10n.s.cpuLabel
        case .gpu: return l10n.s.gpuLabel
        case .memory: return l10n.s.memorySection
        case .memoryApp: return l10n.s.memoryMetricApp
        case .networkDown: return "↓ " + l10n.s.networkSection
        case .networkUp: return "↑ " + l10n.s.networkSection
        case .diskRead: return "↓ " + l10n.s.diskSection
        case .diskWrite: return "↑ " + l10n.s.diskSection
        case .power: return l10n.s.powerSection
        case .battery: return l10n.s.batteryLabel
        case .cpuTemperature: return l10n.s.cpuLabel + " · " + l10n.s.temperatures
        case .gpuTemperature: return l10n.s.gpuLabel + " · " + l10n.s.temperatures
        case .batteryTemperature: return l10n.s.batteryLabel + " · " + l10n.s.temperatures
        case .fan: return FeatureStrings.fanControl(l10n.language).menuBarTitle
        }
    }
}
