// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import AppKit
import SwiftUI

/// Per-app volume sliders, the mixer macOS never shipped. Shows every app
/// holding an audio connection (a green dot marks the ones playing right now).
/// 100% is untouched passthrough; below it attenuates and above it (up to 200%)
/// boosts, with the slider and percentage turning amber in the boost range.
struct MixerSection: View {
    @ObservedObject private var l10n = L10n.shared
    @ObservedObject private var mixer = AppVolumeMixer.shared
    @ObservedObject private var inputManager = AudioInputDeviceManager.shared
    @ObservedObject private var outputSwitcher = SoundOutputSwitcher.shared
    @AppStorage(DefaultsKey.mixerHideInactiveApps)
    private var hideInactiveApps = false
    @AppStorage(DefaultsKey.soundOutputSwitcherEnabled)
    private var soundOutputSwitcherEnabled = false
    @State private var soundOutputSwitcherUIDs: [String] = []
    @State private var showListChooser = false
    @State private var optionsExpanded = false
    @State private var normalSliderTint = Color(nsColor: .controlAccentColor)
    @State private var accentRevision = 0
    @State private var lastResolvedAccent: NSColor?
    @State private var editingVolumeID: String?
    var collapsible = true

    private var mixerText: MixerFeatureStrings { FeatureStrings.mixer(l10n.language) }
    private var switcherText: SoundOutputSwitcherFeatureStrings {
        FeatureStrings.soundOutputSwitcher(l10n.language)
    }

