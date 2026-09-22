// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import SwiftUI

/// Module availability stops runtime entry points while keeping a route to
/// inspect saved settings without constructing the module's services.
struct FeatureHubSettings: View {
    @ObservedObject private var l10n = L10n.shared
    @ObservedObject private var features = FeatureRuntime.shared
    @ObservedObject private var router = SettingsRouter.shared
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var tab: Tab = .features
    /// Tracks the feature-target request currently being revealed, so a
    /// delayed retry from an older request cannot act after a newer one has
    /// already taken over (same convention as `SettingsSectionFocusModifier`).
    @State private var revealID = UUID()
    /// The row briefly tinted after a search or Command Bar selection lands
    /// on it, mirroring the section highlight `SettingsSectionFocusModifier`
    /// gives an ordinary page anchor.
    @State private var highlightedUnit: FeatureUnit?

    private enum Tab { case features, permissions }

    private var hub: FeatureHubStrings { FeatureStrings.hub(l10n.language) }
    private var workspace: ModuleWorkspaceStrings { ModuleWorkspaceStrings(l10n.language) }

    var body: some View {
        ScrollViewReader { proxy in
            content
                .onAppear { revealPendingFeatureTarget(using: proxy) }
                .onChange(of: router.requestID) { _, _ in revealPendingFeatureTarget(using: proxy) }
        }
    }

    private var content: some View {
        SettingsForm {
            SettingsSection {
                HStack(spacing: 8) {
                    Picker("", selection: $tab) {
                        Text(hub.tabFeatures).tag(Tab.features)
                        Text(hub.tabPermissions).tag(Tab.permissions)
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    SettingsHelpButton(title: tab == .features ? hub.tabFeatures : hub.tabPermissions,
                                       text: tab == .features ? workspace.intro + "\n\n" + workspace.footer : hub.permissionsIntro)
                }
                if tab == .features {
                    HStack(spacing: 8) {
                        Text(String(format: workspace.activeFormat,
                                    features.availableCount, features.installableCount))
                            .font(SettingsTypography.body)
                            .foregroundStyle(.secondary)
                        Spacer(minLength: 8)
                        Button {
                            FeatureRuntime.shared.relaunchApp()
                        } label: {
                            Image(systemName: "arrow.clockwise")
                        }
                        .settingsAction(.secondary)
                        .disabled(!features.needsRestartToUnload)
                        .opacity(features.needsRestartToUnload ? 1 : 0)
                        .accessibilityHidden(!features.needsRestartToUnload)
                        .accessibilityLabel(hub.restartButton)
                        .help(hub.restartButton + "\n" + hub.restartNote)
                        Button {
                            FeatureRuntime.shared.setAllAvailable(true)
                        } label: {
                            Text(workspace.addAll)
                        }
                        .settingsAction(.primary)
                        .disabled(features.availableCount == features.installableCount)
                        Button {
                            FeatureRuntime.shared.setAllAvailable(false)
                        } label: {
                            Text(workspace.removeAll)
                        }
                        .settingsAction(.secondary)
                        .disabled(features.availableCount == 0)
                    }
                    .controlSize(.regular)
                }
            }
            if tab == .features {
                featureSections
            } else {
                SettingsSection {
                    PermissionsPortalSections(hub: hub)
                }
            }
        }
        .formStyle(.grouped)

    }

    /// Consumes a pending Feature Hub target: switches off the Permissions
    /// tab if needed and scrolls the requested row into view. Retried once
    /// after the first run-loop turn, the same allowance
    /// `SettingsSectionFocusModifier` gives a freshly installed Form to
    /// register its row identities.
    private func revealPendingFeatureTarget(using proxy: ScrollViewProxy) {
        guard let request = router.pendingFeatureTarget else { return }
        router.consumeFeatureTarget(id: request.id)
        revealID = request.id
        if tab == .permissions { tab = .features }
        DispatchQueue.main.async {
            guard self.revealID == request.id else { return }
            reveal(request.feature.unit, using: proxy)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                guard self.revealID == request.id else { return }
                reveal(request.feature.unit, using: proxy)
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                    guard self.revealID == request.id else { return }
                    clearHighlight()
                }
            }
        }
    }

    private func reveal(_ unit: FeatureUnit, using proxy: ScrollViewProxy) {
        if reduceMotion {
            proxy.scrollTo(unit, anchor: .center)
            highlightedUnit = unit
        } else {
            withAnimation(.easeInOut(duration: 0.3)) {
                proxy.scrollTo(unit, anchor: .center)
                highlightedUnit = unit
            }
        }
    }

    private func clearHighlight() {
        if reduceMotion {
            highlightedUnit = nil
        } else {
            withAnimation(.easeOut(duration: 0.25)) {
                highlightedUnit = nil
            }
        }
    }

    @ViewBuilder
    private var featureSections: some View {
        ForEach(FeatureGroup.allCases, id: \.self) { group in
            SettingsSection {
                ForEach(group.units, id: \.self) { unit in
                    FeatureHubRow(
                        unit: unit,
                        hub: hub,
                        symbolName: unit.symbolName,
                        isHighlighted: highlightedUnit == unit
                    )
                        .id(unit)
                }
                if group == .monitor, !FeatureUnit.monitor.isAvailable {
                    Text(hub.monitorAllOffNote)
                        .font(SettingsTypography.caption)
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text(group.title(hub))
            }
        }
    }
}

