// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import Foundation
import PDFKit
import CoreText

enum MediaPDFTests {
    static func run(_ expect: (Bool, String) -> Void) {
        let fm = FileManager.default
        let directory = fm.temporaryDirectory.appendingPathComponent("kururu-pdf-tests-\(UUID().uuidString)")
        do {
            try fm.createDirectory(at: directory, withIntermediateDirectories: true)
            defer { try? fm.removeItem(at: directory) }
            let first = directory.appendingPathComponent("first.pdf")
            let second = directory.appendingPathComponent("second.pdf")
            try fixture(first, text: "FIRST vector text", size: CGSize(width: 300, height: 420), rotation: 90)
            try fixture(second, text: "SECOND vector text", size: CGSize(width: 500, height: 250), rotation: 0)
            let original = try [Data(contentsOf: first), Data(contentsOf: second)]
            let staged = directory.appendingPathComponent("staged.pdf")
            var updates: [(Int, Int)] = []
            do {
                let count = try MediaPDFSupport.merge([second, first], to: staged, progress: { updates.append(($0, $1)) })
                let result = PDFDocument(url: staged)
                expect(count == 2 && result?.pageCount == 2, "merged output reopens with every page")
                expect(result?.page(at: 0)?.string?.contains("SECOND vector text") == true,
                       "ordered inputs preserve extractable second-document text first")
                expect(result?.page(at: 1)?.string?.contains("FIRST vector text") == true,
                       "first-document vector text survives copying")
                expect(result?.page(at: 0)?.bounds(for: .mediaBox).size == CGSize(width: 500, height: 250),
                       "mixed page sizes are preserved")
                expect(result?.page(at: 1)?.bounds(for: .mediaBox).size == CGSize(width: 300, height: 420)
                       && result?.page(at: 1)?.rotation == 90, "page dimensions and rotation both survive")
                expect(result?.page(at: 1)?.annotations.contains { $0.contents == "note-FIRST vector text" } == true,
                       "page annotations survive serialization")
                let note = result?.page(at: 1)?.annotations.first { $0.contents == "note-FIRST vector text" }
                let sourceNote = PDFDocument(url: first)?.page(at: 0)?.annotations.first { $0.contents == "note-FIRST vector text" }
                expect(note != nil && note?.bounds == sourceNote?.bounds && note?.type == sourceNote?.type,
                       "annotation geometry and type match the serialized source")
                expect(updates.last?.0 == 2 && updates.last?.1 == 2, "progress reaches the verified page total")
            } catch { expect(false, "valid PDF merge succeeds: \(error)") }
            let after = try [Data(contentsOf: first), Data(contentsOf: second)]
            expect(after == original,
                   "source files are byte-for-byte unchanged")

            func rejected(_ urls: [URL], output: URL, expected: MediaPDFError,
                          cancel: () -> Bool = { false }, progress: (Int, Int) -> Void = { _, _ in }) {
                do {
                    _ = try MediaPDFSupport.merge(urls, to: output, isCancelled: cancel, progress: progress)
                    expect(false, "merge rejects \(expected)")
                } catch { expect(error as? MediaPDFError == expected, "merge reports \(expected), got \(error)") }
                expect(!fm.fileExists(atPath: output.path), "failed or cancelled merge leaves no partial file")
            }
            let bad = directory.appendingPathComponent("bad.pdf")
            try Data("broken PDF".utf8).write(to: bad)
            inspectTests(first: first, second: second, bad: bad, expect)
            rejected([first, bad], output: directory.appendingPathComponent("bad-output.pdf"), expected: .invalidDocument("bad.pdf"))
            rejected([first], output: directory.appendingPathComponent("single.pdf"), expected: .tooFewInputs)
            rejected([first, second], output: directory.appendingPathComponent("cancelled.pdf"), expected: .cancelled, cancel: { true })
            var cancelled = false
            rejected([first, second], output: directory.appendingPathComponent("mid-cancel.pdf"), expected: .cancelled,
                     cancel: { cancelled }, progress: { done, _ in if done == 1 { cancelled = true } })
            let empty = directory.appendingPathComponent("empty.pdf")
            var emptyPDF = "%PDF-1.4\n"
            var offsets = [0]
            for object in ["<< /Type /Catalog /Pages 2 0 R >>", "<< /Type /Pages /Kids [] /Count 0 >>"] {
                offsets.append(emptyPDF.utf8.count)
                emptyPDF += "\(offsets.count - 1) 0 obj\n\(object)\nendobj\n"
            }
            let xrefOffset = emptyPDF.utf8.count
            emptyPDF += "xref\n0 3\n0000000000 65535 f \n"
            for offset in offsets.dropFirst() { emptyPDF += String(format: "%010d 00000 n \n", offset) }
            emptyPDF += "trailer\n<< /Root 1 0 R /Size 3 >>\nstartxref\n\(xrefOffset)\n%%EOF\n"
            let emptyData = Data(emptyPDF.utf8)
            // PDFKit rejects a valid zero-page page tree before exposing a PDFDocument.
            expect(PDFDocument(data: emptyData) == nil, "PDFKit rejects the zero-page fixture")
            try emptyData.write(to: empty)
            rejected([first, empty], output: directory.appendingPathComponent("empty-output.pdf"), expected: .invalidDocument("empty.pdf"))
            let cancelWritten = directory.appendingPathComponent("cancel-written.pdf")
            rejected([first, second], output: cancelWritten, expected: .cancelled,
                     cancel: { fm.fileExists(atPath: cancelWritten.path) })
            let manyPages = PDFDocument()
            for _ in 0...MediaPDFSupport.maximumPages {
                manyPages.insert(PDFDocument(url: first)!.page(at: 0)!.copy() as! PDFPage, at: manyPages.pageCount)
            }
            let oversizedPages = directory.appendingPathComponent("many-pages.pdf")
            try manyPages.dataRepresentation()!.write(to: oversizedPages)
            rejected([first, oversizedPages], output: directory.appendingPathComponent("page-limit.pdf"), expected: .tooManyPages)
            let encrypted = directory.appendingPathComponent("encrypted.pdf")
            let protected = PDFDocument(url: first)!
            expect(protected.write(to: encrypted, withOptions: [.userPasswordOption: "secret", .ownerPasswordOption: "owner"]),
                   "encrypted PDF fixture is created")
            rejected([first, encrypted], output: directory.appendingPathComponent("encrypted-output.pdf"), expected: .encryptedDocument("encrypted.pdf"))
            let ownerOnly = directory.appendingPathComponent("owner-only.pdf")
            expect(protected.write(to: ownerOnly, withOptions: [.userPasswordOption: "", .ownerPasswordOption: "owner"]),
                   "owner-only encrypted fixture is created")
            let ownerDocument = PDFDocument(url: ownerOnly)
            expect(ownerDocument?.isEncrypted == true && ownerDocument?.isLocked == false,
                   "owner-only fixture is encrypted but automatically unlocked")
            rejected([first, ownerOnly], output: directory.appendingPathComponent("owner-output.pdf"), expected: .encryptedDocument("owner-only.pdf"))
            var ownerInspection: Result<Int, MediaPDFError>?
            try MediaPDFSupport.inspect([ownerOnly], inspected: { _, result in ownerInspection = result })
            expect(ownerInspection == .failure(.encryptedDocument("owner-only.pdf")),
                   "inspection rejects automatically unlocked encryption too")
            rejected(Array(repeating: first, count: MediaPDFSupport.maximumInputs + 1),
                     output: directory.appendingPathComponent("too-many.pdf"), expected: .tooManyInputs)
            let huge = directory.appendingPathComponent("huge.pdf")
            fm.createFile(atPath: huge.path, contents: nil)
            let hugeHandle = try FileHandle(forWritingTo: huge)
            try hugeHandle.truncate(atOffset: UInt64(MediaPDFSupport.maximumInputBytes + 1))
            try hugeHandle.close()
            rejected([first, huge], output: directory.appendingPathComponent("byte-limit.pdf"), expected: .inputTooLarge)
            do {
                try MediaPDFSupport.inspect([huge], cachedURLs: [huge], inspected: { _, _ in
                    expect(false, "cached oversized file is rejected before row callbacks")
                })
                expect(false, "cached file still counts toward total bytes")
            } catch { expect(error as? MediaPDFError == .inputTooLarge, "cached inspection enforces full batch byte limit") }
            let disappeared = directory.appendingPathComponent("disappeared.pdf")
            var missingInspection: Result<Int, MediaPDFError>?
            try MediaPDFSupport.inspect([disappeared], cachedURLs: [disappeared], inspected: { _, result in missingInspection = result })
            expect(missingInspection == .failure(.unreadable("disappeared.pdf")),
                   "a cached file that disappeared gets a row failure instead of remaining valid")

            let existing = directory.appendingPathComponent("existing.pdf")
            let sentinel = Data("keep existing destination".utf8)
            try sentinel.write(to: existing)
            do { _ = try MediaPDFSupport.merge([first, second], to: existing); expect(false, "existing staging refused") }
            catch { expect(error as? MediaPDFError == .outputExists, "existing staging reports collision") }
            expect((try Data(contentsOf: existing)) == sentinel, "staging collision preserves existing bytes")
            do { try MediaPDFSupport.installWithoutReplacing(staged, at: existing, inputs: [first, second]); expect(false, "existing destination refused") }
            catch { expect(error as? MediaPDFError == .outputExists, "commit reports collision") }
            expect((try Data(contentsOf: existing)) == sentinel, "commit collision preserves destination")
            let alias = directory.appendingPathComponent("hardlink.pdf")
            try fm.linkItem(at: second, to: alias)
            do { try MediaPDFSupport.installWithoutReplacing(staged, at: alias, inputs: [first, second]); expect(false, "any input hardlink refused") }
            catch { expect(error as? MediaPDFError == .sameOutput, "all inputs receive identity protection") }
            do { try MediaPDFSupport.installWithoutReplacing(staged, at: staged, inputs: [first, second]); expect(false, "stage cannot be destination") }
            catch { expect(error as? MediaPDFError == .sameOutput, "stage identity is protected") }
            let final = directory.appendingPathComponent("merged.pdf")
            do {
                try MediaPDFSupport.installWithoutReplacing(staged, at: final, inputs: [first, second])
                expect(PDFDocument(url: final)?.pageCount == 2 && !fm.fileExists(atPath: staged.path),
                       "exclusive commit publishes valid PDF and consumes staging")
            } catch { expect(false, "exclusive commit succeeds: \(error)") }
        } catch { expect(false, "PDF fixture setup succeeds: \(error)") }
    }

