// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import Foundation
import Quartz
import Darwin

enum MediaPDFError: Error, Equatable {
    case tooFewInputs, tooManyInputs, inputTooLarge, tooManyPages
    case unreadable(String), invalidDocument(String), encryptedDocument(String), emptyDocument(String)
    case cancelled, sameOutput, outputExists, writeFailed, verificationFailed, unsupportedStructure
}

enum MediaPDFCompressionMode: String, CaseIterable {
    case preserveResolution, screen
}

struct MediaPDFCompressionResult {
    let originalBytes: Int64
    let outputBytes: Int64
    let didCompress: Bool
}

enum MediaPDFSupport {
    static let maximumInputs = 100
    static let maximumInputBytes = 256 * 1024 * 1024
    static let maximumPages = 1000

    static func compress(_ input: URL, to stagedURL: URL, mode: MediaPDFCompressionMode,
                         isCancelled: () -> Bool = { false }) throws -> MediaPDFCompressionResult {
        func checkCancelled() throws { if isCancelled() { throw MediaPDFError.cancelled } }
        try checkCancelled()
        guard stagedURL.isFileURL else { throw MediaPDFError.writeFailed }
        guard !MediaSupport.fileURLsReferToSameItem(input, stagedURL) else { throw MediaPDFError.sameOutput }
        guard !FileManager.default.fileExists(atPath: stagedURL.path) else { throw MediaPDFError.outputExists }
        var bytes = 0
        let document = try loadDocument(input, bytes: &bytes, isCancelled: isCancelled)
        guard document.pageCount <= maximumPages else { throw MediaPDFError.tooManyPages }
        try checkCompressibleStructure(document)
        let hasTransparency = try checkImageResources(document, isCancelled: isCancelled)
        let expected = try compressionSnapshot(document, isCancelled: isCancelled)
        // Use Preview's Quartz export path: PDFKit's image options can leave existing streams unchanged.
        var imageSettings: [String: Any] = [:]
        if !hasTransparency {
            imageSettings["ImageCompression"] = "ImageJPEGCompress"
            imageSettings["Compression Quality"] = 0.8
        }
        if mode == .screen {
            imageSettings["ImageScaleSettings"] = ["ImageResolution": 144, "ImageScaleInterpolate": true,
                                                   "ImageSizeMax": 2400, "ImageSizeMin": 0]
        }
        guard let filter = QuartzFilter(properties: ["FilterType": 1, "Name": "PDF Compression",
            "FilterData": ["ColorSettings": ["ImageSettings": imageSettings]]]) else { throw MediaPDFError.writeFailed }
        let options: [PDFDocumentWriteOption: Any] = [PDFDocumentWriteOption(rawValue: "QuartzFilter"): filter]
        try checkCancelled()
        guard let data = document.dataRepresentation(options: options) else { throw MediaPDFError.writeFailed }
        try checkCancelled()
        guard data.count < bytes else {
            return MediaPDFCompressionResult(originalBytes: Int64(bytes), outputBytes: Int64(bytes), didCompress: false)
        }
        try writeExclusive(data, to: stagedURL)
        var succeeded = false
        defer { if !succeeded { try? FileManager.default.removeItem(at: stagedURL) } }
        try checkCancelled()
        guard let saved = PDFDocument(url: stagedURL), !saved.isEncrypted,
              try compressionSnapshot(saved, isCancelled: isCancelled).isEqual(expected) else {
            throw MediaPDFError.verificationFailed
        }
        try checkCancelled()
        succeeded = true
        return MediaPDFCompressionResult(originalBytes: Int64(bytes), outputBytes: Int64(data.count), didCompress: true)
    }

    private static func writeExclusive(_ data: Data, to url: URL) throws {
        let descriptor = url.withUnsafeFileSystemRepresentation { path in
            path.map { open($0, O_WRONLY | O_CREAT | O_EXCL, S_IRUSR | S_IWUSR) } ?? -1
        }
        guard descriptor >= 0 else { throw errno == EEXIST ? MediaPDFError.outputExists : MediaPDFError.writeFailed }
        do {
            let handle = FileHandle(fileDescriptor: descriptor, closeOnDealloc: true)
            defer { try? handle.close() }
            try handle.write(contentsOf: data)
            try handle.synchronize()
        } catch {
            try? FileManager.default.removeItem(at: url)
            throw MediaPDFError.writeFailed
        }
    }

