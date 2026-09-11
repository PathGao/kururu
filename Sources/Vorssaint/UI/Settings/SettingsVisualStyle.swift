// SPDX-License-Identifier: GPL-3.0-or-later
import SwiftUI

/// Settings labels and controls share a scale; compact menu panels keep their own typography.
enum SettingsTypography {
    static let body = Font.system(size: 13)
    static let caption = Font.system(size: 12)
    static let sectionTitle = Font.system(size: 13, weight: .semibold)
    static let icon = Font.system(size: 13)
    static let smallIcon = Font.system(size: 12)
}

/// Review bundles select a layout without changing the user's installed app or palette.
enum SettingsVisualStyle: String, CaseIterable {
    case paper = "A", cards = "B", columns = "C", compact = "D"

    static var preview: Self? { VisualReviewConfiguration.current.flatMap(Self.init(rawValue:)) }
    static var isPreview: Bool { preview != nil }
    static var current: Self { preview ?? .cards }
    var name: String {
        switch self {
        case .paper: return "留白"
        case .cards: return "分组"
        case .columns: return "双栏"
        case .compact: return "紧凑"
        }
    }
    var englishName: String {
        switch self {
        case .paper: return "Air"
        case .cards: return "Cards"
        case .columns: return "Columns"
        case .compact: return "Compact"
        }
    }
    var pageInset: CGFloat { self == .paper ? 32 : self == .compact ? 20 : 24 }
    var sectionSpacing: CGFloat { self == .paper ? 32 : self == .compact ? 14 : 16 }
    var contentSpacing: CGFloat { self == .compact ? 10 : self == .paper ? 20 : 16 }
    var rowInset: CGFloat { self == .compact ? 8 : 12 }
    var cornerRadius: CGFloat { self == .cards ? 16 : self == .columns ? 12 : 8 }
    var titleFont: Font { .system(size: self == .paper ? 29 : self == .compact ? 22 : 24, weight: .semibold) }
    var accent: Color {
        switch self {
        case .paper: return Color(red: 0.16, green: 0.40, blue: 0.43)
        case .cards: return Color(red: 0.31, green: 0.34, blue: 0.75)
        case .columns: return Color(red: 0.22, green: 0.43, blue: 0.67)
        case .compact: return Color(red: 0.45, green: 0.34, blue: 0.56)
        }
    }
    func canvas(_ scheme: ColorScheme) -> Color {
        if scheme == .dark { return Color(nsColor: .windowBackgroundColor) }
        switch self {
        case .paper: return Color(red: 0.985, green: 0.982, blue: 0.972)
        case .cards: return Color(red: 0.949, green: 0.954, blue: 0.971)
        case .columns: return Color(nsColor: .textBackgroundColor)
        case .compact: return Color(nsColor: .windowBackgroundColor)
        }
    }
}

struct SettingsForm<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: SettingsVisualStyle.current.sectionSpacing) {
                content
            }
            .frame(maxWidth: 760, alignment: .leading)
            .padding(SettingsVisualStyle.current.pageInset)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .font(SettingsTypography.body)
        .toggleStyle(.checkbox)
        .buttonStyle(SettingsActionStyle())
        .controlSize(SettingsVisualStyle.current == .compact ? .small : .regular)
    }
}

extension View {
    func settingsSurface() -> some View { modifier(SettingsSurfaceModifier(item: false)) }
    func settingsItemSurface() -> some View { modifier(SettingsSurfaceModifier(item: true)) }
}

private struct SettingsSurfaceModifier: ViewModifier {
    let item: Bool
    @ObservedObject private var theme = ThemePreferences.shared
    @Environment(\.colorScheme) private var scheme
    @Environment(\.colorSchemeContrast) private var contrast
    private var style: SettingsVisualStyle { .current }

    func body(content: Content) -> some View {
        content
            .padding(item ? style.rowInset : style == .paper ? 0 : 16)
            .background {
                if !item && style != .paper {
                    RoundedRectangle(cornerRadius: style.cornerRadius, style: .continuous)
                        .fill(style == .cards ? (Theme.color(.card, in: theme.applied) ?? (scheme == .dark ? Color.white.opacity(0.055) : Color(nsColor: .controlBackgroundColor))) : Color.primary.opacity(scheme == .dark ? 0.045 : 0.025))
                }
            }
            .overlay {
                if contrast == .increased && !item {
                    RoundedRectangle(cornerRadius: style.cornerRadius)
                        .strokeBorder(Color.primary.opacity(0.35), lineWidth: 1)
                }
            }
    }
}

