// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import AppKit
import SwiftUI
import UniformTypeIdentifiers

/// The "Menu bar panel" settings page: which sections the panel holds, in what
/// order, and what each shows. One list does all three; options wrap in a grid
/// because Controls and Utilities alone carry more than thirty items.
struct MenuBarPanelSettings: View {
    @AppStorage("monitorHistoryMinutes") private var historyMinutes = 1
    @ObservedObject private var l10n = L10n.shared
    @ObservedObject private var features = FeatureRuntime.shared

    var body: some View {
        let history = MonitorHistoryStrings.text(l10n.language)
        SettingsForm {
            if !PanelSectionsEditor.availableOrder(PanelLayout.order).isEmpty {
                SettingsSection(l10n.s.monitorPanelSection) {
                    PanelSectionsEditor()
                }
                .settingsSectionAnchor(.panelConfiguration)
            }
            SettingsSection(history.history) {
                HStack(spacing: 6) {
                    Picker(history.range, selection: $historyMinutes) {
                        ForEach(1...5, id: \.self) { value in
                            Text("\(value) \(history.minutes)").tag(value)
                        }
                    }
                    SettingsHelpButton(title: history.range, text: history.visibilityHint)
                }
            }
        }
        .formStyle(.grouped)
    }
}

/// One row per panel section: drag the handle to reorder, check to show it,
/// expand to pick what it shows. Only the handle starts a drag, so the
/// checkboxes keep receiving clicks.
struct PanelSectionsEditor: View {
    @ObservedObject private var l10n = L10n.shared
    @ObservedObject private var features = FeatureRuntime.shared
    @State private var order: [PanelSectionID] = PanelLayout.order
    @State private var dragging: PanelSectionID?
    @State private var expanded = Set<PanelSectionID>()

    var body: some View {
        ForEach(Self.availableOrder(order)) { id in
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "line.3.horizontal")
                        .foregroundStyle(.tertiary)
                        .frame(width: 18, height: 22)
                        .contentShape(Rectangle())
                        .onDrag {
                            dragging = id
                            return NSItemProvider(object: id.rawValue as NSString)
                        }
                        .help(UXEntryStrings(l10n.language).panelOrderHint)
                    SettingsVisibilityCheckbox(title: id.title(l10n.s), key: id.visibilityKey, symbolName: id.symbolName)
                    Spacer(minLength: 0)
                    let options = PanelSectionOptions.options(for: id, l10n: l10n)
                    if !options.isEmpty {
                        SettingsCountBadge(text: "\(options.filter { UserDefaults.standard.bool(forKey: $0.key) }.count)/\(options.count)")
                        Button {
                            if expanded.contains(id) { expanded.remove(id) } else { expanded.insert(id) }
                        } label: {
                            Image(systemName: expanded.contains(id) ? "chevron.down" : "chevron.right")
                                .foregroundStyle(.secondary)
                                .frame(width: 22, height: 22)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(id.title(l10n.s))
                    }
                }
                if expanded.contains(id) {
                    PanelSectionOptionsGrid(id: id)
                        .padding(.leading, 26)
                }
            }
            .opacity(dragging == id ? 0.45 : 1)
            .onDrop(of: [UTType.text],
                    delegate: PanelOrderDropDelegate(target: id, order: $order, dragging: $dragging))
        }
        .onAppear { order = PanelLayout.order }
        .onReceive(NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)) { _ in
            order = PanelLayout.order
        }
    }

    static func availableOrder(_ order: [PanelSectionID]) -> [PanelSectionID] {
        order.filter { $0.isAvailable }
    }
}

/// Shows or hides an option's trend chart; dims while the option itself is hidden.
private struct PanelGraphToggle: View {
    let title: String
    @AppStorage private var isOn: Bool
    @AppStorage private var optionShown: Bool
    @ObservedObject private var l10n = L10n.shared

    init(title: String, key: String, optionKey: String) {
        self.title = title
        _isOn = AppStorage(wrappedValue: true, key)
        _optionShown = AppStorage(wrappedValue: true, optionKey)
    }

