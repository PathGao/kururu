// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import SwiftUI

/// Panel section with one brightness slider per adjustable display. Values
/// refresh whenever the section appears, so changes made with the keyboard,
/// in System Settings or on the monitor itself are picked up.
struct BrightnessSection: View {
    @ObservedObject private var l10n = L10n.shared
    @ObservedObject private var service = BrightnessService.shared
    @ObservedObject private var permissions = Permissions.shared
    @AppStorage(DefaultsKey.brightnessOSDEnabled) private var brightnessOSDEnabled = false
    var collapsible = true
    @State private var refreshOwner = UUID()

    private var strings: BrightnessFeatureStrings { FeatureStrings.brightness(l10n.language) }

    var body: some View {
        PanelSection(.brightness, title: AppFeature.brightness.name(l10n.s, language: l10n.language), collapsible: collapsible) {
            VStack(alignment: .leading, spacing: 10) {
                if service.displays.isEmpty {
                    Text(strings.noDisplays)
                        .font(.system(size: 10.5))
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(service.displays) { display in
                        row(display)
                    }
                }
                if let failure = service.displayControlFailure {
                    Text(displayControlFailureText(failure, strings: strings))
                        .font(.system(size: 10.5))
                        .foregroundStyle(.red)
                }
                if service.brightnessOSDSupported {
                    Divider()
                    Toggle(strings.osdToggle, isOn: $brightnessOSDEnabled)
                        .font(.system(size: 10.5, weight: .medium))
                        .toggleStyle(.switch)
                        .controlSize(.mini)
                        .help(strings.osdCaption)
                        .onChange(of: brightnessOSDEnabled) { _, isOn in
                            if isOn { permissions.requestAccessibility() }
                            service.syncWithPreferences()
                        }
                }
            }
            .panelCard()
            .onAppear { service.beginVisibleRefresh(refreshOwner) }
            .onDisappear { service.endVisibleRefresh(refreshOwner) }
        }
    }

    private func row(_ display: BrightnessDisplay) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: display.isBuiltIn ? "laptopcomputer" : "display")
                    .font(.system(size: 10.5, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 16)
                Text(display.name)
                    .font(.system(size: 11.5, weight: .medium))
                    .lineLimit(1)
                    .truncationMode(.middle)
                Spacer(minLength: 4)
                if display.isActive, display.method != nil {
                    Text(display.observedBrightness.map { "\(Int(($0 * 100).rounded()))%" } ?? "—")
                        .font(.system(size: 10.5, weight: .semibold).monospacedDigit())
                        .foregroundStyle(.secondary)
                } else if !display.isActive {
                    Text(strings.displayOff)
                        .font(.system(size: 10.5, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                DisplayPowerButton(display: display, compact: true)
            }
            if display.isActive, display.method != nil {
                DisplayBrightnessControl(display: display, showOSD: brightnessOSDEnabled)
            }
            if let explanation = brightnessControlExplanation(display, strings: strings) {
                Text(explanation)
                    .font(.system(size: 10.5))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if service.brightnessWriteFailures[display.id] != nil {
                Text(strings.brightnessWriteFailed)
                    .font(.system(size: 10.5))
                    .foregroundStyle(.red)
            }
        }
    }

    private func brightnessBinding(_ display: BrightnessDisplay) -> Binding<Double> {
        Binding(get: { display.brightness },
                set: { service.setBrightness($0, for: display.id,
                                             showOSD: brightnessOSDEnabled) })
    }
}

/// Shared power affordance used by Settings and the menu bar panel. It stays
/// icon-only in the row, with a localized tooltip and accessibility label.
struct DisplayPowerButton: View {
    @ObservedObject private var l10n = L10n.shared
    @ObservedObject private var service = BrightnessService.shared
    let display: BrightnessDisplay
    var compact = false

    private var strings: BrightnessFeatureStrings { FeatureStrings.brightness(l10n.language) }
    private var pending: Bool { service.isDisplayPending(display.id) }
    private var enabled: Bool { service.canToggleDisplay(display) }

    private var label: String {
        if !service.displaySwitchingAvailable { return strings.switchUnavailable }
        if display.isActive, !enabled { return strings.lastDisplayCaption }
        return display.isActive ? strings.turnOffDisplay : strings.turnOnDisplay
    }

    var body: some View {
        Group {
            if pending {
                ProgressView()
                    .controlSize(.small)
                    .frame(width: compact ? 16 : 20, height: 18)
                    .accessibilityLabel(label)
            } else {
                Button {
                    service.toggleDisplay(display)
                } label: {
                    Image(systemName: display.isActive ? "power" : "power.circle.fill")
                        .font(.system(size: compact ? 10.5 : 12, weight: .semibold))
                        .foregroundStyle(display.isActive ? AnyShapeStyle(.secondary)
                                                         : AnyShapeStyle(.green))
                        .frame(width: compact ? 16 : 20, height: 18)
                }
                .buttonStyle(.plain)
                .disabled(!enabled)
                .help(label)
                .accessibilityLabel(label)
            }
        }
    }
}

func displayControlFailureText(_ failure: BrightnessService.DisplayControlFailure,
                               strings: BrightnessFeatureStrings) -> String {
    switch failure {
    case .unavailable: return strings.switchUnavailable
    case .lastActive: return strings.lastDisplayCaption
    case .failed: return strings.switchFailed
    case .closedLid: return strings.openLidToEnable
    }
}

/// Describes the displayed value without treating missing readback as a failed write.
func brightnessControlExplanation(_ display: BrightnessDisplay,
                                  strings: BrightnessFeatureStrings) -> String? {
    guard display.isActive else { return nil }
    if display.failure == .identityUnavailable {
        return FeatureBehaviorStrings(language: L10n.shared.language).identityUnavailable
    }
    guard let method = display.method else { return nil }
    if method == .software { return strings.softwareDimmingNote }
    let statusText = FeatureBehaviorStrings(language: L10n.shared.language)
    switch display.status {
    case .pending: return statusText.pending + requestedLevelText(display)
    case .sentUnconfirmed: return statusText.unconfirmed + requestedLevelText(display)
    case .failed, .unknown: return statusText.invalidRead
    case .confirmed: break
    }
    if !display.hasKnownBrightness { return strings.brightnessUnknownNote }
    return display.readable ? nil : strings.brightnessReadbackNote
}

private func requestedLevelText(_ display: BrightnessDisplay) -> String {
    display.requestedBrightness.map { " (\(Int(($0 * 100).rounded()))%)" } ?? ""
}
