// SPDX-License-Identifier: GPL-3.0-or-later

struct ScratchpadSaveStrings {
    var unsavedChanges = "Changes have not been saved."
    var operationFailed = "The action could not be completed. Your current notes are unchanged. Try the action again."
    var retrySave = "Retry saving"
    var quitTitle = "Quit with unsaved notes?"
    var quitMessage = "Some note changes have not been saved. Cancel to retry saving or save a copy as a file. Quitting now will discard these unsaved changes."
    var cancelQuit = "Cancel"
    var discardAndQuit = "Discard changes and quit"

    static func text(_ language: AppLanguage) -> Self {
        switch language {
        case .zhHans:
            return Self(
                unsavedChanges: "更改尚未保存。",
                operationFailed: "操作未完成，当前便条保持不变。请重新执行该操作。",
                retrySave: "重试保存", quitTitle: "放弃未保存的便条更改并退出？",
                quitMessage: "部分便条更改尚未保存。取消退出后可重试保存，或存为文件保留副本。现在退出会丢弃这些未保存的更改。",
                cancelQuit: "取消", discardAndQuit: "放弃更改并退出")
        case .de:
            return Self(
                unsavedChanges: "Änderungen sind nicht gespeichert.",
                operationFailed: "Die Aktion konnte nicht abgeschlossen werden. Deine aktuellen Notizen sind unverändert. Führe die Aktion erneut aus.",
                retrySave: "Speichern wiederholen", quitTitle: "Mit ungespeicherten Notizen beenden?",
                quitMessage: "Einige Notizänderungen sind nicht gespeichert. Brich ab, um erneut zu speichern oder eine Dateikopie zu sichern. Beim Beenden gehen diese ungespeicherten Änderungen verloren.",
                cancelQuit: "Abbrechen", discardAndQuit: "Änderungen verwerfen und beenden")
        case .fr:
            return Self(
                unsavedChanges: "Les modifications ne sont pas enregistrées.",
                operationFailed: "L’action n’a pas abouti. Vos notes actuelles sont inchangées. Recommencez l’action.",
                retrySave: "Réessayer l’enregistrement", quitTitle: "Quitter avec des notes non enregistrées ?",
                quitMessage: "Certaines modifications des notes ne sont pas enregistrées. Annulez pour réessayer ou conserver une copie dans un fichier. Quitter maintenant supprimera ces modifications non enregistrées.",
                cancelQuit: "Annuler", discardAndQuit: "Abandonner les modifications et quitter")
        case .es:
            return Self(
                unsavedChanges: "Los cambios no se han guardado.",
                operationFailed: "No se pudo completar la acción. Tus notas actuales no han cambiado. Repite la acción.",
                retrySave: "Reintentar guardado", quitTitle: "¿Salir con notas sin guardar?",
                quitMessage: "Algunos cambios de las notas no se han guardado. Cancela para reintentar o guardar una copia como archivo. Si sales ahora, se perderán estos cambios sin guardar.",
                cancelQuit: "Cancelar", discardAndQuit: "Descartar cambios y salir")
        case .ja:
            return Self(
                unsavedChanges: "変更を保存できていません。",
                operationFailed: "操作を完了できませんでした。現在のメモは変更されていません。操作をもう一度行ってください。",
                retrySave: "保存を再試行", quitTitle: "未保存のメモを残して終了しますか？",
                quitMessage: "メモの変更の一部が保存されていません。キャンセルして保存を再試行するか、ファイルとしてコピーを保存してください。今終了すると、未保存の変更は失われます。",
                cancelQuit: "キャンセル", discardAndQuit: "変更を破棄して終了")
        default:
            return Self()
        }
    }
}