// MARK: - Unit row

private struct FeatureHubRow: View {
    @ObservedObject private var l10n = L10n.shared
    @ObservedObject private var features = FeatureRuntime.shared
    let unit: FeatureUnit
    let hub: FeatureHubStrings
    let symbolName: String
    var isHighlighted: Bool = false

    private var installed: Bool { unit.isAvailable }
    private var workspace: ModuleWorkspaceStrings { ModuleWorkspaceStrings(l10n.language) }

    /// Set only while this Mac cannot run the unit and it is not yet
    /// enabled, so availability that predates the check keeps an ordinary
    /// row with its settings and Disable reachable.
    private var unsupportedReason: String? { unit.installBlockedReason }

    private var title: String { unit.title(l10n.s, language: l10n.language) }

    private var description: String {
        unit.hubDescription(hub, l10n.s, language: l10n.language)
    }

    private var accessibilityTitle: String {
        unit.isBeta ? "\(title). \(l10n.s.betaFeatureWarning)" : title
    }

    private var energyLabels: [String] { [unit.energyProfile.label(hub)] }

    private var accessibilitySummary: String {
        ([accessibilityTitle, description] + energyLabels).joined(separator: ". ")
    }

    var body: some View {
        HStack(spacing: 10) {
            if let destination = unit.settingsDestination {
                Button {
                    SettingsRouter.shared.request(destination)
                } label: {
                    rowContent(showsChevron: true)
                }
                .buttonStyle(.plain)
                .accessibilityElement(children: .combine)
                .accessibilityLabel(accessibilitySummary)
                .accessibilityAddTraits(.isLink)
                .accessibilityRemoveTraits(.isButton)
            } else {
                rowContent(showsChevron: false)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(accessibilitySummary)
                    .saturation(unsupportedReason == nil ? 1 : 0)
            }
            SettingsHelpButton(title: title, text: (energyLabels + [hub.energyHelp]).joined(separator: "\n\n"))
            HStack(spacing: 0) {
                Button { flip(to: !installed) } label: {
                    ZStack {
                        Text(workspace.remove).hidden()
                        Text(workspace.add).hidden()
                        Text(installed ? workspace.remove : workspace.add)
                    }
                }
                .settingsAction(installed ? .secondary : .primary)
                .disabled(!installed && unsupportedReason != nil)
                .accessibilityLabel("\(installed ? workspace.remove : workspace.add) \(accessibilityTitle)")
            }
            .help(unsupportedReason ?? "")
        }
        .padding(.vertical, 1)
        .overlay {
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(Color.accentColor.opacity(isHighlighted ? 0.10 : 0))
                .allowsHitTesting(false)
        }
    }

