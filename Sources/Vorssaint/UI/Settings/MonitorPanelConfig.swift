// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import SwiftUI

/// Section visibility and child options shared by the monitoring and panel settings pages.
struct MonitorPanelConfig: View {
    var includeMixer = true
    var includeUtilities = true
    var includeStandaloneSections = false
    @ObservedObject private var l10n = L10n.shared
    @ObservedObject private var features = FeatureRuntime.shared
    @State private var expandedBlocks = Set<PanelSectionID>()

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

    @AppStorage(DefaultsKey.panelShowFanControl) private var showFanControl = true
    @AppStorage(DefaultsKey.panelShowKeepAwake) private var showKeepAwake = true
    @AppStorage(DefaultsKey.panelShowBrightness) private var showBrightness = true
    @AppStorage(DefaultsKey.panelShowControls) private var showControls = true
    @AppStorage(DefaultsKey.monitorShowMixer) private var showMixer = true
    @AppStorage(DefaultsKey.panelShowUtilities) private var showUtilities = true
    @AppStorage(DefaultsKey.panelUtilityClipboard) private var showClipboard = true
    @AppStorage(DefaultsKey.panelUtilityURLCleaner) private var showURLCleaner = true

    var body: some View {
        if includeStandaloneSections {
            if PanelSectionID.keepAwake.isAvailable {
                visibilityRow(.keepAwake, master: $showKeepAwake)
            }
            if PanelSectionID.brightness.isAvailable {
                visibilityRow(.brightness, master: $showBrightness)
            }
            if PanelSectionID.controls.isAvailable {
                visibilityRow(.controls, master: $showControls)
            }
            if AppFeature.fanControl.isAvailable {
                let unavailable = AppFeature.fanControl.hardwareUnsupportedReason
                visibilityRow(.fanControl, master: $showFanControl)
                    .disabled(unavailable != nil)
                    .opacity(unavailable == nil ? 1 : 0.55)
                    .help(unavailable ?? "")
                if let unavailable {
                    Text(unavailable)
                        .font(SettingsTypography.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.leading, 28)
                }
            }
        }
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
            }
        }
        if AppFeature.monitorNetwork.isAvailable {
            block(.network, title: l10n.s.networkSection, master: $showNetwork) {
                Toggle(l10n.s.monitorItemNetSpeed, isOn: $netSpeed)
                Toggle(l10n.s.networkApps, isOn: $netApps)
                Toggle(l10n.s.monitorItemNetTotals, isOn: $netTotals)
                Toggle(l10n.s.monitorItemNetTest, isOn: $netTest)
            }
        }
        if AppFeature.monitorDisk.isAvailable {
            block(.disk, title: AppFeature.monitorDisk.name(l10n.s, language: l10n.language), master: $showDisk) {
                Toggle(l10n.s.monitorItemDiskUsage, isOn: $diskUsage)
                Toggle(l10n.s.monitorItemDiskActivity, isOn: $diskActivity)
                Toggle(l10n.s.monitorItemDiskSMART, isOn: $diskSMART)
                Toggle(l10n.s.monitorItemDiskProtection, isOn: $diskProtection)
                Toggle(l10n.s.monitorItemDiskTools, isOn: $diskTools)
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
            }
        }
        // The mixer is a per-app list, so it has no sub-items — just show/hide.
        if includeMixer, AppFeature.mixer.isAvailable {
            visibilityRow(.mixer, master: $showMixer)
        }
        if includeUtilities, PanelSectionID.utilities.isAvailable {
            if AppFeature.clipboardHistory.isAvailable || AppFeature.urlCleaner.isAvailable {
                block(.utilities, title: l10n.s.utilitiesSection, master: $showUtilities) {
                    if AppFeature.clipboardHistory.isAvailable {
                        Toggle(AppFeature.clipboardHistory.name(l10n.s, language: l10n.language), isOn: $showClipboard)
                    }
                    if AppFeature.urlCleaner.isAvailable {
                        Toggle(l10n.s.urlCleanerName, isOn: $showURLCleaner)
                    }
                }
            } else {
                visibilityRow(.utilities, master: $showUtilities)
            }
        }
    }

    private func visibilityRow(_ id: PanelSectionID, master: Binding<Bool>) -> some View {
        HStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: id.symbolName)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.secondary)
                    .frame(width: 20)
                    .accessibilityHidden(true)
                Text(id.title(l10n.s)).font(SettingsTypography.body.weight(.medium))
                Spacer()
            }
            Toggle(l10n.s.monitorShowInPanel, isOn: master)
                .toggleStyle(.switch).controlSize(.regular)
                .labelsHidden()
                .accessibilityLabel("\(id.title(l10n.s)): \(l10n.s.monitorShowInPanel)")
        }
    }

    /// The visibility switch stays discoverable when item options are collapsed.
    @ViewBuilder
    private func block<Content: View>(_ id: PanelSectionID,
                                      title: String,
                                      master: Binding<Bool>,
                                      @ViewBuilder _ items: @escaping () -> Content) -> some View {
        HStack(spacing: 12) {
            DisclosureHeaderRow(isExpanded: expansionBinding(for: id)) {
                Image(systemName: id.symbolName)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.secondary)
                    .frame(width: 20)
                Text(title).font(.system(size: 13, weight: .medium))
                Spacer()
            }
            Toggle(l10n.s.monitorShowInPanel, isOn: master)
                .toggleStyle(.switch).controlSize(.regular)
                .labelsHidden()
                .accessibilityLabel("\(title): \(l10n.s.monitorShowInPanel)")
        }
        if expandedBlocks.contains(id) {
            VStack(alignment: .leading, spacing: 12) {
                if !master.wrappedValue {
                    Text(UXEntryStrings(l10n.language).hiddenOptions)
                        .font(.callout).foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                items()
            }
            .disclosureIndent()
        }
    }

    private func expansionBinding(for id: PanelSectionID) -> Binding<Bool> {
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
