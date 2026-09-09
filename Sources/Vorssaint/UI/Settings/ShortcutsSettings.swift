// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import SwiftUI

/// The central editor for every global shortcut belonging to an installed
/// feature. It writes the same preferences as each feature page, so there is
/// still one setting and one registration path for every action.
struct ShortcutsSettings: View {
    @ObservedObject private var l10n = L10n.shared
    @ObservedObject private var features = FeatureRuntime.shared
    @ObservedObject private var superKey = SuperKeyService.shared
    @AppStorage(DefaultsKey.keyboardBrightnessShortcutsEnabled) private var keyboardBrightnessShortcutsEnabled = false
    @State private var expandedFeatures: Set<AppFeature> = [.screenshot]
    @State private var showsAppShortcuts = false

    private var text: ShortcutSettingsStrings { FeatureStrings.shortcuts(l10n.language) }
    private var hub: FeatureHubStrings { FeatureStrings.hub(l10n.language) }

    private var availableRoles: [GlobalShortcutRole] {
        GlobalShortcutRole.availableRoles(isAvailable: { $0.isAvailable }).filter {
            !$0.isKeyboardBrightness || BrightnessService.keyboardLightIsSupported
        }
    }

    private var captureRoles: [GlobalShortcutRole] {
        GlobalShortcutRole.captureRoles(in: availableRoles)
    }

    private var visibleGroups: [FeatureGroup] {
        FeatureGroup.allCases.filter { group in
            availableRoles.contains { $0.group == group }
        }
    }