    private func rowContent(showsChevron: Bool) -> some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(installed
                        ? AnyShapeStyle(Theme.spaceGradient)
                        : AnyShapeStyle(Color.secondary.opacity(0.22)))
                .frame(width: 30, height: 30)
                .overlay(
                    Image(systemName: symbolName)
                        .font(SettingsTypography.icon)
                        .foregroundStyle(installed ? AnyShapeStyle(.white) : AnyShapeStyle(.secondary))
                )
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(title)
                        .font(SettingsTypography.body.weight(.medium))
                        .foregroundStyle(.primary)
                        .layoutPriority(1)
                    ForEach(unit.permissions, id: \.self) { permission in
                        Image(systemName: permission.symbolName)
                            .font(SettingsTypography.smallIcon)
                            .foregroundStyle(.secondary)
                            .help(permission.name(hub))
                            .accessibilityHidden(true)
                    }
                    if unit.isBeta {
                        Text(l10n.s.betaBadge)
                            .font(SettingsTypography.caption)
                            .foregroundStyle(Color.white)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(Capsule().fill(Color.accentColor))
                            .accessibilityHidden(true)
                    }
                }
                Text(description)
                    .font(SettingsTypography.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 8)
            if showsChevron {
                Image(systemName: "chevron.forward")
                    .font(SettingsTypography.smallIcon)
                    .foregroundStyle(.tertiary)
                    .accessibilityHidden(true)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 40, alignment: .leading)
        .contentShape(Rectangle())
    }

    private func flip(to install: Bool) {
        FeatureRuntime.shared.setAvailable(unit, install)
    }

}

// MARK: - Permissions portal

struct PermissionsPortalSections: View {
    @ObservedObject private var l10n = L10n.shared
    @ObservedObject private var features = FeatureRuntime.shared
    @ObservedObject private var permissions = Permissions.shared
    let hub: FeatureHubStrings
    let visiblePermissions: [AppPermission]
    @State private var automation: [Permissions.AutomationTarget: Permissions.AutomationStatus] = [:]
    @State private var pollingDemandID = UUID()

    init(hub: FeatureHubStrings,
         visiblePermissions: [AppPermission] = AppPermission.allCases) {
        self.hub = hub
        self.visiblePermissions = visiblePermissions
    }

    var body: some View {
        ForEach(visiblePermissions, id: \.self) { permission in
            PermissionPortalRow(permission: permission,
                                hub: hub,
                                status: status(for: permission))
        }
        .onAppear {
            // Statuses that only refresh at launch/activation get a fresh
            // read the moment the portal shows; automation is checked off the
            // main thread because the AE round trip can block briefly.
            permissions.refresh()
            if visiblePermissions.contains(.accessibility)
                || visiblePermissions.contains(.screenRecording) {
                permissions.setActivePermissionSurface(pollingDemandID, visible: true)
            }
            DispatchQueue.global(qos: .userInitiated).async {
                let finder = Permissions.automationStatus(for: .finder)
                let terminal = Permissions.automationStatus(for: .terminal)
                DispatchQueue.main.async {
                    automation = [.finder: finder, .terminal: terminal]
                }
            }
        }
        .onDisappear {
            permissions.setActivePermissionSurface(pollingDemandID, visible: false)
        }
    }

