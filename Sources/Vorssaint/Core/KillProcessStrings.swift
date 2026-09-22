// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import Foundation

/// Strings for the Kill Process feature. Same contract as the other
/// FeatureStrings structs: memberwise init in declaration order, one static
/// per language, all in this file.
struct KillProcessFeatureStrings {
    var pageTitle: String = "Kill Process"
    var browseSubtitle: String = "Browse & Kill"
    var hubDescription: String = "Search running processes and force quit, restart, or kill process trees"
    var searchPlaceholder: String = "Filter by name"
    var columnProcess: String = "Process"
    var columnCPU: String = "CPU"
    var columnMemory: String = "Memory"
    var columnPID: String = "PID"
    var groupToggle: String = "Group related processes"
    var groupCaption: String = "Groups helper processes under the app responsible for them."
    var refreshTooltip: String = "Refresh"
    var pidLabelFormat: String = "PID %d"
    var processCountFormat: String = "Processes: %d"
    var killButton: String = "Kill"
    var forceKillButton: String = "Force Kill"
    var killAllFormat: String = "Kill All “%@”"
    var killTreeButton: String = "Kill Process Tree"
    var restartButton: String = "Restart"
    var copyPID: String = "Copy PID"
    var copyPath: String = "Copy Path"
    var emptyStateTitle: String = "No Processes Found"
    var confirmKillFormat: String = "Kill %@?"
    var confirmForceKillFormat: String = "Force Kill %@?"
    var confirmKillAllFormat: String = "Kill all “%@” processes?"
    var confirmKillTreeFormat: String = "Kill %@ and all its child processes?"
    var adminPromptFormat: String = "\(AppInfo.name) needs administrator access to end “%@”."
    var monitorKillFailedFormat: String = "Could not end %@. The process may have exited or changed. Refresh and try again."
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
    static let enUS = KillProcessFeatureStrings()

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
        adminPromptFormat: "O \(AppInfo.name) precisa de acesso de administrador para encerrar “%@”."
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
        adminPromptFormat: "\(AppInfo.name)’in “%@” işlemini sonlandırması için yönetici erişimi gerekiyor."
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
        adminPromptFormat: "\(AppInfo.name) нужны права администратора, чтобы завершить «%@»."
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
        adminPromptFormat: "\(AppInfo.name) necesita acceso de administrador para finalizar “%@”.",
        monitorKillFailedFormat: "No se pudo finalizar %@. Puede que el proceso haya terminado o cambiado. Actualiza la vista e inténtalo de nuevo."
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
        adminPromptFormat: "\(AppInfo.name) benötigt Administratorrechte, um „%@“ zu beenden.",
        monitorKillFailedFormat: "%@ konnte nicht beendet werden. Der Prozess wurde möglicherweise beendet oder geändert. Aktualisiere die Ansicht und versuche es erneut."
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
        adminPromptFormat: "\(AppInfo.name) a besoin d’un accès administrateur pour arrêter «\u{00A0}%@\u{00A0}».",
        monitorKillFailedFormat: "Impossible d’arrêter %@. Le processus a peut-être quitté ou changé. Actualisez la vue et réessayez."
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
        adminPromptFormat: "\(AppInfo.name) richiede l’accesso da amministratore per terminare “%@”."
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
        adminPromptFormat: "「%@」を終了するには管理者アクセスが必要です。",
        monitorKillFailedFormat: "%@ を終了できませんでした。プロセスが終了または変更された可能性があります。表示を更新して再試行してください。"
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
        hubDescription: "搜索正在运行的进程，强制退出、重新启动或结束整个进程树",
        searchPlaceholder: "按名称筛选",
        columnProcess: "进程",
        columnCPU: "CPU",
        columnMemory: "内存",
        columnPID: "PID",
        groupToggle: "合并相关进程",
        groupCaption: "将辅助进程归并到负责它们的 App 下面。",
        refreshTooltip: "刷新",
        pidLabelFormat: "PID %d",
        processCountFormat: "%d 个进程",
        killButton: "结束",
        forceKillButton: "强制结束",
        killAllFormat: "结束所有“%@”",
        killTreeButton: "结束进程树",
        restartButton: "重新启动",
        copyPID: "拷贝 PID",
        copyPath: "拷贝路径",
        emptyStateTitle: "未找到进程",
        confirmKillFormat: "要结束“%@”吗？",
        confirmForceKillFormat: "要强制结束“%@”吗？",
        confirmKillAllFormat: "要结束所有“%@”进程吗？",
        confirmKillTreeFormat: "要结束“%@”及其所有子进程吗？",
        adminPromptFormat: "\(AppInfo.name) 需要您的管理员密码才能结束“%@”。",
        monitorKillFailedFormat: "无法结束 %@。进程可能已退出或发生变化。请刷新后重试。"
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
        adminPromptFormat: "\(AppInfo.name) 需要管理員權限才能結束「%@」。"
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
        adminPromptFormat: "\(AppInfo.name) 需要管理員權限才能結束「%@」。"
    )
}
