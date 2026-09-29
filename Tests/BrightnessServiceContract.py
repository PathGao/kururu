#!/usr/bin/env python3
"""Compile production request/completion and DDC probing against deterministic IO fixtures."""
from pathlib import Path
import sys
s = Path(sys.argv[1] if len(sys.argv) > 1 else "Sources/Vorssaint/Services/Display/BrightnessService.swift").read_text()
def block(start, end):
    a = s.index(start)
    return s[a:s.index(end, a)]
model = block("struct BrightnessDisplay:", "/// Brightness sliders")
request = block("    func setBrightness(_ value:", "    // MARK: - Display power")
finish = block("    private func finishBrightnessWrite", "    // MARK: - Software dimming").replace("private func", "func")
step = block("    private func step(", "    /// Routes a handled brightness key").replace("private func", "func")
probe = block("    private enum DDCProbe", "    // MARK: - Display identity").replace("private enum", "enum").replace("private func", "func")
fixture = r'''import Foundation
import CoreFoundation
import os
import Darwin
typealias CGDirectDisplayID = UInt32
let KERN_SUCCESS: Int32 = 0
var connected = true
func CGDisplayIsOnline(_ id: UInt32) -> Int32 { connected ? 1 : 0 }
enum BrightnessBridge {
    static var payload: [UInt8] = []
    static var reads = 0
    static var writesSinceRead = 0
    static var requiresRepeatedGET = false
    static var writeI2C: ((CFTypeRef, UInt32, UInt32, UnsafeMutableRawPointer, UInt32) -> Int32)? = { _,_,_,_,_ in writesSinceRead += 1; return 0 }
    static var readI2C: ((CFTypeRef, UInt32, UInt32, UnsafeMutableRawPointer, UInt32) -> Int32)? = { _,_,_,buffer,count in
        reads += 1
        let response = requiresRepeatedGET && writesSinceRead < 2
            ? [UInt8](arrayLiteral: 0x6e,0x80,0xbe,0,0x10,0,0,100,0,80,0x90) : payload
        writesSinceRead = 0
        let bytes = buffer.assumingMemoryBound(to: UInt8.self)
        for i in 0..<Int(count) { bytes[i] = response[i] }
        return 0
    }
}
'''
fixture += model + r'''
final class Fixture {
    struct PendingWrite { let value: Double; let showOSD: Bool; let sequence: UInt64; let fingerprint: String; let method: BrightnessDisplay.Method }
    struct RememberedLevel { let value: Double; let fingerprint: String; let method: BrightnessDisplay.Method }
    struct Route { let method: BrightnessDisplay.Method; var service: CFTypeRef? = "test" as NSString }
    struct DDCReadSteps { let token: UUID; var delta: Double }
    var ddcPendingSteps: [UInt32: DDCReadSteps] = [:]
    var rebuildGeneration = 0
    static let levelTrustWindow: TimeInterval = 3
    func currentSystemBrightness(for id: UInt32, fallback: Double?) -> Double? { fallback }
    static let log = Logger(subsystem: "brightness-contract", category: "test")
    static var identity = "screenA"
    static func displayFingerprint(_ id: UInt32) -> String { identity }
    var running = true
    var displays: [BrightnessDisplay] = []
    var brightnessWriteFailures: [UInt32: String] = [:]
    let stateLock = NSLock()
    var writeSequence: UInt64 = 0
    var displayWriteVersions: [UInt32: UInt64] = [:]
    var latestBrightnessWrites: [UInt32: UInt64] = [:]
    var pendingLevels: [UInt32: PendingWrite] = [:]
    var lastApplied: [UInt32: RememberedLevel] = [:]
    var levelKnownAt: [UInt32: Date] = [:]
    var routes: [UInt32: Route] = [1: Route(method: .ddc)]
    var lifecycleGeneration = 0
    var drainScheduled = true
    let workQueue = DispatchQueue(label: "test")
    var ddcReadFailures: [UInt32: BrightnessSupport.DDCFailure] = [:]
    func drainPendingLevels() {}
    func paceDDCCommand(for id: UInt32) {}
    func recordDDCCommandEnd(for id: UInt32) {}
''' + request + finish + probe + step + "}\n"
fixture += r'''
var checks = 0
var failures = 0
func expect(_ condition: Bool, _ name: String) { checks += 1; if !condition { failures += 1; print("FAIL: \(name)") } }
let p = Fixture()
var display = BrightnessDisplay(id: 1, name: "Fixture", isBuiltIn: false, method: .ddc, isActive: true, brightness: 0.8, readable: true)
display.state.observe(0.8)
p.displays = [display]
p.setBrightness(0.7, for: 1)
expect(p.displays[0].requestedBrightness == 0.7 && p.displays[0].observedBrightness == 0.8, "actual request keeps observed80 separate from requested70")
expect(!p.displays[0].hasKnownBrightness && p.lastApplied.isEmpty, "request is never persisted as confirmed")
p.finishBrightnessWrite(id: 1, sequence: 1, generation: 0, fingerprint: "screenA", method: .ddc, succeeded: true, observed: nil, failure: .checksum)
expect(p.displays[0].status == .sentUnconfirmed && p.lastApplied.isEmpty, "accepted write with bad readback is unconfirmed")
p.setBrightness(0.6, for: 1)
p.setBrightness(0.5, for: 1)
p.finishBrightnessWrite(id: 1, sequence: 2, generation: 0, fingerprint: "screenA", method: .ddc, succeeded: true, observed: 0.6, failure: nil)
expect(p.displays[0].requestedBrightness == 0.5 && p.latestBrightnessWrites[1] == 3, "late write completion cannot overwrite latest target or clear its owner")
p.finishBrightnessWrite(id: 1, sequence: 3, generation: 0, fingerprint: "screenA", method: .ddc, succeeded: false, observed: nil, failure: .writeFailed)
expect(p.displays[0].status == .failed && p.displays[0].observedBrightness == 0.8, "write failure retains last observation")
p.setBrightness(0.4, for: 1)
p.lifecycleGeneration = 1
p.finishBrightnessWrite(id: 1, sequence: 4, generation: 0, fingerprint: "screenA", method: .ddc, succeeded: true, observed: 0.4, failure: nil)
expect(p.displays[0].status == .pending, "completion from stopped lifecycle is discarded")
p.finishBrightnessWrite(id: 1, sequence: 4, generation: 1, fingerprint: "screenB", method: .ddc, succeeded: true, observed: 0.4, failure: nil)
expect(p.displays[0].status == .pending, "reused ID cannot consume previous display completion")
p.setBrightness(0.4, for: 1)
p.finishBrightnessWrite(id: 1, sequence: 5, generation: 1, fingerprint: "screenA", method: .ddc, succeeded: true, observed: 0.4, failure: nil)
expect(p.displays[0].status == .confirmed && p.lastApplied[1]?.value == 0.4, "valid current write readback is committed")
p.setBrightness(0.3, for: 1)
p.routes[1] = Fixture.Route(method: .software)
p.finishBrightnessWrite(id: 1, sequence: 6, generation: 1, fingerprint: "screenA", method: .ddc, succeeded: true, observed: 0.3, failure: nil)
expect(p.lastApplied[1]?.value == 0.4 && p.lastApplied[1]?.method == .ddc, "route switch cannot relabel completed DDC reading as software factor")
expect(p.displays[0].status == .pending, "route switch rejects stale hardware completion publication")
BrightnessBridge.payload = [0x6e,0x80,0xbe,0,0x10,0,0,100,0,80,0x90]
let failed = p.ddcProbeLuminance(for: 1, service: "test" as NSString, classifyingChannel: true)
if case .writeOnly = failed {} else { expect(false, "invalid frame never yields luminance") }
expect(p.ddcReadFailures[1] == .nullReply, "NULL response is retained without consuming stale tail")
expect(BrightnessBridge.reads == BrightnessSupport.ddcProbeAttempts(), "read retry count is bounded")
var valid: [UInt8] = [0x6e,0x88,2,0,0x10,0,0,100,0,80]
valid.append(valid.reduce(UInt8(0x50), ^))
BrightnessBridge.payload = valid + [1]
BrightnessBridge.requiresRepeatedGET = true
for discovery in [true, false] {
    BrightnessBridge.writesSinceRead = 0
    let result = p.ddcProbeLuminance(for: 1, service: "test" as NSString, classifyingChannel: discovery)
    if case .replied(80,100) = result {
        expect(true, "repeated GET recovers real80 for discovery=\(discovery)")
    } else { expect(false, "repeated GET recovers real80 for discovery=\(discovery)") }
}
BrightnessBridge.requiresRepeatedGET = false
BrightnessBridge.payload = valid
let recovered = p.ddcProbeLuminance(for: 1, service: "test" as NSString, classifyingChannel: true)
if case .replied(80,100) = recovered {} else { expect(false, "valid later reply recovers80") }
expect(p.ddcReadFailures[1] == nil, "successful read clears stale failure")
let reused = Fixture(); reused.displays = [display]
reused.setBrightness(0.7, for: 1)
Fixture.identity = "screenB"
reused.finishBrightnessWrite(id: 1, sequence: 1, generation: 0, fingerprint: "screenA", method: .ddc, succeeded: true, observed: 0.7, failure: nil)
expect(reused.latestBrightnessWrites.isEmpty, "identity-mismatched completion clears its pending owner so visible refresh resumes")
expect(reused.pendingLevels.isEmpty && reused.lastApplied.isEmpty, "retired owner cannot leave a queued write or publish into replacement display")
Fixture.identity = "screenA"
let readCount = BrightnessBridge.reads
BrightnessBridge.writeI2C = { _,_,_,_,_ in -1 }
let dead = p.ddcProbeLuminance(for: 1, service: "test" as NSString)
if case .dead = dead {} else { expect(false, "rejected GET cannot certify cached valid reply") }
expect(BrightnessBridge.reads == readCount && p.ddcReadFailures[1] == .transport, "rejected GET never consumes stale reply buffer")
BrightnessBridge.writeI2C = { _,_,_,_,_ in 0 }
let unknown = Fixture()
unknown.displays = [BrightnessDisplay(id: 1, name: "Unknown", isBuiltIn: false, method: .ddc, isActive: true, brightness: 0, readable: false, hasKnownBrightness: false)]
BrightnessBridge.payload = [0x6e,0x80,0xbe,0,0x10,0,0,100,0,80,0x90]
func drain(_ fixture: Fixture) {
    fixture.workQueue.sync {}
    RunLoop.current.run(until: Date().addingTimeInterval(0.02))
}
unknown.step(1, method: .ddc, delta: 0.05, showOSD: false)
drain(unknown)
expect(unknown.displays[0].requestedBrightness == nil && unknown.ddcPendingSteps.isEmpty, "unknown failed read cannot step from invented50")
BrightnessBridge.payload = valid
unknown.step(1, method: .ddc, delta: 0.05, showOSD: false)
drain(unknown)
expect(abs((unknown.displays[0].requestedBrightness ?? 0) - 0.85) < 0.001, "later valid80 read recovers and steps85")
let staleRead = Fixture(); staleRead.displays = [display]
staleRead.step(1, method: .ddc, delta: 0.05, showOSD: false)
staleRead.setBrightness(0.7, for: 1)
drain(staleRead)
expect(staleRead.displays[0].requestedBrightness == 0.7, "late step read cannot replace newer slider70")
let stoppedRead = Fixture(); stoppedRead.displays = [display]
stoppedRead.step(1, method: .ddc, delta: 0.05, showOSD: false)
stoppedRead.running = false
drain(stoppedRead)
expect(stoppedRead.displays[0].requestedBrightness == nil, "step read cannot commit after stop")
print("Brightness service contract: \(checks) checks, \(failures) failures")
exit(failures == 0 ? 0 : 1)
'''
out = Path(sys.argv[2] if len(sys.argv) > 2 else ".build/backend-refactor/brightness-contract/main.swift")
out.parent.mkdir(parents=True, exist_ok=True)
out.write_text(fixture)
