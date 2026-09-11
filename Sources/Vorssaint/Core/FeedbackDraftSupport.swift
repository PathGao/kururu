// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation
import CoreGraphics

enum FeedbackDraftSupport {
    static func initialWindowOrigin(size: CGSize, sourceVisibleFrame: CGRect?, fallback: CGRect) -> CGPoint {
        let visible = sourceVisibleFrame ?? fallback
        return CGPoint(x: visible.minX + max(0, (visible.width - size.width) / 2),
                       y: visible.maxY - size.height - max(0, (visible.height - size.height) / 2))
    }

    static var issuesURL: URL { ProductIdentity.repositoryURL.appendingPathComponent("issues") }

    static func text(category: String, message: String, diagnostics: [String: String], includeDiagnostics: Bool) -> String {
        var text = "Category: " + category + "\n\n" + message
        if includeDiagnostics {
            text += "\n\nTechnical details\n" + diagnostics.keys.sorted().map { $0 + ": " + diagnostics[$0]! }.joined(separator: "\n")
        }
        return text
    }
}

struct LocalFeedbackCopy {
    let title: String
    let explanation: String
    let preview: String
    let copy: String
    let copied: String
    let copyFailed: String
    let issues: String

    static func strings(language: String) -> LocalFeedbackCopy {
        if language == "zh-Hans" || language == "zhHans" {
            return .init(title: "反馈草稿", explanation: "草稿仅保留在当前窗口。复制后可自行粘贴到项目问题页；打开页面不会携带草稿或技术信息。", preview: "将复制的内容", copy: "复制反馈", copied: "反馈已复制，尚未发送。", copyFailed: "无法复制反馈，请重试。", issues: "打开项目问题页")
        }
        if ["zh-TW", "zh-HK", "zhTW", "zhHK", "zh-Hant"].contains(language) {
            return .init(title: "回饋草稿", explanation: "草稿僅保留在目前視窗。複製後可自行貼到專案問題頁；開啟頁面不會攜帶草稿或技術資訊。", preview: "將複製的內容", copy: "複製回饋", copied: "回饋已複製，尚未傳送。", copyFailed: "無法複製回饋，請重試。", issues: "開啟專案問題頁")
        }
        return .init(title: "Feedback draft", explanation: "The draft stays in this window. Copy it to paste into a project issue yourself. Opening the issue page does not include your draft or technical details.", preview: "What will be copied", copy: "Copy feedback", copied: "Feedback copied. Nothing has been sent.", copyFailed: "Could not copy feedback. Please try again.", issues: "Open project issues")
    }
}
