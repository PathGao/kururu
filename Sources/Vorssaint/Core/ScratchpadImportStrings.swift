// SPDX-License-Identifier: GPL-3.0-or-later

struct ScratchpadImportStrings {
    var title = "Import notes"
    var button = "Import notes…"
    var caption = "Choose Scratchpad.json or UTF-8 text and preview selected copies. Import adds to existing notes unless you explicitly choose to replace the only empty note. The source stays unchanged; copies start their retention period now. Up to 12 notes in total."
    var replaceOnlyEmpty = "Replace the current note if it is the only note and is empty"
    var chooseFile = "Choose a notes file"
    var previewTitle = "Choose notes to import"
    var importSelected = "Import selected"
    var cancel = "Cancel"
    var selectAll = "Select all"
    var sourceLabel = "Source"
    var emptySelection = "Select at least one note."
    var busy = "Reading notes…"
    var successFormat = "Imported %d notes."
    var readFailed = "Could not read this file. Check that it is available and try again."
    var invalidDocument = "This file does not contain supported notes. Choose Scratchpad.json or a UTF-8 text file."
    var tooLarge = "This file exceeds the 8 MiB limit. Choose a smaller notes file."
    var currentFile = "This is the current notes file. Choose a different source file."
    var capacityExceeded = "There is not enough room for the selected notes. Keep the total at 12 or fewer."
    var saveFailed = "Could not save the imported notes. Existing notes and the source file were kept."
    var unavailable = "Notes are unavailable right now. Try opening your current notes first."

    var capacityFormat = "Current: %d · Room for: %d · Selected: %d"
    var reduceSelectionFormat = "Deselect at least %d notes to continue."
    var replaceUnavailable = "Replacement is available only when there is exactly one empty note."

