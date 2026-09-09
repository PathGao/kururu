// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import Foundation

/// Localized strings for Dock clicks.
struct DockClickFeatureStrings {
    var pageTitle: String = "Dock clicks"
    var minimize: String = "Click the Dock icon to minimize"
    var minimizeCaption: String = "The active app’s windows minimize when you click its Dock icon. Click again to bring them back."
    var hide: String = "Click the Dock icon to hide the app"
    var hideCaption: String = "The active app hides when you click its Dock icon. Click again to bring it back."
    var cycleWindows: String = "Click the Dock icon to cycle windows"
    var cycleWindowsCaption: String = "Click an active app’s Dock icon to rotate through its windows, like ⌘`."
}

extension FeatureStrings {
    static func dockClick(_ language: AppLanguage) -> DockClickFeatureStrings {
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

extension DockClickFeatureStrings {
    static let enUS = DockClickFeatureStrings()

    static let ptBR = DockClickFeatureStrings(
        pageTitle: "Cliques no Dock",
        minimize: "Clicar no Dock minimiza",
        minimizeCaption: "As janelas do app ativo são minimizadas ao clicar no ícone dele no Dock. Clique de novo para trazê-las de volta.",
        hide: "Clicar no Dock oculta o app",
        hideCaption: "O app ativo é ocultado ao clicar no ícone dele no Dock. Clique de novo para trazê-lo de volta.",
        cycleWindows: "Clicar no Dock alterna janelas",
        cycleWindowsCaption: "Clique no ícone do Dock do app ativo para alternar entre suas janelas, como ⌘`."
    )

    static let tr = DockClickFeatureStrings(
        pageTitle: "Dock tıklamaları",
        minimize: "Dock simgesine tıklayınca küçült",
        minimizeCaption: "Etkin uygulamanın pencereleri Dock simgesine tıklandığında küçülür. Geri getirmek için yeniden tıklayın.",
        hide: "Dock simgesine tıklayınca uygulamayı gizle",
        hideCaption: "Etkin uygulamanın Dock simgesine tıklayınca uygulama gizlenir. Geri getirmek için yeniden tıklayın.",
        cycleWindows: "Dock simgesine tıklayınca pencere değiştir",
        cycleWindowsCaption: "Etkin uygulamanın Dock simgesine tıklayarak pencereleri arasında geçiş yapın, ⌘` gibi."
    )

    static let ru = DockClickFeatureStrings(
        pageTitle: "Клики по Dock",
        minimize: "Сворачивать кликом по Dock",
        minimizeCaption: "Окна активного приложения сворачиваются при клике по его значку в Dock. Кликните ещё раз, чтобы вернуть их.",
        hide: "Скрывать приложение кликом по Dock",
        hideCaption: "Активное приложение скрывается при клике по его значку в Dock. Нажмите ещё раз, чтобы вернуть его.",
        cycleWindows: "Кликом по Dock переключать окна",
        cycleWindowsCaption: "Клик по значку активного приложения в Dock переключает между его окнами, как ⌘`."
    )

    static let es = DockClickFeatureStrings(
        pageTitle: "Clics en el Dock",
        minimize: "Clic en el Dock para minimizar",
        minimizeCaption: "Las ventanas de la app activa se minimizan al hacer clic en su icono del Dock. Vuelve a hacer clic para recuperarlas.",
        hide: "Ocultar la app al hacer clic en el Dock",
        hideCaption: "La app activa se oculta al hacer clic en su icono del Dock. Haz clic de nuevo para recuperarla.",
        cycleWindows: "Clic en el Dock para alternar ventanas",
        cycleWindowsCaption: "Haz clic en el icono del Dock de la app activa para rotar entre sus ventanas, como ⌘`."
    )

    static let de = DockClickFeatureStrings(
        pageTitle: "Dock-Klicks",
        minimize: "Klick aufs Dock-Symbol minimiert",
        minimizeCaption: "Die Fenster der aktiven App werden beim Klick auf ihr Dock-Symbol im Dock abgelegt. Ein weiterer Klick holt sie zurück.",
        hide: "Klick aufs Dock-Symbol blendet App aus",
        hideCaption: "Die aktive App wird ausgeblendet, wenn du auf ihr Dock-Symbol klickst. Ein weiterer Klick holt sie zurück.",
        cycleWindows: "Klick aufs Dock-Symbol wechselt Fenster",
        cycleWindowsCaption: "Ein Klick auf das Dock-Symbol der aktiven App wechselt zwischen ihren Fenstern, wie ⌘`."
    )

    static let fr = DockClickFeatureStrings(
        pageTitle: "Clics sur le Dock",
        minimize: "Réduire d’un clic sur le Dock",
        minimizeCaption: "Les fenêtres de l’app active se réduisent d’un clic sur son icône du Dock. Cliquez à nouveau pour les faire revenir.",
        hide: "Masquer l’app d’un clic sur le Dock",
        hideCaption: "L’app active se masque lorsque vous cliquez sur son icône dans le Dock. Cliquez à nouveau pour la faire revenir.",
        cycleWindows: "Clic sur le Dock pour alterner les fenêtres",
        cycleWindowsCaption: "Cliquez sur l’icône d’une app active dans le Dock pour passer d’une fenêtre à l’autre, comme ⌘`."
    )

    static let it = DockClickFeatureStrings(
        pageTitle: "Clic sul Dock",
        minimize: "Riduci con un clic sul Dock",
        minimizeCaption: "Le finestre dell’app attiva si riducono nel Dock cliccando la sua icona. Fai clic di nuovo per ripristinarle.",
        hide: "Nascondi l’app con un clic sul Dock",
        hideCaption: "L’app attiva viene nascosta quando fai clic sulla sua icona nel Dock. Fai di nuovo clic per riportarla in primo piano.",
        cycleWindows: "Clic sul Dock per alternare le finestre",
        cycleWindowsCaption: "Fai clic sull’icona nel Dock dell’app attiva per passare da una finestra all’altra, come ⌘`."
    )

    static let ja = DockClickFeatureStrings(
        pageTitle: "Dockのクリック",
        minimize: "Dock クリックでしまう",
        minimizeCaption: "手前のアプリの Dock アイコンをクリックするとウインドウをしまいます。もう一度クリックすると戻ります。",
        hide: "Dock クリックでアプリを隠す",
        hideCaption: "手前のアプリの Dock アイコンをクリックすると、そのアプリを隠します。もう一度クリックすると戻ります。",
        cycleWindows: "Dock クリックでウインドウを切り替え",
        cycleWindowsCaption: "手前のアプリの Dock アイコンをクリックするとウインドウを順に切り替えます（⌘` と同様）。"
    )

    static let ko = DockClickFeatureStrings(
        pageTitle: "Dock 클릭",
        minimize: "Dock 클릭으로 최소화",
        minimizeCaption: "앞에 있는 앱의 Dock 아이콘을 클릭하면 윈도우를 최소화합니다. 다시 클릭하면 복원됩니다.",
        hide: "Dock 클릭으로 앱 숨기기",
        hideCaption: "활성 앱의 Dock 아이콘을 클릭하면 앱이 숨겨집니다. 다시 클릭하면 돌아옵니다.",
        cycleWindows: "Dock 클릭으로 윈도우 전환",
        cycleWindowsCaption: "앞에 있는 앱의 Dock 아이콘을 클릭하면 윈도우를 차례로 전환합니다(⌘`과 동일)."
    )

    static let zhHans = DockClickFeatureStrings(
        pageTitle: "Dock 点按",
        minimize: "点按 Dock 图标最小化",
        minimizeCaption: "点按最前面 App 的 Dock 图标可将其窗口最小化。再次点按即可恢复。",
        hide: "点按 Dock 图标隐藏 App",
        hideCaption: "点按当前 App 的 Dock 图标可隐藏它。再次点按即可恢复。",
        cycleWindows: "点按 Dock 图标切换窗口",
        cycleWindowsCaption: "点按最前面 App 的 Dock 图标可在其窗口之间轮换，类似 ⌘`。"
    )

    static let zhTW = DockClickFeatureStrings(
        pageTitle: "Dock 點按",
        minimize: "點按 Dock 圖示最小化",
        minimizeCaption: "點按最前方 App 的 Dock 圖示可將其視窗最小化。再點按一次即可還原。",
        hide: "點按 Dock 圖示隱藏 App",
        hideCaption: "點按目前 App 的 Dock 圖示即可隱藏它。再點按一次即可帶回。",
        cycleWindows: "點按 Dock 圖示切換視窗",
        cycleWindowsCaption: "點按最前方 App 的 Dock 圖示可在其視窗之間輪換，類似 ⌘`。"
    )

    static let zhHK = DockClickFeatureStrings(
        pageTitle: "Dock 點按",
        minimize: "點按 Dock 圖示最小化",
        minimizeCaption: "點按最前面 App 的 Dock 圖示可將其視窗最小化。再點按一次即可還原。",
        hide: "點按 Dock 圖示隱藏 App",
        hideCaption: "點按目前 App 的 Dock 圖示即可隱藏它。再點按一次即可帶回。",
        cycleWindows: "點按 Dock 圖示切換視窗",
        cycleWindowsCaption: "點按最前面 App 的 Dock 圖示可在其視窗之間輪換，類似 ⌘`。"
    )
}
