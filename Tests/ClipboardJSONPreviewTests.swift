// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import Foundation
enum ClipboardJSONPreviewTests {
 static func run(_ check: (Bool, String) -> Void) {
 let input="{\"big\":9007199254740993,\"decimal\":0.12345678901234567890123456789,\"exp\":1e+100,\"big\":2}"
 let formatted=JSONPreviewFormatter.format(input)
 check(formatted != nil,"object recognized")
 for token in ["9007199254740993","0.12345678901234567890123456789","1e+100"] { check(formatted?.contains(token)==true,"exact number \(token)") }
 check(formatted?.components(separatedBy:"\"big\"").count==3,"duplicate key retained")
 check(formatted?.range(of:"\"big\"")?.lowerBound ?? "".startIndex < formatted?.range(of:"\"decimal\"")?.lowerBound ?? "".startIndex,"key order")
 let escaped=#"{"s":"quote \" slash \\ unicode \uD83D\uDE00","real":"中文"}"#
 check(JSONPreviewFormatter.format(escaped)?.contains(#""quote \" slash \\ unicode \uD83D\uDE00""#)==true,"string lexeme unchanged")
 check(JSONPreviewFormatter.format("{}") == "{}","empty object")
 check(JSONPreviewFormatter.format("[ ]") == "[]","empty array")
 check(JSONPreviewFormatter.format(" { \"a\": [1, {\"b\":true}], \"n\":null } ") != nil,"nested")
 for s in ["hello","123","null","\"hello\"","{]","[1,]","{\"a\":01}","{\"a\":1}x","[NaN]"] {check(JSONPreviewFormatter.format(s)==nil,"reject \(s)")}
 check(JSONPreviewFormatter.format(String(repeating:"[",count:65)+"0"+String(repeating:"]",count:65))==nil,"depth limit")
 check(JSONPreviewFormatter.format("[\""+String(repeating:"x",count:262144)+"\"]")==nil,"input limit")
 check(JSONPreviewFormatter.format("[1,2]",outputLimit:5)==nil,"output limit")
 check(JSONPreviewFormatter.format("[1e999999]") != nil,"valid huge exponent lexeme")

 check(JSONPreviewFormatter.format(String(repeating:"[",count:64)+"0"+String(repeating:"]",count:64)) != nil,"depth 64 accepted")
 for bad in ["[+1]","[-]","[1.]","[1e]","[1e+]","[.1]","{a:1}","{\"a\" 1}","[true false]","{\"a\":1,}",#"["\q"]"#,#"["\u12XZ"]"#,"[\"line\nfeed\"]"] {
  check(JSONPreviewFormatter.format(bad)==nil,"invalid grammar \(bad)")
 }
 let whitespace=" \r\n[\t-0, 1.00,1E-03,true,false,null,[],{}]\t"
 let once=JSONPreviewFormatter.format(whitespace)
 check(once != nil && JSONPreviewFormatter.format(once!)==once,"idempotent formatting")
 check(once?.contains("-0")==true && once?.contains("1.00")==true && once?.contains("1E-03")==true,"number spelling retained")
 check(JSONPreviewFormatter.format("[0]",outputLimit:7)=="[\n  0\n]","exact output limit")
 check(JSONPreviewFormatter.format("[0]",outputLimit:6)==nil,"output one byte short")

 }
}
