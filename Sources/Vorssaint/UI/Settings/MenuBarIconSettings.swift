// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import SwiftUI
import UniformTypeIdentifiers

/// What the menu bar icon shows and how it looks. Its tenants — the monitor's
/// metrics, the microphone indicator — appear here because this is where they
/// are placed; each keeps whatever else it does on its own page.
struct MenuBarIconSettings: View {
    @ObservedObject private var l10n = L10n.shared
    @ObservedObject private var features = FeatureRuntime.shared
    @State private var activeMetricCount = 0
    @AppStorage(DefaultsKey.menuBarHideIconWithMetrics) private var hideIconWithMetrics = false
    @AppStorage(DefaultsKey.menuBarCombineTemperatures) private var combineTemperatures = true
    @AppStorage(DefaultsKey.menuBarSeparateMetrics) private var separateMetrics = false
    @AppStorage(DefaultsKey.menuBarMetricSpacing) private var metricSpacing = "standard"
    @AppStorage(DefaultsKey.menuBarMetricAppearance) private var metricAppearance = "values"

    private var workspace: ModuleWorkspaceStrings { ModuleWorkspaceStrings(l10n.language) }

    var body: some View {
        let appearanceStrings = FeatureStrings.menuBarAppearance(l10n.language)
        let appearance = MenuBarMetricAppearance(
            rawValue: Defaults.sanitizedMenuBarMetricAppearance(metricAppearance)
        ) ?? .values
        SettingsForm {
            SettingsSection(l10n.s.monitorMenuBarSection) {
                if FeatureUnit.monitor.isAvailable {
                    MenuBarMetricsPreview()
                } else {
                    // Mic mute's row does not depend on the monitor, so the
                    // editor below renders either way.
                    Text(workspace.inactiveMonitor)
                        .fixedSize(horizontal: false, vertical: true)
                    Button(workspace.add) { FeatureRuntime.shared.setAvailable(.monitor, true) }
                        .buttonStyle(.borderedProminent)
                }
                MenuBarMetricOrderEditor()
                if FeatureUnit.monitor.isAvailable, activeMetricCount == 0 {
                    Text(workspace.noMetrics)
                        .font(SettingsTypography.caption)
                        .foregroundStyle(.secondary)
                }
            }
            SettingsSection(appearanceStrings.metricStyle) {
                if activeMetricCount == 0 {
                    Text(workspace.deferredAppearance)
                        .fixedSize(horizontal: false, vertical: true)
                }
                SettingsControlRow(title: appearanceStrings.label,
                                   systemImage: "chart.bar",
                                   help: appearanceStrings.caption) {
                    Picker(appearanceStrings.label, selection: $metricAppearance) {
                        Text(appearanceStrings.values).tag("values")
                        Text(appearanceStrings.bars).tag("bars")
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                }
                if appearance == .bars {
                    MenuBarUsageBarSettings(strings: appearanceStrings)
                } else {
                    SettingsToggleWithCaption(title: l10n.s.monitorCombineTemperatures,
                                              caption: l10n.s.monitorCombineTemperaturesCaption,
                                              showsCaptionInline: false,
                                              isOn: $combineTemperatures)
                }
                Picker(l10n.s.menuBarSpacingLabel, selection: $metricSpacing) {
                    Text(l10n.s.menuBarSpacingStandard).tag("standard")
                    Text(l10n.s.menuBarSpacingCompact).tag("compact")
                }
                .pickerStyle(.segmented)
                if appearance.allowsCombinedTemperatures {
                    SettingsToggleWithCaption(title: l10n.s.monitorSeparateMenuBarMetrics,
                                              caption: l10n.s.monitorSeparateMenuBarMetricsCaption,
                                              showsCaptionInline: false,
                                              isOn: $separateMetrics)
                } else {
                    Toggle(l10n.s.monitorSeparateMenuBarMetrics, isOn: $separateMetrics)
                }
            }
            SettingsSection(l10n.s.menuBarIconSection) {
                SettingsToggleWithCaption(title: l10n.s.menuBarHideIconToggle,
                                          caption: l10n.s.menuBarHideIconCaption,
                                          showsCaptionInline: false,
                                          isOn: $hideIconWithMetrics)
                HStack(spacing: 6) {
                    Button(l10n.s.showMenuBarIcon) {
                        appDelegate()?.reshowStatusItem()
                    }
                    SettingsHelpButton(title: l10n.s.showMenuBarIcon, text: l10n.s.showMenuBarIconCaption)
                }
            }
        }
        .formStyle(.grouped)
        .onAppear {
            metricAppearance = Defaults.sanitizedMenuBarMetricAppearance(metricAppearance)
            refreshMetricCount()
        }
        .onReceive(NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)) { _ in
            refreshMetricCount()
        }
        .onChange(of: features.revision) { _, _ in refreshMetricCount() }
    }

