// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import AppKit

if CommandLine.arguments.contains("--selftest") {
    SelfTest.runAndExit()
}

SuperKeyMappingGuard.runIfRequestedAndExit()
Defaults.register()
VisualReviewStartup.prepare()
MouseAccelerationGuard.runIfRequestedAndExit()
MouseAccelerationService.recoverPendingAtLaunch()

if CommandLine.arguments.contains("--sensors") {
    SensorDump.runAndExit()
}
if CommandLine.arguments.contains("--uninstall") {
    Uninstaller.runAndExit()
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
