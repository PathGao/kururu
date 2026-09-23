// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import AppKit
import Foundation

/// Runs the image converter's production watermark drawing into a bitmap,
/// and pins the batch subfolder wiring in the workspace view. The upstream
/// port of #1347 only checks the registered default.
enum MediaImageAdvancedOptionsTests {
    static func run(_ suite: TestSuite) {
        logoOpacity(suite)
        textOpacity(suite)
        subfolder(suite)
    }

    /// Alpha of every pixel of a 256 x 256 canvas after drawing, row by row,
    /// in the bitmap context the converter itself draws into.
    private static func alphas(_ watermark: MediaImageWatermark, logo: CGImage?) -> [UInt8] {
        let size = 256
        guard let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size,
                                         bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                                         isPlanar: false, colorSpaceName: .deviceRGB,
                                         bytesPerRow: 0, bitsPerPixel: 0),
              let context = NSGraphicsContext(bitmapImageRep: rep),
              let data = rep.bitmapData
        else { return [] }
        let previous = NSGraphicsContext.current
        NSGraphicsContext.current = context
        Renderer().drawWatermark(watermark, logo: logo, canvasSize: NSSize(width: size, height: size))
        context.flushGraphics()
        NSGraphicsContext.current = previous
        return (0..<size).flatMap { y in
            (0..<size).map { x in data[y * rep.bytesPerRow + x * 4 + 3] }
        }
    }

    private static func logoOpacity(_ suite: TestSuite) {
        let context = CGContext(data: nil, width: 8, height: 8, bitsPerComponent: 8, bytesPerRow: 0,
                                space: CGColorSpaceCreateDeviceRGB(),
                                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
        context?.setFillColor(CGColor(gray: 1, alpha: 1))
        context?.fill(CGRect(x: 0, y: 0, width: 8, height: 8))
        let logo = context?.makeImage()
        // A centered logo covers the canvas center.
        func center(_ opacity: Double) -> Int? {
            let drawn = alphas(MediaImageWatermark(kind: .logo, logoPath: "/logo.png", position: .center,
                                                   opacity: opacity, scale: 0.8),
                               logo: logo)
            return drawn.isEmpty ? nil : Int(drawn[128 * 256 + 128])
        }
        let opaque = center(1)
        let faint = center(0.3)
        suite.expect(opaque == 255, "an opaque logo watermark covers its area, got \(String(describing: opaque))")
        suite.expect(faint.map { abs($0 - 77) <= 3 } == true,
                     "a logo watermark is drawn at its opacity, got \(String(describing: faint))")
    }

    private static func textOpacity(_ suite: TestSuite) {
        // Text alpha is measured as the most opaque pixel anywhere on the canvas.
        func peak(_ opacity: Double) -> Int {
            Int(alphas(MediaImageWatermark(kind: .text, text: "WWW", position: .center,
                                           opacity: opacity),
                       logo: nil).max() ?? 0)
        }
        let opaque = peak(1)
        let faint = peak(0.3)
        suite.expect(opaque >= 250 && faint <= 90,
                     "a text watermark is drawn at its opacity, got \(opaque) and \(faint)")
    }

    private static func subfolder(_ suite: TestSuite) {
        let view = (try? String(contentsOfFile: "Sources/Vorssaint/UI/Media/MediaWorkspaceView.swift",
                                encoding: .utf8)) ?? ""
        suite.expect(view.contains("let outputDirectory = imageSaveInSubfolder\n                    ? outputURL.appendingPathComponent(Self.imageOutputSubfolderName,")
                        && view.contains("outputDirectory: outputDirectory,"),
                     "an image batch writes into the Converted subfolder when the option is on")
    }
}
