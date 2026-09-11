// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import Foundation

struct SettingsActionStrings {
    let language: AppLanguage
    private var chinese: Bool { language == .zhHans }
    var exportFailed: String { chinese ? "未能导出设置。请检查目标位置后重试。" : "Settings could not be exported. Check the destination and try again." }
    func permissionFailure(_ result: PermissionResetResult) -> String {
        switch result {
        case .completed: return ""
        case .preparationFailed:
            return chinese ? "清理未完成：未能恢复系统设置或移除登录项。部分功能已暂停，请重新启动 kururu 后重试。" : "Cleanup stopped because system settings or the login item could not be restored. Some features are paused. Restart kururu before trying again."
        case .ruleRemovalFailed:
            return chinese ? "清理未完成：管理员授权已取消或规则移除失败，尚未重置权限。部分功能已暂停，请重新启动 kururu 后重试。" : "Cleanup stopped because administrator approval was cancelled or rule removal failed. Permissions have not been reset. Some features are paused. Restart kururu before trying again."
        case .resetFailed:
            return chinese ? "权限重置失败。部分系统设置已清理，请重新启动 kururu 后重试。" : "Permissions could not be reset. Some system settings have already been cleared. Restart kururu before trying again."
        }
    }
    func uninstallFailure(_ failure: SelfUninstall.Failure) -> String {
        let messages: [String]
        switch language {
        case .zhHans:
            messages = ["未能恢复系统设置、麦克风或登录项。应用资料保留。部分功能已暂停，请重启后重试。", "管理员授权已取消或规则移除失败。尚未重置权限，应用资料保留。", "权限重置失败。部分系统设置已清理，应用资料保留。", "部分资料未能删除，应用未移除。已删除的资料不会自动恢复。请检查以下位置后重试。", "未能交接应用移除任务。应用未移除，部分权限或资料可能已清理。请检查后重试。"]
        case .de:
            messages = ["Systemeinstellungen, Mikrofone oder Anmeldeeintrag konnten nicht wiederhergestellt werden. App-Daten bleiben erhalten. Einige Funktionen sind pausiert. Starte die App vor einem neuen Versuch neu.", "Administratorfreigabe abgebrochen oder Regel nicht entfernt. Berechtigungen und App-Daten bleiben erhalten.", "Berechtigungen konnten nicht zurückgesetzt werden. Einige Systemeinstellungen wurden bereits bereinigt. App-Daten bleiben erhalten.", "Einige Daten konnten nicht gelöscht werden. Die App bleibt installiert. Gelöschte Daten werden nicht automatisch wiederhergestellt. Prüfe diese Pfade vor einem neuen Versuch.", "App-Entfernung konnte nicht übergeben werden. Die App bleibt installiert. Einige Berechtigungen oder Daten wurden möglicherweise bereinigt. Prüfe dies vor einem neuen Versuch."]
        case .fr:
            messages = ["Impossible de restaurer les réglages système, les microphones ou l’ouverture à la connexion. Les données sont conservées. Certaines fonctions sont en pause. Redémarrez l’app avant de réessayer.", "Autorisation administrateur annulée ou règle non supprimée. Les autorisations et les données sont conservées.", "Impossible de réinitialiser les autorisations. Certains réglages système ont déjà été nettoyés. Les données sont conservées.", "Certaines données n’ont pas pu être supprimées. L’app reste installée. Les données supprimées ne seront pas restaurées automatiquement. Vérifiez ces chemins avant de réessayer.", "Impossible de transmettre la suppression de l’app. L’app reste installée. Certaines autorisations ou données ont peut-être été nettoyées. Vérifiez avant de réessayer."]
        case .es:
            messages = ["No se pudieron restaurar los ajustes del sistema, los micrófonos o el ítem de inicio. Los datos se conservan. Algunas funciones están en pausa. Reinicia la app antes de reintentar.", "Autorización del administrador cancelada o regla no eliminada. Los permisos y los datos se conservan.", "No se pudieron restablecer los permisos. Algunos ajustes del sistema ya se limpiaron. Los datos se conservan.", "No se pudieron eliminar algunos datos. La app sigue instalada. Los datos eliminados no se restaurarán automáticamente. Revisa estas rutas antes de reintentar.", "No se pudo transferir la eliminación de la app. La app sigue instalada. Algunos permisos o datos pueden haberse limpiado. Revisa antes de reintentar."]
        case .ja:
            messages = ["システム設定、マイク、またはログイン項目を復元できませんでした。データは保持されています。一部の機能は停止中です。アプリを再起動して再試行してください。", "管理者の承認がキャンセルされたか、ルールを削除できませんでした。権限とデータは保持されています。", "権限をリセットできませんでした。一部のシステム設定は解除済みですが、データは保持されています。", "一部のデータを削除できませんでした。アプリは残っています。削除済みのデータは自動復元されません。以下のパスを確認して再試行してください。", "アプリの削除処理を引き継げませんでした。アプリは残っています。一部の権限やデータは削除済みの可能性があります。確認して再試行してください。"]
        default:
            messages = ["System settings, microphones or the login item could not be restored. App data is kept. Some features are paused. Restart the app before trying again.", "Administrator approval was canceled or the rule could not be removed. Permissions and app data are kept.", "Permissions could not be reset. Some system settings were already cleared. App data is kept.", "Some data could not be deleted. The app was not removed. Deleted data will not be restored automatically. Check these paths before trying again.", "App removal could not be handed off. The app was not removed. Some permissions or data may already have been cleared. Check before trying again."]
        }
        switch failure {
        case .preparation: return messages[0]
        case .rule: return messages[1]
        case .permissions: return messages[2]
        case .files(let paths): return messages[3] + "\n" + removalRestartNote + "\n" + paths.joined(separator: "\n")
        case .handoff(let reason, let dataRemovalStarted):
            return messages[4] + (dataRemovalStarted ? "\n" + removalRestartNote : "") + "\n" + reason
        }
    }

    private var removalRestartNote: String {
        switch language {
        case .zhHans: return "资料工具已暂停保存。请重启应用后再使用。"
        case .de: return "Die Datenwerkzeuge speichern derzeit nicht. Starte die App neu, bevor du sie wieder verwendest."
        case .fr: return "Les outils de données ne sauvegardent plus. Redémarrez l’app avant de les réutiliser."
        case .es: return "Las herramientas de datos han dejado de guardar. Reinicia la app antes de volver a usarlas."
        case .ja: return "データツールの保存は停止中です。再び使用する前にアプリを再起動してください。"
        default: return "Data tools have stopped saving. Restart the app before using them again."
        }
    }

    func deleteProfileTitle(_ name: String) -> String {
        chinese ? "删除配置“\(name)”？" : "Delete “\(name)”?"
    }
    var deleteProfileBody: String { chinese ? "将删除此配置及其中的所有动作，无法撤销。其他配置不受影响。" : "This deletes the profile and all its actions. This cannot be undone. Other profiles are unaffected." }
    var replacementBlocked: String { chinese ? "此 App 已在拦截名单中，不能同时作为替代 App。请先将它从名单中移除，或选择其他 App。" : "This app is on the blocked list and cannot also be the replacement. Remove it from the list first, or choose another app." }
    var replacementCleared: String { chinese ? "替代 App 已加入拦截名单，因此已取消替代设置。请选择名单以外的 App。" : "The replacement app was added to the blocked list, so its replacement setting was cleared. Choose an app outside the list." }
}
