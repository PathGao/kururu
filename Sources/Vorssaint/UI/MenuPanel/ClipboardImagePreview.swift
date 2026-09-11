// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import SwiftUI
import QuickLook

struct ClipboardImagePreview: View {
    let url: URL?
    let thumbnail: NSImage?
    let dimensions: String
    let copyText: (String) -> Void
    @ObservedObject private var l10n = L10n.shared
    @State private var quickLookURL: URL?
    @State private var recognizedText: String?
    @State private var message: String?
    @State private var reading = false
    @State private var requestID = UUID()
    @State private var task: Task<Void, Never>?

    private var chinese: Bool { l10n.language == .zhHans }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let thumbnail {
                Button { quickLookURL = url } label: {
                    Image(nsImage: thumbnail)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity, maxHeight: 180)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
                .disabled(url == nil)
                .accessibilityLabel(chinese ? "放大查看图片" : "View full image")
            } else {
                Label(chinese ? "图片预览不可用" : "Image preview unavailable", systemImage: "photo.badge.exclamationmark")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text(dimensions).font(.caption2).foregroundStyle(.secondary)
            HStack {
                Button(chinese ? "放大查看" : "View full image") { quickLookURL = url }
                    .disabled(url == nil)
                Spacer()
                if reading {
                    ProgressView().controlSize(.mini)
                    Button(chinese ? "取消" : "Cancel", action: cancel)
                } else {
                    Button(chinese ? "识别文字" : "Recognize text", action: recognize)
                        .disabled(url == nil)
                }
            }
            .controlSize(.small)
            if let message {
                Text(message).font(.caption).foregroundStyle(.secondary)
            }
            if let recognizedText, !recognizedText.isEmpty {
                HStack {
                    Text(chinese ? "图片中的文字" : "Text in image").font(.caption)
                    Spacer()
                    Button(ClipboardActionStrings.copyRecognized) { copyText(recognizedText) }
                        .controlSize(.small)
                }
                ClipboardTextPreview(text: recognizedText)
                    .frame(minHeight: 120, maxHeight: .infinity)
            } else {
                Spacer(minLength: 0)
            }
        }
        .padding(12)
        .quickLookPreview($quickLookURL)
        .onChange(of: url) { _, _ in
            cancel()
            recognizedText = nil
            message = nil
            quickLookURL = nil
        }
        .onDisappear(perform: cancel)
    }

    private func cancel() {
        requestID = UUID()
        task?.cancel()
        task = nil
        reading = false
    }

    private func recognize() {
        guard let url, !reading else { return }
        let id = UUID()
        requestID = id
        reading = true
        message = nil
        task = Task { @MainActor in
            do {
                let result = try await ClipboardImageOCRService.recognize(url: url)
                guard !Task.isCancelled, requestID == id else { return }
                recognizedText = result
                if result.isEmpty { message = chinese ? "没有识别到文字。" : "No text was found." }
            } catch is CancellationError {
            } catch {
                guard !Task.isCancelled, requestID == id else { return }
                if let failure = error as? ClipboardImageOCRError, case .tooLarge = failure {
                    message = chinese ? "图片过大，无法识别文字。" : "This image is too large to recognize."
                } else {
                    message = chinese ? "无法识别文字，请检查图片后重试。" : "Could not recognize text. Check the image and try again."
                }
            }
            guard requestID == id else { return }
            reading = false
            task = nil
        }
    }
}
