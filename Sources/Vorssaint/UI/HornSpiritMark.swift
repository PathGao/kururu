import CoreGraphics

enum HornSpiritMark {
    static func draw(in context: CGContext, size: CGSize, color: CGColor) {
        context.saveGState()
        defer { context.restoreGState() }
        let bounds = outline.boundingBoxOfPath
        let scale = min(size.width / bounds.width, size.height / bounds.height)
        context.translateBy(x: (size.width - bounds.width * scale) / 2,
                            y: (size.height - bounds.height * scale) / 2)
        context.scaleBy(x: scale, y: scale)
        context.translateBy(x: -bounds.minX, y: -bounds.minY)
        context.setFillColor(color)
        context.addPath(outline)
        // Even-odd eye holes stay transparent in either menu bar appearance.
        for x in [8.5, 15.5] {
            context.addEllipse(in: CGRect(x: x - 1, y: 8.4, width: 2, height: 3.2))
        }
        context.fillPath(using: .evenOdd)
    }

    private static let outline: CGPath = {
        let p = CGMutablePath()
        p.move(to: CGPoint(x: 6, y: 8))
        p.addQuadCurve(to: CGPoint(x: 2, y: 2), control: CGPoint(x: 2, y: 7))
        p.addQuadCurve(to: CGPoint(x: 8, y: 4), control: CGPoint(x: 5, y: 5))
        p.addQuadCurve(to: CGPoint(x: 16, y: 4), control: CGPoint(x: 12, y: 1))
        p.addQuadCurve(to: CGPoint(x: 22, y: 2), control: CGPoint(x: 19, y: 5))
        p.addQuadCurve(to: CGPoint(x: 18, y: 8), control: CGPoint(x: 22, y: 7))
        p.addLine(to: CGPoint(x: 20, y: 13))
        p.addLine(to: CGPoint(x: 17, y: 15))
        p.addQuadCurve(to: CGPoint(x: 16, y: 21), control: CGPoint(x: 20, y: 22))
        p.addQuadCurve(to: CGPoint(x: 14, y: 17), control: CGPoint(x: 14, y: 21))
        p.addLine(to: CGPoint(x: 14, y: 20))
        p.addQuadCurve(to: CGPoint(x: 10, y: 20), control: CGPoint(x: 12, y: 24))
        p.addLine(to: CGPoint(x: 10, y: 17))
        p.addQuadCurve(to: CGPoint(x: 7, y: 21), control: CGPoint(x: 10, y: 22))
        p.addQuadCurve(to: CGPoint(x: 7, y: 15), control: CGPoint(x: 4, y: 20))
        p.addLine(to: CGPoint(x: 4, y: 13))
        p.closeSubpath()
        return p
    }()
}
