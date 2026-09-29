// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import AppKit

/// Compile together with HornSpiritMark.swift.
/// ICNS uses the Composer export; monochrome marks use native vector geometry.
@main
struct MakeIcon {
    static func main() throws {
        guard CommandLine.arguments.count == 3 else {
            throw NSError(domain: "MakeIcon", code: 1, userInfo: [NSLocalizedDescriptionKey: "Usage: MakeIcon COMPOSER_EXPORT.png OUTPUT.iconset"])
        }
        let output = URL(fileURLWithPath: CommandLine.arguments[2], isDirectory: true)
        try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
        guard let source = NSImage(contentsOfFile: CommandLine.arguments[1]),
              let artwork = source.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            throw NSError(domain: "MakeIcon", code: 4)
        }
        let sizes: [(String, Int, String?)] = [
            ("icon_16x16", 16, nil), ("icon_16x16@2x", 32, "ic11"),
            ("icon_32x32", 32, nil), ("icon_32x32@2x", 64, "ic12"),
            ("icon_128x128", 128, "ic07"), ("icon_128x128@2x", 256, "ic13"),
            ("icon_256x256", 256, "ic08"), ("icon_256x256@2x", 512, "ic14"),
            ("icon_512x512", 512, "ic09"), ("icon_512x512@2x", 1024, "ic10")
        ]
        var entries: [(type: String, data: Data)] = []
        for (name, pixels, type) in sizes {
            let data = try render(width: pixels, height: pixels, scale: 1,
                                  inset: CGFloat(pixels) * 0.09, color: .white, artwork: artwork)
            try data.write(to: output.appendingPathComponent(name + ".png"))
            if let type { entries.append((type, data)) }
        }
        let parent = output.deletingLastPathComponent()
        try writeICNS(entries: entries, to: parent.appendingPathComponent("AppIcon.icns"))
        // Match BlackHoleGlyph.pointSize and its native drawing transform exactly.
        for scale in [1, 2] {
            let suffix = scale == 1 ? "" : "@2x"
            try render(width: 26, height: 20, scale: scale, inset: 1, color: .black)
                .write(to: parent.appendingPathComponent("MenuBarIcon" + suffix + ".png"))
        }
        try render(width: 640, height: 538, scale: 1, inset: 0, color: .white)
            .write(to: parent.appendingPathComponent("BrandMark.png"))
        print("Composer fallback iconset written to \(output.path)")
    }

    private static func render(width: Int, height: Int, scale: Int, inset: CGFloat, color: NSColor, artwork: CGImage? = nil) throws -> Data {
        guard let rep = NSBitmapImageRep(bitmapDataPlanes: nil,
                                         pixelsWide: width * scale, pixelsHigh: height * scale,
                                         bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                                         isPlanar: false, colorSpaceName: .deviceRGB,
                                         bytesPerRow: 0, bitsPerPixel: 0),
              let context = NSGraphicsContext(bitmapImageRep: rep)?.cgContext else {
            throw NSError(domain: "MakeIcon", code: 2)
        }
        context.translateBy(x: 0, y: CGFloat(height * scale))
        context.scaleBy(x: CGFloat(scale), y: -CGFloat(scale))
        context.translateBy(x: inset, y: inset)
        let available = CGSize(width: CGFloat(width) - inset * 2, height: CGFloat(height) - inset * 2)
        if let artwork {
            context.interpolationQuality = .high
            context.translateBy(x: 0, y: available.height)
            context.scaleBy(x: 1, y: -1)
            context.draw(artwork, in: CGRect(origin: .zero, size: available))
        } else {
            HornSpiritMark.draw(in: context, size: available, color: color.cgColor)
        }
        rep.size = NSSize(width: width, height: height)
        guard let png = rep.representation(using: .png, properties: [:]) else {
            throw NSError(domain: "MakeIcon", code: 3)
        }
        return png
    }
}

func appendFourCC(_ value: String, to data: inout Data) {
    data.append(contentsOf: value.utf8)
}

func appendUInt32BE(_ value: Int, to data: inout Data) {
    let clamped = UInt32(value)
    data.append(UInt8((clamped >> 24) & 0xff))
    data.append(UInt8((clamped >> 16) & 0xff))
    data.append(UInt8((clamped >> 8) & 0xff))
    data.append(UInt8(clamped & 0xff))
}

func writeICNS(entries: [(type: String, data: Data)], to url: URL) throws {
    let totalLength = 8 + entries.reduce(0) { $0 + 8 + $1.data.count }
    var icns = Data()
    appendFourCC("icns", to: &icns)
    appendUInt32BE(totalLength, to: &icns)
    for entry in entries {
        appendFourCC(entry.type, to: &icns)
        appendUInt32BE(8 + entry.data.count, to: &icns)
        icns.append(entry.data)
    }
    try icns.write(to: url)
}
