// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

enum SettingsNavigationTests {
    static func run(_ expect: (Bool, String) -> Void) {
        expect(!SettingsPage.allCases.contains { String(describing: $0) == "support" },
               "retired Support is not an enumerable navigation or search destination")
        expect(SettingsPage.allCases.contains(.about), "About remains reachable after Support removal")
        let unavailable: (AppFeature) -> Bool = { _ in false }
        for unit in FeatureUnit.allCases {
            guard let page = unit.page else { continue }
            expect(FeatureVisibilitySupport.configurationUnit(for: page) == unit,
                   "configuration page resolves its owning module: \(unit)")
            expect(FeatureVisibilitySupport.isSidebarPageVisible(page, selectedPage: page,
                                                                  isAvailable: unavailable),
                   "viewing an inactive module keeps its configuration route visible: \(unit)")
            let visibleModules = FeatureUnit.allCases.filter { other in
                guard let otherPage = other.page else { return false }
                return FeatureVisibilitySupport.isSidebarPageVisible(otherPage, selectedPage: page,
                                                                       isAvailable: unavailable)
            }
            expect(visibleModules == [unit], "viewing \(unit) must not expose every inactive module: \(visibleModules)")
            expect(!FeatureVisibilitySupport.isPageVisible(page, isAvailable: unavailable),
                   "inspection does not mark the module available: \(unit)")
        }
        expect(FeatureVisibilitySupport.configurationUnit(for: .advanced) == nil,
               "ordinary settings never acquire a module gate")
        expect(FeatureVisibilitySupport.isSidebarPageVisible(.advanced, selectedPage: .clipboard,
                                                             isAvailable: unavailable),
               "ordinary settings remain visible while inspecting an inactive module")
        expect(FeatureVisibilitySupport.isSidebarPageVisible(.clipboard, selectedPage: .scratchpad,
                                                             isAvailable: { $0.unit == .clipboard }),
               "an active module stays in the sidebar when another module is inspected")
        expect(AppFeature.urlCleaner.settingsDestination
                == FeatureSettingsDestination(.urlCleaner, sectionAnchor: .urlCleaner),
               "URL Cleaner routes to its own settings page")
        expect(FeatureVisibilitySupport.features(for: .clipboard) == [.clipboardHistory, .pastePlain],
               "URL Cleaner no longer keeps the Clipboard page alive")
        expect(FeatureVisibilitySupport.features(for: .urlCleaner) == [.urlCleaner],
               "URL Cleaner availability gates its direct page")
        expect(FeatureVisibilitySupport.configurationUnit(for: .urlCleaner) == .clipboard,
               "URL Cleaner uses the clipboard module's saved-configuration boundary")

        expect(ClipboardViewerEmptyState.resolve(query: "", captureEnabled: false) == .capturePaused,
               "an empty viewer explains that capture is paused")
        expect(ClipboardViewerEmptyState.resolve(query: "", captureEnabled: true) == .waitingForCopy,
               "an enabled empty viewer explains how the first item appears")
        expect(ClipboardViewerEmptyState.resolve(query: "missing", captureEnabled: false) == .noMatches,
               "a filtered empty viewer reports search state independently of capture")
    }
}
