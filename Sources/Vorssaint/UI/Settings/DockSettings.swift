// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import SwiftUI

struct DockSettings: View {
    @ObservedObject private var l10n = L10n.shared
    @ObservedObject private var features = FeatureRuntime.shared
    @ObservedObject private var permissions = Permissions.shared
    @ObservedObject private var dockPreview = DockPreviewService.shared
    @AppStorage(DefaultsKey.dockPreviewEnabled) private var dockPreviewEnabled = false
    @AppStorage(DefaultsKey.dockPreviewBackgroundOpacity) private var dockPreviewBackgroundOpacity = 1.0
    @AppStorage(DefaultsKey.dockPreviewOpenDelay) private var dockPreviewOpenDelay = DockPreviewSupport.defaultOpenDelayMilliseconds
    @AppStorage(DefaultsKey.dockPreviewQuitAppOnClose) private var dockPreviewQuitAppOnClose = false
    @AppStorage(DefaultsKey.dockClickMinimize) private var dockClickMinimize = false
    @AppStorage(DefaultsKey.dockClickHide) private var dockClickHide = false
    @AppStorage(DefaultsKey.dockClickCycleWindows) private var dockClickCycleWindows = false

    private var text: DockPreviewFeatureStrings { FeatureStrings.dockPreview(l10n.language) }
    private var clickText: DockClickFeatureStrings { FeatureStrings.dockClick(l10n.language) }

    var body: some View {
        SettingsForm {
            SettingsSection {
                FeatureSwitchRow(feature: .dockPreview)
                SettingsInfo(text: dockPreviewCaption,
                             systemImage: dockPreviewWarning ? "exclamationmark.triangle" : "cursorarrow.motionlines",
                             warning: dockPreviewWarning)
                Group {
                    Divider()
                    SettingsControlRow(title: text.openDelay, systemImage: "timer", help: text.openDelayCaption) {
                        HStack(spacing: 6) {
                            TextField(text.openDelay, value: dockPreviewOpenDelayBinding,
                                      formatter: Self.dockPreviewOpenDelayFormatter)
                                .textFieldStyle(.roundedBorder).frame(width: 64)
                            Stepper(text.openDelay, value: dockPreviewOpenDelayBinding,
                                    in: DockPreviewSupport.openDelayMillisecondsRange, step: 50)
                                .labelsHidden()
                            Text(verbatim: "ms").foregroundStyle(.secondary)
                        }
                    }
                    SettingsControlRow(title: text.backgroundOpacity, systemImage: "square.on.square", help: text.backgroundOpacityCaption) {
                        HStack(spacing: 8) {
                            Slider(value: dockPreviewBackgroundOpacityBinding,
                                   in: DockPreviewSupport.backgroundOpacityRange, step: 0.05)
                                .frame(width: 150)
                                .accessibilityLabel(text.backgroundOpacity)
                            Text("\(dockPreviewBackgroundOpacityPercent)%")
                                .font(SettingsTypography.body.monospacedDigit())
                                .foregroundStyle(.secondary).frame(width: 44, alignment: .trailing)
                        }
                    }
                    WindowPreviewControls(sizeKey: DefaultsKey.dockPreviewSize,
                                          exclusionsKey: DefaultsKey.dockPreviewExcludedApps)
                    Divider()
                    SettingsToggleWithCaption(title: text.quitAppOnClose,
                                              caption: text.quitAppOnCloseCaption,
                                              isOn: $dockPreviewQuitAppOnClose)
                }
                .disabled(!dockPreviewEnabled)
            }
            .settingsSectionAnchor(.dock)
            if AppFeature.dockClick.isAvailable {
                SettingsSection(title: AppFeature.dockClick.name(l10n.s, language: l10n.language),
                                systemImage: "cursorarrow.click") {
                    SettingsToggleWithCaption(title: clickText.minimize,
                                              caption: clickText.minimizeCaption,
                                              isOn: $dockClickMinimize)
                        .onChange(of: dockClickMinimize) { _, enabled in
                            if enabled { dockClickHide = false }
                            DockClickService.shared.syncWithPreferences()
                        }
                    SettingsToggleWithCaption(title: clickText.hide,
                                              caption: clickText.hideCaption,
                                              isOn: $dockClickHide)
                        .onChange(of: dockClickHide) { _, enabled in
                            if enabled { dockClickMinimize = false }
                            DockClickService.shared.syncWithPreferences()
                        }
                    SettingsToggleWithCaption(title: clickText.cycleWindows,
                                              caption: clickText.cycleWindowsCaption,
                                              isOn: $dockClickCycleWindows)
                        .onChange(of: dockClickCycleWindows) { _, _ in
                            DockClickService.shared.syncWithPreferences()
                        }
                }
                .settingsSectionAnchor(.dockClick)
            }
            // Dock Preview always captures thumbnails. Dock clicks only need
            // Accessibility, including when previews are switched off.
            if (dockPreviewEnabled || (AppFeature.dockClick.isAvailable
                && (dockClickMinimize || dockClickHide || dockClickCycleWindows))),
               !permissions.accessibility {
                SettingsSection(l10n.s.permissionRequired) {
                    PermissionRow(kind: .accessibility)
                }
            }
            if dockPreviewEnabled, !permissions.screenRecording {
                SettingsSection {
                    PermissionRow(kind: .screenRecording)
                }
            }
        }
        .formStyle(.grouped)
    }

    private var dockPreviewCaption: String {
        guard dockPreviewEnabled else { return text.enableCaption }
        if !permissions.accessibility { return "\(l10n.s.permissionRequired): \(l10n.s.permissionAccessibility)" }
        if !permissions.screenRecording { return "\(l10n.s.permissionRequired): \(l10n.s.permissionScreenRecording)" }
        switch dockPreview.blockedReason {
        case .dockUnavailable: return text.dockUnavailable
        default:
            return text.enableCaption
        }
    }

    private var dockPreviewWarning: Bool {
        dockPreviewEnabled && dockPreview.blockedReason != nil
    }

    private var dockPreviewBackgroundOpacityBinding: Binding<Double> {
        Binding(
            get: { DockPreviewSupport.sanitizedBackgroundOpacity(dockPreviewBackgroundOpacity) },
            set: { dockPreviewBackgroundOpacity = DockPreviewSupport.sanitizedBackgroundOpacity($0) }
        )
    }

    private var dockPreviewBackgroundOpacityPercent: Int {
        Int((DockPreviewSupport.sanitizedBackgroundOpacity(dockPreviewBackgroundOpacity) * 100).rounded())
    }

    private var dockPreviewOpenDelayBinding: Binding<Int> {
        Binding(
            get: { DockPreviewSupport.sanitizedOpenDelay(milliseconds: dockPreviewOpenDelay) },
            set: { dockPreviewOpenDelay = DockPreviewSupport.sanitizedOpenDelay(milliseconds: $0) }
        )
    }

    /// Bounded here as well as in the binding: the field rejects an out-of-range
    /// number as it is typed rather than silently snapping it afterwards.
    private static let dockPreviewOpenDelayFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .none
        formatter.minimum = NSNumber(value: DockPreviewSupport.openDelayMillisecondsRange.lowerBound)
        formatter.maximum = NSNumber(value: DockPreviewSupport.openDelayMillisecondsRange.upperBound)
        formatter.usesGroupingSeparator = false
        return formatter
    }()
}
