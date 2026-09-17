// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import AppKit
import SwiftUI

/// Lists what is installed on the machine, split by who asked for it. Nothing
/// here installs or searches: the page exists so a person can see the packages
/// they chose and the ones something else pulled in behind them. Only the
/// first kind gets an upgrade button — see `HomebrewCommandBuilder.upgrade`.
struct HomebrewSettings: View {
    @ObservedObject private var l10n = L10n.shared
    @ObservedObject private var homebrew = HomebrewManager.shared
    @State private var pendingAction: HomebrewPendingAction?
    @State private var showOperationDetails = false
    /// Ids of the packages whose dependencies are open. Collapsed by default:
    /// the list is about what the person chose, and the dependencies are the
    /// answer to a question they have to ask.
    @State private var expanded: Set<String> = []

    private var hierarchyText: HomebrewHierarchyStrings {
        HomebrewHierarchyStrings(language: l10n.language)
    }

    var body: some View {
        VStack(spacing: 0) {
            pageHeader
                .padding(.horizontal, SettingsVisualStyle.current.pageInset)
                .padding(.vertical, 12)
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .font(SettingsTypography.body)
        .controlSize(.regular)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .onAppear {
            if homebrew.installed.isEmpty {
                homebrew.refreshInstalled()
            }
        }
        .onChange(of: homebrew.operationStatus?.targetID) { _, _ in
            showOperationDetails = false
        }
        .confirmationDialog(confirmationTitle,
                            isPresented: confirmationPresented,
                            titleVisibility: .visible) {
            if let pendingAction {
                Button(actionTitle(for: pendingAction)) { run(pendingAction) }
            }
            Button(l10n.s.uninstallerCancel, role: .cancel) { pendingAction = nil }
        } message: {
            if let pendingAction {
                Text(confirmationBody(for: pendingAction))
            }
        }
    }

    private var pageHeader: some View {
        HStack(spacing: 8) {
            Spacer(minLength: 0)
            refreshButton
            if homebrew.brewPath != nil {
                updateHomebrewButton
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var content: some View {
        SettingsForm {
            if let tap = homebrew.untrustedTap {
                HomebrewTrustCard(tap: tap)
            }
            if let status = homebrew.operationStatus {
                HomebrewOperationStatusView(status: status,
                                            log: homebrew.log,
                                            terminalFallbackCommand: homebrew.terminalFallbackCommand,
                                            compact: false,
                                            showDetails: $showOperationDetails,
                                            onCancel: homebrew.cancelOperation,
                                            onClear: homebrew.clearLog,
                                            onOpenTerminal: homebrew.openTerminalFallback)
            }
            if let error = homebrew.errorMessage, !error.isEmpty {
                Text(error)
                    .font(SettingsTypography.caption)
                    .foregroundStyle(.red)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if homebrew.brewPath == nil && homebrew.masPath == nil {
                missingState
            } else {
                sections
            }
        }
    }

    @ViewBuilder
    private var sections: some View {
        if homebrew.brewPath != nil {
            packageSection(title: l10n.s.homebrewRequested,
                           systemImage: "shippingbox",
                           packages: HomebrewPackageOrdering.updatesFirst(homebrew.requestedPackages),
                           loading: homebrew.isLoadingInstalled)
            let orphans = homebrew.orphanedPackages
            if !orphans.isEmpty {
                packageSection(title: l10n.s.homebrewOrphans,
                               systemImage: "shippingbox",
                               note: l10n.s.homebrewOrphansNote,
                               packages: orphans,
                               loading: homebrew.isLoadingInstalled)
            }
        }
        if homebrew.masPath != nil {
            packageSection(title: l10n.s.homebrewMasApps,
                           systemImage: "app.badge",
                           packages: homebrew.masApps,
                           loading: false)
        }
    }

    private var missingState: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(l10n.s.homebrewMissingTitle)
                .font(SettingsTypography.sectionTitle)
            Text(l10n.s.homebrewMissingBody)
                .font(SettingsTypography.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var refreshButton: some View {
        Button {
            homebrew.refreshInstalled()
        } label: {
            Label(hierarchyText.rereadInstalled, systemImage: "arrow.clockwise")
        }
        .settingsAction(.secondary)
        .fixedSize()
        .help(hierarchyText.rereadInstalled)
        .accessibilityLabel(hierarchyText.rereadInstalled)
        .disabled(homebrew.isBusy)
    }

    private var updateHomebrewButton: some View {
        Button {
            pendingAction = HomebrewPendingAction(action: .updateHomebrew)
        } label: {
            Label(hierarchyText.updateDefinitions, systemImage: "arrow.triangle.2.circlepath")
        }
        .settingsAction(.primary)
        .fixedSize()
        .controlSize(.regular)
        .disabled(homebrew.isBusy)
    }

    private func packageSection(title: String,
                                systemImage: String,
                                note: String? = nil,
                                packages: [HomebrewPackage],
                                loading: Bool) -> some View {
        SettingsSection {
            if let note {
                SettingsExplanation(note)
            }
            if loading {
                HStack(spacing: 8) {
                    ProgressView().controlSize(.small)
                    Text(l10n.s.homebrewLoading)
                        .font(SettingsTypography.caption)
                        .foregroundStyle(.secondary)
                }
            } else if packages.isEmpty {
                Text(l10n.s.homebrewNoPackages)
                    .font(SettingsTypography.caption)
                    .foregroundStyle(.secondary)
            } else {
                LazyVStack(alignment: .leading, spacing: 2) {
                    ForEach(packages) { package in
                        packageRow(package)
                        if expanded.contains(package.id) {
                            ForEach(homebrew.dependencies(of: package)) { dependency in
                                dependencyRow(dependency, under: package)
                            }
                        }
                    }
                }
            }
        } header: {
            HStack(spacing: 8) {
                Label(title, systemImage: systemImage)
                countBadge(packages.count)
            }
        }
    }

    private func countBadge(_ count: Int) -> some View {
        Text("\(count)")
            .font(.system(.subheadline, design: .rounded, weight: .semibold))
            .monospacedDigit()
            .foregroundStyle(.secondary)
            .padding(.horizontal, 5)
            .padding(.vertical, 1)
            .background(Capsule().fill(Color.primary.opacity(0.06)))
    }

    private func packageRow(_ package: HomebrewPackage) -> some View {
        let dependencies = homebrew.dependencies(of: package)
        return VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text(package.displayName)
                    .font(SettingsTypography.body.weight(.semibold))
                    .fixedSize(horizontal: false, vertical: true)
                if package.update == nil, let version = package.versionText {
                    Text(version)
                        .font(SettingsTypography.caption.monospaced())
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Spacer(minLength: 8)
                disclosure(for: package, count: dependencies.count)
                packageUpdate(package)
            }
            if let desc = package.desc, !desc.isEmpty {
                Text(desc)
                    .font(SettingsTypography.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .settingsItemSurface()
        .contextMenu {
            Button(l10n.s.homebrewCopyName) {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(package.name, forType: .string)
            }
            if let homepage = package.homepage, let url = URL(string: homepage) {
                Button(l10n.s.homebrewHomepage) { NSWorkspace.shared.open(url) }
            }
        }
    }

    @ViewBuilder
    private func packageUpdate(_ package: HomebrewPackage) -> some View {
        if let update = package.update {
            HStack(spacing: 10) {
                versionChange(update)
                if package.installedOnRequest {
                    Button {
                        pendingAction = HomebrewPendingAction(action: .upgrade, package: package)
                    } label: {
                        Label(l10n.s.homebrewUpgrade, systemImage: "arrow.up.circle")
                    }
                    .settingsAction(.primary)
                    .fixedSize()
                    .disabled(homebrew.isBusy || update.isPinned)
                    if update.isPinned {
                        Image(systemName: "pin.fill")
                            .foregroundStyle(.secondary)
                            .help(l10n.s.homebrewPinnedVersion)
                            .accessibilityLabel(l10n.s.homebrewPinnedVersion)
                    }
                } else {
                    Text(l10n.s.homebrewUpdateAvailableBadge)
                        .font(SettingsTypography.caption)
                        .foregroundStyle(.orange)
                }
            }
            .layoutPriority(1)
        }
    }

    private func versionChange(_ update: HomebrewPackageUpdate) -> some View {
        let installed = update.installedText.isEmpty ? "—" : update.installedText
        let summary = "\(hierarchyText.currentVersion): \(installed), \(hierarchyText.targetVersion): \(update.currentVersion)"
        return HStack(spacing: 5) {
            Text(installed).foregroundStyle(.secondary)
            Image(systemName: "arrow.right").foregroundStyle(.tertiary)
            Text(update.currentVersion)
        }
        .font(SettingsTypography.caption.monospaced())
        .textSelection(.enabled)
        .fixedSize(horizontal: true, vertical: false)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(summary)
        .help(summary)
    }

    @ViewBuilder
    private func disclosure(for package: HomebrewPackage, count: Int) -> some View {
        if count > 0 {
            Button {
                if expanded.contains(package.id) {
                    expanded.remove(package.id)
                } else {
                    expanded.insert(package.id)
                }
            } label: {
                HStack(spacing: 3) {
                    Image(systemName: "shippingbox")
                    Text("\(count)")
                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                        .monospacedDigit()
                    Image(systemName: "chevron.down")
                        .font(.system(size: 9, weight: .semibold))
                        .rotationEffect(.degrees(expanded.contains(package.id) ? 180 : 0))
                }
            }
            .settingsAction(.secondary)
            .accessibilityLabel(HomebrewDependencyStrings(language: l10n.language)
                .action(package: package.displayName, count: count, expanded: expanded.contains(package.id)))
            .accessibilityValue(HomebrewDependencyStrings(language: l10n.language)
                .state(expanded: expanded.contains(package.id)))
            .help(HomebrewDependencyStrings(language: l10n.language)
                .action(package: package.displayName, count: count, expanded: expanded.contains(package.id)))
        }
    }

    /// One dependency, indented under the package that pulled it in. Only a
    /// dependency shared with another package says anything: that is the one
    /// a person would otherwise read as belonging to this package alone.
    private func dependencyRow(_ dependency: HomebrewPackage,
                               under root: HomebrewPackage) -> some View {
        let shared = homebrew.sharedRoots(of: dependency, besides: root)
        return VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 6) {
                Text(dependency.displayName)
                    .font(SettingsTypography.body)
                    .lineLimit(1)
                if let version = dependency.versionText {
                    Text(version)
                        .font(.system(.callout, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Spacer(minLength: 0)
            }
            if !shared.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(SettingsTypography.smallIcon)
                        .foregroundStyle(.yellow)
                    Text(String(format: l10n.s.homebrewSharedWithFormat,
                                shared.joined(separator: ", ")))
                        .font(SettingsTypography.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }
        }
        .padding(.leading, 24)
        .padding(.trailing, 8)
        .padding(.vertical, 3)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Confirmation

    private var confirmationPresented: Binding<Bool> {
        Binding(get: { pendingAction != nil },
                set: { if !$0 { pendingAction = nil } })
    }

    private var confirmationTitle: String {
        guard let pendingAction else { return "" }
        switch pendingAction.action {
        case .upgrade: return l10n.s.homebrewConfirmUpgradeTitle
        case .updateHomebrew: return hierarchyText.updateDefinitions
        case .uninstall: return l10n.s.homebrewConfirmUninstallTitle
        }
    }

    private func confirmationBody(for action: HomebrewPendingAction) -> String {
        switch action.action {
        case .upgrade:
            return String(format: l10n.s.homebrewConfirmUpgradeBodyFormat,
                          action.package?.displayName ?? "")
        case .updateHomebrew:
            return hierarchyText.updateDefinitionsConfirmation
        case .uninstall:
            return String(format: l10n.s.homebrewConfirmUninstallBodyFormat,
                          action.package?.displayName ?? "")
        }
    }

    private func actionTitle(for action: HomebrewPendingAction) -> String {
        switch action.action {
        case .upgrade: return l10n.s.homebrewUpgrade
        case .updateHomebrew: return hierarchyText.updateDefinitions
        case .uninstall: return l10n.s.homebrewUninstall
        }
    }

    private func run(_ action: HomebrewPendingAction) {
        pendingAction = nil
        switch action.action {
        case .upgrade:
            if let package = action.package { homebrew.upgrade(package) }
        case .updateHomebrew:
            homebrew.updateHomebrew()
        case .uninstall:
            if let package = action.package { homebrew.uninstall(package) }
        }
    }
}

struct HomebrewTrustCard: View {
    @ObservedObject private var l10n = L10n.shared
    @ObservedObject private var homebrew = HomebrewManager.shared
    let tap: String
    var compact = false

    var body: some View {
        VStack(alignment: .leading, spacing: compact ? 6 : 8) {
            Label(l10n.s.homebrewTrustTitle, systemImage: "checkmark.shield")
                .font(compact ? .system(.subheadline, weight: .semibold) : SettingsTypography.sectionTitle)
            Text(String(format: l10n.s.homebrewTrustCaption, tap))
                .font(compact ? .system(size: 9.5) : SettingsTypography.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Button {
                homebrew.trustTapAndContinue()
            } label: {
                HStack(spacing: 5) {
                    if homebrew.isTrustingTap {
                        ProgressView()
                            .controlSize(.mini)
                    }
                    Text(l10n.s.homebrewTrustButton)
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(compact ? .small : .regular)
            .disabled(homebrew.isTrustingTap)
        }
        .padding(compact ? 8 : 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color.orange.opacity(0.09)))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.orange.opacity(0.22), lineWidth: 1))
    }
}
