// SPDX-License-Identifier: GPL-3.0-or-later
struct ShelfPersistenceStrings {
    var unreadable = "Saved shelf could not be read completely. Original data is kept; changes in this session are not saved."
    var saveFailed = "Changes have not been saved. Keep kururu open and retry."
    var tooLarge = "Changes have not been saved. Reduce shelf items or shorten text. Saved data is kept. Keep kururu open until saving resumes."
    var retry = "Retry saving"
    var saving = "Saving…"

    static func text(_ language: AppLanguage) -> Self {
        switch language {
        case .zhHans:
            return Self(unreadable: "无法完整读取已保存的暂存架。原资料已保留，本次会话的更改不会保存。", saveFailed: "更改尚未保存，请保持 kururu 运行并重试。", tooLarge: "更改尚未保存。请减少暂存条目或缩短文字。已保存的资料会保留，请保持 kururu 运行，直到恢复保存。", retry: "重试保存", saving: "正在保存…")
        case .de:
            return Self(unreadable: "Die gespeicherte Ablage konnte nicht vollständig gelesen werden. Originaldaten bleiben erhalten; Änderungen dieser Sitzung werden nicht gespeichert.", saveFailed: "Änderungen wurden nicht gespeichert. Lass kururu geöffnet und versuche es erneut.", tooLarge: "Änderungen wurden nicht gespeichert. Entferne Ablageelemente oder kürze Texte. Gespeicherte Daten bleiben erhalten. Lass kururu geöffnet, bis das Speichern wieder funktioniert.", retry: "Speichern wiederholen", saving: "Wird gespeichert…")
        case .fr:
            return Self(unreadable: "L’étagère enregistrée n’a pas pu être lue entièrement. Les données d’origine sont conservées ; les modifications de cette session ne sont pas enregistrées.", saveFailed: "Les modifications n’ont pas été enregistrées. Gardez kururu ouvert et réessayez.", tooLarge: "Les modifications n’ont pas été enregistrées. Réduisez les éléments ou raccourcissez les textes. Les données enregistrées sont conservées. Gardez kururu ouvert jusqu’à la reprise de l’enregistrement.", retry: "Réessayer l’enregistrement", saving: "Enregistrement…")
        case .es:
            return Self(unreadable: "No se pudo leer toda la bandeja guardada. Se conservan los datos originales; los cambios de esta sesión no se guardan.", saveFailed: "Los cambios no se han guardado. Mantén kururu abierto e inténtalo de nuevo.", tooLarge: "Los cambios no se han guardado. Reduce los elementos o acorta los textos. Los datos guardados se conservan. Mantén kururu abierto hasta que se reanude el guardado.", retry: "Reintentar guardar", saving: "Guardando…")
        case .ja:
            return Self(unreadable: "保存済みのシェルフを完全に読み取れませんでした。元のデータは保持され、このセッションの変更は保存されません。", saveFailed: "変更はまだ保存されていません。kururu を開いたまま再試行してください。", tooLarge: "変更はまだ保存されていません。項目を減らすか、テキストを短くしてください。保存済みのデータは保持されます。保存が再開するまで kururu を開いたままにしてください。", retry: "保存を再試行", saving: "保存中…")
        default: return Self()
        }
    }
}
