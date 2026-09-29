// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import SwiftUI

/// Which per-app breakdown is expanded in the System section.
enum BreakdownKind {
    case cpu, gpu, memory, energy, network

    func processRefreshInterval(configuredMonitorInterval: Int) -> TimeInterval {
        switch self {
        case .cpu, .gpu, .energy:
            return TimeInterval(Defaults.sanitizedMonitorInterval(configuredMonitorInterval))
        case .memory, .network:
            return 4
        }
    }
}

/// The "System" section of the panel: component temperatures, hardware usage
/// and memory pressure, only the readings that matter, presented cleanly.
/// Tapping CPU, GPU or Memory expands the top consumers of that resource.
struct SystemSection: View {
    @ObservedObject private var l10n = L10n.shared
    @ObservedObject private var monitor = SystemMonitor.shared
    @Environment(\.colorScheme) private var colorScheme
    var collapsible = true
    @State private var expanded: BreakdownKind?
    @State private var alertsExpanded = false
    @State private var breakdownRows: [ProcessUsage] = []
    @State private var breakdownIsLoading = false
    @State private var lastBreakdownRefresh = Date.distantPast
    private let breakdownLimit = 15
    @AppStorage(DefaultsKey.monitorInterval) private var monitorInterval = 2
    @AppStorage(DefaultsKey.temperatureUnit) private var temperatureUnit = TemperatureUnit.celsius.rawValue
    @AppStorage(DefaultsKey.monitorSysTemps) private var sysTemps = true
    @AppStorage(DefaultsKey.monitorSysCPU) private var sysCPU = true
    @AppStorage(DefaultsKey.monitorSysGPU) private var sysGPU = true
    @AppStorage(DefaultsKey.monitorSysMemory) private var sysMemory = true
    @AppStorage(DefaultsKey.monitorSysAlerts) private var sysAlerts = true
    @AppStorage(DefaultsKey.monitorSysUptime) private var sysUptime = true
    @AppStorage(DefaultsKey.panelSystemOrder) private var systemOrderRaw = ""
    @State private var draggingBlock: Block?

