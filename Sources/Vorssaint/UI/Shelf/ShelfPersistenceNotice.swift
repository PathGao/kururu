// SPDX-License-Identifier: GPL-3.0-or-later
import SwiftUI

struct ShelfPersistenceNotice: View {
    let issue: ShelfPersistenceIssue
    let isSaving: Bool
    let strings: ShelfPersistenceStrings
    let onRetry: () -> Void

    private var message: String {
        switch issue {
        case .unreadable: return strings.unreadable
        case .saveFailed: return strings.saveFailed
        case .tooLarge: return strings.tooLarge
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(message,
                  systemImage: "exclamationmark.triangle")
                .font(.caption)
                .fixedSize(horizontal: false, vertical: true)
            if issue == .saveFailed {
                VStack(alignment: .leading, spacing: 6) {
                    Button(strings.retry, action: onRetry)
                        .disabled(isSaving)
                    if isSaving {
                        HStack(spacing: 8) {
                            ProgressView().controlSize(.small)
                            Text(strings.saving).font(.caption).fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
        }
        .foregroundStyle(Color(nsColor: .labelColor))
        .tint(Color(nsColor: .controlAccentColor))
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 8))
        .accessibilityElement(children: .contain)
    }
}
