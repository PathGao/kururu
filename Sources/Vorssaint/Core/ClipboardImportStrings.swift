// SPDX-License-Identifier: GPL-3.0-or-later

struct ClipboardImportStrings {
    var title = "Import clipboard history"
    var button = "Import history…"
    var caption = "Choose ClipboardHistory.json or an older preferences plist. JSON uses the adjacent ClipboardImages folder; a plist imports only clipboard history and may need a separately selected image folder. New copies keep current records and sources unchanged. File entries still reference their original locations."
    var chooseImages = "Choose ClipboardImages folder"
    var imagesCaption = "An older preferences file does not contain image files. Choose its original ClipboardImages folder to copy the images; the originals stay in place."
    var chooseFile = "Choose clipboard history"
    var previewTitle = "Choose records to import"
    var sourceLabel = "Source"
    var importSelected = "Import selected"
    var cancel = "Cancel"
    var selectAll = "Select all"
    var busy = "Preparing history…"
    var successFormat = "Imported %d records."
    var emptySelection = "Select at least one record."
    var readFailed = "Could not read the history. Check that the source files are available and try again."
    var invalidDocument = "Choose ClipboardHistory.json or an older preferences plist containing clipboard history."
    var tooLarge = "The history or its images exceed the supported size."
    var missingImage = "An image is missing or invalid. Use the complete original ClipboardImages folder for this history."
    var capacityExceeded = "There is not enough room for the selected records. Select fewer records or adjust the history limit."
    var currentFile = "This is the current history file. Choose a different source file."
    var saveFailed = "Could not save the imported history. Current records and source files were kept."
    var changed = "History changed while the import was being prepared. Try again."
    var unavailable = "Clipboard history is unavailable right now. Try opening your current history first."
    var imageLabel = "Image"
    var filesFormat = "%d files"

