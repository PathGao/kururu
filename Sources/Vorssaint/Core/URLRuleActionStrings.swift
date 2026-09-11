// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import Foundation

struct URLRuleActionStrings {
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

    var lastCleanup: String {
        text("Last automatic cleanup: ", "上次自动清理：", "Letzte automatische Bereinigung: ",
             "Dernier nettoyage automatique : ", "Última limpieza automática: ", "前回の自動クリーニング：")
    }
    var sharedRules: String {
        text("These rules apply to manual and automatic cleanup. Manual cleanup remains available when automatic cleanup is off.",
             "这些规则同时用于手动清理和拷贝时自动清理。关闭自动清理后，仍可手动使用。",
             "Diese Regeln gelten für die manuelle und automatische Bereinigung. Auch bei deaktivierter Automatik bleibt die manuelle Bereinigung verfügbar.",
             "Ces règles s’appliquent au nettoyage manuel et automatique. Le nettoyage manuel reste disponible lorsque le nettoyage automatique est désactivé.",
             "Estas reglas se aplican a la limpieza manual y automática. La limpieza manual sigue disponible cuando la automática está desactivada.",
             "これらのルールは手動と自動のクリーニングに共通です。自動クリーニングをオフにしても手動で使用できます。")
    }
    func enabledCount(_ count: Int, total: Int) -> String {
        String(format: text("%d / %d enabled", "已启用 %d / %d", "%d / %d aktiviert",
                            "%d / %d activées", "%d / %d activadas", "%d / %d 有効"), count, total)
    }
    var enableGroup: String {
        text("Enable all rules in this group", "启用此组全部规则", "Alle Regeln dieser Gruppe aktivieren",
             "Activer toutes les règles du groupe", "Activar todas las reglas de este grupo", "このグループのすべてのルールを有効にする")
    }
    var disableGroup: String {
        text("Disable all rules in this group", "停用此组全部规则", "Alle Regeln dieser Gruppe deaktivieren",
             "Désactiver toutes les règles du groupe", "Desactivar todas las reglas de este grupo", "このグループのすべてのルールを無効にする")
    }
    var groupHelp: String {
        text("Group actions preserve custom rules", "规则组操作，保留自定义规则", "Gruppenaktionen behalten eigene Regeln bei",
             "Les actions du groupe conservent les règles personnalisées", "Las acciones del grupo conservan las reglas personalizadas", "グループ操作ではカスタムルールを保持します")
    }
    var ruleActions: String {
        text("Rule actions", "规则操作", "Regelaktionen", "Actions des règles", "Acciones de reglas", "ルール操作")
    }
    var deleteTitle: String {
        text("Delete custom rule?", "删除自定义规则？", "Eigene Regel löschen?",
             "Supprimer la règle personnalisée ?", "¿Eliminar la regla personalizada?", "カスタムルールを削除しますか？")
    }
    var deleteCustom: String {
        text("Delete custom rule…", "删除自定义规则…", "Eigene Regel löschen…",
             "Supprimer la règle personnalisée…", "Eliminar la regla personalizada…", "カスタムルールを削除…")
    }
    var delete: String { text("Delete", "删除", "Löschen", "Supprimer", "Eliminar", "削除") }
    var cancel: String { text("Cancel", "取消", "Abbrechen", "Annuler", "Cancelar", "キャンセル") }
    var deleteMessage: String {
        text("Only this custom rule will be deleted. To keep it, cancel and uncheck the rule instead.",
             "只删除这条自定义规则。若想保留规则，请取消后关闭它的复选框。",
             "Nur diese eigene Regel wird gelöscht. Um sie zu behalten, brechen Sie ab und deaktivieren Sie ihr Kontrollkästchen.",
             "Seule cette règle personnalisée sera supprimée. Pour la conserver, annulez puis décochez la règle.",
             "Solo se eliminará esta regla personalizada. Para conservarla, cancela y desmarca su casilla.",
             "このカスタムルールだけを削除します。保持する場合はキャンセルし、ルールのチェックを外してください。")
    }
}
