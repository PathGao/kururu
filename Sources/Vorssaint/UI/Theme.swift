// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import SwiftUI

/// Shared look & feel: brand colors, card styling and the brand mark.
enum Theme {
    /// Near-black background behind the brand mark. Neutral greys into black, no
    /// colour cast, with just a hint of depth so the badge does not read as flat.
    static let spaceGradient = LinearGradient(
        colors: [Color(white: 0.10),
                 Color(white: 0.04),
                 Color.black],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

enum PanelTypography {
    static let pageTitle = Font.system(size: 24, weight: .semibold)
    static let panelTitle = Font.system(size: 20, weight: .semibold)
    static let title = Font.system(size: 13, weight: .medium)
    static let body = Font.system(size: 13)
    static let label = Font.system(size: 12)
    static let meta = Font.system(size: 11)
    static let metric = Font.system(size: 16, weight: .medium)
}

struct MetricSymbol: View {
    let name: String

    var body: some View {
        Image(systemName: name)
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(.secondary)
            .frame(width: 20, height: 20)
            .accessibilityHidden(true)
    }
}

enum PanelMetricColor {
    static var data: Color { Color.primary.opacity(0.78) }

    static func green(for scheme: ColorScheme) -> Color {
        scheme == .light ? Color(red: 0.00, green: 0.44, blue: 0.18) : .green
    }

    static func cyan(for scheme: ColorScheme) -> Color {
        scheme == .light ? Color(red: 0.00, green: 0.43, blue: 0.54) : .cyan
    }

    static func mint(for scheme: ColorScheme) -> Color {
        scheme == .light ? Color(red: 0.00, green: 0.44, blue: 0.40) : .mint
    }

    static func yellow(for scheme: ColorScheme) -> Color {
        scheme == .light ? Color(red: 0.56, green: 0.36, blue: 0.00) : .yellow
    }

    static func red(for scheme: ColorScheme) -> Color {
        scheme == .light ? Color(red: 0.68, green: 0.08, blue: 0.10) : .red
    }

    static func orange(for scheme: ColorScheme) -> Color {
        scheme == .light ? Color(red: 0.68, green: 0.30, blue: 0.00) : .orange
    }

    static func pink(for scheme: ColorScheme) -> Color {
        scheme == .light ? Color(red: 0.68, green: 0.06, blue: 0.34) : .pink
    }
}

enum PanelSurface {
    static func baseFill(for scheme: ColorScheme) -> Color {
        scheme == .light ? Color.white.opacity(0.68) : Color.black.opacity(0.42)
    }

    static func cardFill(for scheme: ColorScheme) -> Color {
        scheme == .light ? Color.white.opacity(0.38) : Color.white.opacity(0.075)
    }

    static func controlFill(for scheme: ColorScheme) -> Color {
        scheme == .light ? Color.black.opacity(0.055) : Color.white.opacity(0.085)
    }

    /// Raised contrast is asked for by someone who cannot see a hairline at a
    /// tenth of an opacity, so the outlines that separate one card from the
    /// next are the ones that answer. A panel is rebuilt every time it opens,
    /// which is when a change to this setting shows.
    static func border(for scheme: ColorScheme) -> Color {
        let raised = NSWorkspace.shared.accessibilityDisplayShouldIncreaseContrast
        return scheme == .light
            ? Color.black.opacity(raised ? 0.24 : 0.09)
            : Color.white.opacity(raised ? 0.28 : 0.11)
    }

    /// A control that sits ON a glass surface rather than in it: the system's
    /// own round toggles read as physical because they are lighter than what
    /// is behind them and carry their own shadow.
    static func raisedFill(for scheme: ColorScheme) -> Color {
        scheme == .light ? Color.white.opacity(0.88) : Color.white.opacity(0.14)
    }

    static func raisedBorder(for scheme: ColorScheme) -> Color {
        let raised = NSWorkspace.shared.accessibilityDisplayShouldIncreaseContrast
        return scheme == .light
            ? Color.black.opacity(raised ? 0.22 : 0.07)
            : Color.white.opacity(raised ? 0.32 : 0.16)
    }

    static func raisedShadow(for scheme: ColorScheme) -> Color {
        scheme == .light ? Color.black.opacity(0.14) : Color.black.opacity(0.38)
    }

    /// The lit edge of a glass surface: bright where the light comes from,
    /// gone by the bottom. Without it a translucent panel reads as paper.
    static func rimHighlight(for scheme: ColorScheme) -> LinearGradient {
        LinearGradient(colors: [Color.white.opacity(scheme == .light ? 0.95 : 0.30),
                                Color.white.opacity(scheme == .light ? 0.12 : 0.04)],
                       startPoint: .top,
                       endPoint: .bottom)
    }
}

func sectionTitle(_ text: String) -> some View {
    Text(text)
        .font(PanelTypography.title)
        .foregroundStyle(.primary)
}

extension View {
    /// The rounded card background used by every panel section.
    func panelCard() -> some View {
        modifier(PanelCardModifier())
    }

    func panelGlassSurface(cornerRadius: CGFloat = 18) -> some View {
        modifier(PanelGlassModifier(cornerRadius: cornerRadius))
    }

}

private struct PanelGlassModifier: ViewModifier {
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content.background {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(Color(nsColor: .windowBackgroundColor))
                .overlay {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(Color.primary.opacity(0.03))
                }
        }
    }
}

private struct PanelCardModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.colorSchemeContrast) private var contrast

    @ViewBuilder
    func body(content: Content) -> some View {
        if SettingsVisualStyle.isPreview {
            content.settingsSurface()
        } else {
            content
            .padding(12)
            .background {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(nsColor: .controlBackgroundColor))
            }
            .overlay {
                if contrast == .increased {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(PanelSurface.border(for: colorScheme), lineWidth: 1)
                }
            }
        }
    }
}

func appDelegate() -> AppDelegate? {
    NSApp.delegate as? AppDelegate
}

/// Static, template-colored interpretation of the supplied octopus study.
struct BrandMark: View {
    var width: CGFloat
    var tint: Color = .white

    var body: some View {
        Rectangle().fill(tint).mask {
            Canvas { context, size in
                context.withCGContext { graphics in
                    OctopusMark.draw(in: graphics, size: size, color: NSColor.white.cgColor)
                }
            }
        }
        .frame(width: width, height: width * 210 / 250)
        .accessibilityHidden(true)
    }
}

/// Squircle badge with the mark on the space gradient — the app's face in the
/// About tab and onboarding.
struct BrandBadge: View {
    var size: CGFloat

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.26, style: .continuous)
                .fill(Theme.spaceGradient)
            BrandMark(width: size * 0.8)
        }
        .frame(width: size, height: size)
    }
}