    var body: some View {
        let label = MonitorHistoryStrings.text(l10n.language).history
        let active = isOn && optionShown
        Button { isOn.toggle() } label: {
            Image(systemName: "chart.xyaxis.line")
                .font(.caption.weight(.medium))
                .foregroundStyle(active ? Color.accentColor : Color.secondary)
                .frame(width: 26, height: 20)
                .background(active ? Color.accentColor.opacity(0.16) : Color.secondary.opacity(0.06),
                            in: RoundedRectangle(cornerRadius: 5))
                .overlay {
                    RoundedRectangle(cornerRadius: 5)
                        .strokeBorder(active ? Color.accentColor : Color.secondary.opacity(0.3), lineWidth: 1)
                }
                .opacity(optionShown ? 1 : 0.45)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!optionShown)
        .help(label)
        .accessibilityLabel("\(title): \(label)")
        .accessibilityValue(isOn ? "1" : "0")
    }
}

struct PanelSectionOption: Identifiable {
    let title: String
    let key: String
    var graphKey: String? = nil
    var group: String? = nil
    var id: String { key }
}

enum PanelSectionOptions {
    static func options(for id: PanelSectionID, l10n: L10n) -> [PanelSectionOption] {
        let s = l10n.s
        switch id {
        case .system:
            var items: [PanelSectionOption] = []
            if AppFeature.monitorCPU.isAvailable || AppFeature.monitorGPU.isAvailable {
                items.append(.init(title: s.temperatures, key: DefaultsKey.monitorSysTemps))
            }
            if AppFeature.monitorCPU.isAvailable {
                items.append(.init(title: s.cpuLabel, key: DefaultsKey.monitorSysCPU, graphKey: DefaultsKey.monitorGraphCPU))
            }
            if AppFeature.monitorGPU.isAvailable {
                items.append(.init(title: s.gpuLabel, key: DefaultsKey.monitorSysGPU, graphKey: DefaultsKey.monitorGraphGPU))
            }
            if AppFeature.monitorMemory.isAvailable {
                items.append(.init(title: s.memorySection, key: DefaultsKey.monitorSysMemory, graphKey: DefaultsKey.monitorGraphMemory))
            }
            items.append(.init(title: s.monitorItemUptime, key: DefaultsKey.monitorSysUptime))
            return items
        case .network:
            return [.init(title: s.monitorItemNetSpeed, key: DefaultsKey.monitorNetSpeed, graphKey: DefaultsKey.monitorGraphNetwork),
                    .init(title: s.networkApps, key: DefaultsKey.monitorNetApps),
                    .init(title: s.monitorItemNetTotals, key: DefaultsKey.monitorNetTotals),
                    .init(title: s.monitorItemNetTest, key: DefaultsKey.monitorNetTest)]
        case .disk:
            return [.init(title: s.monitorItemDiskUsage, key: DefaultsKey.monitorDiskUsage),
                    .init(title: s.monitorItemDiskActivity, key: DefaultsKey.monitorDiskActivity, graphKey: DefaultsKey.monitorGraphDisk),
                    .init(title: s.monitorItemDiskSMART, key: DefaultsKey.monitorDiskSMART),
                    .init(title: s.monitorItemDiskProtection, key: DefaultsKey.monitorDiskProtection),
                    .init(title: s.monitorItemDiskTools, key: DefaultsKey.monitorDiskTools)]
        case .power:
            var items: [PanelSectionOption] = [
                .init(title: s.powerSystem, key: DefaultsKey.monitorPwrSystem, graphKey: DefaultsKey.monitorGraphPower),
                .init(title: s.powerAdapter, key: DefaultsKey.monitorPwrAdapter)]
            if PowerSampler.hasInternalBattery {
                items += [.init(title: s.batteryCharge, key: DefaultsKey.monitorSysBattery, graphKey: DefaultsKey.monitorGraphBattery),
                          .init(title: s.powerBattery, key: DefaultsKey.monitorPwrBattery),
                          .init(title: FeatureStrings.batteryTime(l10n.language).title, key: DefaultsKey.monitorPwrTimeRemaining),
                          .init(title: s.monitorShowBatteryTemperature, key: DefaultsKey.monitorPwrTemperature),
                          .init(title: s.powerHealth, key: DefaultsKey.monitorPwrHealth)]
            }
            return items
        case .fanControl:
            return [.init(title: MonitorHistoryStrings.text(l10n.language).history, key: "monitorGraphFan")]
        case .controls:
            let dockClick = FeatureStrings.dockClick(l10n.language)
            return ControlPanelItem.allCases.filter { $0.feature.isAvailable }.map { item in
                let title: String
                switch item {
                case .dockClick: title = dockClick.minimize
                case .dockClickHide: title = dockClick.hide
                case .dockClickCycle: title = dockClick.cycleWindows
                default: title = item.feature.name(s, language: l10n.language)
                }
                let group: String
                switch ControlCategory.category(for: item) {
                case .windows: group = s.panelCategoryWindows
                case .inputDevices: group = s.panelCategoryInput
                case .files: group = s.panelCategoryFiles
                }
                return .init(title: title, key: item.visibilityKey, group: group)
            }.sorted { lhs, rhs in
                groupRank(lhs.group, s) < groupRank(rhs.group, s)
            }
        case .utilities:
            return UtilityPanelItem.allCases.filter { $0.feature.isAvailable }.map {
                .init(title: $0.feature.name(s, language: l10n.language), key: $0.visibilityKey)
            }
        case .keepAwake, .brightness, .mixer:
            return []
        }
    }

