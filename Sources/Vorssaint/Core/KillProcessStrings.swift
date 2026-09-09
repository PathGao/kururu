// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import Foundation

/// Strings for ending a process, shared by the Command Bar rows and the
/// monitor's Force Quit. Same contract as the other
/// FeatureStrings structs: memberwise init in declaration order, one static
/// per language, all in this file.
struct KillProcessFeatureStrings {
    let pageTitle: String
    let browseSubtitle: String
    let pidLabelFormat: String
    let killButton: String
    let forceKillButton: String
    let killAllFormat: String
    let killTreeButton: String
    let restartButton: String
    let confirmKillFormat: String
    let confirmForceKillFormat: String
    let confirmKillAllFormat: String
    let confirmKillTreeFormat: String
    let adminPromptFormat: String
}

extension FeatureStrings {
    static func killProcess(_ language: AppLanguage) -> KillProcessFeatureStrings {
        switch language {
        case .enUS: return .enUS
        case .ptBR: return .ptBR
        case .tr: return .tr
        case .ru: return .ru
        case .es: return .es
        case .de: return .de
        case .fr: return .fr
        case .it: return .it
        case .ja: return .ja
        case .ko: return .ko
        case .zhHans: return .zhHans
        case .zhTW: return .zhTW
        case .zhHK: return .zhHK
        }
    }
}

extension KillProcessFeatureStrings {
    static let enUS = KillProcessFeatureStrings(
        pageTitle: "Kill Process",
        browseSubtitle: "Browse & Kill",
        pidLabelFormat: "PID %d",
        killButton: "Kill",
        forceKillButton: "Force Kill",
        killAllFormat: "Kill All “%@”",
        killTreeButton: "Kill Process Tree",
        restartButton: "Restart",
        confirmKillFormat: "Kill %@?",
        confirmForceKillFormat: "Force Kill %@?",
        confirmKillAllFormat: "Kill all “%@” processes?",
        confirmKillTreeFormat: "Kill %@ and all its child processes?",
        adminPromptFormat: "Vorssaint needs administrator access to end “%@”."
    )

    static let ptBR = KillProcessFeatureStrings(
        pageTitle: "Encerrar Processo",
        browseSubtitle: "Ver e Encerrar",
        pidLabelFormat: "PID %d",
        killButton: "Encerrar",
        forceKillButton: "Forçar encerramento",
        killAllFormat: "Encerrar todos “%@”",
        killTreeButton: "Encerrar árvore de processos",
        restartButton: "Reiniciar",
        confirmKillFormat: "Encerrar %@?",
        confirmForceKillFormat: "Forçar encerramento de %@?",
        confirmKillAllFormat: "Encerrar todos os processos “%@”?",
        confirmKillTreeFormat: "Encerrar %@ e todos os seus processos filhos?",
        adminPromptFormat: "O Vorssaint precisa de acesso de administrador para encerrar “%@”."
    )

    static let tr = KillProcessFeatureStrings(
        pageTitle: "İşlemi Sonlandır",
        browseSubtitle: "Görüntüle ve Sonlandır",
        pidLabelFormat: "PID %d",
        killButton: "Sonlandır",
        forceKillButton: "Zorla Sonlandır",
        killAllFormat: "Tüm “%@” işlemlerini sonlandır",
        killTreeButton: "İşlem Ağacını Sonlandır",
        restartButton: "Yeniden Başlat",
        confirmKillFormat: "%@ sonlandırılsın mı?",
        confirmForceKillFormat: "%@ zorla sonlandırılsın mı?",
        confirmKillAllFormat: "Tüm “%@” işlemleri sonlandırılsın mı?",
        confirmKillTreeFormat: "%@ ve tüm alt işlemleri sonlandırılsın mı?",
        adminPromptFormat: "Vorssaint’in “%@” işlemini sonlandırması için yönetici erişimi gerekiyor."
    )