    var body: some View {
        PanelSection(.mixer, title: AppFeature.mixer.name(l10n.s, language: l10n.language), collapsible: collapsible) {
            VStack(alignment: .leading, spacing: 8) {
                audioDevicesSection

                if AppVolumeMixer.isSupported, (!visibleApps.isEmpty || mixer.needsPermission) {
                    Divider()
                }

                if !AppVolumeMixer.isSupported {
                    emptyLabel(mixerText.unavailable)
                } else if mixer.needsPermission {
                    permissionHint
                } else if visibleApps.isEmpty {
                    emptyLabel(mixerText.empty)
                } else {
                    mixerRows
                }

                if showsSwitcherDevices || showsListChooser {
                    Divider()
                    optionsDisclosure
                }
            }
            .panelCard()
        }
        .onReceive(NSApplication.shared.publisher(for: \.effectiveAppearance, options: [.new])) { _ in
            refreshSliderTint()
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("NSSystemColorsDidChangeNotification"))) { _ in
            refreshSliderTint()
        }
        .onAppear {
            soundOutputSwitcherUIDs = SoundOutputSwitcher.shared.selectedDeviceUIDs()
        }
    }

    private var audioDevicesSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            universalOutputPicker
            systemSoundOutputPicker
            microphonePicker
            if let outputSwitchError = mixer.outputSwitchError {
                inputMessage(String(format: mixerText.systemOutputErrorFormat, outputSwitchError),
                             systemImage: "exclamationmark.triangle")
            }
        }
    }

    /// The lists whose members are live things (outputs plugged in now, apps
    /// running now) stay in the panel; the lasting switches sit on the mixer
    /// settings page.
    private var showsSwitcherDevices: Bool {
        AppFeature.soundOutputSwitcher.isAvailable && soundOutputSwitcherEnabled
    }

    private var showsListChooser: Bool {
        AppVolumeMixer.isSupported && !listChoices.isEmpty
    }

    private var optionsDisclosure: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                optionsExpanded.toggle()
            } label: {
                HStack(spacing: 7) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.secondary)
                        .frame(width: 12)
                        .rotationEffect(.degrees(optionsExpanded ? 90 : 0))
                    Text(l10n.s.keepAwakeOptions)
                        .font(PanelTypography.title)
                        .foregroundStyle(.secondary)
                    Spacer(minLength: 0)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if optionsExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    if showsSwitcherDevices {
                        soundOutputSwitcherDevices
                    }
                    if showsListChooser {
                        listVisibilityFooter
                    }
                }
                .padding(.leading, 19)
            }
        }
    }

    private var universalOutputPicker: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Label {
                    Text(mixerText.systemOutputTitle)
                        .font(PanelTypography.title)
                } icon: {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(PanelTypography.meta)
                }
                .foregroundStyle(.secondary)

                Spacer(minLength: 6)

                Picker(mixerText.systemOutputTooltip, selection: universalOutputSelectionBinding) {
                    if mixer.currentOutputDeviceUID == nil {
                        Text(mixerText.outputUnavailable)
                            .tag(MixerRoutingSupport.systemDefaultSelectionID)
                    }
                    ForEach(universalOutputDevices) { device in
                        Text(outputDeviceTitle(device))
                            .tag(device.uid)
                    }
                    if let selected = mixer.currentOutputDeviceUID,
                       !universalOutputDevices.contains(where: { $0.uid == selected }) {
                        Text(mixerText.outputUnavailable)
                            .tag(selected)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
                .controlSize(.small)
                .frame(width: 164)
                .disabled(universalOutputDevices.isEmpty)
                .help(mixerText.systemOutputTooltip)
            }

            if let volume = mixer.systemOutputVolume {
                HStack(spacing: 8) {
                    Image(systemName: mixer.systemOutputMuted == true || volume <= 0.001
                          ? "speaker.slash.fill"
                          : "speaker.wave.2.fill")
                        .font(PanelTypography.meta)
                        .foregroundStyle(.secondary)
                        .frame(width: 16)

                    MixerVolumeSlider(value: systemOutputVolumeBinding,
                                      normalTint: normalSliderTint,
                                      boostTint: normalSliderTint,
                                      isBoosting: false,
                                      accentRevision: accentRevision,
                                      maximum: 1,
                                      accessibilityLabel: mixerText.systemOutputTitle)

                    EditableVolumePercent(currentPercent: Int((volume * 100).rounded()),
                                          maximumPercent: 100,
                                          width: 36,
                                          editorID: "system-output",
                                          editingID: $editingVolumeID,
                                          accessibilityLabel: mixerText.systemOutputTitle) {
                        Text("\(Int((volume * 100).rounded()))%")
                            .font(PanelTypography.meta)
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    } onCommit: {
                        mixer.setCurrentOutputVolume($0)
                    }
                }
            }

            if universalOutputDevices.isEmpty {
                inputMessage(mixerText.systemOutputNoDevices, systemImage: "speaker.slash")
            }
        }
    }

    private var systemSoundOutputPicker: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Label {
                    Text(mixerText.soundEffectsOutputTitle)
                        .font(PanelTypography.title)
                } icon: {
                    Image(systemName: "bell.fill")
                        .font(PanelTypography.meta)
                }
                .foregroundStyle(.secondary)

                Spacer(minLength: 6)

                Picker(mixerText.soundEffectsOutputTooltip,
                       selection: systemSoundOutputSelectionBinding) {
                    if mixer.currentSystemSoundOutputDeviceUID == nil {
                        Text(mixerText.outputUnavailable)
                            .tag(MixerRoutingSupport.systemDefaultSelectionID)
                    }
                    ForEach(systemSoundOutputDevices) { device in
                        Text(systemSoundOutputDeviceTitle(device))
                            .tag(device.uid)
                    }
                    if let selected = mixer.currentSystemSoundOutputDeviceUID,
                       !systemSoundOutputDevices.contains(where: { $0.uid == selected }) {
                        Text(mixerText.outputUnavailable)
                            .tag(selected)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
                .controlSize(.small)
                .frame(width: 164)
                .disabled(systemSoundOutputDevices.isEmpty)
                .help(mixerText.soundEffectsOutputTooltip)
            }

            if systemSoundOutputDevices.isEmpty {
                inputMessage(mixerText.systemOutputNoDevices, systemImage: "bell.slash")
            }
        }
    }

    private var universalOutputDevices: [MixerOutputDevice] {
        mixer.outputDevices.filter(\.canBeDefaultOutput)
    }

    private var systemSoundOutputDevices: [MixerOutputDevice] {
        mixer.outputDevices.filter(\.canBeDefaultSystemOutput)
    }

    private var universalOutputSelectionBinding: Binding<String> {
        Binding(
            get: { mixer.currentOutputDeviceUID ?? MixerRoutingSupport.systemDefaultSelectionID },
            set: { selection in
                guard selection != MixerRoutingSupport.systemDefaultSelectionID else { return }
                mixer.setUniversalOutputDeviceUID(selection)
            }
        )
    }

    private var systemOutputVolumeBinding: Binding<Double> {
        Binding(
            get: { mixer.systemOutputVolume ?? 0 },
            set: { mixer.setCurrentOutputVolume($0) }
        )
    }

    private var systemSoundOutputSelectionBinding: Binding<String> {
        Binding(
            get: {
                mixer.currentSystemSoundOutputDeviceUID
                    ?? MixerRoutingSupport.systemDefaultSelectionID
            },
            set: { selection in
                guard selection != MixerRoutingSupport.systemDefaultSelectionID else { return }
                mixer.setSystemSoundOutputDeviceUID(selection)
            }
        )
    }

    private var soundOutputSwitcherDevices: some View {
        VStack(alignment: .leading, spacing: 4) {
            if outputSwitcher.lastSwitchFailed {
                inputMessage(switcherText.noAvailableSelection,
                             systemImage: "speaker.badge.exclamationmark")
            }

            Text(switcherText.devices)
                .font(PanelTypography.meta)
                .foregroundStyle(.secondary)

            if universalOutputDevices.isEmpty {
                inputMessage(mixerText.systemOutputNoDevices, systemImage: "speaker.slash")
            } else {
                ForEach(universalOutputDevices) { device in
                    Toggle(isOn: soundOutputSwitcherSelectionBinding(for: device.uid)) {
                        Text(outputDeviceTitle(device))
                            .font(PanelTypography.meta)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                    .toggleStyle(.checkbox)
                    .controlSize(.small)
                }
            }
        }
    }

    private func soundOutputSwitcherSelectionBinding(for uid: String) -> Binding<Bool> {
        Binding(
            get: { soundOutputSwitcherUIDs.contains(uid) },
            set: { selected in
                var next = soundOutputSwitcherUIDs
                if selected {
                    if !next.contains(uid) { next.append(uid) }
                } else {
                    next.removeAll { $0 == uid }
                }
                let visibleOrder = universalOutputDevices.map(\.uid)
                let visible = visibleOrder.filter { next.contains($0) }
                let unavailable = next.filter { !visibleOrder.contains($0) }
                setSoundOutputSwitcherUIDs(visible + unavailable)
            }
        )
    }

    private func setSoundOutputSwitcherUIDs(_ uids: [String]) {
        let sanitized = Defaults.sanitizedSoundOutputSwitcherDeviceUIDs(uids)
        soundOutputSwitcherUIDs = sanitized
        SoundOutputSwitcher.shared.setSelectedDeviceUIDs(sanitized)
    }

    private var microphonePicker: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Label {
                    Text(mixerText.inputTitle)
                        .font(PanelTypography.title)
                } icon: {
                    Image(systemName: "mic.fill")
                        .font(PanelTypography.meta)
                }
                .foregroundStyle(.secondary)

                Spacer(minLength: 6)

                Picker(mixerText.inputTooltip, selection: inputSelectionBinding) {
                    Text(mixerText.outputDefault)
                        .tag(MixerRoutingSupport.systemDefaultSelectionID)
                    ForEach(inputManager.inputDevices) { device in
                        Text(inputDeviceTitle(device))
                            .tag(device.uid)
                    }
                    if let selected = inputManager.preferredInputDeviceUID,
                       inputManager.preferredUnavailable {
                        Text(mixerText.inputUnavailable)
                            .tag(selected)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
                .controlSize(.small)
                .frame(width: 164)
                .disabled(inputManager.inputDevices.isEmpty)
                .help(mixerText.inputTooltip)
            }

            if inputManager.inputDevices.isEmpty {
                inputMessage(mixerText.inputNoDevices, systemImage: "mic.slash")
            } else if inputManager.preferredUnavailable {
                inputMessage(mixerText.inputFallback, systemImage: "mic.badge.xmark")
            } else if let lastError = inputManager.lastError {
                inputMessage(String(format: mixerText.inputErrorFormat, lastError),
                             systemImage: "exclamationmark.triangle")
            }
        }
    }

    private var inputSelectionBinding: Binding<String> {
        Binding(
            get: { inputManager.preferredInputDeviceUID ?? MixerRoutingSupport.systemDefaultSelectionID },
            set: { selection in
                inputManager.setPreferredInputDeviceUID(
                    selection == MixerRoutingSupport.systemDefaultSelectionID ? nil : selection)
            }
        )
    }

    /// One entry per app the list knows about: visible rows checked, hidden
    /// apps unchecked, everything in one alphabetical run so the menu reads
    /// like the list itself.
    private struct MixerListChoice: Identifiable {
        let id: String
        let name: String
        let isListed: Bool
        /// A row with nothing stable to remember it by cannot be hidden; it
        /// still shows here so the menu mirrors the list.
        let canToggle: Bool
    }

    private var listChoices: [MixerListChoice] {
        // The hidden list updates the moment a box is unchecked, while the
        // visible rows only change when the next HAL refresh lands. Keyed by
        // persistence id with the hidden entry winning, a just-hidden app
        // shows up once (unchecked) instead of twice during that gap.
        var seen = Set<String>()
        var choices = mixer.hiddenApps.map { hidden -> MixerListChoice in
            seen.insert(hidden.id)
            return MixerListChoice(id: hidden.id, name: hidden.name, isListed: false, canToggle: true)
        }
        for app in mixer.apps {
            let id = app.persistenceID ?? app.id
            guard seen.insert(id).inserted else { continue }
            choices.append(MixerListChoice(id: id, name: app.name,
                                           isListed: true, canToggle: app.persistenceID != nil))
        }
        choices.sort {
            MixerRoutingSupport.displayOrderedBefore(name: $0.name, id: $0.id,
                                                     otherName: $1.name, otherID: $1.id)
        }
        return choices
    }

    /// Which apps the list shows (issue #300): the row reads how many are
    /// hidden and opens a check per app, right in the panel so several can be
    /// checked or unchecked in one go. Hidden apps stay here even while they
    /// are not running, so they can always be brought back.
    private var listVisibilityFooter: some View {
        VStack(alignment: .leading, spacing: 6) {
            Button {
                showListChooser.toggle()
            } label: {
                HStack(spacing: 8) {
                    Text(mixerText.visibleApps)
                        .font(PanelTypography.meta)
                        .foregroundStyle(.secondary)
                    Spacer(minLength: 6)
                    Text(mixer.hiddenApps.isEmpty
                         ? mixerText.allShown
                         : "\(mixerText.hiddenCountLabel): \(mixer.hiddenApps.count)")
                        .font(PanelTypography.meta)
                        .foregroundStyle(.secondary)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 8, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .rotationEffect(.degrees(showListChooser ? 90 : 0))
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(mixerText.visibleApps)
            .accessibilityValue(mixer.hiddenApps.isEmpty
                                ? mixerText.allShown
                                : "\(mixerText.hiddenCountLabel): \(mixer.hiddenApps.count)")

            if showListChooser {
                ForEach(listChoices) { choice in
                    Toggle(isOn: listedBinding(for: choice)) {
                        Text(choice.name)
                            .font(PanelTypography.meta)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                    .toggleStyle(.checkbox)
                    .controlSize(.small)
                    .disabled(!choice.canToggle)
                }
            }
        }
    }

    private func listedBinding(for choice: MixerListChoice) -> Binding<Bool> {
        Binding(
            get: { choice.isListed },
            set: { listed in
                if listed {
                    mixer.showInList(id: choice.id)
                } else if let app = mixer.apps.first(where: { ($0.persistenceID ?? $0.id) == choice.id }) {
                    mixer.hideFromList(app)
                }
            }
        )
    }

    private var visibleApps: [MixerApp] {
        mixer.apps.filter { app in
            MixerRoutingSupport.shouldShowApp(isPlaying: app.isPlaying,
                                              volume: app.volume,
                                              selectedOutputDeviceUID: app.selectedOutputDeviceUID,
                                              hideInactiveApps: hideInactiveApps)
        }
    }

    private func inputDeviceTitle(_ device: MixerInputDevice) -> String {
        device.isDefault ? "\(device.name) (\(mixerText.outputCurrent))" : device.name
    }

    private func outputDeviceTitle(_ device: MixerOutputDevice) -> String {
        device.isDefault ? "\(device.name) (\(mixerText.outputCurrent))" : device.name
    }

    private func systemSoundOutputDeviceTitle(_ device: MixerOutputDevice) -> String {
        device.uid == mixer.currentSystemSoundOutputDeviceUID
            ? "\(device.name) (\(mixerText.outputCurrent))"
            : device.name
    }

    private func inputMessage(_ text: String, systemImage: String) -> some View {
        Label(text, systemImage: systemImage)
            .font(PanelTypography.meta)
            .foregroundStyle(.secondary)
            .lineLimit(2)
            .fixedSize(horizontal: false, vertical: true)
    }

    @ViewBuilder
    private var mixerRows: some View {
#if compiler(>=6.2)
        if #available(macOS 26.0, *), LiquidGlassSupport.isEnabled() {
            GlassEffectContainer(spacing: 8) {
                rowList
            }
        } else {
            rowList
        }
#else
        rowList
#endif
    }

    @ViewBuilder
    private var rowList: some View {
        ForEach(visibleApps) { app in
            MixerRow(app: app,
                     normalTint: normalSliderTint,
                     accentRevision: accentRevision,
                     editingVolumeID: $editingVolumeID)
        }
    }

    /// Appearance KVO and the system-colors notification can fire in bursts
    /// without the accent actually changing, and every revision bump re-renders
    /// (and, before macOS 26, recreates) every slider row — so compare the
    /// accent resolved against the current appearance and only then re-tint.
    /// When the accent cannot be resolved this fails open (always re-tints),
    /// never closed: eating a real accent change would leave stale sliders.
    private func refreshSliderTint() {
        var resolved: NSColor?
        NSApplication.shared.effectiveAppearance.performAsCurrentDrawingAppearance {
            resolved = NSColor.controlAccentColor.usingColorSpace(.sRGB)
        }
        if let resolved, let last = lastResolvedAccent, resolved == last { return }
        lastResolvedAccent = resolved
        normalSliderTint = Color(nsColor: .controlAccentColor)
        accentRevision += 1
    }

    private func emptyLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11))
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, 4)
    }

    private var permissionHint: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(mixerText.permissionBody)
                .font(PanelTypography.meta)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Button(l10n.s.permissionOpenSettings) {
                Permissions.shared.openAudioCaptureSettings()
            }
            .controlSize(.small)
        }
    }
}

