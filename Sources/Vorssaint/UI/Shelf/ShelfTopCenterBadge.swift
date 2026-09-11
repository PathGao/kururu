// SPDX-License-Identifier: GPL-3.0-or-later
import SwiftUI
import UniformTypeIdentifiers

/// A presentation-only entrance to the existing shelf, never a second item store.
struct ShelfTopCenterBadge: View {
    let title: String
    let count: Int
    let hovered: Bool
    let targeted: Bool
    let expandLabel: String
    var increasedContrast: Bool? = nil
    @Environment(\.colorScheme) private var scheme
    @Environment(\.colorSchemeContrast) private var contrast

    private var raised: Bool { increasedContrast ?? (contrast == .increased) }
    private var foreground: Color { scheme == .dark ? .white : Color(white: 0.12) }
    private var background: Color { scheme == .dark ? Color(white: 0.10) : Color(white: 0.96) }

    var body: some View {
        HStack(spacing: 8) {
            BrandMark(width: 18, tint: foreground)
                .accessibilityHidden(true)
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(maxWidth: 150, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
            Text(Self.countLabel(count))
                .font(.system(size: 11, weight: .semibold))
                .monospacedDigit()
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(foreground.opacity(raised ? 0.18 : 0.08), in: Capsule())
            Image(systemName: "chevron.down")
                .font(.system(size: 9, weight: .bold))
                .opacity(hovered || targeted || raised ? 1 : 0.7)
                .accessibilityHidden(true)
        }
        .foregroundStyle(foreground)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(background, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .strokeBorder(targeted ? Color.accentColor : foreground.opacity(raised ? 0.7 : (hovered ? 0.3 : 0.15)),
                              lineWidth: targeted || raised ? 2 : 1)
        }
        .shadow(color: .black.opacity(scheme == .dark ? 0.25 : 0.12), radius: 5, x: 0, y: 2)
        .contentShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title + ", " + String(max(0, count)) + ", " + expandLabel)
        .accessibilityAddTraits(.isButton)
    }

    static func countLabel(_ count: Int) -> String {
        count > 999 ? "999+" : String(max(0, count))
    }
}

/// The full top entrance. Only the shelf badge owns a drop destination.
struct ShelfTopCenterEntry: View {
    let title: String
    let count: Int
    let hovered: Bool
    let targeted: Bool
    let expandLabel: String
    let notesTitle: String?
    let onExpand: () -> Void
    let onNotes: () -> Void
    var onHoverChange: (Bool) -> Void = { _ in }
    var onTargetChange: (Bool) -> Void = { _ in }
    var onDropProviders: (([NSItemProvider]) -> Bool)? = nil
    var increasedContrast: Bool? = nil
    @Environment(\.colorScheme) private var scheme
    @Environment(\.colorSchemeContrast) private var contrast
    private var raised: Bool { increasedContrast ?? (contrast == .increased) }
    private var foreground: Color { scheme == .dark ? .white : Color(white: 0.12) }
    private var background: Color { scheme == .dark ? Color(white: 0.10) : Color(white: 0.96) }

    var body: some View {
        HStack(spacing: 4) {
            if let onDropProviders {
                shelfBadge.onDrop(of: [.fileURL, .image, .url, .text, .plainText],
                                  isTargeted: Binding(get: { targeted }, set: onTargetChange), perform: onDropProviders)
            } else {
                shelfBadge
            }
            if let notesTitle {
                Button(action: onNotes) {
                    Label(notesTitle, systemImage: "note.text")
                        .font(.system(size: 12, weight: .medium))
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .frame(maxWidth: 130, minHeight: 17)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .foregroundStyle(foreground)
                        .background(background, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 13, style: .continuous)
                                .strokeBorder(foreground.opacity(raised ? 0.7 : 0.15), lineWidth: raised ? 2 : 1)
                        }
                        .shadow(color: .black.opacity(scheme == .dark ? 0.25 : 0.12), radius: 5, x: 0, y: 2)
                        .contentShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(notesTitle)
                .help(notesTitle)
            }
        }
        .accessibilityElement(children: .contain)
    }
    private var shelfBadge: some View {
        ShelfTopCenterBadge(title: title, count: count, hovered: hovered, targeted: targeted,
                            expandLabel: expandLabel, increasedContrast: increasedContrast)
            .fixedSize(horizontal: true, vertical: false)
            .onHover(perform: onHoverChange)
            .onTapGesture(perform: onExpand)
            .accessibilityAction { onExpand() }
            .help(expandLabel)
    }

}