    var body: some View {
        PanelSection(.system, title: l10n.s.systemSection, collapsible: collapsible,
                     supportsEditing: true,
                     resetAction: resetPanelDefaults) { editing in
            VStack(alignment: .leading, spacing: 12) {
                MonitorPerformanceStatus()
                let currentBlocks = blocks(editing: editing)
                ForEach(currentBlocks, id: \.self) { block in
                    PanelReorderableItem(item: block,
                                         isEnabled: editing,
                                         order: blockOrderBinding,
                                         dragging: $draggingBlock) {
                        HStack(alignment: .top, spacing: 8) {
                            if editing {
                                PanelDragHandle()
                            }
                            blockContent(block, editing: editing)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
            }
        }
        .onChange(of: expandedMetricIsVisible) { _, visible in
            if !visible {
                expanded = nil
                breakdownRows = []
                breakdownIsLoading = false
            }
        }
        .onReceive(monitor.$snapshot) { _ in
            guard let kind = expanded,
                  Date().timeIntervalSince(lastBreakdownRefresh) >= kind.processRefreshInterval(
                      configuredMonitorInterval: monitorInterval
                  ) * 0.8
            else { return }
            refreshBreakdown()
        }
        .onDisappear {
            expanded = nil
            breakdownRows = []
            breakdownIsLoading = false
        }
    }

    /// Card subsections, filtered by the per-item toggles and metric availability.
    private enum Block: String, PanelOrderItem { case usage, memory, temps, alerts, uptime }

    // Hub availability per metric family: an unavailable metric leaves the
    // card entirely, including the edit-mode hidden rows.
    private var cpuAvailable: Bool { AppFeature.monitorCPU.isAvailable }
    private var gpuAvailable: Bool { AppFeature.monitorGPU.isAvailable }
    private var memoryAvailable: Bool { AppFeature.monitorMemory.isAvailable }

    private var usageVisible: Bool {
        (sysCPU && cpuAvailable) || (sysGPU && gpuAvailable)
    }

    private var visibleBlocks: [Block] {
        orderedBlocks.filter { isBlockAvailable($0) && isVisible($0) }
    }

    private func blocks(editing: Bool) -> [Block] {
        editing ? orderedBlocks.filter(isBlockAvailable) : visibleBlocks
    }

    private func isBlockAvailable(_ block: Block) -> Bool {
        switch block {
        case .temps, .usage: return cpuAvailable || gpuAvailable
        case .memory: return memoryAvailable
        case .alerts, .uptime: return true
        }
    }

    private var orderedBlocks: [Block] {
        _ = systemOrderRaw
        // Alert rules are configured in Settings. Keeping them out of the panel
        // avoids presenting the same controls twice.
        return PanelLayout.itemOrder(Block.self, key: DefaultsKey.panelSystemOrder).filter { $0 != .alerts && $0 != .temps }
    }

    private var blockOrderBinding: Binding<[Block]> {
        Binding {
            orderedBlocks
        } set: { newValue in
            PanelLayout.setItemOrder(newValue, key: DefaultsKey.panelSystemOrder)
        }
    }

    private func isVisible(_ block: Block) -> Bool {
        switch block {
        case .temps: return sysTemps
        case .usage: return usageVisible
        case .memory: return sysMemory
        case .alerts: return sysAlerts
        case .uptime: return sysUptime
        }
    }

    private func resetPanelDefaults() {
        PanelLayout.resetItemOrder(key: DefaultsKey.panelSystemOrder)
        systemOrderRaw = ""
        sysTemps = true
        sysCPU = true
        sysGPU = true
        sysMemory = true
        sysAlerts = true
        sysUptime = true
    }

    @ViewBuilder
    private func blockContent(_ block: Block, editing: Bool) -> some View {
        switch block {
        case .temps: EmptyView()
        case .usage: usageRows(editing: editing)
        case .memory: memoryRows(editing: editing).panelCard()
        case .alerts: alertRows(editing: editing)
        case .uptime: uptimeRow(editing: editing)
        }
    }

    // MARK: Per-app breakdown

    private var expandedMetricIsVisible: Bool {
        switch expanded {
        case .cpu: return sysCPU && cpuAvailable
        case .gpu: return sysGPU && gpuAvailable
        case .memory: return sysMemory && memoryAvailable
        case .energy, .network: return false
        case nil: return true
        }
    }

    private func toggleBreakdown(_ kind: BreakdownKind) {
        if expanded == kind {
            expanded = nil
            breakdownRows = []
            breakdownIsLoading = false
        } else {
            expanded = kind
            breakdownRows = ProcessUsageService.shared.cachedTop(kind, limit: breakdownLimit) ?? []
            refreshBreakdown()
        }
    }

    private func refreshBreakdown() {
        guard let kind = expanded else { return }
        lastBreakdownRefresh = Date()
        breakdownIsLoading = breakdownRows.isEmpty
        let sampleInterval = percentageSampleInterval
        let cpuPercentage = monitor.snapshot.cpuUsage.map { $0 * 100 }
        let gpuPercentage = monitor.snapshot.gpuUsage.map { $0 * 100 }
        DispatchQueue.global(qos: .utility).async {
            let rows = ProcessUsageService.shared.top(kind,
                                                      limit: breakdownLimit,
                                                      sampleInterval: sampleInterval,
                                                      cpuPercentage: cpuPercentage,
                                                      gpuPercentage: gpuPercentage)
            DispatchQueue.main.async {
                guard expanded == kind else { return }
                breakdownIsLoading = false
                if !rows.isEmpty || breakdownRows.isEmpty {
                    breakdownRows = rows
                }
            }
        }
    }

    private var percentageSampleInterval: TimeInterval {
        TimeInterval(Defaults.sanitizedMonitorInterval(monitorInterval))
    }

    @ViewBuilder
    private func breakdownList(for kind: BreakdownKind) -> some View {
        if expanded == kind {
            VStack(alignment: .leading, spacing: 4) {
                if breakdownRows.isEmpty {
                    Text(breakdownIsLoading ? l10n.s.breakdownMeasuring : emptyBreakdownText(for: kind))
                        .font(PanelTypography.meta)
                        .foregroundStyle(.tertiary)
                        .padding(.leading, 4)
                } else {
                    ForEach(breakdownRows) { row in
                        ProcessUsageRow(row: row,
                                        value: breakdownValue(row, for: kind),
                                        iconSize: 14,
                                        leadingPadding: 4)
                    }
                }
            }
        }
    }

    private func emptyBreakdownText(for kind: BreakdownKind) -> String {
        kind == .energy ? l10n.s.energyAppsIdle : l10n.s.breakdownMeasuring
    }

    private func breakdownValue(_ row: ProcessUsage, for kind: BreakdownKind) -> String {
        kind == .memory ? formatMemory(UInt64(row.value))
                        : String(format: "%.1f%%", locale: MetricFormat.locale, row.value)
    }

    private var displayTemperatureUnit: TemperatureUnit {
        TemperatureUnit(rawValue: temperatureUnit) ?? .celsius
    }

    // MARK: Hardware usage

    private func usageRows(editing: Bool) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                subsectionLabel(l10n.s.usageSection)
                Spacer()
                if !editing { ActivityMonitorButton() }
            }
            VStack(alignment: .leading, spacing: 12) {
                if sysCPU, cpuAvailable {
                    usageRow(label: l10n.s.cpuLabel, fraction: monitor.snapshot.cpuUsage,
                             kind: .cpu, editing: editing, visible: $sysCPU)
                } else if editing, cpuAvailable {
                    PanelHiddenItemRow(title: l10n.s.cpuLabel, systemImage: "cpu", isVisible: $sysCPU)
                }
                if cpuAvailable && gpuAvailable && (editing || (sysCPU && sysGPU)) {
                    Divider().opacity(0.5)
                }
                if sysGPU, gpuAvailable {
                    usageRow(label: l10n.s.gpuLabel, fraction: monitor.snapshot.gpuUsage,
                             kind: .gpu, editing: editing, visible: $sysGPU)
                } else if editing, gpuAvailable {
                    PanelHiddenItemRow(title: l10n.s.gpuLabel, systemImage: "memorychip", isVisible: $sysGPU)
                }
            }
            .panelCard()
        }
    }

