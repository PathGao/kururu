// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import AppKit
import SwiftUI

/// Manual cleanup, automatic behavior and their single shared rule set.
struct URLCleanerSections: View {
    @ObservedObject private var l10n = L10n.shared
    @ObservedObject private var cleaner = URLCleanerService.shared
    @AppStorage(DefaultsKey.urlCleanerEnabled) private var enabled = false
    @AppStorage(DefaultsKey.urlCleanerCustomParameters) private var globalNames = ""
    @AppStorage(DefaultsKey.urlCleanerSiteParameters) private var siteNames = ""
    @AppStorage(DefaultsKey.urlCleanerDisabledParameters) private var disabledNames = ""
    @State private var parameterDrafts: [String: String] = [:]
    @State private var siteDraft = ""
    @State private var siteParameterDraft = ""
    @State private var input = ""
    @State private var resultState = URLCleanerResultState()
    @State private var message: String?
    @State private var showingAddSite = false
    @State private var pendingRemoval: (site: String, name: String)?
    private var actionText: URLRuleActionStrings { URLRuleActionStrings(language: l10n.language) }
    private var flowText: UXTaskFlowStrings { UXTaskFlowStrings(language: l10n.language) }
    private var canClearInput: Bool { !input.isEmpty || resultState.canCopy || message != nil }
    private var rules: URLCleaning.Rules {
        URLCleaning.rules(globalNames: globalNames,
                          siteNames: siteNames,
                          disabledNames: disabledNames)
    }

