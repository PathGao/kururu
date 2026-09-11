// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import AppKit
import SwiftUI

/// System-Settings-style window: a sidebar of pages on the left, the selected
/// page on the right. Scales cleanly as features are added, and gives each
/// feature a page of its own with room for examples and advanced options.
struct SettingsView: View {
    @ObservedObject private var themePreferences = ThemePreferences.shared
    @ObservedObject private var l10n = L10n.shared
    @ObservedObject private var router = SettingsRouter.shared
    @ObservedObject private var features = FeatureRuntime.shared
    @Environment(\.colorScheme) private var colorScheme
    @State private var searchQuery = ""
    @State private var activeSearchIndex: Int?
    @FocusState private var sidebarSearchFocused: Bool

    private struct SearchResultsSnapshot: Equatable {
        let query: String
        let groups: [SettingsSearchGroup]

        var isBlank: Bool {
            query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }

        var items: [SettingsSearchSuggestion] {
            groups.flatMap { group in
                (group.parentMatches ? [group.parentSuggestion] : []) + group.suggestions
            }
        }

        var ids: [SettingsSearchSuggestion.ID] { items.map(\.id) }

        static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.query == rhs.query && lhs.ids == rhs.ids
        }
    }

    /// The one map of pages, shared with the command bar (SettingsDirectory).
    private var sidebarSections: [(title: String, items: [SettingsDirectoryItem])] {
        SettingsDirectory.sections(l10n.s, language: l10n.language)
    }

    var body: some View {
        let searchResults = SearchResultsSnapshot(
            query: searchQuery,
            groups: SettingsSearchSupport.groupedMatchingItems(
                query: searchQuery,
                items: SettingsDirectory.searchItems(l10n.s, language: l10n.language),
                isAvailable: { features.isAvailable($0) })
        )

        NavigationSplitView {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    BrandMark(width: 40, tint: .primary)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(ProductIdentity.name).font(PanelTypography.metric)
                        Text(AppInfo.version)
                            .font(SettingsTypography.caption).foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .padding(.bottom, 12)
                sidebar(searchResults: searchResults)
            }
            .navigationSplitViewColumnWidth(min: 205, ideal: SettingsVisualStyle.current == .compact ? 210 : 230, max: 280)
        } detail: {
            // NavigationSplitView's detail slot sometimes queries its content
            // for an unconstrained ideal size (settling the divider, or on a
            // page switch). `List` answers that with its full content height
            // rather than a viewport size the way `ScrollView` does, and
            // `.frame(maxHeight: .infinity)` only bounds a size it is given,
            // not one it is asked to report - so a few hundred rows (Kill
            // Process) grew the whole window. `GeometryReader` reports the
            // real space it was actually given for normal layout, and ~zero
            // when asked for an unconstrained ideal size, breaking the chain.
            GeometryReader { geometry in
                VStack(alignment: .leading, spacing: 0) {
                    Text(router.page.title(l10n.s, language: l10n.language))
                        .font(SettingsVisualStyle.current.titleFont)
                        .accessibilityAddTraits(.isHeader)
                        .padding(.horizontal, SettingsVisualStyle.current.pageInset)
                        .padding(.top, SettingsVisualStyle.current == .compact ? 18 : 28)
                        .padding(.bottom, 12)
                    detail
                        .font(PanelTypography.body)
                        .environment(\.defaultMinListRowHeight, SettingsVisualStyle.current == .compact ? 32 : 40)
                        .settingsSectionFocus(for: router.page)
                        .scrollContentBackground(.hidden)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .frame(width: geometry.size.width, height: geometry.size.height, alignment: .top)
                .background(SettingsVisualStyle.current.canvas(colorScheme))
            }
        }
        .navigationSplitViewStyle(.balanced)
        .kururuTheme()
        .frame(minWidth: 772, maxWidth: .infinity, minHeight: 528, maxHeight: .infinity)
        .onChange(of: searchResults, initial: true) { previous, current in
            updateSearchSelection(previous: previous, current: current)
        }
        .onChange(of: router.requestID) { _, _ in
            searchQuery = ""
            activeSearchIndex = nil
        }
    }

    /// macOS 27 backs the pinned sidebar search field with a hard top scroll
    /// edge, so rows fade out cleanly under it. On macOS 26 that effect does
    /// not render inside split-view sidebars and the pinned field has no
    /// backing of its own, so rows slid legibly across the placeholder
    /// (issues #183, #254); there the field lives on a fixed header above the
    /// list, where rows can never reach it. Earlier systems keep the classic
    /// opaque sidebar chrome.
    @ViewBuilder
    private func sidebar(searchResults: SearchResultsSnapshot) -> some View {
#if compiler(>=6.2)
        if #available(macOS 27, *) {
            sidebarList(searchResults: searchResults)
                .searchable(text: $searchQuery,
                            placement: .sidebar,
                            prompt: l10n.s.settingsSearchPlaceholder)
                .scrollEdgeEffectStyle(.hard, for: .top)
        } else if #available(macOS 26, *) {
            VStack(spacing: 0) {
                SidebarSearchField(query: $searchQuery, isFocused: $sidebarSearchFocused)
                sidebarList(searchResults: searchResults)
            }
        } else {
            sidebarList(searchResults: searchResults)
                .searchable(text: $searchQuery,
                            placement: .sidebar,
                            prompt: l10n.s.settingsSearchPlaceholder)
        }
#else
        sidebarList(searchResults: searchResults)
            .searchable(text: $searchQuery,
                        placement: .sidebar,
                        prompt: l10n.s.settingsSearchPlaceholder)