    var body: some View {
        Form {
            Section {
                Text(l10n.s.shortcutsPageCaption)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            ForEach(visibleGroups, id: \.self) { group in
                Section(group.title(hub)) {
                    ForEach(featuresWithShortcuts(in: group), id: \.self) { feature in
                        if feature == .screenshot {
                            captureGroupRows
                        } else {
                            featureRows(feature, in: group)
                        }
                    }
                }
            }

            if AppFeature.commandBar.isAvailable {
                Section {
                    Button {
                        showsAppShortcuts = true
                    } label: {
                        Label(FeatureStrings.commandBar(l10n.language).appCenterTitle,
                              systemImage: "app.badge")
                    }
                    Text(FeatureStrings.commandBar(l10n.language).appCenterCaption)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .formStyle(.grouped)
        .sheet(isPresented: $showsAppShortcuts) {
            CommandBarAppShortcutsView()
        }
    }

    private func featuresWithShortcuts(in group: FeatureGroup) -> [AppFeature] {
        AppFeature.allCases.filter { feature in
            // The screenshot slot anchors the combined capture group; the
            // other capture tools render inside it instead of on their own.
            if feature == .screenshot { return group == .capture && !captureRoles.isEmpty }
            if GlobalShortcutRole.captureFeatures.contains(feature) { return false }
            return availableRoles.contains { $0.feature == feature && $0.group == group }
        }
    }

    /// One group for every capture tool's shortcut. Rows keep each tool's own
    /// icon; the group carries the shared page's name and symbol.
    @ViewBuilder
    private var captureGroupRows: some View {
        let roles = captureRoles
        disclosureHeader(
            title: FeatureStrings.screenshot(l10n.language).screenCaptureTitle,
            symbolName: AppFeature.screenshot.symbolName,
            isActive: featureHasActiveShortcut(.screenshot, roles: roles),
            count: roles.count,
            isExpanded: expansionBinding(for: .screenshot))
        if expandedFeatures.contains(.screenshot) {
            ForEach(roles) { role in
                roleRow(role, showsFeatureContext: false)
                    .disclosureIndent()
            }
        }
    }

    @ViewBuilder
    private func featureRows(_ feature: AppFeature, in group: FeatureGroup) -> some View {
        let roles = availableRoles.filter { $0.feature == feature && $0.group == group }
        let count = roles.count
        if count > 1 {
            disclosureHeader(
                title: featureTitle(feature, roles: roles),
                symbolName: featureSymbol(feature, roles: roles),
                isActive: featureHasActiveShortcut(feature, roles: roles),
                count: count,
                isExpanded: expansionBinding(for: feature))
            if expandedFeatures.contains(feature) {
                if feature == .brightness {
                    KeyboardBrightnessShortcutToggle(isEnabled: $keyboardBrightnessShortcutsEnabled)
                        .disclosureIndent()
                }
                ForEach(roles) { role in
                    roleRow(role, showsFeatureContext: false)
                        .disclosureIndent()
                }
            }
        } else if let role = roles.first {
            roleRow(role)
        }
    }

    private func featureTitle(_ feature: AppFeature, roles: [GlobalShortcutRole]) -> String {
        if !roles.isEmpty, roles.allSatisfy(\.isKeyboardBrightness) {
            return FeatureStrings.brightness(l10n.language).keyboardLight
        }
        return feature.name(l10n.s, language: l10n.language)
    }

    private func featureSymbol(_ feature: AppFeature, roles: [GlobalShortcutRole]) -> String {
        !roles.isEmpty && roles.allSatisfy(\.isKeyboardBrightness)
            ? "keyboard" : feature.symbolName
    }

    private func disclosureHeader(title: String,
                                  symbolName: String,
                                  isActive: Bool,
                                  count: Int,
                                  isExpanded: Binding<Bool>) -> some View {
        DisclosureHeaderRow(isExpanded: isExpanded) {
            ShortcutRowLabel(
                title: title,
                symbolName: symbolName,
                contextLabel: nil,
                statusText: isActive ? text.active : text.inactive,
                statusIsActive: isActive
            )
            Spacer()
            Text("\(count)")
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
                .padding(.horizontal, 7)
                .padding(.vertical, 2)
                .background(Capsule().fill(Color.primary.opacity(0.06)))
        }
    }

    private func roleRow(_ role: GlobalShortcutRole,
                         showsFeatureContext: Bool = true) -> some View {
        let title = role.title(l10n.s)
        let featureTitle = role.feature.name(l10n.s, language: l10n.language)
        let active = role.requiredEnableKeys.allSatisfy {
            UserDefaults.standard.bool(forKey: $0)
        }
        return ShortcutPreferenceRow(
            role: role,
            isEnabled: !role.isKeyboardBrightness || keyboardBrightnessShortcutsEnabled,
            label: title,
            symbolName: role.isKeyboardBrightness ? "keyboard" : role.feature.symbolName,
            contextLabel: showsFeatureContext && title != featureTitle ? featureTitle : nil,
            statusText: active ? text.active : text.inactive,
            statusIsActive: active,
            showsSuperKeyAlternative: superKey.isRunning,
            superKeyModifiers: superKey.modifiers,
            includeInactiveConflicts: true,
            onChange: {
                FeatureRuntime.shared.sync(role.availabilityFeatures)
            }
        )
    }

    private func expansionBinding(for feature: AppFeature) -> Binding<Bool> {
        Binding {
            expandedFeatures.contains(feature)
        } set: { expanded in
            if expanded {
                expandedFeatures.insert(feature)
            } else {
                expandedFeatures.remove(feature)
            }
        }
    }

    private func featureHasActiveShortcut(_ feature: AppFeature,
                                          roles: [GlobalShortcutRole]) -> Bool {
        return roles.contains { role in
            role.requiredEnableKeys.allSatisfy { UserDefaults.standard.bool(forKey: $0) }
        }
    }
}

private struct KeyboardBrightnessShortcutToggle: View {
    @ObservedObject private var l10n = L10n.shared
    @ObservedObject private var brightness = BrightnessService.shared
    @Binding var isEnabled: Bool

    var body: some View {
        Toggle(FeatureStrings.brightness(l10n.language).keyboardBrightnessShortcuts,
               isOn: $isEnabled)
            .onChange(of: isEnabled) { _, _ in
                brightness.syncWithPreferences()
            }
        if isEnabled, brightness.keyboardBrightnessShortcutRegistrationFailed {
            Text(l10n.s.shortcutUnavailable)
                .font(.caption)
                .foregroundStyle(.orange)
        }
    }
}

