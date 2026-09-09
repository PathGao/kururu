// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import SwiftUI

/// Reusable panel configuration: one expandable block per panel section, each
/// with a master "show in panel" toggle plus per-item toggles. Shared by
/// Settings → Menu bar panel and the onboarding panel step so the two stay identical.
/// Designed to live inside a `Form` (grouped style) in both places.
struct MonitorPanelConfig: View {
    @ObservedObject private var l10n = L10n.shared
    @ObservedObject private var features = FeatureRuntime.shared
    @State private var expandedBlocks = Set<PanelConfigBlock>()

    @AppStorage(DefaultsKey.monitorShowSystem) private var showSystem = true
    @AppStorage(DefaultsKey.monitorSysTemps) private var sysTemps = true
    @AppStorage(DefaultsKey.monitorSysCPU) private var sysCPU = true
    @AppStorage(DefaultsKey.monitorSysGPU) private var sysGPU = true
    @AppStorage(DefaultsKey.monitorPwrTemperature) private var pwrTemperature = true
    @AppStorage(DefaultsKey.monitorSysBattery) private var sysBattery = true
    @AppStorage(DefaultsKey.monitorSysMemory) private var sysMemory = true
    @AppStorage(DefaultsKey.monitorSysUptime) private var sysUptime = true

    @AppStorage(DefaultsKey.monitorShowNetwork) private var showNetwork = true
    @AppStorage(DefaultsKey.monitorNetSpeed) private var netSpeed = true
    @AppStorage(DefaultsKey.monitorNetApps) private var netApps = true
    @AppStorage(DefaultsKey.monitorNetTotals) private var netTotals = true
    @AppStorage(DefaultsKey.monitorNetTest) private var netTest = true

    @AppStorage(DefaultsKey.monitorShowDisk) private var showDisk = true
    @AppStorage(DefaultsKey.monitorDiskUsage) private var diskUsage = true
    @AppStorage(DefaultsKey.monitorDiskActivity) private var diskActivity = true
    @AppStorage(DefaultsKey.monitorDiskSMART) private var diskSMART = true
    @AppStorage(DefaultsKey.monitorDiskProtection) private var diskProtection = true
    @AppStorage(DefaultsKey.monitorDiskTools) private var diskTools = true

    @AppStorage(DefaultsKey.monitorShowPower) private var showPower = true
    @AppStorage(DefaultsKey.monitorPwrSystem) private var pwrSystem = true
    @AppStorage(DefaultsKey.monitorPwrAdapter) private var pwrAdapter = true
    @AppStorage(DefaultsKey.monitorPwrBattery) private var pwrBattery = true
    @AppStorage(DefaultsKey.monitorPwrTimeRemaining) private var pwrTimeRemaining = true
    @AppStorage(DefaultsKey.monitorPwrHealth) private var pwrHealth = true

    @AppStorage(DefaultsKey.monitorShowMixer) private var showMixer = true

    // Whether a block draws its history curve: it only ever draws one here, so
    // it belongs with the rest of what the panel shows.
    @AppStorage(DefaultsKey.monitorGraphCPU) private var graphCPU = true
    @AppStorage(DefaultsKey.monitorGraphGPU) private var graphGPU = true
    @AppStorage(DefaultsKey.monitorGraphMemory) private var graphMemory = true
    @AppStorage(DefaultsKey.monitorGraphNetwork) private var graphNetwork = true
    @AppStorage(DefaultsKey.monitorGraphDisk) private var graphDisk = true
    @AppStorage(DefaultsKey.monitorGraphPower) private var graphPower = true
    @AppStorage(DefaultsKey.monitorGraphBattery) private var graphBattery = true

