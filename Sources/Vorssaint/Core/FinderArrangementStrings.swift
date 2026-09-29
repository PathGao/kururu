// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import Foundation

struct FinderArrangementStrings {
    var title = "Keep folder icons arranged"
    var caption = "Choose an ordinary local folder in icon view before applying a rule. Finder must open or locate the chosen folder so the app can verify the exact target. The rule affects only that folder and continues without this app."
    var choose = "Choose folder…"
    var current = "Use current Finder folder"
    var apply = "Keep arranged by name"
    var restore = "Restore previous rule"
    var restoreNote = "Restoring the rule does not restore manually placed icon positions."
    var busy = "Working…"
    var done = "Rule verified."
    var permission = "Allow Finder Automation in System Settings, then retry."
    var canceled = "Canceled. No result was confirmed."
    var unsupported = "Open an ordinary local folder in Finder icon view, then read it again."
    var changed = "The folder, view or rule changed. Read it again."
    var failed = "Could not verify the rule. Read the folder before retrying."
    var timedOut = "Finder did not respond in time. Check for a system permission prompt, then read the folder again."
    var rules = ["None", "Snap to grid", "Name", "Date modified", "Date created", "Size", "Kind", "Label"]
    func rule(_ value: FinderArrangementRule) -> String { rules[value.rawValue] }
    func failure(_ value: FinderArrangementFailure) -> String {
        switch value {
        case .permission: return permission
        case .canceled: return canceled
        case .unsupported: return unsupported
        case .changed: return changed
        case .failed: return failed
        case .timedOut: return timedOut
        }
    }
    static func localized(_ language: AppLanguage) -> FinderArrangementStrings {
        switch language {
        case .zhHans: return FinderArrangementStrings(
            title: "持续排列文件夹图标",
            caption: "请先选择普通本地文件夹，再应用图标视图规则。访达需要打开或定位所选文件夹，以便本应用核实目标。规则仅影响此文件夹，退出本应用后仍持续生效。",
            choose: "选择文件夹…",
            current: "使用当前访达文件夹",
            apply: "按名称持续排列",
            restore: "恢复原排列规则",
            restoreNote: "恢复规则不会还原手动摆放的图标位置。",
            busy: "处理中…",
            done: "规则已核实。",
            permission: "请在系统设置中允许访达自动化后重试。",
            canceled: "已取消，未确认操作结果。",
            unsupported: "请在访达图标视图打开普通本地文件夹后重新读取。",
            changed: "文件夹、视图或规则已改变，请重新读取。",
            failed: "无法核实规则，请重新读取文件夹后再试。",
            timedOut: "访达响应超时。请检查是否有系统权限提示，然后重新读取文件夹。",
            rules: ["无排列", "对齐网格", "名称", "修改日期", "创建日期", "大小", "类型", "标签"])
        case .de: return FinderArrangementStrings(
            title: "Ordnersymbole angeordnet halten",
            caption: "Wähle vor dem Anwenden einer Regel einen normalen lokalen Ordner in der Symbolansicht. Finder muss ihn öffnen oder anzeigen, damit die App das genaue Ziel prüfen kann. Die Regel gilt nur dort und bleibt ohne diese App aktiv.",
            choose: "Ordner auswählen…",
            current: "Aktuellen Finder-Ordner verwenden",
            apply: "Nach Namen angeordnet halten",
            restore: "Vorherige Regel wiederherstellen",
            restoreNote: "Die Regel stellt manuell gesetzte Symbolpositionen nicht wieder her.",
            busy: "Wird bearbeitet…",
            done: "Regel überprüft.",
            permission: "Erlaube die Finder-Automatisierung in den Systemeinstellungen und versuche es erneut.",
            canceled: "Abgebrochen. Kein Ergebnis bestätigt.",
            unsupported: "Öffne einen normalen lokalen Ordner in der Finder-Symbolansicht und lies ihn erneut.",
            changed: "Ordner, Ansicht oder Regel geändert. Lies den Ordner erneut.",
            failed: "Regel nicht überprüfbar. Lies den Ordner vor einem neuen Versuch.",
            timedOut: "Finder hat nicht rechtzeitig geantwortet. Prüfe, ob eine Systemabfrage auf Bestätigung wartet, und lies den Ordner erneut.",
            rules: ["Keine", "Am Raster ausrichten", "Name", "Änderungsdatum", "Erstellungsdatum", "Größe", "Art", "Etikett"])
        case .fr: return FinderArrangementStrings(
            title: "Maintenir les icônes rangées",
            caption: "Choisissez un dossier local ordinaire en présentation par icônes avant d’appliquer une règle. Le Finder doit ouvrir ou localiser ce dossier pour que l’app vérifie la cible exacte. La règle ne concerne que ce dossier et reste active sans cette app.",
            choose: "Choisir un dossier…",
            current: "Utiliser le dossier actuel du Finder",
            apply: "Maintenir le rangement par nom",
            restore: "Rétablir la règle précédente",
            restoreNote: "La règle ne restaure pas les positions placées manuellement.",
            busy: "Opération en cours…",
            done: "Règle vérifiée.",
            permission: "Autorisez l’automatisation du Finder dans Réglages Système, puis réessayez.",
            canceled: "Annulé. Aucun résultat confirmé.",
            unsupported: "Ouvrez un dossier local ordinaire par icônes dans le Finder, puis relisez-le.",
            changed: "Le dossier, la présentation ou la règle a changé. Relisez le dossier.",
            failed: "Règle invérifiable. Relisez le dossier avant de réessayer.",
            timedOut: "Le Finder n’a pas répondu à temps. Vérifiez si une demande d’autorisation système attend, puis relisez le dossier.",
            rules: ["Aucun", "Aligner sur la grille", "Nom", "Date de modification", "Date de création", "Taille", "Type", "Étiquette"])
        case .es: return FinderArrangementStrings(
            title: "Mantener ordenados los iconos",
            caption: "Elige una carpeta local normal en vista de iconos antes de aplicar una regla. El Finder debe abrirla o localizarla para que la app verifique el destino exacto. La regla solo afecta a esa carpeta y continúa sin esta app.",
            choose: "Elegir carpeta…",
            current: "Usar carpeta actual del Finder",
            apply: "Mantener orden por nombre",
            restore: "Restaurar regla anterior",
            restoreNote: "La regla no recupera las posiciones colocadas manualmente.",
            busy: "Procesando…",
            done: "Regla verificada.",
            permission: "Permite la automatización del Finder en Ajustes del Sistema y reintenta.",
            canceled: "Cancelado. No se confirmó ningún resultado.",
            unsupported: "Abre una carpeta local normal en la vista de iconos del Finder y vuelve a leerla.",
            changed: "La carpeta, vista o regla cambió. Vuelve a leerla.",
            failed: "No se pudo verificar la regla. Lee la carpeta antes de reintentar.",
            timedOut: "El Finder no respondió a tiempo. Comprueba si hay una solicitud de permiso del sistema y vuelve a leer la carpeta.",
            rules: ["Ninguna", "Alinear a la cuadrícula", "Nombre", "Fecha de modificación", "Fecha de creación", "Tamaño", "Tipo", "Etiqueta"])
        case .ja: return FinderArrangementStrings(
            title: "フォルダのアイコンを整列",
            caption: "ルールを適用する前に、アイコン表示で通常のローカルフォルダを選びます。正確な対象を確認するため、Finderで選んだフォルダを開くか表示する必要があります。ルールはそのフォルダだけに適用され、アプリ終了後も有効です。",
            choose: "フォルダを選択…",
            current: "現在のFinderフォルダを使用",
            apply: "名前順で整列し続ける",
            restore: "以前のルールに戻す",
            restoreNote: "ルールを戻しても手動配置したアイコンの位置は復元されません。",
            busy: "処理中…",
            done: "ルールを確認しました。",
            permission: "システム設定でFinderのオートメーションを許可して再試行してください。",
            canceled: "キャンセルしました。結果は未確認です。",
            unsupported: "Finderのアイコン表示で通常のローカルフォルダを開き、再度読み取ってください。",
            changed: "フォルダ、表示またはルールが変わりました。再度読み取ってください。",
            failed: "ルールを確認できません。再試行前に読み取ってください。",
            timedOut: "Finderの応答がタイムアウトしました。システムの権限確認が表示されていないか確認し、フォルダを再度読み取ってください。",
            rules: ["なし", "グリッドに沿う", "名前", "変更日", "作成日", "サイズ", "種類", "ラベル"])
        default: return FinderArrangementStrings()
        }
    }
}
