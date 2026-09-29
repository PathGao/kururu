// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation
import UniformTypeIdentifiers

enum MediaPDFSelectionTests {
    static func run(_ expect: (Bool, String) -> Void) {
        let first = URL(fileURLWithPath: "/first.pdf")
        let second = URL(fileURLWithPath: "/second.pdf")
        let image = URL(fileURLWithPath: "/picture.png")
        func type(_ url: URL) -> UTType? { url.pathExtension == "pdf" ? .pdf : .png }
        expect(MediaInputSelectionSupport.validatedURLs([second, first], for: .pdfMerger, contentType: type)
               == [second, first], "PDF selection preserves all files and their requested order")
        expect(MediaInputSelectionSupport.validatedURLs([first, image], for: .pdfMerger, contentType: type) == nil,
               "mixed PDF batches are rejected whole instead of silently dropping a file")
        expect(MediaInputSelectionSupport.validatedURLs([first], for: .imageCompressor, contentType: type) == nil,
               "switching a PDF input to image processing cannot rasterize just its first page")
        expect(MediaInputSelectionSupport.validatedURLs([image, image], for: .textExtractor, contentType: type) == nil,
               "switching multiple images to a single-file tool never truncates the batch")
        expect(MediaInputSelectionSupport.validatedURLs([first], for: .pdfMerger, contentType: type) == [first],
               "one selected PDF can be kept while another is added")
        expect(MediaInputSelectionSupport.validatedURLs([], for: .pdfMerger, contentType: type) == nil,
               "an empty selection is not an accepted batch")
        expect(MediaInputSelectionSupport.validatedURLs([first], for: .pdfMerger, contentType: { _ in nil }) == nil,
               "unknown file types are rejected")
        expect(MediaInputSelectionSupport.validatedURLs([URL(string: "https://example.test/file.pdf")!],
               for: .pdfMerger, contentType: { _ in .pdf }) == nil, "remote URLs cannot become local PDF inputs")
        expect(MediaInputSelectionSupport.validatedURLs([first, first], for: .pdfMerger, contentType: type) == [first, first],
               "repeating a PDF intentionally repeats its pages without deduplicating input")
    }
}