private struct MixerRow: View {
    @ObservedObject private var mixer = AppVolumeMixer.shared
    @ObservedObject private var l10n = L10n.shared
    private var mixerText: MixerFeatureStrings { FeatureStrings.mixer(l10n.language) }
    @Environment(\.colorScheme) private var colorScheme
    let app: MixerApp
    let normalTint: Color
    let accentRevision: Int
    @Binding var editingVolumeID: String?

    /// Warm accent to flag the boost range, darkened in Light Mode for contrast.
    private var boostColor: Color { PanelMetricColor.orange(for: colorScheme) }
    /// Tie the visual state to the displayed percentage, so "amber" and ">100%"
    /// always agree and the reset hides exactly when the row reads 100%.
    private var isBoosting: Bool { (app.volume * 100).rounded() > 100 }
    private var isAtUnity: Bool { (app.volume * 100).rounded() == 100 }

    /// SoundSource-sized icon spanning the row's two lines (issue #166); the
    /// bitmap must be requested at this size or the upscale looks blurry.
    private static let iconPointSize: CGFloat = 32

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            ZStack(alignment: .bottomTrailing) {
                Image(nsImage: ResponsibleProcess.icon(for: app.ownerPid,
                                                       pointSize: Self.iconPointSize))
                    .resizable()
                    .frame(width: Self.iconPointSize, height: Self.iconPointSize)
                if app.isPlaying {
                    Circle()
                        .fill(PanelMetricColor.green(for: colorScheme))
                        .frame(width: 8, height: 8)
                        .overlay(Circle().stroke(Color(nsColor: .windowBackgroundColor), lineWidth: 1.2))
                        .offset(x: -1, y: -1)
                }
            }

            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 8) {
                    Text(app.name)
                        .font(PanelTypography.title)
                        .lineLimit(1)
                        .truncationMode(.middle)

                    Spacer(minLength: 4)

                    if !app.isBypassed {
                        outputPicker
                    }
                }

                if app.isBypassed {
                    // Zoom and pro audio apps are listed but never tapped
                    // (issue #177): the row explains itself instead of the
                    // app silently missing from the mixer.
                    Text(mixerText.bypassedCaption)
                        .font(PanelTypography.meta)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    HStack(spacing: 8) {
                        MixerVolumeSlider(value: volumeBinding,
                                          normalTint: normalTint,
                                          boostTint: boostColor,
                                          isBoosting: isBoosting,
                                          accentRevision: accentRevision,
                                          maximum: AppVolumeMixer.maxVolume,
                                          accessibilityLabel: app.name)

                        EditableVolumePercent(currentPercent: Int((app.volume * 100).rounded()),
                                              maximumPercent: Int(AppVolumeMixer.maxVolume * 100),
                                              width: 42,
                                              editorID: "app:\(app.id)",
                                              editingID: $editingVolumeID,
                                              accessibilityLabel: app.name) {
                            HStack(spacing: 2) {
                                if isBoosting {
                                    Image(systemName: "bolt.fill")
                                        .font(.system(size: 8, weight: .bold))
                                        .foregroundStyle(boostColor)
                                }
                                Text("\(Int((app.volume * 100).rounded()))%")
                                    .font(PanelTypography.meta)
                                    .monospacedDigit()
                                    .foregroundStyle(isBoosting ? boostColor : Color.secondary)
                            }
                        } onCommit: {
                            mixer.setVolume($0, for: app)
                        }

                        Button {
                            mixer.setVolume(1, for: app)
                        } label: {
                            Image(systemName: "arrow.counterclockwise")
                                .font(PanelTypography.meta)
                                .foregroundStyle(isBoosting ? boostColor : Color.secondary)
                                .frame(width: 14)
                        }
                        .buttonStyle(.plain)
                        .help(mixerText.resetTooltip)
                        .opacity(isAtUnity ? 0 : 1)
                        .disabled(isAtUnity)

                        Button {
                            mixer.toggleMute(app)
                        } label: {
                            Image(systemName: app.volume <= 0.001 ? "speaker.slash.fill" : "speaker.wave.2.fill")
                                .font(PanelTypography.meta)
                                .foregroundStyle(app.volume <= 0.001
                                                 ? PanelMetricColor.red(for: colorScheme)
                                                 : Color.secondary)
                                .frame(width: 16)
                        }
                        .buttonStyle(.plain)
                    }

                    if app.outputDeviceUnavailable {
                        Label(mixerText.outputFallback, systemImage: "speaker.badge.exclamationmark")
                            .font(PanelTypography.meta)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .padding(.vertical, 2)
        .contextMenu {
            // Same action as unchecking the app in the footer menu, one
            // right-click closer (issue #300).
            if app.persistenceID != nil {
                Button(mixerText.hideFromList) {
                    mixer.hideFromList(app)
                }
            }
        }
    }

    private var volumeBinding: Binding<Double> {
        Binding(
            get: { app.volume },
            set: { mixer.setVolume($0, for: app) }
        )
    }

    private var outputPicker: some View {
        Picker(mixerText.outputTooltip, selection: outputSelectionBinding) {
            Text(mixerText.outputDefault)
                .tag(MixerRoutingSupport.systemDefaultSelectionID)
            ForEach(mixer.outputDevices) { device in
                Text(outputDeviceTitle(device))
                    .tag(device.uid)
            }
            if let selected = app.selectedOutputDeviceUID, app.outputDeviceUnavailable {
                Text(mixerText.outputUnavailable)
                    .tag(selected)
            }
        }
        .labelsHidden()
        .pickerStyle(.menu)
        .controlSize(.small)
        .frame(width: 112)
        .help(mixerText.outputTooltip)
    }

    private var outputSelectionBinding: Binding<String> {
        Binding(
            get: { app.selectedOutputDeviceUID ?? MixerRoutingSupport.systemDefaultSelectionID },
            set: { selection in
                mixer.setOutputDeviceUID(selection == MixerRoutingSupport.systemDefaultSelectionID ? nil : selection,
                                         for: app)
            }
        )
    }

    private func outputDeviceTitle(_ device: MixerOutputDevice) -> String {
        device.isDefault ? "\(device.name) (\(mixerText.outputCurrent))" : device.name
    }
}

