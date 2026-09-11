#!/usr/bin/env python3
"""Generate an offline Swift regression from actual brightness lifecycle blocks.
Run from repo root:
  python3 Tests/BrightnessReadbackRegression.py
  swiftc Sources/Vorssaint/Services/Display/BrightnessSupport.swift .build/brightness-readback/regression/main.swift -o .build/brightness-readback/regression/test
  .build/brightness-readback/regression/test
Optional args: alternate service source, output subdirectory (for mutation checks).
Only external IOKit/display/defaults dependencies are fixture substitutes; the
stop, probe selection, result handling and remembered-value commit blocks run
from the selected production source. The complete step method is also compiled
unchanged, including its asynchronous closure scope; fixture callback parameters
must not hide missing locals in that method. This does not test hardware timing/UI.
"""
from pathlib import Path
import sys
base=Path(sys.argv[1]) if len(sys.argv)>1 else Path("Sources/Vorssaint/Services/Display/BrightnessService.swift")
suffix=sys.argv[2] if len(sys.argv)>2 else "regression"
s=base.read_text()
def block(a,b):return s[s.index(a):s.index(b,s.index(a))]
stop=block("        stateLock.lock()\n        rebuildGeneration += 1", "        ddcPendingSteps = [:]")
read=block("                let rememberedWriteOnly =" if "let rememberedWriteOnly" in s else "                // A timeout describes", "                switch probe {")
read="\n".join(line for line in read.splitlines() if "Self.log.log(" not in line)
switch=block("                switch probe {", "\n            }\n        }\n\n        // Software route")
callbackStart = "                guard self.ddcPendingSteps[displayID]?.token" if "guard self.ddcPendingSteps[displayID]?.token" in s else "                let queued = self.ddcPendingSteps.removeValue"
readCompletion = block(callbackStart, "                var current = cached")
stepGate=block("        let fresh = BrightnessSupport.trustsRememberedLevel", "        // A press that lands")
completeStep=block("    private func step(", "    private func commitStep(")
finish=block("    private func finishBrightnessWrite", "    // MARK: - Software dimming")
remember=block("            for display in resolved where", "\n        }\n        stateLock.unlock()\n        guard !stale else")
# Same-member schema shim allows the old implementation to compile against the new unknown-value assertions.
head="""import Foundation
import os
typealias CGDirectDisplayID = UInt32
struct BrightnessDisplay {
 enum Method { case ddc, system, software }
 let id: UInt32; let name: String; let isBuiltIn: Bool
 var method: Method?; var isActive: Bool; var brightness: Double; var readable: Bool
 var hasKnownBrightness = true
}
final class Probe {
 struct RememberedLevel {var value: Double; var fingerprint: String}
 struct Route {var method: BrightnessDisplay.Method;var service: Int?;var maximum: UInt16; var ddcReadable = false;var ddcPathKey: String?}
 enum DDCProbe {case replied(UInt16,UInt16),writeOnly,dead}
 let stateLock=NSLock(); var lastApplied:[UInt32:RememberedLevel]=[:]
 var levelKnownAt:[UInt32:Date]=[:]; var routes:[UInt32:Route]=[:]
 var pendingLevels:[UInt32:Double]=[:];var writeSequence=0;var latestBrightnessWrites:[UInt32:UInt64]=[:]
 var systemWritesInFlight:Set<UInt32>=[];var knownTopology:Set<UInt32>=[];var knownActiveTopology:Set<UInt32>=[]
 struct DDCReadSteps: ExpressibleByIntegerLiteral {let token:UUID;var delta:Double;init(token:UUID,delta:Double){self.token=token;self.delta=delta};init(integerLiteral:Int){token=UUID();delta=Double(integerLiteral)}}
 var ddcPendingSteps:[UInt32:DDCReadSteps]=[:];var acceptedReads=0
 var running=true;var brightnessWriteFailures:[UInt32:String]=[:];var displays:[BrightnessDisplay]=[]
 static let levelTrustWindow:TimeInterval=3
 static let log=Logger(subsystem:"brightness-offline-test",category:"scope")
 let workQueue=DispatchQueue(label:"brightness-offline-test")
 func currentSystemBrightness(for id:UInt32,fallback:Double?)->Double?{fallback}
 var attemptedRead=false; var stepped:Double?
 func commitStep(from:Double,delta:Double,to:UInt32,method:BrightnessDisplay.Method,showOSD:Bool){stepped=from+delta}
 var rebuildGeneration=0;var rebuildingTopology:Int?;var fingerprint="monitor-A"
 var stored:Set<String>=[];var nextProbe:DDCProbe = .writeOnly;var readCalls=0
 func rememberedLevel(for id:UInt32)->Double? { guard let v=lastApplied[id],v.fingerprint==fingerprint else{return nil};return v.value }
 func writeOnlyDDCPaths()->Set<String>{stored}
 func rememberWriteOnlyDDCPath(_ p:String?){if let p{stored.insert(p)}}
 func forgetWriteOnlyDDCPath(_ p:String?){if let p{stored.remove(p)}}
 func ddcProbeLuminance(for id:UInt32,service:Int,classifyingChannel:Bool=false)->DDCProbe{readCalls+=1;return nextProbe}
 static var activeFingerprint="monitor-A"
 static func displayFingerprint(_ id:UInt32)->String{activeFingerprint}
 func stop(){
"""
body=head+stop+"\n}\nfunc refresh(_ input:DDCProbe)->BrightnessDisplay {\nnextProbe=input; Self.activeFingerprint=fingerprint\nlet id:UInt32=1;let pathKey:String?=\"monitor|port\";let candidate=(index:0, unused:0); let matched=(service:1, unused:0)\nvar built=[BrightnessDisplay(id:id,name:\"Fixture\",isBuiltIn:false,method:.ddc,isActive:true,brightness:0.5,readable:false,hasKnownBrightness:false)]\nvar newRoutes:[UInt32:Route]=[:];var softwareIndices:Set<Int>=[0]\n"+read+"\n"+switch+"\nlet resolved=built\n"+remember+"\nreturn built[0]\n}\n}\n"
body=body.rsplit("}\n",1)[0]+completeStep+finish.replace("private func", "func")+"\nfunc stepGate(_ cached:Double?) { let displayID:UInt32=1;let method=BrightnessDisplay.Method.ddc; let delta=0.05;let showOSD=false;let known:Date?=nil;let route:Route?=Route(method:.ddc,service:1,maximum:100,ddcReadable:false)\n"+stepGate+"\nattemptedRead=true\n}\nfunc finishRead(token readToken:UUID, generation readGeneration:Int, sequence readWriteSequence:Int) {let displayID:UInt32=1\n"+readCompletion+"\n_ = queued;acceptedReads+=1\n}\n}\n"
body+="""
var checks=0;var failures=0
func expect(_ value:Bool,_ message:String){checks+=1;if !value{failures+=1;print("FAIL: \(message)")}}
let p=Probe()
let first=p.refresh(.replied(80,100));expect(first.brightness==0.8 && first.readable,"first real reply is 80%")
p.stop()
let missed=p.refresh(.writeOnly);expect(missed.brightness==0.8 && missed.hasKnownBrightness && !missed.readable,"stop/start timeout retains last80 but marks unreadable")
let recovered=p.refresh(.replied(90,100));expect(recovered.brightness==0.9 && recovered.readable,"later refresh retries and recovers90")
let q=Probe();q.stored=["monitor|port"]
let legacy=q.refresh(.replied(80,100));expect(legacy.brightness==0.8 && q.readCalls==1,"legacy persisted write-only cache cannot block readback")
let unknown=Probe();let noReply=unknown.refresh(.writeOnly)
expect(!noReply.hasKnownBrightness,"first unavailable read does not invent50")
expect(unknown.lastApplied.isEmpty,"unknown placeholder is never remembered as real value")
p.stop();p.fingerprint="monitor-B";let different=p.refresh(.writeOnly)
expect(!different.hasKnownBrightness,"reused display number cannot inherit another monitor brightness")
let pending=Probe();_ = pending.refresh(.replied(80,100))
pending.lastApplied[1]=Probe.RememberedLevel(value:0.3,fingerprint:"monitor-A")
pending.latestBrightnessWrites[1]=1;pending.stop()
let afterPending=pending.refresh(.writeOnly)
expect(!afterPending.hasKnownBrightness,"stop discards an unconfirmed optimistic write before failed readback")
let g=Probe();g.stepGate(nil)
expect(g.attemptedRead && g.stepped==nil,"unknown write-only route requests a fresh read before any step")
let stale=Probe();stale.stepGate(0.8)
expect(stale.attemptedRead && stale.stepped==nil,"previously unreadable route retries before stepping stale80")
let failed=Probe();failed.displays=[first];failed.latestBrightnessWrites[1]=1
failed.finishBrightnessWrite(id:1,sequence:1,generation:0,succeeded:false)
expect(!failed.displays[0].readable && !failed.displays[0].hasKnownBrightness,"failed requested value is not presented as current brightness")
let token=UUID();let later=UUID()
let readNewerWrite=Probe();readNewerWrite.ddcPendingSteps[1] = .init(token:token,delta:0.1);readNewerWrite.writeSequence=2
readNewerWrite.finishRead(token:token,generation:0,sequence:1)
expect(readNewerWrite.acceptedReads==0,"late read cannot overwrite a newer slider request")
let readStopped=Probe();readStopped.ddcPendingSteps[1] = .init(token:token,delta:0.1);readStopped.running=false
readStopped.finishRead(token:token,generation:0,sequence:0)
expect(readStopped.acceptedReads==0,"late read cannot commit after stop")
let readNewSession=Probe();readNewSession.ddcPendingSteps[1] = .init(token:later,delta:0.2);readNewSession.rebuildGeneration=1
readNewSession.finishRead(token:token,generation:0,sequence:0)
expect(readNewSession.acceptedReads==0 && readNewSession.ddcPendingSteps[1]?.token==later,"old callback leaves the new session read and queued steps intact")
let readValid=Probe();readValid.ddcPendingSteps[1] = .init(token:token,delta:0.1)
readValid.finishRead(token:token,generation:0,sequence:0)
expect(readValid.acceptedReads==1 && readValid.ddcPendingSteps.isEmpty,"current read completes exactly once and consumes its queued steps")
readValid.finishRead(token:token,generation:0,sequence:0)
expect(readValid.acceptedReads==1,"completed callback cannot commit a second time")
print("Lifecycle: \(checks) checks, \(failures) failures")
exit(failures==0 ? 0:1)
"""
Path('.build/brightness-readback/'+suffix+'/main.swift').parent.mkdir(parents=True, exist_ok=True)
Path('.build/brightness-readback/'+suffix+'/main.swift').write_text(body)