#endif
    }

    private var hasSearchQuery: Bool {
        !searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    @ViewBuilder
    private func sidebarList(searchResults: SearchResultsSnapshot) -> some View {
        if hasSearchQuery {
            searchResultsList(searchResults)
        } else {
            normalSidebarList
        }
    }

    private var normalSidebarList: some View {
        List(selection: $router.page) {
            ForEach(sidebarSections, id: \.title) { section in
                let items = section.items.filter {
                    FeatureVisibilitySupport.isSidebarPageVisible($0.page, selectedPage: router.page) { $0.unit.isAvailable }
                        && SettingsSearchSupport.matches(query: searchQuery, title: $0.title,
                                                         keywords: $0.keywords)
                }
                if !items.isEmpty {
                    let rows = ForEach(items) { item in
                        Label {
                            Text(item.title).font(.system(size: 12, weight: router.page == item.page ? .semibold : .regular))
                        } icon: {
                            Image(systemName: item.icon)
                                .font(.system(size: 13))
                                .frame(width: 26, height: 28)
                        }
                        .padding(.vertical, 3)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                        .help(item.title)
                        .accessibilityLabel(item.title)
                        .tag(item.page)
                    }
                    // The top rows have no group; an empty header would still
                    // take its row of height.
                    if section.title.isEmpty {
                        Section { rows }
                    } else {
                        Section(section.title) { rows }
                    }
                }
            }
        }
        .listStyle(.sidebar)
    }

    @ViewBuilder
    private func searchResultsList(_ searchResults: SearchResultsSnapshot) -> some View {
        ScrollViewReader { proxy in
            List {
                ForEach(searchResults.groups) { group in
                    searchPageRow(group, searchResults: searchResults)
                    ForEach(group.suggestions) { suggestion in
                        searchSuggestionRow(suggestion, searchResults: searchResults)
                    }
                }
            }
            .listStyle(.sidebar)
            .onChange(of: activeSearchIndex) { _, index in
                guard let index, searchResults.items.indices.contains(index) else { return }
                let id = searchResults.items[index].id
                if NSWorkspace.shared.accessibilityDisplayShouldReduceMotion {
                    proxy.scrollTo(id)
                } else {
                    withAnimation(.easeInOut(duration: 0.2)) { proxy.scrollTo(id) }
                }
            }
            .background {
                SearchKeyMonitor(customSearchFocused: sidebarSearchFocused) { keyCode in
                    handleSearchKey(keyCode, searchResults: searchResults.items)
                }
            }
        }
    }

    private func searchPageRow(_ group: SettingsSearchGroup,
                               searchResults: SearchResultsSnapshot) -> some View {
        let suggestion = group.parentSuggestion
        let selectionIndex = searchResults.items.firstIndex { $0.id == suggestion.id }
        let isSelected = selectionIndex == activeSearchIndex
        return Button {
            requestSearchItem(suggestion)
        } label: {
            Label(group.pageItem.title, systemImage: group.pageItem.icon)
                .fontWeight(.semibold)
                .searchResultRowStyle(isSelected: isSelected)
        }
        .buttonStyle(.plain)
        .help(group.pageItem.title)
        .accessibilityLabel(group.pageItem.title)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .id(suggestion.id)
    }

    private func searchSuggestionRow(_ suggestion: SettingsSearchSuggestion,
                                     searchResults: SearchResultsSnapshot) -> some View {
        let selectionIndex = searchResults.items.firstIndex { $0.id == suggestion.id }
        let isSelected = selectionIndex == activeSearchIndex
        return Button {
            requestSearchItem(suggestion)
        } label: {
            Label(suggestion.title, systemImage: suggestion.icon)
                .searchResultRowStyle(isSelected: isSelected)
                .padding(.leading, 18)
        }
        .buttonStyle(.plain)
        .help(suggestion.title)
        .accessibilityLabel(suggestion.title)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .id(suggestion.id)
    }

    private func handleSearchKey(_ keyCode: UInt16,
                                  searchResults: [SettingsSearchSuggestion]) -> Bool {
        switch keyCode {
        case 126: // Up
            guard !searchResults.isEmpty else { return false }
            activeSearchIndex = SettingsSearchSupport.moveSelection(
                index: activeSearchIndex, delta: -1, count: searchResults.count)
            return true
        case 125: // Down
            guard !searchResults.isEmpty else { return false }
            activeSearchIndex = SettingsSearchSupport.moveSelection(
                index: activeSearchIndex, delta: 1, count: searchResults.count)
            return true
        case 36, 76: // Return / Keypad Enter
            guard let index = activeSearchIndex,
                  searchResults.indices.contains(index) else { return false }
            requestSearchItem(searchResults[index])
            return true
        default:
            return false
        }
    }

    private func updateSearchSelection(previous: SearchResultsSnapshot,
                                       current: SearchResultsSnapshot) {
        guard !current.isBlank, !current.items.isEmpty else {
            activeSearchIndex = nil
            return
        }
        if previous.query != current.query {
            activeSearchIndex = 0
        } else if previous.ids != current.ids {
            activeSearchIndex = SettingsSearchSupport.reconciledSelection(
                index: activeSearchIndex,
                previousIDs: previous.ids,
                resultIDs: current.ids)
        }
    }

    private struct SearchKeyMonitor: NSViewRepresentable {
        var customSearchFocused: Bool
        var handleKey: (UInt16) -> Bool

        func makeNSView(context: Context) -> NSView {
            let view = NSView()
            context.coordinator.install(for: view)
            return view
        }

        func updateNSView(_ nsView: NSView, context: Context) {
            context.coordinator.customSearchFocused = customSearchFocused
            context.coordinator.handleKey = handleKey
        }

        func makeCoordinator() -> Coordinator {
            Coordinator(customSearchFocused: customSearchFocused, handleKey: handleKey)
        }

        static func dismantleNSView(_ nsView: NSView, coordinator: Coordinator) {
            coordinator.removeMonitor()
        }

        final class Coordinator: NSObject {
            var customSearchFocused: Bool
            var handleKey: (UInt16) -> Bool
            private var monitor: Any?

            init(customSearchFocused: Bool, handleKey: @escaping (UInt16) -> Bool) {
                self.customSearchFocused = customSearchFocused
                self.handleKey = handleKey
            }

            func install(for view: NSView) {
                monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) {
                    [weak self, weak view] event in
                    guard let self, let view, let window = view.window,
                          event.window === window,
                          Self.isNavigationKey(event),
                          let editor = window.firstResponder as? NSTextView,
                          editor.isFieldEditor,
                          (customSearchFocused || Self.isSidebarSearchEditor(editor, near: view)),
                          !editor.hasMarkedText() else { return event }
                    return handleKey(event.keyCode) ? nil : event
                }
            }

            func removeMonitor() {
                guard let monitor else { return }
                NSEvent.removeMonitor(monitor)
                self.monitor = nil
            }

            private static func isNavigationKey(_ event: NSEvent) -> Bool {
                let blockedModifiers: NSEvent.ModifierFlags = [.command, .control, .option, .shift]
                guard event.modifierFlags.intersection(blockedModifiers).isEmpty else { return false }
                return [UInt16(126), 125, 36, 76].contains(event.keyCode)
            }

            private static func isSidebarSearchEditor(_ editor: NSTextView,
                                                      near monitorView: NSView) -> Bool {
                guard let searchField = editor.delegate as? NSSearchField else { return false }
                let searchMidX = searchField.convert(searchField.bounds, to: nil).midX
                let sidebarFrame = monitorView.convert(monitorView.bounds, to: nil)
                return sidebarFrame.minX...sidebarFrame.maxX ~= searchMidX
            }
        }
    }

    private func requestSearchItem(_ suggestion: SettingsSearchSuggestion) {
        activeSearchIndex = nil
        let routed = SettingsSearchSupport.route(for: suggestion)
        router.request(routed.destination, targetFeature: routed.targetFeature)
    }

    @ViewBuilder
    private var detail: some View {
        if let unit = FeatureVisibilitySupport.configurationUnit(for: router.page), !unit.isAvailable {
            SavedModuleConfigurationView(unit: unit)
        } else {
            activeDetail
        }
    }

    @ViewBuilder
    private var activeDetail: some View {
        switch router.page {
        case .features: FeatureHubSettings()
        case .radialMenu: RadialMenuSettings()
        case .commandBar: CommandBarSettings()
        case .keepAwake: KeepAwakeSettings()
        case .brightness: BrightnessSettings()
        case .bluetoothSleep: BluetoothSleepSettings()
        case .cleaningMode: CleaningModeSettings()
        case .menuBarIcon: MenuBarIconSettings()
        case .menuBarPanel: MenuBarPanelSettings()
        case .monitor: MonitorSettings()
        case .mouse: MouseSettings()
        case .trackpad: TrackpadSettings()
        case .switcher: SwitcherSettings()
        case .dock: DockSettings()
        case .keyboard: KeyboardSettings()
        case .cutPaste: CutPasteSettings()
        case .windowBehavior: WindowBehaviorSettings()
        case .uninstaller: UninstallerView()
        case .cleaner: CleanerSettings()
        case .homebrew: HomebrewSettings()
        case .environment: EnvironmentSettings()
        case .media: MediaSettings()
        case .clipboard: ClipboardSettings()
        case .urlCleaner: URLCleanerSettings()
        case .mixer: MixerSettings()
        case .micMute: MicMuteSettings()
        case .musicBlock: MusicBlockSettings()
        case .scratchpad: ScratchpadSettings()
        case .screenshot: ScreenCaptureSettings()
        case .shelf: ShelfSettings()
        case .shortcuts: ShortcutsSettings()
        case .advanced: AdvancedSettings()
        case .about: AboutSettings()
        case .releaseNotes: ReleaseNotesSettings()
        }
    }
}