    var body: some View {
        Group {
            SettingsSection(title: l10n.s.urlCleanerManualTitle, systemImage: "link") {
                HStack(spacing: 8) {
                    TextField("", text: $input, prompt: Text(l10n.s.urlCleanerInputPlaceholder))
                        .textFieldStyle(.roundedBorder)
                        .labelsHidden()
                        .accessibilityLabel(l10n.s.urlCleanerInputPlaceholder)
                        .onSubmit { clean() }
                    Button {
                        clearInput()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Color.secondary.opacity(canClearInput ? 1 : 0.35))
                            .frame(width: 22, height: 22)
                    }
                    .buttonStyle(.plain)
                    .help(l10n.s.urlCleanerClearButton)
                    .accessibilityLabel(l10n.s.urlCleanerClearButton)
                    .disabled(!canClearInput)
                }
                HStack {
                    Button(action: paste) {
                        Label(l10n.s.urlCleanerPasteButton, systemImage: "doc.on.clipboard")
                    }
                    Button(action: clean) {
                        Label(l10n.s.urlCleanerCleanButton, systemImage: "wand.and.stars")
                    }
                    .settingsAction(.primary)
                    .disabled(input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 6) {
                        if resultState.output.isEmpty {
                            SettingsInfo(text: message ?? l10n.s.urlCleanerOutputPlaceholder,
                                         systemImage: "text.alignleft")
                        } else {
                            Text(resultState.output)
                                .font(SettingsTypography.caption.monospaced())
                                .lineLimit(3)
                                .truncationMode(.middle)
                                .textSelection(.enabled)
                            if let message {
                                Text(message)
                                    .font(SettingsTypography.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    Button(action: copy) {
                        Label(l10n.s.urlCleanerCopyButton, systemImage: "doc.on.doc")
                    }
                    .disabled(!resultState.canCopy)
                }
            }

            SettingsSection(title: flowText.automaticURLCleaning, systemImage: "arrow.triangle.2.circlepath") {
                FeatureSwitchRow(feature: .urlCleaner, title: l10n.s.urlCleanerEnable)
                SettingsExplanation(flowText.automaticURLCaption)
                SettingsInfo(text: l10n.s.urlCleanerLocalNote, systemImage: "lock.shield")
                if enabled, cleaner.isRunning {
                    Label(l10n.s.urlCleanerActiveNow, systemImage: "checkmark.circle.fill")
                        .font(SettingsTypography.caption)
                        .foregroundStyle(.green)
                }
                if !cleaner.lastRemoved.isEmpty {
                    Text(actionText.lastCleanup + removedSummary(cleaner.lastRemoved))
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            SettingsSection(title: l10n.s.urlCleanerRulesTitle, systemImage: "line.3.horizontal.decrease.circle") {
                SettingsInfo(text: actionText.sharedRules, systemImage: "slider.horizontal.3")
                DisclosureGroup(UXEntryStrings(l10n.language).editRules) {
                    ForEach(URLCleaning.ruleGroups(rules: rules)) { group in
                        DisclosureGroup {
                            parameterGrid(for: group)
                            addParameterRow(site: group.site)
                        } label: {
                            ruleGroupLabel(group)
                        }
                    }
                    DisclosureHeaderRow(isExpanded: $showingAddSite) {
                        Label(l10n.s.urlCleanerRulesAddSite, systemImage: "plus.circle")
                        Spacer()
                    }
                    if showingAddSite { addSiteRow.disclosureIndent() }
                    Text(l10n.s.urlCleanerRulesCaption).font(SettingsTypography.caption).foregroundStyle(.secondary)
                    Text(l10n.s.urlCleanerRulesCoverageCaption).font(SettingsTypography.caption).foregroundStyle(.secondary)
                }
                URLRuleTransferView(globalNames: $globalNames, siteNames: $siteNames, disabledNames: $disabledNames)
            }
        }
        .settingsSectionAnchor(.urlCleaner)
        .onChange(of: input) { _, value in invalidateForInput(value) }
        .onChange(of: globalNames) { _, _ in invalidateForRules() }
        .onChange(of: siteNames) { _, _ in invalidateForRules() }
        .onChange(of: disabledNames) { _, _ in invalidateForRules() }
        .confirmationDialog(actionText.deleteTitle,
                            isPresented: Binding(get: { pendingRemoval != nil },
                                                 set: { if !$0 { pendingRemoval = nil } }),
                            titleVisibility: .visible) {
            if let pendingRemoval {
                Button(actionText.delete + " “" + pendingRemoval.name + "”", role: .destructive) {
                    remove(pendingRemoval.name, from: pendingRemoval.site)
                    self.pendingRemoval = nil
                }
            }
            Button(actionText.cancel, role: .cancel) { pendingRemoval = nil }
        } message: {
            if let pendingRemoval {
                Text(title(for: pendingRemoval.site) + " · " + pendingRemoval.name + "\n" +
                     actionText.deleteMessage)
            }
        }
    }

    private func ruleGroupLabel(_ group: URLCleaning.RuleGroup) -> some View {
        HStack {
            Text(title(for: group.site))
            Spacer()
            Text(actionText.enabledCount(group.enabledCount, total: group.entries.count))
                .foregroundStyle(.secondary)
            Menu {
                Button(actionText.enableGroup) { setGroupEnabled(true, group: group) }
                    .disabled(group.enabledCount == group.entries.count)
                Button(actionText.disableGroup) { setGroupEnabled(false, group: group) }
                    .disabled(group.enabledCount == 0)
            } label: {
                Image(systemName: "ellipsis").frame(width: 24, height: 22)
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
            .help(actionText.groupHelp)
            .accessibilityLabel(title(for: group.site) + " · " + actionText.ruleActions)
        }
    }

    /// Two columns keep a long site list (Bilibili has two dozen names) inside
    /// a row someone can still scroll past.
    private func parameterGrid(for group: URLCleaning.RuleGroup) -> some View {
        LazyVGrid(columns: [GridItem(.flexible(), alignment: .leading),
                            GridItem(.flexible(), alignment: .leading)],
                  alignment: .leading, spacing: 4) {
            ForEach(group.entries) { entry in
                HStack(spacing: 4) {
                    Toggle(entry.name, isOn: enabledBinding(site: group.site, name: entry.name))
                        .toggleStyle(.checkbox)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    if !entry.isBuiltIn {
                        Menu {
                            Button(actionText.deleteCustom, role: .destructive) {
                                pendingRemoval = (group.site, entry.name)
                            }
                        } label: {
                            Image(systemName: "ellipsis")
                        }
                        .menuStyle(.borderlessButton)
                        .fixedSize()
                        .accessibilityLabel(entry.name + " · " + actionText.ruleActions)
                    }
                    Spacer(minLength: 0)
                }
            }
        }
    }

    /// The caption belongs beside the field rather than in the section's own,
    /// which is where someone is when they need to know what a rule matches:
    /// a name, not a position, and one parameter at a time.
    private func addParameterRow(site: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                TextField("", text: parameterDraftBinding(for: site),
                          prompt: Text(l10n.s.urlCleanerRulesParameterPlaceholder))
                    .textFieldStyle(.roundedBorder)
                    .labelsHidden()
                    .accessibilityLabel(l10n.s.urlCleanerRulesParameterPlaceholder)
                    .onSubmit { addParameter(to: site) }
                Button { addParameter(to: site) } label: {
                    Label(l10n.s.urlCleanerRulesAddButton, systemImage: "plus")
                }
                .disabled(URLCleaning.parameterName(from: parameterDrafts[site] ?? "") == nil)
            }
            Text(l10n.s.urlCleanerRulesMatchCaption)
                .font(.callout)
                .foregroundStyle(.secondary)
        }
    }

    /// A site arrives with its first name. An empty site is not a rule, so
    /// there is nothing to store or to list until one is typed.
    private var addSiteRow: some View {
        HStack(spacing: 8) {
            TextField("", text: $siteDraft, prompt: Text(verbatim: "example.com"))
                .textFieldStyle(.roundedBorder)
                .labelsHidden()
                .accessibilityLabel(l10n.s.urlCleanerRulesAddSite)
                .onSubmit { addSite() }
            TextField("", text: $siteParameterDraft,
                      prompt: Text(l10n.s.urlCleanerRulesParameterPlaceholder))
                .textFieldStyle(.roundedBorder)
                .labelsHidden()
                .accessibilityLabel(l10n.s.urlCleanerRulesParameterPlaceholder)
                .onSubmit { addSite() }
            Button(action: addSite) {
                Label(l10n.s.urlCleanerRulesAddButton, systemImage: "plus")
            }
            .disabled(URLCleaning.siteKey(from: siteDraft) == nil
                            || URLCleaning.parameterName(from: siteParameterDraft) == nil)
        }
    }

    private func title(for site: String) -> String {
        site == URLCleaning.allSites ? l10n.s.urlCleanerRulesAllSites : site
    }

    private func removedSummary(_ names: [String]) -> String {
        String(format: l10n.s.urlCleanerRemovedFormat, names.joined(separator: ", "))
    }

    private func parameterDraftBinding(for site: String) -> Binding<String> {
        Binding { parameterDrafts[site] ?? "" } set: { parameterDrafts[site] = $0 }
    }

    private func enabledBinding(site: String, name: String) -> Binding<Bool> {
        Binding {
            !(URLCleaning.tokens(from: disabledNames)[site] ?? []).contains(name)
        } set: { isOn in
            var disabled = URLCleaning.tokens(from: disabledNames)
            if isOn {
                disabled[site]?.remove(name)
            } else {
                disabled[site, default: []].insert(name)
            }
            disabledNames = URLCleaning.storageValue(forTokens: disabled)
        }
    }

    private func addSite() {
        guard let site = URLCleaning.siteKey(from: siteDraft),
              let name = URLCleaning.parameterName(from: siteParameterDraft) else { return }
        siteDraft = ""
        siteParameterDraft = ""
        var added = URLCleaning.tokens(from: siteNames)
        added[site, default: []].insert(name)
        siteNames = URLCleaning.storageValue(forTokens: added)
    }

    private func addParameter(to site: String) {
        guard let name = URLCleaning.parameterName(from: parameterDrafts[site] ?? "") else { return }
        parameterDrafts[site] = ""
        // A name switched off earlier and then typed back in is the same
        // request as switching it on again.
        var disabled = URLCleaning.tokens(from: disabledNames)
        disabled[site]?.remove(name)
        disabledNames = URLCleaning.storageValue(forTokens: disabled)
        if site == URLCleaning.allSites {
            var names = URLCleaning.customParameters(from: globalNames)
            names.insert(name)
            globalNames = URLCleaning.storageValue(forNames: names)
        } else {
            var added = URLCleaning.tokens(from: siteNames)
            added[site, default: []].insert(name)
            siteNames = URLCleaning.storageValue(forTokens: added)
        }
    }

    private func setGroupEnabled(_ enabled: Bool, group: URLCleaning.RuleGroup) {
        let changed = URLCleaning.settingGroupEnabled(enabled, site: group.site, rules: rules)
        disabledNames = URLCleaning.storageValue(forTokens: changed.disabled)
    }

    private func remove(_ name: String, from site: String) {
        var disabled = URLCleaning.tokens(from: disabledNames)
        disabled[site]?.remove(name)
        disabledNames = URLCleaning.storageValue(forTokens: disabled)
        if site == URLCleaning.allSites {
            var names = URLCleaning.customParameters(from: globalNames)
            names.remove(name)
            globalNames = URLCleaning.storageValue(forNames: names)
        } else {
            var added = URLCleaning.tokens(from: siteNames)
            added[site]?.remove(name)
            siteNames = URLCleaning.storageValue(forTokens: added)
        }
    }

    /// Through the shared lane: a direct read here would both race the
    /// clipboard services on AppKit's pasteboard cache and hang the button
    /// (and with it the app) on a promised flavour nobody renders any more.
    private func paste() {
        GeneralPasteboardAccess.shared.async({
            NSPasteboard.general.string(forType: .string) ?? ""
        }, then: { pasted in
            self.input = pasted
            self.clean()
        })
    }

    private func clean() {
        let result = cleaner.clean(input)
        resultState.record(result, input: input, rules: rules)
        switch URLCleaning.outcome(for: result, input: input) {
        case .notAURL: message = l10n.s.urlCleanerNoURL
        case .unchanged: message = l10n.s.urlCleanerNoChange
        case .rewritten: message = l10n.s.urlCleanerCleaned
        case .removed(let names): message = removedSummary(names)
        }
    }

    private func copy() {
        guard resultState.canCopy else { return }
        cleaner.copy(resultState.output)
        message = l10n.s.urlCleanerCopied
    }

    private func clearInput() {
        input = ""
        resultState.invalidate()
        message = nil
    }

    private func invalidateForInput(_ input: String) {
        if resultState.invalidateIfInputChanged(to: input) { message = flowText.resultExpired }
    }

    private func invalidateForRules() {
        if resultState.invalidateIfRulesChanged(to: rules) { message = flowText.resultExpired }
    }
}
