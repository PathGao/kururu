// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import Foundation
import ImageIO

enum ClipboardImageOCRError: Error {
    case unreadable, tooLarge, recognitionFailed
}

enum ClipboardImageOCRService {
    private actor Worker {
        func recognize(url: URL, languages: [String]) throws -> String {
            try ClipboardImageOCRService.recognize(url: url, languages: languages)
        }
    }
    private static let worker = Worker()

    static func recognize(url: URL) async throws -> String {
        let languages = await MainActor.run {
            MediaSupport.recognitionLanguages(for: L10n.shared.language.rawValue)
        }
        let worker = Task.detached(priority: .userInitiated) {
            try await Self.worker.recognize(url: url, languages: languages)
        }
        return try await withTaskCancellationHandler {
            let text = try await worker.value
            try Task.checkCancellation()
            return text
        } onCancel: { worker.cancel() }
    }

    static func recognize(url: URL, languages: [String]) throws -> String {
        try Task.checkCancellation()
        guard url.isFileURL,
              let values = try? url.resourceValues(forKeys: [.isRegularFileKey, .isSymbolicLinkKey, .fileSizeKey]),
              values.isRegularFile == true, values.isSymbolicLink != true,
              let size = values.fileSize else { throw ClipboardImageOCRError.unreadable }
        guard size <= ClipboardImportSupport.maximumImageBytes else { throw ClipboardImageOCRError.tooLarge }
        let data: Data
        do {
            let handle = try FileHandle(forReadingFrom: url)
            defer { try? handle.close() }
            data = try handle.read(upToCount: ClipboardImportSupport.maximumImageBytes + 1) ?? Data()
        } catch { throw ClipboardImageOCRError.unreadable }
        guard data.count <= ClipboardImportSupport.maximumImageBytes else { throw ClipboardImageOCRError.tooLarge }
        try Task.checkCancellation()
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
              let width = properties[kCGImagePropertyPixelWidth] as? Int,
              let height = properties[kCGImagePropertyPixelHeight] as? Int,
              width > 0, height > 0 else { throw ClipboardImageOCRError.unreadable }
        guard width <= ClipboardImportSupport.maximumImagePixels / height else { throw ClipboardImageOCRError.tooLarge }
        // Normalize orientation without enlarging the original or decoding animation frames.
        let options = [kCGImageSourceCreateThumbnailFromImageAlways: true,
                       kCGImageSourceCreateThumbnailWithTransform: true,
                       kCGImageSourceThumbnailMaxPixelSize: max(width, height)] as CFDictionary
        guard let image = CGImageSourceCreateThumbnailAtIndex(source, 0, options) else {
            throw ClipboardImageOCRError.unreadable
        }
        do { return try ScreenTextService.recognizedText(in: image, fallbackLanguages: languages) }
        catch is CancellationError { throw CancellationError() }
        catch { throw ClipboardImageOCRError.recognitionFailed }
    }
}
