// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import AppKit
import AVFoundation
import SwiftUI
import UniformTypeIdentifiers

struct MediaSettings: View {
    var body: some View {
        MediaWorkspaceView(compact: false)
    }
}

struct PanelMediaView: View {
    var onClose: () -> Void

    var body: some View {
        MediaWorkspaceView(compact: true, onClose: onClose)
            .onAppear { PanelInteractionState.shared.viewKeepsPopoverOpen = true }
            .onDisappear { PanelInteractionState.shared.viewKeepsPopoverOpen = false }
    }
}

private enum MediaCompressionLevel: String, CaseIterable, Identifiable {
    case low, medium, high

    var id: String { rawValue }

    var quality: Double {
        switch self {
        case .low: return 0.88
        case .medium: return 0.68
        case .high: return 0.28
        }
    }

    var symbolName: String {
        switch self {
        case .low: return "circle"
        case .medium: return "circle.lefthalf.filled"
        case .high: return "circle.fill"
        }
    }

    static func nearest(to quality: Double) -> MediaCompressionLevel {
        allCases.min { abs($0.quality - quality) < abs($1.quality - quality) } ?? .medium
    }
}

struct MediaWorkspaceView: View {
    @ObservedObject private var l10n = L10n.shared
    @ObservedObject private var media = MediaService.shared
    @ObservedObject private var featureRuntime = FeatureRuntime.shared
    @Environment(\.colorScheme) private var colorScheme

    @AppStorage(DefaultsKey.mediaLastTool) private var toolRaw = MediaTool.videoCompressor.rawValue
    @AppStorage(DefaultsKey.mediaVideoStart) private var videoStart = 0.0
    @AppStorage(DefaultsKey.mediaVideoEnd) private var videoEnd = 0.0
    @AppStorage(DefaultsKey.mediaVideoQuality) private var videoQuality = 0.68
    @AppStorage(DefaultsKey.mediaVideoMaxDimension) private var videoMaxDimension = 1280
    @AppStorage(DefaultsKey.mediaVideoSizing) private var videoSizingRaw = MediaSizingMode.resolution.rawValue
    @AppStorage(DefaultsKey.mediaVideoTargetMegabytes) private var videoTargetMegabytes = 20

    @AppStorage(DefaultsKey.mediaGIFStart) private var gifStart = 0.0
    @AppStorage(DefaultsKey.mediaGIFEnd) private var gifEnd = 0.0
    @AppStorage(DefaultsKey.mediaGIFWidth) private var gifWidth = 720
    @AppStorage(DefaultsKey.mediaGIFFPS) private var gifFPS = 12.0
    @AppStorage(DefaultsKey.mediaGIFLoops) private var gifLoops = true
    @AppStorage(DefaultsKey.mediaGIFSizing) private var gifSizingRaw = MediaSizingMode.resolution.rawValue
    @AppStorage(DefaultsKey.mediaGIFTargetMegabytes) private var gifTargetMegabytes = 10

    @AppStorage(DefaultsKey.mediaImageQuality) private var imageQuality = 0.72
    @AppStorage(DefaultsKey.mediaImageMaxDimension) private var imageMaxDimension = 1600
    @AppStorage(DefaultsKey.mediaImageFormat) private var imageFormatRaw = MediaImageFormat.jpeg.rawValue
    @AppStorage(DefaultsKey.mediaImageStripMetadata) private var imageStripMetadata = true
    @AppStorage(DefaultsKey.mediaImageResizeKind) private var imageResizeKindRaw = MediaImageResizeKind.maxDimension.rawValue
    @AppStorage(DefaultsKey.mediaImageResizeWidth) private var imageResizeWidth = 1600
    @AppStorage(DefaultsKey.mediaImageResizeHeight) private var imageResizeHeight = 1200
    @AppStorage(DefaultsKey.mediaImageExactResizeMode) private var imageExactResizeModeRaw = MediaImageExactResizeMode.stretch.rawValue
    @AppStorage(DefaultsKey.mediaImageWatermarkKind) private var imageWatermarkKindRaw = MediaImageWatermarkKind.off.rawValue
    @AppStorage(DefaultsKey.mediaImageWatermarkText) private var imageWatermarkText = ""
    @AppStorage(DefaultsKey.mediaImageWatermarkLogoPath) private var imageWatermarkLogoPath = ""
    @AppStorage(DefaultsKey.mediaImageWatermarkPosition) private var imageWatermarkPositionRaw = MediaImageWatermarkPosition.bottomRight.rawValue
    @AppStorage(DefaultsKey.mediaImageWatermarkOpacity) private var imageWatermarkOpacity = 0.45
    @AppStorage(DefaultsKey.mediaImageWatermarkMargin) private var imageWatermarkMargin = 32
    @AppStorage(DefaultsKey.mediaImageWatermarkScale) private var imageWatermarkScale = 0.18
    @AppStorage(DefaultsKey.mediaImageRenamePattern) private var imageRenamePattern = ""
    @AppStorage(DefaultsKey.mediaImageBackground) private var imageBackgroundRaw = MediaImageBackground.transparent.rawValue
    @AppStorage(DefaultsKey.mediaImagePreserveModificationDate) private var imagePreserveModificationDate = false
    @AppStorage(DefaultsKey.mediaImageSaveInSubfolder) private var imageSaveInSubfolder = false
    @AppStorage(DefaultsKey.mediaImageProfiles) private var imageProfilesRaw = "[]"
    @AppStorage(DefaultsKey.mediaImageSelectedProfileID) private var imageSelectedProfileID = ""

    @AppStorage(DefaultsKey.mediaTextAccurate) private var textAccurate = true

    @State private var inputURLs: [URL] = []
    @State private var inputRevision = 0
    @State private var pdfCompressionMode: MediaPDFCompressionMode = .preserveResolution
    @State private var pdfInspectionTask: Task<Void, Never>?
    @State private var pdfInspectionGeneration = 0
    @State private var pdfPageCounts: [URL: Int] = [:]
    @State private var pdfInspectionErrors: [URL: MediaPDFError] = [:]
    @State private var pdfInspectionBatchError: MediaPDFError?
    @State private var inputImageSize: CGSize?
    @State private var outputURL: URL?
    @State private var outputWasChosenManually = false
    @State private var isDropTargeted = false
    @State private var localMessage: String?
    @State private var mediaDefaultsTask: Task<Void, Never>?
    @State private var videoImportTask: Task<Void, Never>?
    @State private var videoImportGeneration = 0
    @State private var profileName = ""
    @State private var imageMoreOptionsExpanded = false
    @State private var isImportingVideo = false
    /// Read once per chosen file. Loading it in the body meant decoding the
    /// logo from disk on every redraw, so dragging the opacity slider was
    /// re-reading a file for each frame.
    @State private var watermarkLogo: NSImage?

    var compact: Bool
    var onClose: (() -> Void)? = nil

    private var inputURL: URL? { inputURLs.first }
    private static let imageOutputSubfolderName = "Converted"
    private static let imageRenameTokens = [
        "{name}", "{index}", "{index:03}", "{counter}", "{date}",
        "{time}", "{datetime}", "{width}", "{height}", "{format}",
    ]
    private var isPDFTool: Bool { selectedTool == .pdfMerger || selectedTool == .pdfCompressor }
    private var pdfText: MediaPDFStrings { .localized(l10n.language) }
    private var imageText: MediaImageConverterStrings {
        MediaImageConverterStrings.localized(l10n.language)
    }

    private var screenshotText: ScreenshotFeatureStrings {
        FeatureStrings.screenshot(l10n.language)
    }

    private var selectedTool: MediaTool {
        get { MediaSupport.sanitizedTool(toolRaw) }
        nonmutating set {
            guard !isRunning else { return }
            cancelVideoImport()
            inputRevision &+= 1
            let rejected = !inputURLs.isEmpty
                && MediaInputSelectionSupport.validatedURLs(inputURLs, for: newValue) == nil
            if rejected { inputURLs = [] }
            toolRaw = newValue.rawValue
            refreshPDFInspection()
            inputImageSize = newValue == .imageCompressor
                ? inputURL.flatMap { MediaSupport.imageDisplaySize(at: $0) }
                : nil
            outputURL = defaultOutputURL(for: inputURLs, tool: newValue)
            outputWasChosenManually = false
            applyMediaDefaults(for: inputURL, tool: newValue)
            localMessage = rejected ? pdfText.changedTool : nil
            media.reset()
        }
    }

    private var selectedToolBinding: Binding<MediaTool> {
        Binding {
            selectedTool
        } set: { newValue in
            selectedTool = newValue
        }
    }

    private var isRunning: Bool {
        if case .running = media.state { return true }
        return false
    }

    var body: some View {
        Group {
            if compact {
                VStack(alignment: .leading, spacing: 10) {
                    header
                    toolPicker
                    ScrollView {
                        content.padding(.trailing, 1)
                    }
                    .frame(maxHeight: 430)
                }
            } else {
                SettingsForm {
                    SettingsSection {
                        toolPicker
                        SettingsInfo(text: l10n.s.mediaLocalNote, systemImage: "lock.shield")
                    }
                    content
                }
            }
        }
        .onAppear { refreshPDFInspection() }
        .onChange(of: pdfCompressionMode) {
            guard selectedTool == .pdfCompressor, !isRunning else { return }
            media.reset()
            localMessage = nil
        }
        .onChange(of: currentImageOptions) { oldOptions, newOptions in
            guard selectedTool == .imageCompressor, !isRunning else { return }
            if outputWasChosenManually {
                if inputURLs.count == 1,
                   oldOptions.format != newOptions.format,
                   let outputURL {
                    self.outputURL = MediaSupport.outputURLByReplacingExtension(
                        outputURL,
                        fileExtension: newOptions.format.fileExtension)
                }
                return
            }
            outputURL = defaultOutputURL(for: inputURLs, tool: .imageCompressor)
        }
        .onDisappear {
            cancelPDFInspection()
            mediaDefaultsTask?.cancel()
            cancelVideoImport()
        }
        .onChange(of: featureRuntime.revision) {
            if !AppFeature.mediaTools.isAvailable { cancelVideoImport() }
        }
    }