    private static func checkCompressibleStructure(_ document: PDFDocument) throws {
        guard let catalog = document.documentRef?.catalog else { throw MediaPDFError.invalidDocument("") }
        func has(_ dictionary: CGPDFDictionaryRef, _ key: String) -> Bool {
            var object: CGPDFObjectRef?
            return CGPDFDictionaryGetObject(dictionary, key, &object)
        }
        func dictionary(_ parent: CGPDFDictionaryRef, _ key: String) -> CGPDFDictionaryRef? {
            var result: CGPDFDictionaryRef?
            CGPDFDictionaryGetDictionary(parent, key, &result)
            return result
        }
        // These structures have semantics beyond page content that PDFKit's
        // image rewrite cannot verify. Ordinary named destinations remain valid.
        for key in ["AcroForm", "Perms", "DSS", "StructTreeRoot", "Collection", "AF", "OCProperties", "AA"] {
            if has(catalog, key) { throw MediaPDFError.unsupportedStructure }
        }
        if let mark = dictionary(catalog, "MarkInfo") {
            var marked = CGPDFBoolean(0)
            if CGPDFDictionaryGetBoolean(mark, "Marked", &marked), marked != 0 { throw MediaPDFError.unsupportedStructure }
        }
        if let names = dictionary(catalog, "Names"), has(names, "EmbeddedFiles") || has(names, "JavaScript") {
            throw MediaPDFError.unsupportedStructure
        }
        for index in 0..<document.pageCount {
            guard let page = document.page(at: index), let raw = page.pageRef?.dictionary else { throw MediaPDFError.verificationFailed }
            if has(raw, "AF") || has(raw, "AA") { throw MediaPDFError.unsupportedStructure }
            var annotations: CGPDFArrayRef?
            if CGPDFDictionaryGetArray(raw, "Annots", &annotations), let annotations {
                for annotationIndex in 0..<CGPDFArrayGetCount(annotations) {
                    var annotation: CGPDFDictionaryRef?
                    guard CGPDFArrayGetDictionary(annotations, annotationIndex, &annotation), let annotation else { throw MediaPDFError.unsupportedStructure }
                    if has(annotation, "AA") || has(annotation, "AF") { throw MediaPDFError.unsupportedStructure }
                    if let action = dictionary(annotation, "A") {
                        var type: UnsafePointer<CChar>?
                        guard CGPDFDictionaryGetName(action, "S", &type), let type,
                              ["URI", "GoTo"].contains(String(cString: type)), !has(action, "Next") else { throw MediaPDFError.unsupportedStructure }
                    }
                }
            }
            for annotation in page.annotations {
                guard ["Text", "Link", "FreeText", "Line", "Square", "Circle", "Polygon", "PolyLine", "Highlight", "Underline", "Squiggly", "StrikeOut", "Stamp", "Caret", "Ink", "Popup"].contains(annotation.type ?? "") else {
                    throw MediaPDFError.unsupportedStructure
                }
            }
        }
    }