/// Settings-only interaction roles. Native buttons retain their actions, keyboard
/// shortcuts and accessibility labels while sharing geometry and feedback.
enum SettingsActionRole { case primary, secondary }

struct SettingsActionStyle: ButtonStyle {
    var role: SettingsActionRole = .secondary

    func makeBody(configuration: Configuration) -> some View {
        SettingsActionBody(configuration: configuration, role: role)
    }
}

private struct SettingsActionBody: View {
    let configuration: ButtonStyleConfiguration
    let role: SettingsActionRole
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.isFocused) private var isFocused
    @Environment(\.colorScheme) private var scheme
    @Environment(\.colorSchemeContrast) private var contrast
    @ObservedObject private var theme = ThemePreferences.shared
    @State private var hovered = false

    private var accent: Color { SettingsVisualStyle.current.controlAccent(scheme, theme: theme.applied) }
    private var emphasized: Bool { role == .primary || configuration.role == .destructive }
    private var ink: Color { configuration.role == .destructive ? .red : role == .primary ? accent : .primary }

    var body: some View {
        configuration.label
            .font(SettingsTypography.body.weight(.medium))
            .symbolRenderingMode(.hierarchical)
            .padding(.horizontal, 11)
            .padding(.vertical, 6)
            .frame(minHeight: 30)
            .foregroundStyle(ink)
            .background {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(emphasized ? ink.opacity(configuration.isPressed ? 0.25 : hovered ? 0.19 : 0.12)
                          : Color.primary.opacity(configuration.isPressed ? 0.13 : hovered ? 0.09 : scheme == .dark ? 0.06 : 0.035))
            }
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(isFocused ? accent : (emphasized ? ink.opacity(0.30) : Color.primary.opacity(contrast == .increased ? 0.4 : 0.12)), lineWidth: isFocused ? 2 : 1)
            }
            .opacity(isEnabled ? 1 : 0.42)
            .contentShape(RoundedRectangle(cornerRadius: 8))
            .onHover { hovered = $0 }
    }
}

extension SettingsVisualStyle {
    func controlAccent(_ scheme: ColorScheme, theme: ImportedTheme?) -> Color {
        Theme.color(.accent, in: theme) ?? (scheme == .dark
            ? Color(red: 0.70, green: 0.73, blue: 1.0) : accent)
    }
}

extension View {
    func settingsAction(_ role: SettingsActionRole = .secondary) -> some View {
        buttonStyle(SettingsActionStyle(role: role))
    }
}

struct SettingsSymbol: View {
    let systemImage: String
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.colorScheme) private var scheme
    @ObservedObject private var theme = ThemePreferences.shared

    var body: some View {
        let accent = isEnabled ? SettingsVisualStyle.current.controlAccent(scheme, theme: theme.applied) : Color.secondary
        Image(systemName: systemImage)
            .font(.system(size: 15, weight: .medium))
            .symbolRenderingMode(.hierarchical)
            .foregroundStyle(accent)
            .frame(width: 30, height: 30)
            .background(accent.opacity(0.10), in: RoundedRectangle(cornerRadius: 8))
            .accessibilityHidden(true)
    }
}

/// Name, consequence and control are one visual unit. Long labels or wider
/// controls move below the label instead of compressing each other.
struct SettingsControlRow<Control: View>: View {
    let title: String
    let systemImage: String
    var caption: String? = nil
    @ViewBuilder let control: Control

    private var label: some View {
        HStack(spacing: 10) {
            SettingsSymbol(systemImage: systemImage)
            Text(title).font(SettingsTypography.body.weight(.medium))
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var controls: some View {
        HStack(spacing: 8) { control }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .center, spacing: 0) {
                    label.frame(width: 180, alignment: .leading)
                    Spacer(minLength: 18)
                    controls.fixedSize(horizontal: true, vertical: false)
                }
                VStack(alignment: .leading, spacing: 10) {
                    label
                    controls.frame(maxWidth: .infinity, alignment: .leading).padding(.leading, 40)
                }
            }
            if let caption {
                Text(caption).font(SettingsTypography.caption).foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 40)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .contain)
    }
}

struct SettingsInfo: View {
    let text: String
    var systemImage: String = "info.circle"
    var warning = false

    var body: some View {
        HStack(alignment: .top, spacing: 9) {
            Image(systemName: systemImage).font(SettingsTypography.icon)
                .foregroundStyle(warning ? Color.orange : Color.secondary).padding(.top, 1).accessibilityHidden(true)
            Text(text).font(SettingsTypography.caption).foregroundStyle(warning ? Color.orange : Color.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(11)
        .background(Color.primary.opacity(0.035), in: RoundedRectangle(cornerRadius: 9))
    }
}