    private static func inspectTests(first: URL, second: URL, bad: URL, _ expect: (Bool, String) -> Void) {
        do {
            var rows: [(URL, Result<Int, MediaPDFError>)] = []
            try MediaPDFSupport.inspect([second, bad, first], inspected: { rows.append(($0, $1)) })
            expect(rows.map(\.0) == [second, bad, first], "inspection follows input order and continues after a bad file")
            expect(rows.map(\.1) == [.success(1), .failure(.invalidDocument("bad.pdf")), .success(1)],
                   "inspection associates counts and parse failures with their own URL")
        } catch { expect(false, "inspection returns individual failures: \(error)") }
        do {
            var urls: [URL] = []
            try MediaPDFSupport.inspect([first, bad, second], cachedURLs: [first, bad], inspected: { urls.append($0); _ = $1 })
            expect(urls == [second], "cached URLs skip parsing and duplicate completion callbacks")
        } catch { expect(false, "cached inspection succeeds: \(error)") }
        var cancelled = false
        var completed: [URL] = []
        do {
            try MediaPDFSupport.inspect([first, second], isCancelled: { cancelled }, inspected: {
                completed.append($0); _ = $1; cancelled = true
            })
            expect(false, "inspection cancellation throws")
        } catch { expect(error as? MediaPDFError == .cancelled && completed == [first], "inspection stops before the next URL on cancellation") }
        do {
            try MediaPDFSupport.inspect([first], isCancelled: { true }, inspected: { _, _ in
                expect(false, "pre-cancelled inspection never publishes rows")
            })
            expect(false, "pre-cancelled inspection throws")
        } catch { expect(error as? MediaPDFError == .cancelled, "inspection checks cancellation before metadata access") }
        do {
            try MediaPDFSupport.inspect(Array(repeating: first, count: MediaPDFSupport.maximumInputs + 1), cachedURLs: [first], inspected: { _, _ in
                expect(false, "oversized batch never starts row callbacks")
            })
            expect(false, "cached URLs still count toward batch file limit")
        } catch { expect(error as? MediaPDFError == .tooManyInputs, "cached batch reports file limit") }
    }

    private static func fixture(_ url: URL, text: String, size: CGSize, rotation: Int) throws {
        var bounds = CGRect(origin: .zero, size: size)
        let context = CGContext(url as CFURL, mediaBox: &bounds, nil)!
        context.beginPDFPage(nil)
        context.setStrokeColor(CGColor(gray: 0, alpha: 1))
        context.stroke(CGRect(x: 15, y: 15, width: 80, height: 30))
        context.textPosition = CGPoint(x: 30, y: 100)
        let line = CTLineCreateWithAttributedString(NSAttributedString(string: text,
            attributes: [NSAttributedString.Key(kCTFontAttributeName as String): CTFontCreateWithName("Helvetica" as CFString, 16, nil)]))
        CTLineDraw(line, context)
        context.endPDFPage()
        context.closePDF()
        let document = PDFDocument(url: url)!
        let page = document.page(at: 0)!
        page.rotation = rotation
        let annotation = PDFAnnotation(bounds: CGRect(x: 40, y: 40, width: 20, height: 20), forType: .text, withProperties: nil)
        annotation.contents = "note-" + text
        page.addAnnotation(annotation)
        guard let data = document.dataRepresentation() else { throw MediaPDFError.writeFailed }
        try data.write(to: url)
    }
}
