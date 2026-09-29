// SPDX-License-Identifier: GPL-3.0-or-later
import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct ScratchpadImportSettings: View {
    @ObservedObject private var l10n = L10n.shared
    @ObservedObject private var service = ScratchpadService.shared
    @State private var snapshot: ScratchpadImportSnapshot?
    @State private var sourceURL: URL?
    @State private var targetDocument: ScratchpadDocument?
    @State private var selected = Set<UUID>()
    @State private var showingPreview = false
    @State private var busy = false
    @State private var replaceOnlyEmpty = false
    @State private var message: String?
    @State private var failed = false
    @State private var request = UUID()
    @State private var openPanel: NSOpenPanel?
    @State private var ownsModalInteraction = false

    private var text: ScratchpadImportStrings { .text(l10n.language) }

    var body: some View {
        SettingsSection(text.title) {
            Button(text.button, action: chooseFile)
                .disabled(busy || showingPreview)
            SettingsExplanation(text.caption)
            if busy {
                HStack {
                    ProgressView(text.busy).controlSize(.small)
                    Button(text.cancel) {
                        request = UUID()
                        openPanel?.cancel(nil)
                        openPanel = nil
                        finish()
                    }
                }
            }
            if let message {
                Text(message)
                    .font(SettingsTypography.caption)
                    .foregroundStyle(failed ? Color.orange : Color.secondary)
            }
        }
        .sheet(isPresented: $showingPreview, onDismiss: finish) {
            preview
        }
        .onDisappear {
            request = UUID()
            openPanel?.cancel(nil)
            finish()
        }
        .onChange(of: service.pads) { _, _ in
            if showingPreview { refreshTargetDocument() }
        }
        .onChange(of: selected) { _, _ in clearFailure() }
        .onChange(of: replaceOnlyEmpty) { _, _ in clearFailure() }
        .onChange(of: l10n.language) { _, _ in message = nil }
    }

    private var preview: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(text.previewTitle).font(.headline)
            if let snapshot {
                Text(text.sourceLabel + ": " + snapshot.sourceName)
                    .font(SettingsTypography.caption)
                    .textSelection(.enabled)
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(snapshot.pads) { pad in
                            Toggle(isOn: Binding(
                                get: { selected.contains(pad.id) },
                                set: { if $0 { selected.insert(pad.id) } else { selected.remove(pad.id) } }
                            )) {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(pad.name).fontWeight(.medium)
                                    Text(String(pad.text.prefix(180)))
                                        .font(SettingsTypography.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(3)
                                }
                            }
                            .toggleStyle(.checkbox)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(2)
                }
                .frame(maxHeight: 300)
                Button(text.selectAll) { selected = Set(snapshot.pads.map(\.id)) }
            }
            capacityStatus
            Toggle(text.replaceOnlyEmpty, isOn: $replaceOnlyEmpty)
                .toggleStyle(.checkbox)
                .disabled(!canReplaceOnlyEmpty)
            if !canReplaceOnlyEmpty {
                SettingsExplanation(text.replaceUnavailable)
            }
            SettingsExplanation(text.caption)
            if let message, failed {
                Text(message).font(SettingsTypography.caption).foregroundStyle(.orange)
            }
            HStack {
                Button(text.cancel) { showingPreview = false }
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button(text.importSelected, action: importSelected)
                    .keyboardShortcut(.defaultAction)
                    .disabled(!canImport)
            }
        }
        .padding(22)
        .frame(width: 460)
    }

    private var selectedPads: [ScratchpadPad] {
        snapshot?.pads.filter { selected.contains($0.id) } ?? []
    }

    private var selectedCount: Int { Set(selectedPads.map(\.id)).count }

    private var canReplaceOnlyEmpty: Bool {
        targetDocument.map { ScratchpadImportSupport.canReplaceOnlyEmpty(in: $0) } ?? false
    }

    private var availableCount: Int {
        targetDocument.map {
            ScratchpadImportSupport.availableCount(in: $0, replaceOnlyEmpty: replaceOnlyEmpty)
        } ?? 0
    }

    private var canImport: Bool {
        targetDocument != nil && selectedCount > 0 && selectedCount <= availableCount
    }

    @ViewBuilder
    private var capacityStatus: some View {
        if let targetDocument {
            Text(String(format: text.capacityFormat, targetDocument.pads.count,
                        availableCount, selectedCount))
                .font(SettingsTypography.caption)
                .fixedSize(horizontal: false, vertical: true)
            if selectedCount > availableCount {
                Text(String(format: text.reduceSelectionFormat, selectedCount - availableCount))
                    .font(SettingsTypography.caption)
                    .foregroundStyle(.orange)
                    .fixedSize(horizontal: false, vertical: true)
            }
        } else {
            Text(text.unavailable)
                .font(SettingsTypography.caption)
                .foregroundStyle(.orange)
        }
    }

    private func refreshTargetDocument() {
        do {
            targetDocument = try service.importPreviewDocument()
            if !canReplaceOnlyEmpty { replaceOnlyEmpty = false }
        } catch {
            targetDocument = nil
            replaceOnlyEmpty = false
        }
    }

    private func clearFailure() {
        guard showingPreview, failed else { return }
        message = nil
        failed = false
    }

    private func chooseFile() {
        guard service.canChangePresentation, AppFeature.scratchpad.isAvailable else {
            report(ScratchpadImportActionError.unavailable)
            return
        }
        message = nil
        failed = false
        busy = true
        service.setModalInteractionActive(true)
        ownsModalInteraction = true
        request = UUID()
        let token = request
        let panel = NSOpenPanel()
        panel.title = text.chooseFile
        panel.allowedContentTypes = [.json, .plainText]
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        openPanel = panel
        panel.begin { response in
            guard request == token else { return }
            openPanel = nil
            guard response == .OK, let url = panel.url else { finish(); return }
            DispatchQueue.global(qos: .userInitiated).async {
                let access = url.startAccessingSecurityScopedResource()
                let result = Result {
                    guard let directory = PrivateFileStore.containerURL else {
                        throw ScratchpadImportActionError.unavailable
                    }
                    try ScratchpadImportSupport.validateSource(url,
                        destination: directory.appendingPathComponent("Scratchpad.json"))
                    return try ScratchpadImportSupport.read(url)
                }
                if access { url.stopAccessingSecurityScopedResource() }
                DispatchQueue.main.async {
                    guard request == token else { return }
                    busy = false
                    switch result {
                    case .success(let loaded):
                        replaceOnlyEmpty = false
                        snapshot = loaded
                        sourceURL = url
                        selected = Set(loaded.pads.map(\.id))
                        refreshTargetDocument()
                        showingPreview = true
                    case .failure(let error):
                        report(error)
                        finish()
                    }
                }
            }
        }
    }

    private func importSelected() {
        guard showingPreview, snapshot != nil, let sourceURL else { return }
        refreshTargetDocument()
        guard canImport else { return }
        do {
            let count = try service.importPads(selectedPads, sourceURL: sourceURL, replaceOnlyEmpty: replaceOnlyEmpty)
            failed = false
            message = String(format: text.successFormat, count)
            showingPreview = false
        } catch { report(error) }
    }

    private func finish() {
        busy = false
        snapshot = nil
        sourceURL = nil
        targetDocument = nil
        selected.removeAll()
        replaceOnlyEmpty = false
        if ownsModalInteraction {
            ownsModalInteraction = false
            service.setModalInteractionActive(false)
        }
    }

    private func report(_ error: Error) {
        failed = true
        switch error {
        case ScratchpadImportActionError.unavailable: message = text.unavailable
        case ScratchpadImportActionError.saveFailed: message = text.saveFailed
        case ScratchpadImportError.sameDestination: message = text.currentFile
        case ScratchpadImportError.tooLarge: message = text.tooLarge
        case ScratchpadImportError.capacityExceeded: message = text.capacityExceeded
        case ScratchpadImportError.invalidSelection: message = text.emptySelection
        case ScratchpadImportError.invalidDocument,
             ScratchpadImportError.invalidUTF8,
             ScratchpadImportError.unsupportedFile: message = text.invalidDocument
        default: message = text.readFailed
        }
    }
}