    private func refreshMetricCount() {
        activeMetricCount = MenuBarMetric.enabled(in: .standard).count
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

            Stepper(value: mediumBinding, in: 1...99) {
                HStack {
                    Text(strings.mediumFrom)
                    Spacer()
                    Text("\(mediumThreshold)%")
                        .monospacedDigit()
                }
            }
            .padding(.top, 8)
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

/// What the icon carries, one row per feature it comes from, like the panel's
/// Controls and Utilities rows. Monitor expands to its order strip above a
/// checkbox grid; Mic mute has a single item, so its row is the checkbox.
struct MenuBarMetricOrderEditor: View {
    @ObservedObject private var l10n = L10n.shared
    @ObservedObject private var features = FeatureRuntime.shared
    @AppStorage(DefaultsKey.menuBarMetricOrder) private var metricOrder = ""
    @State private var order: [MenuBarMetric] = MenuBarMetric.order(in: .standard)
    @State private var dragging: MenuBarMetric?
    @State private var monitorExpanded = false
    @State private var revision = 0

    var body: some View {
        let _ = revision
        let available = Self.availableOrder(order)
        let shown = available.filter { UserDefaults.standard.bool(forKey: $0.defaultsKey) }
        Group {
            if FeatureUnit.monitor.isAvailable, !available.isEmpty {
                DisclosureHeaderRow(isExpanded: $monitorExpanded) {
                    Label(FeatureUnit.monitor.title(l10n.s, language: l10n.language),
                          systemImage: FeatureUnit.monitor.symbolName)
                    Spacer()
                    SettingsCountBadge(text: "\(shown.count)/\(available.count)")
                }
                if monitorExpanded {
                    VStack(alignment: .leading, spacing: 10) {
                        // Order first: it is the menu bar read left to right.
                        if !shown.isEmpty { orderStrip(shown) }
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), alignment: .leading), count: 3),
                                  alignment: .leading, spacing: 6) {
                            ForEach(available) { metric in
                                SettingsVisibilityCheckbox(title: metric.title(l10n.s), key: metric.defaultsKey)
                            }
                        }
                    }
                    .disclosureIndent()
                }
            }
            if AppFeature.micMute.isAvailable {
                let micMute = FeatureStrings.micMute(l10n.language)
                HStack(spacing: 6) {
                    Label(FeatureUnit.micMute.title(l10n.s, language: l10n.language),
                          systemImage: FeatureUnit.micMute.symbolName)
                    Spacer()
                    SettingsVisibilityCheckbox(title: micMute.menuBarToggle,
                                               key: DefaultsKey.micMuteMenuBarIndicator)
                        .fixedSize()
                    SettingsHelpButton(title: micMute.menuBarToggle, text: micMute.menuBarCaption)
                }
            }
        }
        .onAppear { order = MenuBarMetric.order(in: .standard) }
        .onChange(of: metricOrder) { _, _ in order = MenuBarMetric.order(in: .standard) }
        .onReceive(NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)) { _ in
            revision &+= 1
        }
    }

    /// The shown metrics in menu bar order. Drag to reorder; a metric with
    /// options of its own opens them on click.
    private func orderStrip(_ shown: [MenuBarMetric]) -> some View {
        MenuBarMetricTokenLayout(spacing: 6) {
            ForEach(shown) { metric in
                MenuBarMetricToken(metric: metric)
                    .opacity(dragging == metric ? 0.45 : 1)
                    .onDrag {
                        dragging = metric
                        return NSItemProvider(object: metric.rawValue as NSString)
                    }
                    .onDrop(of: [UTType.text],
                            delegate: MenuBarMetricOrderDropDelegate(target: metric,
                                                                     order: $order,
                                                                     dragging: $dragging))
            }
        }
    }

    /// Metrics whose family left the hub keep their saved slot but stay out
    /// of the editor until they return.
    static func availableOrder(_ order: [MenuBarMetric]) -> [MenuBarMetric] {
        order.filter { $0.feature.isAvailable && $0.isAvailableOnCurrentHardware }
    }
}

