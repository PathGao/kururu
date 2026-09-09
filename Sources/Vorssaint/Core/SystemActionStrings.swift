// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import Foundation

/// Strings for the one-click system actions the command bar runs. Same
/// contract as the other FeatureStrings structs: memberwise init in
/// declaration order, one static per language, all in this file.
struct SystemActionStrings {
    let darkModeToDark: String
    let darkModeToLight: String
    let emptyTrashTitle: String
    let emptyTrashConfirmTitle: String
    let ejectTitle: String
    let hiddenFilesShow: String
    let hiddenFilesHide: String
    let desktopIconsHide: String
    let desktopIconsShow: String
    let lockScreenTitle: String
    let displayOffTitle: String
    let screenSaverTitle: String
}

extension FeatureStrings {
    static func systemActions(_ language: AppLanguage) -> SystemActionStrings {
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

extension SystemActionStrings {
    static let enUS = SystemActionStrings(
        darkModeToDark: "Switch to dark mode",
        darkModeToLight: "Switch to light mode",
        emptyTrashTitle: "Empty the Trash",
        emptyTrashConfirmTitle: "Empty the Trash?",
        ejectTitle: "Eject all disks",
        hiddenFilesShow: "Show hidden files",
        hiddenFilesHide: "Hide hidden files",
        desktopIconsHide: "Hide desktop icons",
        desktopIconsShow: "Show desktop icons",
        lockScreenTitle: "Lock the screen",
        displayOffTitle: "Turn off the display",
        screenSaverTitle: "Start the screen saver"
    )

    static let ptBR = SystemActionStrings(
        darkModeToDark: "Ativar o modo escuro",
        darkModeToLight: "Ativar o modo claro",
        emptyTrashTitle: "Esvaziar a Lixeira",
        emptyTrashConfirmTitle: "Esvaziar a Lixeira?",
        ejectTitle: "Ejetar todos os discos",
        hiddenFilesShow: "Mostrar arquivos ocultos",
        hiddenFilesHide: "Ocultar arquivos ocultos",
        desktopIconsHide: "Ocultar ícones da mesa",
        desktopIconsShow: "Mostrar ícones da mesa",
        lockScreenTitle: "Bloquear a tela",
        displayOffTitle: "Desligar a tela",
        screenSaverTitle: "Iniciar o protetor de tela"
    )

    static let tr = SystemActionStrings(
        darkModeToDark: "Karanlık moda geç",
        darkModeToLight: "Açık moda geç",
        emptyTrashTitle: "Çöp Sepeti’ni boşalt",
        emptyTrashConfirmTitle: "Çöp Sepeti boşaltılsın mı?",
        ejectTitle: "Tüm diskleri çıkar",
        hiddenFilesShow: "Gizli dosyaları göster",
        hiddenFilesHide: "Gizli dosyaları gizle",
        desktopIconsHide: "Masaüstü simgelerini gizle",
        desktopIconsShow: "Masaüstü simgelerini göster",
        lockScreenTitle: "Ekranı kilitle",
        displayOffTitle: "Ekranı kapat",
        screenSaverTitle: "Ekran koruyucuyu başlat"
    )

    static let ru = SystemActionStrings(
        darkModeToDark: "Включить тёмный режим",
        darkModeToLight: "Включить светлый режим",
        emptyTrashTitle: "Очистить Корзину",
        emptyTrashConfirmTitle: "Очистить Корзину?",
        ejectTitle: "Извлечь все диски",
        hiddenFilesShow: "Показать скрытые файлы",
        hiddenFilesHide: "Скрыть скрытые файлы",
        desktopIconsHide: "Скрыть значки рабочего стола",
        desktopIconsShow: "Показать значки рабочего стола",
        lockScreenTitle: "Заблокировать экран",
        displayOffTitle: "Выключить экран",
        screenSaverTitle: "Запустить заставку"
    )

    static let es = SystemActionStrings(
        darkModeToDark: "Cambiar al modo oscuro",
        darkModeToLight: "Cambiar al modo claro",
        emptyTrashTitle: "Vaciar la Papelera",
        emptyTrashConfirmTitle: "¿Vaciar la Papelera?",
        ejectTitle: "Expulsar todos los discos",
        hiddenFilesShow: "Mostrar archivos ocultos",
        hiddenFilesHide: "Ocultar archivos ocultos",
        desktopIconsHide: "Ocultar iconos del escritorio",
        desktopIconsShow: "Mostrar iconos del escritorio",
        lockScreenTitle: "Bloquear la pantalla",
        displayOffTitle: "Apagar la pantalla",
        screenSaverTitle: "Iniciar el salvapantallas"
    )

    static let de = SystemActionStrings(
        darkModeToDark: "Zum Dunkelmodus wechseln",
        darkModeToLight: "Zum Hellmodus wechseln",
        emptyTrashTitle: "Papierkorb entleeren",
        emptyTrashConfirmTitle: "Papierkorb entleeren?",
        ejectTitle: "Alle Festplatten auswerfen",
        hiddenFilesShow: "Versteckte Dateien einblenden",
        hiddenFilesHide: "Versteckte Dateien ausblenden",
        desktopIconsHide: "Schreibtischsymbole ausblenden",
        desktopIconsShow: "Schreibtischsymbole einblenden",
        lockScreenTitle: "Bildschirm sperren",
        displayOffTitle: "Bildschirm ausschalten",
        screenSaverTitle: "Bildschirmschoner starten"
    )

    static let fr = SystemActionStrings(
        darkModeToDark: "Passer en mode sombre",
        darkModeToLight: "Passer en mode clair",
        emptyTrashTitle: "Vider la Corbeille",
        emptyTrashConfirmTitle: "Vider la Corbeille\u{00A0}?",
        ejectTitle: "Éjecter tous les disques",
        hiddenFilesShow: "Afficher les fichiers masqués",
        hiddenFilesHide: "Masquer les fichiers masqués",
        desktopIconsHide: "Masquer les icônes du bureau",
        desktopIconsShow: "Afficher les icônes du bureau",
        lockScreenTitle: "Verrouiller l’écran",
        displayOffTitle: "Éteindre l’écran",
        screenSaverTitle: "Lancer l’économiseur d’écran"
    )

    static let it = SystemActionStrings(
        darkModeToDark: "Passa alla modalità scura",
        darkModeToLight: "Passa alla modalità chiara",
        emptyTrashTitle: "Svuota il Cestino",
        emptyTrashConfirmTitle: "Svuotare il Cestino?",
        ejectTitle: "Espelli tutti i dischi",
        hiddenFilesShow: "Mostra i file nascosti",
        hiddenFilesHide: "Nascondi i file nascosti",
        desktopIconsHide: "Nascondi le icone della scrivania",
        desktopIconsShow: "Mostra le icone della scrivania",
        lockScreenTitle: "Blocca lo schermo",
        displayOffTitle: "Spegni lo schermo",
        screenSaverTitle: "Avvia il salvaschermo"
    )

    static let ja = SystemActionStrings(
        darkModeToDark: "ダークモードに切り替える",
        darkModeToLight: "ライトモードに切り替える",
        emptyTrashTitle: "ゴミ箱を空にする",
        emptyTrashConfirmTitle: "ゴミ箱を空にしますか?",
        ejectTitle: "すべてのディスクを取り出す",
        hiddenFilesShow: "不可視ファイルを表示",
        hiddenFilesHide: "不可視ファイルを隠す",
        desktopIconsHide: "デスクトップのアイコンを隠す",
        desktopIconsShow: "デスクトップのアイコンを表示",
        lockScreenTitle: "画面をロック",
        displayOffTitle: "ディスプレイをオフにする",
        screenSaverTitle: "スクリーンセーバを開始"
    )

    static let ko = SystemActionStrings(
        darkModeToDark: "다크 모드로 전환",
        darkModeToLight: "라이트 모드로 전환",
        emptyTrashTitle: "휴지통 비우기",
        emptyTrashConfirmTitle: "휴지통을 비울까요?",
        ejectTitle: "모든 디스크 추출",
        hiddenFilesShow: "숨겨진 파일 보기",
        hiddenFilesHide: "숨겨진 파일 가리기",
        desktopIconsHide: "데스크탑 아이콘 가리기",
        desktopIconsShow: "데스크탑 아이콘 보기",
        lockScreenTitle: "화면 잠금",
        displayOffTitle: "디스플레이 끄기",
        screenSaverTitle: "화면 보호기 시작"
    )

    static let zhHans = SystemActionStrings(
        darkModeToDark: "切换到深色模式",
        darkModeToLight: "切换到浅色模式",
        emptyTrashTitle: "清倒废纸篓",
        emptyTrashConfirmTitle: "要清倒废纸篓吗？",
        ejectTitle: "推出所有磁盘",
        hiddenFilesShow: "显示隐藏的文件",
        hiddenFilesHide: "不显示隐藏的文件",
        desktopIconsHide: "隐藏桌面图标",
        desktopIconsShow: "显示桌面图标",
        lockScreenTitle: "锁定屏幕",
        displayOffTitle: "关闭显示器",
        screenSaverTitle: "启动屏幕保护程序"
    )

    static let zhTW = SystemActionStrings(
        darkModeToDark: "切換到深色模式",
        darkModeToLight: "切換到淺色模式",
        emptyTrashTitle: "清空垃圾桶",
        emptyTrashConfirmTitle: "要清空垃圾桶嗎?",
        ejectTitle: "退出所有磁碟",
        hiddenFilesShow: "顯示隱藏的檔案",
        hiddenFilesHide: "不顯示隱藏的檔案",
        desktopIconsHide: "隱藏桌面圖像",
        desktopIconsShow: "顯示桌面圖像",
        lockScreenTitle: "鎖定螢幕",
        displayOffTitle: "關閉顯示器",
        screenSaverTitle: "啟動螢幕保護程式"
    )

    static let zhHK = SystemActionStrings(
        darkModeToDark: "切換至深色模式",
        darkModeToLight: "切換至淺色模式",
        emptyTrashTitle: "清空垃圾桶",
        emptyTrashConfirmTitle: "要清空垃圾桶嗎?",
        ejectTitle: "推出所有磁碟",
        hiddenFilesShow: "顯示隱藏的檔案",
        hiddenFilesHide: "不顯示隱藏的檔案",
        desktopIconsHide: "隱藏桌面圖像",
        desktopIconsShow: "顯示桌面圖像",
        lockScreenTitle: "鎖定螢幕",
        displayOffTitle: "關閉顯示器",
        screenSaverTitle: "啟動螢幕保護程式"
    )
}
