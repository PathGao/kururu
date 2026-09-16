// SPDX-License-Identifier: GPL-3.0-or-later
import Combine
import Foundation

@MainActor
final class EnvironmentUpdateChecker: ObservableObject {
    static let shared = EnvironmentUpdateChecker()

    @Published private(set) var records: [String: EnvironmentUpdateRecord] = [:]
    @Published private(set) var isChecking = false
    private var task: Task<Void, Never>?
    private var generation = 0
    private var operationObservation: AnyCancellable?
    private var observedOperation = false
    private var acceptsAutomaticRefresh = true

    private init() {
        let manager = HomebrewManager.shared
        operationObservation = Publishers.CombineLatest4(
            manager.$operation.map { $0 != nil }.removeDuplicates(),
            manager.$isLoadingInstalled.removeDuplicates(),
            manager.$isCheckingEnvironment.removeDuplicates(),
            EnvironmentInspector.shared.$isLoading.removeDuplicates())
            .combineLatest($isChecking.removeDuplicates())
            .sink { [weak self] state, _ in
                guard let self else { return }
                if state.0 { self.observedOperation = true }
                // Published values arrive before assignment. Check the settled state,
                // including the catalog refresh that follows a completed operation.
                DispatchQueue.main.async { [weak self] in
                    guard let self, self.observedOperation,
                          self.acceptsAutomaticRefresh,
                          !HomebrewManager.shared.isBusy,
                          !EnvironmentInspector.shared.isLoading, !self.isChecking else { return }
                    self.observedOperation = false
                    if !self.records.isEmpty { self.refreshAndCheck() }
                }
            }
    }

    func refreshAndCheck() {
        guard !isChecking, !EnvironmentInspector.shared.isLoading else { return }
        acceptsAutomaticRefresh = true
        reset()
        isChecking = true
        let generation = generation
        EnvironmentInspector.shared.refresh { [weak self] report in
            guard let self, self.generation == generation else { return }
            self.isChecking = false
            self.check(report.tools)
        }
    }

    func reset() {
        generation += 1
        task?.cancel()
        task = nil
        records = [:]
        isChecking = false
    }

    func cancel() {
        acceptsAutomaticRefresh = false
        observedOperation = false
        reset()
        EnvironmentInspector.shared.cancel()
        HomebrewManager.shared.cancelEnvironmentUpdateCheck()
    }

    func check(_ tools: [EnvironmentTool]) {
        guard !isChecking else { return }
        acceptsAutomaticRefresh = true
        reset()
        isChecking = true
        let generation = generation
        task = Task {
            let sources = tools.filter { $0.path != nil && $0.source.supportsUpdateCheck }
                .map { ($0.command, $0.source) }
            guard !Task.isCancelled, generation == self.generation else { return }
            records = Dictionary(uniqueKeysWithValues: sources.map {
                ($0.0, EnvironmentUpdateRecord(source: $0.1))
            })
            var brewSnapshots: [String: EnvironmentHomebrewSnapshot] = [:]
            var checkedPrefixes = Set<String>()
            for (command, source) in sources {
                guard !Task.isCancelled, generation == self.generation else { return }
                let result: EnvironmentUpdateResult
                switch source {
                case let .standalone(tool):
                    do {
                        let version = try await Self.latestVersion(tool)
                        let current = tools.first { $0.command == command }?.version ?? ""
                        result = EnvironmentUpdateResult(status: EnvironmentUpdateSupport.comparison(current: current, latest: version))
                    } catch {
                        result = EnvironmentUpdateResult(status: .failed)
                    }
                case let .homebrew(prefix, _, _):
                    if checkedPrefixes.insert(prefix).inserted {
                        brewSnapshots[prefix] = await withCheckedContinuation { continuation in
                            let brewPath = URL(fileURLWithPath: prefix).appendingPathComponent("bin/brew").path
                            HomebrewManager.shared.checkEnvironmentUpdates(brewPath: brewPath) {
                                continuation.resume(returning: $0)
                            }
                        }
                    }
                    if let snapshot = brewSnapshots[prefix] {
                        result = EnvironmentUpdateSupport.homebrewResult(source: source,
                            packages: snapshot.packages, updates: snapshot.updates)
                    } else {
                        result = EnvironmentUpdateResult(status: .failed)
                    }
                default:
                    result = EnvironmentUpdateResult(status: .unsupported)
                }
                guard !Task.isCancelled, generation == self.generation else { return }
                records[command]?.result = result
                records[command]?.checkedAt = Date()
            }
            isChecking = false
            task = nil
        }
    }

    private static func latestVersion(_ tool: String) async throws -> String {
        let repository = tool == "bun" ? "oven-sh/bun" : "astral-sh/uv"
        let url = URL(string: "https://api.github.com/repos/\(repository)/releases/latest")!
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 10
        configuration.timeoutIntervalForResource = 15
        configuration.httpShouldSetCookies = false
        configuration.urlCache = nil
        let session = URLSession(configuration: configuration)
        defer { session.invalidateAndCancel() }
        var request = URLRequest(url: url)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("kururu-environment", forHTTPHeaderField: "User-Agent")
        let (bytes, response) = try await session.bytes(for: request)
        let limit = 1_024 * 1_024
        guard let response = response as? HTTPURLResponse, response.statusCode == 200,
              response.url?.scheme == "https", response.url?.host == "api.github.com",
              response.expectedContentLength <= limit else { throw URLError(.badServerResponse) }
        var data = Data()
        for try await byte in bytes {
            try Task.checkCancellation()
            guard data.count < limit else { throw URLError(.dataLengthExceedsMaximum) }
            data.append(byte)
        }
        guard let version = EnvironmentUpdateSupport.releaseVersion(data, tool: tool) else {
            throw URLError(.cannotParseResponse)
        }
        return version
    }
}