    static func text(_ language: AppLanguage) -> Self {
        switch language {
        case .zhHans:
            return Self(title: "导入便条", button: "导入便条…",
                        caption: "选择 Scratchpad.json 或 UTF-8 文本文件并预览。默认追加副本，保留现有便条；仅勾选下方选项时替换唯一空白便条。源文件不变，副本从现在计算保留期限，总数最多 12 张。",
                        replaceOnlyEmpty: "如果当前只有一张空白便条，替换它",
                        chooseFile: "选择便条文件", previewTitle: "选择要导入的便条", importSelected: "导入所选便条", cancel: "取消", selectAll: "全选", sourceLabel: "来源",
                        emptySelection: "请至少选择一张便条。", busy: "正在读取便条…", successFormat: "已导入 %d 张便条。",
                        readFailed: "无法读取文件，请检查文件是否可用后重试。",
                        invalidDocument: "文件不包含支持的便条内容，请选择 Scratchpad.json 或 UTF-8 文本文件。",
                        tooLarge: "文件超过 8 MiB 上限，请选择较小的便条文件。",
                        currentFile: "这是当前正在使用的便条文件，请选择其他来源文件。",
                        capacityExceeded: "所选便条超出剩余数量，请将便条总数控制在 12 张以内。",
                        saveFailed: "无法保存导入的便条，现有便条和源文件已保留。",
                        unavailable: "便条暂不可用，请先尝试打开现有便条。",
                        capacityFormat: "当前 %d 张 · 可导入 %d 张 · 已选 %d 张",
                        reduceSelectionFormat: "请至少取消选择 %d 张便条。",
                        replaceUnavailable: "仅当前只有一张空白便条时可以替换。")
        case .de:
            return Self(title: "Notizen importieren", button: "Notizen importieren…",
                        caption: "Wähle Scratchpad.json oder UTF-8-Text und prüfe die Vorschau. Kopien werden hinzugefügt; nur mit der Option unten wird die einzige leere Notiz ersetzt. Die Quelle bleibt unverändert. Die Aufbewahrungsfrist beginnt jetzt. Insgesamt höchstens 12 Notizen.",
                        replaceOnlyEmpty: "Die aktuelle Notiz ersetzen, wenn sie die einzige und leer ist",
                        chooseFile: "Notizdatei wählen", previewTitle: "Notizen zum Import auswählen", importSelected: "Auswahl importieren", cancel: "Abbrechen", selectAll: "Alle auswählen", sourceLabel: "Quelle",
                        emptySelection: "Wähle mindestens eine Notiz aus.", busy: "Notizen werden gelesen…", successFormat: "%d Notizen importiert.",
                        readFailed: "Die Datei konnte nicht gelesen werden. Prüfe, ob sie verfügbar ist, und versuche es erneut.",
                        invalidDocument: "Die Datei enthält keine unterstützten Notizen. Wähle Scratchpad.json oder eine UTF-8-Textdatei.",
                        tooLarge: "Die Datei überschreitet die Grenze von 8 MiB. Wähle eine kleinere Notizdatei.",
                        currentFile: "Dies ist die aktuelle Notizdatei. Wähle eine andere Quelldatei.",
                        capacityExceeded: "Für die Auswahl ist nicht genug Platz. Insgesamt dürfen es höchstens 12 Notizen sein.",
                        saveFailed: "Die importierten Notizen konnten nicht gespeichert werden. Vorhandene Notizen und die Quelldatei wurden beibehalten.",
                        unavailable: "Notizen sind derzeit nicht verfügbar. Versuche zuerst, deine vorhandenen Notizen zu öffnen.",
                        capacityFormat: "Vorhanden: %d · Platz für: %d · Ausgewählt: %d",
                        reduceSelectionFormat: "Wähle mindestens %d Notizen ab.",
                        replaceUnavailable: "Ersetzen ist nur bei genau einer leeren Notiz möglich.")
        case .fr:
            return Self(title: "Importer des notes", button: "Importer des notes…",
                        caption: "Choisissez Scratchpad.json ou du texte UTF-8 et consultez l’aperçu. Les copies sont ajoutées ; seule l’option ci-dessous permet de remplacer l’unique note vide. La source reste inchangée. La conservation des copies commence maintenant. Maximum : 12 notes.",
                        replaceOnlyEmpty: "Remplacer la note actuelle si elle est la seule et qu’elle est vide",
                        chooseFile: "Choisir un fichier de notes", previewTitle: "Choisir les notes à importer", importSelected: "Importer la sélection", cancel: "Annuler", selectAll: "Tout sélectionner", sourceLabel: "Source",
                        emptySelection: "Sélectionnez au moins une note.", busy: "Lecture des notes…", successFormat: "%d notes importées.",
                        readFailed: "Impossible de lire ce fichier. Vérifiez qu’il est disponible et réessayez.",
                        invalidDocument: "Ce fichier ne contient pas de notes prises en charge. Choisissez Scratchpad.json ou un fichier texte UTF-8.",
                        tooLarge: "Ce fichier dépasse la limite de 8 MiB. Choisissez un fichier de notes plus petit.",
                        currentFile: "Il s’agit du fichier de notes actuel. Choisissez un autre fichier source.",
                        capacityExceeded: "Il n’y a pas assez de place pour la sélection. Limitez le total à 12 notes.",
                        saveFailed: "Impossible d’enregistrer les notes importées. Les notes existantes et le fichier source ont été conservés.",
                        unavailable: "Les notes sont indisponibles pour le moment. Essayez d’abord d’ouvrir vos notes existantes.",
                        capacityFormat: "Actuelles\u{00A0}: %d · Places disponibles\u{00A0}: %d · Sélectionnées\u{00A0}: %d",
                        reduceSelectionFormat: "Désélectionnez au moins %d notes.",
                        replaceUnavailable: "Le remplacement est possible uniquement s’il existe une seule note vide.")
        case .es:
            return Self(title: "Importar notas", button: "Importar notas…",
                        caption: "Elige Scratchpad.json o texto UTF-8 y revisa la vista previa. Las copias se añaden; solo la opción de abajo permite sustituir la única nota vacía. El original no cambia. La conservación de las copias comienza ahora. Máximo: 12 notas.",
                        replaceOnlyEmpty: "Sustituir la nota actual si es la única y está vacía",
                        chooseFile: "Elegir archivo de notas", previewTitle: "Elegir notas para importar", importSelected: "Importar selección", cancel: "Cancelar", selectAll: "Seleccionar todo", sourceLabel: "Origen",
                        emptySelection: "Selecciona al menos una nota.", busy: "Leyendo notas…", successFormat: "Se importaron %d notas.",
                        readFailed: "No se pudo leer el archivo. Comprueba que esté disponible e inténtalo de nuevo.",
                        invalidDocument: "El archivo no contiene notas compatibles. Elige Scratchpad.json o un archivo de texto UTF-8.",
                        tooLarge: "El archivo supera el límite de 8 MiB. Elige un archivo de notas más pequeño.",
                        currentFile: "Este es el archivo de notas actual. Elige otro archivo de origen.",
                        capacityExceeded: "No hay espacio para las notas seleccionadas. Mantén el total en 12 notas o menos.",
                        saveFailed: "No se pudieron guardar las notas importadas. Se conservaron las notas existentes y el archivo original.",
                        unavailable: "Las notas no están disponibles ahora. Intenta abrir primero tus notas existentes.",
                        capacityFormat: "Actuales: %d · Espacio para: %d · Seleccionadas: %d",
                        reduceSelectionFormat: "Deselecciona al menos %d notas.",
                        replaceUnavailable: "Solo se puede reemplazar si hay exactamente una nota vacía.")
        case .ja:
            return Self(title: "メモを読み込む", button: "メモを読み込む…",
                        caption: "Scratchpad.json または UTF-8 テキストを選び、内容を確認します。通常はコピーを追加し、下の項目を選んだ場合のみ唯一の空白メモを置き換えます。元ファイルは変更せず、コピーの保存期間は今から始まります。合計 12 件までです。",
                        replaceOnlyEmpty: "現在のメモが 1 件だけで空白の場合は置き換える",
                        chooseFile: "メモファイルを選択", previewTitle: "読み込むメモを選択", importSelected: "選択したメモを読み込む", cancel: "キャンセル", selectAll: "すべて選択", sourceLabel: "読み込み元",
                        emptySelection: "メモを 1 件以上選択してください。", busy: "メモを読み込み中…", successFormat: "%d 件のメモを読み込みました。",
                        readFailed: "ファイルを読み取れません。利用可能か確認して、もう一度お試しください。",
                        invalidDocument: "対応するメモが含まれていません。Scratchpad.json または UTF-8 テキストファイルを選んでください。",
                        tooLarge: "ファイルが上限の 8 MiB を超えています。より小さいメモファイルを選んでください。",
                        currentFile: "これは現在使用中のメモファイルです。別の読み込み元ファイルを選んでください。",
                        capacityExceeded: "選択したメモを追加する空きがありません。合計 12 件以内にしてください。",
                        saveFailed: "読み込んだメモを保存できませんでした。既存のメモと元ファイルは保持されています。",
                        unavailable: "現在メモを利用できません。先に既存のメモを開いてみてください。",
                        capacityFormat: "現在 %d 件 · 読み込み可能 %d 件 · 選択済み %d 件",
                        reduceSelectionFormat: "少なくとも %d 件の選択を解除してください。",
                        replaceUnavailable: "現在のメモが空白の 1 件だけの場合に置き換えられます。")
        default:
            return Self()
        }
    }
}
