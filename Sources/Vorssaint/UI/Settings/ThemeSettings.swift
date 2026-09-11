// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import SwiftUI
import UniformTypeIdentifiers

struct ThemeSettings: View {
    @ObservedObject private var preferences = ThemePreferences.shared
    @ObservedObject private var l10n = L10n.shared
    @State private var preview: ImportedTheme?
    @State private var errorMessage: String?
    @State private var isReading = false
    @State private var isChoosingFile = false
    @State private var filePanel: NSOpenPanel?
    @State private var themeLink = ""
    @State private var requestID = UUID()
    @State private var importTask: Task<Void, Never>?

    private var text: ThemeSettingsText { ThemeSettingsText(language: l10n.language) }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(text.title).font(.headline)
            Text(preferences.applied.map { $0.name.isEmpty ? text.imported : $0.name } ?? text.defaultName)
                .font(.callout)
                .foregroundStyle(.secondary)
            SettingsExplanation(text.scope)
            Link(text.browseButton, destination: URL(string: "https://vscodethemes.com/")!)
                .buttonStyle(.link)
                .foregroundStyle(Color(nsColor: .linkColor))
            HStack {
                TextField("", text: $themeLink, prompt: Text(text.linkPlaceholder))
                    .textFieldStyle(.roundedBorder)
                    .labelsHidden()
                    .accessibilityLabel(text.linkLabel)
                    .disabled(isReading || isChoosingFile)
                    .onSubmit { loadLink() }
                Button(text.previewTitle, action: loadLink)
                    .disabled(isReading || isChoosingFile || themeLink.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .fixedSize()
            }
            if isReading {
                HStack {
                    ProgressView().controlSize(.small)
                    Text(text.reading).font(SettingsTypography.caption)
                    Spacer()
                    Button(text.cancelLoading, action: cancelImport)
                }
            }
            HStack {
                Button(text.importButton, action: chooseFile).disabled(isReading || isChoosingFile)
                Spacer()
                Button(text.restoreButton) {
                    preferences.restoreDefault()
                    preview = nil
                    errorMessage = nil
                }
                .disabled(preferences.applied == nil || isReading || isChoosingFile)
            }
            if let errorMessage {
                Label(errorMessage, systemImage: "exclamationmark.triangle")
                    .font(SettingsTypography.caption)
                    .foregroundStyle(Color(nsColor: .labelColor))
                    .accessibilityLabel(errorMessage)
            }
            if let preview {
                Text(text.previewTitle).font(.headline)
                ThemePreviewCard(palette: preview, text: text)
                SettingsExplanation(text.previewCaption)
                HStack {
                    Button(text.cancelButton) { self.preview = nil; errorMessage = nil }
                    Spacer()
                    Button(text.applyButton) {
                        do {
                            try preferences.apply(preview)
                            self.preview = nil
                            errorMessage = nil
                        } catch {
                            errorMessage = text.message(for: (error as? ThemeImportError) ?? .unreadable)
                        }
                    }
                }
                .disabled(isReading)
            }
        }
        // Keep recovery controls independent of imported accent colors.
        .tint(.primary)
        .buttonStyle(.bordered)
        .onDisappear(perform: cancelImport)
    }

    private func cancelImport() {
        requestID = UUID()
        filePanel?.cancel(nil)
        filePanel = nil
        isChoosingFile = false
        importTask?.cancel()
        importTask = nil
        isReading = false
    }

    private func loadLink() {
        guard !isReading, !isChoosingFile, !themeLink.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        let id = UUID()
        requestID = id
        isReading = true
        errorMessage = nil
        let link = themeLink
        importTask = Task { @MainActor in
            do {
                let theme = try await ThemeLinkImportService.fetch(link)
                guard !Task.isCancelled, requestID == id else { return }
                preview = theme
            } catch is CancellationError {
            } catch {
                guard !Task.isCancelled, requestID == id else { return }
                errorMessage = text.message(for: error)
            }
            guard requestID == id else { return }
            isReading = false
            importTask = nil
        }
    }

    private func chooseFile() {
        guard !isReading, !isChoosingFile else { return }
        isChoosingFile = true
        let id = UUID()
        requestID = id
        let panel = NSOpenPanel()
        filePanel = panel
        panel.allowedContentTypes = [.json, UTType(filenameExtension: "jsonc") ?? .plainText]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.prompt = text.previewTitle
        let completion: (NSApplication.ModalResponse) -> Void = { response in
            guard requestID == id else { return }
            isChoosingFile = false
            filePanel = nil
            guard response == .OK, let url = panel.url else { return }
            isReading = true
            errorMessage = nil
            DispatchQueue.global(qos: .userInitiated).async {
                let result = Result { try ThemeImportSupport.read(url) }
                DispatchQueue.main.async {
                    guard requestID == id else { return }
                    isReading = false
                    switch result {
                    case .success(let theme): preview = theme
                    case .failure(let failure): errorMessage = text.message(for: failure)
                    }
                }
            }
        }
        if let window = NSApp.keyWindow {
            panel.beginSheetModal(for: window, completionHandler: completion)
        } else {
            panel.begin(completionHandler: completion)
        }
    }
}

private struct ThemePreviewCard: View {
    let palette: ImportedTheme
    let text: ThemeSettingsText

    private func color(_ role: ThemeColorRole, fallback: NSColor) -> Color {
        Theme.color(role, in: palette) ?? Color(nsColor: fallback)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(palette.name.isEmpty ? text.imported : palette.name)
                .font(.headline)
                .foregroundStyle(color(.primaryText, fallback: .labelColor))
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(text.settingsSample).font(.subheadline)
                    Text(text.secondarySample)
                        .font(SettingsTypography.caption)
                        .foregroundStyle(color(.secondaryText, fallback: .secondaryLabelColor))
                    RoundedRectangle(cornerRadius: 3)
                        .fill(color(.accent, fallback: .controlAccentColor))
                        .frame(width: 60, height: 6)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 6) {
                    Text("CPU  24%")
                        .font(PanelTypography.metric)
                    Text(text.normalSample)
                        .font(SettingsTypography.caption)
                        .foregroundStyle(color(.secondaryText, fallback: .secondaryLabelColor))
                }
            }
            .foregroundStyle(color(.primaryText, fallback: .labelColor))
            .padding(12)
            .background(color(.card, fallback: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(color(.border, fallback: .separatorColor), lineWidth: 1))
            CPUCoreMatrix(usage: [0, 0.45, 1, nil], palette: palette,
                          coreGroups: [CPUCoreGroup(name: "CPU", indices: [0, 1, 2, 3])])
            MonitorTrendPlot(samples: [
                .init(id: 0, time: 0, value: 15, segment: 0),
                .init(id: 1, time: 15, value: 55, segment: 0),
                .init(id: 2, time: 30, value: 24, segment: 0),
                .init(id: 3, time: 50, value: 70, segment: 1),
            ], now: 60, window: 1, ymax: 100, palette: palette)
            .frame(height: 90)
            .padding(12)
            .background(color(.card, fallback: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(color(.border, fallback: .separatorColor), lineWidth: 1))
        }
        .padding(12)
        .background(color(.background, fallback: .windowBackgroundColor), in: RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .contain)
    }
}