    // MARK: Uptime

    @ViewBuilder
    private func uptimeRow(editing: Bool) -> some View {
        if !sysUptime {
            PanelHiddenItemRow(title: l10n.s.monitorItemUptime, systemImage: "clock", isVisible: $sysUptime)
        } else {
            HStack(spacing: 6) {
                Image(systemName: "clock")
                    .font(PanelTypography.meta)
                    .foregroundStyle(.secondary)
                Text("\(l10n.s.systemUptime) \(Self.uptimeString())")
                    .font(PanelTypography.meta)
                    .foregroundStyle(.secondary)
                Spacer()
                if editing {
                    PanelInlineHideButton(isVisible: $sysUptime)
                }
            }
        }
    }

    static func uptimeString() -> String {
        let total = SystemInfo.wallClockUptimeSeconds() ?? Int(ProcessInfo.processInfo.systemUptime)
        return MetricFormat.uptime(total)
    }

    private static let memoryFormatter: ByteCountFormatter = {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .memory
        return formatter
    }()

    private func usageRow(label: String, fraction: Double?, kind: BreakdownKind,
                          editing: Bool, visible: Binding<Bool>) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                HStack(spacing: 8) {
                    MetricSymbol(name: kind == .cpu ? "cpu" : "memorychip")
                    Text(label).font(PanelTypography.title)
                }
                .frame(width: 64, alignment: .leading)
                Button {
                    toggleBreakdown(kind)
                } label: {
                    HStack(spacing: 4) {
                        Text(fraction.map { String(format: "%.0f%%", locale: MetricFormat.locale, $0 * 100) } ?? "–")
                            .font(PanelTypography.metric)
                            .monospacedDigit()
                            .lineLimit(1)
                        if !editing {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 8, weight: .semibold))
                                .rotationEffect(.degrees(expanded == kind ? 90 : 0))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(width: 60, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(editing)
                .accessibilityLabel(label)
                .accessibilityValue(fraction.map { String(format: "%.0f%%", locale: MetricFormat.locale, $0 * 100) } ?? "–")
                if sysTemps {
                    let temperature = kind == .cpu ? monitor.snapshot.cpuTemperature : monitor.snapshot.gpuTemperature
                    Label(temperature.map { MetricFormat.temperature($0, unit: displayTemperatureUnit) } ?? "–",
                          systemImage: "thermometer.medium")
                        .font(PanelTypography.label)
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
                if editing { PanelInlineHideButton(isVisible: visible) }
            }
            if kind == .cpu {
                CPUCoreMatrix(usage: monitor.snapshot.cpuCoreUsage)
            }
            if !editing {
                MonitorTrendView(metrics: [kind == .cpu ? .cpu : .gpu], embedded: true)
                breakdownList(for: kind)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: Memory

    @ViewBuilder
    private func memoryRows(editing: Bool) -> some View {
        if !sysMemory {
            PanelHiddenItemRow(title: l10n.s.memorySection,
                               systemImage: "memorychip.fill",
                               isVisible: $sysMemory)
        } else {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    if editing {
                        memoryRowContent(isInteractive: false)
                        PanelInlineHideButton(isVisible: $sysMemory)
                    } else {
                        Button {
                            toggleBreakdown(.memory)
                        } label: {
                            memoryRowContent(isInteractive: true)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
                let used = MonitorMemoryMetric.current.value(in: monitor.snapshot)
                if let used, let total = monitor.snapshot.memoryTotal, total > 0 {
                    MetricScale(fraction: Double(used) / Double(total))
                        .padding(.vertical, 8)
                }
                HStack(alignment: .top, spacing: 12) {
                    memorySecondaryRow(l10n.s.memoryCompressed, monitor.snapshot.memoryCompressed)
                    memorySecondaryRow(l10n.s.memoryCachedFiles, monitor.snapshot.memoryCached)
                    memorySecondaryRow(l10n.s.memorySwapUsed, monitor.snapshot.memorySwapUsed)
                }
                if !editing {
                    MonitorTrendView(metrics: [MonitorMemoryMetric.current == .app ? .memoryApp : .memory], embedded: true)
                }
                breakdownList(for: .memory)
            }
        }
    }

    @ViewBuilder
    private func memorySecondaryRow(_ title: String, _ bytes: UInt64?) -> some View {
        if let bytes {
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(PanelTypography.label)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Text(formatMemory(bytes))
                    .font(PanelTypography.metric)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func memoryRowContent(isInteractive: Bool) -> some View {
        HStack(spacing: 8) {
            Text(l10n.s.memorySection)
                .font(PanelTypography.title)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            let memoryValue = MonitorMemoryMetric.current.value(in: monitor.snapshot)
            if let used = memoryValue, let total = monitor.snapshot.memoryTotal {
                HStack(alignment: .firstTextBaseline, spacing: 3) {
                    Text(formatMemory(used)).font(PanelTypography.metric)
                    Text("/ \(formatMemory(total))")
                        .font(PanelTypography.meta)
                        .foregroundStyle(.secondary)
                }
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            }
            Spacer(minLength: 0)
            PressureIndicator(pressure: monitor.snapshot.memoryPressure)
                .fixedSize()
                .help(l10n.s.memoryPressure)
            if isInteractive {
                Image(systemName: "chevron.right")
                    .font(.system(size: 8, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .rotationEffect(.degrees(expanded == .memory ? 90 : 0))
            }
        }
    }

    private func subsectionLabel(_ text: String) -> some View {
        Text(text)
            .font(PanelTypography.title)
            .foregroundStyle(.secondary)
    }

    @ViewBuilder
    private func alertRows(editing: Bool) -> some View {
        let text = FeatureStrings.monitorAlerts(l10n.language)
        if !sysAlerts {
            PanelHiddenItemRow(title: text.section,
                               systemImage: "bell.badge",
                               isVisible: $sysAlerts)
        } else {
            VStack(alignment: .leading, spacing: 7) {
                HStack(spacing: 6) {
                    Button {
                        alertsExpanded.toggle()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 8, weight: .semibold))
                                .foregroundStyle(.secondary)
                                .rotationEffect(.degrees(alertsExpanded ? 90 : 0))
                            subsectionLabel(text.section)
                            Spacer(minLength: 0)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    if editing {
                        PanelInlineHideButton(isVisible: $sysAlerts)
                    }
                }
                if alertsExpanded {
                    MonitorAlertsControls(compact: true)
                }
            }
        }
    }

    private func formatMemory(_ bytes: UInt64) -> String {
        Self.memoryFormatter.string(fromByteCount: Int64(bytes))
    }
}

/// Capacity with a known total; zero has no visible fill.
struct UsageBar: View {
    let fraction: Double

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.primary.opacity(0.08))
                if fraction.isFinite, fraction > 0 {
                    Capsule().fill(PanelMetricColor.data)
                        .frame(width: proxy.size.width * min(1, fraction))
                }
            }
        }
        .frame(height: 4)
    }
}

/// Traffic-light pill for memory pressure: green = normal, yellow = caution,
/// red = critical.
struct PressureIndicator: View {
    @ObservedObject private var l10n = L10n.shared
    @Environment(\.colorScheme) private var colorScheme
    let pressure: MemoryPressure

    var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(color)
                .frame(width: 7, height: 7)
            Text(label)
                .font(.system(.subheadline, weight: .medium))
                .foregroundStyle(color)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(Capsule().fill(color.opacity(0.13)))
    }

    private var color: Color {
        switch pressure {
        case .normal: return PanelMetricColor.green(for: colorScheme)
        case .warning: return PanelMetricColor.yellow(for: colorScheme)
        case .critical: return PanelMetricColor.red(for: colorScheme)
        case .unknown: return .secondary
        }
    }

    private var label: String {
        switch pressure {
        case .normal: return l10n.s.pressureNormal
        case .warning: return l10n.s.pressureWarning
        case .critical: return l10n.s.pressureCritical
        case .unknown: return "-"
        }
    }
}

struct MetricScale: View {
    var fraction: Double?

    var body: some View {
        if let fraction, fraction.isFinite {
            UsageBar(fraction: fraction).accessibilityHidden(true)
        }
    }
}