// MARK: - Updates

struct UpdatesView: View {
    @ObservedObject private var l10n = L10n.shared
    @ObservedObject private var updates = UpdateService.shared
    @AppStorage(DefaultsKey.autoCheckUpdates) private var autoCheck = true

    var body: some View {
        SettingsSection(l10n.s.updatesSection) {
            if BuildCapabilityPolicy.allowsUpdates(configured: ProductIdentity.allowsSelfUpdates,
                                                   development: AppInfo.isDeveloperBuild) {
                Toggle(l10n.s.autoCheckToggle, isOn: $autoCheck)
                    .onChange(of: autoCheck) { _, value in
                        UpdateService.shared.autoCheckEnabled = value
                    }

                statusRow

                HStack {
                    Button(l10n.s.checkNowButton) {
                        updates.check(manual: true)
                    }
                    .disabled(isBusy)

                    if case .available = updates.state {
                        Button(l10n.s.updateInstallButton) {
                            appDelegate()?.showUpdatePreview()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }

                if let lastChecked = updates.lastChecked {
                    Text("\(l10n.s.updateLastChecked) \(Self.format(lastChecked))")
                        .font(SettingsTypography.caption)
                        .foregroundStyle(.tertiary)
                }
            } else {
                SettingsExplanation(BuildCapabilityPolicy.updatesUnavailable(languageCode: l10n.language.rawValue))
            }
        }
    }

    @ViewBuilder
    private var statusRow: some View {
        switch updates.state {
        case .idle:
            EmptyView()
        case .checking:
            label(l10n.s.updateChecking, system: "arrow.triangle.2.circlepath", tint: .secondary)
        case .upToDate:
            label(l10n.s.updateUpToDate, system: "checkmark.circle.fill", tint: .green)
        case let .available(version):
            label("\(l10n.s.updateAvailablePrefix) \(version)", system: "arrow.down.circle.fill", tint: .accentColor)
        case let .downloading(progress):
            if let progress {
                label("\(l10n.s.updateDownloading) \(Int(progress * 100))%",
                      system: "arrow.down.circle", tint: .secondary)
            } else {
                label(l10n.s.updateDownloading, system: "arrow.down.circle", tint: .secondary)
            }
        case .installing:
            label(l10n.s.updateInstalling, system: "gearshape.2.fill", tint: .secondary)
        case let .failed(reason):
            label("\(l10n.s.updateFailedPrefix) \(reason)", system: "exclamationmark.triangle.fill", tint: .orange)
        }
    }

    private func label(_ text: String, system: String, tint: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: system).foregroundStyle(tint)
            Text(text).font(.callout)
            Spacer()
        }
    }

    private var isBusy: Bool {
        switch updates.state {
        case .checking, .downloading, .installing: return true
        default: return false
        }
    }

    private static func format(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .short
        f.timeStyle = .short
        return f.string(from: date)
    }
}

// MARK: - Mouse

