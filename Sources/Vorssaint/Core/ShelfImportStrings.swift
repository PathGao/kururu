// SPDX-License-Identifier: GPL-3.0-or-later
struct ShelfImportStrings {
    var title = "Import shelf items"
    var button = "Import items…"
    var caption = "Choose ShelfItems.json or an older preferences plist. Append copies of selected records while keeping existing records and sources."
    var preview = "Choose items to import"
    var cancel = "Cancel"
    var busy = "Preparing import…"
    var selectAll = "Select all"
    var selectNone = "Deselect all"
    var importSelected = "Import selected"
    var filesWarning = "Old indexes do not identify which files belong to the old app. Choose a location and an import mode for each directory, including its subdirectories. Copy attachments stored by the old app so removing it will not break these items."
    var original = "Directory in index"
    var location = "Read from"
    var mode = "Import mode"
    var chooseMode = "Choose a mode…"
    var reference = "Reference originals"
    var copy = "Copy attachments"
    var notSelected = "Not selected"
    var useOriginal = "Use original location"
    var chooseDirectory = "Choose matching folder…"
    var referenceCaption = "Uses files at the selected location. Moving or deleting them may make the items unavailable."
    var copyCaption = "Copies files into this shelf and leaves the originals in place. Folder items can only be referenced."
    var filesFormat = "%d file references, including subdirectories"
    var successFormat = "Imported %d items."
    var failure = "Import could not finish. Check the source and folder choices, or select fewer items, then try again."
    var group = "Group"
    var groupDetails = "Show all contents · the whole group is selected together"
    var selectionFormat = "%d top-level entries selected · %d items inside"

