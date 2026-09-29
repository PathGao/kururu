// SPDX-License-Identifier: GPL-3.0-or-later
import SwiftUI

/// The rail stays fixed while its entries scroll inside the rounded viewport.
struct PanelNavigationScrollView<Content: View>: View {
    let height: CGFloat
    @ViewBuilder let content: Content
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @State private var contentFrame = CGRect.zero
    @Namespace private var viewport

    var body: some View {
        ScrollView(.vertical) {
            content
                .onGeometryChange(for: CGRect.self) { $0.frame(in: .named(viewport)) } action: {
                    contentFrame = $0
                }
        }
        .coordinateSpace(name: viewport)
        .scrollIndicators(.hidden)
        .frame(height: height)
        .mask {
            VStack(spacing: 0) {
                LinearGradient(colors: [contentFrame.minY < -1 ? .clear : .black, .black],
                               startPoint: .top, endPoint: .bottom)
                    .frame(height: 12)
                Rectangle()
                LinearGradient(colors: [.black, contentFrame.maxY > height + 1 ? .clear : .black],
                               startPoint: .top, endPoint: .bottom)
                    .frame(height: 12)
            }
        }
        .background {
            let shape = RoundedRectangle(cornerRadius: 12, style: .continuous)
            if reduceTransparency {
                shape.fill(Color(nsColor: .controlBackgroundColor))
            } else {
                shape.fill(.regularMaterial)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
