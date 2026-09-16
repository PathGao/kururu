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
        guard Self.isPreview else { return .accentColor }
        switch self {
        case .paper: return Color(red: 0.16, green: 0.40, blue: 0.43)
        case .cards: return Color(red: 0.31, green: 0.34, blue: 0.75)
        case .columns: return Color(red: 0.22, green: 0.43, blue: 0.67)
        case .compact: return Color(red: 0.45, green: 0.34, blue: 0.56)
        }
    }
    @ViewBuilder
    func canvas(_ scheme: ColorScheme) -> some View {
        if !Self.isPreview || scheme == .dark {
            Color(nsColor: .windowBackgroundColor)
                .overlay(Color.primary.opacity(scheme == .light ? 0.04 : 0))
        } else {
            switch self {
            case .paper: Color(red: 0.985, green: 0.982, blue: 0.972)
            case .cards: Color(red: 0.949, green: 0.954, blue: 0.971)
            case .columns: Color(nsColor: .textBackgroundColor)
            case .compact: Color(nsColor: .windowBackgroundColor)
            }
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
        .buttonStyle(.bordered)
        .controlSize(SettingsVisualStyle.current == .compact ? .small : .regular)
    }
}

extension View {
    func settingsSurface() -> some View { modifier(SettingsSurfaceModifier(item: false)) }
    func settingsItemSurface() -> some View { modifier(SettingsSurfaceModifier(item: true)) }
}

private struct SettingsSurfaceModifier: ViewModifier {
    let item: Bool
    @Environment(\.colorScheme) private var scheme
    @Environment(\.colorSchemeContrast) private var contrast
    private var style: SettingsVisualStyle { .current }

    func body(content: Content) -> some View {
        content
            .padding(item ? style.rowInset : style == .paper ? 0 : 16)
            .background {
                if !item && style != .paper {
                    RoundedRectangle(cornerRadius: style.cornerRadius, style: .continuous)
                        .fill(style == .cards ? (scheme == .dark ? Color.white.opacity(0.055) : Color(nsColor: .controlBackgroundColor)) : Color.primary.opacity(scheme == .dark ? 0.045 : 0.025))
                }
            }
            .overlay {
                if !item && style != .paper {
                    RoundedRectangle(cornerRadius: style.cornerRadius, style: .continuous)
                        .strokeBorder(Color.primary.opacity(contrast == .increased ? 0.35 : 0.06),
                                      lineWidth: contrast == .increased ? 1 : 0.5)
                }
            }
    }
}

/// Explicit action roles keep native button rendering and keyboard behavior.
enum SettingsActionRole { case primary, secondary }

extension View {
    @ViewBuilder
    func settingsAction(_ role: SettingsActionRole = .secondary) -> some View {
        if role == .primary {
            buttonStyle(.borderedProminent)
        } else {
            buttonStyle(.bordered)
        }
    }
}

struct SettingsSymbol: View {
    let systemImage: String
    @Environment(\.isEnabled) private var isEnabled
    var body: some View {
        let accent = isEnabled ? SettingsVisualStyle.current.accent : Color.secondary
        Image(systemName: systemImage)
            .font(.system(size: 15, weight: .medium))
            .symbolRenderingMode(.hierarchical)
            .foregroundStyle(accent)
            .frame(width: 30, height: 30)
            .accessibilityHidden(true)
    }
}

/// Name, consequence and control are one visual unit. Long labels or wider
/// controls move below the label instead of compressing each other.
struct SettingsControlRow<Control: View>: View {
    let title: String
    let systemImage: String
    var caption: String? = nil
    var help: String? = nil
    @ViewBuilder let control: Control

    private var label: some View {
        HStack(spacing: 10) {
            SettingsSymbol(systemImage: systemImage)
            Text(title).font(SettingsTypography.body.weight(.medium))
                .fixedSize(horizontal: false, vertical: true)
            if let help { SettingsHelpButton(title: title, text: help) }
            Spacer(minLength: 0)
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

/// Supplemental explanations are available by keyboard or click, not only hover.
struct SettingsHelpButton: View {
    let title: String
    let text: String
    @State private var presented = false

    var body: some View {
        Button { presented.toggle() } label: {
            Image(systemName: "questionmark.circle")
                .font(SettingsTypography.body)
                .foregroundStyle(.secondary)
                .frame(width: 22, height: 22)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityHint(text)
        .help(text)
        .popover(isPresented: $presented) {
            VStack(alignment: .leading, spacing: 8) {
                Text(title).font(SettingsTypography.sectionTitle)
                Text(text).font(SettingsTypography.body)
                    .fixedSize(horizontal: false, vertical: true)
                    .textSelection(.enabled)
            }
            .padding(16)
            .frame(width: 320, alignment: .leading)
        }
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
