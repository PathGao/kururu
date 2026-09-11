// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import Foundation
import Darwin

enum LocalPortTests {
    static func run(expect: (Bool, String) -> Void) {
        let fixture = "p42\0cserver with spaces\0\nf3\0tIPv4\0PTCP\0n127.0.0.1:8080\0TST=LISTEN\0\nf4\0tIPv6\0PTCP\0n[::1]:8080\0TST=LISTEN\0\nf5\0PTCP\0n127.0.0.1:8080->127.0.0.1:9000\0TST=ESTABLISHED\0\np43\0\nf6\0tIPv4\0PUDP\0n*:5353\0\nf7\0PUDP\0n*:0\0\nf8\0PTCP\0n*:99999\0TST=LISTEN\0\n"
        let rows = LocalPortSupport.parse(Data(fixture.utf8))
        let connected = LocalPortSupport.parse(Data("p44\0cclient\0\nf1\0tIPv4\0PUDP\0n127.0.0.1:6000->127.0.0.1:7000\0\nf2\0tIPv6\0PUDP\0n[::1]:6001->[::1]:7001\0\nf3\0PTCP\0n127.0.0.1:6002->127.0.0.1:7002\0TST=LISTEN\0\n".utf8))
        expect(connected.contains { $0.transport == "UDP" && $0.address == "127.0.0.1" && $0.port == 6000 },
               "connected UDP retains its local IPv4 binding")
        expect(connected.contains { $0.transport == "UDP" && $0.address == "::1" && $0.port == 6001 },
               "connected UDP retains its local IPv6 binding")
        expect(!connected.contains { $0.transport == "TCP" || $0.port == 7000 || $0.port == 7001 },
               "remote endpoints and connected TCP never appear as local listeners")
        expect(rows.count == 3, "parse only valid TCP listeners and unconnected bound UDP sockets")
        expect(rows.first(where: { $0.pid == 42 })?.name == "server with spaces", "field parser preserves spaces in process names")
        expect(rows.contains { $0.address == "::1" && $0.port == 8080 }, "IPv6 listener preserves its address")
        expect(rows.first(where: { $0.pid == 43 })?.name == nil, "missing process name cannot inherit previous process metadata")
        expect(LocalPortSupport.filtered(rows, query: "8080").count == 2, "numeric search matches a full port")
        expect(LocalPortSupport.filtered(rows, query: "808").isEmpty, "numeric search never matches a partial port")
        expect(LocalPortSupport.filtered(rows, query: "SERVER WITH").count == 2, "process search ignores case")
        expect(LocalPortSupport.commandPort("port 8080") == 8080 && LocalPortSupport.commandPort("8080") == 8080,
               "command bar accepts explicit and bare port queries")
        expect(LocalPortSupport.commandPort("65536") == nil && LocalPortSupport.commandPort("80+1") == nil,
               "command port queries reject invalid ports and arithmetic")
        expect(LocalPortScanner.classify(status: 1, timedOut: false, output: Data()).isSuccess,
               "lsof no-match exit is a successful empty snapshot")
        expect(!LocalPortScanner.classify(status: 1, timedOut: false, output: Data("lsof: denied".utf8)).isSuccess,
               "lsof errors never masquerade as an empty complete list")
        expect(!LocalPortScanner.classify(status: 0, timedOut: true, output: Data(fixture.utf8)).isSuccess,
               "timeout never publishes a successful partial snapshot")
        if let row = rows.first {
            var captured = row
            captured.startedAt = 100
            expect(!LocalPortSupport.matchesTarget(captured, startedAt: captured.startedAt!, currentRows: rows, currentStart: 101),
                   "old row retains its original identity after a newer snapshot arrives")
            expect(LocalPortSupport.matchesTarget(row, startedAt: 100, currentRows: rows, currentStart: 100),
                   "unchanged socket and kernel process identity permit termination")
            expect(!LocalPortSupport.matchesTarget(row, startedAt: 100, currentRows: rows, currentStart: 101),
                   "reused PID cannot terminate a newer process")
            expect(!LocalPortSupport.matchesTarget(row, startedAt: 100, currentRows: [], currentStart: 100),
                   "closed socket invalidates a previously confirmed target")
            expect(!LocalPortSupport.matchesTarget(row, startedAt: 100, currentRows: rows, currentStart: nil),
                   "unreadable process identity cannot authorize termination")
        }
        let malformed = LocalPortSupport.parse(Data("p0\0cfake\0\nf1\0PTCP\0n*:80\0TST=LISTEN\0\n".utf8))
        expect(malformed.isEmpty, "invalid PIDs never become actionable rows")
        liveSockets(expect: expect)
    }

