// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

enum ClipboardActionStrings {
    private static func label(_ en: String, _ zh: String, _ de: String, _ fr: String, _ es: String, _ ja: String) -> String {
        switch L10n.shared.language {
        case .zhHans: return zh
        case .de: return de
        case .fr: return fr
        case .es: return es
        case .ja: return ja
        default: return en
        }
    }
    static var manage: String {
        label("Manage…", "管理…", "Verwalten…", "Gérer…", "Gestionar…", "管理…")
    }
    static var clear: String {
        label("Clear all unpinned…", "清除全部未固定记录…", "Alle nicht angehefteten löschen…",
              "Effacer tous les éléments non épinglés…", "Borrar todos los elementos sin fijar…", "未固定の履歴をすべて削除…")
    }
    static func clearMessage(_ count: Int) -> String {
        label("Delete \(count) unpinned entries from the entire history, regardless of search. Pinned entries stay. This cannot be undone.",
              "将删除全部历史中的 \(count) 条未固定记录，与当前搜索无关。固定记录保留。此操作无法撤销。",
              "\(count) nicht angeheftete Einträge aus dem gesamten Verlauf löschen, unabhängig von der Suche. Angeheftete Einträge bleiben erhalten. Dies kann nicht rückgängig gemacht werden.",
              "Supprimer \(count) éléments non épinglés de tout l’historique, quelle que soit la recherche. Les éléments épinglés sont conservés. Cette action est irréversible.",
              "Eliminar \(count) elementos sin fijar de todo el historial, independientemente de la búsqueda. Se conservan los elementos fijados. Esta acción no se puede deshacer.",
              "検索条件に関係なく、履歴全体から未固定の \(count) 件を削除します。固定済みの項目は残ります。この操作は取り消せません。")
    }
    static var confirm: String {
        label("Delete unpinned entries", "删除未固定记录", "Nicht angeheftete löschen", "Supprimer les éléments non épinglés", "Eliminar elementos sin fijar", "未固定の履歴を削除")
    }
    static var copyFailed: String {
        label("Could not read the source or write to the clipboard. Check the source file or image, then retry.",
              "无法读取源内容或写入剪贴板。请检查原文件或图片后重试。",
              "Quelle konnte nicht gelesen oder in die Zwischenablage geschrieben werden. Prüfe die Quelldatei oder das Bild und versuche es erneut.",
              "Impossible de lire la source ou d’écrire dans le presse-papiers. Vérifiez le fichier ou l’image source, puis réessayez.",
              "No se pudo leer el origen o escribir en el portapapeles. Comprueba el archivo o la imagen de origen e inténtalo de nuevo.",
              "元の内容を読み取るか、クリップボードへ書き込めませんでした。元のファイルや画像を確認して再試行してください。")
    }
    static var pasteUnavailable: String {
        label("Cannot paste automatically. Focus the destination app and check Accessibility permission, then reopen history; or use Copy and paste manually.",
              "无法自动粘贴。请先聚焦目标应用并检查辅助功能权限，再重新打开历史；也可以使用拷贝后手动粘贴。",
              "Automatisches Einfügen nicht möglich. Aktiviere die Ziel-App, prüfe die Bedienungshilfen-Berechtigung und öffne den Verlauf erneut. Alternativ kopiere den Inhalt und füge ihn manuell ein.",
              "Collage automatique impossible. Activez l’app cible, vérifiez l’autorisation Accessibilité et rouvrez l’historique. Vous pouvez aussi copier et coller manuellement.",
              "No se puede pegar automáticamente. Activa la app de destino, comprueba el permiso de Accesibilidad y vuelve a abrir el historial. También puedes copiar y pegar manualmente.",
              "自動で貼り付けられません。貼り付け先のアプリを選び、アクセシビリティ権限を確認して履歴を開き直してください。コピー後に手動で貼り付けることもできます。")
    }
    static var pasteFailed: String {
        label("Copied, but could not send Paste to the destination. Switch to that app and press ⌘V.",
              "已拷贝，但无法向目标应用发送粘贴。请切换到目标应用后按 ⌘V。",
              "Kopiert, aber Einfügen konnte nicht an die Ziel-App gesendet werden. Wechsle zu dieser App und drücke ⌘V.",
              "Copié, mais le collage n’a pas pu être envoyé à l’app cible. Activez cette app et appuyez sur ⌘V.",
              "Copiado, pero no se pudo enviar Pegar a la app de destino. Cambia a esa app y pulsa ⌘V.",
              "コピーしましたが、貼り付け先へ操作を送信できませんでした。そのアプリに切り替えて ⌘V を押してください。")
    }
    static var copyRecognized: String {
        label("Copy recognized text", "拷贝识别文字", "Erkannten Text kopieren", "Copier le texte reconnu", "Copiar texto reconocido", "認識した文字をコピー")
    }
    static func copyOriginal(_ kind: ClipboardHistoryEntryKind) -> String {
        switch kind {
        case .text: return label("Copy original text", "拷贝原文", "Originaltext kopieren", "Copier le texte original", "Copiar texto original", "元のテキストをコピー")
        case .image: return label("Copy original image", "拷贝原图", "Originalbild kopieren", "Copier l’image originale", "Copiar imagen original", "元の画像をコピー")
        case .files: return label("Copy original files", "拷贝原文件", "Originaldateien kopieren", "Copier les fichiers originaux", "Copiar archivos originales", "元のファイルをコピー")
        }
    }
}
