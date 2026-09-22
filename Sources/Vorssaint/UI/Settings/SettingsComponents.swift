// SPDX-License-Identifier: GPL-3.0-or-later
import SwiftUI

/// Settings labels and controls share a scale; compact menu panels keep their own typography.
enum SettingsTypography {
    static let body = Font.body
    static let caption = Font.callout
    static let sectionTitle = Font.headline
    static let icon = Font.body
    static let smallIcon = Font.callout
}

/// Shared metrics for settings pages, so headers, sections and cards line up.
enum SettingsMetrics {
    static let pageInset: CGFloat = 24
    static let sectionSpacing: CGFloat = 16
    static let contentSpacing: CGFloat = 16
    static let rowInset: CGFloat = 12
    static let cornerRadius: CGFloat = 16
    static let titleFont = Font.system(size: 24, weight: .semibold)

    /// The page background behind every settings detail view.
    static func canvas(_ scheme: ColorScheme) -> some View {
        Color(nsColor: .windowBackgroundColor)
            .overlay(Color.primary.opacity(scheme == .light ? 0.04 : 0))
    }
}

struct SettingsForm<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        Form { content }
            .formStyle(.grouped)
            .environment(\.inSettingsForm, true)
            .font(SettingsTypography.body)
            .toggleStyle(.switch)
    }
}

private struct InSettingsFormKey: EnvironmentKey { static let defaultValue = false }

extension EnvironmentValues {
    /// Sections become native grouped rows inside a Form and keep their card elsewhere.
    var inSettingsForm: Bool {
        get { self[InSettingsFormKey.self] }
        set { self[InSettingsFormKey.self] = newValue }
    }
}

extension View {
    /// Compact panel surfaces keep checkboxes; the same controls in Settings use switches.
    @ViewBuilder
    func toggleStyle(compact: Bool) -> some View {
        if compact { toggleStyle(.checkbox) } else { toggleStyle(.switch) }
    }

    func settingsSurface() -> some View { modifier(SettingsSurfaceModifier(item: false)) }
    func settingsItemSurface() -> some View { modifier(SettingsSurfaceModifier(item: true)) }
}

private struct SettingsSurfaceModifier: ViewModifier {
    let item: Bool
    @Environment(\.colorScheme) private var scheme
    @Environment(\.colorSchemeContrast) private var contrast

    func body(content: Content) -> some View {
        content
            .padding(item ? SettingsMetrics.rowInset : 16)
            .background {
                if !item {
                    RoundedRectangle(cornerRadius: SettingsMetrics.cornerRadius, style: .continuous)
                        .fill(scheme == .dark ? Color.white.opacity(0.055) : Color(nsColor: .controlBackgroundColor))
                }
            }
            .overlay {
                if !item {
                    RoundedRectangle(cornerRadius: SettingsMetrics.cornerRadius, style: .continuous)
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
        let accent = isEnabled ? Color.accentColor : Color.secondary
        Image(systemName: systemImage)
            .font(.system(.title3, weight: .medium))
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
        HStack(spacing: 6) {
            Text(title)
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
                    label
                    Spacer(minLength: 18)
                    controls.fixedSize(horizontal: true, vertical: false)
                }
                VStack(alignment: .leading, spacing: 10) {
                    label
                    controls.frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            if let caption {
                Text(caption).font(SettingsTypography.caption).foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
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

/// A checkbox bound by key, so a row needs no stored property of its own.
struct SettingsVisibilityCheckbox: View {
    let title: String
    var symbolName: String? = nil
    @AppStorage private var isOn: Bool

    init(title: String, key: String, symbolName: String? = nil) {
        self.title = title
        self.symbolName = symbolName
        _isOn = AppStorage(wrappedValue: true, key)
    }

    var body: some View {
        Toggle(isOn: $isOn) {
            if let symbolName {
                Label(title, systemImage: symbolName)
            } else {
                Text(title).lineLimit(1).truncationMode(.tail)
            }
        }
        .toggleStyle(.checkbox)
        .help(title)
    }
}

/// How many of a row's items are on, readable without expanding it.
struct SettingsCountBadge: View {
    let text: String

    var body: some View {
        Text(text)
            .font(SettingsTypography.caption.monospacedDigit())
            .foregroundStyle(.secondary)
            .padding(.horizontal, 7)
            .padding(.vertical, 2)
            .background(Capsule().fill(Color.primary.opacity(0.06)))
    }
}
