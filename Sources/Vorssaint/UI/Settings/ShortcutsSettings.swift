// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import SwiftUI
import Combine

/// The central editor for every global shortcut belonging to an installed
/// feature. It writes the same preferences as each feature page, so there is
/// still one setting and one registration path for every action.
struct ShortcutsSettings: View {
    @ObservedObject private var l10n = L10n.shared
    @ObservedObject private var features = FeatureRuntime.shared
    @ObservedObject private var superKey = SuperKeyService.shared
    @AppStorage(DefaultsKey.keyboardBrightnessShortcutsEnabled) private var keyboardBrightnessShortcutsEnabled = false
    @AppStorage(BrightnessShortcutPreferenceKey.enabled) private var displayBrightnessShortcutsEnabled = false
    @State private var expandedFeatures: [FeatureGroup: Set<AppFeature>] = [.capture: [.screenshot]]
    @State private var showsAppShortcuts = false
    @State private var historyRevision = 0
    @State private var failedRoles: Set<GlobalShortcutRole> = []

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
                // Window layout keeps one shortcut per action instead of a
                // role, so it has to open its group on its own.
                || (group == .windowsDesktop && AppFeature.windowLayout.isAvailable)
        }
    }

    private var historyChanges: AnyPublisher<Void, Never> {
        guard AppFeature.clipboardHistory.isAvailable else {
            return Empty().eraseToAnyPublisher()
        }
        return ClipboardHistoryService.shared.objectWillChange.eraseToAnyPublisher()
    }

    private var registrationChanges: AnyPublisher<(GlobalShortcutRole, Bool), Never> {
        Publishers.MergeMany(availableRoles.map { role in
            role.registrationFailurePublisher.map { (role, $0) }.eraseToAnyPublisher()
        }).eraseToAnyPublisher()
    }

    var body: some View {
        let _ = historyRevision
        SettingsForm {
            SettingsSection {
                Text(l10n.s.shortcutsPageCaption)
                    .font(SettingsTypography.caption)
                    .foregroundStyle(.secondary)
            }

            ForEach(visibleGroups, id: \.self) { group in
                SettingsSection(group.title(hub)) {
                    ForEach(featuresWithShortcuts(in: group), id: \.self) { feature in
                        if feature == .screenshot {
                            captureGroupRows
                        } else if feature == .windowLayout {
                            windowLayoutGroupRows
                        } else {
                            featureRows(feature, in: group)
                        }
                    }
                }
            }

            if AppFeature.commandBar.isAvailable {
                SettingsSection {
                    Button {
                        showsAppShortcuts = true
                    } label: {
                        Label(FeatureStrings.commandBar(l10n.language).appCenterTitle,
                              systemImage: "app.badge")
                    }
                    Text(FeatureStrings.commandBar(l10n.language).appCenterCaption)
                        .font(SettingsTypography.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .formStyle(.grouped)
        .onReceive(historyChanges) { historyRevision &+= 1 }
        .onReceive(registrationChanges) { role, failed in
            if failed != failedRoles.contains(role) {
                if failed { failedRoles.insert(role) } else { failedRoles.remove(role) }
            }
        }
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
            if feature == .windowLayout {
                return group == .windowsDesktop && feature.isAvailable
            }
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
            isExpanded: expansionBinding(for: .screenshot, in: .capture))
        if expandedFeatures[.capture, default: []].contains(.screenshot) {
            ForEach(roles) { role in
                roleRow(role, showsFeatureContext: false)
                    .disclosureIndent()
            }
        }
    }

    /// Window layout's shortcuts live on its own actions rather than roles,
    /// so the group is built from the action list instead of `availableRoles`.
    @ViewBuilder
    private var windowLayoutGroupRows: some View {
        let layoutText = FeatureStrings.windowLayout(l10n.language)
        let shortcutsEnabled = UserDefaults.standard.bool(
            forKey: DefaultsKey.windowLayoutShortcutsEnabled)
        disclosureHeader(
            title: AppFeature.windowLayout.name(l10n.s, language: l10n.language),
            symbolName: AppFeature.windowLayout.symbolName,
            isActive: shortcutsEnabled
                && WindowLayoutAction.shortcutActions.contains { $0.savedShortcut != nil },
            count: WindowLayoutAction.shortcutActions.count,
            isExpanded: expansionBinding(for: .windowLayout, in: .windowsDesktop))
        if expandedFeatures[.windowsDesktop, default: []].contains(.windowLayout) {
            ForEach(WindowLayoutAction.shortcutActions) { action in
                WindowLayoutActionRow(action: action,
                                      title: action.title(layoutText),
                                      symbol: action.symbolName,
                                      applyEnabled: false,
                                      shortcutEnabled: shortcutsEnabled,
                                      showsApply: false)
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
                isExpanded: expansionBinding(for: feature, in: group))
            if expandedFeatures[group, default: []].contains(feature) {
                if feature == .brightness {
                    if roles.allSatisfy(\.isKeyboardBrightness) {
                        KeyboardBrightnessShortcutToggle(isEnabled: $keyboardBrightnessShortcutsEnabled)
                            .disclosureIndent()
                    } else {
                        DisplayBrightnessShortcutToggle(isEnabled: $displayBrightnessShortcutsEnabled)
                            .disclosureIndent()
                    }
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
                statusIsActive: false
            )
            Spacer()
            Text("\(count)")
                .font(SettingsTypography.caption.monospacedDigit())
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
        let active = role.isActive(isOn: { UserDefaults.standard.bool(forKey: $0) },
                                   isAvailable: { $0.isAvailable },
                                   hasClipboardHistory: { !ClipboardHistoryService.shared.entries.isEmpty })
        let failed = active && failedRoles.contains(role)
        let needsMixer = active && role == .soundOutputSwitcher && !AppFeature.mixer.isAvailable
        let status = failed
            ? ShortcutSettingsStrings.registrationIssue(l10n.language,
                multiple: role == .radialMenu || role.isKeyboardBrightness || role == .displayBrightnessDecrease || role == .displayBrightnessIncrease)
            : needsMixer ? UXEntryStrings(l10n.language).outputDevicesNeedMixer
            : active ? text.active : text.inactive
        return ShortcutPreferenceRow(
            role: role,
            isEnabled: true,
            label: title,
            symbolName: role.isKeyboardBrightness ? "keyboard" : role.feature.symbolName,
            contextLabel: showsFeatureContext && title != featureTitle ? featureTitle : nil,
            statusText: status,
            statusIsActive: false,
            showsSuperKeyAlternative: superKey.isRunning,
            superKeyModifiers: superKey.modifiers,
            includeInactiveConflicts: true,
            onChange: {
                FeatureRuntime.shared.sync(role.availabilityFeatures)
            }
        )
    }

    private func expansionBinding(for feature: AppFeature, in group: FeatureGroup) -> Binding<Bool> {
        Binding {
            expandedFeatures[group, default: []].contains(feature)
        } set: { expanded in
            if expanded {
                expandedFeatures[group, default: []].insert(feature)
            } else {
                expandedFeatures[group, default: []].remove(feature)
            }
        }
    }

    private func featureHasActiveShortcut(_ feature: AppFeature,
                                          roles: [GlobalShortcutRole]) -> Bool {
        return roles.contains { role in
            role.isActive(isOn: { UserDefaults.standard.bool(forKey: $0) },
                          isAvailable: { $0.isAvailable },
                          hasClipboardHistory: { !ClipboardHistoryService.shared.entries.isEmpty })
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
                .font(SettingsTypography.caption)
                .foregroundStyle(.orange)
        }
    }
}

private struct DisplayBrightnessShortcutToggle: View {
    @ObservedObject private var l10n = L10n.shared
    @ObservedObject private var brightness = BrightnessService.shared
    @Binding var isEnabled: Bool

    var body: some View {
        Toggle(BrightnessShortcutStrings.localized(l10n.language).toggle, isOn: $isEnabled)
            .onChange(of: isEnabled) { _, _ in brightness.syncWithPreferences() }
        if isEnabled, brightness.displayBrightnessShortcutRegistrationFailed {
            Text(l10n.s.shortcutUnavailable)
                .font(SettingsTypography.caption)
                .foregroundStyle(.orange)
        }
    }
}

private extension GlobalShortcutRole {
    // Published values deliver registration outcomes after the service changes them.
    var registrationFailurePublisher: AnyPublisher<Bool, Never> {
        switch self {
        case .keepAwake: return HotkeyManager.shared.$registrationFailed.eraseToAnyPublisher()
        case .shelf: return ShelfService.shared.$hotkeyRegistrationFailed.eraseToAnyPublisher()
        case .clipboard: return ClipboardHistoryService.shared.$shortcutRegistrationFailed.eraseToAnyPublisher()
        case .soundOutputSwitcher: return SoundOutputSwitcher.shared.$registrationFailed.eraseToAnyPublisher()
        case .pastePlain: return PastePlainService.shared.$shortcutRegistrationFailed.eraseToAnyPublisher()
        case .micMute: return MicMuteService.shared.$shortcutRegistrationFailed.eraseToAnyPublisher()
        case .screenshotFullScreen: return ScreenshotService.shared.$fullScreenShortcutRegistrationFailed.eraseToAnyPublisher()
        case .screenshotLastCapture: return ScreenshotService.shared.$lastCaptureShortcutRegistrationFailed.eraseToAnyPublisher()
        case .screenshotClipboard: return ScreenshotService.shared.$clipboardShortcutRegistrationFailed.eraseToAnyPublisher()
        case .recentCaptures: return RecentCaptureService.shared.$shortcutRegistrationFailed.eraseToAnyPublisher()
        case .radialMenu: return RadialMenuService.shared.$registrationFailed.eraseToAnyPublisher()
        case .scratchpad: return ScratchpadService.shared.$shortcutRegistrationFailed.eraseToAnyPublisher()
        case .cameraPreview: return CameraPreviewService.shared.$shortcutRegistrationFailed.eraseToAnyPublisher()
        case .snippetLibrary: return SnippetLibraryService.shared.$shortcutRegistrationFailed.eraseToAnyPublisher()
        case .commandBar: return CommandBarService.shared.$shortcutRegistrationFailed.eraseToAnyPublisher()
        case .keyboardBrightnessDecrease, .keyboardBrightnessIncrease:
            return BrightnessService.shared.$keyboardBrightnessShortcutRegistrationFailed.eraseToAnyPublisher()
        case .displayBrightnessDecrease, .displayBrightnessIncrease:
            return BrightnessService.shared.$displayBrightnessShortcutRegistrationFailed.eraseToAnyPublisher()
        case .switcher, .switcherWindow, .finderRename, .colorPicker, .screenOCR, .screenshot, .screenRecorder:
            return Just(false).eraseToAnyPublisher()
        }
    }
}
