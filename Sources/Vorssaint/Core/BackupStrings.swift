// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import Foundation

/// Strings for the settings backup (export and import on the Advanced page).
/// Same contract as the other FeatureStrings structs: memberwise init in
/// declaration order, one static per language, all in this file.
struct BackupFeatureStrings {
    var title: String = "Backup"
    var description: String = "Export portable preferences to a file for another Mac. This settings backup excludes text from \(FeatureStrings.scratchpad(.enUS).pageTitle), clipboard history and Shelf items, and does not transfer system permissions."
    var exportButton: String = "Export settings…"
    var importButton: String = "Import settings…"
    var exported: String = "Backup saved"
    var importConfirmTitle: String = "Import these settings?"
    var importConfirmBody: String = "Your current settings are replaced by the file’s and the app restarts. Nothing else on this Mac is touched."
    var importAction: String = "Import and restart"
    var invalidFile: String = "This file is not a valid \(AppInfo.name) backup."
}

extension FeatureStrings {
    static func backup(_ language: AppLanguage) -> BackupFeatureStrings {
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

extension BackupFeatureStrings {
    static let ko = BackupFeatureStrings(
        title: "백업",
        description: "Export portable preferences to a file for another Mac. This settings backup excludes text from \(FeatureStrings.scratchpad(.ko).pageTitle), clipboard history and Shelf items, and does not transfer system permissions.",
        exportButton: "설정 내보내기…",
        importButton: "설정 가져오기…",
        exported: "백업을 저장했습니다",
        importConfirmTitle: "이 설정을 가져올까요?",
        importConfirmBody: "현재 설정이 파일의 설정으로 바뀌고 앱이 다시 시작됩니다. 이 Mac의 다른 항목은 변경되지 않습니다.",
        importAction: "가져오고 다시 시작",
        invalidFile: "이 파일은 유효한 \(AppInfo.name) 백업이 아닙니다."
    )
}

extension BackupFeatureStrings {
    static let enUS = BackupFeatureStrings()

    static let ptBR = BackupFeatureStrings(
        title: "Backup",
        description: "Export portable preferences to a file for another Mac. This settings backup excludes text from \(FeatureStrings.scratchpad(.ptBR).pageTitle), clipboard history and Shelf items, and does not transfer system permissions.",
        exportButton: "Exportar configurações…",
        importButton: "Importar configurações…",
        exported: "Backup salvo",
        importConfirmTitle: "Importar estas configurações?",
        importConfirmBody: "As configurações atuais são substituídas pelas do arquivo e o app reinicia. Nada mais neste Mac é alterado.",
        importAction: "Importar e reiniciar",
        invalidFile: "Este arquivo não é um backup válido do \(AppInfo.name)."
    )

    static let tr = BackupFeatureStrings(
        title: "Yedek",
        description: "Export portable preferences to a file for another Mac. This settings backup excludes text from \(FeatureStrings.scratchpad(.tr).pageTitle), clipboard history and Shelf items, and does not transfer system permissions.",
        exportButton: "Ayarları dışa aktar…",
        importButton: "Ayarları içe aktar…",
        exported: "Yedek kaydedildi",
        importConfirmTitle: "Bu ayarlar içe aktarılsın mı?",
        importConfirmBody: "Mevcut ayarlar dosyadakilerle değiştirilir ve uygulama yeniden başlar. Bu Mac’te başka hiçbir şeye dokunulmaz.",
        importAction: "İçe aktar ve yeniden başlat",
        invalidFile: "Bu dosya geçerli bir \(AppInfo.name) yedeği değil."
    )

    static let ru = BackupFeatureStrings(
        title: "Резервная копия",
        description: "Export portable preferences to a file for another Mac. This settings backup excludes text from \(FeatureStrings.scratchpad(.ru).pageTitle), clipboard history and Shelf items, and does not transfer system permissions.",
        exportButton: "Экспортировать настройки…",
        importButton: "Импортировать настройки…",
        exported: "Копия сохранена",
        importConfirmTitle: "Импортировать эти настройки?",
        importConfirmBody: "Текущие настройки заменяются настройками из файла, и приложение перезапускается. Больше ничего на этом Mac не меняется.",
        importAction: "Импортировать и перезапустить",
        invalidFile: "Этот файл не является корректной резервной копией \(AppInfo.name)."
    )

    static let es = BackupFeatureStrings(
        title: "Copia de seguridad",
        description: "Exporta los ajustes transferibles a un archivo para otro Mac. Esta copia de ajustes no incluye el texto de \(FeatureStrings.scratchpad(.es).pageTitle), el historial del portapapeles ni los ítems del estante, y no transfiere permisos del sistema.",
        exportButton: "Exportar ajustes…",
        importButton: "Importar ajustes…",
        exported: "Copia guardada",
        importConfirmTitle: "¿Importar estos ajustes?",
        importConfirmBody: "Los ajustes actuales se sustituyen por los del archivo y la app se reinicia. Nada más cambia en este Mac.",
        importAction: "Importar y reiniciar",
        invalidFile: "Este archivo no es una copia de seguridad válida de \(AppInfo.name)."
    )

    static let de = BackupFeatureStrings(
        title: "Backup",
        description: "Exportiere übertragbare Einstellungen in eine Datei für einen anderen Mac. Diese Einstellungssicherung enthält keine Texte aus „\(FeatureStrings.scratchpad(.de).pageTitle)“, Zwischenablagehistorie oder Ablageobjekte und überträgt keine Systemberechtigungen.",
        exportButton: "Einstellungen exportieren…",
        importButton: "Einstellungen importieren…",
        exported: "Backup gesichert",
        importConfirmTitle: "Diese Einstellungen importieren?",
        importConfirmBody: "Die aktuellen Einstellungen werden durch die der Datei ersetzt und die App startet neu. Sonst ändert sich auf diesem Mac nichts.",
        importAction: "Importieren und neu starten",
        invalidFile: "Diese Datei ist kein gültiges \(AppInfo.name)-Backup."
    )

    static let fr = BackupFeatureStrings(
        title: "Sauvegarde",
        description: "Exportez les réglages transférables dans un fichier pour un autre Mac. Cette sauvegarde ne contient ni le texte de «\u{00A0}\(FeatureStrings.scratchpad(.fr).pageTitle)\u{00A0}», ni l’historique du presse-papiers, ni les éléments de l’étagère et ne transfère pas les autorisations système.",
        exportButton: "Exporter les réglages…",
        importButton: "Importer les réglages…",
        exported: "Sauvegarde enregistrée",
        importConfirmTitle: "Importer ces réglages\u{00A0}?",
        importConfirmBody: "Les réglages actuels sont remplacés par ceux du fichier et l’app redémarre. Rien d’autre ne change sur ce Mac.",
        importAction: "Importer et redémarrer",
        invalidFile: "Ce fichier n’est pas une sauvegarde \(AppInfo.name) valide."
    )

    static let it = BackupFeatureStrings(
        title: "Backup",
        description: "Export portable preferences to a file for another Mac. This settings backup excludes text from \(FeatureStrings.scratchpad(.it).pageTitle), clipboard history and Shelf items, and does not transfer system permissions.",
        exportButton: "Esporta impostazioni…",
        importButton: "Importa impostazioni…",
        exported: "Backup salvato",
        importConfirmTitle: "Importare queste impostazioni?",
        importConfirmBody: "Le impostazioni attuali vengono sostituite da quelle del file e l’app si riavvia. Nient’altro cambia su questo Mac.",
        importAction: "Importa e riavvia",
        invalidFile: "Questo file non è un backup \(AppInfo.name) valido."
    )

    static let ja = BackupFeatureStrings(
        title: "バックアップ",
        description: "移行できる設定をファイルに書き出し、別の Mac に読み込めます。この設定バックアップには\(FeatureStrings.scratchpad(.ja).pageTitle)の本文、クリップボード履歴、シェルフの項目は含まれず、システム権限も移行されません。",
        exportButton: "設定を書き出す…",
        importButton: "設定を読み込む…",
        exported: "バックアップを保存しました",
        importConfirmTitle: "この設定を読み込みますか?",
        importConfirmBody: "現在の設定はファイルの内容に置き換えられ、アプリが再起動します。このMacのほかの部分は変わりません。",
        importAction: "読み込んで再起動",
        invalidFile: "このファイルは有効な\(AppInfo.name)のバックアップではありません。"
    )

    static let zhHans = BackupFeatureStrings(
        title: "备份",
        description: "将可迁移的偏好设置导出为文件，供另一台 Mac 导入。此设置备份不包含\(FeatureStrings.scratchpad(.zhHans).pageTitle)文本、剪贴板历史或暂存架项目，也不会转移系统权限。",
        exportButton: "导出设置…",
        importButton: "导入设置…",
        exported: "备份已存储",
        importConfirmTitle: "导入这些设置？",
        importConfirmBody: "当前设置将被文件中的设置替换，App 会重启。这台 Mac 上的其他内容不受影响。",
        importAction: "导入并重启",
        invalidFile: "该文件不是有效的 \(AppInfo.name) 备份。"
    )

    static let zhTW = BackupFeatureStrings(
        title: "備份",
        description: "Export portable preferences to a file for another Mac. This settings backup excludes text from \(FeatureStrings.scratchpad(.zhTW).pageTitle), clipboard history and Shelf items, and does not transfer system permissions.",
        exportButton: "匯出設定…",
        importButton: "匯入設定…",
        exported: "備份已儲存",
        importConfirmTitle: "匯入這些設定?",
        importConfirmBody: "目前設定將被檔案中的設定取代,App 會重新啟動。這台 Mac 上的其他內容不受影響。",
        importAction: "匯入並重新啟動",
        invalidFile: "此檔案不是有效的 \(AppInfo.name) 備份。"
    )

    static let zhHK = BackupFeatureStrings(
        title: "備份",
        description: "Export portable preferences to a file for another Mac. This settings backup excludes text from \(FeatureStrings.scratchpad(.zhHK).pageTitle), clipboard history and Shelf items, and does not transfer system permissions.",
        exportButton: "匯出設定…",
        importButton: "匯入設定…",
        exported: "備份已儲存",
        importConfirmTitle: "匯入這些設定?",
        importConfirmBody: "目前設定將被檔案中的設定取代,App 會重新啟動。這台 Mac 上的其他內容不受影響。",
        importAction: "匯入並重新啟動",
        invalidFile: "此檔案不是有效嘅 \(AppInfo.name) 備份。"
    )
}
