// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import Foundation

struct LocalPort: Identifiable, Equatable {
    let pid: Int32
    let name: String?
    let address: String
    let port: Int
    let transport: String
    let family: String
    var startedAt: UInt64? = nil
    var id: String { "\(pid):\(transport):\(family):\(address):\(port)" }
    var endpoint: String { address.contains(":") ? "[\(address)]:\(port)" : "\(address):\(port)" }
    var copyText: String { "\(transport) \(family) \(endpoint)\t\(name ?? "?")\tPID \(pid)" }
}

enum LocalPortSupport {
    static func matchesTarget(_ row: LocalPort, startedAt: UInt64, currentRows: [LocalPort], currentStart: UInt64?) -> Bool {
        currentStart == startedAt && currentRows.contains { $0.id == row.id && $0.name == row.name }
    }

    // lsof -F0 fields are NUL terminated; newlines delimit process/file sets.
    // Parse records, not its locale-dependent human-readable table.
    static func parse(_ data: Data) -> [LocalPort] {
        var pid: Int32?
        var name: String?
        var rows: [LocalPort] = []
        var seen: Set<String> = []
        for record in data.split(separator: 10) {
            let fields = record.split(separator: 0).map { String(decoding: $0, as: UTF8.self) }
            guard let first = fields.first else { continue }
            if first.hasPrefix("p") {
                pid = Int32(first.dropFirst())
                name = fields.first { $0.hasPrefix("c") }.map { String($0.dropFirst()) }
                continue
            }
            guard first.hasPrefix("f"), let pid, pid > 0 else { continue }
            let transport = fields.first { $0.hasPrefix("P") }.map { String($0.dropFirst()) } ?? ""
            let connection = fields.first { $0.hasPrefix("n") }.map { String($0.dropFirst()) } ?? ""
            let endpoint = transport == "UDP" ? connection.components(separatedBy: "->")[0] : connection
            let family = fields.first { $0.hasPrefix("t") }.map { String($0.dropFirst()) } ?? ""
            guard (transport == "TCP" && fields.contains("TST=LISTEN")) || transport == "UDP",
                  !endpoint.contains("->"), let colon = endpoint.lastIndex(of: ":"),
                  let port = Int(endpoint[endpoint.index(after: colon)...]), (1...65535).contains(port)
            else { continue }
            let address = String(endpoint[..<colon]).trimmingCharacters(in: CharacterSet(charactersIn: "[]"))
            guard !address.isEmpty else { continue }
            let row = LocalPort(pid: pid, name: name, address: address, port: port,
                                transport: transport, family: family)
            if seen.insert(row.id).inserted { rows.append(row) }
        }
        return rows.sorted { ($0.port, $0.transport, $0.pid, $0.address, $0.family)
            < ($1.port, $1.transport, $1.pid, $1.address, $1.family) }
    }

    static func filtered(_ rows: [LocalPort], query: String) -> [LocalPort] {
        let query = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return rows }
        if let port = Int(query) { return rows.filter { $0.port == port } }
        return rows.filter { ($0.name ?? "").localizedCaseInsensitiveContains(query)
            || String($0.pid) == query }
    }

    static func commandPort(_ query: String) -> Int? {
        var query = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if query.hasPrefix("port ") { query = String(query.dropFirst(5)).trimmingCharacters(in: .whitespaces) }
        guard !query.isEmpty, query.utf8.allSatisfy({ (48...57).contains($0) }),
              let port = Int(query), (1...65535).contains(port) else { return nil }
        return port
    }
}
