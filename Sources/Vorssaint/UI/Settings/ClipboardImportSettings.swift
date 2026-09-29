// SPDX-License-Identifier: GPL-3.0-or-later
import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct ClipboardImportSettings: View {
    @ObservedObject private var l10n = L10n.shared
    @ObservedObject private var service = ClipboardHistoryService.shared
    @State private var snapshot: ClipboardImportSnapshot?
    @State private var sourceURL: URL?
    @State private var selected = Set<UUID>()
    @State private var showingPreview = false
    @State private var busy = false
    @State private var message: String?
    @State private var failed = false
    @State private var request = UUID()
    @State private var importToken: UUID?
    @State private var openPanel: NSOpenPanel?

    private var text: ClipboardImportStrings { .text(l10n.language) }

    var body: some View {
        SettingsSection(title: text.title, systemImage: "square.and.arrow.down") {
            Button(action: chooseFile) {
                Label(text.button, systemImage: "square.and.arrow.down")
            }
            .disabled(busy || showingPreview || service.isImporting)
            SettingsInfo(text: text.caption, systemImage: "doc.on.doc")
            if busy && !showingPreview {
                ProgressView(text.busy).controlSize(.small)
                Button(text.cancel, action: cancel)
            }
            if let message {
                Text(message).font(SettingsTypography.caption)
                    .foregroundStyle(failed ? Color.orange : Color.secondary)
            }
        }
        .sheet(isPresented: $showingPreview, onDismiss: cancel) { preview }
        .onDisappear(perform: cancel)
        .onChange(of: l10n.language) { _, _ in message = nil }
    }

    private var preview: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label(text.previewTitle, systemImage: "checklist").font(SettingsTypography.sectionTitle)
            if let snapshot {
                Text(text.sourceLabel + ": " + snapshot.sourceName).font(SettingsTypography.caption).textSelection(.enabled)
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        ForEach(snapshot.entries) { entry in
                            Toggle(isOn: Binding(
                                get: { selected.contains(entry.id) },
                                set: { if $0 { selected.insert(entry.id) } else { selected.remove(entry.id) } }
                            )) {
                                HStack(alignment: .top, spacing: 8) {
                                    if entry.isPinned { Image(systemName: "pin.fill").accessibilityLabel(FeatureStrings.clipboard(l10n.language).pinned) }
                                    Text(summary(entry)).font(SettingsTypography.caption).lineLimit(3)
                                }
                            }
                            .toggleStyle(.checkbox)
                            .disabled(busy)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(2)
                }.frame(maxHeight: 300)
                Button { selected = Set(snapshot.entries.map(\.id)) } label: {
                    Label(text.selectAll, systemImage: "checkmark.circle")
                }
                .disabled(busy)
            }
            SettingsInfo(text: text.caption, systemImage: "doc.on.doc")
            if busy { ProgressView(text.busy).controlSize(.small) }
            if let message, failed { Text(message).font(SettingsTypography.caption).foregroundStyle(.orange) }
            HStack {
                Button(text.cancel, action: cancel).keyboardShortcut(.cancelAction)
                Spacer()
                Button(action: importSelected) {
                    Label(text.importSelected, systemImage: "square.and.arrow.down")
                }
                .settingsAction(.primary)
                .keyboardShortcut(.defaultAction).disabled(busy || selected.isEmpty)
            }
        }
        .settingsAction(.secondary)
        .padding(22)
        .frame(width: 520)
    }

    private func summary(_ entry: ClipboardHistoryEntry) -> String {
        switch entry.kind {
        case .text: return String(entry.text.prefix(180))
        case .image: return text.imageLabel + " " + entry.imageDimensionsLabel
        case .files: return String(format: text.filesFormat, entry.filePaths.count) + "\n" + entry.fileNames.prefix(3).joined(separator: " · ")
        }
    }

    private func chooseFile() {
        message = nil
        failed = false
        busy = true
        request = UUID()
        let token = request
        service.hideHistoryWindow()
        let panel = NSOpenPanel()
        panel.title = text.chooseFile
        panel.allowedContentTypes = [.json, .propertyList]
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        openPanel = panel
        panel.begin { response in
            guard request == token else { return }
            openPanel = nil
            guard response == .OK, let url = panel.url else { cancel(); return }
            load(url, token: token)
        }
    }

    private func chooseImages(for source: URL, token: UUID) {
        let panel = NSOpenPanel()
        panel.title = text.chooseImages
        panel.message = text.imagesCaption
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = false
        openPanel = panel
        panel.begin { response in
            guard request == token else { return }
            openPanel = nil
            guard response == .OK, let directory = panel.url else { cancel(); return }
            load(source, imageDirectory: directory, token: token)
        }
    }

    private func load(_ url: URL, imageDirectory: URL? = nil, token: UUID) {
        DispatchQueue.global(qos: .userInitiated).async {
            let access = url.startAccessingSecurityScopedResource()
            let imageAccess = imageDirectory?.startAccessingSecurityScopedResource() ?? false
            let result = Result {
                guard let directory = PrivateFileStore.containerURL else { throw ClipboardImportError.unavailable }
                try ClipboardImportSupport.validateSource(url,
                    destination: directory.appendingPathComponent("ClipboardHistory.json"))
                return try ClipboardImportSupport.read(url, imageDirectory: imageDirectory)
            }
            if access { url.stopAccessingSecurityScopedResource() }
            if imageAccess { imageDirectory?.stopAccessingSecurityScopedResource() }
            DispatchQueue.main.async {
                guard request == token else { return }
                switch result {
                case let .success(loaded):
                    busy = false
                    snapshot = loaded
                    sourceURL = url
                    selected = Set(loaded.entries.map(\.id))
                    showingPreview = true
                case .failure(ClipboardImportError.imageDirectoryRequired):
                    chooseImages(for: url, token: token)
                case let .failure(error):
                    busy = false
                    report(error)
                }
            }
        }
    }

    private func importSelected() {
        guard !busy, let snapshot, let sourceURL else { return }
        busy = true
        message = nil
        let token = request
        importToken = service.importEntries(snapshot.entries.filter { selected.contains($0.id) },
                                            images: snapshot.images, sourceURL: sourceURL) { result in
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
    }

    private func report(_ error: Error) {
        failed = true
        switch error {
        case ClipboardImportError.invalidDocument: message = text.invalidDocument
        case ClipboardImportError.tooLarge: message = text.tooLarge
        case ClipboardImportError.missingImage: message = text.missingImage
        case ClipboardImportError.capacityExceeded: message = text.capacityExceeded
        case ClipboardImportError.emptySelection: message = text.emptySelection
        case ClipboardImportError.sameDestination: message = text.currentFile
        case ClipboardImportError.saveFailed: message = text.saveFailed
        case ClipboardImportError.changed: message = text.changed
        case ClipboardImportError.unavailable: message = text.unavailable
        default: message = text.readFailed
        }
    }
}
