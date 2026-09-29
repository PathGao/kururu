// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import Foundation

/// Localized strings for Dock Preview.
struct DockPreviewFeatureStrings {
    var pageTitle: String = "Dock Preview"
    var enable: String = "Preview windows from the Dock"
    var enableCaption: String = "Hover over an open app in the Dock to see its windows, then click the one you want."
    var currentSpaceOnlyCaption: String = "When off, shows windows from all desktops. Choosing a window on another desktop takes you there."
    var backgroundOpacity: String = "Panel background"
    var backgroundOpacityCaption: String = "Turn it down to see more of what sits behind the panel."
    var openDelay: String = "Open delay"
    var openDelayCaption: String = "How long the pointer has to rest on an icon before its panel opens."
    var quitAppOnClose: String = "Quit the app with the × button"
    var quitAppOnCloseCaption: String = "In Dock Preview, × quits the whole app instead of closing only that window."
    var keepDockVisible: String = "Keep Dock visible (experimental)"
    var keepDockVisibleCaption: String = "Pauses auto-hide while the preview is open and restores it when you leave. May resize windows. If the app is interrupted, reopen it to restore the Dock."
    var activeNow: String = "Active in the Dock"
    var dockUnavailable: String = "Could not read Dock items."
    var autohideBeta: String = "Beta. You may run into some bugs."
    var openWindow: String = "Open window"
    var closeWindow: String = "Close window"
    var minimizeWindow: String = "Minimize window"
    var restoreWindow: String = "Restore window"
    var pinPanel: String = "Pin preview"
    var unpinPanel: String = "Unpin preview"
    var pinned: String = "Pinned"
    var closePanel: String = "Close preview"
    var previousWindow: String = "Previous window"
    var nextWindow: String = "Next window"
}

