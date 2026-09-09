// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import SwiftUI

struct TrackpadSettings: View {
    @ObservedObject private var l10n = L10n.shared
    @ObservedObject private var permissions = Permissions.shared
    @ObservedObject private var middleClick = MiddleClickService.shared
    @AppStorage(DefaultsKey.middleClickEnabled) private var middleClickEnabled = false
    @AppStorage(DefaultsKey.middleClickTapFingers) private var middleClickTapFingers = 0

    var body: some View {
        Form {
            if AppFeature.middleClick.isAvailable {
                Section(AppFeature.middleClick.name(l10n.s, language: l10n.language)) {
                    Toggle(l10n.s.middleClickEnable, isOn: $middleClickEnabled)
                        .onChange(of: middleClickEnabled) { _, enabled in
                            MiddleClickService.shared.syncWithPreferences()
                            if enabled { permissions.requestAccessibility() }
                        }
                    Text(l10n.s.middleClickEnableCaption)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if middleClickEnabled {
                        Picker(l10n.s.middleClickTapPicker, selection: $middleClickTapFingers) {
                            Text(l10n.s.middleClickTapOff).tag(0)
                            Text(l10n.s.middleClickTapThreeFingers).tag(3)
                            Text(l10n.s.middleClickTapFourFingers).tag(4)
                        }
                        .onChange(of: middleClickTapFingers) { _, _ in
                            MiddleClickService.shared.syncWithPreferences()
                        }
                        Text(l10n.s.middleClickTapCaption)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    if middleClickEnabled, middleClick.systemDragGestureConflict {
                        Text(l10n.s.middleClickDragConflict)
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                    if middleClickEnabled {
                        MouseExceptionsList(scope: .middleClick)
                    }
                }
                .settingsSectionAnchor(.middleClick)
            }
            if middleClickEnabled, !permissions.accessibility {
                Section(l10n.s.permissionRequired) {
                    PermissionRow(kind: .accessibility)
                }
            }
        }
        .formStyle(.grouped)
        .onAppear {
            MiddleClickService.shared.refreshDragGestureConflict()
        }
    }
}
