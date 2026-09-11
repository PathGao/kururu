// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import AppKit

/// Compile together with Sources/Vorssaint/UI/OctopusMark.swift.
/// All renditions share the application's native geometry; no bitmap master is read.
@main
struct MakeIcon {
    static func main() throws {
        guard CommandLine.arguments.count == 2 else {
            throw NSError(domain: "MakeIcon", code: 1, userInfo: [NSLocalizedDescriptionKey: "Usage: MakeIcon OUTPUT.iconset"])
        }
        let output = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
        try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
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
                                  inset: CGFloat(pixels) * 0.09, color: .white, badge: true)
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
        try render(width: 512, height: 512, scale: 1, inset: 48, color: .white, artwork: true)
            .write(to: parent.appendingPathComponent("OctopusArtwork.png"))
        print("Native octopus iconset written to \(output.path)")
    }

    private static func render(width: Int, height: Int, scale: Int, inset: CGFloat, color: NSColor, badge: Bool = false, artwork: Bool = false) throws -> Data {
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
        if badge {
            context.saveGState()
            let radius = available.width * 0.26
            context.addPath(CGPath(roundedRect: CGRect(origin: .zero, size: available),
                                   cornerWidth: radius, cornerHeight: radius, transform: nil))
            context.clip()
            let colors = [NSColor(white: 0.98, alpha: 1).cgColor,
                          NSColor(white: 0.94, alpha: 1).cgColor,
                          NSColor(white: 0.87, alpha: 1).cgColor] as CFArray
            if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors,
                                         locations: [0, 0.5, 1]) {
                context.drawLinearGradient(gradient, start: .zero,
                                           end: CGPoint(x: available.width, y: available.height), options: [])
            }
            context.restoreGState()
            context.translateBy(x: available.width * 0.10, y: available.height * 0.10)
        }
        // Eye cutouts clear only the mark layer, leaving the badge behind them.
        context.beginTransparencyLayer(auxiliaryInfo: nil)
        if badge || artwork {
            let markSize = badge
                ? CGSize(width: available.width * 0.8, height: available.height * 0.8)
                : available
            OctopusMark.drawArtwork(in: context, size: markSize)
        } else {
            OctopusMark.draw(in: context, size: available, color: color.cgColor)
        }
        context.endTransparencyLayer()
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
