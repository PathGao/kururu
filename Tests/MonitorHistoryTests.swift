import Foundation

enum MonitorHistoryTests {
 static func run(_ expect: (Bool, String) -> Void) {
  expect(MonitorHistory.percentageCeiling([]) == 10, "empty load chart has a useful minimum scale")
  expect(MonitorHistory.percentageCeiling([0.03, 0.06]) == 10, "low CPU load does not reserve 100 percent height")
  expect(MonitorHistory.percentageCeiling([0.16]) == 20, "load axis rounds up to a stable step")
  expect(MonitorHistory.percentageCeiling([0.98]) == 100, "near-full load retains a 100 percent ceiling")
  expect(MonitorHistory.percentageCeiling([.nan, .infinity, 0.12]) == 20, "invalid readings do not corrupt the axis")
  expect(MonitorMetric.cpu.graphPreferenceKey == MonitorMetric.cpuTemperature.graphPreferenceKey, "CPU details follow the CPU chart setting")
  expect(MonitorMetric.cpu.graphPreferenceKey != MonitorMetric.gpu.graphPreferenceKey, "CPU and GPU chart visibility are independent")
  var history = MonitorHistory()
  for t in 0...400 { history.record(.cpu, value: 0.5, at: Double(t), interval: 1) }
  expect(history.series[.cpu]?.count == 301, "history retains five minutes, not 120 samples")
  expect(history.series[.cpu]?.first?.time == 100, "history evicts by timestamp")
  history.record(.cpu, value: 0.8, at: 405, interval: 5)
  let points = history.points(.cpu, endingAt: 405, minutes: 1)
  expect(points.first?.time == 345 && points.last?.time == 405, "viewport keeps real timestamps after cadence change")
  expect(points.first?.segment == points.last?.segment, "cadence change alone does not create a gap")
  history.record(.cpu, value: nil, at: 410, interval: 5)
  history.record(.cpu, value: 0.6, at: 415, interval: 5)
  expect(history.series[.cpu]?.last?.segment != points.last?.segment, "missing reading breaks the line")
  let beforeSleep = history.series[.cpu]?.last?.segment
  history.record(.cpu, value: 0.3, at: 450, interval: 5)
  expect(history.series[.cpu]?.last?.segment != beforeSleep, "sleep gap breaks the line")
  history.record(.gpu, value: .nan, at: 451, interval: 1)
  expect(history.points(.gpu, endingAt: 451, minutes: 5).isEmpty, "nonfinite readings cannot reach charts")
  expect(history.points(.cpu, endingAt: 900, minutes: 5).isEmpty, "stopped metrics cannot show expired history")
  history.record(.cpu, value: 0.2, at: 40, interval: 1)
  expect(history.series[.cpu]?.count == 1, "backward wall-clock correction resets that series")
  var paused = MonitorHistory()
  paused.record(.cpu, value: 0.2, at: 0, interval: 5)
  paused.markGap()
  paused.record(.cpu, value: 0.3, at: 2, interval: 5)
  expect(paused.series[.cpu]?.first?.segment != paused.series[.cpu]?.last?.segment,
         "explicit pauses break lines even within one sample interval")
  var rapid = MonitorHistory()
  for t in 0...1000 { rapid.record(.memory, value: 0.2, at: Double(t)/100, interval: 1) }
  expect((rapid.series[.memory]?.count ?? 0) <= 601, "event-driven refreshes cannot grow history without bound")
 }
}
