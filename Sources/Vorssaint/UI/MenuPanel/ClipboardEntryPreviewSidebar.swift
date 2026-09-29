// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import SwiftUI

/// On-demand inspector for the selected clipboard entry. It keeps the full
/// content selectable and editable without permanently taking space from the
/// history list.
struct ClipboardEntryPreviewSidebar: View {
    @ObservedObject private var l10n = L10n.shared
    var text: ClipboardFeatureStrings
    var entry: ClipboardHistoryEntry?
    @Binding var isEditing: Bool
    var onClose: () -> Void
    var isEntryCurrent: (UUID) -> Bool
    @State private var draft = ""
    @State private var editSaveFailed = false
    @State private var isSaving = false
    @State private var editingSession = UUID()
    @State private var editingEntryID: UUID?
    @FocusState private var editorFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            sidebarHeader
            Divider()
            if let entry {
                if editingEntryID == entry.id {
                    textEditor(entry)
                    if editSaveFailed { editFailureMessage }
                } else if entry.kind == .text {
                    ClipboardJSONPreview(original: entry.text) { copyDerivedText($0, from: entry) }
                        .id(entry.id)
                } else if let source = imageSource(entry) {
                    ClipboardImagePreview(url: source.url, thumbnail: source.thumbnail,
                                          dimensions: source.dimensions) { copyDerivedText($0, from: entry) }
                        .id(entry.id)
                } else {
                    contentScrollView(entry)
                }
                Divider()
                sidebarFooter(entry)
            } else {
                emptyState
            }
        }
        .onChange(of: entry?.id) { _, newID in
            if editingEntryID != nil, editingEntryID != newID {
                cancelEditing()
            }
        }
        .onChange(of: draft) { _, _ in clearEditFailure() }
        .onDisappear { cancelEditing() }
    }

    private var sidebarHeader: some View {
        HStack(spacing: 8) {
            Label(text.previewLabel, systemImage: "doc.text.magnifyingglass")
                .font(.system(size: 11.5, weight: .semibold))
                .foregroundStyle(.secondary)
            Spacer()
            Button {
                cancelEditing()
                onClose()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 9.5, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 20, height: 20)
            }
            .buttonStyle(.plain)
            .help(l10n.s.menuClose)
            .accessibilityLabel(l10n.s.menuClose)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    private func contentScrollView(_ entry: ClipboardHistoryEntry) -> some View {
        ScrollView {
            previewContent(entry)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .frame(maxHeight: .infinity)
    }

    private func textEditor(_ entry: ClipboardHistoryEntry) -> some View {
        TextEditor(text: $draft)
            .font(.system(.callout))
            .lineSpacing(2)
            .scrollContentBackground(.hidden)
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.primary.opacity(0.045))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(Color.accentColor.opacity(0.45), lineWidth: 1)
            )
            .padding(12)
            .focused($editorFocused)
            .onExitCommand { cancelEditing() }
            .accessibilityLabel(text.edit)
    }

    @ViewBuilder
    private func previewContent(_ entry: ClipboardHistoryEntry) -> some View {
        switch entry.kind {
        case .text:
            // Standard text selection lets someone copy only the fragment
            // they need; the window monitor leaves ⌘C with this view.
            Text(entry.text)
                .font(.system(.callout))
                .textSelection(.enabled)
                .lineSpacing(2)
                .frame(maxWidth: .infinity, alignment: .topLeading)
        case .image:
            EmptyView()
        case .files:
            filesPreview(entry)
        }
    }

    private func imageSource(_ entry: ClipboardHistoryEntry) -> (url: URL?, thumbnail: NSImage?, dimensions: String)? {
        if entry.kind == .image {
            let name = entry.imageFile.flatMap { name in
                !name.isEmpty && name != "." && name != ".."
                    && (name as NSString).lastPathComponent == name && !name.contains("\\") ? name : nil
            }
            return (name.flatMap { ClipboardImageStore.directory?.appendingPathComponent($0) },
                    name.flatMap { ClipboardImageStore.thumbnail(named: $0) },
                    "\(text.imageEntryLabel) · \(entry.imageDimensionsLabel)")
        }
        if entry.kind == .files, entry.filePaths.count == 1,
           let path = entry.filePaths.first, ClipboardImageStore.isImageFile(atPath: path) {
            return (URL(fileURLWithPath: path), ClipboardImageStore.fileThumbnail(atPath: path),
                    (path as NSString).lastPathComponent)
        }
        return nil
    }

    private func copyDerivedText(_ value: String, from entry: ClipboardHistoryEntry) {
        guard isEntryCurrent(entry.id), !value.isEmpty else { return }
        let textEntry = ClipboardHistoryEntry(id: entry.id, text: value,
                                             copiedAt: entry.copiedAt, pinnedAt: entry.pinnedAt)
        ClipboardHistoryService.shared.copyOnlyQuickEntry(textEntry)
    }

    @ViewBuilder
    private func filesPreview(_ entry: ClipboardHistoryEntry) -> some View {
        if entry.filePaths.count == 1, let path = entry.filePaths.first {
            singleFilePreview(path)
        } else {
            multipleFilesPreview(entry)
        }
    }

    @ViewBuilder
    private func singleFilePreview(_ path: String) -> some View {
        let isImage = ClipboardImageStore.isImageFile(atPath: path)
        let thumbnail = ClipboardImageStore.fileThumbnail(atPath: path)
        let fileName = (path as NSString).lastPathComponent

        VStack(alignment: .leading, spacing: 10) {
            if isImage, let thumbnail {
                Image(nsImage: thumbnail)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                let dim = ClipboardImageStore.imageDimensionsLabel(atPath: path)
                let size = ClipboardImageStore.fileSizeString(atPath: path)
                let parts = [text.imageEntryLabel, dim, size].compactMap { $0 }
                Text(parts.joined(separator: " · "))
                    .font(.system(size: 10.5))
                    .foregroundStyle(.secondary)
            } else {
                HStack(spacing: 8) {
                    Image(nsImage: NSWorkspace.shared.icon(forFile: path))
                        .resizable()
                        .frame(width: 32, height: 32)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(fileName)
                            .font(.system(.callout, weight: .medium))
                            .lineLimit(2)
                        if let size = ClipboardImageStore.fileSizeString(atPath: path) {
                            Text(size)
                                .font(.system(.caption))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(path)
                    .font(.system(size: 10.5, design: .monospaced))
                    .textSelection(.enabled)
                    .lineSpacing(2)
                    .foregroundStyle(.secondary)
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(Color.primary.opacity(0.04))
                    )
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    @ViewBuilder
    private func multipleFilesPreview(_ entry: ClipboardHistoryEntry) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String(format: text.fileCountFormat, entry.filePaths.count))
                .font(.system(size: 11.5, weight: .semibold))
                .foregroundStyle(.secondary)

            VStack(spacing: 6) {
                ForEach(entry.filePaths, id: \.self) { path in
                    HStack(spacing: 6) {
                        if ClipboardImageStore.isImageFile(atPath: path),
                           let thumb = ClipboardImageStore.fileThumbnail(atPath: path, maxPixelSize: 64) {
                            Image(nsImage: thumb)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 20, height: 20)
                                .clipShape(RoundedRectangle(cornerRadius: 3, style: .continuous))
                        } else {
                            Image(nsImage: NSWorkspace.shared.icon(forFile: path))
                                .resizable()
                                .frame(width: 18, height: 18)
                        }
                        Text((path as NSString).lastPathComponent)
                            .font(.system(.subheadline))
                            .lineLimit(1)
                            .truncationMode(.middle)
                        Spacer()
                    }
                }
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(Color.primary.opacity(0.04))
            )

            Text(entry.filePaths.joined(separator: "\n"))
                .font(.system(size: 10.5, design: .monospaced))
                .textSelection(.enabled)
                .lineSpacing(2)
                .foregroundStyle(.secondary)
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Color.primary.opacity(0.04))
                )
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    private var emptyState: some View {
        Image(systemName: "doc.on.clipboard")
            .font(.system(.title, weight: .light))
            .foregroundStyle(.tertiary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func sidebarFooter(_ entry: ClipboardHistoryEntry) -> some View {
        HStack(spacing: 6) {
            if entry.isPinned {
                Image(systemName: "pin.fill")
                    .font(.system(size: 9.5))
                    .foregroundStyle(Color.accentColor)
            }
            Text(entry.copiedAt, style: .time)
                .font(.system(size: 9.5))
                .foregroundStyle(.tertiary)
            Spacer()
            if editingEntryID == entry.id {
                if isSaving {
                    ProgressView().controlSize(.mini).accessibilityLabel(text.save)
                }
                Button(text.cancel) {
                    cancelEditing()
                }
                Button(text.save) {
                    saveEditing(entry)
                }
                .buttonStyle(.borderedProminent)
                .disabled(isSaving || !ClipboardHistoryEditing.canSave(original: entry.text, draft: draft))
            } else {
                if entry.kind == .text {
                    Button(text.edit) {
                        beginEditing(entry)
                    }
                }
                Button(ClipboardActionStrings.copyOriginal(entry.kind)) {
                    ClipboardHistoryService.shared.copyOnlyQuickEntry(entry)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .controlSize(.mini)
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
    }

    private func beginEditing(_ entry: ClipboardHistoryEntry) {
        editingSession = UUID()
        isSaving = false
        editSaveFailed = false
        draft = entry.text
        editingEntryID = entry.id
        isEditing = true
        DispatchQueue.main.async { editorFocused = true }
    }

    private func cancelEditing() {
        editingSession = UUID()
        isSaving = false
        editSaveFailed = false
        editorFocused = false
        editingEntryID = nil
        draft = ""
        isEditing = false
    }

    private var editFailureMessage: some View {
        Text(text.editSaveFailed)
            .font(.caption)
            .foregroundStyle(.orange)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 12)
            .padding(.bottom, 8)
    }

    private func clearEditFailure() {
        editingSession = UUID()
        isSaving = false
        editSaveFailed = false
    }

    private func saveEditing(_ entry: ClipboardHistoryEntry) {
        guard !isSaving, editingEntryID == entry.id else { return }
        let session = editingSession
        let savedDraft = draft
        isSaving = true
        editSaveFailed = false
        ClipboardHistoryService.shared.updateText(entry, to: savedDraft, isCurrent: { [self] in
            editingSession == session && editingEntryID == entry.id
                && isEditing && isEntryCurrent(entry.id) && draft == savedDraft
        }) { [self] saved in
            guard editingSession == session, editingEntryID == entry.id,
                  isEditing, isEntryCurrent(entry.id) else { return }
            isSaving = false
            guard draft == savedDraft else { return }
            guard saved else {
                editSaveFailed = true
                editorFocused = true
                return
            }
            cancelEditing()
        }
    }
}
