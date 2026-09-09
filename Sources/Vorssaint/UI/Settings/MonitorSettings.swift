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

    @AppStorage("monitorHistoryMinutes") private var historyMinutes = 1
    @AppStorage(DefaultsKey.monitorInterval) private var interval = 2
    @AppStorage(DefaultsKey.temperatureUnit) private var temperatureUnit = TemperatureUnit.celsius.rawValue
    @AppStorage(DefaultsKey.monitorMemoryMetric) private var memoryMetric = "used"


    var body: some View {
        Form {
            Section {
                MonitorPerformanceStatus()
            }
            .listRowBackground(Color.clear)
            FeatureSwitchSection(unit: .monitor, usesGrid: true)
                .listRowBackground(Color.clear)
            Section {
                Picker(l10n.s.monitorIntervalLabel, selection: $interval) {
                    ForEach(1...5, id: \.self) { seconds in
                        Text(intervalTitle(seconds)).tag(seconds)
                    }
                }
                Text(MonitorHistoryStrings.text(l10n.language).intervalHint)
                    .font(.caption).foregroundStyle(.secondary)
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
            Section(MonitorHistoryStrings.text(l10n.language).history) {
                Picker(MonitorHistoryStrings.text(l10n.language).range, selection: $historyMinutes) {
                    ForEach(1...5, id: \.self) { value in
                        Text("\(value) \(MonitorHistoryStrings.text(l10n.language).minutes)").tag(value)
                    }
                }
                MonitorGraphToggle(title: l10n.s.cpuLabel, key: DefaultsKey.monitorGraphCPU)
                MonitorGraphToggle(title: l10n.s.gpuLabel, key: DefaultsKey.monitorGraphGPU)
                MonitorGraphToggle(title: l10n.s.memorySection, key: DefaultsKey.monitorGraphMemory)
                MonitorGraphToggle(title: l10n.s.networkSection, key: DefaultsKey.monitorGraphNetwork)
                MonitorGraphToggle(title: AppFeature.monitorDisk.name(l10n.s, language: l10n.language), key: DefaultsKey.monitorGraphDisk)
                MonitorGraphToggle(title: AppFeature.monitorPower.name(l10n.s, language: l10n.language), key: DefaultsKey.monitorGraphPower)
                MonitorGraphToggle(title: l10n.s.batteryLabel, key: DefaultsKey.monitorGraphBattery)
                if AppFeature.fanControl.isAvailable {
                    MonitorGraphToggle(title: FeatureStrings.fanControl(l10n.language).menuBarTitle, key: "monitorGraphFan")
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
        return Section(text.section) {
            MonitorAlertsControls(compact: false)
        }
    }
}


// Contributed in PR #179: the memory pressure-dot option lives under the
// Memory row, matching the Network row's inline option.





private struct MonitorGraphToggle: View {
    let title: String
    @AppStorage private var visible: Bool

    init(title: String, key: String) {
        self.title = title
        _visible = AppStorage(wrappedValue: true, key)
    }

    var body: some View { Toggle(title, isOn: $visible) }
}
