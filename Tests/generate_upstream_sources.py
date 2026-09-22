#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Vorssaint

"""Compile selected production methods against test doubles, without an app.

Bodies are read verbatim on every build, never copied into a maintained fixture.
The narrow declaration/indentation contract fails closed if a method moves or
changes shape; the Swift compiler then checks the generated source normally.
"""
from pathlib import Path
import json
import re

ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "build/generated-tests"


def declaration(path, prefix):
    lines = (ROOT / path).read_text().splitlines(keepends=True)
    starts = [i for i, line in enumerate(lines) if line.startswith(prefix)]
    if len(starts) != 1:
        raise ValueError(f"Expected one declaration {prefix!r} in {path}")
    start = starts[0]
    indent = prefix[:len(prefix) - len(prefix.lstrip())]
    end = next(i for i in range(start + 1, len(lines)) if lines[i].rstrip() == indent + "}")
    body = "".join(lines[start:end + 1])
    return f'#sourceLocation(file: {json.dumps(path)}, line: {start + 1})\n{body}\n#sourceLocation()\n'


WRITTEN = set()


def write(name, text):
    WRITTEN.add(name)
    path = OUTPUT / name
    if not path.exists() or path.read_text() != text:
        path.write_text(text)


def main():
    OUTPUT.mkdir(parents=True, exist_ok=True)
    cleaner = "Sources/Vorssaint/Services/Cleaner/JunkCleaner.swift"
    write("CleanerEligibilityBodies.swift", "import Foundation\nextension CleanerEligibilityTests {\n"
          + "".join(declaration(cleaner, "    private static func " + name)
                    .replace("private static func", "static func", 1)
                    .replace("fm.homeDirectoryForCurrentUser", "fixtureRoot!")
                    for name in ["appendLeftovers(", "scanCaches(", "scanLogs(",
                                 "directorySize(", "fileSize(", "sorted("])
          + declaration(cleaner, "    private static func leftoverOwner(")
          + declaration(cleaner, "    private static func containerOwner(")
          + declaration(cleaner, "    private static func mayRemove(")
          + "static func owner(_ url: URL, metadata: Bool = false) -> String? {\n"
          + "leftoverOwner(entry: url.lastPathComponent, url: url, usesContainerMetadata: metadata)\n}\n"
          + "static func canRemove(_ item: Item, installed: Set<String> = []) -> Bool {\n"
          + "mayRemove(item, installed: installed)\n}\n}\n")

    switcher = "Sources/Vorssaint/UI/Switcher/SwitcherView.swift"
    switcher_service = "Sources/Vorssaint/Services/Switcher/AppSwitcher.swift"
    write("SwitcherScroll.swift", "import AppKit\nimport SwiftUI\n"
          + "extension SwitcherScrollContract {\nstruct Strip: View {\n"
          + "@ObservedObject var switcher: Model\n"
          + "var iconRowContentWidth: CGFloat { switcher.iconRowLayout.contentWidth(simpleMode: true, windowRow: false) }\n"
          + "var body: some View {\nif selectedWindow != nil {\nlet appWindows = selectedAppWindows\n"
          + "if switcher.simple {\nGroup {\n"
          + declaration(switcher, "                ScrollViewReader { proxy in")
          + "}\n.frame(width: iconRowContentWidth - 2 * SwitcherIconRowLayout.simpleTitlePanelPadding, "
          + "height: 25 * SwitcherIconRowLayout.scale)\n} else {\n"
          + declaration(switcher, "                    ScrollViewReader { proxy in")
          + "}\n}\n}\n"
          + declaration(switcher, "    private var selectedWindow:")
          + declaration(switcher, "    private var selectedAppWindows:")
          + declaration(switcher, "    private func revealSelection(")
          + "}\n}\nextension SwitcherScrollContract.Model {\n"
          + "func search(_ query: String) { searchQuery = query; applySearchFilter(preferredItemID: selectedItemID) }\n"
          + declaration(switcher_service, "    private var selectedItemID:")
          + declaration(switcher_service, "    private func applySearchFilter(")
          + "}\n")
    selection = "Sources/Vorssaint/Services/QuickTools/ScreenshotSelectionController.swift"
    refresh_methods = [
        "    private func screenCaptureToolDidChange()",
        "    private func adoptCapturePolicy(",
        "    private func applySource(",
        "    private func loadLiveLoupeImages()",
        "    private func markCapturePending()",
        "    private func captureFullDisplayUnderMouse()",
        "    private func repeatLastRegion()",
        "    fileprivate func confirmWindow(",
        "    fileprivate func confirmRegion(",
        "    fileprivate func confirmColor(",
    ]
    write("ScreenshotSelectionRefresh.swift", "import Foundation\nimport AppKit\n"
          + "extension ScreenshotSelectionRefreshContract.Chooser {\n"
          + declaration(selection, "    fileprivate var acceptsCaptureInput:").replace("fileprivate var", "var", 1)
          + "".join(declaration(selection, prefix).replace("fileprivate func", "func", 1)
                    .replace("private func", "func", 1).replace("UserDefaults.standard", "ReviewDefaults.current")
                    for prefix in refresh_methods)
          + "}\n")
    activator = "Sources/Vorssaint/Services/Switcher/WindowActivator.swift"
    write("SwitcherActivationBodies.swift", "import AppKit\nimport ApplicationServices\n"
          + "extension SwitcherActivationTests.Activator {\n"
          + "".join(declaration(activator, prefix).replace("private static", "static", 1)
                    for prefix in ["    private static func activateApp(",
                                   "    private static func activateAppCooperatively(",
                                   "    private static func activateSource("])
          + "}\nextension SwitcherActivationTests.Bridge {\n"
          + declaration("Sources/Vorssaint/Services/Switcher/SpaceWindowBridge.swift",
                        "    static func frontWindow(") + "}\n")
    brightness = "Sources/Vorssaint/Services/Display/BrightnessService.swift"
    write("DisplayRestoration.swift", "import CoreGraphics\nimport Foundation\n"
          + "extension DisplayRestorationTests {\nfinal class BrightnessService: Fixture {\n"
          + declaration(brightness, "    enum DisplayControlFailure:")
          + "".join(declaration(brightness, prefix).replace("private ", "", 1) for prefix in [
              "    private static func configureDisplay(", "    private func restoreDisplay(",
              "    private func syncLidObserver()", "    private func restoreDeferredDisplays()",
              "    private func restoreManagedDisplays()", "    func restoreDisplaysLeftOff()",
              "    private func commitDisplayToggle(", "    private func finishDisplayToggle(",
              "    private func restoreManagedDisplayIfHeadless("])
          + "}\n}\n")
    shelf = "Sources/Vorssaint/Services/Shelf/ShelfService.swift"
    write("ShelfDropRouting.swift", "import AppKit\nextension ShelfDropRoutingContract {\n"
          + "final class ShelfService: ShelfState {\nstatic var shared = ShelfService()\n"
          + declaration(shelf, "    func acceptDrop(pasteboard:")
          + declaration(shelf, "    func accept(draggingInfo:")
          + "}\n}\n")

if __name__ == "__main__":
    main()
    # build.sh compiles every file here, so one no longer generated must not linger.
    for stale in OUTPUT.glob("*.swift"):
        if stale.name not in WRITTEN:
            stale.unlink()