    static func errorMessage(_ language: AppLanguage, _ error: Error) -> (message: String, path: String?) {
        func localized(_ en: String, _ zh: String, _ de: String, _ fr: String, _ es: String, _ ja: String) -> String {
            switch language {
            case .zhHans: return zh
            case .de: return de
            case .fr: return fr
            case .es: return es
            case .ja: return ja
            default: return en
            }
        }
        switch error {
        case ShelfImportError.invalidDocument, ShelfImportTransactionError.invalidDocument:
            return (localized("Choose a valid ShelfItems.json or preferences plist containing shelf items.", "请选择有效的 ShelfItems.json 或包含暂存架项目的偏好 plist。", "Wähle eine gültige ShelfItems.json oder eine Einstellungs-plist mit Ablageeinträgen.", "Choisissez un ShelfItems.json valide ou une plist contenant les éléments de l’étagère.", "Elige un ShelfItems.json válido o un plist con elementos de la bandeja.", "有効な ShelfItems.json またはシェルフ項目を含む設定 plist を選んでください。"), nil)
        case ShelfImportError.tooLarge, ShelfImportAssetError.tooLarge, ShelfImportTransactionError.tooLarge:
            return (localized("The source or attachments exceed the supported size. Select fewer items or a smaller source.", "来源或附件超出支持的大小，请减少所选项目或使用更小的来源文件。", "Quelle oder Anhänge sind zu groß. Wähle weniger Einträge oder eine kleinere Quelle.", "La source ou les pièces jointes sont trop volumineuses. Réduisez la sélection ou la source.", "El origen o los adjuntos son demasiado grandes. Reduce la selección o el origen.", "読み込み元または添付ファイルが大きすぎます。項目を減らすか、小さい読み込み元を選んでください。"), nil)
        case ShelfImportError.capacityExceeded:
            return (localized("The selection exceeds the shelf’s remaining capacity. Select fewer items.", "所选项目超出暂存架剩余容量，请减少选择。", "Die Auswahl überschreitet die freie Kapazität. Wähle weniger Einträge.", "La sélection dépasse la capacité disponible. Sélectionnez moins d’éléments.", "La selección supera la capacidad disponible. Selecciona menos elementos.", "選択した項目が空き容量を超えています。項目を減らしてください。"), nil)
        case ShelfImportError.emptySelection:
            return (localized("Select at least one item.", "请至少选择一个项目。", "Wähle mindestens einen Eintrag.", "Sélectionnez au moins un élément.", "Selecciona al menos un elemento.", "項目を 1 件以上選択してください。"), nil)
        case let ShelfImportAssetError.invalidPath(path):
            return (localized("This source path is invalid. Choose another source.", "此来源路径无效，请选择其他来源。", "Dieser Quellpfad ist ungültig. Wähle eine andere Quelle.", "Ce chemin source est invalide. Choisissez une autre source.", "Esta ruta de origen no es válida. Elige otro origen.", "読み込み元のパスが無効です。別の読み込み元を選んでください。"), path)
        case let ShelfImportAssetError.unmappedFile(path):
            return (localized("Choose the matching folder for this file.", "请为此文件选择对应的读取文件夹。", "Wähle den passenden Ordner für diese Datei.", "Choisissez le dossier correspondant à ce fichier.", "Elige la carpeta correspondiente a este archivo.", "このファイルに対応するフォルダを選んでください。"), path)
        case let ShelfImportAssetError.missingFile(path):
            return (localized("This file is missing at the selected location. Choose the correct folder or deselect its entry.", "所选位置中找不到此文件，请选择正确的文件夹或取消对应项目。", "Diese Datei fehlt am gewählten Ort. Korrigiere den Ordner oder wähle den Eintrag ab.", "Ce fichier est absent. Corrigez le dossier ou désélectionnez l’entrée.", "Falta este archivo. Corrige la carpeta o deselecciona la entrada.", "選択した場所にファイルがありません。フォルダを変更するか、項目の選択を解除してください。"), path)
        case let ShelfImportAssetError.unreadableFile(path):
            return (localized("This file or folder cannot be read. Check its location and type; folder items must use reference mode.", "无法读取此文件或文件夹，请检查位置和类型。文件夹项目必须选择引用原件。", "Datei oder Ordner nicht lesbar. Prüfe Ort und Typ; Ordner müssen referenziert werden.", "Fichier ou dossier illisible. Vérifiez son emplacement et son type ; les dossiers doivent être référencés.", "No se puede leer el archivo o carpeta. Revisa ubicación y tipo; las carpetas deben referenciarse.", "ファイルまたはフォルダを読み取れません。場所と種類を確認してください。フォルダは参照モードを使用してください。"), path)
        case let ShelfImportAssetError.changedFile(path):
            return (localized("This file changed during preparation. Try again when it stops changing.", "准备期间此文件发生了变化，请等文件停止变化后重试。", "Die Datei wurde während der Vorbereitung geändert. Versuche es erneut, sobald sie unverändert bleibt.", "Ce fichier a changé pendant la préparation. Réessayez lorsqu’il sera stable.", "Este archivo cambió durante la preparación. Reintenta cuando deje de cambiar.", "準備中にファイルが変更されました。変更が終わってから再試行してください。"), path)
        case ShelfImportAssetError.mappingConflict:
            return (localized("Source folder mappings overlap. Reopen the import and choose the folders again.", "来源目录设置重叠，请重新打开导入并选择目录。", "Quellordner überlappen sich. Öffne den Import erneut und wähle die Ordner neu.", "Les dossiers sources se chevauchent. Rouvrez l’import et choisissez les dossiers à nouveau.", "Las carpetas de origen se superponen. Abre de nuevo la importación y vuelve a elegirlas.", "読み込み元フォルダの範囲が重複しています。読み込みを開き直して選択してください。"), nil)
        case ShelfImportAssetError.currentIndex:
            return (localized("This is the current shelf index. Choose a different source file.", "这是当前正在使用的暂存架索引，请选择其他来源文件。", "Dies ist der aktuelle Ablageindex. Wähle eine andere Quelldatei.", "Il s’agit de l’index actuel. Choisissez un autre fichier source.", "Este es el índice actual. Elige otro archivo de origen.", "現在使用中のシェルフです。別の読み込み元ファイルを選んでください。"), nil)
        case ShelfImportTransactionError.saveFailed:
            return (localized("Could not save the import. Check available storage and try again.", "无法保存导入结果，请检查可用存储空间后重试。", "Import konnte nicht gespeichert werden. Prüfe den freien Speicher und versuche es erneut.", "Impossible d’enregistrer l’import. Vérifiez l’espace disponible et réessayez.", "No se pudo guardar la importación. Comprueba el espacio disponible y reintenta.", "読み込み結果を保存できません。空き容量を確認して再試行してください。"), nil)
        case ShelfImportServiceError.unavailable:
            return (localized("The shelf is unavailable for import. Resolve its storage issue or wait for the current operation, then retry.", "暂存架暂时无法导入，请先处理存储提示或等待当前操作完成后重试。", "Die Ablage ist derzeit nicht verfügbar. Behebe Speicherprobleme oder warte auf den laufenden Vorgang.", "L’étagère est indisponible. Résolvez son problème de stockage ou attendez la fin de l’opération.", "La bandeja no está disponible. Resuelve el problema de almacenamiento o espera a que termine la operación.", "現在読み込めません。保存の問題を解決するか、処理が終わってから再試行してください。"), nil)
        case ShelfImportServiceError.changed:
            return (localized("The shelf changed during preparation. Review the selection and try again.", "准备期间暂存架发生了变化，请检查选择后重试。", "Die Ablage wurde während der Vorbereitung geändert. Prüfe die Auswahl und versuche es erneut.", "L’étagère a changé pendant la préparation. Vérifiez la sélection et réessayez.", "La bandeja cambió durante la preparación. Revisa la selección y reintenta.", "準備中にシェルフが変更されました。選択を確認して再試行してください。"), nil)
        case let ShelfImportServiceError.managedReference(path):
            return (localized("This location is managed by the shelf. Choose Copy attachments to keep the original out of shelf cleanup.", "该位置由暂存架管理，请选择复制附件，避免把原文件加入清理范围。", "Dieser Ort wird von der Ablage verwaltet. Wähle Anhänge kopieren, damit das Original nicht von der Bereinigung erfasst wird.", "Cet emplacement est géré par l’étagère. Choisissez Copier les pièces jointes pour exclure l’original du nettoyage.", "La bandeja administra esta ubicación. Elige Copiar adjuntos para excluir el original de la limpieza.", "この場所はシェルフが管理しています。元ファイルを削除対象に含めないよう、添付ファイルをコピーしてください。"), path)
        default: return (text(language).failure, nil)
        }
    }