/// The percentage keeps its compact read-only appearance until clicked, then
/// becomes a selected text field so the next keystroke replaces the old value.
private struct EditableVolumePercent<Label: View>: View {
    let currentPercent: Int
    let maximumPercent: Int
    let width: CGFloat
    let editorID: String
    @Binding var editingID: String?
    let accessibilityLabel: String
    @ViewBuilder let label: () -> Label
    let onCommit: (Double) -> Void

    @State private var draft = ""

    private var isEditing: Bool { editingID == editorID }

    var body: some View {
        ZStack {
            HStack(spacing: 1) {
                AutofocusingVolumeTextField(text: $draft,
                                            isActive: isEditing,
                                            accessibilityLabel: accessibilityLabel,
                                            onSubmit: commit,
                                            onCancel: cancel)
                Text("%")
                    .font(PanelTypography.meta)
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, 3)
            .frame(width: width, height: 18)
            .background(
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(Color(nsColor: .controlBackgroundColor))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .strokeBorder(Color.accentColor.opacity(0.7), lineWidth: 1)
            )
            .opacity(isEditing ? 1 : 0)
            .allowsHitTesting(isEditing)
            .accessibilityHidden(!isEditing)

            Button(action: beginEditing) {
                label()
                    .frame(width: width, alignment: .trailing)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .opacity(isEditing ? 0 : 1)
            .allowsHitTesting(!isEditing)
            .accessibilityLabel("\(accessibilityLabel) \(currentPercent)%")
            .accessibilityHidden(isEditing)
        }
        .frame(width: width, alignment: .trailing)
    }

    private func beginEditing() {
        draft = String(currentPercent)
        editingID = editorID
    }

    @discardableResult
    private func commit() -> Bool {
        guard let volume = MixerRoutingSupport.volumeFraction(
            fromPercentageText: draft,
            maximumPercent: maximumPercent
        ) else {
            NSSound.beep()
            return false
        }
        onCommit(volume)
        editingID = nil
        return true
    }

    private func cancel() {
        if isEditing { editingID = nil }
    }
}

/// A native field is used because an NSPopover can attach its SwiftUI backing
/// view after a FocusState request has already fired. The field retries when it
/// joins the window, then owns Return, Escape and loss-of-focus behavior.
private struct AutofocusingVolumeTextField: NSViewRepresentable {
    @Binding var text: String
    let isActive: Bool
    let accessibilityLabel: String
    let onSubmit: () -> Bool
    let onCancel: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text,
                    isActive: isActive,
                    onSubmit: onSubmit,
                    onCancel: onCancel)
    }

    func makeNSView(context: Context) -> MixerPercentNativeTextField {
        let field = MixerPercentNativeTextField()
        field.delegate = context.coordinator
        field.isBordered = false
        field.drawsBackground = false
        field.focusRingType = .none
        field.alignment = .right
        field.font = .systemFont(ofSize: 10.5, weight: .medium)
        field.cell?.wraps = false
        field.cell?.isScrollable = true
        field.isEnabled = isActive
        field.isHidden = !isActive
        field.setAccessibilityLabel(accessibilityLabel)
        field.didAttachToWindow = { [weak field, weak coordinator = context.coordinator] in
            guard let field else { return }
            coordinator?.focusIfNeeded(field)
        }
        return field
    }

    func updateNSView(_ field: MixerPercentNativeTextField, context: Context) {
        context.coordinator.text = $text
        context.coordinator.onSubmit = onSubmit
        context.coordinator.onCancel = onCancel
        field.setAccessibilityLabel(accessibilityLabel)
        if field.stringValue != text { field.stringValue = text }
        context.coordinator.setActive(isActive, field: field)
    }

    static func dismantleNSView(_ field: MixerPercentNativeTextField,
                                coordinator: Coordinator) {
        coordinator.stopMonitoringEscape()
        field.didAttachToWindow = nil
        field.delegate = nil
    }

    final class Coordinator: NSObject, NSTextFieldDelegate {
        var text: Binding<String>
        private var isActive: Bool
        var onSubmit: () -> Bool
        var onCancel: () -> Void
        private var didFocus = false
        private var isFinishing = false
        private var escapeMonitor: Any?

        init(text: Binding<String>,
             isActive: Bool,
             onSubmit: @escaping () -> Bool,
             onCancel: @escaping () -> Void) {
            self.text = text
            self.isActive = isActive
            self.onSubmit = onSubmit
            self.onCancel = onCancel
            super.init()
            if isActive { startMonitoringEscape() }
        }

        func controlTextDidChange(_ notification: Notification) {
            guard let field = notification.object as? NSTextField else { return }
            text.wrappedValue = field.stringValue
        }

        func controlTextDidEndEditing(_ notification: Notification) {
            guard isActive, didFocus, !isFinishing,
                  let field = notification.object as? NSTextField else { return }
            text.wrappedValue = field.stringValue
            isFinishing = true
            if !onSubmit() { onCancel() }
        }

        func control(_ control: NSControl,
                     textView: NSTextView,
                     doCommandBy commandSelector: Selector) -> Bool {
            if commandSelector == #selector(NSResponder.insertNewline(_:)) {
                text.wrappedValue = (control as? NSTextField)?.stringValue ?? text.wrappedValue
                if onSubmit() { isFinishing = true }
                return true
            }
            if commandSelector == #selector(NSResponder.cancelOperation(_:)) {
                finish(onCancel)
                return true
            }
            return false
        }

        func focusIfNeeded(_ field: MixerPercentNativeTextField) {
            guard isActive, !didFocus else { return }
            DispatchQueue.main.async { [weak self, weak field] in
                guard let self, let field, self.isActive, !self.didFocus else { return }
                if field.focusAndSelectAll() { self.didFocus = true }
            }
        }

        func setActive(_ active: Bool, field: MixerPercentNativeTextField) {
            if active != isActive {
                isActive = active
                didFocus = false
                isFinishing = false
                if active {
                    field.isHidden = false
                    field.isEnabled = true
                    startMonitoringEscape()
                } else {
                    stopMonitoringEscape()
                    field.isEnabled = false
                    field.isHidden = true
                }
            }
            if active { focusIfNeeded(field) }
        }

        private func startMonitoringEscape() {
            guard escapeMonitor == nil else { return }
            escapeMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
                guard let self, self.isActive, event.keyCode == 53 else { return event }
                self.finish(self.onCancel)
                return nil
            }
        }

        func stopMonitoringEscape() {
            guard let escapeMonitor else { return }
            NSEvent.removeMonitor(escapeMonitor)
            self.escapeMonitor = nil
        }

        private func finish(_ action: () -> Void) {
            guard !isFinishing else { return }
            isFinishing = true
            action()
        }
    }
}