    /// Bound ordinary image and Form resources before PDFKit decodes pixels.
    /// Inline content-stream images are not represented by this resource tree.
    private static func checkImageResources(_ document: PDFDocument, isCancelled: () -> Bool) throws -> Bool {
        var hasTransparency = false
        var visited = Set<CGPDFStreamRef>()
        var visits = 0
        func visit(_ stream: CGPDFStreamRef, depth: Int) throws {
            guard !isCancelled() else { throw MediaPDFError.cancelled }
            guard visited.insert(stream).inserted else { return }
            guard depth <= 16, visits < 4096 else { throw MediaPDFError.unsupportedStructure }
            visits += 1
            guard let dictionary = CGPDFStreamGetDictionary(stream) else { throw MediaPDFError.unsupportedStructure }
            var subtype: UnsafePointer<CChar>?
            guard CGPDFDictionaryGetName(dictionary, "Subtype", &subtype), let subtype else { throw MediaPDFError.unsupportedStructure }
            switch String(cString: subtype) {
            case "Image":
                var width: CGPDFInteger = 0, height: CGPDFInteger = 0
                var mask: CGPDFObjectRef?
                if CGPDFDictionaryGetObject(dictionary, "SMask", &mask) || CGPDFDictionaryGetObject(dictionary, "Mask", &mask) { hasTransparency = true }
                var imageMask = CGPDFBoolean(0)
                if CGPDFDictionaryGetBoolean(dictionary, "ImageMask", &imageMask), imageMask != 0 { hasTransparency = true }
                for key in ["SMask", "Mask"] {
                    var stream: CGPDFStreamRef?
                    if CGPDFDictionaryGetStream(dictionary, key, &stream), let stream { try visit(stream, depth: depth + 1) }
                }
                guard CGPDFDictionaryGetInteger(dictionary, "Width", &width), width > 0,
                      CGPDFDictionaryGetInteger(dictionary, "Height", &height), height > 0,
                      MediaSupport.imageRenderSizeIsSafe(CGSize(width: width, height: height)) else { throw MediaPDFError.unsupportedStructure }
            case "Form":
                var group: CGPDFDictionaryRef?
                if CGPDFDictionaryGetDictionary(dictionary, "Group", &group), let group {
                    var kind: UnsafePointer<CChar>?
                    if CGPDFDictionaryGetName(group, "S", &kind), let kind, String(cString: kind) == "Transparency" { hasTransparency = true }
                }
                var resources: CGPDFDictionaryRef?
                if CGPDFDictionaryGetDictionary(dictionary, "Resources", &resources), let resources { try walk(resources, depth: depth + 1) }
            default: throw MediaPDFError.unsupportedStructure
            }
        }
        func walk(_ resources: CGPDFDictionaryRef, depth: Int) throws {
            var failure: Error?
            var states: CGPDFDictionaryRef?
            if CGPDFDictionaryGetDictionary(resources, "ExtGState", &states), let states {
                CGPDFDictionaryApplyBlock(states, { _, object, _ in
                    var state: CGPDFDictionaryRef?
                    if CGPDFObjectGetValue(object, .dictionary, &state), let state {
                        var mask: CGPDFDictionaryRef?
                        if CGPDFDictionaryGetDictionary(state, "SMask", &mask), let mask {
                            hasTransparency = true
                            var group: CGPDFStreamRef?
                            if CGPDFDictionaryGetStream(mask, "G", &group), let group {
                                do { try visit(group, depth: depth + 1) }
                                catch { failure = error; return false }
                            }
                        }
                    }
                    return true
                }, nil)
            }
            if let failure { throw failure }
            var xobjects: CGPDFDictionaryRef?
            guard CGPDFDictionaryGetDictionary(resources, "XObject", &xobjects), let xobjects else { return }
            CGPDFDictionaryApplyBlock(xobjects, { _, object, _ in
                var stream: CGPDFStreamRef?
                guard CGPDFObjectGetValue(object, .stream, &stream), let stream else { failure = MediaPDFError.unsupportedStructure; return false }
                do { try visit(stream, depth: depth) }
                catch { failure = error; return false }
                return true
            }, nil)
            if let failure { throw failure }
        }
        for index in 0..<document.pageCount {
            guard !isCancelled() else { throw MediaPDFError.cancelled }
            guard var dictionary = document.page(at: index)?.pageRef?.dictionary else { throw MediaPDFError.verificationFailed }
            // Resources can be inherited from the page tree.
            for depth in 0...16 {
                var resources: CGPDFDictionaryRef?
                if CGPDFDictionaryGetDictionary(dictionary, "Resources", &resources), let resources { try walk(resources, depth: 0); break }
                var parent: CGPDFDictionaryRef?
                guard CGPDFDictionaryGetDictionary(dictionary, "Parent", &parent), let parent else { break }
                guard depth < 16 else { throw MediaPDFError.unsupportedStructure }
                dictionary = parent
            }
        }
        return hasTransparency
    }