struct MouseSettings: View {
    @ObservedObject private var l10n = L10n.shared
    @ObservedObject private var features = FeatureRuntime.shared
    @ObservedObject private var permissions = Permissions.shared
    @ObservedObject private var inverter = ScrollInverter.shared
    @ObservedObject private var smoothScroll = SmoothScrollService.shared
    @ObservedObject private var mouseNavigation = MouseNavigationService.shared
    @AppStorage(DefaultsKey.scrollInverterEnabled) private var invertVertical = false
    @AppStorage(DefaultsKey.scrollInverterHorizontalEnabled) private var invertHorizontal = false
    @AppStorage(DefaultsKey.focusFollowsMouseEnabled) private var focusFollowsMouseEnabled = false
    @AppStorage(DefaultsKey.focusFollowsMouseDelay) private var focusFollowsMouseDelay =
        FocusFollowsMouseSupport.defaultDelayMilliseconds
    @AppStorage(DefaultsKey.smoothScrollEnabled) private var smoothScrollEnabled = false
    @AppStorage(DefaultsKey.smoothScrollStep) private var smoothScrollStep = SmoothScrollSupport.defaultStep
    @AppStorage(DefaultsKey.smoothScrollResponse) private var smoothScrollResponse =
        SmoothScrollSupport.defaultResponse
    @AppStorage(DefaultsKey.mouseNavigationEnabled) private var mouseNavigationEnabled = false
    @AppStorage(DefaultsKey.mouseButtonShortcutsEnabled) private var mouseButtonShortcutsEnabled = false
    @AppStorage(DefaultsKey.mouseSpacesGestureEnabled) private var spacesEnabled = false
    @AppStorage(DefaultsKey.mouseClickDebounceEnabled) private var mouseClickDebounceEnabled = false
    @AppStorage(DefaultsKey.mouseClickDebounceWindowMs) private var mouseClickDebounceWindow =
        Defaults.defaultMouseClickDebounceWindowMs
    @State private var smoothScrollMoreOptionsExpanded = false
    @State private var mouseClickDebounceMoreOptionsExpanded = false

    private var mouseClickDebounceText: MouseClickDebounceStrings {
        FeatureStrings.mouseClickDebounce(l10n.language)
    }

    var body: some View {
        SettingsForm {
            if AppFeature.scrollInverter.isAvailable {
                SettingsSection(l10n.s.scrollSection) {
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle(l10n.s.invertVerticalScroll, isOn: $invertVertical)
                            .onChange(of: invertVertical) { _, _ in
                                ScrollInverter.shared.syncWithPreferences()
                                if scrollDirectionEnabled { permissions.requestAccessibility() }
                            }
                        Toggle(l10n.s.invertHorizontalScroll, isOn: $invertHorizontal)
                            .onChange(of: invertHorizontal) { _, _ in
                                ScrollInverter.shared.syncWithPreferences()
                                if scrollDirectionEnabled { permissions.requestAccessibility() }
                            }
                        SettingsCaptionText(l10n.s.scrollTrackpadNote)
                    }
                    if scrollDirectionEnabled, inverter.isRunning {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            Text(l10n.s.scrollActiveNow)
                                .font(SettingsTypography.caption)
                                .foregroundStyle(.green)
                        }
                    }
                    Group {
                        MouseExceptionsList(scope: .scrollDirection)
                    }
                }
                .settingsSectionAnchor(.scrollDirection)
            }
            if AppFeature.focusFollowsMouse.isAvailable {
                SettingsSection {
                    VStack(alignment: .leading, spacing: 4) {
                        FeatureSwitchRow(feature: .focusFollowsMouse)
                        SettingsCaptionText(l10n.s.focusFollowsMouseCaption)
                    }
                    Group {
                        SettingsControlRow(title: l10n.s.focusFollowsMouseDelay, systemImage: "timer") {
                            Slider(value: focusFollowsMouseDelayBinding,
                                   in: Double(FocusFollowsMouseSupport.delayRange.lowerBound)
                                       ... Double(FocusFollowsMouseSupport.delayRange.upperBound),
                                   step: 50) {
                                Text(l10n.s.focusFollowsMouseDelay)
                            }
                            .labelsHidden()
                            .frame(width: 150)
                            Text("\(focusFollowsMouseDelay) ms")
                                .font(SettingsTypography.caption.monospacedDigit())
                                .foregroundStyle(.secondary)
                                .frame(width: 68, alignment: .trailing)
                        }
                        MouseExceptionsList(scope: .focusFollowsMouse)
                    }
                }
                .settingsSectionAnchor(.focusFollowsMouse)
            }
            if AppFeature.smoothScroll.isAvailable {
                SettingsSection {
                    VStack(alignment: .leading, spacing: 4) {
                        FeatureSwitchRow(feature: .smoothScroll)
                        SettingsCaptionText(l10n.s.smoothScrollCaption)
                    }
                    Group {
                        SettingsControlRow(title: l10n.s.smoothScrollStepLabel, systemImage: "arrow.up.and.down") {
                            Slider(value: smoothScrollStepBinding,
                                   in: Double(SmoothScrollSupport.stepRange.lowerBound)...Double(SmoothScrollSupport.stepRange.upperBound),
                                   step: 10) {
                                Text(l10n.s.smoothScrollStepLabel)
                            }
                            .labelsHidden()
                            .frame(width: 150)
                            Text("\(SmoothScrollSupport.sanitizedStep(smoothScrollStep))")
                                .font(SettingsTypography.caption.monospacedDigit())
                                .foregroundStyle(.secondary)
                                .frame(width: 34, alignment: .trailing)
                        }
                        DisclosureGroup(isExpanded: $smoothScrollMoreOptionsExpanded) {
                            SettingsControlRow(title: l10n.s.smoothScrollResponseLabel, systemImage: "waveform.path") {
                                Slider(value: smoothScrollResponseBinding,
                                       in: Double(SmoothScrollSupport.responseRange.lowerBound)
                                           ... Double(SmoothScrollSupport.responseRange.upperBound),
                                       step: 5) {
                                    Text(l10n.s.smoothScrollResponseLabel)
                                }
                                .labelsHidden()
                                .frame(width: 150)
                                Text("\(SmoothScrollSupport.sanitizedResponse(smoothScrollResponse))%")
                                    .font(SettingsTypography.caption.monospacedDigit())
                                    .foregroundStyle(.secondary)
                                    .frame(width: 42, alignment: .trailing)
                            }
                            .padding(.top, 4)
                        } label: {
                            Text(mouseClickDebounceText.moreOptions)
                        }
                        MouseExceptionsList(scope: .smoothScroll)
                    }
                }
                .settingsSectionAnchor(.smoothScroll)
            }
            if AppFeature.mouseAcceleration.isAvailable {
                SettingsSection {
                    VStack(alignment: .leading, spacing: 4) {
                        FeatureSwitchRow(feature: .mouseAcceleration)
                        SettingsCaptionText(l10n.s.mouseAccelerationCaption)
                    }
                }
                .settingsSectionAnchor(.mouseAcceleration)
            }
            if AppFeature.mouseNavigation.isAvailable {
                SettingsSection {
                    VStack(alignment: .leading, spacing: 4) {
                        FeatureSwitchRow(feature: .mouseNavigation)
                        SettingsCaptionText(l10n.s.mouseNavigationCaption)
                    }
                    if mouseNavigationEnabled, mouseNavigation.isRunning {
                        Label(l10n.s.mouseNavigationActiveNow, systemImage: "checkmark.circle.fill")
                            .font(SettingsTypography.caption)
                            .foregroundStyle(.green)
                    }
                    Group {
                        MouseExceptionsList(scope: .navigation)
                    }
                }
                .settingsSectionAnchor(.mouseNavigation)
            }
            if AppFeature.mouseButtonShortcuts.isAvailable {
                MouseButtonShortcutsSection()
            }
            if AppFeature.mouseClickDebounce.isAvailable {
                SettingsSection {
                    VStack(alignment: .leading, spacing: 4) {
                        FeatureSwitchRow(feature: .mouseClickDebounce)
                        SettingsCaptionText(mouseClickDebounceText.caption)
                    }
                    Group {
                        DisclosureGroup(isExpanded: $mouseClickDebounceMoreOptionsExpanded) {
                            SettingsControlRow(title: mouseClickDebounceText.windowLabel,
                                               systemImage: "timer",
                                               caption: mouseClickDebounceText.windowCaption) {
                                Text("\(Defaults.sanitizedMouseClickDebounceWindow(mouseClickDebounceWindow)) ms")
                                    .foregroundStyle(.secondary)
                                    .monospacedDigit()
                                Stepper(mouseClickDebounceText.windowLabel,
                                        value: mouseClickDebounceWindowBinding,
                                        in: Defaults.allowedMouseClickDebounceWindowRange,
                                        step: 5)
                                    .labelsHidden()
                            }
                        } label: {
                            Text(mouseClickDebounceText.moreOptions)
                        }
                    }
                }
                .settingsSectionAnchor(.mouseClickDebounce)
            }
            if accessibilityNoteVisible {
                SettingsSection(l10n.s.permissionRequired) {
                    PermissionRow(kind: .accessibility)
                }
            }
        }
        .formStyle(.grouped)
    }

    /// Only features that are on AND still available can ask for the
    /// permission note; a hub-disabled one no longer needs anything.
    private var accessibilityNoteVisible: Bool {
        let anyEngaged = (scrollDirectionEnabled && AppFeature.scrollInverter.isAvailable)
            || (focusFollowsMouseEnabled && AppFeature.focusFollowsMouse.isAvailable)
            || (smoothScrollEnabled && AppFeature.smoothScroll.isAvailable)
            || (mouseNavigationEnabled && AppFeature.mouseNavigation.isAvailable)
            || ((mouseButtonShortcutsEnabled || spacesEnabled)
                && AppFeature.mouseButtonShortcuts.isAvailable)
            || (mouseClickDebounceEnabled && AppFeature.mouseClickDebounce.isAvailable)
        return anyEngaged && !permissions.accessibility
    }

    private var scrollDirectionEnabled: Bool {
        invertVertical || invertHorizontal
    }

    private var smoothScrollStepBinding: Binding<Double> {
        Binding(
            get: { Double(SmoothScrollSupport.sanitizedStep(smoothScrollStep)) },
            set: { smoothScrollStep = Int($0) }
        )
    }

    private var smoothScrollResponseBinding: Binding<Double> {
        Binding(
            get: { Double(SmoothScrollSupport.sanitizedResponse(smoothScrollResponse)) },
            set: { smoothScrollResponse = Int($0) }
        )
    }

    private var focusFollowsMouseDelayBinding: Binding<Double> {
        Binding(
            get: { Double(FocusFollowsMouseSupport.sanitizedDelay(focusFollowsMouseDelay)) },
            set: {
                focusFollowsMouseDelay = Int($0)
                FocusFollowsMouseService.shared.preferencesDidChange()
            }
        )
    }

    private var mouseClickDebounceWindowBinding: Binding<Int> {
        Binding(
            get: { Defaults.sanitizedMouseClickDebounceWindow(mouseClickDebounceWindow) },
            set: {
                mouseClickDebounceWindow = Defaults.sanitizedMouseClickDebounceWindow($0)
                MouseClickDebounceService.shared.syncWithPreferences()
            }
        )
    }
}

