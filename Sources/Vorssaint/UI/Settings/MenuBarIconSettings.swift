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
    @AppStorage(DefaultsKey.micMuteMenuBarIndicator) private var micMenuBarIndicator = true

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
                    MenuBarMetricOrderEditor()
                    Text(activeMetricCount == 0 ? workspace.noMetrics : l10n.s.monitorMenuBarCaption)
                        .font(SettingsTypography.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text(workspace.inactiveMonitor)
                        .fixedSize(horizontal: false, vertical: true)
                    Button(workspace.add) { FeatureRuntime.shared.setAvailable(.monitor, true) }
                        .buttonStyle(.borderedProminent)
                }
            }
            SettingsSection(appearanceStrings.label) {
                if activeMetricCount == 0 {
                    Text(workspace.deferredAppearance)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Picker(appearanceStrings.label, selection: $metricAppearance) {
                    Text(appearanceStrings.values).tag("values")
                    Text(appearanceStrings.bars).tag("bars")
                }
                .pickerStyle(.segmented)
                if appearance == .bars {
                    Text(appearanceStrings.caption)
                        .font(SettingsTypography.caption).foregroundStyle(.secondary)
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
            SettingsSection {
                SettingsToggleWithCaption(title: l10n.s.menuBarHideIconToggle,
                                          caption: l10n.s.menuBarHideIconCaption,
                                          showsCaptionInline: false,
                                          isOn: $hideIconWithMetrics)
                if AppFeature.micMute.isAvailable {
                    SettingsToggleWithCaption(title: FeatureStrings.micMute(l10n.language).menuBarToggle,
                                              caption: FeatureStrings.micMute(l10n.language).menuBarCaption,
                                              showsCaptionInline: false,
                                              isOn: $micMenuBarIndicator)
                }
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

/// The metrics shown in the menu bar, as tokens in menu bar order. Drag a token
/// to reorder, click it for its options, add hidden metrics from the menu. The
/// saved order keeps a slot for hidden metrics, so hiding does not reshuffle it.
struct MenuBarMetricOrderEditor: View {
    @ObservedObject private var l10n = L10n.shared
    @ObservedObject private var features = FeatureRuntime.shared
    @AppStorage(DefaultsKey.menuBarMetricOrder) private var metricOrder = ""
    @State private var order: [MenuBarMetric] = MenuBarMetric.order(in: .standard)
    @State private var dragging: MenuBarMetric?
    @State private var visibilityRevision = 0

    var body: some View {
        let workspace = ModuleWorkspaceStrings(l10n.language)
        let _ = visibilityRevision
        let available = Self.availableOrder(order)
        let hidden = available.filter { !UserDefaults.standard.bool(forKey: $0.defaultsKey) }
        MenuBarMetricTokenLayout(spacing: 6) {
            ForEach(available.filter { UserDefaults.standard.bool(forKey: $0.defaultsKey) }) { metric in
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
            Menu {
                ForEach(hidden) { metric in
                    Button {
                        UserDefaults.standard.set(true, forKey: metric.defaultsKey)
                    } label: {
                        Label(metric.title(l10n.s), systemImage: metric.symbolName)
                    }
                }
            } label: {
                Label(workspace.addMetrics, systemImage: "plus")
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
            .disabled(hidden.isEmpty)
        }
        .padding(.vertical, 2)
        .onAppear { order = MenuBarMetric.order(in: .standard) }
        .onChange(of: metricOrder) { _, _ in order = MenuBarMetric.order(in: .standard) }
        .onReceive(NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)) { _ in
            visibilityRevision += 1
        }
    }

    /// Metrics whose family left the hub keep their saved slot but stay out
    /// of the editor until they return.
    static func availableOrder(_ order: [MenuBarMetric]) -> [MenuBarMetric] {
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

/// One shown metric. A Button rather than a Toggle: inside a draggable view a
/// Button still receives the click. Its options live in the popover.
private struct MenuBarMetricToken: View {
    @ObservedObject private var l10n = L10n.shared
    let metric: MenuBarMetric
    @AppStorage private var shown: Bool
    @AppStorage(DefaultsKey.menuBarMemoryStyle) private var memoryStyle = "percent"
    @AppStorage(DefaultsKey.menuBarNetworkUploadFirst) private var uploadFirst = false
    @State private var presented = false

    init(metric: MenuBarMetric) {
        self.metric = metric
        _shown = AppStorage(wrappedValue: false, metric.defaultsKey)
    }

    var body: some View {
        let title = metric.title(l10n.s)
        Button { presented = true } label: {
            Label(title, systemImage: metric.symbolName)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Color.primary.opacity(0.07), in: Capsule())
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .popover(isPresented: $presented, arrowEdge: .bottom) {
            VStack(alignment: .leading, spacing: 10) {
                Text(title).font(.headline)
                Toggle(ModuleWorkspaceStrings(l10n.language).showMenuBarMetric, isOn: $shown)
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