    private static func liveSockets(expect: (Bool, String) -> Void) {
        let tcp = socket(AF_INET, SOCK_STREAM, 0)
        let udp = socket(AF_INET, SOCK_DGRAM, 0)
        let connectedUDP = socket(AF_INET, SOCK_DGRAM, 0)
        guard tcp >= 0, udp >= 0, connectedUDP >= 0 else {
            if tcp >= 0 { close(tcp) }
            if udp >= 0 { close(udp) }
            if connectedUDP >= 0 { close(connectedUDP) }
            expect(false, "create controlled test sockets")
            return
        }
        defer { close(tcp); close(udp); close(connectedUDP) }
        func bindLoopback(_ fd: Int32) -> Int? {
            var address = sockaddr_in()
            address.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
            address.sin_family = sa_family_t(AF_INET)
            address.sin_addr.s_addr = inet_addr("127.0.0.1")
            let status = withUnsafePointer(to: &address) {
                $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                    bind(fd, $0, socklen_t(MemoryLayout<sockaddr_in>.size))
                }
            }
            guard status == 0 else { return nil }
            var size = socklen_t(MemoryLayout<sockaddr_in>.size)
            let read = withUnsafeMutablePointer(to: &address) {
                $0.withMemoryRebound(to: sockaddr.self, capacity: 1) { getsockname(fd, $0, &size) }
            }
            return read == 0 ? Int(UInt16(bigEndian: address.sin_port)) : nil
        }
        guard let tcpPort = bindLoopback(tcp), let udpPort = bindLoopback(udp), listen(tcp, 1) == 0 else {
            expect(false, "bind controlled loopback listeners")
            return
        }
        let result = LocalPortScanner.snapshot()
        let pid = getpid()
        expect(result.isSuccess, "local lsof query completes without elevation")
        expect(result.rows.contains { $0.pid == pid && $0.port == tcpPort && $0.transport == "TCP" },
               "query finds our live TCP listener")
        expect(result.rows.contains { $0.pid == pid && $0.port == udpPort && $0.transport == "UDP" },
               "query finds our live UDP binding")
        guard let connectedPort = bindLoopback(connectedUDP) else {
            expect(false, "bind controlled connected UDP socket")
            return
        }
        var peer = sockaddr_in()
        peer.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        peer.sin_family = sa_family_t(AF_INET)
        peer.sin_addr.s_addr = inet_addr("127.0.0.1")
        peer.sin_port = UInt16(udpPort).bigEndian
        // UDP connect selects our own test socket as the peer; it sends no payload.
        let connectedStatus = withUnsafePointer(to: &peer) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                connect(connectedUDP, $0, socklen_t(MemoryLayout<sockaddr_in>.size))
            }
        }
        expect(connectedStatus == 0, "connect UDP only to our controlled loopback socket")
        let connectedResult = LocalPortScanner.snapshot()
        expect(connectedResult.isSuccess && connectedResult.rows.contains {
            $0.pid == pid && $0.port == connectedPort && $0.transport == "UDP" && $0.address == "127.0.0.1"
        }, "query keeps our live connected UDP local port")
    }
}