// MARK: - Switcher

struct SwitcherSettings: View {
    @ObservedObject private var l10n = L10n.shared
    @ObservedObject private var features = FeatureRuntime.shared
    @ObservedObject private var permissions = Permissions.shared
    @AppStorage(DefaultsKey.switcherEnabled) private var switcherEnabled = true
    @AppStorage(DefaultsKey.switcherTakeOverSystemShortcuts) private var switcherTakeOverSystemShortcuts = false
    @AppStorage(DefaultsKey.switcherShortcut) private var switcherShortcutStorage = GlobalShortcut.switcherDefault.storageValue
    @AppStorage(DefaultsKey.switcherIconRowMode) private var switcherIconRowMode = false
    @AppStorage(DefaultsKey.switcherSimpleMode) private var switcherSimpleMode = false
    @AppStorage(DefaultsKey.switcherMergeTabs) private var switcherMergeTabs = false
    @AppStorage(DefaultsKey.switcherWindowlessApps) private var switcherWindowlessApps = SwitcherWindowlessApps.fallback.rawValue
    @AppStorage(DefaultsKey.switcherMinimizedPlacement) private var switcherMinimizedPlacement = WindowSwitchMinimizedPlacement.normal.rawValue
    @AppStorage(DefaultsKey.switcherShowFullscreenWindows) private var switcherShowFullscreenWindows = true
    @AppStorage(DefaultsKey.switcherScreenPlacement) private var switcherScreenPlacement = SwitcherScreenPlacement.fallback.rawValue
    @AppStorage(DefaultsKey.switcherCurrentSpaceOnly) private var switcherCurrentSpaceOnly = false
    @AppStorage(DefaultsKey.switcherSearchPinEnabled) private var switcherSearchPinEnabled = false
    @AppStorage(DefaultsKey.switcherShowShortcutHints) private var switcherShowShortcutHints = true
    @AppStorage(DefaultsKey.switcherAppearanceDelay) private var switcherAppearanceDelay = SwitcherSupport.defaultAppearanceDelayMilliseconds