    private func status(for permission: AppPermission) -> PermissionPortalRow.Status {
        switch permission {
        case .accessibility: return permissions.accessibility ? .granted : .missing
        case .screenRecording: return permissions.screenRecording ? .granted : .missing
        case .fullDiskAccess: return permissions.fullDiskAccess ? .granted : .missing
        case .filesAndFolders:
            guard AppFeature.cleaner.isAvailable,
                  WhatsAppDownloadSupport.isEnabled else {
                return .unknown
            }
            switch WhatsAppDownloadManager.shared.accessStatus {
            case .available: return .granted
            case .denied: return .missing
            case .unknown: return .unknown
            }
        case .notifications:
            switch permissions.notifications {
            case .granted: return .granted
            case .denied, .undetermined: return .missing
            case .unknown: return .unknown
            }
        case .automationFinder: return automationStatus(.finder)
        case .automationTerminal: return automationStatus(.terminal)
        case .audioCapture:
            // No public check exists for system audio capture; the mixer
            // reports a failed tap, which is the one readable signal.
            if AppFeature.mixer.isAvailable, AppVolumeMixer.shared.needsPermission {
                return .missing
            }
            return .unknown
        case .microphone:
            switch permissions.microphone {
            case .granted: return .granted
            case .denied, .undetermined: return .missing
            case .unknown: return .unknown
            }
        case .camera:
            switch permissions.camera {
            case .granted: return .granted
            case .denied, .undetermined: return .missing
            case .unknown: return .unknown
            }
        case .appManagement:
            // macOS has no public preflight API for this permission. The
            // system records the app only after its first protected write.
            return .unknown
        }
    }

    private func automationStatus(_ target: Permissions.AutomationTarget) -> PermissionPortalRow.Status {
        switch automation[target] {
        case .granted: return .granted
        case .denied, .undetermined: return .missing
        case .notDeterminable, .none: return .unknown
        }
    }
}

private struct PermissionPortalRow: View {
    enum Status { case granted, missing, unknown }

    @ObservedObject private var l10n = L10n.shared
    let permission: AppPermission
    let hub: FeatureHubStrings
    let status: Status

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: permission.symbolName)
                .font(SettingsTypography.icon)
                .foregroundStyle(.secondary)
                .frame(width: 24, height: 24)
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(permission.name(hub))
                        .fontWeight(.medium)
                    statusChip
                }
                Text(permission.explainer(hub))
                    .font(SettingsTypography.caption)
                    .foregroundStyle(.secondary)
                Text(usedByLine)
                    .font(SettingsTypography.caption)
                    .foregroundStyle(.tertiary)
                if status == .granted, activeFeatures.isEmpty {
                    unusedCard
                }
                HStack(spacing: 8) {
                    if status != .granted, hasRequestFlow {
                        Button(hub.requestButton) { request() }
                    }
                    Button(hub.openSystemSettings) { openSystemSettings() }
                }
                .controlSize(.regular)
                .padding(.top, 2)
            }
        }
        .padding(.vertical, 3)
        .accessibilityElement(children: .combine)
    }

    private var activeFeatures: [AppFeature] {
        AppFeature.activeFeatures(using: permission).filter {
            permission != .notifications || $0 != .monitorPower || PowerSampler.hasInternalBattery
        }
    }

    private var usedByLine: String {
        let names = activeFeatures.map { $0.name(l10n.s, language: l10n.language) }
        guard !names.isEmpty else { return hub.usedByNone }
        return String(format: hub.usedByFormat, names.joined(separator: ", "))
    }

    private var statusChip: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(chipColor)
                .frame(width: 6, height: 6)
            Text(chipText)
                .font(SettingsTypography.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var chipColor: Color {
        switch status {
        case .granted: return .green
        case .missing: return .orange
        case .unknown: return .secondary
        }
    }

    private var chipText: String {
        switch status {
        case .granted: return hub.statusGranted
        case .missing: return hub.statusMissing
        case .unknown: return hub.statusUnknown
        }
    }

    private var unusedCard: some View {
        Text(hub.unusedBanner)
            .font(SettingsTypography.caption)
            .foregroundStyle(.secondary)
            .padding(8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(Color.primary.opacity(0.05))
            )
    }

    private var hasRequestFlow: Bool {
        switch permission {
        case .accessibility, .screenRecording, .fullDiskAccess: return true
        case .notifications: return Permissions.shared.notifications == .undetermined
        case .microphone: return Permissions.shared.microphone == .undetermined
        case .camera: return Permissions.shared.camera == .undetermined
        case .filesAndFolders, .automationFinder, .automationTerminal, .audioCapture,
             .appManagement: return false
        }
    }

    private func request() {
        switch permission {
        case .accessibility: Permissions.shared.requestAccessibility()
        case .screenRecording: Permissions.shared.requestScreenRecording()
        case .fullDiskAccess: Permissions.shared.requestFullDiskAccess()
        case .notifications:
            Notifier.requestPermission()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                Permissions.shared.refresh()
            }
        case .microphone: Permissions.shared.requestMicrophone()
        case .camera: Permissions.shared.requestCamera()
        case .filesAndFolders, .automationFinder, .automationTerminal, .audioCapture,
             .appManagement:
            break
        }
    }

    private func openSystemSettings() {
        switch permission {
        case .accessibility: Permissions.shared.openAccessibilitySettings()
        case .screenRecording: Permissions.shared.openScreenRecordingSettings()
        case .fullDiskAccess: Permissions.shared.openFullDiskAccessSettings()
        case .filesAndFolders: Permissions.shared.openFilesAndFoldersSettings()
        case .notifications: Permissions.shared.openNotificationSettings()
        case .automationFinder, .automationTerminal: Permissions.shared.openAutomationSettings()
        case .audioCapture: Permissions.shared.openAudioCaptureSettings()
        case .microphone: Permissions.shared.openMicrophoneSettings()
        case .camera: Permissions.shared.openCameraSettings()
        case .appManagement: Permissions.shared.openAppManagementSettings()
        }
    }
}