extension FeatureStrings {
    static func dockPreview(_ language: AppLanguage) -> DockPreviewFeatureStrings {
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

extension DockPreviewFeatureStrings {
    static let enUS = DockPreviewFeatureStrings()

    static let ptBR = DockPreviewFeatureStrings(
        pageTitle: "Dock Preview",
        enable: "Pré-visualizar janelas no Dock",
        enableCaption: "Passe o mouse em um app aberto no Dock para ver suas janelas e clique na que quiser abrir.",
        backgroundOpacity: "Fundo do painel",
        backgroundOpacityCaption: "Diminua para ver mais do que está atrás do painel.",
        openDelay: "Atraso de abertura",
        openDelayCaption: "Quanto tempo o ponteiro precisa ficar sobre um ícone antes de o painel abrir.",
        quitAppOnClose: "Encerrar o app com o botão ×",
        quitAppOnCloseCaption: "No Dock Preview, × encerra o app inteiro em vez de fechar apenas aquela janela.",
        activeNow: "Ativo no Dock",
        dockUnavailable: "Não foi possível ler os itens do Dock.",
        autohideBeta: "Beta. Você pode encontrar alguns bugs.",
        openWindow: "Abrir janela",
        closeWindow: "Fechar janela",
        minimizeWindow: "Minimizar janela",
        restoreWindow: "Restaurar janela",
        pinPanel: "Fixar prévia",
        unpinPanel: "Desfixar prévia",
        pinned: "Fixado",
        closePanel: "Fechar prévia",
        previousWindow: "Janela anterior",
        nextWindow: "Próxima janela"
    )

    static let tr = DockPreviewFeatureStrings(
        pageTitle: "Dock Preview",
        enable: "Dock’tan pencereleri önizle",
        enableCaption: "Pencerelerini görmek için Dock’taki açık bir uygulamanın üzerine gel, ardından açmak istediğin pencereye tıkla.",
        backgroundOpacity: "Panel arka planı",
        backgroundOpacityCaption: "Panelin arkasındakileri daha çok görmek için azalt.",
        openDelay: "Açılma gecikmesi",
        openDelayCaption: "Panelin açılması için imlecin bir simgenin üzerinde ne kadar bekleyeceği.",
        quitAppOnClose: "× düğmesiyle uygulamadan çık",
        quitAppOnCloseCaption: "Dock Preview’da × yalnızca o pencereyi kapatmak yerine uygulamadan tamamen çıkar.",
        activeNow: "Dock’ta etkin",
        dockUnavailable: "Dock öğeleri okunamadı.",
        autohideBeta: "Beta. Bazı hatalarla karşılaşabilirsin.",
        openWindow: "Pencereyi aç",
        closeWindow: "Pencereyi kapat",
        minimizeWindow: "Pencereyi küçült",
        restoreWindow: "Pencereyi geri yükle",
        pinPanel: "Önizlemeyi sabitle",
        unpinPanel: "Önizleme sabitlemesini kaldır",
        pinned: "Sabitlendi",
        closePanel: "Önizlemeyi kapat",
        previousWindow: "Önceki pencere",
        nextWindow: "Sonraki pencere"
    )

    static let ru = DockPreviewFeatureStrings(
        pageTitle: "Dock Preview",
        enable: "Показывать окна из Dock",
        enableCaption: "Наведите указатель на открытое приложение в Dock, чтобы увидеть его окна, затем нажмите нужное.",
        backgroundOpacity: "Фон панели",
        backgroundOpacityCaption: "Уменьшите, чтобы видеть больше того, что находится за панелью.",
        openDelay: "Задержка открытия",
        openDelayCaption: "Сколько указатель должен оставаться на значке, прежде чем откроется панель.",
        quitAppOnClose: "Завершать приложение кнопкой ×",
        quitAppOnCloseCaption: "В Dock Preview кнопка × завершает всё приложение, а не закрывает только это окно.",
        activeNow: "Активно в Dock",
        dockUnavailable: "Не удалось прочитать элементы Dock.",
        autohideBeta: "Бета. Возможны ошибки.",
        openWindow: "Открыть окно",
        closeWindow: "Закрыть окно",
        minimizeWindow: "Свернуть окно",
        restoreWindow: "Восстановить окно",
        pinPanel: "Закрепить превью",
        unpinPanel: "Открепить превью",
        pinned: "Закреплено",
        closePanel: "Закрыть превью",
        previousWindow: "Предыдущее окно",
        nextWindow: "Следующее окно"
    )

    static let es = DockPreviewFeatureStrings(
        pageTitle: "Dock Preview",
        enable: "Previsualizar ventanas en el Dock",
        enableCaption: "Pasa el cursor sobre una app abierta en el Dock para ver sus ventanas y haz clic en la que quieras abrir.",
        backgroundOpacity: "Fondo del panel",
        backgroundOpacityCaption: "Bájalo para ver más de lo que hay detrás del panel.",
        openDelay: "Retardo de apertura",
        openDelayCaption: "Cuánto tiempo debe reposar el puntero sobre un icono antes de que se abra el panel.",
        quitAppOnClose: "Salir de la app con el botón ×",
        quitAppOnCloseCaption: "En Dock Preview, × cierra toda la app en lugar de cerrar solo esa ventana.",
        activeNow: "Activo en el Dock",
        dockUnavailable: "No se pudieron leer los ítems del Dock.",
        autohideBeta: "Beta. Puedes encontrar algunos errores.",
        openWindow: "Abrir ventana",
        closeWindow: "Cerrar ventana",
        minimizeWindow: "Minimizar ventana",
        restoreWindow: "Restaurar ventana",
        pinPanel: "Fijar vista previa",
        unpinPanel: "Soltar vista previa",
        pinned: "Fijado",
        closePanel: "Cerrar vista previa",
        previousWindow: "Ventana anterior",
        nextWindow: "Siguiente ventana"
    )

    static let de = DockPreviewFeatureStrings(
        pageTitle: "Dock Preview",
        enable: "Fenster im Dock vorab anzeigen",
        enableCaption: "Zeige auf eine geöffnete App im Dock, um ihre Fenster zu sehen, und klicke dann auf das gewünschte.",
        backgroundOpacity: "Hintergrund des Panels",
        backgroundOpacityCaption: "Verringere ihn, um mehr von dem zu sehen, was hinter dem Panel liegt.",
        openDelay: "Öffnungsverzögerung",
        openDelayCaption: "Wie lange der Zeiger auf einem Symbol ruhen muss, bevor sich das Panel öffnet.",
        quitAppOnClose: "App mit der ×-Taste beenden",
        quitAppOnCloseCaption: "In Dock Preview beendet × die gesamte App, statt nur dieses Fenster zu schließen.",
        activeNow: "Im Dock aktiv",
        dockUnavailable: "Dock-Elemente konnten nicht gelesen werden.",
        autohideBeta: "Beta. Es können noch Fehler auftreten.",
        openWindow: "Fenster öffnen",
        closeWindow: "Fenster schließen",
        minimizeWindow: "Fenster minimieren",
        restoreWindow: "Fenster wiederherstellen",
        pinPanel: "Vorschau anheften",
        unpinPanel: "Vorschau lösen",
        pinned: "Angeheftet",
        closePanel: "Vorschau schließen",
        previousWindow: "Vorheriges Fenster",
        nextWindow: "Nächstes Fenster"
    )

    static let fr = DockPreviewFeatureStrings(
        pageTitle: "Dock Preview",
        enable: "Prévisualiser les fenêtres dans le Dock",
        enableCaption: "Survolez une app ouverte dans le Dock pour voir ses fenêtres, puis cliquez sur celle à ouvrir.",
        backgroundOpacity: "Fond du panneau",
        backgroundOpacityCaption: "Baissez-le pour voir davantage ce qui se trouve derrière le panneau.",
        openDelay: "Délai d’ouverture",
        openDelayCaption: "Combien de temps le pointeur doit rester sur une icône avant que le panneau s’ouvre.",
        quitAppOnClose: "Quitter l’app avec le bouton ×",
        quitAppOnCloseCaption: "Dans Dock Preview, × quitte toute l’app au lieu de fermer uniquement cette fenêtre.",
        activeNow: "Actif dans le Dock",
        dockUnavailable: "Impossible de lire les éléments du Dock.",
        autohideBeta: "Bêta. Vous pouvez rencontrer quelques bugs.",
        openWindow: "Ouvrir la fenêtre",
        closeWindow: "Fermer la fenêtre",
        minimizeWindow: "Réduire la fenêtre",
        restoreWindow: "Restaurer la fenêtre",
        pinPanel: "Épingler l’aperçu",
        unpinPanel: "Détacher l’aperçu",
        pinned: "Épinglé",
        closePanel: "Fermer l’aperçu",
        previousWindow: "Fenêtre précédente",
        nextWindow: "Fenêtre suivante"
    )

    static let it = DockPreviewFeatureStrings(
        pageTitle: "Dock Preview",
        enable: "Anteprima finestre dal Dock",
        enableCaption: "Passa il mouse su un’app aperta nel Dock per vedere le sue finestre, poi fai clic su quella da aprire.",
        backgroundOpacity: "Sfondo del pannello",
        backgroundOpacityCaption: "Abbassalo per vedere di più di ciò che sta dietro al pannello.",
        openDelay: "Ritardo di apertura",
        openDelayCaption: "Quanto a lungo il puntatore deve restare su un’icona prima che il pannello si apra.",
        quitAppOnClose: "Chiudi l’app con il pulsante ×",
        quitAppOnCloseCaption: "In Dock Preview, × chiude l’intera app invece della sola finestra.",
        activeNow: "Attivo nel Dock",
        dockUnavailable: "Impossibile leggere gli elementi del Dock.",
        autohideBeta: "Beta. Potresti riscontrare alcuni bug.",
        openWindow: "Apri finestra",
        closeWindow: "Chiudi finestra",
        minimizeWindow: "Riduci finestra",
        restoreWindow: "Ripristina finestra",
        pinPanel: "Fissa anteprima",
        unpinPanel: "Sblocca anteprima",
        pinned: "Fissata",
        closePanel: "Chiudi anteprima",
        previousWindow: "Finestra precedente",
        nextWindow: "Finestra successiva"
    )

    static let ja = DockPreviewFeatureStrings(
        pageTitle: "Dock Preview",
        enable: "Dock でウインドウをプレビュー",
        enableCaption: "Dock の開いているアプリにポインタを重ねてウインドウを確認し、開きたいウインドウをクリックします。",
        backgroundOpacity: "パネルの背景",
        backgroundOpacityCaption: "下げると、パネルの後ろにあるものがより見えるようになります。",
        openDelay: "表示までの待ち時間",
        openDelayCaption: "ポインタをアイコンに置いてからパネルが開くまでの時間です。",
        quitAppOnClose: "× ボタンでアプリを終了",
        quitAppOnCloseCaption: "Dock Preview では、× はそのウインドウだけを閉じる代わりにアプリ全体を終了します。",
        activeNow: "Dock で有効",
        dockUnavailable: "Dock の項目を読み取れませんでした。",
        autohideBeta: "ベータ版です。一部の不具合が残っている場合があります。",
        openWindow: "ウインドウを開く",
        closeWindow: "ウインドウを閉じる",
        minimizeWindow: "ウインドウをしまう",
        restoreWindow: "ウインドウを戻す",
        pinPanel: "プレビューを固定",
        unpinPanel: "固定を解除",
        pinned: "固定中",
        closePanel: "プレビューを閉じる",
        previousWindow: "前のウインドウ",
        nextWindow: "次のウインドウ"
    )

    static let ko = DockPreviewFeatureStrings(
        pageTitle: "Dock 미리보기",
        enable: "Dock에서 윈도우 미리보기",
        enableCaption: "Dock의 열린 앱 위에 포인터를 올려 윈도우를 확인한 다음 원하는 윈도우를 클릭하세요.",
        backgroundOpacity: "패널 배경",
        backgroundOpacityCaption: "낮추면 패널 뒤에 있는 것이 더 많이 보입니다.",
        openDelay: "열림 지연",
        openDelayCaption: "포인터가 아이콘 위에 머문 뒤 패널이 열리기까지의 시간입니다.",
        quitAppOnClose: "× 버튼으로 앱 종료",
        quitAppOnCloseCaption: "Dock Preview에서 ×는 해당 윈도우만 닫는 대신 앱 전체를 종료합니다.",
        activeNow: "Dock에서 활성화됨",
        dockUnavailable: "Dock 항목을 읽을 수 없습니다.",
        autohideBeta: "베타 기능입니다. 일부 문제가 남아 있을 수 있습니다.",
        openWindow: "윈도우 열기",
        closeWindow: "윈도우 닫기",
        minimizeWindow: "윈도우 최소화",
        restoreWindow: "윈도우 복원",
        pinPanel: "미리보기 고정",
        unpinPanel: "고정 해제",
        pinned: "고정됨",
        closePanel: "미리보기 닫기",
        previousWindow: "이전 윈도우",
        nextWindow: "다음 윈도우"
    )

    static let zhHans = DockPreviewFeatureStrings(
        pageTitle: "Dock 窗口预览",
        enable: "在 Dock 中预览窗口",
        enableCaption: "将指针悬停在 Dock 中已打开的 App 上查看窗口，然后点按要打开的窗口。",
        currentSpaceOnlyCaption: "关闭时显示所有桌面的窗口。选择其他桌面上的窗口时，会切换到该桌面。",
        backgroundOpacity: "面板背景",
        backgroundOpacityCaption: "调低后可以看到更多面板后面的内容。",
        openDelay: "打开延迟",
        openDelayCaption: "指针停在图标上多久之后才打开面板。",
        quitAppOnClose: "使用 × 按钮退出 App",
        quitAppOnCloseCaption: "在 Dock 窗口预览中，× 会退出整个 App，而不只是关闭该窗口。",
        keepDockVisible: "保持程序坞显示（实验性）",
        keepDockVisibleCaption: "预览打开时暂停自动隐藏，离开时恢复。可能调整窗口大小。如果 App 意外中断，请重新打开以恢复程序坞设置。",
        activeNow: "已在 Dock 中启用",
        dockUnavailable: "无法读取 Dock 项目。",
        autohideBeta: "测试版。你可能会遇到一些错误。",
        openWindow: "打开窗口",
        closeWindow: "关闭窗口",
        minimizeWindow: "最小化窗口",
        restoreWindow: "恢复窗口",
        pinPanel: "固定预览",
        unpinPanel: "取消固定预览",
        pinned: "已固定",
        closePanel: "关闭预览",
        previousWindow: "上一个窗口",
        nextWindow: "下一个窗口"
    )

    static let zhTW = DockPreviewFeatureStrings(
        pageTitle: "Dock Preview",
        enable: "在 Dock 中預覽視窗",
        enableCaption: "將游標停在 Dock 中已開啟的 App 上查看視窗，然後點按要開啟的視窗。",
        backgroundOpacity: "面板背景",
        backgroundOpacityCaption: "調低後可以看到更多面板後面的內容。",
        openDelay: "開啟延遲",
        openDelayCaption: "指標停在圖示上多久之後才打開面板。",
        quitAppOnClose: "使用 × 按鈕結束 App",
        quitAppOnCloseCaption: "在 Dock Preview 中，× 會結束整個 App，而不只是關閉該視窗。",
        activeNow: "已在 Dock 中開啟",
        dockUnavailable: "無法讀取 Dock 項目。",
        autohideBeta: "測試版。你可能會遇到一些問題。",
        openWindow: "開啟視窗",
        closeWindow: "關閉視窗",
        minimizeWindow: "最小化視窗",
        restoreWindow: "還原視窗",
        pinPanel: "釘選預覽",
        unpinPanel: "取消釘選預覽",
        pinned: "已釘選",
        closePanel: "關閉預覽",
        previousWindow: "上一個視窗",
        nextWindow: "下一個視窗"
    )

    static let zhHK = DockPreviewFeatureStrings(
        pageTitle: "Dock Preview",
        enable: "在 Dock 中預覽視窗",
        enableCaption: "將指標停在 Dock 中已開啟的 App 上查看視窗，然後點按要開啟的視窗。",
        backgroundOpacity: "面板背景",
        backgroundOpacityCaption: "調低後可以看到更多面板後面的內容。",
        openDelay: "開啟延遲",
        openDelayCaption: "指標停在圖示上多久之後才打開面板。",
        quitAppOnClose: "使用 × 按鈕結束 App",
        quitAppOnCloseCaption: "在 Dock Preview 中，× 會結束整個 App，而不只是關閉該視窗。",
        activeNow: "已在 Dock 中啟用",
        dockUnavailable: "無法讀取 Dock 項目。",
        autohideBeta: "測試版。你可能會遇到一些問題。",
        openWindow: "開啟視窗",
        closeWindow: "關閉視窗",
        minimizeWindow: "最小化視窗",
        restoreWindow: "還原視窗",
        pinPanel: "釘選預覽",
        unpinPanel: "取消釘選預覽",
        pinned: "已釘選",
        closePanel: "關閉預覽",
        previousWindow: "上一個視窗",
        nextWindow: "下一個視窗"
    )
}