    private var switcherEngaged: Bool { switcherEnabled && AppFeature.switcher.isAvailable }
    private var switcherShortcutDisplayString: String {
        (GlobalShortcut(storageValue: switcherShortcutStorage) ?? .switcherDefault).displayString
    }
    private var switcherWindowlessAppsSelection: Binding<String> {
        Binding(
            get: {
                SwitcherWindowlessApps.mode(
                    storedValue: switcherWindowlessApps,
                    takeOverSystemShortcuts: switcherTakeOverSystemShortcuts).rawValue
            },
            set: { value in
                if !switcherTakeOverSystemShortcuts { switcherWindowlessApps = value }
            }
        )
    }

    var body: some View {
        SettingsForm {
            if AppFeature.switcher.isAvailable {
                SettingsSection {
                    Toggle(isOn: $switcherEnabled) {
                        HStack(spacing: 10) {
                            SettingsSymbol(systemImage: "rectangle.on.rectangle")
                            Text(l10n.s.switcherEnable).font(SettingsTypography.sectionTitle)
                            Spacer(minLength: 8)
                        }
                    }
                    .toggleStyle(.switch)
                    .onChange(of: switcherEnabled) { _, _ in
                        AppSwitcher.shared.syncWithPreferences()
                    }
                    SettingsInfo(text: l10n.s.switcherEnableCaption, systemImage: "rectangle.on.rectangle")
                }
                .settingsSectionAnchor(.switcher)

                SettingsSection(title: UXEntryStrings(l10n.language).activationAndShortcuts, systemImage: "keyboard") {
                    ShortcutPreferenceRow(role: .switcher,
                                          isEnabled: true,
                                          label: l10n.s.switcherShortcutHintApps) {
                        AppSwitcher.shared.syncWithPreferences()
                    }
                    ShortcutPreferenceRow(role: .switcherWindow,
                                          isEnabled: true,
                                          label: l10n.s.switcherShortcutHintWindows) {
                        AppSwitcher.shared.syncWithPreferences()
                    }
                    Text(l10n.s.switcherWindowShortcutCaption)
                        .font(SettingsTypography.caption)
                        .foregroundStyle(.secondary)
                    SettingsToggleWithCaption(title: l10n.s.switcherTakeOverSystemShortcuts, caption: l10n.s.switcherTakeOverSystemShortcutsCaption, isOn: $switcherTakeOverSystemShortcuts)
                        .onChange(of: switcherTakeOverSystemShortcuts) { _, _ in
                            AppSwitcher.shared.syncWithPreferences()
                        }
                    Text(String(format: l10n.s.switcherUsageHintFormat,
                                GlobalShortcutRole.switcher.savedShortcut.displayString))
                        .font(SettingsTypography.caption)
                        .foregroundStyle(.secondary)

                }

                SettingsSection(title: UXEntryStrings(l10n.language).appearanceAndPreviews, systemImage: "macwindow") {
                    SettingsToggleWithCaption(title: l10n.s.switcherSimpleMode, caption: l10n.s.switcherSimpleModeCaption, isOn: $switcherSimpleMode)
                        .onChange(of: switcherSimpleMode) { _, _ in
                            AppSwitcher.shared.syncWithPreferences()
                        }

                    SettingsToggleWithCaption(title: String(format: l10n.s.switcherIconRowMode, switcherShortcutDisplayString), caption: l10n.s.switcherIconRowModeCaption, isOn: $switcherIconRowMode)
                        .disabled(switcherSimpleMode)
                        .onChange(of: switcherIconRowMode) { _, _ in
                            AppSwitcher.shared.syncWithPreferences()
                        }

                    if switcherSimpleMode || switcherIconRowMode {
                        SettingsToggleWithCaption(title: l10n.s.switcherShowShortcutHints, caption: l10n.s.switcherShowShortcutHintsCaption, isOn: $switcherShowShortcutHints)
                    }

                    SettingsControlRow(title: l10n.s.switcherScreenPlacementLabel, systemImage: "display", caption: l10n.s.switcherScreenPlacementCaption) {
                        Picker(l10n.s.switcherScreenPlacementLabel, selection: $switcherScreenPlacement) {
                            Text(l10n.s.switcherScreenPlacementPointer).tag(SwitcherScreenPlacement.pointer.rawValue)
                            Text(l10n.s.switcherScreenPlacementMenuBar).tag(SwitcherScreenPlacement.menuBar.rawValue)
                            Text(l10n.s.switcherScreenPlacementActiveWindow).tag(SwitcherScreenPlacement.activeWindow.rawValue)
                        }
                        .labelsHidden()
                    }

                    Divider()
                    WindowPreviewControls(sizeKey: DefaultsKey.switcherPreviewSize,
                                          exclusionsKey: DefaultsKey.switcherPreviewExcludedApps,
                                          onSizeChange: AppSwitcher.shared.syncWithPreferences)
                }

                SettingsSection(title: UXEntryStrings(l10n.language).windowScope, systemImage: "square.stack.3d.up") {
                    SettingsToggleWithCaption(title: l10n.s.switcherMergeTabs, caption: l10n.s.switcherMergeTabsCaption, isOn: $switcherMergeTabs)

                    SettingsControlRow(title: l10n.s.switcherMinimizedPlacementLabel, systemImage: "minus.rectangle") {
                        Picker(l10n.s.switcherMinimizedPlacementLabel, selection: $switcherMinimizedPlacement) {
                            Text(l10n.s.switcherMinimizedPlacementNormal).tag(WindowSwitchMinimizedPlacement.normal.rawValue)
                            Text(l10n.s.switcherMinimizedPlacementEnd).tag(WindowSwitchMinimizedPlacement.end.rawValue)
                            Text(l10n.s.switcherMinimizedPlacementHidden).tag(WindowSwitchMinimizedPlacement.hidden.rawValue)
                        }
                        .onChange(of: switcherMinimizedPlacement) { _, _ in
                            AppSwitcher.shared.syncWithPreferences()
                        }
                        .labelsHidden()
                    }

                    Toggle(l10n.s.switcherShowFullscreenWindows, isOn: $switcherShowFullscreenWindows)
                        .onChange(of: switcherShowFullscreenWindows) { _, _ in
                            AppSwitcher.shared.syncWithPreferences()
                        }

                    SettingsToggleWithCaption(title: l10n.s.switcherCurrentSpaceOnly, caption: l10n.s.switcherCurrentSpaceOnlyCaption, isOn: $switcherCurrentSpaceOnly)

                    SettingsControlRow(title: l10n.s.switcherWindowlessApps, systemImage: "app.dashed", caption: l10n.s.switcherWindowlessAppsCaption) {
                        Picker(l10n.s.switcherWindowlessApps,
                               selection: switcherWindowlessAppsSelection) {
                            Text(l10n.s.switcherWindowlessAppsOff).tag(SwitcherWindowlessApps.off.rawValue)
                            Text(l10n.s.switcherWindowlessAppsFinder).tag(SwitcherWindowlessApps.finder.rawValue)
                            Text(l10n.s.switcherWindowlessAppsAll).tag(SwitcherWindowlessApps.all.rawValue)
                        }
                        .disabled(switcherTakeOverSystemShortcuts)
                        .labelsHidden()
                    }
                    SwitcherAppRulesList()
                }

                SettingsSection(title: UXEntryStrings(l10n.language).interaction, systemImage: "cursorarrow.click") {
                    SettingsControlRow(title: l10n.s.switcherAppearanceDelay, systemImage: "timer",
                                       caption: l10n.s.switcherAppearanceDelayCaption) {
                        Slider(value: switcherAppearanceDelayBinding,
                               in: Double(SwitcherSupport.appearanceDelayMillisecondsRange.lowerBound)
                                   ... Double(SwitcherSupport.appearanceDelayMillisecondsRange.upperBound),
                               step: 25)
                            .frame(width: 150)
                            .accessibilityLabel(l10n.s.switcherAppearanceDelay)
                        Text("\(sanitizedSwitcherAppearanceDelay) ms")
                            .font(SettingsTypography.caption.monospaced())
                            .foregroundStyle(.secondary)
                            .frame(width: 64, alignment: .trailing)
                    }
                    SettingsToggleWithCaption(title: l10n.s.switcherSearchPin,
                                              caption: l10n.s.switcherSearchPinCaption,
                                              isOn: $switcherSearchPinEnabled)
                }
            }
            if switcherEngaged {
                if !permissions.accessibility {
                    SettingsSection(l10n.s.permissionRequired) {
                        PermissionRow(kind: .accessibility)
                    }
                }
                if !permissions.screenRecording,
                   SwitcherSupport.capturesPreviews(simpleMode: switcherSimpleMode) {
                    SettingsSection {
                        PermissionRow(kind: .screenRecording)
                    }
                }
            }
        }
        .formStyle(.grouped)
    }