// MARK: - Descriptions and permission names

extension FeatureUnit {
    /// A lone feature keeps its hub description; a unit with several lists
    /// their names, so no new string is needed.
    func hubDescription(_ hub: FeatureHubStrings, _ s: Strings, language: AppLanguage) -> String {
        features.count == 1
            ? features[0].hubDescription(hub)
            : features.map { $0.name(s, language: language) }.joined(separator: " · ")
    }
}

extension AppFeature {
    func hubDescription(_ hub: FeatureHubStrings) -> String {
        switch self {
        case .switcher: return hub.descSwitcher
        case .dockPreview: return hub.descDockPreview
        case .dockClick: return hub.descDockClick
        case .windowMaximizer: return hub.descWindowMaximizer
        case .autoQuit: return hub.descAutoQuit
        case .quitWindowProtection: return FeatureStrings.quitProtection(L10n.shared.language).description
        case .scrollInverter: return hub.descScrollInverter
        case .scrollHorizontal: return L10n.shared.s.scrollHorizontalCaption
        case .focusFollowsMouse: return L10n.shared.s.focusFollowsMouseCaption
        case .smoothScroll: return hub.descSmoothScroll
        case .mouseAcceleration: return L10n.shared.s.mouseAccelerationCaption
        case .mouseNavigation: return hub.descMouseNavigation
        case .mouseButtonShortcuts: return FeatureStrings.mouseButtons(L10n.shared.language).hubDescription
        case .middleClick: return hub.descMiddleClick
        case .keyboardDebounce: return hub.descKeyboardDebounce
        case .textSnippets: return FeatureStrings.snippets(L10n.shared.language).hubDescription
        case .superKey: return FeatureStrings.superKey(L10n.shared.language).hubDescription
        case .mouseClickDebounce:
            return FeatureStrings.mouseClickDebounce(L10n.shared.language).caption
        case .clipboardHistory: return hub.descClipboardHistory
        case .pastePlain: return hub.descPastePlain
        case .finderCutPaste: return hub.descFinderCutPaste
        case .finderRename: return FeatureStrings.finderRename(L10n.shared.language).hubDescription
        case .shelf: return hub.descShelf
        case .urlCleaner: return hub.descURLCleaner
        case .mixer: return hub.descMixer
        case .soundOutputSwitcher: return hub.descSoundOutputSwitcher
        case .micMute: return hub.descMicMute
        case .musicBlock: return hub.descMusicBlock
        case .keepAwake: return hub.descKeepAwake
        case .brightness: return FeatureStrings.brightness(L10n.shared.language).hubDescription
        case .bluetoothSleep: return FeatureStrings.bluetoothSleep(L10n.shared.language).hubDescription
        case .colorPicker: return hub.descColorPicker
        case .screenOCR: return hub.descScreenOCR
        case .screenshot: return FeatureStrings.screenshot(L10n.shared.language).hubDescription
        case .screenRecorder: return FeatureStrings.recorder(L10n.shared.language).hubDescription
        case .radialMenu: return FeatureStrings.radialMenu(L10n.shared.language).hubDescription
        case .scratchpad: return FeatureStrings.scratchpad(L10n.shared.language).hubDescription
        case .commandBar: return FeatureStrings.commandBar(L10n.shared.language).hubDescription
        case .cleaningMode: return hub.descCleaningMode
        case .mediaTools: return hub.descMediaTools
        case .cleaner:
            let description = hub.descCleaner
            guard WhatsAppDownloadSupport.isEnabled else {
                return description
            }
            return description + " · "
                + FeatureStrings.whatsAppDownloads(L10n.shared.language).hubDescription
        case .uninstaller: return hub.descUninstaller
        case .homebrew: return hub.descHomebrew
        case .environment: return FeatureStrings.environment(L10n.shared.language).hubDescription
        case .killProcess: return FeatureStrings.killProcess(L10n.shared.language).hubDescription
        case .cameraPreview: return FeatureStrings.cameraPreview(L10n.shared.language).hubDescription
        case .monitorCPU: return hub.descMonitorCPU
        case .monitorGPU: return hub.descMonitorGPU
        case .monitorMemory: return hub.descMonitorMemory
        case .monitorNetwork: return hub.descMonitorNetwork
        case .monitorDisk: return hub.descMonitorDisk
        case .monitorPower: return hub.descMonitorPower
        case .fanControl: return FeatureStrings.fanControl(L10n.shared.language).hubDescription
        }
    }
}

