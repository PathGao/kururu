// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import SwiftUI
import UniformTypeIdentifiers

/// What the menu bar icon shows and how it looks. Its tenants — the monitor's
/// metrics, the microphone indicator — appear here because this is where they
/// are placed; each keeps whatever else it does on its own page.
struct MenuBarIconSettings: View {
    @ObservedObject private var l10n = L10n.shared
    @AppStorage(DefaultsKey.menuBarHideIconWithMetrics) private var hideIconWithMetrics = false
    @AppStorage(DefaultsKey.menuBarCombineTemperatures) private var combineTemperatures = true
    @AppStorage(DefaultsKey.menuBarSeparateMetrics) private var separateMetrics = false
    @AppStorage(DefaultsKey.menuBarMetricSpacing) private var metricSpacing = "standard"
    @AppStorage(DefaultsKey.menuBarMetricAppearance) private var metricAppearance = "values"
    @AppStorage(DefaultsKey.micMuteMenuBarIndicator) private var micMenuBarIndicator = true

    var body: some View {
        let appearanceStrings = FeatureStrings.menuBarAppearance(l10n.language)
        let appearance = MenuBarMetricAppearance(
            rawValue: Defaults.sanitizedMenuBarMetricAppearance(metricAppearance)
        ) ?? .values
        Form {
            Section(l10n.s.monitorMenuBarSection) {
                MenuBarMetricsPreview()
                    .padding(.vertical, 10)
                Text(l10n.s.monitorMenuBarCaption)
                    .font(.caption).foregroundStyle(.secondary)
            }
            Section(appearanceStrings.label) {
                Picker(appearanceStrings.label, selection: $metricAppearance) {
                    Text(appearanceStrings.values).tag("values")
                    Text(appearanceStrings.bars).tag("bars")
                }
                .pickerStyle(.segmented)
                Text(appearanceStrings.caption)
                    .font(.caption).foregroundStyle(.secondary)
                if appearance == .bars {
                    MenuBarUsageBarSettings(strings: appearanceStrings)
                } else {
                    Toggle(l10n.s.monitorCombineTemperatures, isOn: $combineTemperatures)
                    Text(l10n.s.monitorCombineTemperaturesCaption)
                        .font(.caption).foregroundStyle(.secondary)
                }
                Picker(l10n.s.menuBarSpacingLabel, selection: $metricSpacing) {
                    Text(l10n.s.menuBarSpacingStandard).tag("standard")
                    Text(l10n.s.menuBarSpacingCompact).tag("compact")
                }
                .pickerStyle(.segmented)
                Toggle(l10n.s.monitorSeparateMenuBarMetrics, isOn: $separateMetrics)
                if appearance.allowsCombinedTemperatures {
                    Text(l10n.s.monitorSeparateMenuBarMetricsCaption)
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            Section(appearanceStrings.metricsTitle) {
                MenuBarMetricOrderEditor()
            }
            Section {
                Toggle(l10n.s.menuBarHideIconToggle, isOn: $hideIconWithMetrics)
                Text(l10n.s.menuBarHideIconCaption)
                    .font(.caption).foregroundStyle(.secondary)
                Button(l10n.s.showMenuBarIcon) {
                    appDelegate()?.reshowStatusItem()
                }
                Text(l10n.s.showMenuBarIconCaption)
                    .font(.caption).foregroundStyle(.secondary)
            }
            if AppFeature.micMute.isAvailable {
                Section(AppFeature.micMute.name(l10n.s, language: l10n.language)) {
                    Toggle(FeatureStrings.micMute(l10n.language).menuBarToggle,
                           isOn: $micMenuBarIndicator)
                    Text(FeatureStrings.micMute(l10n.language).menuBarCaption)
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
        }
        .formStyle(.grouped)
        .onAppear {
            metricAppearance = Defaults.sanitizedMenuBarMetricAppearance(metricAppearance)
        }
    }
}

private struct MenuBarUsageBarSettings: View {
    let strings: MenuBarAppearanceStrings

    @AppStorage(DefaultsKey.menuBarUsageBarNormalColor) private var normalColor = MenuBarUsageBarSupport.defaultNormalColor
    @AppStorage(DefaultsKey.menuBarUsageBarElevatedColor) private var elevatedColor = MenuBarUsageBarSupport.defaultElevatedColor
    @AppStorage(DefaultsKey.menuBarUsageBarCriticalColor) private var criticalColor = MenuBarUsageBarSupport.defaultCriticalColor
    @AppStorage(DefaultsKey.menuBarUsageBarMediumThreshold) private var mediumThreshold = MenuBarUsageBarSupport.defaultMediumThreshold
    @AppStorage(DefaultsKey.menuBarUsageBarHighThreshold) private var highThreshold = MenuBarUsageBarSupport.defaultHighThreshold

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            Text(strings.customize)
                .font(.subheadline.weight(.semibold))

            ColorPicker(strings.normalColor,
                        selection: colorBinding($normalColor,
                                                fallback: MenuBarUsageBarSupport.defaultNormalColor),
                        supportsOpacity: false)
            ColorPicker(strings.mediumColor,
                        selection: colorBinding($elevatedColor,
                                                fallback: MenuBarUsageBarSupport.defaultElevatedColor),
                        supportsOpacity: false)
            ColorPicker(strings.highColor,
                        selection: colorBinding($criticalColor,
                                                fallback: MenuBarUsageBarSupport.defaultCriticalColor),
                        supportsOpacity: false)

            Divider()

            Stepper(value: mediumBinding, in: 1...99) {
                HStack {
                    Text(strings.mediumFrom)
                    Spacer()
                    Text("\(mediumThreshold)%")
                        .monospacedDigit()
                }
            }
            Stepper(value: highBinding, in: 2...100) {
                HStack {
                    Text(strings.highFrom)
                    Spacer()
                    Text("\(highThreshold)%")
                        .monospacedDigit()
                }
            }
        }
        .padding(.leading, 12)
        .onAppear(perform: sanitize)
    }

    private var mediumBinding: Binding<Int> {
        Binding(get: { mediumThreshold },
                set: { mediumThreshold = min(max(1, $0), max(1, highThreshold - 1)) })
    }

    private var highBinding: Binding<Int> {
        Binding(get: { highThreshold },
                set: { highThreshold = min(100, max(mediumThreshold + 1, $0)) })
    }

    private func colorBinding(_ storage: Binding<String>, fallback: String) -> Binding<Color> {
        Binding {
            let rgb = MenuBarUsageBarSupport.rgb(for: storage.wrappedValue, fallback: fallback)
            return Color(red: rgb.red, green: rgb.green, blue: rgb.blue)
        } set: { color in
            guard let converted = NSColor(color).usingColorSpace(.sRGB) else { return }
            storage.wrappedValue = MenuBarUsageBarSupport.hex(red: Double(converted.redComponent),
                                                              green: Double(converted.greenComponent),
                                                              blue: Double(converted.blueComponent))
        }
    }

    private func sanitize() {
        normalColor = MenuBarUsageBarSupport.sanitizedColorHex(normalColor,
                                                               fallback: MenuBarUsageBarSupport.defaultNormalColor)
        elevatedColor = MenuBarUsageBarSupport.sanitizedColorHex(elevatedColor,
                                                                 fallback: MenuBarUsageBarSupport.defaultElevatedColor)
        criticalColor = MenuBarUsageBarSupport.sanitizedColorHex(criticalColor,
                                                                 fallback: MenuBarUsageBarSupport.defaultCriticalColor)
        let thresholds = MenuBarUsageBarSupport.thresholds(medium: mediumThreshold,
                                                           high: highThreshold)
        mediumThreshold = thresholds.medium
        highThreshold = thresholds.high
    }
}

/// Drag-to-reorder and show/hide list for the menu bar metrics. The order stays
/// independent from which metrics are visible, so toggles do not reshuffle it.
struct MenuBarMetricOrderEditor: View {
    @ObservedObject private var l10n = L10n.shared
    @ObservedObject private var features = FeatureRuntime.shared
    @AppStorage(DefaultsKey.menuBarMetricOrder) private var metricOrder = ""
    @State private var order: [MenuBarMetric] = MenuBarMetric.order(in: .standard)
    @State private var dragging: MenuBarMetric?

    var body: some View {
        VStack(spacing: 0) {
            ForEach(visibleOrder) { metric in
                VStack(spacing: 0) {
                    HStack(spacing: 8) {
                        HStack(spacing: 8) {
                            Image(systemName: "line.3.horizontal")
                                .font(.system(size: 12))
                                .foregroundStyle(.tertiary)
                            Image(systemName: metric.symbolName)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(.secondary)
                                .frame(width: 18)
                            Text(metric.title(l10n.s))
                            Spacer(minLength: 0)
                        }
                        .frame(maxWidth: .infinity)
                        .contentShape(Rectangle())
                        .opacity(dragging == metric ? 0.45 : 1)
                        .onDrag {
                            dragging = metric
                            return NSItemProvider(object: metric.rawValue as NSString)
                        }
                        .onDrop(of: [UTType.text],
                                delegate: MenuBarMetricOrderDropDelegate(target: metric,
                                                                         order: $order,
                                                                         dragging: $dragging))

                        MenuBarMetricVisibilityToggle(metric: metric)
                    }
                    .frame(height: 32)

                    if metric == .memory {
                        MemoryMenuBarOrderOption()
                    }

                    if metric == .network {
                        NetworkMenuBarOrderOption()
                    }

                    if metric != visibleOrder.last {
                        Divider()
                    }
                }
            }
        }
        .padding(.vertical, 2)
        .onAppear { order = MenuBarMetric.order(in: .standard) }
        .onChange(of: metricOrder) { _, _ in order = MenuBarMetric.order(in: .standard) }
    }

    /// Metrics whose family left the hub keep their saved slot but stay out
    /// of the editor until they return.
    private var visibleOrder: [MenuBarMetric] {
        order.filter { $0.feature.isAvailable && $0.isAvailableOnCurrentHardware }
    }
}

private struct MenuBarMetricOrderDropDelegate: DropDelegate {
    let target: MenuBarMetric
    @Binding var order: [MenuBarMetric]
    @Binding var dragging: MenuBarMetric?

    func dropEntered(info: DropInfo) {
        guard let dragging,
              dragging != target,
              let from = order.firstIndex(of: dragging),
              let to = order.firstIndex(of: target) else { return }

        withAnimation(.easeInOut(duration: 0.12)) {
            order.move(fromOffsets: IndexSet(integer: from), toOffset: to > from ? to + 1 : to)
        }
        MenuBarMetric.setOrder(order)
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }

    func performDrop(info: DropInfo) -> Bool {
        dragging = nil
        MenuBarMetric.setOrder(order)
        return true
    }
}

private struct MenuBarMetricVisibilityToggle: View {
    @ObservedObject private var l10n = L10n.shared
    let metric: MenuBarMetric
    @AppStorage private var shown: Bool

    init(metric: MenuBarMetric) {
        self.metric = metric
        _shown = AppStorage(wrappedValue: false, metric.defaultsKey)
    }

    var body: some View {
        PanelInlineHideButton(isVisible: $shown)
            .accessibilityValue(metric.title(l10n.s))
    }

}

private struct MemoryMenuBarOrderOption: View {
    @ObservedObject private var l10n = L10n.shared
    @AppStorage(DefaultsKey.menuBarMemory) private var menuBarMemory = false
    @AppStorage(DefaultsKey.menuBarMemoryStyle) private var memoryStyle = "percent"

    var body: some View {
        if menuBarMemory {
            MetricRowOptionToggle(label: l10n.s.monitorMemoryPressureDot,
                                  isOn: Binding(
                                      get: { Defaults.sanitizedMenuBarMemoryStyle(memoryStyle) != "percent" },
                                      set: { memoryStyle = $0 ? "both" : "percent" }))
                .onAppear {
                    memoryStyle = Defaults.sanitizedMenuBarMemoryStyle(memoryStyle)
                }
        }
    }
}

private struct NetworkMenuBarOrderOption: View {
    @ObservedObject private var l10n = L10n.shared
    @AppStorage(DefaultsKey.menuBarNetwork) private var menuBarNetwork = false
    @AppStorage(DefaultsKey.menuBarNetworkUploadFirst) private var uploadFirst = false

    var body: some View {
        if menuBarNetwork {
            MetricRowOptionToggle(label: l10n.s.monitorNetworkUploadFirst, isOn: $uploadFirst)
        }
    }
}

/// Inline per-metric option row: caption on the left, a switch on the right,
/// indented under its metric. The switch is a hand-rolled capsule Button on
/// purpose: a native Toggle inside the reorderable metric list never receives
/// the click (the row's drag handling swallows it), while a plain Button does.
private struct MetricRowOptionToggle: View {
    let label: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 8) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer(minLength: 0)
            Button {
                isOn.toggle()
            } label: {
                ZStack(alignment: isOn ? .trailing : .leading) {
                    Capsule()
                        .fill(isOn ? Color.accentColor : Color.secondary.opacity(0.28))
                        .frame(width: 28, height: 16)
                    Circle()
                        .fill(Color.white)
                        .frame(width: 12, height: 12)
                        .padding(2)
                }
                .frame(width: 30, height: 20)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help(label)
            .accessibilityLabel(label)
            .accessibilityValue(isOn ? "1" : "0")
        }
        .padding(.leading, 58)
        .padding(.trailing, 4)
        .padding(.bottom, 7)
    }
}