    private static func initialView(_ document: PDFDocument) throws -> [String] {
        guard let catalog = document.documentRef?.catalog else { throw MediaPDFError.verificationFailed }
        var object: CGPDFObjectRef?
        guard CGPDFDictionaryGetObject(catalog, "OpenAction", &object), var object else { return [] }
        var action: CGPDFDictionaryRef?
        if CGPDFObjectGetValue(object, .dictionary, &action), let action {
            var type: UnsafePointer<CChar>?
            var destination: CGPDFObjectRef?
            var next: CGPDFObjectRef?
            guard CGPDFDictionaryGetName(action, "S", &type), let type, String(cString: type) == "GoTo",
                  !CGPDFDictionaryGetObject(action, "Next", &next),
                  CGPDFDictionaryGetObject(action, "D", &destination), let destination else { throw MediaPDFError.unsupportedStructure }
            object = destination
        }
        func token(_ object: CGPDFObjectRef) throws -> String {
            var page: CGPDFDictionaryRef?
            if CGPDFObjectGetValue(object, .dictionary, &page), let page {
                guard let index = (0..<document.pageCount).first(where: { document.page(at: $0)?.pageRef?.dictionary == page }) else { throw MediaPDFError.unsupportedStructure }
                return "page:\(index)"
            }
            var number: CGPDFReal = 0
            if CGPDFObjectGetValue(object, .real, &number) { return "number:\(number)" }
            var integer: CGPDFInteger = 0
            if CGPDFObjectGetValue(object, .integer, &integer) { return "number:\(CGPDFReal(integer))" }
            var name: UnsafePointer<CChar>?
            if CGPDFObjectGetValue(object, .name, &name), let name { return "name:" + String(cString: name) }
            var string: CGPDFStringRef?
            if CGPDFObjectGetValue(object, .string, &string), let string, let text = CGPDFStringCopyTextString(string) { return "string:" + (text as String) }
            if CGPDFObjectGetType(object) == .null { return "null" }
            throw MediaPDFError.unsupportedStructure
        }
        var array: CGPDFArrayRef?
        guard CGPDFObjectGetValue(object, .array, &array), let array else { return [try token(object)] }
        guard CGPDFArrayGetCount(array) <= 8 else { throw MediaPDFError.unsupportedStructure }
        return try (0..<CGPDFArrayGetCount(array)).map { index in
            var item: CGPDFObjectRef?
            guard CGPDFArrayGetObject(array, index, &item), let item else { throw MediaPDFError.unsupportedStructure }
            return try token(item)
        }
    }

    private static func compressionSnapshot(_ document: PDFDocument, isCancelled: () -> Bool) throws -> NSDictionary {
        var pages: [[String: Any]] = []
        for index in 0..<document.pageCount {
            guard !isCancelled() else { throw MediaPDFError.cancelled }
            guard let page = document.page(at: index) else { throw MediaPDFError.verificationFailed }
            let annotations = try page.annotations.map { annotation -> [String: Any] in
                var values: [String: Any] = ["type": annotation.type ?? "", "bounds": NSStringFromRect(annotation.bounds),
                    "contents": annotation.contents ?? "", "color": annotation.color.description,
                    "display": annotation.shouldDisplay, "print": annotation.shouldPrint]
                // Compare only stable annotation values, never parent-page or
                // appearance-stream object identity after serialization.
                for key in ["QuadPoints", "Vertices", "L", "LE", "IC"] {
                    if let value = annotation.value(forAnnotationKey: PDFAnnotationKey(rawValue: "/" + key)) { values[key] = value }
                }
                if let paths = annotation.paths {
                    values["ink"] = paths.map { path in
                        (0..<path.elementCount).map { index in
                            var points = [NSPoint](repeating: .zero, count: 3)
                            let element = path.element(at: index, associatedPoints: &points)
                            let count = element == .cubicCurveTo ? 3 : (element == .quadraticCurveTo ? 2 : (element == .closePath ? 0 : 1))
                            return [String(element.rawValue)] + points.prefix(count).map(NSStringFromPoint)
                        }
                    }
                }
                if annotation.type == "FreeText" {
                    values["font"] = annotation.font?.fontName ?? ""
                    values["fontSize"] = annotation.font?.pointSize ?? 0
                    values["fontColor"] = annotation.fontColor?.usingColorSpace(.deviceRGB)?.description ?? ""
                    values["alignment"] = annotation.alignment.rawValue
                }
                var destination = annotation.destination
                if let action = annotation.action {
                    if let url = action as? PDFActionURL { values["url"] = url.url?.absoluteString ?? "" }
                    else if let go = action as? PDFActionGoTo { destination = go.destination }
                    else { throw MediaPDFError.unsupportedStructure }
                }
                if let destination {
                    guard let target = destination.page else { throw MediaPDFError.verificationFailed }
                    values["target"] = document.index(for: target)
                    values["point"] = NSStringFromPoint(destination.point)
                    values["zoom"] = String(describing: destination.zoom)
                }
                return values
            }
            pages.append(["text": page.string ?? "", "rotation": page.rotation,
                "boxes": [PDFDisplayBox.mediaBox, .cropBox, .bleedBox, .trimBox, .artBox].map { NSStringFromRect(page.bounds(for: $0)) },
                "annotations": annotations])
        }
        return ["pages": pages, "initialView": try initialView(document)]
    }

