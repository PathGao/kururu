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
        Form {
            FeatureSwitchSection(unit: .dock)
            Section {
                do {
                    Text(dockPreviewCaption)
                        .font(.caption)
                        .foregroundStyle(dockPreviewWarning ? .orange : .secondary)
                    if dockPreviewEnabled {
                        HStack {
                            Text(text.openDelay)
                            Spacer()
                            TextField("", value: dockPreviewOpenDelayBinding,
                                      formatter: Self.dockPreviewOpenDelayFormatter)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 64)
                            Stepper("", value: dockPreviewOpenDelayBinding,
                                    in: DockPreviewSupport.openDelayMillisecondsRange,
                                    step: 50)
                                .labelsHidden()
                            Text(verbatim: "ms")
                                .foregroundStyle(.secondary)
                        }
                        .fixedSize(horizontal: false, vertical: true)
                        SettingsCaptionText(text.openDelayCaption)
                        HStack {
                            Text(text.backgroundOpacity)
                            Slider(value: dockPreviewBackgroundOpacityBinding,
                                   in: DockPreviewSupport.backgroundOpacityRange,
                                   step: 0.05)
                            Text("\(dockPreviewBackgroundOpacityPercent)%")
                                .font(.system(.body, design: .monospaced))
                                .foregroundStyle(.secondary)
                                .frame(width: 52, alignment: .trailing)
                        }
                        SettingsCaptionText(text.backgroundOpacityCaption)
                        Toggle(text.quitAppOnClose,
                               isOn: $dockPreviewQuitAppOnClose)
                        SettingsCaptionText(text.quitAppOnCloseCaption)
                    }
                }
            } header: {
                Text(AppFeature.dockPreview.name(l10n.s, language: l10n.language))
            }
            .settingsSectionAnchor(.dock)
            if AppFeature.dockClick.isAvailable {
                Section {
                    do {
                        Toggle(clickText.minimize, isOn: $dockClickMinimize)
                            .onChange(of: dockClickMinimize) { _, enabled in
                                if enabled { dockClickHide = false }
                                DockClickService.shared.syncWithPreferences()
                            }
                        Text(clickText.minimizeCaption)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Toggle(clickText.hide, isOn: $dockClickHide)
                            .onChange(of: dockClickHide) { _, enabled in
                                if enabled { dockClickMinimize = false }
                                DockClickService.shared.syncWithPreferences()
                            }
                        Text(clickText.hideCaption)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Toggle(clickText.cycleWindows, isOn: $dockClickCycleWindows)
                            .onChange(of: dockClickCycleWindows) { _, _ in
                                DockClickService.shared.syncWithPreferences()
                            }
                        Text(clickText.cycleWindowsCaption)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text(AppFeature.dockClick.name(l10n.s, language: l10n.language))
                }
                .settingsSectionAnchor(.dockClick)
            }
            WindowPreviewSection(sizeKey: DefaultsKey.dockPreviewSize,
                                 exclusionsKey: DefaultsKey.dockPreviewExcludedApps)
            // Dock Preview always captures thumbnails, so an enabled preview
            // needs both permissions; no mode makes screen recording optional.
            if dockPreviewEnabled {
                if !permissions.accessibility {
                    Section(l10n.s.permissionRequired) {
                        PermissionRow(kind: .accessibility)
                    }
                }
                if !permissions.screenRecording {
                    Section {
                        PermissionRow(kind: .screenRecording)
                    }
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
