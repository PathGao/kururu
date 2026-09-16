// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import SwiftUI

/// Settings groups share a surface while controls retain native semantics.
struct SettingsSection<Header: View, Content: View, Footer: View>: View {
    private let header: Header
    private let content: Content
    private let footer: Footer

    init(@ViewBuilder content: () -> Content,
         @ViewBuilder header: () -> Header,
         @ViewBuilder footer: () -> Footer) {
        self.content = content()
        self.header = header()
        self.footer = footer()
    }

    @ViewBuilder
    var body: some View {
        groupedSection
    }

    private var sectionHeader: some View {
        header
            .font(SettingsTypography.sectionTitle)
            .foregroundStyle(.primary)
            .accessibilityAddTraits(.isHeader)
    }

    private var sectionContent: some View {
        VStack(alignment: .leading, spacing: SettingsVisualStyle.current.contentSpacing) {
            content
                .font(SettingsTypography.body)
                .buttonStyle(.bordered)
            footer.font(SettingsTypography.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var groupedSection: some View {
        if SettingsVisualStyle.current == .columns, Header.self != EmptyView.self {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .top, spacing: 24) {
                    sectionHeader.frame(width: 132, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)
                    sectionContent.frame(minWidth: 320).settingsSurface()
                }
                VStack(alignment: .leading, spacing: 14) {
                    sectionHeader
                    sectionContent.settingsSurface()
                }
            }
        } else {
            VStack(alignment: .leading, spacing: SettingsVisualStyle.current == .compact ? 10 : 14) {
                if Header.self != EmptyView.self { sectionHeader }
                sectionContent
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .settingsSurface()
        }
    }

}

extension SettingsSection where Header == EmptyView, Footer == EmptyView {
    init(@ViewBuilder content: () -> Content) {
        self.init(content: content, header: { EmptyView() }, footer: { EmptyView() })
    }
}

extension SettingsSection where Header == Text, Footer == EmptyView {
    init(_ title: String, @ViewBuilder content: () -> Content) {
        self.init(content: content, header: { Text(title) }, footer: { EmptyView() })
    }
}

extension SettingsSection where Footer == EmptyView {
    init(@ViewBuilder content: () -> Content, @ViewBuilder header: () -> Header) {
        self.init(content: content, header: header, footer: { EmptyView() })
    }
}

extension SettingsSection where Header == EmptyView {
    init(@ViewBuilder content: () -> Content, @ViewBuilder footer: () -> Footer) {
        self.init(content: content, header: { EmptyView() }, footer: footer)
    }
}

/// Consequences and scope should remain readable next to the action they explain.
struct SettingsExplanation: View {
    let text: String

    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text)
            .font(SettingsTypography.body)
            .foregroundStyle(.primary)
            .fixedSize(horizontal: false, vertical: true)
    }
}


struct SettingsSectionHeading: View {
    let title: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 10) {
            SettingsSymbol(systemImage: systemImage)
            Text(title).font(SettingsTypography.sectionTitle)
        }
    }
}

extension SettingsSection where Header == SettingsSectionHeading, Footer == EmptyView {
    init(title: String, systemImage: String, @ViewBuilder content: () -> Content) {
        self.init(content: content,
                  header: { SettingsSectionHeading(title: title, systemImage: systemImage) },
                  footer: { EmptyView() })
    }
}