    private static func groupRank(_ group: String?, _ s: Strings) -> Int {
        [s.panelCategoryWindows, s.panelCategoryInput, s.panelCategoryFiles].firstIndex(of: group ?? "") ?? 0
    }
}

/// A section's options in three columns, under their group name when they have one.
private struct PanelSectionOptionsGrid: View {
    let id: PanelSectionID
    @ObservedObject private var l10n = L10n.shared
    @AppStorage private var sectionShown: Bool

    init(id: PanelSectionID) {
        self.id = id
        _sectionShown = AppStorage(wrappedValue: true, id.visibilityKey)
    }

    var body: some View {
        let options = PanelSectionOptions.options(for: id, l10n: l10n)
        let groups = options.reduce(into: [String?]()) { if !$0.contains($1.group) { $0.append($1.group) } }
        VStack(alignment: .leading, spacing: 8) {
            ForEach(groups, id: \.self) { group in
                VStack(alignment: .leading, spacing: 4) {
                    if let group {
                        Text(group)
                            .font(SettingsTypography.caption)
                            .foregroundStyle(.secondary)
                    }
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), alignment: .leading), count: 3),
                              alignment: .leading, spacing: 6) {
                        ForEach(options.filter { $0.group == group }) { option in
                            HStack(spacing: 2) {
                                SettingsVisibilityCheckbox(title: option.title, key: option.key)
                                if let graphKey = option.graphKey {
                                    PanelGraphToggle(title: option.title, key: graphKey, optionKey: option.key)
                                }
                            }
                        }
                    }
                }
            }
        }
        .disabled(!sectionShown)
    }
}

private struct PanelOrderDropDelegate: DropDelegate {
    let target: PanelSectionID
    @Binding var order: [PanelSectionID]
    @Binding var dragging: PanelSectionID?

    func dropEntered(info: DropInfo) {
        guard let dragging,
              dragging != target,
              let from = order.firstIndex(of: dragging),
              let to = order.firstIndex(of: target) else { return }

        withAnimation(.easeInOut(duration: 0.12)) {
            order.move(fromOffsets: IndexSet(integer: from), toOffset: to > from ? to + 1 : to)
        }
        PanelLayout.setOrder(order)
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }

    func performDrop(info: DropInfo) -> Bool {
        dragging = nil
        PanelLayout.setOrder(order)
        return true
    }
}
