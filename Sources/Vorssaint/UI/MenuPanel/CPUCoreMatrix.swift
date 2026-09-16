// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import SwiftUI

struct CPUCoreMatrix: View {
    @ObservedObject private var l10n = L10n.shared
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorSchemeContrast) private var contrast
    @State private var width: CGFloat = 280
    let usage: [Double?]
    var increasedContrast: Bool? = nil
    private var usesIncreasedContrast: Bool { increasedContrast ?? (contrast == .increased) }
    var coreGroups: [CPUCoreGroup]? = nil

    private var groups: [CPUCoreGroup] { coreGroups ?? CPUCoreTopology.groups(for: usage.count) }
    private var rows: [[CPUCoreSegment]] { CPUCoreLayout.rows(groups: groups, width: max(70, width - 16)) }

    private var chipHeight: CGFloat {
        let count = rows.count
        return CGFloat(count * 88 + max(0, count - 1) * 12 + 16)
    }

    var body: some View {
        if !usage.isEmpty {
            GeometryReader { proxy in
                chipRows
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.primary.opacity(0.025), in: RoundedRectangle(cornerRadius: 5))
                .overlay(RoundedRectangle(cornerRadius: 5).strokeBorder(Color.primary.opacity(0.12), lineWidth: 1))
                .onAppear { width = proxy.size.width }
                .onChange(of: proxy.size.width) { _, value in width = value }
            }
            .frame(height: chipHeight)
            .accessibilityElement(children: .contain)
            .accessibilityLabel(CPUCoreStrings.text(l10n.language).title)
            .accessibilityHint(CPUCoreStrings.text(l10n.language).hint)
        }
    }

    private var chipRows: some View {
        let layout = rows
        return VStack(alignment: .leading, spacing: 12) {
            ForEach(layout.indices, id: \.self) { index in
                chipRow(layout[index])
            }
        }
    }

    private func chipRow(_ segments: [CPUCoreSegment]) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ForEach(segments.indices, id: \.self) { index in
                coreGroup(segments[index])
            }
        }
    }

    private func coreGroup(_ segment: CPUCoreSegment) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                ForEach(segment.group.indices, id: \.self) { index in
                    coreBar(index)
                }
            }
            Text("\(CPUCoreStrings.groupName(segment.group.name, language: l10n.language)) ×\(segment.group.indices.count)")
                .font(PanelTypography.meta)
                .foregroundStyle(Color.secondary)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
                .frame(height: 22, alignment: .topLeading)
        }
        .frame(width: segment.width)
    }

    private func coreBar(_ index: Int) -> some View {
        let value = usage.indices.contains(index) ? usage[index].flatMap { $0.isFinite ? min(1, max(0, $0)) : nil } : nil
        return GeometryReader { proxy in
            ZStack(alignment: .bottom) {
                Rectangle().fill(Color.primary.opacity(0.035))
                if let value {
                    Rectangle()
                        .fill(Color.primary.opacity(0.78))
                        .frame(height: proxy.size.height * value)
                } else {
                    Text("–").font(PanelTypography.meta).foregroundStyle(Color.secondary)
                        .frame(maxHeight: .infinity)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 2))
            .overlay {
                RoundedRectangle(cornerRadius: 2)
                    .strokeBorder(usesIncreasedContrast ? Color.primary.opacity(0.65) : Color.primary.opacity(0.25),
                                  style: StrokeStyle(lineWidth: usesIncreasedContrast ? 1.5 : 0.75,
                                                     dash: value == nil ? [2, 2] : []))
            }
            .animation(reduceMotion ? nil : .easeOut(duration: 0.2), value: value)
        }
        .frame(height: 60)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(String(format: CPUCoreStrings.text(l10n.language).coreFormat, index + 1))
        .accessibilityValue(value.map { MetricFormat.percent($0) } ?? "–")
    }
}