private struct MixerVolumeSlider: View {
    @Binding var value: Double
    let normalTint: Color
    let boostTint: Color
    let isBoosting: Bool
    let accentRevision: Int
    let maximum: Double
    let accessibilityLabel: String

    private var activeTint: Color { isBoosting ? boostTint : normalTint }
    private var percentage: Int { Int((value * 100).rounded()) }

    var body: some View {
        Group {
#if compiler(>=6.2)
            if #available(macOS 26.0, *), LiquidGlassSupport.isEnabled() {
                LiquidGlassMixerSlider(value: $value,
                                       tint: activeTint,
                                       isBoosting: isBoosting,
                                       maximum: maximum,
                                       accessibilityLabel: accessibilityLabel)
            } else {
                nativeSlider
                    .accessibilityLabel(accessibilityLabel)
                    .accessibilityValue("\(percentage)%")
            }
#else
            nativeSlider
                .accessibilityLabel(accessibilityLabel)
                .accessibilityValue("\(percentage)%")
#endif
        }
    }

    private var nativeSlider: some View {
        Slider(value: $value, in: 0...maximum)
            .controlSize(.small)
            // Pass an explicit accent (not nil) for the normal state: on the
            // macOS slider, tint(nil) does not reliably clear a previously
            // applied colour, so the bar would stay amber after leaving boost.
            .tint(activeTint)
            .id(accentRevision)
    }
}

