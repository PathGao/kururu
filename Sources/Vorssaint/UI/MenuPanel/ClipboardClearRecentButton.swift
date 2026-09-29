// SPDX-License-Identifier: GPL-3.0-or-later
import SwiftUI

struct ClipboardClearRecentButton: View {
    @ObservedObject private var history = ClipboardHistoryService.shared
    @ObservedObject private var l10n = L10n.shared
    var inManagementMenu = false
    @State private var confirmedIDs: Set<UUID> = []
    @State private var confirming = false

    var body: some View {
        Group {
            if inManagementMenu {
                Menu {
                    clearButton
                } label: {
                    Label(ClipboardActionStrings.manage, systemImage: "ellipsis")
                }
                .menuStyle(.borderlessButton)
                .fixedSize()
            } else {
                clearButton
            }
        }
        .alert(ClipboardActionStrings.clear, isPresented: $confirming) {
            Button(FeatureStrings.clipboard(l10n.language).cancel, role: .cancel) {}
            Button(ClipboardActionStrings.confirm, role: .destructive) {
                history.clearRecent(confirmedIDs: confirmedIDs)
            }
        } message: {
            Text(ClipboardActionStrings.clearMessage(confirmedIDs.count))
        }
    }

    private var clearButton: some View {
        Button {
            confirmedIDs = Set(history.recentEntries.map(\.id))
            confirming = true
        } label: {
            Label(ClipboardActionStrings.clear, systemImage: "trash")
        }
        .disabled(history.recentEntries.isEmpty)
    }

}
