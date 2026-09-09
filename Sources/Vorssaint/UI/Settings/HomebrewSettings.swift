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

    var body: some View {
        VStack(spacing: 0) {
            pageHeader
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            Divider()
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
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
            Label(AppFeature.homebrew.name(l10n.s, language: l10n.language), systemImage: "shippingbox")
                .font(.system(size: 14, weight: .semibold))
            Spacer(minLength: 0)
            refreshButton
            if homebrew.brewPath != nil {
                updateHomebrewButton
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
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
                        .font(.caption)
                        .foregroundStyle(.red)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if homebrew.brewPath == nil && homebrew.masPath == nil {
                    missingState
                } else {
                    sections
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    private var sections: some View {
        if homebrew.brewPath != nil {
            packageSection(title: l10n.s.homebrewRequested,
                           packages: HomebrewPackageOrdering.updatesFirst(homebrew.requestedPackages),
                           loading: homebrew.isLoadingInstalled)
            packageSection(title: l10n.s.homebrewDependencies,
                           note: l10n.s.homebrewDependenciesNote,
                           packages: homebrew.dependencyPackages,
                           loading: homebrew.isLoadingInstalled)
        }
        if homebrew.masPath != nil {
            packageSection(title: l10n.s.homebrewMasApps,
                           packages: homebrew.masApps,
                           loading: false)
        }
    }

    private var missingState: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(l10n.s.homebrewMissingTitle)
                .font(.system(size: 13, weight: .semibold))
            Text(l10n.s.homebrewMissingBody)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var refreshButton: some View {
        Button {
            homebrew.refreshInstalled()
        } label: {
            Image(systemName: "arrow.clockwise")
        }
        .fixedSize()
        .help(l10n.s.homebrewRefresh)
        .disabled(homebrew.isBusy)
    }

    private var updateHomebrewButton: some View {
        Button {
            pendingAction = HomebrewPendingAction(action: .updateHomebrew)
        } label: {
            Label(l10n.s.homebrewUpdateHomebrew, systemImage: "arrow.triangle.2.circlepath")
        }
        .fixedSize()
        .controlSize(.small)
        .disabled(homebrew.isBusy)
    }

    private func packageSection(title: String,
                                note: String? = nil,
                                packages: [HomebrewPackage],
                                loading: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Text(title)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
                countBadge(packages.count)
                Spacer(minLength: 0)
            }
            if let note {
                Text(note)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if loading {
                HStack(spacing: 8) {
                    ProgressView().controlSize(.small)
                    Text(l10n.s.homebrewLoading)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else if packages.isEmpty {
                Text(l10n.s.homebrewNoPackages)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                LazyVStack(alignment: .leading, spacing: 2) {
                    ForEach(packages) { package in
                        packageRow(package)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func countBadge(_ count: Int) -> some View {
        Text("\(count)")
            .font(.system(size: 9, weight: .semibold, design: .rounded))
            .monospacedDigit()
            .foregroundStyle(.secondary)
            .padding(.horizontal, 5)
            .padding(.vertical, 1)
            .background(Capsule().fill(Color.primary.opacity(0.06)))
    }

    private func packageRow(_ package: HomebrewPackage) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(package.displayName)
                        .font(.system(size: 12, weight: .medium))
                        .lineLimit(1)
                    if let version = package.versionText {
                        Text(version)
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                if let desc = package.desc, !desc.isEmpty {
                    Text(desc)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            Spacer(minLength: 8)
            if let update = package.update {
                if package.installedOnRequest {
                    Button {
                        pendingAction = HomebrewPendingAction(action: .upgrade, package: package)
                    } label: {
                        Text("\(l10n.s.homebrewUpgrade) \(update.currentVersion)")
                    }
                    .controlSize(.small)
                    .disabled(homebrew.isBusy || update.isPinned)
                } else {
                    Text(l10n.s.homebrewUpdateAvailableBadge)
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .background(RoundedRectangle(cornerRadius: 6).fill(Color.primary.opacity(0.03)))
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

    // MARK: - Confirmation

    private var confirmationPresented: Binding<Bool> {
        Binding(get: { pendingAction != nil },
                set: { if !$0 { pendingAction = nil } })
    }

    private var confirmationTitle: String {
        guard let pendingAction else { return "" }
        switch pendingAction.action {
        case .upgrade: return l10n.s.homebrewConfirmUpgradeTitle
        case .updateHomebrew: return l10n.s.homebrewConfirmUpdateHomebrewTitle
        case .uninstall: return l10n.s.homebrewConfirmUninstallTitle
        }
    }

    private func confirmationBody(for action: HomebrewPendingAction) -> String {
        switch action.action {
        case .upgrade:
            return String(format: l10n.s.homebrewConfirmUpgradeBodyFormat,
                          action.package?.displayName ?? "")
        case .updateHomebrew:
            return l10n.s.homebrewConfirmUpdateHomebrewBody
        case .uninstall:
            return String(format: l10n.s.homebrewConfirmUninstallBodyFormat,
                          action.package?.displayName ?? "")
        }
    }

    private func actionTitle(for action: HomebrewPendingAction) -> String {
        switch action.action {
        case .upgrade: return l10n.s.homebrewUpgrade
        case .updateHomebrew: return l10n.s.homebrewUpdateHomebrew
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
                .font(compact ? .system(size: 11, weight: .semibold) : .headline)
            Text(String(format: l10n.s.homebrewTrustCaption, tap))
                .font(compact ? .system(size: 9.5) : .caption)
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
