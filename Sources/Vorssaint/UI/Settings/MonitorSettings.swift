// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import AppKit
import SwiftUI
import UniformTypeIdentifiers

/// The "Monitor" settings page: what is measured, how often, which metrics
/// draw a history graph and when they raise an alert. What the menu bar icon
/// and the panel look like belongs to the menu bar panel page.
struct MonitorSettings: View {
    @ObservedObject private var l10n = L10n.shared
    @ObservedObject private var features = FeatureRuntime.shared

    @AppStorage(DefaultsKey.monitorInterval) private var interval = 2
    @AppStorage(DefaultsKey.temperatureUnit) private var temperatureUnit = TemperatureUnit.celsius.rawValue
    @AppStorage(DefaultsKey.monitorMemoryMetric) private var memoryMetric = "used"


    var body: some View {
        Form {
            FeatureSwitchSection(unit: .monitor)
            Section {
                Picker(l10n.s.monitorIntervalLabel, selection: $interval) {
                    Text(l10n.s.monitorInterval1).tag(1)
                    Text(l10n.s.monitorInterval2).tag(2)
                    Text(l10n.s.monitorInterval5).tag(5)
                }
                Picker(l10n.s.temperatures, selection: $temperatureUnit) {
                    Text("°C").tag(TemperatureUnit.celsius.rawValue)
                    Text("°F").tag(TemperatureUnit.fahrenheit.rawValue)
                }
                .pickerStyle(.segmented)
                if AppFeature.monitorMemory.isAvailable {
                    Picker(l10n.s.monitorMemoryMetricLabel, selection: $memoryMetric) {
                        Text(l10n.s.memoryMetricUsed).tag("used")
                        Text(l10n.s.memoryMetricApp).tag("app")
                    }
                    .pickerStyle(.segmented)
                }
            }
            monitorAlertsSection
            if AppFeature.fanControl.isAvailable {
                let fanStrings = FeatureStrings.fanControl(l10n.language)
                Section {
                    Text(fanStrings.settingsCaption)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(l10n.s.betaFeatureWarning)
                        .font(.caption)
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
                .settingsSectionAnchor(.fanControl)
            }
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

    private var monitorAlertsSection: some View {
        let text = FeatureStrings.monitorAlerts(l10n.language)
        return Section(text.section) {
            MonitorAlertsControls(compact: false)
        }
    }
}


// Contributed in PR #179: the memory pressure-dot option lives under the
// Memory row, matching the Network row's inline option.




