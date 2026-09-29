// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import AppKit
import SwiftUI

/// Environment diagnostics and user-triggered update checks; installation stays with each tool's manager.
struct EnvironmentSettings: View {
    @ObservedObject private var l10n = L10n.shared
    @ObservedObject private var inspector = EnvironmentInspector.shared
    @ObservedObject private var updates = EnvironmentUpdateChecker.shared
    @State private var copyFeedback = EnvironmentCopyFeedback()
    @ObservedObject private var homebrew = HomebrewManager.shared
    @State private var tab = 0
    @State private var expanded: Set<String> = []
    @State private var showDiagnostics = false
    @State private var showOperationDetails = false
    @State private var pendingPackage: HomebrewPackage?
    @State private var configurations: [EnvironmentConfiguration] = []
    @State private var projectDirectory: String?

    private func label(_ zh: String, _ en: String, _ de: String, _ fr: String, _ es: String, _ ja: String) -> String {
        switch l10n.language {
        case .zhHans: return zh
        case .de: return de
        case .fr: return fr
        case .es: return es
        case .ja: return ja
        default: return en
        }
    }
    private var busy: Bool { inspector.isLoading || updates.isChecking || homebrew.isBusy }

    private var detailText: EnvironmentDetailStrings { EnvironmentDetailStrings(language: l10n.language) }

    private var text: EnvironmentFeatureStrings { FeatureStrings.environment(l10n.language) }
    private var updateText: EnvironmentUpdateStrings { EnvironmentUpdateStrings(language: l10n.language) }

    var body: some View {
        VStack(spacing: 0) {
            header
                .padding(.horizontal, SettingsMetrics.pageInset)
                .padding(.vertical, 12)
            SettingsForm {
                if tab == 0 {
                    if let tap = homebrew.untrustedTap {
                        HomebrewTrustCard(tap: tap)
                    }
                    if let status = homebrew.operationStatus {
                        HomebrewOperationStatusView(status: status, log: homebrew.log,
                            terminalFallbackCommand: homebrew.terminalFallbackCommand, compact: false,
                            showDetails: $showOperationDetails, onCancel: homebrew.cancelOperation,
                            onClear: homebrew.clearLog, onOpenTerminal: homebrew.openTerminalFallback)
                    }
                    commandsSection
                    DisclosureGroup(isExpanded: $showDiagnostics) {
                        pathSection
                        cachesSection
                        SettingsExplanation(updateText.note)
                    } label: {
                        Text(label("环境诊断", "Environment diagnostics", "Umgebungsdiagnose", "Diagnostic de l’environnement", "Diagnóstico del entorno", "環境の診断"))
                            .font(SettingsTypography.body.weight(.medium))
                    }
                } else {
                    configurationSections
                }
            }
        }
        .font(SettingsTypography.body)
        .controlSize(.regular)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .onAppear {
            reloadConfigurations()
            if inspector.report.tools.isEmpty {
                copyFeedback.clear()
                inspector.refresh()
            }
        }
        .onChange(of: inspector.isLoading) { _, _ in
            copyFeedback.clear()
        }
        .confirmationDialog(l10n.s.homebrewConfirmUpgradeTitle,
            isPresented: Binding(get: { pendingPackage != nil }, set: { if !$0 { pendingPackage = nil } }),
            titleVisibility: .visible) {
                if let package = pendingPackage {
                    Button(l10n.s.homebrewUpgrade) { homebrew.upgrade(package); pendingPackage = nil }
                }
                Button(l10n.s.uninstallerCancel, role: .cancel) { pendingPackage = nil }
            } message: {
                if let package = pendingPackage {
                    Text(String(format: l10n.s.homebrewConfirmUpgradeBodyFormat, package.displayName))
                }
            }
    }

    private var header: some View {
        HStack(spacing: 8) {
            Picker("", selection: $tab) {
                Text(label("工具", "Tools", "Werkzeuge", "Outils", "Herramientas", "ツール")).tag(0)
                Text(label("配置文件", "Configuration files", "Konfigurationsdateien", "Fichiers de configuration", "Archivos de configuración", "設定ファイル")).tag(1)
            }
            .pickerStyle(.segmented)
            .frame(width: 190)
            Spacer(minLength: 8)
            Button {
                reloadConfigurations()
                copyFeedback.clear()
                updates.reset()
                inspector.refresh()
            } label: { Label(text.refresh, systemImage: "arrow.clockwise") }
            .settingsAction(.secondary)
            .disabled(busy)
            if tab == 0 {
                Button { updates.refreshAndCheck() } label: {
                    HStack(spacing: 6) {
                        if updates.isChecking { ProgressView().controlSize(.small) }
                        Text(updateText.check)
                    }
                }
                .settingsAction(.primary)
                .disabled(busy)
            }
            Menu {
                Button(text.copyReport) {
                    copy(EnvironmentInspector.diagnosticText(inspector.report, updates: updates.records), target: "report")
                }
            } label: { Image(systemName: "ellipsis") }
            .menuStyle(.borderlessButton)
            .fixedSize()
            .disabled(busy)
        }
    }

