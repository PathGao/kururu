// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

enum MonitorMetric: String, CaseIterable {
    case cpu, gpu, memory, memoryApp, networkDown, networkUp, diskRead, diskWrite
    case power, battery, cpuTemperature, gpuTemperature, batteryTemperature, fan

    var graphPreferenceKey: String {
        switch self {
        case .cpu, .cpuTemperature: return "monitorGraphCPU"
        case .gpu, .gpuTemperature: return "monitorGraphGPU"
        case .memory, .memoryApp: return "monitorGraphMemory"
        case .networkDown, .networkUp: return "monitorGraphNetwork"
        case .diskRead, .diskWrite: return "monitorGraphDisk"
        case .power: return "monitorGraphPower"
        case .battery, .batteryTemperature: return "monitorGraphBattery"
        case .fan: return "monitorGraphFan"
        }
    }
}

struct MonitorSample: Identifiable {
    var id: TimeInterval { time }
    let time: TimeInterval
    let value: Double
    let segment: Int
}

/// Queue-confined, five-minute history. Missing reads and long gaps split lines.
struct MonitorHistory {
    private(set) var series: [MonitorMetric: [MonitorSample]] = [:]
    private var segments: [MonitorMetric: Int] = [:]
    private var intervals: [MonitorMetric: TimeInterval] = [:]

    mutating func record(_ metric: MonitorMetric, value: Double?, at time: TimeInterval,
                         interval: TimeInterval) {
        guard time.isFinite else { return }
        var samples = series[metric, default: []]
        var segment = segments[metric, default: 0]
        if let last = samples.last {
            if time <= last.time {
                samples.removeAll()
                segment += 1
            } else if time - last.time > max(interval, intervals[metric, default: interval]) * 1.8 {
                segment += 1
            }
        }
        samples.removeAll { $0.time < time - 300 }
        if let value, value.isFinite {
            samples.append(MonitorSample(time: time, value: value, segment: segment))
        } else {
            segment += 1
        }
        if samples.count > 601 { samples.removeFirst(samples.count - 601) }
        series[metric] = samples
        segments[metric] = segment
        intervals[metric] = interval
    }

    /// Stable percentage steps avoid rescaling on every small fluctuation.
    static func percentageCeiling(_ values: [Double]) -> Double {
        let peak = max(0, values.filter(\.isFinite).max() ?? 0) * 100
        return [10.0, 20, 40, 60, 80, 100].first { $0 >= min(100, peak * 1.1) } ?? 100
    }

    mutating func markGap() {
        for metric in MonitorMetric.allCases { segments[metric, default: 0] += 1 }
    }

    func points(_ metric: MonitorMetric, endingAt now: TimeInterval, minutes: Int) -> [MonitorSample] {
        let start = now - Double(min(5, max(1, minutes)) * 60)
        return series[metric, default: []].filter { $0.time >= start && $0.time <= now }
    }
}