    static func inspect(_ inputs: [URL], cachedURLs: Set<URL> = [],
                        isCancelled: () -> Bool = { false },
                        inspected: (URL, Result<Int, MediaPDFError>) -> Void) throws {
        guard !isCancelled() else { throw MediaPDFError.cancelled }
        guard inputs.count <= maximumInputs else { throw MediaPDFError.tooManyInputs }
        var totalBytes = 0
        var cachedBytes = 0
        var sizes: [Result<Int, MediaPDFError>] = []
        for input in inputs {
            guard !isCancelled() else { throw MediaPDFError.cancelled }
            let result: Result<Int, MediaPDFError>
            do { result = .success(try inputSize(input)) }
            catch { result = .failure((error as? MediaPDFError) ?? .unreadable(input.lastPathComponent)) }
            if case let .success(size) = result {
                guard size <= maximumInputBytes - totalBytes else { throw MediaPDFError.inputTooLarge }
                totalBytes += size
                if cachedURLs.contains(input) { cachedBytes += size }
            }
            sizes.append(result)
        }
        var bytes = cachedBytes
        for (index, input) in inputs.enumerated() {
            guard !isCancelled() else { throw MediaPDFError.cancelled }
            if case let .failure(error) = sizes[index] {
                inspected(input, .failure(error))
            } else if !cachedURLs.contains(input) {
                let result: Result<Int, MediaPDFError> = try autoreleasepool {
                    do {
                        let count = try loadDocument(input, bytes: &bytes, isCancelled: isCancelled).pageCount
                        return .success(count)
                    } catch let error as MediaPDFError {
                        if error == .cancelled || error == .inputTooLarge { throw error }
                        return .failure(error)
                    }
                }
                guard !isCancelled() else { throw MediaPDFError.cancelled }
                inspected(input, result)
            }
        }
        guard !isCancelled() else { throw MediaPDFError.cancelled }
    }

    static func merge(_ inputs: [URL], to stagedURL: URL,
                      isCancelled: () -> Bool = { false },
                      progress: (Int, Int) -> Void = { _, _ in }) throws -> Int {
        func checkCancelled() throws {
            if isCancelled() { throw MediaPDFError.cancelled }
        }
        try checkCancelled()
        guard inputs.count >= 2 else { throw MediaPDFError.tooFewInputs }
        guard inputs.count <= maximumInputs else { throw MediaPDFError.tooManyInputs }
        guard stagedURL.isFileURL else { throw MediaPDFError.writeFailed }
        guard !inputs.contains(where: { MediaSupport.fileURLsReferToSameItem($0, stagedURL) }) else { throw MediaPDFError.sameOutput }
        guard !FileManager.default.fileExists(atPath: stagedURL.path) else { throw MediaPDFError.outputExists }

        var documents: [PDFDocument] = []
        var bytes = 0
        var totalPages = 0
        for input in inputs {
            try checkCancelled()
            let document = try loadDocument(input, bytes: &bytes, isCancelled: isCancelled)
            guard document.pageCount <= maximumPages - totalPages else { throw MediaPDFError.tooManyPages }
            totalPages += document.pageCount
            documents.append(document)
        }
        let merged = PDFDocument()
        progress(0, totalPages)
        for (documentIndex, document) in documents.enumerated() {
            for pageIndex in 0..<document.pageCount {
                try checkCancelled()
                // PDFKit insert transfers ownership. Copy first to retain the
                // source page content streams, page boxes and annotations.
                guard let page = document.page(at: pageIndex)?.copy() as? PDFPage else {
                    throw MediaPDFError.invalidDocument(inputs[documentIndex].lastPathComponent)
                }
                merged.insert(page, at: merged.pageCount)
                progress(merged.pageCount, totalPages)
            }
        }
        try checkCancelled()
        guard let data = merged.dataRepresentation() else { throw MediaPDFError.writeFailed }
        try checkCancelled()
        try writeExclusive(data, to: stagedURL)
        var succeeded = false
        defer { if !succeeded { try? FileManager.default.removeItem(at: stagedURL) } }
        try checkCancelled()
        guard let reopened = PDFDocument(url: stagedURL),
              !reopened.isLocked, reopened.pageCount == totalPages,
              (0..<totalPages).allSatisfy({ index in
                  guard let saved = reopened.page(at: index), let expected = merged.page(at: index) else { return false }
                  return saved.rotation == expected.rotation
                      && saved.bounds(for: .mediaBox) == expected.bounds(for: .mediaBox)
                      && saved.bounds(for: .cropBox) == expected.bounds(for: .cropBox)
              })
        else { throw MediaPDFError.verificationFailed }
        try checkCancelled()
        succeeded = true
        return totalPages
    }

