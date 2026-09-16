import CoreGraphics
import Foundation

// Read-only snapshot. Pass the app PID to avoid collecting other apps' data.
guard CommandLine.arguments.count == 2, let pid = Int32(CommandLine.arguments[1]) else {
    fputs("Usage: InspectEventTaps <pid>\n", stderr)
    exit(2)
}
var count: UInt32 = 0
guard CGGetEventTapList(0, nil, &count) == .success else { exit(1) }
var taps = [CGEventTapInformation](repeating: CGEventTapInformation(), count: Int(count) + 32)
let capacity = UInt32(taps.count)
guard CGGetEventTapList(capacity, &taps, &count) == .success else { exit(1) }
let owned = taps.prefix(min(Int(count), taps.count)).filter { $0.tappingProcess == pid }
print("PID \(pid): \(owned.count) registered taps, \(owned.filter(\.enabled).count) enabled")
for tap in owned {
    print("tap=\(tap.eventTapID) enabled=\(tap.enabled) point=\(tap.tapPoint.rawValue) mask=\(tap.eventsOfInterest) average_us=\(tap.avgUsecLatency) max_us=\(tap.maxUsecLatency)")
}
