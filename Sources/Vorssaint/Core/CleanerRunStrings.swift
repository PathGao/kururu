// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import Foundation

struct CleanerRunStrings {
    var success = "Last run %1$@: succeeded · %2$@ freed"
    var partialFailure = "Last run %1$@: partly completed · %2$@ freed · %3$d items failed"
    var failure = "Last run %1$@: failed · %3$d items failed"
    var unknown = "Last run %1$@: result unknown (older record) · %2$@ freed"

    func summary(result: CleanerRunResult, ranAt: String, freed: String) -> String {
        let format: String
        switch result.outcome {
        case .success: format = success
        case .partialFailure: format = partialFailure
        case .failure: format = failure
        case .unknown: format = unknown
        }
        return String(format: format, ranAt, freed, result.failed)
    }

    static func localized(_ language: AppLanguage) -> CleanerRunStrings {
        switch language {
        case .zhHans:
            return .init(success: "上次运行 %1$@：成功，已释放 %2$@",
                         partialFailure: "上次运行 %1$@：部分失败，已释放 %2$@，%3$d 项失败",
                         failure: "上次运行 %1$@：全部失败，%3$d 项失败",
                         unknown: "上次运行 %1$@：结果未知（旧记录），已释放 %2$@")
        case .de:
            return .init(success: "Letzter Lauf %1$@: erfolgreich · %2$@ freigegeben",
                         partialFailure: "Letzter Lauf %1$@: teilweise fehlgeschlagen · %2$@ freigegeben · %3$d Elemente fehlgeschlagen",
                         failure: "Letzter Lauf %1$@: fehlgeschlagen · %3$d Elemente fehlgeschlagen",
                         unknown: "Letzter Lauf %1$@: Ergebnis unbekannt (älterer Eintrag) · %2$@ freigegeben")
        case .fr:
            return .init(success: "Dernière exécution %1$@ : réussie · %2$@ libérés",
                         partialFailure: "Dernière exécution %1$@ : échec partiel · %2$@ libérés · %3$d éléments en échec",
                         failure: "Dernière exécution %1$@ : échec · %3$d éléments en échec",
                         unknown: "Dernière exécution %1$@ : résultat inconnu (ancien enregistrement) · %2$@ libérés")
        case .es:
            return .init(success: "Última ejecución %1$@: correcta · %2$@ liberados",
                         partialFailure: "Última ejecución %1$@: fallo parcial · %2$@ liberados · %3$d elementos fallidos",
                         failure: "Última ejecución %1$@: fallida · %3$d elementos fallidos",
                         unknown: "Última ejecución %1$@: resultado desconocido (registro antiguo) · %2$@ liberados")
        case .ja:
            return .init(success: "前回の実行 %1$@：成功・%2$@ を解放",
                         partialFailure: "前回の実行 %1$@：一部失敗・%2$@ を解放・%3$d 項目が失敗",
                         failure: "前回の実行 %1$@：すべて失敗・%3$d 項目が失敗",
                         unknown: "前回の実行 %1$@：結果不明（古い記録）・%2$@ を解放")
        default: return CleanerRunStrings()
        }
    }
}
