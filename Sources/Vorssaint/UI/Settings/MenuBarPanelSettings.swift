// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import AppKit
import SwiftUI
import UniformTypeIdentifiers

/// The "Menu bar panel" settings page: what the panel holds and in what order.
/// The icon above it has its own page, and each tenant keeps whatever else it
/// does on its own.
struct MenuBarPanelSettings: View {
    @ObservedObject private var l10n = L10n.shared

    var body: some View {
        Form {
            Section(l10n.s.monitorOrderSection) {
                PanelOrderEditor()
                Text(l10n.s.monitorOrderHint)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .settingsSectionAnchor(.panelConfiguration)
            Section(l10n.s.monitorPanelSection) {
                MonitorPanelConfig()
                Text(l10n.s.monitorPanelConfigHint)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
    }
}

/// Drag-to-reorder and show/hide list for the panel's major sections. Writes the
/// order to `PanelLayout` and each section's visibility to its own key, both of
/// which the live panel observes. A bounded, non-scrolling list so it sits inside
/// the grouped Form without its own scroll area.
struct PanelOrderEditor: View {
    @ObservedObject private var l10n = L10n.shared
    @ObservedObject private var features = FeatureRuntime.shared
    @AppStorage(DefaultsKey.panelShowFanControl) private var showFanControl = true
    @State private var order: [PanelSectionID] = PanelLayout.order
    @State private var dragging: PanelSectionID?
    /// Bumped whenever a section is shown/hidden so the dimmed titles and the
    /// "can't hide the last one" guard recompute.
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

                        // Fan Control is governed by its own toggle on Monitor, so
                        // it has no separate show/hide here.
                        if id != .fanControl {
                            SectionVisibilityEye(id: id,
                                                 canHide: visibleCount > 1,
                                                 onChange: { visibilityChanges += 1 })
                        }
                    }
                    .frame(height: 46)
                    .padding(.horizontal, 8)
                    .background(Color.primary.opacity(0.025), in: RoundedRectangle(cornerRadius: 13))
                }
            }
        }
        .padding(.vertical, 2)
        .onAppear { order = PanelLayout.order }
        .onChange(of: showFanControl) { _, _ in order = PanelLayout.order }
    }

    private var editableOrder: [PanelSectionID] {
        order.filter { ($0 != .fanControl || showFanControl) && $0.isAvailable }
    }

    private func isShown(_ id: PanelSectionID) -> Bool {
        _ = visibilityChanges
        return PanelLayout.isShown(id)
    }

    /// How many sections are currently visible in the panel, so the last one
    /// can't be hidden (which would leave an empty panel).
    private var visibleCount: Int {
        _ = visibilityChanges
        return editableOrder.reduce(0) { $0 + (PanelLayout.isShown($1) ? 1 : 0) }
    }
}

/// An eye button that shows/hides one panel section, backed by that section's
/// own visibility key so the live panel updates immediately.
private struct SectionVisibilityEye: View {
    @ObservedObject private var l10n = L10n.shared
    let id: PanelSectionID
    let canHide: Bool
    let onChange: () -> Void
    @AppStorage private var shown: Bool

    init(id: PanelSectionID, canHide: Bool, onChange: @escaping () -> Void) {
        self.id = id
        self.canHide = canHide
        self.onChange = onChange
        _shown = AppStorage(wrappedValue: id.shownByDefault, id.visibilityKey)
    }

    var body: some View {
        PanelInlineHideButton(isVisible: Binding(
            get: { shown },
            set: { shown = $0; onChange() }
        ))
        // Keep at least one section visible.
        .disabled(shown && !canHide)
        .accessibilityValue(id.title(l10n.s))
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





