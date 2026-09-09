// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

// Renders the installer (DMG) window background: a clean light panel with the
// app title and an arrow pointing from the app icon toward the Applications
// folder. The two icons themselves are placed by Finder on top of this image.
// Usage: swift Tools/MakeDMGBackground.swift <output.png>
import AppKit

// Window is 600×400 pt; render at 2× for Retina sharpness.
let scale: CGFloat = 2
let widthPt: CGFloat = 600, heightPt: CGFloat = 400
let px = Int(widthPt * scale), py = Int(heightPt * scale)

let out = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "dmg-background.png"
let scriptDir = URL(fileURLWithPath: CommandLine.arguments[0]).deletingLastPathComponent()
let logoPath = scriptDir.deletingLastPathComponent().appendingPathComponent("Resources/Brand/logo.png").path

guard let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: px, pixelsHigh: py,
                                 bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                                 isPlanar: false, colorSpaceName: .deviceRGB,
                                 bytesPerRow: 0, bitsPerPixel: 0),
      let ctx = NSGraphicsContext(bitmapImageRep: rep) else { exit(1) }
rep.size = NSSize(width: widthPt, height: heightPt)

NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = ctx
ctx.cgContext.scaleBy(x: scale, y: scale)   // draw in points, output at 2×

let full = NSRect(x: 0, y: 0, width: widthPt, height: heightPt)

// Soft vertical gradient, light and neutral.
NSGradient(colors: [
    NSColor(calibratedWhite: 0.99, alpha: 1),
    NSColor(calibratedWhite: 0.94, alpha: 1),
])?.draw(in: full, angle: -90)

// Title (origin is bottom-left, so high y = near the top).
let title = "Vorssaint"
let titleAttrs: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 26, weight: .bold),
    .foregroundColor: NSColor(calibratedWhite: 0.12, alpha: 1),
]
let titleSize = title.size(withAttributes: titleAttrs)
title.draw(at: NSPoint(x: (widthPt - titleSize.width) / 2, y: heightPt - 70), withAttributes: titleAttrs)

// Subtitle / instruction.
let subtitle = "Arraste o app para a pasta Aplicativos · Drag the app to Applications"
let subAttrs: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 12, weight: .regular),
    .foregroundColor: NSColor(calibratedWhite: 0.45, alpha: 1),
]
let subSize = subtitle.size(withAttributes: subAttrs)
subtitle.draw(at: NSPoint(x: (widthPt - subSize.width) / 2, y: 54), withAttributes: subAttrs)

// Arrow between the icon columns (icons sit at x≈150 and x≈450, centered at y≈200
// from the top → y≈200 from the bottom in this 400-tall canvas).
let arrowY: CGFloat = heightPt - 200
let arrow = NSBezierPath()
arrow.lineWidth = 9
arrow.lineCapStyle = .round
arrow.lineJoinStyle = .round
arrow.move(to: NSPoint(x: 250, y: arrowY))
arrow.line(to: NSPoint(x: 348, y: arrowY))
arrow.move(to: NSPoint(x: 330, y: arrowY + 16))
arrow.line(to: NSPoint(x: 350, y: arrowY))
arrow.line(to: NSPoint(x: 330, y: arrowY - 16))
NSColor(calibratedRed: 0.40, green: 0.34, blue: 0.78, alpha: 0.9).setStroke()
arrow.stroke()

NSGraphicsContext.restoreGraphicsState()

// Embed the brand mark watermark faintly behind the title (optional, subtle).
if let logo = NSImage(contentsOfFile: logoPath) {
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = ctx
    ctx.cgContext.scaleBy(x: scale, y: scale)
    let mark = NSRect(x: widthPt / 2 - 16, y: heightPt - 112, width: 32, height: 32)
    logo.draw(in: mark, from: .zero, operation: .sourceOver, fraction: 0.12)
    NSGraphicsContext.restoreGraphicsState()
}

guard let data = rep.representation(using: .png, properties: [:]) else { exit(1) }
do {
    try data.write(to: URL(fileURLWithPath: out))
    print("dmg background written to \(out)")
} catch {
    print("failed: \(error)")
    exit(1)
}
