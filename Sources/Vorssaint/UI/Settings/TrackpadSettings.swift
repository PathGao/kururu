// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import SwiftUI

struct TrackpadSettings: View {
    @ObservedObject private var l10n = L10n.shared
    @ObservedObject private var features = FeatureRuntime.shared
    @ObservedObject private var permissions = Permissions.shared
    @ObservedObject private var middleClick = MiddleClickService.shared
    @AppStorage(DefaultsKey.middleClickEnabled) private var middleClickEnabled = false
    @AppStorage(DefaultsKey.middleClickTapFingers) private var middleClickTapFingers = 0
    @AppStorage(DefaultsKey.radialMenuEnabled) private var radialMenuEnabled = false
    @AppStorage(DefaultsKey.radialMenuProfiles) private var radialProfilesData = Data()
    @AppStorage(DefaultsKey.trackpadSpreadProfile) private var spreadProfile = ""
    private var tuningText: InputTuningStrings { InputTuningStrings(language: l10n.language) }
    private var gestureText: TrackpadGestureStrings { .localized(l10n.language) }
    private var radialProfiles: [RadialMenuProfile] { RadialMenuSupport.decodeProfiles(radialProfilesData) }
    private var middleTapBinding: Binding<Int> {
        Binding(get: { middleClickTapFingers }, set: { fingers in
            guard !TrackpadGestureRouting.conflicts(fingers: fingers,
                middleClickTapFingers: 0, profiles: radialProfiles, excludingProfileID: nil) else { return }
            middleClickTapFingers = fingers
            MiddleClickService.shared.syncWithPreferences()
        })
    }

    private var middleClickWanted: Bool {
        AppFeature.middleClick.isAvailable && middleClickEnabled
    }

    private var activeRadialTapFingers: [Int] {
        guard AppFeature.radialMenu.isAvailable, radialMenuEnabled else { return [] }
        return [3, 4].filter { fingers in
            guard let owner = TrackpadGestureRouting.owner(fingers: fingers,
                middleClickTapFingers: middleClickTapFingers, profiles: radialProfiles)
            else { return false }
            if case .radial = owner { return true }
            return false
        }
    }

    private var spreadWanted: Bool {
        AppFeature.radialMenu.isAvailable && radialMenuEnabled
            && radialProfiles.contains { $0.id.uuidString == spreadProfile }
    }

    private var needsTrackpadInput: Bool { middleClickWanted || !activeRadialTapFingers.isEmpty || spreadWanted }
    private var needsThreeFingerInput: Bool { middleClickWanted || activeRadialTapFingers.contains(3) || spreadWanted }

    @ViewBuilder
    private var inputWarnings: some View {
        if needsTrackpadInput {
            if !permissions.accessibility {
                SettingsSection(l10n.s.permissionRequired) {
                    PermissionRow(kind: .accessibility)
                }
            } else if !middleClick.trackpadAvailable {
                SettingsSection {
                    Text(gestureText.unavailable).font(SettingsTypography.caption).foregroundStyle(.orange)
                }
            }
            if needsThreeFingerInput, middleClick.systemDragGestureConflict {
                SettingsSection {
                    Text(gestureText.systemDragConflict).font(SettingsTypography.caption).foregroundStyle(.orange)
                }
            }
        }
    }

