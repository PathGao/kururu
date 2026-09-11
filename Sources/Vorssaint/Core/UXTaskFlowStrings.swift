// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

struct UXTaskFlowStrings {
    let language: AppLanguage

    private func text(_ en: String, _ zh: String, _ de: String, _ fr: String, _ es: String, _ ja: String) -> String {
        switch language {
        case .zhHans: return zh
        case .de: return de
        case .fr: return fr
        case .es: return es
        case .ja: return ja
        default: return en
        }
    }

    var viewClipboard: String { text("View Clipboard", "查看剪贴板", "Zwischenablage anzeigen", "Afficher le presse-papiers", "Ver portapapeles", "クリップボードを表示") }
    var useClipboard: String { text("Use Clipboard", "使用入口", "Zwischenablage verwenden", "Utiliser le presse-papiers", "Usar portapapeles", "クリップボードを使う") }
    var automaticCapture: String { text("Automatic Capture", "自动记录", "Automatische Erfassung", "Capture automatique", "Captura automática", "自動記録") }
    var recordCopiedContent: String { text("Automatically record copied content", "自动记录复制的内容", "Kopierte Inhalte automatisch aufzeichnen", "Enregistrer automatiquement le contenu copié", "Registrar automáticamente el contenido copiado", "コピーした内容を自動的に記録") }
    var automaticCaptureCaption: String { text("Record new copies in local history. Turning this off keeps existing history and the viewer available.", "将新复制内容记录到本地历史。关闭后保留已有历史，仍可查看。", "Speichert neue Kopien im lokalen Verlauf. Beim Ausschalten bleiben Verlauf und Anzeige verfügbar.", "Enregistre les nouvelles copies dans l’historique local. La désactivation conserve l’historique et son affichage.", "Guarda las nuevas copias en el historial local. Al desactivarlo se conservan el historial y el visor.", "新しいコピーをローカル履歴に記録します。オフにしても履歴と表示機能は残ります。") }
    var dataManagement: String { text("History Management", "历史管理", "Verlauf verwalten", "Gestion de l’historique", "Gestión del historial", "履歴管理") }
    var relatedTools: String { text("Related Tools", "相关工具", "Zugehörige Werkzeuge", "Outils associés", "Herramientas relacionadas", "関連ツール") }
    var openURLCleaner: String { text("Open URL Cleaner…", "打开 URL 清理…", "URL-Bereinigung öffnen…", "Ouvrir le nettoyage d’URL…", "Abrir limpiador de URL…", "URL クリーナーを開く…") }
    var automaticURLCleaning: String { text("Automatic Cleaning", "自动行为", "Automatische Bereinigung", "Nettoyage automatique", "Limpieza automática", "自動クリーニング") }
    var automaticURLCaption: String { text("Clean copied links automatically. Manual cleaning stays available, and both use the rules below.", "复制链接时自动清理。关闭后仍可手动清理，两种方式共用下方规则。", "Bereinigt kopierte Links automatisch. Die manuelle Bereinigung bleibt verfügbar; beide verwenden die Regeln unten.", "Nettoie automatiquement les liens copiés. Le nettoyage manuel reste disponible et les deux utilisent les règles ci-dessous.", "Limpia automáticamente los enlaces copiados. La limpieza manual sigue disponible y ambas usan las reglas siguientes.", "コピーしたリンクを自動でクリーニングします。手動操作は常に利用でき、どちらも下のルールを使います。") }
    var resultExpired: String { text("The result is out of date. Clean the current link again.", "输入或规则已改变，请重新清理当前链接。", "Das Ergebnis ist veraltet. Bereinige den aktuellen Link erneut.", "Le résultat n’est plus à jour. Nettoyez à nouveau le lien actuel.", "El resultado está desactualizado. Limpia de nuevo el enlace actual.", "入力またはルールが変わりました。現在のリンクをもう一度クリーニングしてください。") }
    var captureActive: String { text("Recording copied text, images, and files", "正在记录复制的文字、图片和文件", "Kopierter Text, Bilder und Dateien werden aufgezeichnet", "Enregistrement du texte, des images et des fichiers copiés", "Registrando texto, imágenes y archivos copiados", "コピーしたテキスト、画像、ファイルを記録中") }
    var capturePaused: String { text("Recording is paused. Existing history is retained and can still be viewed.", "记录已暂停。已有历史会保留，仍可查看。", "Die Aufzeichnung ist pausiert. Der vorhandene Verlauf bleibt erhalten und kann weiter angezeigt werden.", "L’enregistrement est en pause. L’historique existant est conservé et reste consultable.", "El registro está en pausa. El historial existente se conserva y se puede seguir consultando.", "記録は一時停止中です。既存の履歴は保持され、引き続き表示できます。") }
    var emptyCapturePaused: String { text("Clipboard recording is paused. Turn it on to record new copies.", "剪贴板记录已暂停。开启后会记录新的复制内容。", "Die Zwischenablage-Aufzeichnung ist pausiert. Aktiviere sie, um neue Kopien zu speichern.", "L’enregistrement du presse-papiers est en pause. Activez-le pour enregistrer les nouvelles copies.", "El registro del portapapeles está en pausa. Actívalo para guardar nuevas copias.", "クリップボードの記録は一時停止中です。オンにすると新しいコピーを記録します。") }
    var emptyWaitingForCopy: String { text("No history yet. Copy text, an image, or files to add the first item.", "还没有历史。复制文字、图片或文件后，第一条记录会显示在这里。", "Noch kein Verlauf. Kopiere Text, ein Bild oder Dateien, um den ersten Eintrag hinzuzufügen.", "Aucun historique. Copiez du texte, une image ou des fichiers pour ajouter le premier élément.", "Aún no hay historial. Copia texto, una imagen o archivos para añadir el primer elemento.", "履歴はまだありません。テキスト、画像、ファイルをコピーすると最初の項目が追加されます。") }
    var emptyNoMatches: String { text("No history matches this search.", "没有与此搜索匹配的历史记录。", "Kein Verlauf entspricht dieser Suche.", "Aucun élément de l’historique ne correspond à cette recherche.", "Ningún elemento del historial coincide con esta búsqueda.", "この検索に一致する履歴はありません。") }
    var enableCapture: String { text("Turn On Recording", "开启记录", "Aufzeichnung einschalten", "Activer l’enregistrement", "Activar registro", "記録をオンにする") }
    var clearSearch: String { text("Clear Search", "清除搜索", "Suche löschen", "Effacer la recherche", "Borrar búsqueda", "検索をクリア") }
}

enum ClipboardViewerEmptyState: Equatable {
    case capturePaused, waitingForCopy, noMatches

    static func resolve(query: String, captureEnabled: Bool) -> Self {
        if !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return .noMatches }
        return captureEnabled ? .waitingForCopy : .capturePaused
    }
}
