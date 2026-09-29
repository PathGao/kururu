// SPDX-License-Identifier: GPL-3.0-or-later
import SwiftUI

struct ClipboardQuickFooter: View {
    let text: ClipboardFeatureStrings
    let batchCount: Int
    let totalCount: Int
    let paste: () -> Void
    let copy: () -> Void
    let clearSelection: () -> Void
    let delete: () -> Void
    let hasSelection: Bool
    let copyLabel: String

    var body: some View {
        VStack(spacing: 8) {
            if hasSelection {
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 8) { primaryActions }
                    VStack(alignment: .leading, spacing: 8) { primaryActions }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Divider()
            }
            HStack(spacing: 8) {
                Label("\(totalCount)", systemImage: "doc.on.clipboard")
                    .font(PanelTypography.meta)
                    .foregroundStyle(.secondary)
                Spacer(minLength: 16)
                if batchCount > 0 {
                    Button(String(format: text.deleteSelectedFormat, batchCount), role: .destructive,
                           action: delete)
                } else {
                    ClipboardClearRecentButton(inManagementMenu: true)
                }
            }
        }
        .controlSize(.small)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    @ViewBuilder
    private var primaryActions: some View {
        Button((batchCount > 0 ? String(format: text.pasteSelectedFormat, batchCount) : L10n.shared.s.menuPaste) + " ↵", action: paste)
            .buttonStyle(.borderedProminent)
        Button(batchCount > 0 ? String(format: text.copySelectedFormat, batchCount) : copyLabel, action: copy)
        if batchCount > 0 { Button(text.clearSelection, action: clearSelection) }
    }
}