    private func group(_ tool: EnvironmentTool) -> Int {
        switch tool.source {
        case .standalone, .homebrew, .managed: return 0
        case .system, .appleDeveloperTools: return 1
        case .forwarded, .unknown: return 2
        }
    }

    private func available(_ tool: EnvironmentTool) -> String? {
        guard let record = updates.records[tool.command], record.isVisible,
              case let .available(version) = record.result?.status else { return nil }
        return version
    }

    private var commandsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            if inspector.isLoading && inspector.report.tools.isEmpty { ProgressView() }
            ForEach(0..<3) { index in
                let tools = inspector.report.tools.filter { group($0) == index }.sorted {
                    if (available($0) != nil) != (available($1) != nil) { return available($0) != nil }
                    return $0.command.localizedStandardCompare($1.command) == .orderedAscending
                }
                if !tools.isEmpty {
                    SettingsSection {
                        LazyVStack(spacing: 2) {
                            ForEach(tools) { tool in commandRow(tool) }
                        }
                    } header: {
                        HStack(spacing: 8) {
                            Text(index == 0 ? label("用户安装", "User installed", "Vom Benutzer installiert", "Installés par l’utilisateur", "Instalados por el usuario", "ユーザーがインストール") : index == 1
                                ? label("系统与开发工具附带", "Bundled tools", "Mitgelieferte Werkzeuge", "Outils fournis", "Herramientas incluidas", "付属ツール") : label("其他命令", "Other commands", "Weitere Befehle", "Autres commandes", "Otros comandos", "その他のコマンド"))
                            Text("\(tools.count)")
                                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 5).padding(.vertical, 1)
                                .background(Capsule().fill(Color.primary.opacity(0.06)))
                        }
                    }
                }
            }
            if let checked = updates.records.values.compactMap(\.checkedAt).max(), !updates.isChecking {
                Text("\(updateText.checked): \(checked.formatted(date: .abbreviated, time: .shortened))")
                    .font(SettingsTypography.caption).foregroundStyle(.secondary)
            }
        }
    }

    private func commandRow(_ tool: EnvironmentTool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Button {
                    if !expanded.insert(tool.id).inserted { expanded.remove(tool.id) }
                } label: {
                    Image(systemName: expanded.contains(tool.id) ? "chevron.down" : "chevron.right")
                        .font(.system(.caption, weight: .semibold)).frame(width: 12)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(label("显示详情：", "Show details: ", "Details anzeigen: ", "Afficher les détails : ", "Mostrar detalles: ", "詳細を表示：") + tool.command)
                Text(tool.command).font(SettingsTypography.body.weight(.semibold))
                Spacer(minLength: 8)
                HStack(spacing: 5) {
                    Text(displayVersion(tool)).foregroundStyle(.secondary)
                    if let version = available(tool) {
                        Image(systemName: "arrow.right").foregroundStyle(.tertiary)
                        Text(version)
                    }
                }
                .font(SettingsTypography.caption.monospaced())
                .textSelection(.enabled)
                .lineLimit(1)
                if available(tool) != nil { upgradeAction(tool) }
                if let record = updates.records[tool.id], record.isVisible, record.result?.status == .failed {
                    Image(systemName: "exclamationmark.circle").foregroundStyle(.orange)
                        .help(updateText.status(.failed))
                        .accessibilityLabel(updateText.status(.failed))
                }
            }
            Text(compactSource(tool.source))
                .font(SettingsTypography.caption).foregroundStyle(.secondary)
                .padding(.leading, 22)
            if expanded.contains(tool.id) {
                VStack(alignment: .leading, spacing: 10) {
                    if let version = tool.version {
                        Text("\(detailText.version(reportedByForwarder: tool.isShim)): \(version)")
                            .font(SettingsTypography.caption).foregroundStyle(.secondary).textSelection(.enabled)
                    }
                    if let path = tool.path {
                        pathRow(label: detailText.resolvedPath, path: path)
                        Button(label("在 Finder 中显示", "Show in Finder", "Im Finder zeigen", "Afficher dans le Finder", "Mostrar en el Finder", "Finderで表示")) {
                            NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: path)])
                        }.buttonStyle(.link)
                    }
                    if let target = tool.shimTarget { pathRow(label: detailText.forwardTarget, path: target) }
                    if let record = updates.records[tool.id], record.isVisible, let result = record.result {
                        Text(updateText.status(result.status)).font(SettingsTypography.caption)
                        if case .homebrew = record.source { SettingsExplanation(updateText.brewNote) }
                    }
                    if !tool.shadowedPaths.isEmpty {
                        Text(detailText.otherCopies(tool.shadowedPaths.count)).font(SettingsTypography.caption)
                        ForEach(tool.shadowedPaths, id: \.self) { path in pathRow(label: nil, path: path) }
                    }
                }.padding(.leading, 22).padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .settingsItemSurface()
    }

    private func displayVersion(_ tool: EnvironmentTool) -> String {
        if available(tool) != nil, case let .homebrew(_, _, version) = tool.source { return version }
        guard let raw = tool.version else {
            return tool.path == nil ? text.notFound : label("版本未读出", "Version unavailable", "Version nicht verfügbar", "Version indisponible", "Versión no disponible", "バージョンを取得できません")
        }
        let tokens = raw.split(whereSeparator: { $0.isWhitespace })
        return tokens.first(where: { $0.first?.isNumber == true || ($0.hasPrefix("v") && $0.dropFirst().first?.isNumber == true) }).map(String.init) ?? raw
    }

    private func compactSource(_ source: EnvironmentUpdateSource) -> String {
        if case let .homebrew(_, formula, _) = source { return label("后装 · Homebrew · ", "User-installed · Homebrew · ", "Nachinstalliert · Homebrew · ", "Installé ensuite · Homebrew · ", "Instalado después · Homebrew · ", "追加インストール · Homebrew · ") + formula }
        return updateText.source(source)
    }

    @ViewBuilder
    private func upgradeAction(_ tool: EnvironmentTool) -> some View {
        if case let .homebrew(prefix, _, _) = tool.source,
           homebrew.brewPath == URL(fileURLWithPath: prefix).appendingPathComponent("bin/brew").path,
           let package = updates.records[tool.id]?.result?.package {
            Button {
                pendingPackage = package
            } label: { Label(l10n.s.homebrewUpgrade, systemImage: "arrow.up.circle") }
            .settingsAction(.primary).fixedSize().disabled(busy)
        } else if case let .standalone(name) = tool.source {
            Link(destination: URL(string: name == "bun" ? "https://bun.sh/docs/installation#upgrading"
                : "https://docs.astral.sh/uv/getting-started/installation/#upgrading-uv")!) {
                Label(updateText.instructions, systemImage: "arrow.up.right")
            }.settingsAction(.secondary).fixedSize()
        }
    }

    private func reloadConfigurations() {
        configurations = EnvironmentConfiguration.discover()
        if let projectDirectory { configurations += EnvironmentConfiguration.discoverProject(projectDirectory) }
    }

    private var configurationSections: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(label("已发现的配置文件；是否生效取决于工具的加载方式。", "Discovered files; tools determine which configuration is loaded.", "Gefundene Dateien; welche Konfiguration geladen wird, bestimmt das jeweilige Werkzeug.", "Fichiers trouvés ; chaque outil décide quelle configuration il charge.", "Archivos encontrados; cada herramienta decide qué configuración carga.", "見つかったファイルです。どの設定を読み込むかはツールによります。"))
                    .font(SettingsTypography.caption).foregroundStyle(.secondary)
                Spacer()
                Button(label("选择项目…", "Choose project…", "Projekt auswählen…", "Choisir un projet…", "Elegir proyecto…", "プロジェクトを選択…")) {
                    let panel = NSOpenPanel()
                    panel.canChooseFiles = false
                    panel.canChooseDirectories = true
                    panel.allowsMultipleSelection = false
                    if panel.runModal() == .OK, let url = panel.url {
                        projectDirectory = url.path
                        reloadConfigurations()
                    }
                }.settingsAction(.secondary).fixedSize()
            }
            ForEach(["user", "project", "system"], id: \.self) { scope in
                let files = configurations.filter { $0.scope == scope }
                if !files.isEmpty || (scope == "project" && projectDirectory != nil) {
                    SettingsSection(title: scope == "user" ? label("用户配置", "User configuration", "Benutzerkonfiguration", "Configuration utilisateur", "Configuración de usuario", "ユーザー設定") : scope == "project"
                        ? label("项目配置", "Project configuration", "Projektkonfiguration", "Configuration du projet", "Configuración del proyecto", "プロジェクト設定") : label("系统配置", "System configuration", "Systemkonfiguration", "Configuration système", "Configuración del sistema", "システム設定"), systemImage: "doc.text") {
                        if scope == "project", let projectDirectory {
                            Text(projectDirectory).font(SettingsTypography.caption).foregroundStyle(.secondary).textSelection(.enabled)
                        }
                        if files.isEmpty {
                            Text(label("此目录未发现支持识别的配置文件。", "No recognized configuration files in this directory.", "In diesem Ordner wurden keine erkannten Konfigurationsdateien gefunden.", "Aucun fichier de configuration reconnu dans ce dossier.", "No hay archivos de configuración reconocidos en esta carpeta.", "このフォルダに認識できる設定ファイルはありません。"))
                                .font(SettingsTypography.caption).foregroundStyle(.secondary)
                        }
                        ForEach(files) { file in
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(file.name).font(SettingsTypography.body.weight(.semibold))
                                    Text(file.path).font(SettingsTypography.caption.monospaced())
                                        .foregroundStyle(.secondary).textSelection(.enabled)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                Spacer(minLength: 8)
                                Button(label("定位", "Reveal", "Zeigen", "Afficher", "Mostrar", "表示")) {
                                    NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: file.path)])
                                }.settingsAction(.secondary).fixedSize()
                                EnvironmentCopyButton(title: text.copyPath, succeeded: copyFeedback.result(for: file.path),
                                    copied: text.copied, failed: text.copyFailed) { copy(file.path, target: file.path) }
                                    .fixedSize()
                            }.settingsItemSurface()
                        }
                    }
                }
            }
        }
    }

    private func pathRow(label: String?, path: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                if let label {
                    Text(label)
                        .font(SettingsTypography.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                }
                Text(abbreviate(path))
                    .font(.system(.callout, design: .monospaced))
                    .textSelection(.enabled)
                    .fixedSize(horizontal: false, vertical: true)
                    .help(path)
            }
            Spacer(minLength: 8)
            EnvironmentCopyButton(title: text.copyPath,
                                  succeeded: copyFeedback.result(for: path),
                                  copied: text.copied, failed: text.copyFailed) {
                copy(path, target: path)
            }
            .fixedSize()
            .disabled(inspector.isLoading)
        }
    }

    // MARK: - Terminal PATH vs app PATH

    private var pathSection: some View {
        section(text.pathTitle, systemImage: "arrow.triangle.branch", note: detailText.pathNote) {
            VStack(alignment: .leading, spacing: 10) {
                if !inspector.report.readLoginShell && !inspector.report.terminalPath.isEmpty {
                    Text(text.shellUnavailable)
                        .font(SettingsTypography.caption)
                        .foregroundStyle(.orange)
                        .fixedSize(horizontal: false, vertical: true)
                }
                pathList(detailText.pathDifference,
                         entries: inspector.report.terminalOnlyPath,
                         emptyText: text.pathNoDifference,
                         highlighted: true)
                DisclosureGroup(text.pathTerminal) {
                    pathList(text.pathTerminal, entries: inspector.report.terminalPath, showsTitle: false)
                }
                DisclosureGroup(text.pathGui) {
                    pathList(text.pathGui, entries: inspector.report.guiPath, showsTitle: false)
                }
            }
        }
    }

    private func pathList(_ title: String,
                          entries: [String],
                          emptyText: String? = nil,
                          highlighted: Bool = false,
                          showsTitle: Bool = true) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            if showsTitle {
                Text(title).font(SettingsTypography.body.weight(.medium))
            }
            if entries.isEmpty {
                Text(emptyText ?? "—")
                    .font(SettingsTypography.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(entries, id: \.self) { entry in
                    Text(abbreviate(entry))
                        .font(.system(.callout, design: .monospaced))
                        .foregroundStyle(highlighted ? Color.orange : Color.secondary)
                        .textSelection(.enabled)
                        .fixedSize(horizontal: false, vertical: true)
                        .help(entry)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Caches

    private var cachesSection: some View {
        section(text.cachesTitle, systemImage: "internaldrive", note: text.cachesNote) {
            VStack(alignment: .leading, spacing: 3) {
                if inspector.report.caches.isEmpty {
                    Text(text.cachesEmpty)
                        .font(SettingsTypography.caption)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(inspector.report.caches) { cache in
                        HStack(spacing: 8) {
                            Text(abbreviate(cache.path))
                                .font(.system(.callout, design: .monospaced))
                                .textSelection(.enabled)
                                .fixedSize(horizontal: false, vertical: true)
                                .help(cache.path)
                            Spacer(minLength: 8)
                            Text(ByteCountFormatter.string(fromByteCount: cache.size, countStyle: .file))
                                .font(SettingsTypography.caption)
                                .monospacedDigit()
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Shared

    private func section<Content: View>(_ title: String,
                                        systemImage: String,
                                        note: String,
                                        @ViewBuilder content: () -> Content) -> some View {
        SettingsSection(title: title, systemImage: systemImage) {
            SettingsExplanation(note)
            content()
        }
    }

    private func abbreviate(_ path: String) -> String {
        let home = NSHomeDirectory()
        return path.hasPrefix(home + "/") ? "~" + path.dropFirst(home.count) : path
    }

    private func copy(_ value: String, target: String) {
        copyFeedback.copy(value, target: target) { value in
            NSPasteboard.general.clearContents()
            return NSPasteboard.general.setString(value, forType: .string)
        }
    }
}