#if compiler(>=6.2)
@available(macOS 26.0, *)
private struct LiquidGlassMixerSlider: View {
    @Binding var value: Double
    let tint: Color
    let isBoosting: Bool
    let maximum: Double
    let accessibilityLabel: String
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorScheme) private var colorScheme

    private let knobWidth: CGFloat = 24
    private let knobHeight: CGFloat = 15
    private let trackHeight: CGFloat = 5

    private var progress: CGFloat {
        let clamped = min(max(value, 0), maximum)
        return CGFloat(clamped / maximum)
    }

    var body: some View {
        GeometryReader { proxy in
            let width = max(proxy.size.width, knobWidth)
            let amount = progress
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.primary.opacity(trackOpacity))
                    .frame(height: trackHeight)

                Capsule()
                    .fill(tint)
                    .frame(width: max(trackHeight, width * amount), height: trackHeight)
                    .shadow(color: tint.opacity(0.18), radius: 3)

                knob
                    .frame(width: knobWidth, height: knobHeight)
                    .offset(x: (width - knobWidth) * amount)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .animation(.easeOut(duration: 0.16), value: amount)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        updateValue(at: gesture.location.x, width: width)
                    }
            )
        }
        .frame(height: knobHeight)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityValue("\(Int((value * 100).rounded()))%")
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment:
                value = min(maximum, value + 0.05)
            case .decrement:
                value = max(0, value - 0.05)
            @unknown default:
                break
            }
        }
    }

    private var trackOpacity: Double {
        colorScheme == .light ? 0.11 : 0.16
    }

    private var knob: some View {
        ZStack {
            knobFill
            Capsule()
                .strokeBorder(tint.opacity(isBoosting ? 0.55 : 0.36), lineWidth: isBoosting ? 1.1 : 0.8)
            Capsule()
                .fill(
                    LinearGradient(colors: [
                        Color.white.opacity(colorScheme == .light ? 0.48 : 0.28),
                        Color.white.opacity(0.06)
                    ], startPoint: .top, endPoint: .bottom)
                )
                .blendMode(.screen)
                .padding(1)
        }
        .shadow(color: tint.opacity(isBoosting ? 0.24 : 0.16), radius: 3, x: 0, y: 0)
        .shadow(color: Color.black.opacity(colorScheme == .light ? 0.08 : 0.18), radius: 2, x: 0, y: 1)
    }

    @ViewBuilder
    private var knobFill: some View {
        if reduceTransparency {
            Capsule()
                .fill(Color(nsColor: .controlBackgroundColor))
                .overlay(Capsule().fill(tint.opacity(colorScheme == .light ? 0.10 : 0.16)))
        } else {
            Color.clear
                .glassEffect(.regular.tint(tint.opacity(isBoosting ? 0.18 : 0.10)).interactive(), in: Capsule())
        }
    }

    private func updateValue(at x: CGFloat, width: CGFloat) {
        let travel = max(width - knobWidth, 1)
        let normalized = min(max((x - knobWidth / 2) / travel, 0), 1)
        value = Double(normalized) * maximum
    }
}
#endif