    var body: some View {
        if PanelSectionID.system.isAvailable {
            block(.system, title: l10n.s.systemSection, master: $showSystem) {
                if AppFeature.monitorCPU.isAvailable || AppFeature.monitorGPU.isAvailable {
                    Toggle(l10n.s.temperatures, isOn: $sysTemps)
                }
                if AppFeature.monitorCPU.isAvailable {
                    Toggle(l10n.s.cpuLabel, isOn: $sysCPU)
                }
                if AppFeature.monitorGPU.isAvailable {
                    Toggle(l10n.s.gpuLabel, isOn: $sysGPU)
                }
                if AppFeature.monitorMemory.isAvailable {
                    Toggle(l10n.s.memorySection, isOn: $sysMemory)
                }
                Toggle(l10n.s.monitorItemUptime, isOn: $sysUptime)
                DisclosureGroup(l10n.s.monitorGraphsSection) {
                    Text(l10n.s.monitorGraphsCaption)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if AppFeature.monitorCPU.isAvailable {
                        Toggle(l10n.s.cpuLabel, isOn: $graphCPU)
                    }
                    if AppFeature.monitorGPU.isAvailable {
                        Toggle(l10n.s.gpuLabel, isOn: $graphGPU)
                    }
                    if AppFeature.monitorMemory.isAvailable {
                        Toggle(l10n.s.memorySection, isOn: $graphMemory)
                    }
                }
            }
        }
        if AppFeature.monitorNetwork.isAvailable {
            block(.network, title: l10n.s.networkSection, master: $showNetwork) {
                Toggle(l10n.s.monitorItemNetSpeed, isOn: $netSpeed)
                Toggle(l10n.s.networkApps, isOn: $netApps)
                Toggle(l10n.s.monitorItemNetTotals, isOn: $netTotals)
                Toggle(l10n.s.monitorItemNetTest, isOn: $netTest)
                Toggle(l10n.s.monitorGraphsSection, isOn: $graphNetwork)
            }
        }
        if AppFeature.monitorDisk.isAvailable {
            block(.disk, title: AppFeature.monitorDisk.name(l10n.s, language: l10n.language), master: $showDisk) {
                Toggle(l10n.s.monitorItemDiskUsage, isOn: $diskUsage)
                Toggle(l10n.s.monitorItemDiskActivity, isOn: $diskActivity)
                Toggle(l10n.s.monitorItemDiskSMART, isOn: $diskSMART)
                Toggle(l10n.s.monitorItemDiskProtection, isOn: $diskProtection)
                Toggle(l10n.s.monitorItemDiskTools, isOn: $diskTools)
                Toggle(l10n.s.monitorGraphsSection, isOn: $graphDisk)
            }
        }
        if AppFeature.monitorPower.isAvailable {
            block(.power, title: AppFeature.monitorPower.name(l10n.s, language: l10n.language), master: $showPower) {
                Toggle(l10n.s.powerSystem, isOn: $pwrSystem)
                Toggle(l10n.s.powerAdapter, isOn: $pwrAdapter)
                if PowerSampler.hasInternalBattery {
                    Toggle(l10n.s.batteryCharge, isOn: $sysBattery)
                    Toggle(l10n.s.powerBattery, isOn: $pwrBattery)
                    Toggle(FeatureStrings.batteryTime(l10n.language).title, isOn: $pwrTimeRemaining)
                    DisclosureGroup(FeatureStrings.mouseClickDebounce(l10n.language).moreOptions) {
                        Toggle(l10n.s.monitorShowBatteryTemperature, isOn: $pwrTemperature)
                        Toggle(l10n.s.powerHealth, isOn: $pwrHealth)
                    }
                }
                DisclosureGroup(l10n.s.monitorGraphsSection) {
                    Toggle(l10n.s.monitorShowPowerLabel, isOn: $graphPower)
                    if PowerSampler.hasInternalBattery {
                        Toggle(l10n.s.batteryLabel, isOn: $graphBattery)
                    }
                }
            }
        }
        // The mixer is a per-app list, so it has no sub-items — just show/hide.
        if AppFeature.mixer.isAvailable {
            Toggle(FeatureStrings.mixer(l10n.language).pageTitle, isOn: $showMixer)
        }
    }

    /// One expandable section: a master "show in panel" toggle, then the per-item
    /// toggles (disabled while the whole block is hidden).
    @ViewBuilder
    private func block<Content: View>(_ id: PanelConfigBlock,
                                      title: String,
                                      master: Binding<Bool>,
                                      @ViewBuilder _ items: @escaping () -> Content) -> some View {
        DisclosureHeaderRow(isExpanded: expansionBinding(for: id)) {
            Text(title)
            Spacer()
        }
        if expandedBlocks.contains(id) {
            Group {
                Toggle(l10n.s.monitorShowInPanel, isOn: master)
                items()
                    .disabled(!master.wrappedValue)
            }
            .disclosureIndent()
        }
    }

    private func expansionBinding(for id: PanelConfigBlock) -> Binding<Bool> {
        Binding(
            get: { expandedBlocks.contains(id) },
            set: { expanded in
                if expanded {
                    expandedBlocks.insert(id)
                } else {
                    expandedBlocks.remove(id)
                }
            }
        )
    }

}

private enum PanelConfigBlock: Hashable {
    case system, network, disk, power
}
