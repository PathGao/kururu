// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import Foundation
import Darwin

/// Downloads theme data only; no extension is installed or executed.
enum ThemeLinkImportService {
    static let maximumDownloadBytes = 20 * 1_024 * 1_024

    static func fetch(_ input: String) async throws -> ImportedTheme {
        let link = try ThemeLinkImportSupport.parse(input)
        try Task.checkCancellation()
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 15
        configuration.timeoutIntervalForResource = 60
        configuration.httpShouldSetCookies = false
        configuration.urlCache = nil
        let session = URLSession(configuration: configuration, delegate: RedirectPolicy(), delegateQueue: nil)
        defer { session.invalidateAndCancel() }
        let data: Data
        do {
            let (bytes, response) = try await session.bytes(from: link.downloadURL)
            guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
                throw ThemeLinkImportError.downloadFailed
            }
            guard response.expectedContentLength <= maximumDownloadBytes else { throw ThemeLinkImportError.tooLarge }
            var received = Data()
            for try await byte in bytes {
                try Task.checkCancellation()
                guard received.count < maximumDownloadBytes else { throw ThemeLinkImportError.tooLarge }
                received.append(byte)
            }
            data = received
        } catch {
            if Task.isCancelled { throw CancellationError() }
            throw (error as? ThemeLinkImportError) ?? .downloadFailed
        }
        let worker = Task.detached(priority: .userInitiated) {
            try extract(data, slug: link.slug)
        }
        return try await withTaskCancellationHandler {
            let theme = try await worker.value
            try Task.checkCancellation()
            return theme
        } onCancel: { worker.cancel() }
    }

    static func extract(_ archive: Data, slug: String) throws -> ImportedTheme {
        guard archive.count <= maximumDownloadBytes else { throw ThemeLinkImportError.tooLarge }
        try Task.checkCancellation()
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true,
                                                attributes: [.posixPermissions: 0o700])
        defer { try? FileManager.default.removeItem(at: directory) }
        let file = directory.appendingPathComponent("theme.vsix")
        try archive.write(to: file, options: .atomic)
        let summary = try runUnzip(["-Z", "-t", file.path], limit: 4096)
        guard let text = String(data: summary, encoding: .utf8) else { throw ThemeLinkImportError.invalidArchive }
        let fields = text.split(separator: ",")
        guard fields.count >= 2,
              let count = fields[0].split(separator: " ").first.flatMap({ Int($0) }),
              let expanded = fields[1].split(separator: " ").first.flatMap({ Int($0) }),
              count <= 10_000, expanded <= 100 * 1_024 * 1_024 else { throw ThemeLinkImportError.tooLarge }
        let manifest = try readEntry("extension/package.json", archive: file, limit: 256 * 1_024)
        let selection = try ThemeLinkImportSupport.selection(manifest: manifest, slug: slug)
        let theme = try readEntry(selection.path, archive: file, limit: ThemeImportSupport.maximumBytes)
        try Task.checkCancellation()
        do {
            let parsed = try ThemeImportSupport.parse(theme)
            return ImportedTheme(name: parsed.name.isEmpty ? selection.name : parsed.name, colors: parsed.colors)
        }
        catch { throw ThemeLinkImportError.invalidTheme }
    }

    private static func readEntry(_ path: String, archive: URL, limit: Int) throws -> Data {
        try runUnzip(["-p", archive.path, path], limit: limit)
    }

    private static func runUnzip(_ arguments: [String], limit: Int) throws -> Data {
        // Only bounded stdout is read; no archive member is written to disk.
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/unzip")
        process.arguments = arguments
        process.environment = ["LC_ALL": "C", "LANG": "C"]
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice
        try Task.checkCancellation()
        try process.run()
        let deadline = DispatchWorkItem { if process.isRunning { kill(process.processIdentifier, SIGKILL) } }
        DispatchQueue.global().asyncAfter(deadline: .now() + 10, execute: deadline)
        defer {
            deadline.cancel()
            if process.isRunning { kill(process.processIdentifier, SIGKILL) }
            process.waitUntilExit()
            try? pipe.fileHandleForReading.close()
        }
        var data = Data()
        while true {
            try Task.checkCancellation()
            let chunk = pipe.fileHandleForReading.readData(ofLength: 16 * 1_024)
            if chunk.isEmpty { break }
            guard data.count + chunk.count <= limit else { throw ThemeLinkImportError.tooLarge }
            data.append(chunk)
        }
        process.waitUntilExit()
        guard process.terminationStatus == 0 else { throw ThemeLinkImportError.invalidArchive }
        return data
    }

    private final class RedirectPolicy: NSObject, URLSessionTaskDelegate {
        func urlSession(_ session: URLSession, task: URLSessionTask,
                        willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest,
                        completionHandler: @escaping (URLRequest?) -> Void) {
            guard let url = request.url, url.scheme == "https", url.user == nil, url.password == nil,
                  url.port == nil, let host = url.host?.lowercased(),
                  host.hasSuffix(".gallery.vsassets.io") || host.hasSuffix(".gallerycdn.vsassets.io") else {
                completionHandler(nil)
                return
            }
            completionHandler(request)
        }
    }
}
