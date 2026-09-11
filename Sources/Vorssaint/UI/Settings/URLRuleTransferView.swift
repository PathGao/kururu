// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import SwiftUI
import UniformTypeIdentifiers
import Darwin

struct URLRuleTransferView: View {
    @ObservedObject private var l10n = L10n.shared
    @Binding var globalNames: String
    @Binding var siteNames: String
    @Binding var disabledNames: String
    @State private var requestID = UUID()
    @State private var panel: NSSavePanel?
    @State private var busy = false
    @State private var document: URLRuleImportSupport.Document?
    @State private var preview: URLRuleImportSupport.Preview?
    @State private var sourceName = ""
    @State private var message: String?
    @State private var failed = false

    private var zh: Bool { l10n.language == .zhHans }
    private func text(_ chinese: String, _ english: String) -> String { zh ? chinese : english }
    private var current: URLCleaning.Rules {
        URLCleaning.rules(globalNames: globalNames, siteNames: siteNames, disabledNames: disabledNames)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Button(action: chooseImport) {
                    Label(text("导入规则…", "Import rules…"), systemImage: "square.and.arrow.down")
                }
                Button(action: chooseExport) {
                    Label(text("导出规则…", "Export rules…"), systemImage: "square.and.arrow.up")
                }
            }
            .disabled(busy)
            SettingsInfo(text: text("支持 kururu 规则 JSON。导入会保留本地设置；导出仅包含自定义规则和已停用规则，不包含内置规则全集。",
                                    "Supports kururu rules JSON. Import keeps local choices; export includes custom and disabled rules, not the full built-in list."),
                         systemImage: "doc.text")
            if busy {
                HStack {
                    ProgressView().controlSize(.small)
                    Text(text("正在处理规则文件…", "Processing rules file…")).font(SettingsTypography.caption)
                    Spacer()
                    Button(text("取消", "Cancel"), action: cancel)
                }
            }
            if let message {
                Label(message, systemImage: failed ? "exclamationmark.triangle" : "info.circle")
                    .font(SettingsTypography.caption).fixedSize(horizontal: false, vertical: true)
            }
            if let document, let preview {
                Text(text("来源：", "Source: ") + sourceName)
                    .font(.headline).textSelection(.enabled)
                Text(text("新增 \(preview.addedCount) · 状态改变 \(preview.changedCount) · 保留 \(preview.duplicateCount)",
                          "Added \(preview.addedCount) · State changes \(preview.changedCount) · Kept \(preview.duplicateCount)"))
                    .font(SettingsTypography.caption)
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 10) {
                        ForEach(Array(document.rows.enumerated()), id: \.offset) { _, row in
                            VStack(alignment: .leading, spacing: 3) {
                                Text((row.host.isEmpty ? text("所有网站", "All sites") : row.host) + " · " + row.name)
                                    .textSelection(.enabled)
                                let local = preview.baseRules.added[row.host]?.contains(row.name) == true ||
                                    preview.baseRules.disabled[row.host]?.contains(row.name) == true
                                let enabled = local ? preview.baseRules.disabled[row.host]?.contains(row.name) != true : row.enabled
                                Text((enabled ? text("启用", "Enabled") : text("停用", "Disabled")) + " · " +
                                     (local ? text("保留本地设置", "Local choice kept") : text("采用文件设置", "File choice")))
                                    .font(SettingsTypography.caption).foregroundStyle(.secondary)
                            }
                        }
                    }.frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(height: min(240, CGFloat(max(1, document.rows.count)) * 58))
                HStack {
                    Button(text("取消", "Cancel")) { clearPreview() }
                    Spacer()
                    Button(action: confirm) {
                        Label(text("确认合并", "Confirm merge"), systemImage: "arrow.triangle.merge")
                    }
                    .settingsAction(.primary)
                    .disabled(busy)
                }
            }
        }
        .onDisappear(perform: cancel)
    }

    private func clearPreview() {
        document = nil; preview = nil; sourceName = ""; message = nil; failed = false
    }

    private func cancel() {
        requestID = UUID()
        panel?.cancel(nil); panel = nil; busy = false
        clearPreview()
    }

    private func present(_ picker: NSSavePanel, completion: @escaping (NSApplication.ModalResponse) -> Void) {
        panel = picker
        if let window = NSApp.keyWindow {
            picker.beginSheetModal(for: window, completionHandler: completion)
        } else {
            picker.begin(completionHandler: completion)
        }
    }

    private func chooseImport() {
        guard !busy else { return }
        busy = true
        let id = UUID(); requestID = id
        let picker = NSOpenPanel()
        picker.allowedContentTypes = [.json]
        picker.canChooseDirectories = false; picker.canChooseFiles = true
        picker.allowsMultipleSelection = false
        present(picker) { response in
            guard requestID == id else { return }
            panel = nil
            guard response == .OK, let url = picker.url else { busy = false; return }
            clearPreview()
            DispatchQueue.global(qos: .userInitiated).async {
                let result = Result { try URLRuleImportSupport.decode(URLRuleTransferFile.read(url)) }
                DispatchQueue.main.async {
                    guard requestID == id else { return }
                    busy = false
                    switch result {
                    case .success(let loaded):
                        document = loaded
                        preview = URLRuleImportSupport.preview(loaded, current: current)
                        sourceName = url.lastPathComponent
                    case .failure(let error): report(error)
                    }
                }
            }
        }
    }

    private func confirm() {
        guard !busy, let document, let preview else { return }
        let latest = current
        guard latest == preview.baseRules else {
            self.preview = URLRuleImportSupport.preview(document, current: latest)
            failed = false
            message = text("本地规则已改变，预览已更新。请检查后再次确认。", "Local rules changed. Review the updated preview and confirm again.")
            return
        }
        let merged = preview.rules
        globalNames = URLCleaning.storageValue(forNames: merged.added[URLCleaning.allSites] ?? [])
        siteNames = URLCleaning.storageValue(forTokens: merged.added.filter { $0.key != URLCleaning.allSites })
        disabledNames = URLCleaning.storageValue(forTokens: merged.disabled)
        clearPreview()
        message = text("规则已合并。", "Rules merged.")
    }

    private func chooseExport() {
        guard !busy else { return }
        busy = true
        let id = UUID(); requestID = id
        let picker = NSSavePanel()
        picker.allowedContentTypes = [.json]
        picker.nameFieldStringValue = "kururu-url-rules.json"
        present(picker) { response in
            guard requestID == id else { return }
            panel = nil
            guard response == .OK, let url = picker.url else { busy = false; return }
            let snapshot = current
            message = nil; failed = false
            DispatchQueue.global(qos: .userInitiated).async {
                let result = Result { try URLRuleImportSupport.export(current: snapshot) }
                DispatchQueue.main.async {
                    guard requestID == id else { return }
                    busy = false
                    switch result {
                    case .success(let data):
                        // The bounded write starts only after the live request check.
                        // Once writing starts it is synchronous, so cancellation cannot report a false rollback.
                        let access = url.startAccessingSecurityScopedResource()
                        defer { if access { url.stopAccessingSecurityScopedResource() } }
                        do {
                            try data.write(to: url, options: .atomic)
                            message = text("规则已导出。", "Rules exported.")
                        } catch { report(error) }
                    case .failure(let error): report(error)
                    }
                }
            }
        }
    }

    private func report(_ error: Error) {
        failed = true
        guard let error = error as? URLRuleImportSupport.Failure else {
            message = text("无法读写规则文件。请选择可访问的普通文件后重试。", "Could not read or write the rules file. Choose an accessible regular file and try again.")
            return
        }
        switch error {
        case .tooLarge: message = text("规则文件超过 256 KiB。", "The rules file exceeds 256 KiB.")
        case .tooManyRules: message = text("规则数量超过 2048 条。", "The file exceeds 2048 rules.")
        case .unsupportedFormat: message = text("仅支持 kururu 规则 JSON，不兼容 ClearURLs 规则文件。", "Only kururu rules JSON is supported. ClearURLs rule files are incompatible.")
        case .unsupportedVersion: message = text("不支持此规则文件版本。", "This rules file version is unsupported.")
        case .invalidDocument: message = text("规则文件格式无效，未导入任何规则。", "Invalid rules file. No rules were imported.")
        case .invalidRule(let row): message = text("第 \(row) 条规则无效，未导入任何规则。", "Rule \(row) is invalid. No rules were imported.")
        case .duplicateRule(let row): message = text("第 \(row) 条规则重复，未导入任何规则。", "Rule \(row) is duplicated. No rules were imported.")
        }
    }
}