extension AppPermission {
    func name(_ hub: FeatureHubStrings) -> String {
        switch self {
        case .accessibility: return hub.permAccessibility
        case .screenRecording: return hub.permScreenRecording
        case .fullDiskAccess: return hub.permFullDisk
        case .filesAndFolders: return hub.permFilesAndFolders
        case .notifications: return hub.permNotifications
        case .automationFinder: return hub.permAutomationFinder
        case .automationTerminal: return hub.permAutomationTerminal
        case .audioCapture: return hub.permAudioCapture
        case .microphone: return FeatureStrings.recorder(L10n.shared.language).microphonePermissionName
        case .camera: return FeatureStrings.cameraPreview(L10n.shared.language).permName
        case .appManagement: return hub.groupAppManagement
        }
    }

    func explainer(_ hub: FeatureHubStrings) -> String {
        switch self {
        case .accessibility: return hub.explainAccessibility
        case .screenRecording: return hub.explainScreenRecording
        case .fullDiskAccess: return hub.explainFullDisk
        case .filesAndFolders: return hub.explainFilesAndFolders
        case .notifications: return hub.explainNotifications
        case .automationFinder: return hub.explainAutomationFinder
        case .automationTerminal: return hub.explainAutomationTerminal
        case .audioCapture: return hub.explainAudioCapture
        case .microphone:
            return FeatureStrings.recorder(L10n.shared.language).microphonePermissionExplain
        case .camera: return FeatureStrings.cameraPreview(L10n.shared.language).permExplain
        case .appManagement: return hub.explainAppManagement
        }
    }
}

struct FeatureSwitchRow: View {
    @ObservedObject private var l10n = L10n.shared
    @ObservedObject private var features = FeatureRuntime.shared
    let feature: AppFeature
    var title: String? = nil
    var help: String? = nil

    /// The mouse page asked for Accessibility the moment one of these
    /// went on; the other members show a permission row instead.
    private static let asksAccessibility: Set<AppFeature> = [
        .scrollInverter, .scrollHorizontal, .focusFollowsMouse, .smoothScroll, .mouseNavigation,
        .mouseButtonShortcuts, .mouseClickDebounce,
    ]

