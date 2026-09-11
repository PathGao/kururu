// SPDX-License-Identifier: GPL-3.0-or-later
import SwiftUI

struct EnvironmentCopyButton: View {
    let title: String
    let succeeded: Bool?
    let copied: String
    let failed: String
    let action: () -> Void

    var body: some View {
        VStack(alignment: .trailing, spacing: 3) {
            Button(action: action) {
                Label(title, systemImage: "doc.on.doc")
            }
            .settingsAction(.secondary)
            if let succeeded {
                Label(succeeded ? copied : failed,
                      systemImage: succeeded ? "checkmark.circle" : "exclamationmark.circle")
                    .font(SettingsTypography.caption)
                    .foregroundStyle(succeeded ? Color.secondary : Color.orange)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
