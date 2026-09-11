// SPDX-License-Identifier: GPL-3.0-or-later
import SwiftUI

struct PanelEntrySettings: View {
    let title: String
    let section: PanelSectionID
    @AppStorage private var shown: Bool
    @AppStorage private var sectionShown: Bool
    @ObservedObject private var l10n = L10n.shared

    init(title: String, key: String, section: PanelSectionID = .utilities) {
        self.title = title
        self.section = section
        _shown = AppStorage(wrappedValue: true, key)
        _sectionShown = AppStorage(wrappedValue: section.shownByDefault, section.visibilityKey)
    }

    var body: some View {
        let text = UXEntryStrings(l10n.language)
        Toggle(title, isOn: $shown)
        if shown && !sectionShown {
            VStack(alignment: .leading, spacing: 8) {
                Text(text.hiddenGroup(section.title(l10n.s)))
                    .font(.callout).foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                Button(text.showGroup) { sectionShown = true }
            }
        }
    }
}

struct MonitorEntrySettings: View {
    @ObservedObject private var l10n = L10n.shared
    @ObservedObject private var features = FeatureRuntime.shared
    @State private var panelUnavailable = false
    @State private var noDisplaySelected = false

    var body: some View {
        let text = UXEntryStrings(l10n.language)
        SettingsSection(text.displayLocations) {
            SettingsExplanation(text.monitorLocation)
            Button(text.openPanel) { panelUnavailable = appDelegate()?.openMonitorPanel() != true }
                .buttonStyle(.borderedProminent)
            if panelUnavailable {
                Text(text.panelUnavailable)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if noDisplaySelected {
                Text(text.noDisplaySelected)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            SettingsExplanation(text.visibilityNote)
        }
        .onAppear(perform: refreshDisplayState)
        .onReceive(NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)) { _ in
            refreshDisplayState()
        }
        .onChange(of: features.revision) { _, _ in refreshDisplayState() }
        SettingsSection(l10n.s.monitorMenuBarSection) {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 200), alignment: .leading)],
                      alignment: .leading, spacing: 12) {
                ForEach(MenuBarMetricOrderEditor.availableOrder(MenuBarMetric.order(in: .standard))) { metric in
                    MenuBarMetricPickerRow(metric: metric)
                }
            }
            Button(text.iconLayout) { SettingsRouter.shared.request(FeatureSettingsDestination(.menuBarIcon)) }
        }
        SettingsSection(l10n.s.monitorPanelSection) {
            MonitorPanelConfig(includeMixer: false, includeUtilities: false)
            Button(text.panelLayout) { SettingsRouter.shared.request(FeatureSettingsDestination(.menuBarPanel, sectionAnchor: .panelConfiguration)) }
        }
    }

    private func refreshDisplayState() {
        let sections: [PanelSectionID] = [.system, .network, .disk, .power, .fanControl]
        noDisplaySelected = MenuBarMetric.enabled(in: .standard).isEmpty
            && !sections.contains { $0.isAvailable && PanelLayout.isShown($0) }
    }
}