    var body: some View {
        let blocked = feature.installBlockedReason
        let name = title ?? feature.name(l10n.s, language: l10n.language)
        let binding = Binding(
            get: { feature.pageSwitchKey.map { UserDefaults.standard.bool(forKey: $0) } ?? feature.isAvailable },
            set: { on in
                FeatureRuntime.shared.setSwitch(feature, on)
                if on, Self.asksAccessibility.contains(feature) {
                    Permissions.shared.requestAccessibility()
                }
            }
        )
        VStack(alignment: .leading, spacing: 5) {
          Group {
            if feature.pageSwitchKey != nil {
                Toggle(isOn: binding) {
                    HStack(spacing: 12) {
                        SettingsSymbol(systemImage: feature.symbolName)
                        Text(name).font(SettingsTypography.body.weight(.semibold))
                        ForEach(feature.permissions, id: \.self) { permission in
                            Image(systemName: permission.symbolName)
                                .foregroundStyle(.secondary)
                                .help(permission.name(FeatureStrings.hub(l10n.language)))
                        }
                        if let help { SettingsHelpButton(title: name, text: help) }
                        Spacer(minLength: 8)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .toggleStyle(.switch).controlSize(.regular)
                .disabled(blocked != nil)
            } else {
                HStack(spacing: 12) {
                    SettingsSymbol(systemImage: feature.symbolName)
                    Text(name).font(SettingsTypography.body.weight(.semibold))
                    Spacer(minLength: 8)
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.accentColor)
                        .accessibilityHidden(true)
                }
            }
        }
          .opacity(blocked == nil ? 1 : 0.55)
          if let blocked {
              Text(blocked)
                  .font(SettingsTypography.caption)
                  .foregroundStyle(.secondary)
                  .fixedSize(horizontal: false, vertical: true)
                  .padding(.leading, 42)
          }
        }
        .frame(maxWidth: .infinity, minHeight: 40, alignment: .leading)
        .help(blocked ?? "")
    }
}

/// Reads preferences only. Opening an inactive module must not instantiate its
/// services, load private history, request permission, or register shortcuts.
struct SavedModuleConfigurationView: View {
    @ObservedObject private var l10n = L10n.shared
    let unit: FeatureUnit
    private var text: ModuleWorkspaceStrings { ModuleWorkspaceStrings(l10n.language) }
    private var shortcuts: [GlobalShortcutRole] {
        GlobalShortcutRole.allCases.filter { $0.feature.unit == unit }
    }

    var body: some View {
        SettingsForm {
            SettingsSection {
                Label(text.inactiveTitle, systemImage: "pause.circle")
                    .font(SettingsTypography.sectionTitle)
                Text(text.inactiveNote)
                    .fixedSize(horizontal: false, vertical: true)
                Button { FeatureRuntime.shared.setAvailable(unit, true) } label: {
                    Label(text.add, systemImage: "plus.circle")
                }
                .settingsAction(.primary)
                .disabled(unit.installBlockedReason != nil)
                if let reason = unit.installBlockedReason {
                    Text(reason).fixedSize(horizontal: false, vertical: true)
                }
            }
            SettingsSection(text.savedBehaviors) {
                ForEach(unit.features, id: \.self) { feature in
                    LabeledContent(feature.name(l10n.s, language: l10n.language)) {
                        Text(savedBehavior(feature)).foregroundStyle(.secondary)
                    }
                }
            }
            if !shortcuts.isEmpty {
                SettingsSection(text.savedShortcuts) {
                    ForEach(shortcuts) { role in
                        LabeledContent(role.title(l10n.s)) {
                            Text(role.savedShortcut.displayString)
                                .font(SettingsTypography.body.monospaced())
                                .textSelection(.enabled)
                        }
                    }
                }
            }
        }
        .formStyle(.grouped)
    }

    private func savedBehavior(_ feature: AppFeature) -> String {
        var keys = feature.enabledKeys
        if let key = feature.switchKey, !keys.contains(key) { keys.append(key) }
        guard !keys.isEmpty else { return text.noSeparateSwitch }
        let enabled = keys.filter { UserDefaults.standard.bool(forKey: $0) }.count
        return keys.count == 1 ? (enabled == 1 ? text.on : text.off) : text.actionCount(enabled, keys.count)
    }
}