    private var sanitizedSwitcherAppearanceDelay: Int {
        SwitcherSupport.sanitizedAppearanceDelay(milliseconds: switcherAppearanceDelay)
    }

    private var switcherAppearanceDelayBinding: Binding<Double> {
        Binding(
            get: { Double(sanitizedSwitcherAppearanceDelay) },
            set: {
                switcherAppearanceDelay = SwitcherSupport.sanitizedAppearanceDelay(
                    milliseconds: Int($0.rounded()))
            }
        )
    }
}

// MARK: - About

struct AboutSettings: View {
    @ObservedObject private var l10n = L10n.shared

    private var feedbackStrings: FeedbackStrings { FeatureStrings.feedback(l10n.language) }

    var body: some View {
        SettingsForm {
            SettingsSection {
                aboutContent
            }

            UpdatesView()

            SettingsSection(feedbackStrings.sectionTitle) {
                Button {
                    appDelegate()?.openFeedbackWindow()
                } label: {
                    Label(feedbackStrings.openButton,
                          systemImage: "bubble.left.and.text.bubble.right")
                }
                SettingsCaptionText(feedbackStrings.sectionCaption)
            }
        }
        .formStyle(.grouped)
    }

    private var aboutContent: some View {
        VStack(spacing: 14) {
            BrandBadge(size: 80)
            VStack(spacing: 3) {
                Text(AppInfo.name)
                    .font(.title2.bold())
                HStack(spacing: 6) {
                    Text("\(l10n.s.versionPrefix) \(AppInfo.version)")
                        .font(SettingsTypography.caption)
                        .foregroundStyle(.secondary)
                    if AppInfo.isBeta {
                        Text(l10n.s.betaBadgeLabel)
                            .font(.system(size: 9, weight: .bold))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1.5)
                            .background(Color.orange.opacity(0.18))
                            .foregroundStyle(.orange)
                            .clipShape(Capsule())
                    }
                }
                if AppInfo.isDeveloperBuild, let commit = AppInfo.buildCommit {
                    // Dev-only: which source commit this build came from. Never shipped.
                    Text(commit)
                        .font(.caption2.monospaced())
                        .foregroundStyle(.tertiary)
                        .textSelection(.enabled)
                }
            }
            Text(l10n.s.aboutDescription)
                .font(.system(size: 12))
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            HStack(spacing: 12) {
                Button(l10n.s.reviewIntro) {
                    appDelegate()?.showOnboarding()
                }
                Button(l10n.s.reviewHighlights) {
                    appDelegate()?.showUpdateHighlights()
                }
                Link("kururu · \(l10n.s.viewOnGitHub)", destination: AppInfo.repositoryURL)
            }
            Link(AppInfo.copyright, destination: URL(string: "https://github.com/vorssaint/vorssaint-utils")!)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }
}

// MARK: - Release notes

struct ReleaseNotesSettings: View {
    @ObservedObject private var l10n = L10n.shared
    private var notes: ReleaseNotes { ReleaseNotes.current(languageCode: l10n.language.rawValue) }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text(l10n.s.obWhatsNewTitle)
                    .font(.title2.bold())
                Text(versionLine)
                    .font(SettingsTypography.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    if notes.sections.isEmpty {
                        fallbackNote
                    } else {
                        ForEach(Array(notes.sections.enumerated()), id: \.offset) { _, section in
                            releaseSection(section)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var versionLine: String {
        notes.versionLabel(languageCode: l10n.language.rawValue)
    }

    private var fallbackNote: some View {
        HStack(alignment: .top, spacing: 9) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.secondary)
                .frame(width: 18, alignment: .center)
            Text(l10n.s.obWhatsNewFallback)
                .font(.system(size: 12.5))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func releaseSection(_ section: ReleaseNoteSection) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            if !section.title.isEmpty {
                Text(section.title.uppercased())
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.secondary)
                    .tracking(1.2)
            }
            ForEach(Array(section.items.enumerated()), id: \.offset) { _, item in
                releaseItem(item, sectionTitle: section.title)
            }
        }
    }

