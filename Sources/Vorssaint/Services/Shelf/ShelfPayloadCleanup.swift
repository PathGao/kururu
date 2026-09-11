// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation
import Darwin

struct ShelfPayloadCandidate {
    let url: URL
    let device: dev_t
    let inode: ino_t
    let modifiedSeconds: Int
    let modifiedNanoseconds: Int
}

enum ShelfPayloadCleanup {
    private static func parent(of url: URL, roots: [URL]) -> (Int32, String)? {
        guard url.isFileURL, !url.path.contains("\0"), url.host == nil || url.host == "" || url.host?.lowercased() == "localhost" else { return nil }
        let path = url.standardizedFileURL.path
        for root in roots where root.isFileURL && !root.path.contains("\0")
            && (root.host == nil || root.host == "" || root.host?.lowercased() == "localhost") {
            let rootPath = root.standardizedFileURL.path
            guard path.hasPrefix(rootPath + "/") else { continue }
            let components = String(path.dropFirst(rootPath.count + 1)).split(separator: "/").map(String.init)
            guard let name = components.last, !name.isEmpty else { continue }
            var fd = open(rootPath, O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC)
            guard fd >= 0 else { continue }
            var valid = true
            for component in components.dropLast() {
                let next = openat(fd, component, O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC)
                close(fd)
                fd = next
                if fd < 0 { valid = false; break }
            }
            if valid { return (fd, name) }
        }
        return nil
    }

    static func capture(_ urls: [URL], roots: [URL], writtenBefore: Date? = nil) -> [ShelfPayloadCandidate] {
        var seen = Set<String>()
        return urls.compactMap { url in
            let canonical = url.standardizedFileURL
            guard seen.insert(canonical.path).inserted,
                  let (fd, name) = parent(of: canonical, roots: roots) else { return nil }
            defer { close(fd) }
            var info = stat()
            guard fstatat(fd, name, &info, AT_SYMLINK_NOFOLLOW) == 0, info.st_mode & S_IFMT == S_IFREG else { return nil }
            let modified = Date(timeIntervalSince1970: Double(info.st_mtimespec.tv_sec) + Double(info.st_mtimespec.tv_nsec) / 1_000_000_000)
            if let writtenBefore, !(modified < writtenBefore) { return nil }
            return ShelfPayloadCandidate(url: canonical, device: info.st_dev, inode: info.st_ino,
                modifiedSeconds: info.st_mtimespec.tv_sec, modifiedNanoseconds: info.st_mtimespec.tv_nsec)
        }
    }

    static func collect(in roots: [URL], writtenBefore: Date) -> [ShelfPayloadCandidate] {
        let urls: [URL] = roots.flatMap { root -> [URL] in
            var info = stat()
            guard root.isFileURL, !root.path.contains("\0"),
                  root.host == nil || root.host == "" || root.host?.lowercased() == "localhost",
                  lstat(root.path, &info) == 0, info.st_mode & S_IFMT == S_IFDIR else { return [] }
            return (try? FileManager.default.contentsOfDirectory(at: root, includingPropertiesForKeys: nil)) ?? []
        }
        return capture(urls, roots: roots, writtenBefore: writtenBefore)
    }

    /// The caller serializes this with reference publication and durable commits.
    static func remove(_ candidates: [ShelfPayloadCandidate], keeping: Set<String>, roots: [URL]) -> [ShelfPayloadCandidate] {
        var retry: [ShelfPayloadCandidate] = []
        for candidate in candidates {
            guard !keeping.contains(candidate.url.standardizedFileURL.path),
                  let (fd, name) = parent(of: candidate.url, roots: roots) else { continue }
            defer { close(fd) }
            var info = stat()
            guard fstatat(fd, name, &info, AT_SYMLINK_NOFOLLOW) == 0,
                  info.st_mode & S_IFMT == S_IFREG,
                  info.st_dev == candidate.device, info.st_ino == candidate.inode,
                  info.st_mtimespec.tv_sec == candidate.modifiedSeconds,
                  info.st_mtimespec.tv_nsec == candidate.modifiedNanoseconds else { continue }
            if unlinkat(fd, name, 0) != 0 && errno != ENOENT { retry.append(candidate) }
        }
        return retry
    }
}