    var body: some View {
        SettingsForm {
            if AppFeature.middleClick.isAvailable {
                SettingsSection(AppFeature.middleClick.name(l10n.s, language: l10n.language)) {
                    SettingsToggleWithCaption(title: l10n.s.middleClickEnable,
                                              caption: l10n.s.middleClickEnableCaption,
                                              isOn: $middleClickEnabled)
                        .onChange(of: middleClickEnabled) { _, enabled in
                            MiddleClickService.shared.syncWithPreferences()
                            if enabled { permissions.requestAccessibility() }
                        }
                    SettingsControlRow(title: l10n.s.middleClickTapPicker,
                                       systemImage: "hand.tap",
                                       caption: l10n.s.middleClickTapCaption) {
                        Picker(l10n.s.middleClickTapPicker, selection: middleTapBinding) {
                            Text(l10n.s.middleClickTapOff).tag(0)
                            ForEach([3, 4], id: \.self) { fingers in
                                Text(fingers == 3 ? l10n.s.middleClickTapThreeFingers : l10n.s.middleClickTapFourFingers)
                                    .tag(fingers)
                                    .disabled(fingers != middleClickTapFingers && TrackpadGestureRouting.conflicts(
                                        fingers: fingers, middleClickTapFingers: 0,
                                        profiles: radialProfiles, excludingProfileID: nil))
                            }
                        }
                        .labelsHidden()
                        .onChange(of: middleClickTapFingers) { _, _ in
                            MiddleClickService.shared.syncWithPreferences()
                        }
                    }
                    Text(gestureText.reservation).font(SettingsTypography.caption).foregroundStyle(.secondary)
                    if middleClickTapFingers != 0, TrackpadGestureRouting.conflicts(
                        fingers: middleClickTapFingers, middleClickTapFingers: 0,
                        profiles: radialProfiles, excludingProfileID: nil) {
                        Text(gestureText.conflict).font(SettingsTypography.caption).foregroundStyle(.orange)
                    }
                    MouseExceptionsList(scope: .middleClick)
                }
                .settingsSectionAnchor(.middleClick)
            }
            if AppFeature.radialMenu.isAvailable {
                SettingsSection(tuningText.spread) {
                    Picker(tuningText.spread, selection: Binding(
                        get: { radialProfiles.contains { $0.id.uuidString == spreadProfile } ? spreadProfile : "" },
                        set: { spreadProfile = $0 })) {
                        Text(l10n.s.middleClickTapOff).tag("")
                        ForEach(radialProfiles) { profile in
                            Text(profile.displayName(FeatureStrings.radialMenu(l10n.language))).tag(profile.id.uuidString)
                        }
                    }
                    .onChange(of: spreadProfile) { _, value in
                        MiddleClickService.shared.syncWithPreferences()
                        if !value.isEmpty { permissions.requestAccessibility() }
                    }
                    SettingsCaptionText(tuningText.spreadHint)
                    FeatureSwitchRow(feature: .radialMenu)
                    Button(AppFeature.radialMenu.name(l10n.s, language: l10n.language)) {
                        SettingsRouter.shared.request(AppFeature.radialMenu.settingsDestination)
                    }
                }
            }
            let bindings = radialProfiles.filter { $0.trackpadTapFingers != 0 }
            if !bindings.isEmpty {
                SettingsSection(gestureText.bindings) {
                    ForEach(bindings) { profile in
                        VStack(alignment: .leading, spacing: 4) {
                            LabeledContent(profile.displayName(FeatureStrings.radialMenu(l10n.language)),
                                value: profile.trackpadTapFingers == 3 ? l10n.s.middleClickTapThreeFingers : l10n.s.middleClickTapFourFingers)
                            if TrackpadGestureRouting.conflicts(fingers: profile.trackpadTapFingers,
                                middleClickTapFingers: middleClickTapFingers, profiles: radialProfiles,
                                excludingProfileID: profile.id) {
                                Text(gestureText.conflict).font(SettingsTypography.caption).foregroundStyle(.orange)
                            }
                        }
                    }
                    Text(gestureText.hint).font(SettingsTypography.caption).foregroundStyle(.secondary)
                    VStack(alignment: .leading, spacing: 4) {
                        Button {
                            SettingsRouter.shared.request(AppFeature.radialMenu.settingsDestination)
                        } label: {
                            Label(AppFeature.radialMenu.name(l10n.s, language: l10n.language),
                                  systemImage: "arrow.right")
                        }
                        SettingsCaptionText(gestureText.configuration)
                    }
                }
            }
            inputWarnings
        }
        .formStyle(.grouped)
        .onAppear {
            MiddleClickService.shared.refreshDragGestureConflict()
        }
    }
}