    @ViewBuilder
    private func releaseItem(_ item: ReleaseNoteItem, sectionTitle: String) -> some View {
        switch item {
        case let .paragraph(text):
            Text(text)
                .font(.system(size: 12.8))
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
        case let .bullet(text):
            HStack(alignment: .top, spacing: 9) {
                Image(systemName: iconName(for: sectionTitle))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 18, alignment: .center)
                Text(text)
                    .font(.system(size: 12.5))
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        case let .image(image):
            if let nsImage = releaseNoteImage(image) {
                Image(nsImage: nsImage)
                    .resizable()
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(.quaternary, lineWidth: 1)
                    )
                    .accessibilityLabel(image.alt)
                    .padding(.leading, 27)
            }
        }
    }

    private func releaseNoteImage(_ image: ReleaseNoteImage) -> NSImage? {
        var path = image.path
        if let resourcesRange = path.range(of: "Resources/") {
            path = String(path[resourcesRange.lowerBound...])
        }
        if path.hasPrefix("Resources/") {
            path.removeFirst("Resources/".count)
        }
        let nsPath = path as NSString
        let ext = nsPath.pathExtension
        let name = (nsPath.deletingPathExtension as NSString).lastPathComponent
        let directory = nsPath.deletingLastPathComponent
        guard !name.isEmpty, !ext.isEmpty else { return nil }
        let subdirectory = directory.isEmpty || directory == "." ? nil : directory
        guard let url = Bundle.main.url(forResource: name,
                                        withExtension: ext,
                                        subdirectory: subdirectory) else { return nil }
        return NSImage(contentsOf: url)
    }

    private func iconName(for title: String) -> String {
        switch title.lowercased() {
        case "added": return "plus.circle.fill"
        case "changed": return "slider.horizontal.3"
        case "fixed": return "checkmark.circle.fill"
        default: return "circle.fill"
        }
    }
}

// MARK: - Shared settings rows

struct SettingsCaptionText: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text)
            .font(SettingsTypography.caption)
            .foregroundStyle(.secondary)
            .lineLimit(nil)
            .fixedSize(horizontal: false, vertical: true)
    }
}

struct SettingsToggleWithCaption: View {
    let title: String
    let caption: String
    @Binding var isOn: Bool

    var body: some View {
        Toggle(isOn: $isOn) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(SettingsTypography.body.weight(.medium))
                SettingsCaptionText(caption)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - Shared permission row

enum PermissionKind {
    case accessibility
    case screenRecording
    case microphone
}

/// Status + actions for one TCC permission; shared by Settings and onboarding.
struct PermissionRow: View {
    @ObservedObject private var l10n = L10n.shared
    @ObservedObject private var permissions = Permissions.shared
    @State private var pollingDemandID = UUID()
    let kind: PermissionKind

    private var granted: Bool {
        switch kind {
        case .accessibility: return permissions.accessibility
        case .screenRecording: return permissions.screenRecording
        case .microphone: return permissions.microphone == .granted
        }
    }

    private var monitorsActivePermission: Bool {
        switch kind {
        case .accessibility, .screenRecording: return true
        case .microphone: return false
        }
    }

    private var name: String {
        switch kind {
        case .accessibility: return l10n.s.permissionAccessibility
        case .screenRecording: return l10n.s.permissionScreenRecording
        case .microphone:
            return FeatureStrings.recorder(l10n.language).microphonePermissionName
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: granted ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                    .foregroundStyle(granted ? .green : .orange)
                Text(name)
                Spacer()
                Text(granted ? l10n.s.permissionGranted : l10n.s.permissionMissing)
                    .font(SettingsTypography.caption)
                    .foregroundStyle(granted ? .green : .orange)
            }
            if !granted {
                HStack(spacing: 8) {
                    Button(l10n.s.permissionRequest) {
                        switch kind {
                        case .accessibility:
                            permissions.requestAccessibility()
                        case .screenRecording:
                            permissions.requestScreenRecording()
                        case .microphone:
                            permissions.requestMicrophone()
                        }
                    }
                    Button(l10n.s.permissionOpenSettings) {
                        switch kind {
                        case .accessibility:
                            permissions.openAccessibilitySettings()
                        case .screenRecording:
                            permissions.openScreenRecordingSettings()
                        case .microphone:
                            permissions.openMicrophoneSettings()
                        }
                    }
                }
                .controlSize(.small)
            }
        }
        .onAppear {
            if monitorsActivePermission {
                permissions.setActivePermissionSurface(pollingDemandID, visible: true)
            }
        }
        .onDisappear {
            permissions.setActivePermissionSurface(pollingDemandID, visible: false)
        }
    }
}

/// Search field for the macOS 26 sidebar, styled after the system pill.
/// It sits on a fixed header outside the List, so scrolling rows can never
/// cross it (issues #183, #254). Esc and the clear button empty the query,
/// matching the system field.
private struct SidebarSearchField: View {
    @ObservedObject private var l10n = L10n.shared
    @Binding var query: String
    var isFocused: FocusState<Bool>.Binding

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField(l10n.s.settingsSearchPlaceholder, text: $query)
                .textFieldStyle(.plain)
                .focused(isFocused)
                .onExitCommand { query = "" }
            if !query.isEmpty {
                Button {
                    query = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(l10n.s.urlCleanerClearButton)
            }
        }
        .padding(.vertical, 5)
        .padding(.horizontal, 7)
        .background(.quaternary.opacity(0.5), in: Capsule())
        .padding(.horizontal, 10)
        .padding(.top, 8)
        .padding(.bottom, 4)
    }
}

private extension View {
    func searchResultRowStyle(isSelected: Bool) -> some View {
        frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .padding(.vertical, 4)
            .padding(.horizontal, 6)
            .foregroundStyle(isSelected ? Color.accentColor : Color.primary)
            .background {
                RoundedRectangle(cornerRadius: 6)
                    .fill(isSelected ? Color.accentColor.opacity(0.18) : .clear)
            }
    }
}
