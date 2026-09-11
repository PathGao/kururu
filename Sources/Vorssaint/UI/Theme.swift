// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import SwiftUI

/// Shared look & feel: brand colors, card styling and the brand mark.
enum Theme {
    static func color(_ role: ThemeColorRole, in palette: ImportedTheme? = ThemePreferences.shared.applied) -> Color? {
        palette?.colors[role].map { Color(.sRGB, red: $0.red, green: $0.green, blue: $0.blue, opacity: $0.alpha) }
    }

    static func colorScheme(in palette: ImportedTheme?, fallback: ColorScheme) -> ColorScheme? {
        guard let background = palette?.colors[.background] else { return nil }
        let base = fallback == .dark ? 0.0 : 1.0
        func linear(_ component: Double) -> Double {
            let value = component * background.alpha + base * (1 - background.alpha)
            return value <= 0.04045 ? value / 12.92 : pow((value + 0.055) / 1.055, 2.4)
        }
        let luminance = 0.2126 * linear(background.red)
            + 0.7152 * linear(background.green) + 0.0722 * linear(background.blue)
        return luminance > 0.179 ? .light : .dark
    }

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
    static var data: Color { (Theme.color(.primaryText) ?? Color.primary).opacity(0.78) }

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
        Theme.color(.background) ?? (scheme == .light ? Color.white.opacity(0.68) : Color.black.opacity(0.42))
    }

    static func cardFill(for scheme: ColorScheme) -> Color {
        Theme.color(.card) ?? (scheme == .light ? Color.white.opacity(0.38) : Color.white.opacity(0.075))
    }

    static func controlFill(for scheme: ColorScheme) -> Color {
        Theme.color(.card) ?? (scheme == .light ? Color.black.opacity(0.055) : Color.white.opacity(0.085))
    }

    /// Raised contrast is asked for by someone who cannot see a hairline at a
    /// tenth of an opacity, so the outlines that separate one card from the
    /// next are the ones that answer. A panel is rebuilt every time it opens,
    /// which is when a change to this setting shows.
    static func border(for scheme: ColorScheme) -> Color {
        let raised = NSWorkspace.shared.accessibilityDisplayShouldIncreaseContrast
        if !raised, let imported = Theme.color(.border) { return imported }
        return scheme == .light
            ? Color.black.opacity(raised ? 0.24 : 0.09)
            : Color.white.opacity(raised ? 0.28 : 0.11)
    }

    /// A control that sits ON a glass surface rather than in it: the system's
    /// own round toggles read as physical because they are lighter than what
    /// is behind them and carry their own shadow.
    static func raisedFill(for scheme: ColorScheme) -> Color {
        Theme.color(.card) ?? (scheme == .light ? Color.white.opacity(0.88) : Color.white.opacity(0.14))
    }

    static func raisedBorder(for scheme: ColorScheme) -> Color {
        let raised = NSWorkspace.shared.accessibilityDisplayShouldIncreaseContrast
        if !raised, let imported = Theme.color(.border) { return imported }
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
    func kururuTheme() -> some View {
        modifier(KururuThemeModifier())
    }

    /// The rounded card background used by every panel section.
    func panelCard() -> some View {
        modifier(PanelCardModifier())
    }

    func panelGlassSurface(cornerRadius: CGFloat = 18) -> some View {
        modifier(PanelGlassModifier(cornerRadius: cornerRadius))
    }

    func panelNavigationSurface() -> some View {
        background(PanelNavigationSurface())
    }
}

private struct KururuThemeModifier: ViewModifier {
    @ObservedObject private var theme = ThemePreferences.shared
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .tint(Theme.color(.accent, in: theme.applied) ?? SettingsVisualStyle.preview?.accent)
            .background(Theme.color(.background, in: theme.applied))
            .preferredColorScheme(Theme.colorScheme(in: theme.applied, fallback: colorScheme))
    }
}

private struct PanelGlassModifier: ViewModifier {
    @ObservedObject private var theme = ThemePreferences.shared
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content.background {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(Theme.color(.background, in: theme.applied) ?? Color(nsColor: .windowBackgroundColor))
                .overlay {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(Color.primary.opacity(0.03))
                }
        }
    }
}

private struct PanelCardModifier: ViewModifier {
    @ObservedObject private var theme = ThemePreferences.shared
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
                    .fill(Theme.color(.card, in: theme.applied) ?? Color(nsColor: .controlBackgroundColor))
            }
            .overlay {
                if contrast == .increased || theme.applied?.colors[.border] != nil {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(PanelSurface.border(for: colorScheme), lineWidth: 1)
                }
            }
        }
    }
}

private struct PanelNavigationSurface: View {
    @ObservedObject private var theme = ThemePreferences.shared
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @AppStorage(DefaultsKey.liquidGlassEnabled) private var liquidGlassEnabled = false

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 12, style: .continuous)
        if let card = Theme.color(.card, in: theme.applied) {
            shape.fill(card)
        } else {
#if compiler(>=6.2)
        if #available(macOS 26.0, *), liquidGlassEnabled, !reduceTransparency {
            shape.fill(Color.clear).glassEffect(.regular, in: shape)
        } else {
            standardSurface(shape)
        }
#else
        standardSurface(shape)
#endif
        }
    }

    @ViewBuilder
    private func standardSurface(_ shape: RoundedRectangle) -> some View {
        if reduceTransparency {
            shape.fill(Color(nsColor: .controlBackgroundColor))
        } else {
            shape.fill(.regularMaterial)
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
