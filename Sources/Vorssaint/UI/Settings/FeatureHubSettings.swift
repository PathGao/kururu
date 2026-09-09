// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import SwiftUI

/// The Features hub. One tile per unit, grouped in plain language: off
/// means the unit disappears from the whole app (Settings, panel, menu
/// bar, shortcuts) and costs nothing; its configuration is kept for its
/// return. The Permissions tab is the transparency portal: what each system
/// permission does, which features use it right now, and a gentle nudge when
/// one is granted with nothing using it.
struct FeatureHubSettings: View {
    @ObservedObject private var l10n = L10n.shared
    @ObservedObject private var features = FeatureRuntime.shared
    @ObservedObject private var router = SettingsRouter.shared
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var tab: Tab = .features
    @State private var confirmingPreset: FeaturePreset?
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

    var body: some View {
        ScrollViewReader { proxy in
            content
                .onAppear { revealPendingFeatureTarget(using: proxy) }
                .onChange(of: router.requestID) { _, _ in revealPendingFeatureTarget(using: proxy) }
        }
    }

    private var content: some View {
        Form {
            Section {
                Picker("", selection: $tab) {
                    Text(hub.tabFeatures).tag(Tab.features)
                    Text(hub.tabPermissions).tag(Tab.permissions)
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                Text(tab == .features ? hub.intro : hub.permissionsIntro)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if tab == .features {
                    HStack(spacing: 8) {
                        Text(String(format: hub.activeCountFormat,
                                    features.availableCount, features.installableCount))
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                        Spacer(minLength: 8)
                        Button(hub.installAllButton) {
                            FeatureRuntime.shared.setAllAvailable(true)
                        }
                        .disabled(features.availableCount == features.installableCount)
                        Button(hub.uninstallAllButton) {
                            FeatureRuntime.shared.setAllAvailable(false)
                        }
                        .disabled(features.availableCount == 0)
                    }
                    .controlSize(.small)
                }
            }
            // The restart notice lives at the very top, never behind a
            // scroll: uninstalling anything makes it impossible to miss.
            if features.needsRestartToUnload {
                Section {
                    HStack(spacing: 10) {
                        Image(systemName: "arrow.clockwise.circle.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(Color.accentColor)
                        Text(hub.restartNote)
                            .font(.callout)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: 10)
                        Button(hub.restartButton) {
                            FeatureRuntime.shared.relaunchApp()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding(.vertical, 4)
                    .listRowBackground(Color.accentColor.opacity(0.12))
                }
            }
            if tab == .features {
                presetsSection
                featureSections
            } else {
                Section {
                    PermissionsPortalSections(hub: hub)
                }
            }
        }
        .formStyle(.grouped)
        .alert(confirmingPreset.map { presetName($0) } ?? "",
               isPresented: Binding(get: { confirmingPreset != nil },
                                    set: { if !$0 { confirmingPreset = nil } }),
               presenting: confirmingPreset) { preset in
            Button(hub.presetConfirmApply) {
                withAnimation(.easeOut(duration: 0.22)) {
                    FeatureRuntime.shared.apply(preset)
                }
            }
            Button(hub.presetConfirmCancel, role: .cancel) {}
        } message: { preset in
            Text(String(format: hub.presetConfirmFormat, presetName(preset)))
        }
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

    /// Three one-click starting points. Nobody arrives wanting 37 decisions;
    /// a preset shapes the app in one move and everything else stays one
    /// click away in the list below.
    private var presetsSection: some View {
        Section {
            HStack(alignment: .top, spacing: 8) {
                ForEach(FeaturePreset.allCases) { preset in
                    PresetCard(preset: preset,
                               name: presetName(preset),
                               caption: presetDescription(preset),
                               applyTitle: hub.presetApplyButton) {
                        confirmingPreset = preset
                    }
                }
            }
            .padding(.vertical, 2)
        } header: {
            Text(hub.presetsTitle)
        } footer: {
            Text(hub.presetsCaption)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func presetName(_ preset: FeaturePreset) -> String {
        switch preset {
        case .essential: return hub.presetEssentialName
        case .windows: return hub.presetWindowsName
        case .battery: return hub.presetBatteryName
        }
    }

    private func presetDescription(_ preset: FeaturePreset) -> String {
        switch preset {
        case .essential: return hub.presetEssentialDesc
        case .windows: return hub.presetWindowsDesc
        case .battery: return hub.presetBatteryDesc
        }
    }

    @ViewBuilder
    private var featureSections: some View {
        ForEach(FeatureGroup.allCases, id: \.self) { group in
            Section {
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
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text(group.title(hub))
            }
        }
        Section {
            Text(hub.footerNote)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Preset card

private struct PresetCard: View {
    let preset: FeaturePreset
    let name: String
    let caption: String
    let applyTitle: String
    let onApply: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: preset.symbolName)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.accentColor)
                Text(name)
                    .font(.system(size: 12, weight: .semibold))
                    .lineLimit(1)
            }
            Text(caption)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
            Spacer(minLength: 0)
            Button(applyTitle, action: onApply)
                .buttonStyle(.bordered)
                .controlSize(.small)
        }
        .padding(9)
        .frame(maxWidth: .infinity, minHeight: 96, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.secondary.opacity(0.08))
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(name). \(caption)")
    }
}

// MARK: - Unit row

private struct FeatureHubRow: View {
    @ObservedObject private var l10n = L10n.shared
    @ObservedObject private var features = FeatureRuntime.shared
    @State private var working = false
    let unit: FeatureUnit
    let hub: FeatureHubStrings
    let symbolName: String
    var isHighlighted: Bool = false

    private var installed: Bool { unit.isAvailable }

    /// Set only while this Mac cannot run the unit and it is not yet
    /// installed, so an install that predates the check keeps an ordinary
    /// row with its settings and Uninstall reachable.
    private var unsupportedReason: String? { unit.installBlockedReason }

    private var title: String { unit.title(l10n.s, language: l10n.language) }

    private var description: String {
        unit.hubDescription(hub, l10n.s, language: l10n.language)
    }

    private var accessibilityTitle: String {
        unit.isBeta ? "\(title). \(l10n.s.betaFeatureWarning)" : title
    }

    private var energyLabels: [String] { [unit.energyProfile.label(hub)] }

    var body: some View {
        HStack(spacing: 10) {
            if installed, let destination = unit.settingsDestination {
                Button {
                    SettingsRouter.shared.request(destination)
                } label: {
                    rowContent(showsChevron: true)
                }
                .buttonStyle(.plain)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(accessibilityTitle). \(description)")
                .accessibilityAddTraits(.isLink)
                .accessibilityRemoveTraits(.isButton)
            } else {
                rowContent(showsChevron: false)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(accessibilityTitle). \(description)")
                    .opacity(unsupportedReason == nil ? 1 : 0.4)
                    .saturation(unsupportedReason == nil ? 1 : 0)
            }
            if working {
                ProgressView()
                    .controlSize(.small)
            } else if installed {
                Button(hub.uninstallButton) { flip(to: false) }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .accessibilityLabel("\(hub.uninstallButton) \(accessibilityTitle)")
            } else if let reason = unsupportedReason {
                // .help() never fires on a disabled control, so the tooltip
                // has to sit on this wrapper. Flattening it loses the only
                // place the reason is shown.
                HStack(spacing: 0) {
                    Button(hub.installButton) { flip(to: true) }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .disabled(true)
                        .accessibilityLabel("\(hub.installButton) \(accessibilityTitle). \(reason)")
                }
                .help(reason)
            } else {
                Button(hub.installButton) { flip(to: true) }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    .accessibilityLabel("\(hub.installButton) \(accessibilityTitle)")
            }
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
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(installed ? AnyShapeStyle(.white) : AnyShapeStyle(.secondary))
                )
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(title)
                        .foregroundStyle(installed ? AnyShapeStyle(.primary) : AnyShapeStyle(.secondary))
                    if unit.isBeta {
                        Text(l10n.s.betaBadge)
                            .font(.system(size: 8, weight: .bold))
                            .foregroundStyle(Color.white)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(Capsule().fill(Color.accentColor))
                            .accessibilityHidden(true)
                    }
                    ForEach(unit.permissions, id: \.self) { permission in
                        Image(systemName: permission.symbolName)
                            .font(.system(size: 9))
                            .foregroundStyle(.tertiary)
                            .help(permission.name(hub))
                            .accessibilityHidden(true)
                    }
                    ForEach(energyLabels, id: \.self) { label in
                        Text(label)
                            .font(.system(size: 9))
                            .foregroundStyle(.tertiary)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(Capsule().fill(Color.secondary.opacity(0.12)))
                            .help(hub.energyHelp)
                            .accessibilityHidden(true)
                    }
                }
                Text(description)
                    .font(.caption)
                    .foregroundStyle(installed ? Color.secondary : Color.secondary.opacity(0.6))
            }
            Spacer(minLength: 8)
            if showsChevron {
                Image(systemName: "chevron.forward")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.tertiary)
                    .accessibilityHidden(true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }

    /// A quick, honest beat of feedback: the spinner shows the action landed,
    /// then the row fades to its new state. The flip itself is instant.
    private func flip(to install: Bool) {
        guard !working else { return }
        working = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
            withAnimation(.easeOut(duration: 0.22)) {
                FeatureRuntime.shared.setAvailable(unit, install)
            }
            working = false
        }
    }
}

// MARK: - Member switches

/// One row per member of the unit at the top of its page: the switch that
/// turns the member on (`AppFeature.pageSwitchKey`) and what it costs once
/// on. A member's own switch off is the old per-feature uninstall: the
/// feature leaves every surface and its service tears down; only its row
/// here stays, so it can come back. An enable key off is the member's block
/// waiting below.
struct FeatureSwitchSection: View {
    let unit: FeatureUnit

    var body: some View {
        Section {
            ForEach(unit.features, id: \.self) { feature in
                SwitchRow(feature: feature)
            }
        }
    }

    private struct SwitchRow: View {
        @ObservedObject private var l10n = L10n.shared
        @ObservedObject private var features = FeatureRuntime.shared
        let feature: AppFeature

        /// The mouse page asked for Accessibility the moment one of these
        /// went on; the other members show a permission row instead.
        private static let asksAccessibility: Set<AppFeature> = [
            .scrollInverter, .focusFollowsMouse, .smoothScroll, .mouseNavigation,
            .mouseButtonShortcuts, .mouseClickDebounce,
        ]

        var body: some View {
            let blocked = feature.installBlockedReason
            // .help() never fires on a disabled control, so the tooltip sits
            // on this wrapper, as the hub row does it.
            HStack(spacing: 8) {
                Toggle(feature.name(l10n.s, language: l10n.language), isOn: Binding(
                    get: { feature.pageSwitchKey.map { UserDefaults.standard.bool(forKey: $0) } ?? false },
                    set: { on in
                        FeatureRuntime.shared.setSwitch(feature, on)
                        if on, Self.asksAccessibility.contains(feature) {
                            Permissions.shared.requestAccessibility()
                        }
                    }
                ))
                .disabled(blocked != nil)
                Text(feature.energyProfile.label(FeatureStrings.hub(l10n.language)))
                    .font(.system(size: 9))
                    .foregroundStyle(.tertiary)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 1)
                    .background(Capsule().fill(Color.secondary.opacity(0.12)))
                    .help(FeatureStrings.hub(l10n.language).energyHelp)
            }
            .help(blocked ?? "")
        }
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
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.secondary)
                .frame(width: 24, height: 24)
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(permission.name(hub))
                        .fontWeight(.medium)
                    statusChip
                }
                Text(permission.explainer(hub))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(usedByLine)
                    .font(.caption)
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
                .controlSize(.small)
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
                .font(.caption)
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
            .font(.caption)
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
        case .appManagement: return hub.explainAppManagement
        }
    }
}
