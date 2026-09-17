// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

struct MediaPDFStrings {
    var title = "PDF Merge"
    var merge = "Merge PDFs"
    var choose = "Choose PDF files"
    var add = "Add PDFs"
    var pagesFormat = "%d pages"
    var readingPages = "Reading page count…"
    var order = "Files and page order"
    var moveUp = "Move up"
    var moveDown = "Move down"
    var remove = "Remove file"
    var hint = "Pages are appended in the file order below. Originals stay unchanged; the result is one new PDF."
    var selectionRejected = "Choose PDF files only. The whole selection was rejected; no files were added."
    var changedTool = "The previous files do not match this tool. Choose new input files."
    var outputExists = "That output already exists. Choose an output folder to generate a new filename."
    var tooFew = "Choose at least two PDF files."
    var tooMany = "Choose no more than 100 PDF files."
    var tooLarge = "The PDF files exceed the combined 256 MiB input limit."
    var tooManyPages = "The PDF input exceeds 1,000 pages."
    var unreadable = "Cannot read PDF: "
    var invalid = "Invalid PDF: "
    var encrypted = "Encrypted PDFs cannot be processed: "
    var empty = "This PDF has no pages: "
    var writeFailed = "The PDF could not be saved. Check the output folder and available space."
    var verificationFailed = "The PDF could not be verified. No output was published."

    var compressorTitle = "PDF Compression"
    var compress = "Compress PDF"
    var chooseSingle = "Choose one PDF file"
    var singleSelectionRejected = "Choose one PDF file only. The whole selection was rejected."
    var preserveResolution = "Keep image resolution"
    var screen = "Optimize for screen"
    var compressionHint = "Text stays selectable. The original is kept; a new PDF is saved only if smaller."
    var preserveHint = "Keep image resolution with moderate lossy compression. Transparency is preserved."
    var screenHint = "Reduce images to 144 dpi for screen reading. Fine detail may be lost; transparency is preserved."
    var notSmaller = "No space to save. No copy was created."
    var originalSizeFormat = "Original size: %@"
    var unsupportedStructure = "This PDF contains a structure this tool cannot safely preserve, such as forms, signatures or attachments. No copy was created."

    static func localized(_ language: AppLanguage) -> Self {
        guard language == .zhHans else { return Self() }
        return Self(title: "PDF 合并", merge: "合并 PDF", choose: "选择 PDF 文件", add: "添加 PDF",
                    pagesFormat: "%d 页", readingPages: "正在读取页数…", order: "文件与页序", moveUp: "上移", moveDown: "下移", remove: "移除文件",
                    hint: "按下方文件顺序依次合并所有页面。保留原件，结果保存为一个新的 PDF 文件。",
                    selectionRejected: "只能选择 PDF 文件。本次选择已整批拒绝，没有添加任何文件。",
                    changedTool: "原有文件不适用于此工具，已清空选择。请重新选择输入文件。",
                    outputExists: "输出文件已存在。请选择输出文件夹，以生成新的文件名。",
                    tooFew: "请至少选择两份 PDF。", tooMany: "最多选择 100 份 PDF。",
                    tooLarge: "PDF 输入文件合计超过 256 MiB 限制。", tooManyPages: "PDF 输入超过 1,000 页。",
                    unreadable: "无法读取 PDF：", invalid: "PDF 文件无效：", encrypted: "无法处理加密 PDF：",
                    empty: "PDF 没有页面：", writeFailed: "无法保存 PDF，请检查输出文件夹及可用空间。",
                    verificationFailed: "无法验证 PDF，未生成输出文件。",
                    compressorTitle: "PDF 压缩", compress: "压缩 PDF", chooseSingle: "选择一份 PDF 文件",
                    singleSelectionRejected: "只能选择一份 PDF 文件，本次选择已整批拒绝。",
                    preserveResolution: "保持图片分辨率", screen: "适合屏幕",
                    compressionHint: "文字保持可选择，保留原件。仅在体积更小时保存副本。",
                    preserveHint: "保持图片分辨率，适度降低图片质量，保留透明效果。",
                    screenHint: "图片降至 144 dpi，适合屏幕阅读。可能损失细节，保留透明效果。",
                    notSmaller: "没有可节省的空间，未生成副本。", originalSizeFormat: "原始大小：%@",
                    unsupportedStructure: "此 PDF 含有工具无法安全保留的结构，例如表单、签名或附件，未生成副本。")
    }
}
