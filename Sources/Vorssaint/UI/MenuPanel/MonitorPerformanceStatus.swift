// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import SwiftUI

struct MonitorPerformanceStatus: View {
    @ObservedObject private var l10n = L10n.shared
    @State private var thermal = ProcessInfo.processInfo.thermalState
    @State private var lowPower = ProcessInfo.processInfo.isLowPowerModeEnabled

    var body: some View {
        let text = MonitorPerformanceStrings.text(l10n.language)
        HStack(spacing: 8) {
            Image(systemName: "thermometer.medium")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(color)
                .frame(width: 24, height: 24)
                .background(color.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
            HStack(spacing: 6) {
                Text(text.title).font(PanelTypography.meta).foregroundStyle(.secondary)
                Text(label(text)).font(.system(size: 12, weight: .semibold))
            }
            Spacer(minLength: 0)
            if lowPower {
                Label(text.lowPower, systemImage: "leaf")
                    .font(PanelTypography.meta)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(10)
        .background(Color.primary.opacity(0.035), in: RoundedRectangle(cornerRadius: 14))
        .help(text.hint)
        .onAppear { refresh() }
        .onReceive(NotificationCenter.default.publisher(for: ProcessInfo.thermalStateDidChangeNotification)
            .receive(on: RunLoop.main)) { _ in refresh() }
        .onReceive(NotificationCenter.default.publisher(for: .NSProcessInfoPowerStateDidChange)
            .receive(on: RunLoop.main)) { _ in refresh() }
    }

    private func refresh() {
        thermal = ProcessInfo.processInfo.thermalState
        lowPower = ProcessInfo.processInfo.isLowPowerModeEnabled
    }

    private func label(_ text: MonitorPerformanceStrings) -> String {
        switch thermal {
        case .nominal: return text.nominal
        case .fair: return text.fair
        case .serious: return text.serious
        case .critical: return text.critical
        @unknown default: return "–"
        }
    }

    private var color: Color {
        switch thermal {
        case .nominal: return .accentColor
        case .fair: return .yellow
        case .serious: return .orange
        case .critical: return .red
        @unknown default: return .secondary
        }
    }
}
