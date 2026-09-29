// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import AppKit
import Combine
import os

final class FinderArrangementService: ObservableObject {
    @Published private(set) var snapshot: FinderArrangementSnapshot?
    @Published private(set) var originalRule: FinderArrangementRule?
    @Published private(set) var isBusy = false
    @Published private(set) var failure: FinderArrangementFailure?
    @Published private(set) var completed = false
    private let queue = DispatchQueue(label: "Finder arrangement")

    private static let log = Logger(subsystem: Bundle.main.bundleIdentifier ?? "kururu",
                                    category: "FinderArrangement")
    private static let client = FinderArrangementClient(run: { script in
        let result = AppleScriptRunner.runDetailed(script)
        if !result.ok {
            // Keep the system code, without logging script text or folder paths.
            log.error("Finder script failed, Apple Events code: \(result.errorNumber ?? 0, privacy: .public)")
        }
        return result
    }, acceptsPath: { path in
        let url = URL(fileURLWithPath: path)
        guard url.standardizedFileURL != FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Desktop").standardizedFileURL,
              let values = try? url.resourceValues(forKeys: [.isDirectoryKey, .isPackageKey, .volumeIsLocalKey])
        else { return false }
        return values.isDirectory == true && values.isPackage != true && values.volumeIsLocal == true
    })

    func capture() {
        perform { Self.client.capture() } completion: { [weak self] value in
            self?.replaceTarget(with: value)
        }
    }

    func select(_ url: URL) {
        let path = url.standardizedFileURL.path
        snapshot = nil
        originalRule = nil
        perform { Self.client.acquire(path: path) } completion: { [weak self] value in
            self?.replaceTarget(with: value)
        }
    }

    func apply() {
        guard let snapshot, snapshot.rule != .name else { return }
        perform { Self.client.change(snapshot, to: .name) } completion: { [weak self] value in
            self?.snapshot = value
            self?.originalRule = snapshot.rule
            self?.completed = true
        }
    }

    func restore() {
        guard let snapshot, let originalRule else { return }
        perform { Self.client.change(snapshot, to: originalRule) } completion: { [weak self] value in
            self?.snapshot = value
            self?.originalRule = nil
            self?.completed = true
        }
    }

    private func replaceTarget(with value: FinderArrangementSnapshot) {
        originalRule = nil
        snapshot = value
    }

    private func perform(_ work: @escaping () -> Result<FinderArrangementSnapshot, FinderArrangementFailure>,
                         completion: @escaping (FinderArrangementSnapshot) -> Void) {
        guard !isBusy, AppFeature.finderCutPaste.isAvailable || AppFeature.finderRename.isAvailable else { return }
        isBusy = true
        failure = nil
        completed = false
        queue.async { [weak self] in
            let result = work()
            DispatchQueue.main.async {
                guard let self else { return }
                self.isBusy = false
                switch result {
                case .success(let snapshot): completion(snapshot)
                case .failure(let error): self.failure = error
                }
            }
        }
    }
}
