// SPDX-License-Identifier: GPL-3.0-or-later
import SwiftUI

struct UninstallerSelectionErrorView: View {
    @ObservedObject private var l10n = L10n.shared
    let error: UninstallerSelectionError

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label {
                Text(error.message(language: l10n.language.rawValue))
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            } icon: {
                Image(systemName: "exclamationmark.triangle")
                    .foregroundStyle(.orange)
            }
        }
        .font(.callout)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
    }
}