    /// Shared bounded snapshot reader used by preview inspection and merge.
    /// A document is held only by its caller; inspect releases each one before
    /// moving to the next URL, while merge retains sources until serialization.
    private static func loadDocument(_ input: URL, bytes: inout Int,
                                     isCancelled: () -> Bool) throws -> PDFDocument {
        guard !isCancelled() else { throw MediaPDFError.cancelled }
        let name = input.lastPathComponent
        let size = try inputSize(input)
        guard size <= maximumInputBytes - bytes else { throw MediaPDFError.inputTooLarge }
        let data: Data
        do {
            let handle = try FileHandle(forReadingFrom: input)
            defer { try? handle.close() }
            data = try handle.read(upToCount: maximumInputBytes - bytes + 1) ?? Data()
        } catch { throw MediaPDFError.unreadable(name) }
        bytes += data.count
        guard bytes <= maximumInputBytes else { throw MediaPDFError.inputTooLarge }
        guard !isCancelled() else { throw MediaPDFError.cancelled }
        guard let document = PDFDocument(data: data) else { throw MediaPDFError.invalidDocument(name) }
        guard !document.isEncrypted, !document.isLocked else { throw MediaPDFError.encryptedDocument(name) }
        guard document.pageCount > 0 else { throw MediaPDFError.emptyDocument(name) }
        guard !isCancelled() else { throw MediaPDFError.cancelled }
        return document
    }

    private static func inputSize(_ input: URL) throws -> Int {
        guard input.isFileURL,
              let values = try? input.resourceValues(forKeys: [.isRegularFileKey, .fileSizeKey]),
              values.isRegularFile == true, let size = values.fileSize, size >= 0
        else { throw MediaPDFError.unreadable(input.lastPathComponent) }
        return size
    }

    static func installWithoutReplacing(_ stagedURL: URL, at outputURL: URL, inputs: [URL]) throws {
        guard stagedURL.isFileURL, outputURL.isFileURL else { throw MediaPDFError.writeFailed }
        guard !MediaSupport.fileURLsReferToSameItem(stagedURL, outputURL),
              !inputs.contains(where: {
                  MediaSupport.fileURLsReferToSameItem($0, outputURL)
                      || MediaSupport.fileURLsReferToSameItem($0, stagedURL)
              })
        else { throw MediaPDFError.sameOutput }
        // The caller holds its operation/cancellation lock here. RENAME_EXCL
        // refuses even a destination that appears after a save-panel check.
        let status = stagedURL.withUnsafeFileSystemRepresentation { source in
            outputURL.withUnsafeFileSystemRepresentation { target in
                guard let source, let target else { return Int32(-1) }
                return renameatx_np(AT_FDCWD, source, AT_FDCWD, target, UInt32(RENAME_EXCL))
            }
        }
        guard status == 0 else {
            throw errno == EEXIST ? MediaPDFError.outputExists : MediaPDFError.writeFailed
        }
    }

}
