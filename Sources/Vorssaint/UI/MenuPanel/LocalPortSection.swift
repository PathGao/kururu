// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import SwiftUI

struct LocalPortSection: View {
    @ObservedObject private var service = LocalPortService.shared
    @ObservedObject private var l10n = L10n.shared
    @State private var expanded = false
    @State private var query = ""

    var body: some View {
        let strings = LocalPortStrings.text(l10n.language)
        DisclosureGroup(strings.title, isExpanded: $expanded) {
            VStack(alignment: .leading, spacing: 8) {
                Text(strings.scope).font(.caption).foregroundStyle(.secondary)
                HStack {
                    TextField(strings.search, text: $query)
                        .textFieldStyle(.roundedBorder)
                    Button(strings.refresh) { service.refresh() }
                        .disabled(service.isLoading)
                }
                if service.isLoading {
                    Text(strings.loading).font(.caption).foregroundStyle(.secondary)
                }
                if service.failed {
                    Text(strings.failed).font(.caption).foregroundStyle(.red)
                }
                let rows = LocalPortSupport.filtered(service.rows, query: query)
                if rows.isEmpty && !service.isLoading && !service.failed {
                    Text(strings.empty).font(.caption).foregroundStyle(.secondary)
                }
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 8) {
                        ForEach(rows) { row in
                            HStack(alignment: .top) {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text("\(row.transport) \(row.family) \(row.endpoint)")
                                        .font(.caption.monospaced()).textSelection(.enabled)
                                    Text("\(row.name ?? strings.restricted) · PID \(row.pid)")
                                        .font(.caption).foregroundStyle(.secondary)
                                    if row.name != nil && row.startedAt == nil {
                                        Text(strings.restricted).font(.caption2).foregroundStyle(.secondary)
                                    }
                                }
                                Spacer(minLength: 4)
                                Menu {
                                    Button(strings.copy) { service.copy(row) }
                                    if service.canTerminate(row) {
                                        Divider()
                                        Button(strings.terminate, role: .destructive) { service.confirmTermination(row) }
                                    }
                                } label: {
                                    Image(systemName: "ellipsis.circle")
                                }
                                .menuStyle(.borderlessButton)
                                .fixedSize()
                                .accessibilityLabel(row.copyText)
                            }
                        }
                    }
                }
                .frame(maxHeight: 240)
            }
            .padding(.top, 6)
        }
        .onChange(of: expanded) { _, value in
            if value { service.refresh() }
        }
    }
}