    static func text(_ language: AppLanguage) -> Self {
        switch language {
        case .zhHans:
            return Self(title: "导入暂存架项目", button: "导入项目…",
                caption: "选择 ShelfItems.json 或旧偏好 plist。追加所选记录的副本，现有记录和源文件保留。",
                preview: "选择要导入的项目", cancel: "取消", busy: "正在准备导入…", selectAll: "全选", selectNone: "取消全选", importSelected: "导入所选项目",
                filesWarning: "旧索引没有记录文件是否属于旧应用。请为每个目录明确选择读取位置与导入方式，设置也用于其子目录。旧应用保存的附件应选择复制，避免删除旧应用后项目失联。",
                original: "索引中的目录", location: "读取位置", mode: "导入方式", chooseMode: "请选择方式…", reference: "引用原件", copy: "复制附件", notSelected: "尚未选择", useOriginal: "使用原位置", chooseDirectory: "选择对应文件夹…",
                referenceCaption: "继续使用所选位置的文件，移动或删除这些文件后项目可能无法打开。", copyCaption: "将文件复制到此暂存架，源文件保留。文件夹项目只能引用。", filesFormat: "%d 个文件引用，包含子目录", successFormat: "已导入 %d 个项目。", failure: "导入未完成。请检查来源和文件夹选择，或减少所选项目后重试。", group: "批组", groupDetails: "展开全部内容 · 整组一起选择", selectionFormat: "已选 %d 个顶层项目，共含 %d 个内容项目")
        case .de:
            return Self(title: "Ablage importieren", button: "Einträge importieren…",
                caption: "Wähle ShelfItems.json oder eine ältere Einstellungs-plist. Kopien der Auswahl werden angehängt; vorhandene Einträge und Quellen bleiben erhalten.",
                preview: "Einträge zum Import auswählen", cancel: "Abbrechen", busy: "Import wird vorbereitet…", selectAll: "Alle auswählen", selectNone: "Auswahl aufheben", importSelected: "Auswahl importieren",
                filesWarning: "Alte Indizes kennzeichnen keine app-eigenen Dateien. Wähle für jeden Ordner samt Unterordnern einen Speicherort und Importmodus. Kopiere Anhänge der alten App, damit ihre Entfernung die Verweise nicht unterbricht.",
                original: "Ordner im Index", location: "Lesen aus", mode: "Importmodus", chooseMode: "Modus auswählen…", reference: "Originale referenzieren", copy: "Anhänge kopieren", notSelected: "Nicht ausgewählt", useOriginal: "Originalort verwenden", chooseDirectory: "Passenden Ordner wählen…",
                referenceCaption: "Verwendet die Dateien am gewählten Ort. Verschieben oder Löschen kann die Einträge unzugänglich machen.", copyCaption: "Kopiert Dateien in diese Ablage und behält die Originale. Ordner können nur referenziert werden.", filesFormat: "%d Dateiverweise einschließlich Unterordnern", successFormat: "%d Einträge importiert.", failure: "Import nicht abgeschlossen. Prüfe Quelle und Ordner oder wähle weniger Einträge und versuche es erneut.", group: "Gruppe", groupDetails: "Alle Inhalte anzeigen · Gruppe wird vollständig ausgewählt", selectionFormat: "%d Haupteinträge ausgewählt · %d enthaltene Elemente")
        case .fr:
            return Self(title: "Importer dans l’étagère", button: "Importer des éléments…",
                caption: "Choisissez ShelfItems.json ou une ancienne plist de préférences. Des copies de la sélection sont ajoutées ; les éléments existants et les sources sont conservés.",
                preview: "Choisir les éléments à importer", cancel: "Annuler", busy: "Préparation de l’import…", selectAll: "Tout sélectionner", selectNone: "Tout désélectionner", importSelected: "Importer la sélection",
                filesWarning: "Les anciens index n’indiquent pas les fichiers appartenant à l’ancienne app. Choisissez un emplacement et un mode pour chaque dossier et ses sous-dossiers. Copiez les pièces jointes de l’ancienne app pour préserver leur accès après sa suppression.",
                original: "Dossier dans l’index", location: "Lire depuis", mode: "Mode d’import", chooseMode: "Choisir un mode…", reference: "Référencer les originaux", copy: "Copier les pièces jointes", notSelected: "Non sélectionné", useOriginal: "Utiliser l’emplacement original", chooseDirectory: "Choisir le dossier correspondant…",
                referenceCaption: "Utilise les fichiers à l’emplacement choisi. Leur déplacement ou suppression peut rendre les éléments indisponibles.", copyCaption: "Copie les fichiers dans cette étagère et conserve les originaux. Les dossiers peuvent uniquement être référencés.", filesFormat: "%d références de fichiers, sous-dossiers compris", successFormat: "%d éléments importés.", failure: "Import non terminé. Vérifiez la source et les dossiers, ou sélectionnez moins d’éléments, puis réessayez.", group: "Groupe", groupDetails: "Voir tout le contenu · sélection du groupe entier", selectionFormat: "%d entrées principales sélectionnées · %d éléments inclus")
        case .es:
            return Self(title: "Importar a la bandeja", button: "Importar elementos…",
                caption: "Elige ShelfItems.json o un plist de preferencias antiguo. Se añaden copias de la selección; los elementos existentes y los originales se conservan.",
                preview: "Elegir elementos para importar", cancel: "Cancelar", busy: "Preparando importación…", selectAll: "Seleccionar todo", selectNone: "Deseleccionar todo", importSelected: "Importar selección",
                filesWarning: "Los índices antiguos no identifican los archivos de la app anterior. Elige una ubicación y un modo para cada carpeta y sus subcarpetas. Copia los adjuntos de la app anterior para mantener el acceso después de eliminarla.",
                original: "Carpeta en el índice", location: "Leer desde", mode: "Modo de importación", chooseMode: "Elegir modo…", reference: "Referenciar originales", copy: "Copiar adjuntos", notSelected: "Sin seleccionar", useOriginal: "Usar ubicación original", chooseDirectory: "Elegir carpeta correspondiente…",
                referenceCaption: "Usa los archivos de la ubicación elegida. Moverlos o eliminarlos puede impedir abrir los elementos.", copyCaption: "Copia los archivos a esta bandeja y conserva los originales. Las carpetas solo pueden referenciarse.", filesFormat: "%d referencias de archivos, incluidas subcarpetas", successFormat: "%d elementos importados.", failure: "No se completó la importación. Revisa el origen y las carpetas, o selecciona menos elementos, y vuelve a intentarlo.", group: "Grupo", groupDetails: "Ver todo el contenido · se selecciona el grupo entero", selectionFormat: "%d entradas principales seleccionadas · %d elementos incluidos")
        case .ja:
            return Self(title: "シェルフに読み込む", button: "項目を読み込む…",
                caption: "ShelfItems.json または旧設定の plist を選びます。選択した項目のコピーを追加し、既存の項目と元ファイルは保持します。",
                preview: "読み込む項目を選択", cancel: "キャンセル", busy: "読み込みを準備中…", selectAll: "すべて選択", selectNone: "選択を解除", importSelected: "選択した項目を読み込む",
                filesWarning: "旧インデックスには旧アプリ所有のファイルかどうかが記録されていません。各フォルダとそのサブフォルダの場所と読み込み方法を選んでください。旧アプリを削除しても使えるよう、旧アプリが保存した添付ファイルはコピーしてください。",
                original: "インデックス内のフォルダ", location: "読み込み場所", mode: "読み込み方法", chooseMode: "方法を選択…", reference: "元ファイルを参照", copy: "添付ファイルをコピー", notSelected: "未選択", useOriginal: "元の場所を使用", chooseDirectory: "対応するフォルダを選択…",
                referenceCaption: "選択した場所のファイルを使用します。移動や削除により項目を開けなくなる場合があります。", copyCaption: "このシェルフにファイルをコピーし、元ファイルを保持します。フォルダ項目は参照のみ対応しています。", filesFormat: "サブフォルダを含む %d 件のファイル参照", successFormat: "%d 件の項目を読み込みました。", failure: "読み込みが完了しませんでした。読み込み元とフォルダを確認するか、選択する項目を減らして再試行してください。", group: "グループ", groupDetails: "すべての内容を表示 · グループ全体を選択", selectionFormat: "最上位 %d 件を選択 · 内容は合計 %d 件")
        default: return Self()
        }
    }
}