    static let ru = KillProcessFeatureStrings(
        pageTitle: "Завершить процесс",
        browseSubtitle: "Просмотр и завершение",
        pidLabelFormat: "PID %d",
        killButton: "Завершить",
        forceKillButton: "Завершить принудительно",
        killAllFormat: "Завершить все «%@»",
        killTreeButton: "Завершить дерево процессов",
        restartButton: "Перезапустить",
        confirmKillFormat: "Завершить %@?",
        confirmForceKillFormat: "Принудительно завершить %@?",
        confirmKillAllFormat: "Завершить все процессы «%@»?",
        confirmKillTreeFormat: "Завершить %@ и все его дочерние процессы?",
        adminPromptFormat: "Vorssaint нужны права администратора, чтобы завершить «%@»."
    )

    static let es = KillProcessFeatureStrings(
        pageTitle: "Finalizar Proceso",
        browseSubtitle: "Ver y Finalizar",
        pidLabelFormat: "PID %d",
        killButton: "Finalizar",
        forceKillButton: "Forzar finalización",
        killAllFormat: "Finalizar todos “%@”",
        killTreeButton: "Finalizar árbol de procesos",
        restartButton: "Reiniciar",
        confirmKillFormat: "¿Finalizar %@?",
        confirmForceKillFormat: "¿Forzar la finalización de %@?",
        confirmKillAllFormat: "¿Finalizar todos los procesos “%@”?",
        confirmKillTreeFormat: "¿Finalizar %@ y todos sus procesos hijos?",
        adminPromptFormat: "Vorssaint necesita acceso de administrador para finalizar “%@”."
    )

    static let de = KillProcessFeatureStrings(
        pageTitle: "Prozess beenden",
        browseSubtitle: "Anzeigen & Beenden",
        pidLabelFormat: "PID %d",
        killButton: "Beenden",
        forceKillButton: "Beenden erzwingen",
        killAllFormat: "Alle „%@“ beenden",
        killTreeButton: "Prozessbaum beenden",
        restartButton: "Neu starten",
        confirmKillFormat: "%@ beenden?",
        confirmForceKillFormat: "%@ zwangsweise beenden?",
        confirmKillAllFormat: "Alle „%@“-Prozesse beenden?",
        confirmKillTreeFormat: "%@ und alle untergeordneten Prozesse beenden?",
        adminPromptFormat: "Vorssaint benötigt Administratorrechte, um „%@“ zu beenden."
    )

    static let fr = KillProcessFeatureStrings(
        pageTitle: "Forcer à quitter",
        browseSubtitle: "Parcourir et arrêter",
        pidLabelFormat: "PID %d",
        killButton: "Arrêter",
        forceKillButton: "Forcer l’arrêt",
        killAllFormat: "Arrêter tous les «\u{00A0}%@\u{00A0}»",
        killTreeButton: "Arrêter l’arborescence du processus",
        restartButton: "Redémarrer",
        confirmKillFormat: "Arrêter %@\u{00A0}?",
        confirmForceKillFormat: "Forcer l’arrêt de %@\u{00A0}?",
        confirmKillAllFormat: "Arrêter tous les processus «\u{00A0}%@\u{00A0}»\u{00A0}?",
        confirmKillTreeFormat: "Arrêter %@ et tous ses processus enfants\u{00A0}?",
        adminPromptFormat: "Vorssaint a besoin d’un accès administrateur pour arrêter «\u{00A0}%@\u{00A0}»."
    )

    static let it = KillProcessFeatureStrings(
        pageTitle: "Termina Processo",
        browseSubtitle: "Sfoglia e Termina",
        pidLabelFormat: "PID %d",
        killButton: "Termina",
        forceKillButton: "Forza terminazione",
        killAllFormat: "Termina tutti “%@”",
        killTreeButton: "Termina alberatura del processo",
        restartButton: "Riavvia",
        confirmKillFormat: "Terminare %@?",
        confirmForceKillFormat: "Forzare la terminazione di %@?",
        confirmKillAllFormat: "Terminare tutti i processi “%@”?",
        confirmKillTreeFormat: "Terminare %@ e tutti i suoi processi figli?",
        adminPromptFormat: "Vorssaint richiede l’accesso da amministratore per terminare “%@”."
    )

