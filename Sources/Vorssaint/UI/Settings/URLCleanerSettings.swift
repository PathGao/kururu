// SPDX-License-Identifier: GPL-3.0-or-later
import SwiftUI

struct URLCleanerSettings: View {
    @ObservedObject private var l10n = L10n.shared
    var body: some View {
        SettingsForm {
            URLCleanerSections()
            SettingsSection(UXEntryStrings(l10n.language).displayLocations) {
                PanelEntrySettings(title: l10n.s.monitorShowInPanel,
                                   key: DefaultsKey.panelUtilityURLCleaner)
            }
        }
        .formStyle(.grouped)
    }
}
