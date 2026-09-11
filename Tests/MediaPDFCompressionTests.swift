// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint
import Foundation
import PDFKit
import CoreText

enum MediaPDFCompressionTests {
    static func run(_ expect: (Bool, String) -> Void) {
        let fm = FileManager.default
        let directory = fm.temporaryDirectory.appendingPathComponent("kururu-compress-\(UUID())")
        do {
            try fm.createDirectory(at: directory, withIntermediateDirectories: true)
            defer { try? fm.removeItem(at: directory) }
            let input = directory.appendingPathComponent("image.pdf")
            try fixture(input, image: true)
            let doc = PDFDocument(url: input)!
            doc.page(at: 0)!.rotation = 90
            doc.page(at: 0)!.setBounds(CGRect(x: 10, y: 10, width: 390, height: 330), for: .cropBox)
            let note = PDFAnnotation(bounds: CGRect(x: 20, y: 20, width: 30, height: 30), forType: .text, withProperties: nil)
            note.contents = "Keep this note"
            doc.page(at: 0)!.addAnnotation(note)
            let link = PDFAnnotation(bounds: CGRect(x: 80, y: 20, width: 100, height: 30), forType: .link, withProperties: nil)
            link.action = PDFActionURL(url: URL(string: "https://example.com/pdf")!)
            doc.page(at: 0)!.addAnnotation(link)
            let internalLink = PDFAnnotation(bounds: CGRect(x: 190, y: 20, width: 50, height: 30), forType: .link, withProperties: nil)
            internalLink.action = PDFActionGoTo(destination: PDFDestination(page: doc.page(at: 0)!, at: CGPoint(x: 35, y: 80)))
            doc.page(at: 0)!.addAnnotation(internalLink)
            let highlight = PDFAnnotation(bounds: CGRect(x: 20, y: 80, width: 80, height: 20), forType: .highlight, withProperties: nil)
            highlight.quadrilateralPoints = [NSValue(point: CGPoint(x: 0, y: 20)), NSValue(point: CGPoint(x: 80, y: 20)), NSValue(point: .zero), NSValue(point: CGPoint(x: 80, y: 0))]
            doc.page(at: 0)!.addAnnotation(highlight)
            let ink = PDFAnnotation(bounds: CGRect(x: 20, y: 120, width: 80, height: 20), forType: .ink, withProperties: nil)
            let stroke = NSBezierPath(); stroke.move(to: .zero); stroke.line(to: CGPoint(x: 40, y: 10)); ink.add(stroke)
            doc.page(at: 0)!.addAnnotation(ink)
            guard doc.write(to: input) else { throw MediaPDFError.writeFailed }
            let original = try Data(contentsOf: input)
            for mode in MediaPDFCompressionMode.allCases {
                let output = directory.appendingPathComponent(mode.rawValue + ".pdf")
                do {
                    let result = try MediaPDFSupport.compress(input, to: output, mode: mode)
                    expect(result.didCompress && result.outputBytes < result.originalBytes, "image compression shrinks \(mode)")
                    let saved = PDFDocument(url: output)?.page(at: 0)
                    let source = PDFDocument(url: input)?.page(at: 0)
                    expect(saved?.string == source?.string && saved != nil, "selectable text survives \(mode)")
                    expect(saved?.rotation == 90 && saved?.bounds(for: .cropBox) == source?.bounds(for: .cropBox), "geometry and rotation survive \(mode)")
                    expect(saved?.annotations.contains { $0.contents == "Keep this note" } == true, "note survives \(mode)")
                    expect(saved?.annotations.contains { ($0.action as? PDFActionURL)?.url?.absoluteString == "https://example.com/pdf" } == true, "URI link survives \(mode)")
                    expect(saved?.annotations.contains { ($0.action as? PDFActionGoTo)?.destination.point == CGPoint(x: 35, y: 80) } == true, "internal destination survives \(mode)")
                    expect(saved?.annotations.first { $0.type == "Highlight" }?.quadrilateralPoints == source?.annotations.first { $0.type == "Highlight" }?.quadrilateralPoints, "highlight geometry survives \(mode)")
                    expect(saved?.annotations.first { $0.type == "Ink" }?.paths?.first?.elementCount == 2, "ink path survives \(mode)")
                } catch { expect(false, "compression succeeds: \(error)") }
            }
            expect(try Data(contentsOf: input) == original, "original is unchanged")
            func reject(_ source: URL, _ name: String, _ expected: MediaPDFError, cancel: () -> Bool = { false }) {
                let out = directory.appendingPathComponent(name)
                do { _ = try MediaPDFSupport.compress(source, to: out, mode: .screen, isCancelled: cancel); expect(false, "reject \(expected)") }
                catch { expect(error as? MediaPDFError == expected, "reports \(expected): \(error)") }
                expect(!fm.fileExists(atPath: out.path), "rejection leaves no candidate \(name)")
            }
            reject(input, "cancel.pdf", .cancelled, cancel: { true })
            var polls = 0
            reject(input, "late-cancel.pdf", .cancelled, cancel: { polls += 1; return polls > 5 })
            let afterWrite = directory.appendingPathComponent("after-write.pdf")
            reject(input, "after-write.pdf", .cancelled, cancel: { fm.fileExists(atPath: afterWrite.path) })
            let alias = directory.appendingPathComponent("hardlink.pdf")
            try fm.linkItem(at: input, to: alias)
            do { _ = try MediaPDFSupport.compress(input, to: alias, mode: .screen); expect(false, "hardlink rejected") }
            catch { expect(error as? MediaPDFError == .sameOutput, "hardlink rejected") }
            let bad = directory.appendingPathComponent("bad.pdf")
            try Data("invalid".utf8).write(to: bad)
            reject(bad, "bad-out.pdf", .invalidDocument("bad.pdf"))
            do { _ = try MediaPDFSupport.compress(input, to: input, mode: .screen); expect(false, "same output rejected") }
            catch { expect(error as? MediaPDFError == .sameOutput, "same output rejected") }
            let existing = directory.appendingPathComponent("existing.pdf")
            let sentinel = Data("existing".utf8); try sentinel.write(to: existing)
            do { _ = try MediaPDFSupport.compress(input, to: existing, mode: .screen); expect(false, "existing rejected") }
            catch { expect(error as? MediaPDFError == .outputExists, "existing rejected") }
            expect(try Data(contentsOf: existing) == sentinel, "existing target unchanged")
            let encrypted = directory.appendingPathComponent("encrypted.pdf")
            _ = doc.write(to: encrypted, withOptions: [.ownerPasswordOption: "owner", .userPasswordOption: "secret"])
            reject(encrypted, "encrypted-out.pdf", .encryptedDocument("encrypted.pdf"))
            let simple = directory.appendingPathComponent("simple.pdf")
            try rawFixture(simple)
            let noGain = directory.appendingPathComponent("no-gain.pdf")
            do {
                let result = try MediaPDFSupport.compress(simple, to: noGain, mode: .screen)
                expect(!result.didCompress && !fm.fileExists(atPath: noGain.path), "non-smaller candidate leaves no output")
            } catch { expect(false, "non-smaller is normal result: \(error)") }
            for structure in ["/AcroForm << /Fields [] >>", "/StructTreeRoot << /Type /StructTreeRoot >>", "/Collection << >>", "/Names << /EmbeddedFiles << /Names [] >> >>", "/OCProperties << >>"] {
                let unsupported = directory.appendingPathComponent("unsupported.pdf")
                try rawFixture(unsupported, catalog: structure)
                reject(unsupported, "unsupported-out.pdf", .unsupportedStructure)
            }
            for catalog in ["/MarkInfo << /Marked false >>", "/OpenAction [3 0 R /Fit]", "/OpenAction << /S /GoTo /D [3 0 R /Fit] >>", "/Names << /Dests << /Names [] >> >>"] {
                let ordinary = directory.appendingPathComponent("ordinary.pdf")
                try rawFixture(ordinary, catalog: catalog)
                do { _ = try MediaPDFSupport.compress(ordinary, to: directory.appendingPathComponent(UUID().uuidString), mode: .screen); expect(true, "ordinary catalog accepted") }
                catch { expect(false, "ordinary catalog must not be rejected: \(catalog) \(error)") }
            }
            let action = directory.appendingPathComponent("action.pdf")
            try rawFixture(action, catalog: "/OpenAction << /S /JavaScript /JS (app.alert) >>")
            reject(action, "action-out.pdf", .unsupportedStructure)
            let giant = directory.appendingPathComponent("giant.pdf")
            let largeImage = "<< /Type /XObject /Subtype /Image /Width 20001 /Height 1 /ColorSpace /DeviceRGB /BitsPerComponent 8 /Length 0 >>\nstream\n\nendstream"
            try rawFixture(giant, page: "/Resources << /XObject << /Im1 4 0 R >> >>", extra: [largeImage])
            reject(giant, "giant-out.pdf", .unsupportedStructure)
            try rawFixture(giant, page: "/Resources << /XObject << /Fm1 4 0 R >> >>", extra: ["<< /Type /XObject /Subtype /Form /BBox [0 0 1 1] /Resources << /XObject << /Im1 5 0 R >> >> /Length 0 >>\nstream\n\nendstream", largeImage])
            reject(giant, "giant-form-out.pdf", .unsupportedStructure)
            try rawFixture(giant, page: "/Resources << /ExtGState << /GS1 << /SMask << /S /Luminosity /G 4 0 R >> >> >> >>", extra: ["<< /Type /XObject /Subtype /Form /BBox [0 0 1 1] /Resources << /XObject << /Im1 5 0 R >> >> /Length 0 >>\nstream\n\nendstream", largeImage])
            reject(giant, "giant-softmask-form-out.pdf", .unsupportedStructure)
            let transparent = directory.appendingPathComponent("transparent.pdf")
            try transparencyFixture(transparent)
            let transparentSource = PDFDocument(url: transparent)!
            let referencePixels = pixels(transparentSource)
            let jpeg = PDFDocument(data: transparentSource.dataRepresentation(options: [PDFDocumentWriteOption.saveImagesAsJPEGOption: true, PDFDocumentWriteOption.optimizeImagesForScreenOption: true])!)!
            let jpegError = pixelDifference(referencePixels, pixels(jpeg))
            for mode in MediaPDFCompressionMode.allCases {
                let out = directory.appendingPathComponent("transparent-" + mode.rawValue + ".pdf")
                let result = try MediaPDFSupport.compress(transparent, to: out, mode: mode)
                let candidate = result.didCompress ? PDFDocument(url: out)! : transparentSource
                let error = pixelDifference(referencePixels, pixels(candidate))
                expect(error < jpegError / 2, "transparent \(mode) preserves pixels better than faulty JPEG path (\(error) vs \(jpegError))")
            }
            let many = PDFDocument()
            for index in 0...MediaPDFSupport.maximumPages { many.insert(PDFPage(), at: index) }
            let manyURL = directory.appendingPathComponent("many.pdf")
            _ = many.write(to: manyURL)
            reject(manyURL, "many-out.pdf", .tooManyPages)
        } catch { expect(false, "compression fixture setup: \(error)") }
    }
    private static func transparencyFixture(_ url: URL) throws {
        var box = CGRect(x: 0, y: 0, width: 480, height: 560)
        guard let context = CGContext(url as CFURL, mediaBox: &box, nil) else { throw MediaPDFError.writeFailed }
        context.beginPDFPage(nil)
        context.setFillColor(CGColor(gray: 1, alpha: 1)); context.fill(box)
        for y in 0..<14 { for x in 0..<20 {
            context.setFillColor(CGColor(gray: (x+y)%2 == 0 ? 0.88 : 0.55, alpha: 1))
            context.fill(CGRect(x: 30+x*21, y: 165+y*21, width: 21, height: 21))
        } }
        context.draw(alphaImage(alpha: true), in: CGRect(x: 30, y: 165, width: 420, height: 294))
        context.endPDFPage(); context.closePDF()
    }
    private static func pixels(_ document: PDFDocument) -> [UInt8] {
        let context = CGContext(data: nil, width: 480, height: 560, bitsPerComponent: 8, bytesPerRow: 480*4,
            space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        context.setFillColor(CGColor(gray: 1, alpha: 1)); context.fill(CGRect(x: 0, y: 0, width: 480, height: 560))
        document.page(at: 0)!.draw(with: .mediaBox, to: context)
        return Array(UnsafeBufferPointer(start: context.data!.assumingMemoryBound(to: UInt8.self), count: 480*560*4))
    }
    private static func pixelDifference(_ lhs: [UInt8], _ rhs: [UInt8]) -> Double {
        zip(lhs, rhs).reduce(0.0) { $0 + abs(Double($1.0) - Double($1.1)) } / Double(lhs.count)
    }
private static func alphaImage(alpha: Bool) -> CGImage {
 let w=1000,h=700
 var p=[UInt8](repeating:0,count:w*h*4); var seed:UInt32=19
 for y in 0..<h { for x in 0..<w {
 seed=seed &* 1664525 &+ 1013904223
 let n=Int(seed>>24)%35
 let a=alpha ? max(0,min(255,Int(255*(1-hypot(Double(x-w/2)/500,Double(y-h/2)/350))))) : 255
 let i=(y*w+x)*4
 p[i]=UInt8((30+x*190/w+n)*a/255);p[i+1]=UInt8((30+y*190/h+n)*a/255);p[i+2]=UInt8((130+n)*a/255);p[i+3]=UInt8(a)
 }}
 return CGImage(width:w,height:h,bitsPerComponent:8,bitsPerPixel:32,bytesPerRow:w*4,space:CGColorSpaceCreateDeviceRGB(),bitmapInfo:CGBitmapInfo(rawValue:CGImageAlphaInfo.premultipliedLast.rawValue),provider:CGDataProvider(data:Data(p) as CFData)!,decode:nil,shouldInterpolate:true,intent:.defaultIntent)!
}
    private static func rawFixture(_ url: URL, catalog: String = "", page: String = "", extra: [String] = []) throws {
        let objects = ["<< /Type /Catalog /Pages 2 0 R \(catalog) >>", "<< /Type /Pages /Kids [3 0 R] /Count 1 >>", "<< /Type /Page /Parent 2 0 R /MediaBox [0 0 300 300] \(page) >>"] + extra
        var pdf = "%PDF-1.4\n"
        var offsets = [0]
        for (index, object) in objects.enumerated() { offsets.append(pdf.utf8.count); pdf += "\(index + 1) 0 obj\n\(object)\nendobj\n" }
        let xref = pdf.utf8.count
        pdf += "xref\n0 \(objects.count + 1)\n0000000000 65535 f \n"
        for offset in offsets.dropFirst() { pdf += String(format: "%010d 00000 n \n", offset) }
        pdf += "trailer\n<< /Size \(objects.count + 1) /Root 1 0 R >>\nstartxref\n\(xref)\n%%EOF\n"
        try Data(pdf.utf8).write(to: url)
    }
private static func fixture(_ url: URL, image: Bool) throws {
    var box = CGRect(x: 0, y: 0, width: 420, height: 360)
    guard let context = CGContext(url as CFURL, mediaBox: &box, nil) else { fatalError("context") }
    context.beginPDFPage(nil)
    context.setStrokeColor(CGColor(gray: 0.15, alpha: 1))
    context.setLineWidth(1.25)
    context.stroke(CGRect(x: 20, y: 20, width: 380, height: 320))
    context.textPosition = CGPoint(x: 28, y: 325)
    let attributes: [NSAttributedString.Key: Any] = [
        NSAttributedString.Key(kCTFontAttributeName as String): CTFontCreateWithName("Helvetica" as CFString, 12, nil)
    ]
    CTLineDraw(CTLineCreateWithAttributedString(NSAttributedString(string: "Compression text 012345", attributes: attributes)), context)
    if image {
        let width = 1600, height = 1200
        var pixels = [UInt8](repeating: 0, count: width * height * 3)
        var seed: UInt32 = 1
        for y in 0..<height { for x in 0..<width {
            seed = seed &* 1664525 &+ 1013904223
            let noise = Int((seed >> 24) % 25) - 12
            let offset = (y * width + x) * 3
            pixels[offset] = UInt8(clamping: 35 + x * 180 / width + noise)
            pixels[offset + 1] = UInt8(clamping: 35 + y * 180 / height + noise)
            pixels[offset + 2] = UInt8(clamping: 70 + (x + y) * 110 / (width + height) + noise)
        } }
        let data = Data(pixels) as CFData
        let provider = CGDataProvider(data: data)!
        let bitmap = CGImage(width: width, height: height, bitsPerComponent: 8, bitsPerPixel: 24,
            bytesPerRow: width * 3, space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue), provider: provider,
            decode: nil, shouldInterpolate: true, intent: .defaultIntent)!
        context.draw(bitmap, in: CGRect(x: 35, y: 65, width: 350, height: 262.5))
    }
    context.endPDFPage()
    context.closePDF()
}
}