    static let ja = KillProcessFeatureStrings(
        pageTitle: "プロセスを強制終了",
        browseSubtitle: "表示して終了",
        pidLabelFormat: "PID %d",
        killButton: "終了",
        forceKillButton: "強制終了",
        killAllFormat: "「%@」をすべて終了",
        killTreeButton: "プロセスツリーを終了",
        restartButton: "再起動",
        confirmKillFormat: "%@を終了しますか？",
        confirmForceKillFormat: "%@を強制終了しますか？",
        confirmKillAllFormat: "「%@」のプロセスをすべて終了しますか？",
        confirmKillTreeFormat: "%@とすべての子プロセスを終了しますか？",
        adminPromptFormat: "「%@」を終了するには管理者アクセスが必要です。"
    )

    static let ko = KillProcessFeatureStrings(
        pageTitle: "프로세스 종료",
        browseSubtitle: "보기 및 종료",
        pidLabelFormat: "PID %d",
        killButton: "종료",
        forceKillButton: "강제 종료",
        killAllFormat: "“%@” 모두 종료",
        killTreeButton: "프로세스 트리 종료",
        restartButton: "재시작",
        confirmKillFormat: "%@을(를) 종료할까요?",
        confirmForceKillFormat: "%@을(를) 강제 종료할까요?",
        confirmKillAllFormat: "“%@” 프로세스를 모두 종료할까요?",
        confirmKillTreeFormat: "%@와(과) 모든 하위 프로세스를 종료할까요?",
        adminPromptFormat: "“%@”을(를) 종료하려면 관리자 권한이 필요합니다."
    )

    static let zhHans = KillProcessFeatureStrings(
        pageTitle: "结束进程",
        browseSubtitle: "浏览并结束",
        pidLabelFormat: "PID %d",
        killButton: "结束",
        forceKillButton: "强制结束",
        killAllFormat: "结束所有“%@”",
        killTreeButton: "结束进程树",
        restartButton: "重新启动",
        confirmKillFormat: "要结束“%@”吗？",
        confirmForceKillFormat: "要强制结束“%@”吗？",
        confirmKillAllFormat: "要结束所有“%@”进程吗？",
        confirmKillTreeFormat: "要结束“%@”及其所有子进程吗？",
        adminPromptFormat: "Vorssaint 需要您的管理员密码才能结束“%@”。"
    )

    static let zhTW = KillProcessFeatureStrings(
        pageTitle: "結束處理程序",
        browseSubtitle: "瀏覽並結束",
        pidLabelFormat: "PID %d",
        killButton: "結束",
        forceKillButton: "強制結束",
        killAllFormat: "結束所有「%@」",
        killTreeButton: "結束處理程序樹",
        restartButton: "重新啟動",
        confirmKillFormat: "要結束「%@」嗎？",
        confirmForceKillFormat: "要強制結束「%@」嗎？",
        confirmKillAllFormat: "要結束所有「%@」處理程序嗎？",
        confirmKillTreeFormat: "要結束「%@」及其所有子處理程序嗎？",
        adminPromptFormat: "Vorssaint 需要管理員權限才能結束「%@」。"
    )

    static let zhHK = KillProcessFeatureStrings(
        pageTitle: "結束處理程序",
        browseSubtitle: "瀏覽並結束",
        pidLabelFormat: "PID %d",
        killButton: "結束",
        forceKillButton: "強制結束",
        killAllFormat: "結束所有「%@」",
        killTreeButton: "結束處理程序樹",
        restartButton: "重新啟動",
        confirmKillFormat: "要結束「%@」嗎？",
        confirmForceKillFormat: "要強制結束「%@」嗎？",
        confirmKillAllFormat: "要結束所有「%@」處理程序嗎？",
        confirmKillTreeFormat: "要結束「%@」及其所有子處理程序嗎？",
        adminPromptFormat: "Vorssaint 需要管理員權限才能結束「%@」。"
    )
}
