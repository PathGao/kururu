// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import AppKit
import SwiftUI
import UniformTypeIdentifiers

/// The "Menu bar panel" settings page: what the panel holds and in what order.
/// The icon above it has its own page, and each tenant keeps whatever else it
/// does on its own.
struct MenuBarPanelSettings: View {
    @AppStorage("monitorHistoryMinutes") private var historyMinutes = 1
    @ObservedObject private var l10n = L10n.shared
    @ObservedObject private var features = FeatureRuntime.shared

    var body: some View {
        SettingsForm {
            if !PanelOrderEditor.availableOrder(PanelLayout.order).isEmpty {
                SettingsSection(l10n.s.monitorOrderSection) {
                    PanelOrderEditor()
                    Text(UXEntryStrings(l10n.language).panelOrderHint)
                        .font(SettingsTypography.caption)
                        .foregroundStyle(.secondary)
                }
                .settingsSectionAnchor(.panelConfiguration)
            }
            SettingsSection(l10n.s.monitorPanelSection) {
                MonitorPanelConfig(includeStandaloneSections: true)
                Picker(MonitorHistoryStrings.text(l10n.language).range, selection: $historyMinutes) {
                    ForEach(1...5, id: \.self) { value in
                        Text("\(value) \(MonitorHistoryStrings.text(l10n.language).minutes)").tag(value)
                    }
                }
                Text(MonitorHistoryStrings.text(l10n.language).visibilityHint)
                    .font(SettingsTypography.caption).foregroundStyle(.secondary)
                Text(l10n.s.monitorPanelConfigHint)
                    .font(SettingsTypography.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
    }
}

/// Reorders panel sections; visibility controls live with each section's options below.
struct PanelOrderEditor: View {
    @ObservedObject private var l10n = L10n.shared
    @ObservedObject private var features = FeatureRuntime.shared
    @State private var order: [PanelSectionID] = PanelLayout.order
    @State private var dragging: PanelSectionID?
    /// Also observes changes made on individual feature pages.
    @State private var visibilityChanges = 0

    var body: some View {
        VStack(spacing: 8) {
            ForEach(editableOrder) { id in
                VStack(spacing: 0) {
                    HStack(spacing: 8) {
                        HStack(spacing: 8) {
                            Image(systemName: "line.3.horizontal")
                                .font(.system(size: 12))
                                .foregroundStyle(.tertiary)
                            Image(systemName: id.symbolName)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(isShown(id) ? Color.accentColor : Color.secondary)
                                .frame(width: 34, height: 34)
                                .background(Color.primary.opacity(0.035), in: RoundedRectangle(cornerRadius: 10))
                            Text(id.title(l10n.s))
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(isShown(id) ? .primary : .secondary)
                            Spacer(minLength: 0)
                        }
                        .frame(maxWidth: .infinity)
                        .contentShape(Rectangle())
                        .opacity(dragging == id ? 0.45 : 1)
                        .onDrag {
                            dragging = id
                            return NSItemProvider(object: id.rawValue as NSString)
                        }
                        .onDrop(of: [UTType.text],
                                delegate: PanelOrderDropDelegate(target: id,
                                                                 order: $order,
                                                                 dragging: $dragging))

                    }
                    .frame(height: 46)
                    .padding(.horizontal, 8)
                    .background(Color.primary.opacity(0.025), in: RoundedRectangle(cornerRadius: 13))
                }
            }
        }
        .padding(.vertical, 2)
        .onAppear { order = PanelLayout.order }
        .onReceive(NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)) { _ in
            visibilityChanges += 1
            order = PanelLayout.order
        }
    }

    private var editableOrder: [PanelSectionID] {
        Self.availableOrder(order)
    }

    static func availableOrder(_ order: [PanelSectionID]) -> [PanelSectionID] {
        order.filter { $0.isAvailable }
    }

    private func isShown(_ id: PanelSectionID) -> Bool {
        _ = visibilityChanges
        return PanelLayout.isShown(id)
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




