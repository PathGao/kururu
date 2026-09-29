// SPDX-License-Identifier: GPL-3.0-or-later

import SwiftUI

struct ScratchpadSaveNotice: View {
    let issue: ScratchpadSaveIssue
    let text: ScratchpadSaveStrings
    let retry: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label {
                Text(issue == .unsavedChanges ? text.unsavedChanges : text.operationFailed)
                    .fixedSize(horizontal: false, vertical: true)
            } icon: {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
            }
            if issue == .unsavedChanges {
                Button(text.retrySave, action: retry)
            }
        }
        .font(.system(.subheadline))
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Color.red.opacity(0.08))
    }
}

struct ScratchpadMutationDialog: View {
    let title: String
    let message: String?
    let namePlaceholder: String?
    @Binding var renameDraft: String
    let failure: String?
    let cancelTitle: String
    let confirmTitle: String
    let isDestructive: Bool
    let canConfirm: Bool
    let cancel: () -> Void
    let confirm: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title).font(.headline)
            if let message {
                Text(message).fixedSize(horizontal: false, vertical: true)
            }
            if let namePlaceholder {
                TextField(namePlaceholder, text: $renameDraft)
                    .textFieldStyle(.roundedBorder)
                    .accessibilityLabel(title)
            }
            if let failure {
                Label(failure, systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
                    .fixedSize(horizontal: false, vertical: true)
            }
            HStack {
                Spacer(minLength: 0)
                Button(cancelTitle, action: cancel).keyboardShortcut(.cancelAction)
                Button(confirmTitle, role: isDestructive ? .destructive : nil, action: confirm)
                    .keyboardShortcut(isDestructive ? nil : .defaultAction)
                    .disabled(!canConfirm)
            }
        }
        .font(.system(.callout))
        .padding(16)
        .frame(width: 280)
    }
}
