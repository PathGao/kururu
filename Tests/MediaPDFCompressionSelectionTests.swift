// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation
import UniformTypeIdentifiers

enum MediaPDFCompressionSelectionTests {
    static func run(_ expect: (Bool, String) -> Void) {
        let first = URL(fileURLWithPath: "/first.pdf")
        let second = URL(fileURLWithPath: "/second.pdf")
        let picture = URL(fileURLWithPath: "/picture.png")
        func type(_ url: URL) -> UTType? { url.pathExtension == "pdf" ? .pdf : .png }
        expect(MediaInputSelectionSupport.validatedURLs([first], for: .pdfCompressor, contentType: type) == [first],
               "PDF compression accepts exactly one local PDF")
        expect(MediaInputSelectionSupport.validatedURLs([first, second], for: .pdfCompressor, contentType: type) == nil,
               "Switching a merge batch to compression rejects the whole batch instead of truncating it")
        expect(MediaInputSelectionSupport.validatedURLs([first, picture], for: .pdfCompressor, contentType: type) == nil,
               "Compression rejects mixed dropped files without silently filtering")
        expect(MediaInputSelectionSupport.validatedURLs([picture], for: .pdfCompressor, contentType: type) == nil,
               "Switching image input to PDF compression requires a new input")
        expect(MediaInputSelectionSupport.validatedURLs([first], for: .imageCompressor, contentType: type) == nil,
               "Switching PDF compression to an image tool cannot rasterize the first page")
        expect(MediaInputSelectionSupport.validatedURLs([first], for: .pdfMerger, contentType: type) == [first],
               "A single compression PDF can seed a merge selection while another PDF is added")
        expect(MediaInputSelectionSupport.validatedURLs([second, first], for: .pdfMerger, contentType: type) == [second, first],
               "Adding the single-PDF tool preserves merge multi-selection and ordering")
        expect(MediaInputSelectionSupport.validatedURLs([], for: .pdfCompressor, contentType: type) == nil,
               "Compression does not accept an empty selection")
        expect(MediaInputSelectionSupport.validatedURLs([first], for: .pdfCompressor, contentType: { _ in nil }) == nil,
               "Compression refuses an unknown content type")
        expect(MediaInputSelectionSupport.validatedURLs([URL(string: "https://example.test/file.pdf")!],
               for: .pdfCompressor, contentType: { _ in .pdf }) == nil,
               "Compression only accepts local file URLs")
    }
}
