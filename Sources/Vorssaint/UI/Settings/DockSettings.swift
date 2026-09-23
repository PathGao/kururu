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
    @AppStorage(DefaultsKey.dockPreviewKeepDockVisible) private var dockPreviewKeepDockVisible = false
    @AppStorage(DefaultsKey.dockClickMinimize) private var dockClickMinimize = false
    @AppStorage(DefaultsKey.dockClickHide) private var dockClickHide = false
    @AppStorage(DefaultsKey.dockClickCycleWindows) private var dockClickCycleWindows = false

    private var text: DockPreviewFeatureStrings { FeatureStrings.dockPreview(l10n.language) }
    private var clickText: DockClickFeatureStrings { FeatureStrings.dockClick(l10n.language) }

    private enum DockClickChoice: Hashable { case none, minimize, hide }

    private var dockClickActionBinding: Binding<DockClickChoice> {
        Binding(get: { dockClickMinimize ? .minimize : dockClickHide ? .hide : .none },
                set: { choice in
                    dockClickMinimize = choice == .minimize
                    dockClickHide = choice == .hide
                    DockClickService.shared.syncWithPreferences()
                })
    }

    var body: some View {
        SettingsForm {
            SettingsSection {
                FeatureSwitchRow(feature: .dockPreview)
                SettingsInfo(text: dockPreviewCaption,
                             systemImage: dockPreviewWarning ? "exclamationmark.triangle" : "cursorarrow.motionlines",
                             warning: dockPreviewWarning)
                Group {
                    SettingsControlRow(title: text.openDelay, systemImage: "timer", help: text.openDelayCaption) {
                        HStack(spacing: 6) {
                            TextField(text.openDelay, value: dockPreviewOpenDelayBinding,
                                      formatter: Self.dockPreviewOpenDelayFormatter)
                                .labelsHidden()
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
                    SettingsToggleWithCaption(title: text.quitAppOnClose,
                                              caption: text.quitAppOnCloseCaption,
                                              isOn: $dockPreviewQuitAppOnClose)
                    SettingsToggleWithCaption(title: text.keepDockVisible,
                                              caption: text.keepDockVisibleCaption,
                                              isOn: $dockPreviewKeepDockVisible)
                        .disabled(!DockAutohideHold.isSupported && !dockPreviewKeepDockVisible)
                        .onChange(of: dockPreviewKeepDockVisible) { _, _ in
                            dockPreview.syncWithPreferences()
                        }
                }
                .disabled(!dockPreviewEnabled)
            }
            .settingsSectionAnchor(.dock)
            if AppFeature.dockClick.isAvailable {
                SettingsSection(title: AppFeature.dockClick.name(l10n.s, language: l10n.language),
                                systemImage: "cursorarrow.click") {
                    // Minimize and hide answer the same click, so they are one choice;
                    // cycling comes first whenever the app has several windows.
                    HStack(spacing: 6) {
                        Picker(clickText.clickAction, selection: dockClickActionBinding) {
                            Text(clickText.clickActionDefault).tag(DockClickChoice.none)
                            Text(clickText.clickActionMinimize).tag(DockClickChoice.minimize)
                            Text(clickText.clickActionHide).tag(DockClickChoice.hide)
                        }
                        SettingsHelpButton(title: clickText.clickAction,
                                           text: clickText.minimizeCaption + "\n\n" + clickText.hideCaption)
                    }
                    SettingsToggleWithCaption(title: clickText.cycleFirst,
                                              caption: clickText.cycleWindowsCaption,
                                              showsCaptionInline: false,
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