/// Reads a bounded regular file without waiting on a FIFO or following a symlink.
private enum URLRuleTransferFile {
    static func read(_ url: URL) throws -> Data {
        let access = url.startAccessingSecurityScopedResource()
        defer { if access { url.stopAccessingSecurityScopedResource() } }
        let fd = open(url.path, O_RDONLY | O_NOFOLLOW | O_NONBLOCK)
        guard fd >= 0 else { throw CocoaError(.fileReadNoPermission) }
        defer { close(fd) }
        var info = stat()
        guard fstat(fd, &info) == 0, (info.st_mode & S_IFMT) == S_IFREG else {
            throw CocoaError(.fileReadUnsupportedScheme)
        }
        guard info.st_size <= URLRuleImportSupport.maximumBytes else { throw URLRuleImportSupport.Failure.tooLarge }
        var result = Data()
        var buffer = [UInt8](repeating: 0, count: 8192)
        while true {
            let count = Darwin.read(fd, &buffer, min(buffer.count, URLRuleImportSupport.maximumBytes + 1 - result.count))
            if count < 0 {
                if errno == EINTR { continue }
                throw CocoaError(.fileReadUnknown)
            }
            if count == 0 { return result }
            result.append(contentsOf: buffer.prefix(count))
            guard result.count <= URLRuleImportSupport.maximumBytes else { throw URLRuleImportSupport.Failure.tooLarge }
        }
    }
}