/// Moves within the full saved order, so hidden metrics keep their slots.
private struct MenuBarMetricOrderDropDelegate: DropDelegate {
    let target: MenuBarMetric
    @Binding var order: [MenuBarMetric]
    @Binding var dragging: MenuBarMetric?

    func dropEntered(info: DropInfo) {
        guard let dragging, dragging != target,
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
        return true
    }
}

/// One shown metric in the order strip. Only memory and network have options
/// of their own; the others are drag handles and nothing more.
private struct MenuBarMetricToken: View {
    @ObservedObject private var l10n = L10n.shared
    let metric: MenuBarMetric
    @AppStorage(DefaultsKey.menuBarMemoryStyle) private var memoryStyle = "percent"
    @AppStorage(DefaultsKey.menuBarNetworkUploadFirst) private var uploadFirst = false
    @State private var presented = false

    private var hasOptions: Bool { metric == .memory || metric == .network }

    var body: some View {
        let title = metric.title(l10n.s)
        if hasOptions {
            Button { presented = true } label: { capsule(title) }
                .buttonStyle(.plain)
                .accessibilityLabel(title)
                .popover(isPresented: $presented, arrowEdge: .bottom) { options(title) }
        } else {
            capsule(title)
        }
    }

    private func capsule(_ title: String) -> some View {
        HStack(spacing: 4) {
            Label(title, systemImage: metric.symbolName)
            if hasOptions {
                Image(systemName: "chevron.down")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(Color.primary.opacity(0.07), in: Capsule())
        .contentShape(Capsule())
    }

    private func options(_ title: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(.headline)
            if metric == .memory {
                Toggle(l10n.s.monitorMemoryPressureDot, isOn: Binding(
                    get: { Defaults.sanitizedMenuBarMemoryStyle(memoryStyle) != "percent" },
                    set: { memoryStyle = $0 ? "both" : "percent" }))
            }
            if metric == .network {
                Toggle(l10n.s.monitorNetworkUploadFirst, isOn: $uploadFirst)
            }
        }
        .toggleStyle(.checkbox)
        .padding(14)
        .frame(minWidth: 200, alignment: .leading)
    }
}

/// Lays tokens left to right, wraps when a row is full, and centers each token
/// vertically in its row so controls of different heights line up.
private struct MenuBarMetricTokenLayout: Layout {
    var spacing: CGFloat

    private func rows(_ subviews: Subviews, maxWidth: CGFloat) -> [(indices: [Int], height: CGFloat)] {
        var rows: [(indices: [Int], height: CGFloat)] = []
        var x: CGFloat = 0
        for index in subviews.indices {
            let size = subviews[index].sizeThatFits(.unspecified)
            if rows.isEmpty || (x > 0 && x + size.width > maxWidth) {
                rows.append(([], 0))
                x = 0
            }
            rows[rows.count - 1].indices.append(index)
            rows[rows.count - 1].height = max(rows[rows.count - 1].height, size.height)
            x += size.width + spacing
        }
        return rows
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        let rows = rows(subviews, maxWidth: maxWidth)
        var height = spacing * CGFloat(max(0, rows.count - 1))
        for row in rows { height += row.height }
        var widest: CGFloat = 0
        for row in rows {
            var width = spacing * CGFloat(max(0, row.indices.count - 1))
            for index in row.indices {
                width += subviews[index].sizeThatFits(.unspecified).width
            }
            widest = max(widest, width)
        }
        return CGSize(width: maxWidth.isFinite ? maxWidth : widest, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var y = bounds.minY
        for row in rows(subviews, maxWidth: bounds.width) {
            var x = bounds.minX
            for index in row.indices {
                let size = subviews[index].sizeThatFits(.unspecified)
                subviews[index].place(at: CGPoint(x: x, y: y + (row.height - size.height) / 2),
                                      proposal: ProposedViewSize(size))
                x += size.width + spacing
            }
            y += row.height + spacing
        }
    }
}
