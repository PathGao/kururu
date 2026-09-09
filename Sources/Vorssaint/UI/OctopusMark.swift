// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import SwiftUI

enum OctopusMark {
    static func draw(in context: CGContext, size: CGSize, color: CGColor) {
        context.saveGState()
        defer { context.restoreGState() }
        let scale = min(size.width / 250, size.height / 210)
        context.translateBy(x: (size.width - 250 * scale) / 2, y: (size.height - 210 * scale) / 2)
        context.scaleBy(x: scale, y: scale)
        context.translateBy(x: 125, y: 90)
        context.setFillColor(color)
        for path in silhouettes { context.addPath(path.cgPath); context.fillPath() }
        context.setBlendMode(.clear)
        for x in [-23.0, 9.0] {
            context.addPath(CGPath(roundedRect: CGRect(x: x, y: -32, width: 14, height: 30),
                                   cornerWidth: 7, cornerHeight: 7, transform: nil))
            context.fillPath()
        }
    }

    // Rest pose from the supplied 2026-09-07 study, with its eight tapered arms.
    private static let arms: [[CGPoint]] = [
        [CGPoint(x: -14, y: 21), CGPoint(x: -45, y: 25), CGPoint(x: -65, y: 40), CGPoint(x: -87, y: 39), CGPoint(x: -108, y: 25), CGPoint(x: -113, y: 9), CGPoint(x: -106, y: 4), CGPoint(x: -100, y: 12)],
        [CGPoint(x: 14, y: 21), CGPoint(x: 45, y: 24), CGPoint(x: 67, y: 33), CGPoint(x: 89, y: 28), CGPoint(x: 103, y: 10), CGPoint(x: 100, y: -4), CGPoint(x: 90, y: -5), CGPoint(x: 86, y: 3)],
        [CGPoint(x: -14, y: 21), CGPoint(x: -42, y: 45), CGPoint(x: -58, y: 65), CGPoint(x: -77, y: 72), CGPoint(x: -91, y: 66), CGPoint(x: -94, y: 52), CGPoint(x: -85, y: 47), CGPoint(x: -80, y: 54)],
        [CGPoint(x: 14, y: 21), CGPoint(x: 43, y: 44), CGPoint(x: 66, y: 58), CGPoint(x: 85, y: 58), CGPoint(x: 97, y: 48), CGPoint(x: 93, y: 37), CGPoint(x: 84, y: 38), CGPoint(x: 83, y: 45)],
        [CGPoint(x: -14, y: 21), CGPoint(x: -25, y: 49), CGPoint(x: -35, y: 74), CGPoint(x: -48, y: 94), CGPoint(x: -64, y: 99), CGPoint(x: -72, y: 90), CGPoint(x: -69, y: 79), CGPoint(x: -62, y: 81)],
        [CGPoint(x: 14, y: 21), CGPoint(x: 19, y: 50), CGPoint(x: 29, y: 80), CGPoint(x: 43, y: 103), CGPoint(x: 61, y: 110), CGPoint(x: 73, y: 100), CGPoint(x: 68, y: 89), CGPoint(x: 61, y: 93)],
        [CGPoint(x: -14, y: 21), CGPoint(x: -47, y: 37), CGPoint(x: -61, y: 48), CGPoint(x: -69, y: 41), CGPoint(x: -70, y: 25), CGPoint(x: -64, y: 11), CGPoint(x: -56, y: 8), CGPoint(x: -52, y: 16)],
        [CGPoint(x: 14, y: 21), CGPoint(x: 45, y: 39), CGPoint(x: 56, y: 61), CGPoint(x: 51, y: 81), CGPoint(x: 34, y: 87), CGPoint(x: 24, y: 79), CGPoint(x: 28, y: 69), CGPoint(x: 35, y: 72)],
    ]

    static let silhouettes: [Path] = {
        var paths: [Path] = []
        for (index, arm) in arms.enumerated() {
            var path = Path()
            var left: [CGPoint] = []
            var right: [CGPoint] = []
            for step in 0...70 {
                let t = Double(step) / 70
                let center = sample(arm, at: t)
                let before = sample(arm, at: max(0, t - 0.003))
                let after = sample(arm, at: min(1, t + 0.003))
                let dx = after.x - before.x, dy = after.y - before.y
                let length = max(hypot(dx, dy), 0.001)
                let radius = 3.2 + (index < 4 ? 8.3 : 9.3) * pow(1 - t, 0.85)
                left.append(CGPoint(x: center.x - dy / length * radius,
                                    y: center.y + dx / length * radius))
                right.append(CGPoint(x: center.x + dy / length * radius,
                                     y: center.y - dx / length * radius))
            }
            path.addLines(left + right.reversed())
            path.closeSubpath()
            paths.append(path)
            if let tip = arm.last {
                paths.append(Path(ellipseIn: CGRect(x: tip.x - 3.2, y: tip.y - 3.2, width: 6.4, height: 6.4)))
            }
        }
        var path = Path()
        path.move(to: CGPoint(x: -34, y: 16))
        path.addCurve(to: CGPoint(x: -46, y: -45),
                      control1: CGPoint(x: -38, y: 0), control2: CGPoint(x: -51, y: -20))
        path.addCurve(to: CGPoint(x: 4, y: -82),
                      control1: CGPoint(x: -41, y: -72), control2: CGPoint(x: -21, y: -84))
        path.addCurve(to: CGPoint(x: 47, y: -36),
                      control1: CGPoint(x: 34, y: -81), control2: CGPoint(x: 50, y: -61))
        path.addCurve(to: CGPoint(x: 34, y: 17),
                      control1: CGPoint(x: 45, y: -12), control2: CGPoint(x: 31, y: 0))
        path.addCurve(to: CGPoint(x: 0, y: 38),
                      control1: CGPoint(x: 42, y: 33), control2: CGPoint(x: 19, y: 40))
        path.addCurve(to: CGPoint(x: -34, y: 16),
                      control1: CGPoint(x: -22, y: 39), control2: CGPoint(x: -41, y: 32))
        path.closeSubpath()
        paths.append(path)
        return paths
    }()

    private static func sample(_ points: [CGPoint], at t: Double) -> CGPoint {
        let v = t * Double(points.count - 1)
        let j = min(points.count - 2, Int(v)), u = v - Double(j)
        let a = points[max(0, j - 1)], b = points[j]
        let c = points[j + 1], d = points[min(points.count - 1, j + 2)]
        func coordinate(_ a: Double, _ b: Double, _ c: Double, _ d: Double) -> Double {
            0.5 * (2 * b + (-a + c) * u + (2 * a - 5 * b + 4 * c - d) * u * u
                   + (-a + 3 * b - 3 * c + d) * u * u * u)
        }
        return CGPoint(x: coordinate(a.x, b.x, c.x, d.x),
                       y: coordinate(a.y, b.y, c.y, d.y))
    }
}
