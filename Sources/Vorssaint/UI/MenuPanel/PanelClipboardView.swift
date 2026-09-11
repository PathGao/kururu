// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import SwiftUI

struct PanelClipboardView: View {
    @ObservedObject private var l10n = L10n.shared
    @ObservedObject private var history = ClipboardHistoryService.shared
    @AppStorage(DefaultsKey.clipboardHistoryEnabled) private var enabled = false
    @AppStorage(DefaultsKey.clipboardHistoryShortcutEnabled) private var shortcutEnabled = true
    @State private var query = ""
    @State private var copiedID: UUID?
    @State private var copyFailed = false

    var onClose: () -> Void

    private var text: ClipboardFeatureStrings {
        FeatureStrings.clipboard(l10n.language)
    }

    private var filteredEntries: [ClipboardHistoryEntry] {
        history.filteredEntries(matching: query)
    }

    private var canReorderEntries: Bool {
        query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            header
            controls
            if copyFailed {
                Text(ClipboardActionStrings.copyFailed).font(.caption).foregroundStyle(.orange)
            }
            entriesList
        }
        .onAppear { PanelInteractionState.shared.viewKeepsPopoverOpen = true }
        .onDisappear { PanelInteractionState.shared.viewKeepsPopoverOpen = false }
    }

    private var header: some View {
        HStack(spacing: 8) {
            Label(AppFeature.clipboardHistory.name(l10n.s, language: l10n.language), systemImage: "doc.on.clipboard")
                .font(.system(size: 12, weight: .semibold))
            Spacer()
            Button(action: onClose) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .frame(width: 22, height: 22)
            }
            .buttonStyle(.plain)
            .help(l10n.s.uninstallerCancel)
        }
    }

    private var controls: some View {
        VStack(alignment: .leading, spacing: 7) {
            Toggle(text.enable, isOn: $enabled)
                .toggleStyle(.checkbox)
                .font(PanelTypography.title)
                .onChange(of: enabled) { _, _ in
                    ClipboardHistoryService.shared.syncWithPreferences()
                }
            Text(enabled ? text.caption : text.disabled)
                .font(PanelTypography.meta)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            if enabled, shortcutEnabled {
                Text("\(text.shortcut): \(shortcut.displayString)")
                    .font(PanelTypography.meta)
                    .foregroundStyle(.tertiary)
            }
            HStack(spacing: 6) {
                TextField(text.search, text: $query)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 11))
                    .disabled(history.entries.isEmpty)
                ClipboardClearRecentButton()
                    .labelStyle(.iconOnly)
                    .buttonStyle(.bordered)
                    .controlSize(.mini)
                Button {
                    history.showHistoryWindow()
                } label: {
                    Image(systemName: "arrow.up.forward.app")
                        .font(.system(size: 11, weight: .semibold))
                        .frame(width: 24, height: 22)
                }
                .buttonStyle(.bordered)
                .controlSize(.mini)
                .help(text.shortcut)
            }
        }
        .panelCard()
    }

    @ViewBuilder
    private var entriesList: some View {
        if history.entries.isEmpty {
            emptyState(text.empty)
        } else if filteredEntries.isEmpty {
            emptyState(text.noResults)
        } else {
            ScrollView {
                // Lazy: a large history would otherwise build every row, and
                // decode every image thumbnail, each time the panel opens.
                LazyVStack(alignment: .leading, spacing: 7) {
                    ForEach(filteredEntries) { entry in
                        entryRow(entry)
                    }
                }
            }
            .frame(maxHeight: 260)
        }
    }

    private func emptyState(_ message: String) -> some View {
        Text(message)
            .font(PanelTypography.meta)
            .foregroundStyle(.tertiary)
            .frame(maxWidth: .infinity)
            .frame(height: 72)
            .panelCard()
    }

    private var shortcut: GlobalShortcut {
        GlobalShortcut.saved(for: DefaultsKey.clipboardHistoryShortcut,
                             fallback: .clipboardDefault)
    }

    @ViewBuilder
    private func entryPreview(_ entry: ClipboardHistoryEntry) -> some View {
        switch entry.kind {
        case .text:
            // Deliberately not selectable: clicking a selectable Text swaps in
            // the selection renderer, which lays the whole preview out and
            // ignores the line limit, so a long entry paints over the rows
            // below it. The history window shows the full, selectable text.
            Text(entry.preview)
                .font(PanelTypography.meta)
                .lineLimit(3)
                .truncationMode(.tail)
                .frame(maxWidth: .infinity, alignment: .leading)
        case .image:
            HStack(alignment: .center, spacing: 7) {
                if let name = entry.imageFile,
                   let thumbnail = ClipboardImageStore.thumbnail(named: name) {
                    Image(nsImage: thumbnail)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: 110, maxHeight: 40)
                        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                }
                Text("\(text.imageEntryLabel) · \(entry.imageDimensionsLabel)")
                    .font(PanelTypography.meta)
                    .foregroundStyle(.secondary)
            }
        case .files:
            if entry.filePaths.count == 1,
               let path = entry.filePaths.first,
               ClipboardImageStore.isImageFile(atPath: path),
               let thumbnail = ClipboardImageStore.fileThumbnail(atPath: path) {
                HStack(alignment: .center, spacing: 7) {
                    Image(nsImage: thumbnail)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: 110, maxHeight: 40)
                        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                    Text(entry.fileNames.first ?? entry.preview)
                        .font(PanelTypography.meta)
                        .lineLimit(2)
                        .truncationMode(.middle)
                }
                .help(path)
            } else {
                HStack(alignment: .center, spacing: 7) {
                    Image(systemName: "folder")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.secondary)
                    Text(entry.filePaths.count == 1
                         ? (entry.fileNames.first ?? entry.preview)
                         : String(format: text.fileCountFormat, entry.filePaths.count))
                        .font(PanelTypography.meta)
                        .lineLimit(2)
                        .truncationMode(.middle)
                }
                .help(entry.filePaths.joined(separator: "\n"))
            }
        }
    }

    private func entryRow(_ entry: ClipboardHistoryEntry) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            if entry.isPinned {
                Label(text.pinned, systemImage: "pin.fill")
                    .font(PanelTypography.meta)
                    .foregroundStyle(Color.accentColor)
            }
            entryPreview(entry)
            HStack(spacing: 6) {
                Button {
                    // The tick means "it is on the clipboard", so it waits for
                    // the write instead of announcing one still queued behind
                    // a stalled pasteboard provider.
                    copiedID = nil
                    copyFailed = false
                    history.copy(entry) { copied in
                        copyFailed = !copied
                        if copied { copiedID = entry.id }
                    }
                } label: {
                    Label(copiedID == entry.id ? text.copied : ClipboardActionStrings.copyOriginal(entry.kind),
                          systemImage: copiedID == entry.id ? "checkmark" : "doc.on.doc")
                        .font(PanelTypography.meta)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.mini)
                Menu {
                    Button(entry.isPinned ? text.unpin : text.pin) {
                        history.togglePin(entry)
                    }
                    Button(text.moveUp) { history.move(entry, .up) }
                        .disabled(!canReorderEntries || !history.canMove(entry, .up))
                    Button(text.moveDown) { history.move(entry, .down) }
                        .disabled(!canReorderEntries || !history.canMove(entry, .down))
                    Divider()
                    Button(text.delete, role: .destructive) { history.remove(entry) }
                } label: {
                    Label(text.moreActions, systemImage: "ellipsis")
                        .labelStyle(.iconOnly)
                        .font(PanelTypography.meta)
                }
                .menuStyle(.borderlessButton)
                .menuIndicator(.hidden)
                .fixedSize()
                .help(text.moreActions)
                .accessibilityLabel(text.moreActions)
                Spacer()
                Text(entry.copiedAt, style: .time)
                    .font(PanelTypography.meta)
                    .foregroundStyle(.tertiary)
            }
        }
        .panelCard()
    }
}