    static func text(_ language: AppLanguage) -> Self {
        switch language {
        case .zhHans:
            return Self(title: "导入剪贴板历史", button: "导入历史…",
                        caption: "选择 ClipboardHistory.json 或旧偏好 plist。JSON 使用相邻的 ClipboardImages；plist 只读取剪贴板历史，有图片时需另选图片文件夹。追加新副本，当前记录和源文件不变；文件条目仍引用原位置。",
                        chooseImages: "选择 ClipboardImages 文件夹", imagesCaption: "旧偏好文件不包含图片文件，请选择原 ClipboardImages 文件夹以复制图片，原件仍留在原位置。", chooseFile: "选择剪贴板历史文件", previewTitle: "选择要导入的记录", sourceLabel: "来源", importSelected: "导入所选记录", cancel: "取消", selectAll: "全选", busy: "正在准备历史记录…", successFormat: "已导入 %d 条记录。", emptySelection: "请至少选择一条记录。",
                        readFailed: "无法读取历史记录，请检查源文件是否可用后重试。", invalidDocument: "请选择 ClipboardHistory.json 或包含剪贴板历史的旧偏好 plist。", tooLarge: "历史记录或图片超出支持的大小。",
                        missingImage: "图片缺失或无效，请使用这份历史对应的完整原 ClipboardImages 文件夹。", capacityExceeded: "所选记录超出剩余容量，请减少选择或调整历史记录上限。", currentFile: "这是当前正在使用的历史文件，请选择其他来源文件。", saveFailed: "无法保存导入的历史，当前记录和源文件已保留。", changed: "准备导入期间历史记录发生了变化，请重试。", unavailable: "剪贴板历史暂不可用，请先尝试打开当前历史。", imageLabel: "图片", filesFormat: "%d 个文件")
        case .de:
            return Self(title: "Zwischenablageverlauf importieren", button: "Verlauf importieren…",
                        caption: "Wähle ClipboardHistory.json oder eine ältere Einstellungs-plist. JSON nutzt den benachbarten Ordner ClipboardImages; aus einer plist wird nur der Zwischenablageverlauf gelesen, gegebenenfalls mit separat gewähltem Bildordner. Kopien lassen aktuelle Einträge und Quellen unverändert. Dateieinträge behalten ihren ursprünglichen Pfad.",
                        chooseImages: "Ordner ClipboardImages wählen", imagesCaption: "Eine ältere Einstellungsdatei enthält keine Bilddateien. Wähle den ursprünglichen Ordner ClipboardImages, um die Bilder zu kopieren. Die Originale bleiben an ihrem Ort.", chooseFile: "Zwischenablageverlauf wählen", previewTitle: "Einträge zum Import auswählen", sourceLabel: "Quelle", importSelected: "Auswahl importieren", cancel: "Abbrechen", selectAll: "Alle auswählen", busy: "Verlauf wird vorbereitet…", successFormat: "%d Einträge importiert.", emptySelection: "Wähle mindestens einen Eintrag aus.",
                        readFailed: "Der Verlauf konnte nicht gelesen werden. Prüfe die Verfügbarkeit der Quelldateien und versuche es erneut.", invalidDocument: "Wähle ClipboardHistory.json oder eine ältere Einstellungs-plist mit Zwischenablageverlauf.", tooLarge: "Der Verlauf oder seine Bilder überschreiten die unterstützte Größe.",
                        missingImage: "Ein Bild fehlt oder ist ungültig. Verwende den vollständigen ursprünglichen Ordner ClipboardImages für diesen Verlauf.", capacityExceeded: "Für die Auswahl ist nicht genug Platz. Wähle weniger Einträge oder passe das Verlaufslimit an.", currentFile: "Dies ist die aktuelle Verlaufsdatei. Wähle eine andere Quelldatei.", saveFailed: "Der importierte Verlauf konnte nicht gespeichert werden. Aktuelle Einträge und Quelldateien wurden beibehalten.", changed: "Der Verlauf wurde während der Vorbereitung geändert. Versuche es erneut.", unavailable: "Der Zwischenablageverlauf ist derzeit nicht verfügbar. Versuche zuerst, den aktuellen Verlauf zu öffnen.", imageLabel: "Bild", filesFormat: "%d Dateien")
        case .fr:
            return Self(title: "Importer l’historique du presse-papiers", button: "Importer l’historique…",
                        caption: "Choisissez ClipboardHistory.json ou une ancienne plist de préférences. Le JSON utilise ClipboardImages à côté ; seul l’historique est lu dans une plist, avec un dossier d’images à choisir si nécessaire. Les copies préservent les entrées et sources actuelles. Les fichiers restent référencés à leur emplacement d’origine.",
                        chooseImages: "Choisir le dossier ClipboardImages", imagesCaption: "Une ancienne plist de préférences ne contient pas les fichiers images. Choisissez son dossier ClipboardImages d’origine pour copier les images ; les originaux restent en place.", chooseFile: "Choisir un historique", previewTitle: "Choisir les entrées à importer", sourceLabel: "Source", importSelected: "Importer la sélection", cancel: "Annuler", selectAll: "Tout sélectionner", busy: "Préparation de l’historique…", successFormat: "%d entrées importées.", emptySelection: "Sélectionnez au moins une entrée.",
                        readFailed: "Impossible de lire l’historique. Vérifiez que les fichiers sources sont disponibles et réessayez.", invalidDocument: "Choisissez ClipboardHistory.json ou une ancienne plist de préférences contenant l’historique du presse-papiers.", tooLarge: "L’historique ou ses images dépassent la taille prise en charge.",
                        missingImage: "Une image est absente ou invalide. Utilisez le dossier ClipboardImages d’origine complet correspondant à cet historique.", capacityExceeded: "Il n’y a pas assez de place. Sélectionnez moins d’entrées ou ajustez la limite de l’historique.", currentFile: "Il s’agit du fichier d’historique actuel. Choisissez un autre fichier source.", saveFailed: "Impossible d’enregistrer l’historique importé. Les entrées actuelles et les fichiers sources ont été conservés.", changed: "L’historique a changé pendant la préparation. Réessayez.", unavailable: "L’historique est indisponible pour le moment. Essayez d’abord d’ouvrir l’historique actuel.", imageLabel: "Image", filesFormat: "%d fichiers")
        case .es:
            return Self(title: "Importar historial del portapapeles", button: "Importar historial…",
                        caption: "Elige ClipboardHistory.json o un plist de preferencias antiguo. JSON usa la carpeta ClipboardImages adyacente; del plist solo se lee el historial y, si hay imágenes, debes elegir su carpeta. Las copias conservan los registros y originales. Las entradas de archivos mantienen su ubicación original.",
                        chooseImages: "Elegir carpeta ClipboardImages", imagesCaption: "El archivo de preferencias antiguo no contiene las imágenes. Elige su carpeta ClipboardImages original para copiarlas; los originales permanecen en su ubicación.", chooseFile: "Elegir historial", previewTitle: "Elegir registros para importar", sourceLabel: "Origen", importSelected: "Importar selección", cancel: "Cancelar", selectAll: "Seleccionar todo", busy: "Preparando historial…", successFormat: "Se importaron %d registros.", emptySelection: "Selecciona al menos un registro.",
                        readFailed: "No se pudo leer el historial. Comprueba que los archivos originales estén disponibles e inténtalo de nuevo.", invalidDocument: "Elige ClipboardHistory.json o un plist de preferencias antiguo que contenga el historial del portapapeles.", tooLarge: "El historial o sus imágenes superan el tamaño admitido.",
                        missingImage: "Falta una imagen o no es válida. Usa la carpeta ClipboardImages original completa correspondiente a este historial.", capacityExceeded: "No hay espacio para la selección. Elige menos registros o ajusta el límite del historial.", currentFile: "Este es el archivo de historial actual. Elige otro archivo de origen.", saveFailed: "No se pudo guardar el historial importado. Se conservaron los registros actuales y los archivos originales.", changed: "El historial cambió durante la preparación. Inténtalo de nuevo.", unavailable: "El historial no está disponible ahora. Intenta abrir primero el historial actual.", imageLabel: "Imagen", filesFormat: "%d archivos")
        case .ja:
            return Self(title: "クリップボード履歴を読み込む", button: "履歴を読み込む…",
                        caption: "ClipboardHistory.json または旧設定の plist を選びます。JSON は隣の ClipboardImages を使用し、plist は履歴だけを読み取ります。画像がある場合は別途フォルダを選びます。コピーを追加し、現在の履歴と元データは保持します。ファイル項目は元の場所を参照します。",
                        chooseImages: "ClipboardImages フォルダを選択", imagesCaption: "旧設定ファイルには画像ファイルが含まれません。元の ClipboardImages フォルダを選んで画像をコピーします。元ファイルは移動しません。", chooseFile: "履歴ファイルを選択", previewTitle: "読み込む履歴を選択", sourceLabel: "読み込み元", importSelected: "選択した履歴を読み込む", cancel: "キャンセル", selectAll: "すべて選択", busy: "履歴を準備中…", successFormat: "%d 件の履歴を読み込みました。", emptySelection: "履歴を 1 件以上選択してください。",
                        readFailed: "履歴を読み取れません。元ファイルが利用可能か確認して、もう一度お試しください。", invalidDocument: "ClipboardHistory.json またはクリップボード履歴を含む旧設定の plist を選んでください。", tooLarge: "履歴または画像が対応するサイズを超えています。",
                        missingImage: "画像が見つからないか無効です。この履歴に対応する元の完全な ClipboardImages フォルダを使用してください。", capacityExceeded: "選択した履歴を追加する空きがありません。選択を減らすか、履歴の上限を調整してください。", currentFile: "これは現在使用中の履歴ファイルです。別の読み込み元ファイルを選んでください。", saveFailed: "読み込んだ履歴を保存できませんでした。現在の履歴と元ファイルは保持されています。", changed: "準備中に履歴が変更されました。もう一度お試しください。", unavailable: "現在、履歴を利用できません。先に現在の履歴を開いてみてください。", imageLabel: "画像", filesFormat: "%d 個のファイル")
        default:
            return Self()
        }
    }
}