    private var header: some View {
        HStack(spacing: 9) {
            Label(AppFeature.mediaTools.name(l10n.s, language: l10n.language), systemImage: "photo.on.rectangle.angled")
                .font(compact ? .system(.callout, weight: .semibold) : SettingsTypography.body.weight(.semibold))
            Spacer(minLength: 0)
            Text(l10n.s.mediaLocalNote)
                .font(compact ? .system(size: 9.5, weight: .medium) : SettingsTypography.body.weight(.medium))
                .foregroundStyle(.secondary)
            if let onClose {
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
    }

    private var toolPicker: some View {
        Group {
            if compact { toolChoices.pickerStyle(.menu) }
            else { toolChoices.pickerStyle(.segmented) }
        }
        .disabled(isRunning)
    }

    private var toolChoices: some View {
        Picker("", selection: selectedToolBinding) {
            ForEach(MediaTool.allCases) { tool in
                Text(title(for: tool)).tag(tool)
            }
        }
        .labelsHidden()
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: compact ? 9 : SettingsMetrics.sectionSpacing) {
            fileCard
                .disabled(isRunning)
            if compact {
                optionsCard.disabled(isRunning)
                actionRow
            } else {
                VStack(alignment: .leading, spacing: SettingsMetrics.contentSpacing) {
                    optionsCard.disabled(isRunning)
                    Divider()
                    actionRow
                }
                .settingsSurface()
            }
            statusCard
        }
    }

    private var fileCard: some View {
        VStack(alignment: .leading, spacing: 9) {
            ZStack(alignment: .trailing) {
                Button {
                    chooseInput()
                } label: {
                    HStack(spacing: 9) {
                        Image(systemName: selectedTool == .textExtractor ? "doc.text.viewfinder" : "doc.badge.plus")
                            .font(.system(size: 16, weight: .semibold))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(inputTitle)
                                .font(compact ? .system(size: 11.5, weight: .semibold) : SettingsTypography.body.weight(.semibold))
                                .lineLimit(1)
                                .truncationMode(.middle)
                            Text(selectedTool == .pdfCompressor ? pdfText.chooseSingle
                                 : selectedTool == .pdfMerger ? pdfText.choose : l10n.s.mediaDropHint)
                                .font(compact ? .system(size: 9.5) : SettingsTypography.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(compact ? 9 : 12)
                    .padding(.trailing, inputURLs.isEmpty ? 0 : (compact ? 30 : 34))
                    .frame(maxWidth: .infinity, minHeight: compact ? 52 : 62, alignment: .leading)
                    .contentShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity, minHeight: compact ? 52 : 62, alignment: .leading)

                if !inputURLs.isEmpty {
                    Button {
                        clearInput()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(compact ? .system(size: 14, weight: .semibold) : SettingsTypography.body.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .frame(width: compact ? 24 : 28, height: compact ? 24 : 28)
                            .contentShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .help(l10n.s.mediaCancel)
                    .padding(.trailing, compact ? 8 : 10)
                }
            }
            .frame(maxWidth: .infinity, minHeight: compact ? 52 : 62, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isDropTargeted ? Color.accentColor.opacity(0.16) : PanelSurface.controlFill(for: colorScheme))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(isDropTargeted ? Color.accentColor.opacity(0.7) : PanelSurface.border(for: colorScheme),
                                  lineWidth: isDropTargeted ? 1.2 : 0.8)
            )
            .onDrop(of: [.fileURL], isTargeted: $isDropTargeted) { providers in
                acceptDrop(providers)
            }

            HStack(spacing: 7) {
                Text(l10n.s.mediaOutput)
                    .font(compact ? .system(size: 9.5, weight: .semibold) : SettingsTypography.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(outputURL?.lastPathComponent ?? l10n.s.mediaOutputAutomatic)
                    .font(compact ? .system(.caption) : SettingsTypography.body)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Spacer(minLength: 0)
                Button {
                    chooseOutput()
                } label: {
                    Label(l10n.s.mediaChooseOutput, systemImage: "folder")
                }
                .controlSize(compact ? .small : .regular)
                .disabled(inputURLs.isEmpty || isRunning)
            }
            if selectedTool == .imageCompressor, inputURLs.count > 1 {
                Toggle(imageText.saveInSubfolder, isOn: $imageSaveInSubfolder)
                    .toggleStyle(.checkbox)
                    .disabled(isRunning)
            }
        }
        .mediaWorkspaceSurface(compact: compact)
    }

    @ViewBuilder
    private var optionsCard: some View {
        switch selectedTool {
        case .videoCompressor:
            VStack(alignment: .leading, spacing: 10) {
                timeRangeRow(start: $videoStart, end: $videoEnd)
                sizingPicker(selection: $videoSizingRaw)
                if videoSizing == .resolution {
                    compressionRow(value: $videoQuality)
                    stepperInt(l10n.s.mediaMaxSize, value: $videoMaxDimension, range: 640...3840, step: 320, suffix: "px")
                } else {
                    targetSizeRow(value: $videoTargetMegabytes)
                }
            }
            .mediaWorkspaceSurface(compact: compact, settings: false)
        case .gifMaker:
            VStack(alignment: .leading, spacing: 10) {
                timeRangeRow(start: $gifStart, end: $gifEnd)
                sizingPicker(selection: $gifSizingRaw)
                if gifSizing == .resolution {
                    fpsSliderRow(value: $gifFPS, range: 1...30)
                    HStack(spacing: 10) {
                        stepperInt(l10n.s.mediaWidth, value: $gifWidth, range: 160...1600, step: 80, suffix: "px")
                    }
                } else {
                    targetSizeRow(value: $gifTargetMegabytes)
                }
                Toggle(l10n.s.mediaLoopGIF, isOn: $gifLoops)
                    .toggleStyle(compact: compact)
            }
            .mediaWorkspaceSurface(compact: compact, settings: false)
        case .imageCompressor:
            VStack(alignment: .leading, spacing: 10) {
                imageQuickPresetsRow
                imagePreviewSection
                Picker(l10n.s.mediaFormat, selection: $imageFormatRaw) {
                    Text("JPEG").tag(MediaImageFormat.jpeg.rawValue)
                    Text("PNG").tag(MediaImageFormat.png.rawValue)
                    Text("HEIC").tag(MediaImageFormat.heic.rawValue)
                    Text("PDF").tag(MediaImageFormat.pdf.rawValue)
                }
                .pickerStyle(.segmented)
                compressionRow(value: $imageQuality)
                imageResizeSection
                DisclosureHeaderRow(isExpanded: $imageMoreOptionsExpanded) {
                    Text(imageText.moreOptions)
                    Spacer()
                }
                if imageMoreOptionsExpanded {
                    VStack(alignment: .leading, spacing: 10) {
                        imageProfileRow
                        // PDF output never carries EXIF (the image is re-encoded
                        // into the document), so the toggle would be a dead control.
                        if MediaImageFormat.sanitized(imageFormatRaw) != .pdf {
                            Toggle(l10n.s.mediaStripMetadata, isOn: $imageStripMetadata)
                                .toggleStyle(compact: compact)
                        }
                        imageBackgroundSection
                        imageWatermarkSection
                        imageRenameSection
                        Toggle(imageText.preserveDate, isOn: $imagePreserveModificationDate)
                            .toggleStyle(compact: compact)
                    }
                    .padding(.top, 6)
                    .disclosureIndent()
                }
            }
            .mediaWorkspaceSurface(compact: compact, settings: false)
        case .textExtractor:
            VStack(alignment: .leading, spacing: 10) {
                Picker(l10n.s.mediaOCRMode, selection: $textAccurate) {
                    Text(l10n.s.mediaOCRAccurate).tag(true)
                    Text(l10n.s.mediaOCRFast).tag(false)
                }
                .pickerStyle(.segmented)
            }
            .mediaWorkspaceSurface(compact: compact, settings: false)
        case .pdfMerger:
            pdfFilesCard
        case .pdfCompressor:
            VStack(alignment: .leading, spacing: 10) {
                Picker(pdfText.compressorTitle, selection: $pdfCompressionMode) {
                    Text(pdfText.preserveResolution).tag(MediaPDFCompressionMode.preserveResolution)
                    Text(pdfText.screen).tag(MediaPDFCompressionMode.screen)
                }
                .pickerStyle(.segmented)
                Text(pdfText.compressionHint).font(compact ? .caption : SettingsTypography.caption).foregroundStyle(.secondary)
                Text(pdfCompressionMode == .preserveResolution ? pdfText.preserveHint : pdfText.screenHint)
                    .font(compact ? .caption : SettingsTypography.caption).foregroundStyle(.secondary)
                if let inputURL {
                    Text(pdfPageDescription(for: inputURL)).font(compact ? .caption : SettingsTypography.caption)
                        .foregroundStyle(pdfInspectionErrors[inputURL] == nil ? Color.secondary : Color.orange)
                }
                if let error = pdfInspectionBatchError {
                    Text(message(for: error)).font(compact ? .caption : SettingsTypography.caption).foregroundStyle(.orange)
                }
            }
            .mediaWorkspaceSurface(compact: compact, settings: false)
        }
    }

    private var pdfFilesCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(pdfText.order).font(compact ? .headline : SettingsTypography.sectionTitle)
            Text(pdfText.hint).font(compact ? .caption : SettingsTypography.caption).foregroundStyle(.secondary)
            ForEach(Array(inputURLs.enumerated()), id: \.offset) { index, url in
                HStack(spacing: 8) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("\(index + 1). \(url.lastPathComponent)")
                            .lineLimit(1).truncationMode(.middle)
                            .help(url.path)
                        Text(pdfPageDescription(for: url))
                            .font(compact ? .caption : SettingsTypography.caption)
                            .foregroundStyle(pdfInspectionErrors[url] == nil ? Color.secondary : Color.orange)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    Button { movePDF(at: index, by: -1) } label: {
                        Image(systemName: "arrow.up")
                    }
                    .disabled(index == 0)
                    .help(pdfText.moveUp)
                    .accessibilityLabel(pdfText.moveUp + " " + url.lastPathComponent)
                    Button { movePDF(at: index, by: 1) } label: {
                        Image(systemName: "arrow.down")
                    }
                    .disabled(index + 1 == inputURLs.count)
                    .help(pdfText.moveDown)
                    .accessibilityLabel(pdfText.moveDown + " " + url.lastPathComponent)
                    Button { removePDF(at: index) } label: {
                        Image(systemName: "minus.circle")
                    }
                    .help(pdfText.remove)
                    .accessibilityLabel(pdfText.remove + " " + url.lastPathComponent)
                }
                .controlSize(compact ? .small : .regular)
            }
            Button(pdfText.add) { chooseInput(appending: true) }
            if let error = pdfInspectionBatchError {
                Text(message(for: error)).font(compact ? .caption : SettingsTypography.caption).foregroundStyle(.orange)
            }
            if inputURLs.count < 2 {
                Text(pdfText.tooFew).font(compact ? .caption : SettingsTypography.caption).foregroundStyle(.secondary)
            }
        }
        .mediaWorkspaceSurface(compact: compact, settings: false)
    }

    private func pdfPageDescription(for url: URL) -> String {
        if let error = pdfInspectionErrors[url] { return message(for: error) }
        if let count = pdfPageCounts[url] { return String(format: pdfText.pagesFormat, count) }
        if let error = pdfInspectionBatchError { return message(for: error) }
        return pdfText.readingPages
    }

    private var actionRow: some View {
        HStack(spacing: 8) {
            Button {
                run()
            } label: {
                Label(actionTitle, systemImage: selectedTool == .textExtractor ? "text.viewfinder" : "play.fill")
            }
            .mediaWorkspacePrimaryAction(compact: compact)
            .disabled(inputURLs.isEmpty || isRunning || (selectedTool == .pdfMerger && inputURLs.count < 2))

            if selectedTool == .videoCompressor {
                Button {
                    openVideoEditor()
                } label: {
                    Label(screenshotText.editButton, systemImage: "crop")
                }
                .disabled(inputURLs.count != 1 || isRunning || isImportingVideo)
                if isImportingVideo {
                    ProgressView()
                        .controlSize(compact ? .small : .regular)
                }
            }

            if isRunning {
                Button {
                    media.cancel()
                } label: {
                    Label(l10n.s.mediaCancel, systemImage: "xmark")
                }
            }

            Spacer(minLength: 0)
        }
        .controlSize(compact ? .small : .regular)
    }

    @ViewBuilder
    private var statusCard: some View {
        switch media.state {
        case .idle, .ready:
            if let localMessage {
                messageCard(localMessage, systemImage: "exclamationmark.triangle.fill", color: .orange)
            }
        case let .running(progress, _):
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label(l10n.s.mediaRunning, systemImage: "gearshape.2")
                        .font(compact ? .system(size: 10.5, weight: .semibold) : SettingsTypography.body.weight(.semibold))
                    Spacer()
                    if selectedTool != .pdfCompressor {
                        Text("\(Int((progress * 100).rounded()))%")
                            .font(compact ? .system(.caption, design: .monospaced, weight: .medium) : SettingsTypography.body.weight(.medium).monospaced())
                            .foregroundStyle(.secondary)
                    }
                }
                if selectedTool == .pdfCompressor {
                    ProgressView()
                        .controlSize(compact ? .small : .regular)
                } else {
                    ProgressView(value: progress)
                }
            }
            .mediaWorkspaceSurface(compact: compact)
        case let .completed(result):
            resultCard(result)
        case let .failed(failure):
            messageCard(message(for: failure), systemImage: "exclamationmark.triangle.fill", color: .orange)
        case .cancelled:
            messageCard(l10n.s.mediaCancelled, systemImage: "xmark.circle.fill", color: .secondary)
        }
    }

