// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

struct ThemeSettingsText {
    let language: AppLanguage

    private func localized(_ en: String, _ zh: String, _ de: String, _ fr: String, _ es: String, _ ja: String) -> String {
        switch language {
        case .zhHans: return zh
        case .de: return de
        case .fr: return fr
        case .es: return es
        case .ja: return ja
        default: return en
        }
    }
    var title: String { localized("Interface colors",
            "界面配色",
            "Oberflächenfarben",
            "Couleurs de l’interface",
            "Colores de la interfaz",
            "インターフェイスの配色") }
    var defaultName: String { localized("kururu default greyscale",
            "kururu 默认灰阶",
            "kururu-Standardgraustufen",
            "Niveaux de gris par défaut de kururu",
            "Escala de grises predeterminada de kururu",
            "kururu 標準のグレースケール") }
    var imported: String { localized("Imported colors",
            "导入的配色",
            "Importierte Farben",
            "Couleurs importées",
            "Colores importados",
            "読み込んだ配色") }
    var scope: String { localized("Choose colors on the theme website, then paste the theme page link to preview. Only interface colors are used; no extension is installed.",
            "从主题网站挑选配色，粘贴主题页面链接预览。只使用界面配色，不安装主题扩展。",
            "Wähle Farben auf der Theme-Website aus und füge den Link zur Theme-Seite für eine Vorschau ein. Es werden nur Oberflächenfarben verwendet; keine Erweiterung wird installiert.",
            "Choisissez des couleurs sur le site de thèmes, puis collez le lien de la page du thème pour les prévisualiser. Seules les couleurs de l’interface sont utilisées ; aucune extension n’est installée.",
            "Elige colores en el sitio de temas y pega el enlace de la página del tema para previsualizarlos. Solo se usan los colores de la interfaz; no se instala ninguna extensión.",
            "テーマサイトで配色を選び、テーマページのリンクを貼り付けてプレビューします。インターフェイスの配色だけを使用し、拡張機能はインストールしません。") }
    var browseButton: String { localized("Browse themes",
            "浏览主题网站",
            "Themes durchsuchen",
            "Parcourir les thèmes",
            "Explorar temas",
            "テーマを見る") }
    var linkPlaceholder: String { "https://vscodethemes.com/e/…" }
    var linkLabel: String { localized("Theme page link",
            "主题页面链接",
            "Link zur Theme-Seite",
            "Lien de la page du thème",
            "Enlace de la página del tema",
            "テーマページのリンク") }
    var cancelLoading: String { localized("Cancel loading",
            "取消读取",
            "Laden abbrechen",
            "Annuler le chargement",
            "Cancelar carga",
            "読み込みをキャンセル") }
    var reading: String { localized("Loading colors…",
            "正在读取配色…",
            "Farben werden geladen…",
            "Chargement des couleurs…",
            "Cargando colores…",
            "配色を読み込み中…") }
    var importButton: String { localized("Import from file…",
            "从文件导入…",
            "Aus Datei importieren…",
            "Importer un fichier…",
            "Importar desde archivo…",
            "ファイルから読み込む…") }
    var restoreButton: String { localized("Restore default",
            "恢复默认",
            "Standard wiederherstellen",
            "Rétablir les valeurs par défaut",
            "Restaurar valores predeterminados",
            "標準に戻す") }
    var previewTitle: String { localized("Preview",
            "预览",
            "Vorschau",
            "Aperçu",
            "Vista previa",
            "プレビュー") }
    var previewCaption: String { localized("Preview leaves your current colors unchanged. Missing colors use defaults; check that text remains legible. Warning colors stay unchanged.",
            "预览不更改当前配色。缺少的颜色沿用默认值；请检查文字与背景是否清楚。警告状态颜色保持不变。",
            "Die Vorschau ändert die aktuellen Farben nicht. Fehlende Farben verwenden Standardwerte; prüfe die Lesbarkeit des Textes. Warnfarben bleiben unverändert.",
            "L’aperçu ne modifie pas vos couleurs actuelles. Les couleurs manquantes utilisent les valeurs par défaut ; vérifiez la lisibilité du texte. Les couleurs d’avertissement restent inchangées.",
            "La vista previa no cambia los colores actuales. Los colores que falten usan los valores predeterminados; comprueba que el texto sea legible. Los colores de advertencia no cambian.",
            "プレビューでは現在の配色を変更しません。未指定の色には標準値を使用します。文字が読みやすいか確認してください。警告色は変更しません。") }
    var cancelButton: String { localized("Cancel preview",
            "取消预览",
            "Vorschau abbrechen",
            "Annuler l’aperçu",
            "Cancelar vista previa",
            "プレビューをキャンセル") }
    var applyButton: String { localized("Apply colors",
            "应用配色",
            "Farben anwenden",
            "Appliquer les couleurs",
            "Aplicar colores",
            "配色を適用") }
    var settingsSample: String { localized("Settings sample",
            "设置示例",
            "Einstellungsbeispiel",
            "Exemple de réglages",
            "Ejemplo de ajustes",
            "設定の表示例") }
    var secondarySample: String { localized("Secondary description",
            "次要说明文字",
            "Ergänzende Beschreibung",
            "Description secondaire",
            "Descripción secundaria",
            "補足説明") }
    var normalSample: String { localized("Monitor sample · Normal",
            "监控示例 · 正常",
            "Monitorbeispiel · Normal",
            "Exemple de suivi · Normal",
            "Ejemplo de monitorización · Normal",
            "モニターの表示例 · 正常") }
    func message(for error: Error) -> String {
        if let error = error as? ThemeImportError { return message(for: error) }
        guard let error = error as? ThemeLinkImportError else {
            return localized("Could not load colors. Try again later. Your current colors were kept.",
            "无法读取配色，请稍后重试。当前配色已保留。",
            "Farben konnten nicht geladen werden. Versuche es später erneut. Deine aktuellen Farben wurden beibehalten.",
            "Impossible de charger les couleurs. Réessayez plus tard. Vos couleurs actuelles ont été conservées.",
            "No se pudieron cargar los colores. Inténtalo de nuevo más tarde. Se conservaron los colores actuales.",
            "配色を読み込めませんでした。しばらくしてから再試行してください。現在の配色は保持されています。")
        }
        switch error {
        case .invalidLink: return localized("Paste the full page link for a theme on VS Code Themes.",
            "请粘贴 VS Code Themes 中某个主题的完整页面链接。",
            "Füge den vollständigen Seitenlink eines Themes von VS Code Themes ein.",
            "Collez le lien complet de la page d’un thème sur VS Code Themes.",
            "Pega el enlace completo de la página de un tema en VS Code Themes.",
            "VS Code Themes のテーマページの完全なリンクを貼り付けてください。")
        case .downloadFailed: return localized("The download did not finish. Check your connection and try again.",
            "下载未完成，请检查网络后重试。",
            "Der Download wurde nicht abgeschlossen. Prüfe deine Verbindung und versuche es erneut.",
            "Le téléchargement n’a pas abouti. Vérifiez votre connexion et réessayez.",
            "La descarga no se completó. Comprueba la conexión e inténtalo de nuevo.",
            "ダウンロードが完了しませんでした。接続を確認して再試行してください。")
        case .tooLarge: return localized("This theme is too large. Choose another theme.",
            "主题文件过大，请选择另一个主题。",
            "Dieses Theme ist zu groß. Wähle ein anderes Theme.",
            "Ce thème est trop volumineux. Choisissez-en un autre.",
            "Este tema es demasiado grande. Elige otro.",
            "このテーマは大きすぎます。別のテーマを選んでください。")
        case .invalidArchive: return localized("This theme package could not be read. Choose another theme.",
            "无法读取这个主题包，请选择另一个主题。",
            "Dieses Theme-Paket konnte nicht gelesen werden. Wähle ein anderes Theme.",
            "Impossible de lire ce paquet de thème. Choisissez un autre thème.",
            "No se pudo leer este paquete de tema. Elige otro.",
            "このテーマパッケージを読み取れませんでした。別のテーマを選んでください。")
        case .themeNotFound: return localized("The linked colors were not found in the package. Choose the theme page again.",
            "主题包中找不到链接指定的配色，请重新选择主题页面。",
            "Die verlinkten Farben wurden im Paket nicht gefunden. Wähle die Theme-Seite erneut aus.",
            "Les couleurs indiquées par le lien sont introuvables dans le paquet. Sélectionnez à nouveau la page du thème.",
            "No se encontraron los colores del enlace en el paquete. Vuelve a elegir la página del tema.",
            "リンクで指定された配色がパッケージ内に見つかりませんでした。テーマページを選び直してください。")
        case .ambiguousTheme: return localized("This link matches more than one theme. Choose a specific theme page.",
            "这个链接对应多个配色，无法确定要使用哪一个。请选择具体主题页面。",
            "Dieser Link passt zu mehreren Themes. Wähle eine bestimmte Theme-Seite.",
            "Ce lien correspond à plusieurs thèmes. Choisissez la page d’un thème précis.",
            "Este enlace corresponde a varios temas. Elige la página de un tema específico.",
            "このリンクには複数のテーマが該当します。特定のテーマページを選んでください。")
        case .invalidTheme: return localized("This theme has no readable interface colors. Choose another theme.",
            "这个主题没有可读取的界面配色，请选择另一个主题。",
            "Dieses Theme enthält keine lesbaren Oberflächenfarben. Wähle ein anderes Theme.",
            "Ce thème ne contient aucune couleur d’interface lisible. Choisissez-en un autre.",
            "Este tema no contiene colores de interfaz que se puedan leer. Elige otro.",
            "このテーマには読み取り可能なインターフェイスの配色がありません。別のテーマを選んでください。")
        }
    }
    func message(for error: ThemeImportError) -> String {
        switch error {
        case .tooLarge: return localized("The file exceeds 256 KiB. Choose a smaller theme file.",
            "文件超过 256 KiB，请选择较小的主题文件。",
            "Die Datei ist größer als 256 KiB. Wähle eine kleinere Theme-Datei.",
            "Le fichier dépasse 256 KiB. Choisissez un fichier de thème plus petit.",
            "El archivo supera los 256 KiB. Elige un archivo de tema más pequeño.",
            "ファイルが 256 KiB を超えています。より小さいテーマファイルを選んでください。")
        case .invalidJSON: return localized("The file is not valid UTF-8 JSON / JSONC.",
            "文件不是有效的 UTF-8 JSON / JSONC。",
            "Die Datei ist kein gültiges UTF-8-JSON / JSONC.",
            "Le fichier n’est pas un document JSON / JSONC UTF-8 valide.",
            "El archivo no es JSON / JSONC válido en UTF-8.",
            "ファイルは有効な UTF-8 JSON / JSONC ではありません。")
        case .invalidColors: return localized("The theme needs a colors object.",
            "主题缺少 colors 颜色对象。",
            "Das Theme benötigt ein colors-Objekt.",
            "Le thème doit contenir un objet colors.",
            "El tema necesita un objeto colors.",
            "テーマには colors オブジェクトが必要です。")
        case .noColors: return localized("The file has no supported interface colors.",
            "文件没有可用于界面的颜色。",
            "Die Datei enthält keine unterstützten Oberflächenfarben.",
            "Le fichier ne contient aucune couleur d’interface prise en charge.",
            "El archivo no contiene colores de interfaz compatibles.",
            "ファイルには対応しているインターフェイスの配色がありません。")
        case .invalidColor(let key): return localized("Invalid color for \(key). Use a hexadecimal color.",
            "颜色字段 \(key) 格式无效，请使用十六进制颜色。",
            "Ungültige Farbe für \(key). Verwende eine hexadezimale Farbe.",
            "Couleur invalide pour \(key). Utilisez une couleur hexadécimale.",
            "Color no válido para \(key). Usa un color hexadecimal.",
            "\(key) の色が無効です。16進数の色を使用してください。")
        case .unreadable: return localized("The theme could not be read or applied. Your current colors were kept.",
            "无法读取或应用主题文件，当前配色已保留。",
            "Das Theme konnte nicht gelesen oder angewendet werden. Deine aktuellen Farben wurden beibehalten.",
            "Le thème n’a pas pu être lu ou appliqué. Vos couleurs actuelles ont été conservées.",
            "No se pudo leer o aplicar el tema. Se conservaron los colores actuales.",
            "テーマを読み取るか適用することができませんでした。現在の配色は保持されています。")
        }
    }
}
