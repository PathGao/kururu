// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import AppKit
import SwiftUI
import UniformTypeIdentifiers

/// Display choices share the global menu bar and panel preferences.
struct MonitorSettings: View {
    @ObservedObject private var l10n = L10n.shared
    @ObservedObject private var features = FeatureRuntime.shared

    @AppStorage(DefaultsKey.monitorInterval) private var interval = 2
    @AppStorage(DefaultsKey.temperatureUnit) private var temperatureUnit = TemperatureUnit.celsius.rawValue
    @AppStorage(DefaultsKey.monitorMemoryMetric) private var memoryMetric = "used"


    var body: some View {
        SettingsForm {
            MonitorEntrySettings()
            SettingsSection {
                MonitorPerformanceStatus()
            }
            .listRowBackground(Color.clear)
            SettingsSection(title: UXEntryStrings(l10n.language).samplingAndUnits, systemImage: "gauge.with.dots.needle.33percent") {
                SettingsControlRow(title: l10n.s.monitorIntervalLabel,
                                   systemImage: "timer",
                                   help: MonitorHistoryStrings.text(l10n.language).intervalHint) {
                    Picker(l10n.s.monitorIntervalLabel, selection: $interval) {
                        ForEach(1...5, id: \.self) { seconds in
                            Text(intervalTitle(seconds)).tag(seconds)
                        }
                    }
                    .labelsHidden()
                }
                SettingsControlRow(title: l10n.s.temperatures, systemImage: "thermometer.medium") {
                    Picker(l10n.s.temperatures, selection: $temperatureUnit) {
                        Text("°C").tag(TemperatureUnit.celsius.rawValue)
                        Text("°F").tag(TemperatureUnit.fahrenheit.rawValue)
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                }
                if AppFeature.monitorMemory.isAvailable {
                    SettingsControlRow(title: l10n.s.monitorMemoryMetricLabel, systemImage: "memorychip") {
                        Picker(l10n.s.monitorMemoryMetricLabel, selection: $memoryMetric) {
                            Text(l10n.s.memoryMetricUsed).tag("used")
                            Text(l10n.s.memoryMetricApp).tag("app")
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()
                    }
                }
            }
            monitorAlertsSection
            SettingsSection {
                FeatureSwitchRow(feature: .fanControl)
                Text(FeatureStrings.fanControl(l10n.language).settingsCaption)
                    .font(SettingsTypography.caption)
                    .foregroundStyle(.secondary)
                Text(l10n.s.betaFeatureWarning)
                    .font(SettingsTypography.caption)
                    .foregroundStyle(.secondary)
            } header: {
                HStack(spacing: 6) {
                    Text(AppFeature.fanControl.name(l10n.s, language: l10n.language))
                    Text(l10n.s.betaBadge)
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(Color.white)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1)
                        .background(Capsule().fill(Color.accentColor))
                }
            }
            .saturation(AppFeature.fanControl.installBlockedReason == nil ? 1 : 0)
            .settingsSectionAnchor(.fanControl)
        }
        .formStyle(.grouped)
        .onAppear {
            interval = Defaults.sanitizedMonitorInterval(interval)
            if TemperatureUnit(rawValue: temperatureUnit) == nil {
                temperatureUnit = TemperatureUnit.celsius.rawValue
            }
            memoryMetric = Defaults.sanitizedMonitorMemoryMetric(memoryMetric)
        }
    }

    private func intervalTitle(_ seconds: Int) -> String {
        switch seconds {
        case 1: return l10n.s.monitorInterval1
        case 2: return l10n.s.monitorInterval2
        case 5: return l10n.s.monitorInterval5
        default: return "\(seconds) \(MonitorHistoryStrings.text(l10n.language).seconds)"
        }
    }

    private var monitorAlertsSection: some View {
        let text = FeatureStrings.monitorAlerts(l10n.language)
        return SettingsSection(text.section) {
            MonitorAlertsControls(compact: false)
        }
    }
}
