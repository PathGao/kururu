// SPDX-License-Identifier: GPL-3.0-or-later
import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct ShelfImportSettings: View {
    private struct DirectoryChoice: Equatable {
        var directory: URL?
        var copyFiles: Bool?
    }
    @ObservedObject private var l10n = L10n.shared
    @ObservedObject private var service = ShelfService.shared
    @State private var snapshot: ShelfImportSnapshot?
    @State private var sourceURL: URL?
    @State private var selected = Set<UUID>()
    @State private var expanded = Set<UUID>()
    @State private var choices: [String: DirectoryChoice] = [:]
    @State private var showingPreview = false
    @State private var busy = false
    @State private var message: String?
    @State private var failed = false
    @State private var errorPath: String?
    @State private var request = UUID()
    @State private var importToken: UUID?
    @State private var openPanel: NSOpenPanel?

    private var text: ShelfImportStrings { .text(l10n.language) }
    private var selectedItems: [ShelfPersistedItem] {
        snapshot?.items.filter { selected.contains($0.id) } ?? []
    }
    private func paths(_ items: [ShelfPersistedItem]) -> [String] {
        items.flatMap { item in
            item.kind == .batch ? paths(item.children ?? []) : (item.path.map { [$0] } ?? [])
        }
    }
    private func contains(_ root: String, _ path: String) -> Bool {
        (path as NSString).pathComponents.starts(with: (root as NSString).pathComponents)
    }
    private var roots: [String] {
        let parents = Set(paths(selectedItems).map { ($0 as NSString).deletingLastPathComponent })
        return parents.filter { candidate in
            !parents.contains { $0 != candidate && contains($0, candidate) }
        }.sorted()
    }
    private var ready: Bool {
        !selected.isEmpty && roots.allSatisfy { choices[$0]?.directory != nil && choices[$0]?.copyFiles != nil }
    }
    private func leafCount(_ items: [ShelfPersistedItem]) -> Int {
        items.reduce(0) { $0 + ($1.kind == .batch ? leafCount($1.children ?? []) : 1) }
    }
    private func descendants(_ item: ShelfPersistedItem, depth: Int = 0) -> [(item: ShelfPersistedItem, depth: Int)] {
        (item.children ?? []).flatMap { [($0, depth)] + descendants($0, depth: depth + 1) }
    }

    var body: some View {
        SettingsSection(text.title) {
            Button(text.button, action: chooseFile).disabled(busy || showingPreview || service.isImporting)
            SettingsExplanation(text.caption)
            if busy && !showingPreview {
                ProgressView(text.busy).controlSize(.small)
                Button(text.cancel, action: cancel)
            }
            if let message {
                Text(message).font(SettingsTypography.caption).foregroundStyle(failed ? Color.orange : Color.secondary)
                if let errorPath { Text(errorPath).font(SettingsTypography.caption).textSelection(.enabled) }
            }
        }
        .sheet(isPresented: $showingPreview, onDismiss: cancel) { preview }
        .onDisappear(perform: cancel)
        .onChange(of: l10n.language) { _, _ in message = nil }
        .onChange(of: selected) { _, _ in clearPreviewFailure() }
        .onChange(of: choices) { _, _ in clearPreviewFailure() }
    }

    private var preview: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(text.preview).font(.headline)
            if let sourceURL { Text(sourceURL.path).font(SettingsTypography.caption).textSelection(.enabled) }
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    ForEach(snapshot?.items ?? [], id: \.id) { item in
                        Toggle(isOn: Binding(get: { selected.contains(item.id) }, set: {
                            if $0 { selected.insert(item.id) } else { selected.remove(item.id) }
                        })) { Text(summary(item)).font(SettingsTypography.caption).textSelection(.enabled) }
                        .toggleStyle(.checkbox)
                        if item.kind == .batch {
                            DisclosureGroup(isExpanded: Binding(get: { expanded.contains(item.id) }, set: {
                                if $0 { expanded.insert(item.id) } else { expanded.remove(item.id) }
                            })) {
                                ForEach(descendants(item), id: \.item.id) { row in
                                    Text(summary(row.item)).font(SettingsTypography.caption).textSelection(.enabled)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.leading, CGFloat(row.depth) * 12)
                                }
                            } label: { Text(text.groupDetails).font(SettingsTypography.caption).foregroundStyle(.secondary) }
                        }
                    }
                    Text(String(format: text.selectionFormat, selectedItems.count, leafCount(selectedItems)))
                        .font(SettingsTypography.caption).foregroundStyle(.secondary)
                    HStack {
                        Button(text.selectAll) { selected = Set(snapshot?.items.map(\.id) ?? []) }
                        Button(text.selectNone) { selected.removeAll() }
                    }
                    if !roots.isEmpty {
                        Text(text.filesWarning).font(SettingsTypography.caption).foregroundStyle(.orange)
                        ForEach(roots, id: \.self) { root in directoryRow(root) }
                    }
                }.frame(maxWidth: .infinity, alignment: .leading).padding(2).disabled(busy)
            }.frame(maxHeight: 480)
            if busy { ProgressView(text.busy).controlSize(.small) }
            if let message, failed {
                Text(message).font(SettingsTypography.caption).foregroundStyle(.orange)
                if let errorPath { Text(errorPath).font(SettingsTypography.caption).textSelection(.enabled) }
            }
            HStack {
                Button(text.cancel, action: cancel).keyboardShortcut(.cancelAction)
                Spacer()
                Button(text.importSelected, action: importSelected)
                    .keyboardShortcut(.defaultAction).disabled(busy || !ready || service.isImporting)
            }
        }.padding(22).frame(width: 600)
    }

    private func directoryRow(_ root: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(text.original + ": " + root).textSelection(.enabled)
            Text(String(format: text.filesFormat, paths(selectedItems).filter { contains(root, $0) }.count))
                .foregroundStyle(.secondary)
            Picker(text.mode, selection: Binding<Bool?>(get: { choices[root]?.copyFiles }, set: {
                choices[root, default: DirectoryChoice()].copyFiles = $0
            })) {
                Text(text.chooseMode).tag(Optional<Bool>.none)
                Text(text.reference).tag(Optional(false))
                Text(text.copy).tag(Optional(true))
            }
            Text(text.location + ": " + (choices[root]?.directory?.path ?? text.notSelected)).textSelection(.enabled)
            ViewThatFits(in: .horizontal) {
                HStack { directoryButtons(root) }
                VStack(alignment: .leading) { directoryButtons(root) }
            }
            if let copy = choices[root]?.copyFiles {
                Text(copy ? text.copyCaption : text.referenceCaption).foregroundStyle(.secondary)
            }
        }.font(SettingsTypography.caption).padding(10).frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
    }

    @ViewBuilder private func directoryButtons(_ root: String) -> some View {
        Button(text.useOriginal) { choices[root, default: DirectoryChoice()].directory = URL(fileURLWithPath: root) }
        Button(text.chooseDirectory) { chooseDirectory(root) }
    }

    private func summary(_ item: ShelfPersistedItem) -> String {
        let title = item.title.isEmpty ? (item.text ?? item.url ?? item.path ?? text.group) : item.title
        return String(title.prefix(180))
    }

    private func chooseFile() {
        message = nil
        errorPath = nil
        failed = false
        busy = true
        request = UUID()
        let token = request
        let panel = NSOpenPanel()
        panel.title = text.button
        panel.allowedContentTypes = [.json, .propertyList]
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        openPanel = panel
        panel.begin { response in
            guard request == token else { return }
            openPanel = nil
            guard response == .OK, let url = panel.url else { cancel(); return }
            DispatchQueue.global(qos: .userInitiated).async {
                let access = url.startAccessingSecurityScopedResource()
                let result = Result {
                    guard let directory = PrivateFileStore.containerURL else { throw ShelfImportError.invalidDocument }
                    return try ShelfImportAssets.read(source: url,
                        currentIndex: directory.appendingPathComponent("ShelfItems.json"),
                        legacy: url.pathExtension.lowercased() == "plist")
                }
                if access { url.stopAccessingSecurityScopedResource() }
                DispatchQueue.main.async {
                    guard request == token else { return }
                    busy = false
                    switch result {
                    case let .success(loaded):
                        snapshot = loaded
                        sourceURL = url
                        selected = Set(loaded.items.map(\.id))
                        showingPreview = true
                    case let .failure(error): report(error)
                    }
                }
            }
        }
    }

    private func chooseDirectory(_ root: String) {
        let token = request
        let panel = NSOpenPanel()
        panel.title = text.chooseDirectory
        panel.message = text.original + ": " + root
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = false
        panel.allowsMultipleSelection = false
        openPanel = panel
        panel.begin { response in
            guard request == token else { return }
            openPanel = nil
            guard response == .OK, let url = panel.url else { return }
            choices[root, default: DirectoryChoice()].directory = url
        }
    }

    private func importSelected() {
        guard !busy, ready, let sourceURL else { return }
        let mappings = roots.compactMap { root -> ShelfImportMapping? in
            guard let choice = choices[root], let directory = choice.directory, let copy = choice.copyFiles else { return nil }
            return ShelfImportMapping(originalDirectory: root, selectedDirectory: directory, copyFiles: copy)
        }
        busy = true
        message = nil
        errorPath = nil
        let token = request
        importToken = service.importItems(selectedItems, mappings: mappings, sourceURL: sourceURL) { result in
            guard request == token else { return }
            busy = false
            importToken = nil
            switch result {
            case let .success(count):
                failed = false
                message = String(format: text.successFormat, count)
                showingPreview = false
            case let .failure(error): report(error)
            }
        }
    }

    private func cancel() {
        request = UUID()
        openPanel?.cancel(nil)
        openPanel = nil
        if let importToken { service.cancelImport(importToken) }
        importToken = nil
        busy = false
        showingPreview = false
        snapshot = nil
        sourceURL = nil
        selected.removeAll()
        expanded.removeAll()
        choices.removeAll()
    }

    private func clearPreviewFailure() {
        guard showingPreview, failed, !busy else { return }
        message = nil
        errorPath = nil
        failed = false
    }

    private func report(_ error: Error) {
        failed = true
        let detail = ShelfImportStrings.errorMessage(l10n.language, error)
        message = detail.message
        errorPath = detail.path
    }
}
