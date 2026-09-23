// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import Foundation

/// English is the default for every field; a language that has no wording
/// for one falls back to it, so a partial translation stays usable.
struct RecorderExportStrings {
    var speed: String = "Export speed"
    var custom: String = "Custom speed"
    var duration: String = "Export duration"
    var previewNote: String = "Applies to video and GIF. The editing preview stays at 1×; the original recording is unchanged."
}

extension FeatureStrings {
    static func recorderExport(_ language: AppLanguage) -> RecorderExportStrings {
        language == .zhHans ? .zhHans : RecorderExportStrings()
    }
}

extension RecorderExportStrings {
    static let zhHans = RecorderExportStrings(
        speed: "导出速度", custom: "自定义速度", duration: "导出时长",
        previewNote: "适用于视频和 GIF。编辑预览保持 1×，原始录制不会改变。")
}