    private func resultCard(_ result: MediaResult) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(result.pdfNotSmaller ? pdfText.notSmaller : l10n.s.mediaCompleted,
                  systemImage: result.pdfNotSmaller ? "info.circle" : "checkmark.circle.fill")
                .font(compact ? .system(size: 10.5, weight: .semibold) : SettingsTypography.body.weight(.semibold))
                .foregroundStyle(result.pdfNotSmaller ? Color.secondary : Color.green)
            if result.pdfNotSmaller {
                Text(String(format: pdfText.originalSizeFormat,
                    ByteCountFormatter.string(fromByteCount: result.originalBytes, countStyle: .file)))
                    .font(compact ? .caption : SettingsTypography.caption).foregroundStyle(.secondary)
            }
            if let outputURL = result.outputURL {
                Text(result.imageBatchItems.count > 1 ? batchSummary(result) : String(format: l10n.s.mediaResultSavedFormat, outputURL.lastPathComponent))
                    .font(compact ? .system(.caption) : SettingsTypography.body)
                    .lineLimit(2)
                    .truncationMode(.middle)
                Text(String(format: l10n.s.mediaResultSizeFormat,
                            ByteCountFormatter.string(fromByteCount: result.originalBytes, countStyle: .file),
                            ByteCountFormatter.string(fromByteCount: result.outputBytes, countStyle: .file)))
                    .font(compact ? .system(size: 9.5) : SettingsTypography.caption)
                    .foregroundStyle(.secondary)
                if result.tool != .pdfMerger, let delta = resultSizeDelta(result) {
                    Text(delta)
                        .font(compact ? .system(size: 9.5) : SettingsTypography.caption)
                        .foregroundStyle(.secondary)
                }
                if result.tool != .pdfMerger, MediaSupport.outputGrew(originalBytes: result.originalBytes,
                                           outputBytes: result.outputBytes) {
                    Text(l10n.s.mediaResultGrewCaption)
                        .font(compact ? .system(size: 9.5) : SettingsTypography.caption)
                        .foregroundStyle(.secondary)
                }
                if result.failedCount > 0 {
                    Text(result.imageBatchItems.compactMap { item in
                        item.failure.map { "\(item.inputURL.lastPathComponent): \(message(for: $0))" }
                    }.prefix(3).joined(separator: "\n"))
                        .font(compact ? .system(size: 9) : SettingsTypography.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                }
            }
            if let text = result.text {
                Text(text.isEmpty ? l10n.s.mediaEmptyText : text)
                    .font(compact ? .system(.caption, design: .monospaced) : SettingsTypography.body.monospaced())
                    .lineLimit(compact ? 5 : 8)
                    .textSelection(.enabled)
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 7, style: .continuous).fill(Color.primary.opacity(0.045)))
            }
            HStack(spacing: 8) {
                if let outputURL = result.outputURL {
                    Button {
                        NSWorkspace.shared.activateFileViewerSelecting(result.outputURLs.isEmpty ? [outputURL] : result.outputURLs)
                    } label: {
                        Label(l10n.s.mediaOpenInFinder, systemImage: "folder")
                    }
                }
                if let text = result.text {
                    Button {
                        copy(text)
                    } label: {
                        Label(l10n.s.mediaCopyText, systemImage: "doc.on.doc")
                    }
                }
                if result.imageBatchItems.count > 1 {
                    Button {
                        copy(batchSummaryText(result))
                    } label: {
                        Label(imageText.copySummary, systemImage: "doc.on.doc")
                    }
                }
                Button {
                    run()
                } label: {
                    Label(l10n.s.mediaRunAgain, systemImage: "arrow.clockwise")
                }
            }
            .controlSize(compact ? .small : .regular)
        }
        .mediaWorkspaceSurface(compact: compact)
    }

    private func batchSummary(_ result: MediaResult) -> String {
        if result.failedCount > 0 {
            return String(format: imageText.batchPartialFormat, result.processedCount, result.failedCount)
        }
        return String(format: imageText.batchSavedFormat, result.processedCount)
    }

    private func batchSummaryText(_ result: MediaResult) -> String {
        var lines = [String(format: imageText.batchSummaryHeaderFormat, result.processedCount, result.failedCount)]
        if let delta = resultSizeDelta(result) {
            lines.append(delta)
        }
        for item in result.imageBatchItems {
            if let outputURL = item.outputURL {
                lines.append(String(format: imageText.batchSummaryItemFormat,
                                    item.inputURL.lastPathComponent,
                                    outputURL.lastPathComponent))
            } else if let failure = item.failure {
                lines.append("\(item.inputURL.lastPathComponent): \(message(for: failure))")
            }
        }
        return lines.joined(separator: "\n")
    }

    private func resultSizeDelta(_ result: MediaResult) -> String? {
        let delta = result.originalBytes - result.outputBytes
        guard delta != 0 else { return nil }
        let formatted = ByteCountFormatter.string(fromByteCount: abs(delta), countStyle: .file)
        if delta > 0 {
            return String(format: imageText.savedBytesFormat, formatted)
        }
        return String(format: imageText.grewBytesFormat, formatted)
    }

    private func messageCard(_ message: String, systemImage: String, color: Color) -> some View {
        Label(message, systemImage: systemImage)
            .font(compact ? .system(size: 10.5, weight: .medium) : SettingsTypography.body.weight(.medium))
            .foregroundStyle(color)
            .frame(maxWidth: .infinity, alignment: .leading)
            .mediaWorkspaceSurface(compact: compact)
    }

    private var imageProfileRow: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Picker(imageText.profile, selection: $imageSelectedProfileID) {
                    Text(imageText.noProfile).tag("")
                    ForEach(imageProfiles) { profile in
                        Text(profile.name).tag(profile.id)
                    }
                }
                .labelsHidden()
                .onChange(of: imageSelectedProfileID) { _, value in
                    guard !value.isEmpty,
                          let profile = imageProfiles.first(where: { $0.id == value }) else { return }
                    applyImageOptions(profile.options)
                }
                Button {
                    deleteSelectedProfile()
                } label: {
                    Image(systemName: "trash")
                }
                .disabled(imageSelectedProfileID.isEmpty)
                .help(imageText.deleteProfile)
            }
            if selectedImageProfile != nil, imageProfileIsModified {
                Label(imageText.profileModified, systemImage: "pencil")
                    .font(compact ? .system(size: 9, weight: .medium) : SettingsTypography.caption.weight(.medium))
                    .foregroundStyle(.secondary)
            }
            HStack(spacing: 6) {
                TextField(imageText.profileName, text: $profileName)
                    .textFieldStyle(.roundedBorder)
                Button {
                    updateSelectedProfile()
                } label: {
                    Label(imageText.updateProfile, systemImage: "checkmark")
                }
                .controlSize(compact ? .small : .regular)
                .disabled(imageSelectedProfileID.isEmpty)
                Button {
                    saveNewProfile()
                } label: {
                    Label(imageText.saveAsNew, systemImage: "plus")
                }
                .controlSize(compact ? .small : .regular)
            }
        }
    }

    private var imageQuickPresetsRow: some View {
        HStack(spacing: 6) {
            Button(imageText.presetWeb) {
                applyImageOptions(MediaImageOptions(quality: 0.72,
                                                    maxDimension: 1600,
                                                    format: .jpeg,
                                                    stripMetadata: true,
                                                    resizeMode: .maxDimension(1600),
                                                    renamePattern: MediaImageRenamePattern("{name}-web")))
            }
            Button(imageText.presetSocial) {
                applyImageOptions(MediaImageOptions(quality: 0.82,
                                                    maxDimension: 2048,
                                                    format: .png,
                                                    stripMetadata: true,
                                                    resizeMode: .maxDimension(2048),
                                                    renamePattern: MediaImageRenamePattern("{name}-social")))
            }
            Button(imageText.presetDocs) {
                applyImageOptions(MediaImageOptions(quality: 0.7,
                                                    maxDimension: 1600,
                                                    format: .pdf,
                                                    stripMetadata: true,
                                                    resizeMode: .maxDimension(1600),
                                                    background: .white,
                                                    preserveModificationDate: true))
            }
        }
        .controlSize(compact ? .small : .regular)
    }

    private var imagePreviewSection: some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(previewBackgroundColor)
                if let thumbnail = inputURL.flatMap({ ImageThumbnailer.thumbnail(for: $0, pointSize: compact ? 96 : 128) }) {
                    previewImage(thumbnail)
                        .frame(width: previewFrameSize.width,
                               height: previewFrameSize.height,
                               alignment: .center)
                        .clipped()
                } else {
                    Image(systemName: "photo")
                        .font(.system(size: compact ? 26 : 32))
                        .foregroundStyle(.secondary)
                }
            }
            .task(id: currentWatermark.usesLogo ? imageWatermarkLogoPath : "") {
                watermarkLogo = currentWatermark.usesLogo
                    ? NSImage(contentsOfFile: imageWatermarkLogoPath)
                    : nil
            }
            .frame(width: previewFrameSize.width, height: previewFrameSize.height)
            .overlay(alignment: previewAlignment) {
                previewWatermarkOverlay
                    .padding(previewWatermarkMargin)
                    .opacity(currentWatermark.opacity)
            }
            .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .strokeBorder(PanelSurface.border(for: colorScheme), lineWidth: 0.8)
            )

            VStack(alignment: .leading, spacing: 5) {
                Text(imageText.preview)
                    .font(compact ? .system(.caption, weight: .semibold) : SettingsTypography.body.weight(.semibold))
                Text("\(imageText.outputName): \(previewOutputName)")
                    .font(compact ? .system(size: 9.5) : SettingsTypography.caption)
                    .lineLimit(2)
                    .truncationMode(.middle)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
    }

    @ViewBuilder
    private func previewImage(_ image: NSImage) -> some View {
        if currentResizeMode.kind == .exact, currentResizeMode.exactMode == .stretch {
            Image(nsImage: image)
                .resizable()
        } else if currentResizeMode.kind == .exact, currentResizeMode.exactMode == .fill {
            Image(nsImage: image)
                .resizable()
                .scaledToFill()
                .clipped()
        } else {
            Image(nsImage: image)
                .resizable()
                .scaledToFit()
        }
    }

    @ViewBuilder
    private var previewWatermarkOverlay: some View {
        if currentWatermark.isEnabled {
            HStack(spacing: 4) {
                if currentWatermark.usesLogo {
                    if let logo = watermarkLogo {
                        Image(nsImage: logo)
                            .resizable()
                            .scaledToFit()
                            .frame(width: previewWatermarkLogoSide, height: previewWatermarkLogoSide)
                    }
                }
                if currentWatermark.usesText {
                    Text(currentWatermark.text)
                        .font(.system(size: compact ? 8 : 10, weight: .semibold))
                        .lineLimit(1)
                }
            }
            .foregroundStyle(.white)
            .shadow(color: .black.opacity(0.55), radius: 2, y: 1)
        }
    }

    private var imageResizeSection: some View {
        VStack(alignment: .leading, spacing: 7) {
            Picker(imageText.resize, selection: $imageResizeKindRaw) {
                Text(imageText.resizeNone).tag(MediaImageResizeKind.none.rawValue)
                Text(imageText.resizeMax).tag(MediaImageResizeKind.maxDimension.rawValue)
                Text(imageText.resizeWidth).tag(MediaImageResizeKind.width.rawValue)
                Text(imageText.resizeHeight).tag(MediaImageResizeKind.height.rawValue)
                Text(imageText.resizeExact).tag(MediaImageResizeKind.exact.rawValue)
            }
            .pickerStyle(.menu)
            switch MediaImageResizeKind.sanitized(imageResizeKindRaw) {
            case .none:
                EmptyView()
            case .maxDimension:
                stepperInt(l10n.s.mediaMaxSize, value: $imageMaxDimension, range: 64...20_000, step: 128, suffix: "px")
            case .width:
                stepperInt(l10n.s.mediaWidth, value: $imageResizeWidth, range: 1...20_000, step: 64, suffix: "px")
            case .height:
                stepperInt(imageText.height, value: $imageResizeHeight, range: 1...20_000, step: 64, suffix: "px")
            case .exact:
                HStack(spacing: 10) {
                    stepperInt(l10n.s.mediaWidth, value: $imageResizeWidth, range: 1...20_000, step: 64, suffix: "px")
                    stepperInt(imageText.height, value: $imageResizeHeight, range: 1...20_000, step: 64, suffix: "px")
                }
                Picker("", selection: $imageExactResizeModeRaw) {
                    Text(imageText.exactStretch).tag(MediaImageExactResizeMode.stretch.rawValue)
                    Text(imageText.exactFit).tag(MediaImageExactResizeMode.fit.rawValue)
                    Text(imageText.exactFill).tag(MediaImageExactResizeMode.fill.rawValue)
                }
                .labelsHidden()
                .pickerStyle(.segmented)
            }
        }
    }

    private var imageWatermarkSection: some View {
        VStack(alignment: .leading, spacing: 7) {
            Picker(imageText.watermark, selection: $imageWatermarkKindRaw) {
                Text(imageText.watermarkOff).tag(MediaImageWatermarkKind.off.rawValue)
                Text(imageText.watermarkText).tag(MediaImageWatermarkKind.text.rawValue)
                Text(imageText.watermarkLogo).tag(MediaImageWatermarkKind.logo.rawValue)
                Text(imageText.watermarkBoth).tag(MediaImageWatermarkKind.textAndLogo.rawValue)
            }
            .pickerStyle(.menu)
            if currentWatermarkKind == .text || currentWatermarkKind == .textAndLogo {
                TextField(imageText.watermarkTextPlaceholder, text: $imageWatermarkText)
                    .textFieldStyle(.roundedBorder)
            }
            if currentWatermarkKind == .logo || currentWatermarkKind == .textAndLogo {
                HStack(spacing: 6) {
                    Text(imageWatermarkLogoPath.isEmpty ? imageText.noLogo : URL(fileURLWithPath: imageWatermarkLogoPath).lastPathComponent)
                        .font(compact ? .system(.caption) : SettingsTypography.body)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    Spacer(minLength: 0)
                    Button {
                        chooseWatermarkLogo()
                    } label: {
                        Label(imageText.chooseLogo, systemImage: "photo")
                    }
                    .controlSize(compact ? .small : .regular)
                    if !imageWatermarkLogoPath.isEmpty {
                        Button {
                            imageWatermarkLogoPath = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            if currentWatermarkKind != .off {
                Picker(imageText.position, selection: $imageWatermarkPositionRaw) {
                    Text(imageText.topLeft).tag(MediaImageWatermarkPosition.topLeft.rawValue)
                    Text(imageText.topRight).tag(MediaImageWatermarkPosition.topRight.rawValue)
                    Text(imageText.center).tag(MediaImageWatermarkPosition.center.rawValue)
                    Text(imageText.bottomLeft).tag(MediaImageWatermarkPosition.bottomLeft.rawValue)
                    Text(imageText.bottomRight).tag(MediaImageWatermarkPosition.bottomRight.rawValue)
                }
                .pickerStyle(.menu)
                stepperDouble(imageText.opacity, value: $imageWatermarkOpacity, range: 0.1...1, step: 0.05, suffix: "%") {
                    "\(Int(($0 * 100).rounded()))"
                }
                stepperInt(imageText.margin, value: $imageWatermarkMargin, range: 0...2000, step: 8, suffix: "px")
                stepperDouble(imageText.scale, value: $imageWatermarkScale, range: 0.05...0.8, step: 0.01, suffix: "%") {
                    "\(Int(($0 * 100).rounded()))"
                }
            }
        }
    }

    private var imageBackgroundSection: some View {
        Picker(imageText.background, selection: $imageBackgroundRaw) {
            Text(imageText.backgroundTransparent).tag(MediaImageBackground.transparent.rawValue)
            Text(imageText.backgroundWhite).tag(MediaImageBackground.white.rawValue)
            Text(imageText.backgroundBlack).tag(MediaImageBackground.black.rawValue)
        }
        .pickerStyle(.segmented)
    }

    private var imageRenameSection: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(imageText.rename)
                .font(compact ? .system(.caption, weight: .semibold) : SettingsTypography.body.weight(.semibold))
            HStack(spacing: 6) {
                TextField("{name}-{index:03}", text: $imageRenamePattern)
                    .textFieldStyle(.roundedBorder)
                Menu {
                    ForEach(Self.imageRenameTokens, id: \.self) { token in
                        Button(token) {
                            imageRenamePattern.append(token)
                        }
                    }
                } label: {
                    Text("{…}")
                        .font(compact ? .system(.caption, design: .monospaced) : SettingsTypography.body.monospaced())
                }
                .menuStyle(.borderlessButton)
                .fixedSize()
                .help(imageText.rename)
                .accessibilityLabel(imageText.rename)
            }
        }
    }

    private func timeRangeRow(start: Binding<Double>, end: Binding<Double>) -> some View {
        HStack(spacing: 10) {
            numberField(l10n.s.mediaStartTime, value: start, suffix: "s")
            numberField(l10n.s.mediaEndTime, value: end, suffix: "s")
        }
    }

    private var videoSizing: MediaSizingMode {
        MediaSizingMode.sanitized(videoSizingRaw)
    }

    private var gifSizing: MediaSizingMode {
        MediaSizingMode.sanitized(gifSizingRaw)
    }

    private func sizingPicker(selection: Binding<String>) -> some View {
        Picker("", selection: selection) {
            Text(l10n.s.mediaSizingResolution).tag(MediaSizingMode.resolution.rawValue)
            Text(l10n.s.mediaSizingFileSize).tag(MediaSizingMode.targetSize.rawValue)
        }
        .pickerStyle(.segmented)
        .labelsHidden()
    }

    private func targetSizeRow(value: Binding<Int>) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            integerField(l10n.s.mediaTargetSize,
                         value: value,
                         suffix: l10n.s.mediaMegabytesSuffix)
            Text(l10n.s.mediaTargetSizeHint)
                .font(compact ? .system(size: 9.5) : SettingsTypography.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func compressionRow(value: Binding<Double>) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(l10n.s.mediaQuality)
                .font(compact ? .system(.caption, weight: .semibold) : SettingsTypography.body.weight(.semibold))
            HStack(spacing: 6) {
                ForEach(MediaCompressionLevel.allCases) { level in
                    compressionButton(level, value: value)
                }
            }
        }
    }

    private func compressionButton(_ level: MediaCompressionLevel, value: Binding<Double>) -> some View {
        let selected = MediaCompressionLevel.nearest(to: value.wrappedValue) == level
        return Button {
            value.wrappedValue = level.quality
        } label: {
            HStack(spacing: 5) {
                Image(systemName: level.symbolName)
                    .font(compact ? .system(.caption, weight: .semibold) : SettingsTypography.body.weight(.semibold))
                Text(compressionTitle(for: level))
                    .font(compact ? .system(.caption, weight: .semibold) : SettingsTypography.body.weight(.semibold))
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .frame(height: compact ? 28 : 32)
            .foregroundStyle(selected ? Color.accentColor : Color.primary.opacity(0.78))
            .background(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(selected ? Color.accentColor.opacity(0.16) : PanelSurface.controlFill(for: colorScheme))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .strokeBorder(selected ? Color.accentColor.opacity(0.45) : PanelSurface.border(for: colorScheme),
                                  lineWidth: 0.8)
            )
        }
        .buttonStyle(.plain)
    }

    private func fpsSliderRow(value: Binding<Double>, range: ClosedRange<Double>) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(l10n.s.mediaFPS)
                    .font(compact ? .system(.caption, weight: .semibold) : SettingsTypography.body.weight(.semibold))
                Spacer()
                Text("\(Int(value.wrappedValue.rounded()))")
                    .font(compact ? .system(.caption, design: .monospaced) : SettingsTypography.body.monospaced())
                    .foregroundStyle(.secondary)
            }
            Slider(value: value, in: range, step: 1)
        }
    }

    private func numberField(_ label: String, value: Binding<Double>, suffix: String) -> some View {
        numberField(label, suffix: suffix) {
            TextField("", value: value, formatter: Self.decimalFormatter)
        }
    }

    private func integerField(_ label: String, value: Binding<Int>, suffix: String) -> some View {
        // Wider than the trim fields: this label is a phrase in most languages,
        // not a single word.
        numberField(label, suffix: suffix, labelWidth: compact ? 74 : 92) {
            TextField("", value: value, formatter: Self.megabytesFormatter)
        }
    }

    private func numberField<Field: View>(_ label: String,
                                          suffix: String,
                                          labelWidth: CGFloat? = nil,
                                          @ViewBuilder field: () -> Field) -> some View {
        HStack(spacing: 5) {
            Text(label)
                .font(compact ? .system(.caption, weight: .semibold) : SettingsTypography.body.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(width: labelWidth ?? (compact ? 48 : 62), alignment: .leading)
            field()
                .textFieldStyle(.plain)
                .font(compact ? .system(.body, design: .monospaced, weight: .medium) : SettingsTypography.body.weight(.medium).monospaced())
                .padding(.horizontal, 9)
                .frame(width: compact ? 62 : 76, height: compact ? 28 : 30, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(PanelSurface.controlFill(for: colorScheme))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .strokeBorder(PanelSurface.border(for: colorScheme), lineWidth: 0.8)
                )
            Text(suffix)
                .font(compact ? .system(size: 9.5) : SettingsTypography.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func stepperInt(_ label: String, value: Binding<Int>, range: ClosedRange<Int>,
                            step: Int, suffix: String) -> some View {
        Stepper(value: value, in: range, step: step) {
            HStack(spacing: 4) {
                Text(label)
                    .font(compact ? .system(.caption, weight: .semibold) : SettingsTypography.body.weight(.semibold))
                Spacer(minLength: 0)
                Text("\(value.wrappedValue)\(suffix)")
                    .font(compact ? .system(.caption, design: .monospaced) : SettingsTypography.body.monospaced())
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func stepperDouble(_ label: String,
                               value: Binding<Double>,
                               range: ClosedRange<Double>,
                               step: Double,
                               suffix: String,
                               display: @escaping (Double) -> String) -> some View {
        Stepper(value: value, in: range, step: step) {
            HStack(spacing: 4) {
                Text(label)
                    .font(compact ? .system(.caption, weight: .semibold) : SettingsTypography.body.weight(.semibold))
                Spacer(minLength: 0)
                Text("\(display(value.wrappedValue))\(suffix)")
                    .font(compact ? .system(.caption, design: .monospaced) : SettingsTypography.body.monospaced())
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var inputTitle: String {
        guard !inputURLs.isEmpty else { return l10n.s.mediaSelectFile }
        if selectedTool == .pdfMerger { return "\(inputURLs.count) PDF" }
        if selectedTool == .imageCompressor, inputURLs.count > 1 {
            return String(format: imageText.filesSelectedFormat, inputURLs.count)
        }
        return inputURLs[0].lastPathComponent
    }

    private var currentResizeMode: MediaImageResizeMode {
        MediaImageResizeMode(kind: MediaImageResizeKind.sanitized(imageResizeKindRaw),
                             maxDimension: imageMaxDimension,
                             width: imageResizeWidth,
                             height: imageResizeHeight,
                             exactMode: MediaImageExactResizeMode.sanitized(imageExactResizeModeRaw))
    }

    private var currentWatermarkKind: MediaImageWatermarkKind {
        MediaImageWatermarkKind.sanitized(imageWatermarkKindRaw)
    }

    private var currentWatermark: MediaImageWatermark {
        MediaImageWatermark(kind: currentWatermarkKind,
                            text: imageWatermarkText,
                            logoPath: imageWatermarkLogoPath,
                            position: MediaImageWatermarkPosition.sanitized(imageWatermarkPositionRaw),
                            opacity: imageWatermarkOpacity,
                            margin: imageWatermarkMargin,
                            scale: imageWatermarkScale)
    }

    private var currentImageOptions: MediaImageOptions {
        MediaImageOptions(quality: imageQuality,
                          maxDimension: imageMaxDimension,
                          format: MediaImageFormat.sanitized(imageFormatRaw),
                          stripMetadata: imageStripMetadata,
                          resizeMode: currentResizeMode,
                          watermark: currentWatermark,
                          renamePattern: MediaImageRenamePattern(imageRenamePattern),
                          background: MediaImageBackground.sanitized(imageBackgroundRaw),
                          preserveModificationDate: imagePreserveModificationDate)
    }

    private var imageProfiles: [MediaImageProfile] {
        guard let data = imageProfilesRaw.data(using: .utf8),
              let profiles = try? JSONDecoder().decode([MediaImageProfile].self, from: data) else {
            return []
        }
        return MediaSupport.sanitizedImageProfiles(profiles)
    }

    private var selectedImageProfile: MediaImageProfile? {
        guard !imageSelectedProfileID.isEmpty else { return nil }
        return imageProfiles.first { $0.id == imageSelectedProfileID }
    }

    private var imageProfileIsModified: Bool {
        guard let profile = selectedImageProfile else { return false }
        return profile.options != currentImageOptions
    }

    private var previewOutputName: String {
        guard let inputURL else { return l10n.s.mediaOutputAutomatic }
        if let outputURL { return outputURL.lastPathComponent }
        return defaultOutputURL(for: [inputURL], tool: .imageCompressor)?.lastPathComponent
            ?? l10n.s.mediaOutputAutomatic
    }

    private var previewOutputSize: CGSize {
        guard inputURL != nil, let sourceSize = inputImageSize else {
            return currentResizeMode.targetSize(for: CGSize(width: 1600, height: 1200))
        }
        return currentResizeMode.targetSize(for: sourceSize)
    }

    private var previewFrameSize: CGSize {
        let bounds = CGSize(width: compact ? 108 : 136, height: compact ? 74 : 92)
        let ratio = max(0.01, previewOutputSize.width / previewOutputSize.height)
        if ratio > bounds.width / bounds.height {
            return CGSize(width: bounds.width, height: max(1, bounds.width / ratio))
        }
        return CGSize(width: max(1, bounds.height * ratio), height: bounds.height)
    }

    private var previewWatermarkLogoSide: CGFloat {
        let side = min(previewFrameSize.width, previewFrameSize.height)
        return min(side, max(4, side * CGFloat(currentWatermark.scale)))
    }

    private var previewWatermarkMargin: CGFloat {
        let outputSide = max(1, min(previewOutputSize.width, previewOutputSize.height))
        let previewSide = min(previewFrameSize.width, previewFrameSize.height)
        return min(previewSide / 2, CGFloat(imageWatermarkMargin) * previewSide / outputSide)
    }

    private var previewAlignment: Alignment {
        switch MediaImageWatermarkPosition.sanitized(imageWatermarkPositionRaw) {
        case .topLeft: return .topLeading
        case .topRight: return .topTrailing
        case .center: return .center
        case .bottomLeft: return .bottomLeading
        case .bottomRight: return .bottomTrailing
        }
    }

    private var previewBackgroundColor: Color {
        if MediaImageFormat.sanitized(imageFormatRaw) == .jpeg
            || MediaImageFormat.sanitized(imageFormatRaw) == .pdf {
            return MediaImageBackground.sanitized(imageBackgroundRaw) == .black ? .black : .white
        }
        switch MediaImageBackground.sanitized(imageBackgroundRaw) {
        case .transparent:
            return Color.primary.opacity(0.045)
        case .white:
            return .white
        case .black:
            return .black
        }
    }

    private var actionTitle: String {
        switch selectedTool {
        case .videoCompressor: return l10n.s.mediaStartVideo
        case .gifMaker: return l10n.s.mediaStartGIF
        case .imageCompressor:
            // Choosing PDF changes the file's kind, so the button says what
            // will actually happen instead of promising compression.
            return MediaImageFormat.sanitized(imageFormatRaw) == .pdf
                ? l10n.s.mediaStartConvertPDF
                : l10n.s.mediaStartImage
        case .textExtractor: return l10n.s.mediaStartText
        case .pdfMerger: return pdfText.merge
        case .pdfCompressor: return pdfText.compress
        }
    }

    private func title(for tool: MediaTool) -> String {
        switch tool {
        case .videoCompressor: return l10n.s.mediaToolVideo
        case .gifMaker: return l10n.s.mediaToolGIF
        case .imageCompressor: return l10n.s.mediaToolImage
        case .textExtractor: return l10n.s.mediaToolText
        case .pdfMerger: return pdfText.title
        case .pdfCompressor: return pdfText.compressorTitle
        }
    }

    private func compressionTitle(for level: MediaCompressionLevel) -> String {
        switch level {
        case .low: return l10n.s.mediaCompressionLow
        case .medium: return l10n.s.mediaCompressionMedium
        case .high: return l10n.s.mediaCompressionHigh
        }
    }

    private func chooseInput(appending: Bool = false) {
        guard !isRunning else { return }
        inputRevision &+= 1
        let revision = inputRevision
        let tool = selectedTool
        let panel = NSOpenPanel()
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = MediaSupport.allowsMultipleInputs(for: tool)
        panel.allowedContentTypes = inputTypes
        Self.runPanelModal(panel) { response in
            if response == .OK, !isRunning, selectedTool == tool, inputRevision == revision {
                if appending { editPDFInputs(inputURLs + panel.urls) }
                else { setInputs(panel.urls) }
            }
        }
    }

    private func chooseOutput() {
        guard let inputURL, !isRunning else { return }
        if isPDFTool {
            let tool = selectedTool
            let panel = NSOpenPanel()
            panel.canChooseFiles = false
            panel.canChooseDirectories = true
            panel.allowsMultipleSelection = false
            panel.directoryURL = outputURL?.deletingLastPathComponent() ?? inputURL.deletingLastPathComponent()
            Self.runPanelModal(panel) { response in
                if response == .OK, let directory = panel.url, !isRunning, selectedTool == tool {
                    outputURL = pdfOutputURL(in: directory)
                    outputWasChosenManually = true
                    localMessage = nil
                }
            }
            return
        }
        if selectedTool == .imageCompressor, inputURLs.count > 1 {
            let panel = NSOpenPanel()
            panel.canChooseFiles = false
            panel.canChooseDirectories = true
            panel.allowsMultipleSelection = false
            panel.directoryURL = outputURL ?? inputURL.deletingLastPathComponent()
            Self.runPanelModal(panel) { response in
                if response == .OK, let url = panel.url {
                    outputURL = url
                    outputWasChosenManually = true
                }
            }
            return
        }
        let panel = NSSavePanel()
        panel.allowedContentTypes = [outputType]
        let fallback = defaultOutputURL(for: inputURLs, tool: selectedTool)
        panel.directoryURL = (outputURL ?? fallback)?.deletingLastPathComponent()
        panel.nameFieldStringValue = (outputURL ?? fallback)?.lastPathComponent ?? ""
        Self.runPanelModal(panel) { response in
            if response == .OK, let url = panel.url {
                outputURL = url
                outputWasChosenManually = true
            }
        }
    }

    /// The hosts of this view (menu popover, quick launcher) never activate
    /// the app, and a modal file dialog in an inactive app takes no clicks or
    /// keys (only Cancel reacts). Activate first and let the run loop turn so
    /// the activation lands before the modal session starts, then hand key
    /// focus back to the launcher.
    /// One dialog at a time: the modal now starts a run-loop turn after the
    /// click, so a double-click (or clicking both pickers quickly) would queue
    /// a second identical dialog behind the first without this guard.
    private static var panelModalActive = false

    private static func runPanelModal(_ panel: NSSavePanel,
                                      completion: @escaping (NSApplication.ModalResponse) -> Void) {
        guard !panelModalActive else { return }
        panelModalActive = true
        NSApp.activate(ignoringOtherApps: true)
        DispatchQueue.main.async {
            let response = panel.runModal()
            panelModalActive = false
            completion(response)
        }
    }

    private func acceptDrop(_ providers: [NSItemProvider]) -> Bool {
        let fileProviders = providers.filter { $0.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) }
        guard !isRunning else { return false }
        guard !fileProviders.isEmpty, fileProviders.count == providers.count else {
            rejectInputSelection()
            return false
        }
        inputRevision &+= 1
        let revision = inputRevision
        let tool = selectedTool
        let group = DispatchGroup()
        let lock = NSLock()
        var indexedURLs: [(offset: Int, url: URL)] = []
        for (offset, provider) in fileProviders.enumerated() {
            group.enter()
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
            let url: URL?
            if let itemURL = item as? URL {
                url = itemURL
            } else if let data = item as? Data {
                url = URL(dataRepresentation: data, relativeTo: nil)
            } else {
                url = nil
            }
                if let url {
                    lock.lock()
                    indexedURLs.append((offset, url))
                    lock.unlock()
                }
                group.leave()
            }
        }
        group.notify(queue: .main) {
            let urls = MediaSupport.urlsInProviderOrder(indexedURLs)
            guard inputRevision == revision, selectedTool == tool, !isRunning,
                  AppFeature.mediaTools.isAvailable else { return }
            guard urls.count == providers.count,
                  MediaInputSelectionSupport.validatedURLs(urls, for: tool) != nil else {
                rejectInputSelection()
                return
            }
            if tool == .pdfMerger { editPDFInputs(inputURLs + urls) }
            else { setInputs(urls) }
        }
        return true
    }

    private func setInput(_ url: URL) {
        setInputs([url])
    }

    private func setInputs(_ urls: [URL]) {
        guard !isRunning else { return }
        guard let accepted = MediaInputSelectionSupport.validatedURLs(urls, for: selectedTool) else {
            rejectInputSelection()
            return
        }
        guard selectedTool != .pdfMerger || accepted.count <= MediaPDFSupport.maximumInputs else {
            media.reset()
            localMessage = pdfText.tooMany
            return
        }
        inputRevision &+= 1
        cancelVideoImport()
        inputURLs = accepted
        refreshPDFInspection()
        inputImageSize = selectedTool == .imageCompressor
            ? inputURL.flatMap { MediaSupport.imageDisplaySize(at: $0) }
            : nil
        outputURL = defaultOutputURL(for: inputURLs, tool: selectedTool)
        outputWasChosenManually = false
        applyMediaDefaults(for: inputURL, tool: selectedTool)
        localMessage = nil
        media.reset()
    }

    private func cancelPDFInspection() {
        pdfInspectionGeneration &+= 1
        pdfInspectionTask?.cancel()
        pdfInspectionTask = nil
    }

    private func refreshPDFInspection() {
        cancelPDFInspection()
        pdfInspectionBatchError = nil
        guard isPDFTool, !inputURLs.isEmpty else {
            pdfPageCounts = [:]
            pdfInspectionErrors = [:]
            return
        }
        let urls = inputURLs
        let selected = Set(urls)
        pdfPageCounts = pdfPageCounts.filter { selected.contains($0.key) }
        pdfInspectionErrors = pdfInspectionErrors.filter { selected.contains($0.key) }
        let cached = Set(pdfPageCounts.keys).union(pdfInspectionErrors.keys)
        let generation = pdfInspectionGeneration
        pdfInspectionTask = Task.detached(priority: .utility) {
            do {
                try MediaPDFSupport.inspect(urls, cachedURLs: cached,
                    isCancelled: { Task.isCancelled }, inspected: { url, result in
                        DispatchQueue.main.async {
                            guard pdfInspectionGeneration == generation, isPDFTool else { return }
                            switch result {
                            case let .success(count):
                                pdfPageCounts[url] = count
                                pdfInspectionErrors.removeValue(forKey: url)
                            case let .failure(error):
                                pdfInspectionErrors[url] = error
                                pdfPageCounts.removeValue(forKey: url)
                            }
                        }
                    })
                guard !Task.isCancelled else { return }
                DispatchQueue.main.async {
                    guard pdfInspectionGeneration == generation, isPDFTool else { return }
                    let total = urls.reduce(0) { $0 + (pdfPageCounts[$1] ?? 0) }
                    if total > MediaPDFSupport.maximumPages { pdfInspectionBatchError = .tooManyPages }
                    pdfInspectionTask = nil
                }
            } catch {
                guard !Task.isCancelled else { return }
                let failure = (error as? MediaPDFError) ?? .verificationFailed
                DispatchQueue.main.async {
                    guard pdfInspectionGeneration == generation, isPDFTool else { return }
                    pdfInspectionBatchError = failure
                    pdfInspectionTask = nil
                }
            }
        }
    }

    private func rejectInputSelection() {
        media.reset()
        localMessage = selectedTool == .pdfCompressor ? pdfText.singleSelectionRejected
            : selectedTool == .pdfMerger ? pdfText.selectionRejected : l10n.s.mediaErrorUnsupported
    }

    private func movePDF(at index: Int, by delta: Int) {
        guard !isRunning, selectedTool == .pdfMerger,
              inputURLs.indices.contains(index), inputURLs.indices.contains(index + delta) else { return }
        var urls = inputURLs
        urls.swapAt(index, index + delta)
        editPDFInputs(urls)
    }

    private func removePDF(at index: Int) {
        guard !isRunning, selectedTool == .pdfMerger, inputURLs.indices.contains(index) else { return }
        var urls = inputURLs
        urls.remove(at: index)
        editPDFInputs(urls)
    }

    private func editPDFInputs(_ urls: [URL]) {
        let directory = outputWasChosenManually ? outputURL?.deletingLastPathComponent() : nil
        if urls.isEmpty { clearInput(); return }
        setInputs(urls)
        guard inputURLs == urls else { return }
        if let directory {
            outputURL = pdfOutputURL(in: directory)
            outputWasChosenManually = true
        }
    }

    private func pdfOutputURL(in directory: URL) -> URL? {
        guard let inputURL else { return nil }
        return MediaSupport.uniqueOutputURL(in: directory,
            baseName: MediaSupport.visibleOutputBaseName(for: inputURL)
                + (selectedTool == .pdfCompressor ? "-compressed" : "-merged"), fileExtension: "pdf")
    }

    private func clearInput() {
        guard !isRunning else { return }
        inputRevision &+= 1
        mediaDefaultsTask?.cancel()
        cancelVideoImport()
        inputURLs = []
        refreshPDFInspection()
        inputImageSize = nil
        outputURL = nil
        outputWasChosenManually = false
        localMessage = nil
        media.reset()
    }

    private func applyMediaDefaults(for url: URL?, tool: MediaTool) {
        mediaDefaultsTask?.cancel()
        guard let url, tool == .videoCompressor || tool == .gifMaker else { return }
        mediaDefaultsTask = Task {
            guard let duration = await Self.mediaDuration(for: url),
                  !Task.isCancelled else { return }
            await MainActor.run {
                guard inputURL == url, selectedTool == tool else { return }
                switch tool {
                case .videoCompressor:
                    videoStart = 0
                    videoEnd = duration
                case .gifMaker:
                    gifStart = 0
                    gifEnd = duration
                case .imageCompressor, .textExtractor, .pdfMerger, .pdfCompressor:
                    break
                }
            }
        }
    }

    private static func mediaDuration(for url: URL) async -> Double? {
        guard let duration = try? await AVURLAsset(url: url).load(.duration).seconds else { return nil }
        guard duration.isFinite, duration > 0 else { return nil }
        return (duration * 10).rounded() / 10
    }

    @MainActor
    private func openVideoEditor() {
        guard AppFeature.mediaTools.isAvailable, let url = inputURL,
              !isImportingVideo else { return }
        cancelVideoImport()
        videoImportGeneration &+= 1
        let generation = videoImportGeneration
        isImportingVideo = true
        localMessage = nil
        videoImportTask = Task { @MainActor in
            let asset = AVURLAsset(url: url)
            let hasVideo = ((try? await asset.loadTracks(withMediaType: .video)) ?? []).isEmpty == false
            guard !Task.isCancelled, videoImportGeneration == generation,
                  inputURL == url, selectedTool == .videoCompressor,
                  AppFeature.mediaTools.isAvailable else { return }
            guard hasVideo else {
                isImportingVideo = false
                videoImportTask = nil
                localMessage = l10n.s.mediaErrorNoVideo
                return
            }
            let take = await Task.detached(priority: .userInitiated) {
                RecorderTakeStore.shared.importVideo(at: url)
            }.value
            guard !Task.isCancelled, videoImportGeneration == generation,
                  inputURL == url, selectedTool == .videoCompressor,
                  AppFeature.mediaTools.isAvailable else {
                if let take { RecorderTakeStore.shared.delete(take) }
                return
            }
            isImportingVideo = false
            videoImportTask = nil
            guard let take else {
                localMessage = l10n.s.mediaErrorUnsupported
                return
            }
            if !ScreenRecorderService.shared.openEditor(with: take, owner: .mediaTools) {
                RecorderTakeStore.shared.delete(take)
            }
        }
    }

    @MainActor
    private func cancelVideoImport() {
        videoImportGeneration &+= 1
        videoImportTask?.cancel()
        videoImportTask = nil
        isImportingVideo = false
    }

    private func run() {
        guard !isRunning else { return }
        inputRevision &+= 1
        guard MediaInputSelectionSupport.validatedURLs(inputURLs, for: selectedTool) != nil else {
            rejectInputSelection()
            return
        }
        if selectedTool == .pdfMerger, inputURLs.count < 2 {
            media.reset()
            localMessage = pdfText.tooFew
            return
        }
        guard let inputURL, !inputURLs.isEmpty else {
            localMessage = l10n.s.mediaErrorNoFile
            return
        }
        let outputURL = outputURL ?? defaultOutputURL(for: inputURLs, tool: selectedTool)
        guard let outputURL else {
            localMessage = l10n.s.mediaErrorNoFile
            return
        }
        if isPDFTool {
            if inputURLs.contains(where: { MediaSupport.fileURLsReferToSameItem($0, outputURL) }) {
                media.reset()
                localMessage = l10n.s.mediaErrorSameOutput
                return
            }
            if FileManager.default.fileExists(atPath: outputURL.path) {
                media.reset()
                localMessage = pdfText.outputExists
                return
            }
        }
        self.outputURL = outputURL
        localMessage = nil
        switch selectedTool {
        case .videoCompressor:
            media.compressVideo(inputURL: inputURL, outputURL: outputURL,
                                options: MediaVideoOptions(start: videoStart,
                                                           end: videoEnd,
                                                           quality: videoQuality,
                                                           maxDimension: videoMaxDimension,
                                                           fps: 30,
                                                           keepAudio: true,
                                                           codec: .h264,
                                                           sizing: videoSizing,
                                                           targetBytes: MediaSupport.targetBytes(
                                                               megabytes: videoTargetMegabytes)))
        case .gifMaker:
            media.makeGIF(inputURL: inputURL, outputURL: outputURL,
                          options: MediaGIFOptions(start: gifStart,
                                                   end: gifEnd,
                                                   quality: 0.74,
                                                   width: gifWidth,
                                                   fps: gifFPS,
                                                   loops: gifLoops,
                                                   sizing: gifSizing,
                                                   targetBytes: MediaSupport.targetBytes(
                                                       megabytes: gifTargetMegabytes)))
        case .imageCompressor:
            if inputURLs.count > 1 {
                let outputDirectory = imageSaveInSubfolder
                    ? outputURL.appendingPathComponent(Self.imageOutputSubfolderName,
                                                       isDirectory: true)
                    : outputURL
                media.processImages(inputURLs: inputURLs,
                                    outputDirectory: outputDirectory,
                                    options: currentImageOptions)
            } else {
                media.compressImage(inputURL: inputURL,
                                    outputURL: outputURL,
                                    options: currentImageOptions)
            }
        case .pdfMerger:
            media.mergePDFs(inputURLs: inputURLs, outputURL: outputURL)
        case .pdfCompressor:
            media.compressPDF(inputURL: inputURL, outputURL: outputURL, mode: pdfCompressionMode)
        case .textExtractor:
            media.extractText(inputURL: inputURL, outputURL: outputURL,
                              options: MediaTextOptions(accurate: textAccurate,
                                                        languageCorrection: true,
                                                        recognitionLanguages: MediaSupport.recognitionLanguages(for: l10n.language.rawValue)))
        }
    }

    private var inputTypes: [UTType] {
        MediaSupport.inputTypes(for: selectedTool)
    }

    private var outputType: UTType {
        switch selectedTool {
        case .videoCompressor: return .mpeg4Movie
        case .gifMaker: return .gif
        case .imageCompressor:
            switch MediaImageFormat.sanitized(imageFormatRaw) {
            case .jpeg: return .jpeg
            case .heic: return .heic
            case .png: return .png
            case .pdf: return .pdf
            }
        case .textExtractor: return .plainText
        case .pdfMerger, .pdfCompressor: return .pdf
        }
    }

    private func defaultOutputURL(for inputURLs: [URL], tool: MediaTool) -> URL? {
        guard let inputURL = inputURLs.first else { return nil }
        switch tool {
        case .videoCompressor:
            return MediaSupport.uniqueOutputURL(for: inputURL, suffix: "-compressed", fileExtension: "mp4")
        case .gifMaker:
            return MediaSupport.uniqueOutputURL(for: inputURL, suffix: "", fileExtension: "gif")
        case .imageCompressor:
            if inputURLs.count > 1 {
                return inputURL.deletingLastPathComponent()
            }
            let sourceSize = inputImageSize ?? CGSize(width: 1600, height: 1200)
            return MediaSupport.imageOutputURL(for: inputURL,
                                               outputDirectory: inputURL.deletingLastPathComponent(),
                                               options: currentImageOptions,
                                               index: 1,
                                               outputSize: currentResizeMode.targetSize(for: sourceSize))
        case .pdfCompressor:
            return MediaSupport.uniqueOutputURL(for: inputURL, suffix: "-compressed", fileExtension: "pdf")
        case .pdfMerger:
            return MediaSupport.uniqueOutputURL(for: inputURL, suffix: "-merged", fileExtension: "pdf")
        case .textExtractor:
            return MediaSupport.uniqueOutputURL(for: inputURL, suffix: "-text", fileExtension: "txt")
        }
    }

    private func message(for failure: MediaFailure) -> String {
        switch failure {
        case let .pdf(error): return message(for: error)
        case .noInput: return l10n.s.mediaErrorNoFile
        case .noVideoTrack: return l10n.s.mediaErrorNoVideo
        case .sameOutput: return l10n.s.mediaErrorSameOutput
        case .unsupported: return l10n.s.mediaErrorUnsupported
        case .imageTooLarge: return imageText.tooLarge
        case let .gifTooLong(maxSeconds):
            return String(format: FeatureStrings.recorder(l10n.language).gifTooLongFormat,
                          maxSeconds)
        case .targetTooSmall: return l10n.s.mediaErrorTargetTooSmall
        case .watermarkUnavailable: return imageText.noLogo
        case .cancelled: return l10n.s.mediaCancelled
        case let .failed(message): return message.isEmpty ? l10n.s.mediaErrorUnsupported : message
        }
    }

    private func message(for error: MediaPDFError) -> String {
        switch error {
        case .unsupportedStructure: return pdfText.unsupportedStructure
        case .tooFewInputs: return pdfText.tooFew
        case .tooManyInputs: return pdfText.tooMany
        case .inputTooLarge: return pdfText.tooLarge
        case .tooManyPages: return pdfText.tooManyPages
        case .cancelled: return l10n.s.mediaCancelled
        case .sameOutput: return l10n.s.mediaErrorSameOutput
        case .outputExists: return pdfText.outputExists
        case .writeFailed: return pdfText.writeFailed
        case .verificationFailed: return pdfText.verificationFailed
        case let .unreadable(name): return pdfText.unreadable + name
        case let .invalidDocument(name): return pdfText.invalid + name
        case let .encryptedDocument(name): return pdfText.encrypted + name
        case let .emptyDocument(name): return pdfText.empty + name
        }
    }

    private func chooseWatermarkLogo() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [.image]
        Self.runPanelModal(panel) { response in
            if response == .OK, let url = panel.url {
                imageWatermarkLogoPath = url.path
            }
        }
    }

    private func updateSelectedProfile() {
        var profiles = imageProfiles
        let trimmed = profileName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !imageSelectedProfileID.isEmpty,
              let index = profiles.firstIndex(where: { $0.id == imageSelectedProfileID }) else { return }
        let name = trimmed.isEmpty ? profiles[index].name : trimmed
        profiles[index] = MediaImageProfile(id: profiles[index].id, name: name, options: currentImageOptions)
        profileName = ""
        saveImageProfiles(profiles)
    }

    private func saveNewProfile() {
        var profiles = imageProfiles
        let trimmed = profileName.trimmingCharacters(in: .whitespacesAndNewlines)
        let name = trimmed.isEmpty ? String(format: imageText.profileDefaultNameFormat, profiles.count + 1) : trimmed
        let profile = MediaImageProfile(name: name, options: currentImageOptions)
        profiles.append(profile)
        imageSelectedProfileID = profile.id
        profileName = ""
        saveImageProfiles(profiles)
    }

    private func deleteSelectedProfile() {
        guard !imageSelectedProfileID.isEmpty else { return }
        var profiles = imageProfiles
        profiles.removeAll { $0.id == imageSelectedProfileID }
        imageSelectedProfileID = ""
        saveImageProfiles(profiles)
    }

    private func saveImageProfiles(_ profiles: [MediaImageProfile]) {
        let cleanProfiles = MediaSupport.sanitizedImageProfiles(profiles)
        guard let data = try? JSONEncoder().encode(cleanProfiles),
              let raw = String(data: data, encoding: .utf8) else { return }
        imageProfilesRaw = raw
    }

    private func applyImageOptions(_ options: MediaImageOptions) {
        imageQuality = options.quality
        // Older profiles can carry the previously clamped legacy field;
        // resizeMode remains authoritative for the value the user selected.
        imageMaxDimension = options.resizeMode.maxDimension
        imageFormatRaw = options.format.rawValue
        imageStripMetadata = options.stripMetadata
        imageResizeKindRaw = options.resizeMode.kind.rawValue
        imageResizeWidth = options.resizeMode.width
        imageResizeHeight = options.resizeMode.height
        imageExactResizeModeRaw = options.resizeMode.exactMode.rawValue
        imageWatermarkKindRaw = options.watermark.kind.rawValue
        imageWatermarkText = options.watermark.text
        imageWatermarkLogoPath = options.watermark.logoPath
        imageWatermarkPositionRaw = options.watermark.position.rawValue
        imageWatermarkOpacity = options.watermark.opacity
        imageWatermarkMargin = options.watermark.margin
        imageWatermarkScale = options.watermark.scale
        imageRenamePattern = options.renamePattern.rawValue
        imageBackgroundRaw = options.background.rawValue
        imagePreserveModificationDate = options.preserveModificationDate
    }

    private func copy(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }

    /// A size target is typed rather than stepped, so the formatter is what
    /// keeps it a whole number the planner can work with.
    private static let megabytesFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .none
        formatter.allowsFloats = false
        formatter.minimum = NSNumber(value: MediaSupport.minimumTargetMegabytes)
        formatter.maximum = NSNumber(value: MediaSupport.maximumTargetMegabytes)
        return formatter
    }()

    private static let decimalFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 1
        formatter.minimum = 0
        return formatter
    }()
}

private extension View {
    @ViewBuilder
    func mediaWorkspaceSurface(compact: Bool, settings: Bool = true) -> some View {
        if compact { panelCard() }
        else if settings { settingsSurface() }
        else { self }
    }

    @ViewBuilder
    func mediaWorkspacePrimaryAction(compact: Bool) -> some View {
        if compact { buttonStyle(.borderedProminent) }
        else { settingsAction(.primary) }
    }
}
