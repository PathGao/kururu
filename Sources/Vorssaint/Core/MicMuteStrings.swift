// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import Foundation

/// Localized strings for the microphone mute toggle.
struct MicMuteFeatureStrings {
    var pageTitle: String = "Mute microphone"
    var unmuteName: String = "Unmute microphone"
    var caption: String = "Cuts the Mac’s microphone with a click or shortcut, across every app."
    var mutedHUD: String = "Microphone muted"
    var unmutedHUD: String = "Microphone back on"
    var menuBarToggle: String = "Show in the menu bar while muted"
    var menuBarCaption: String = "A red crossed-out mic appears beside the app’s icon in the menu bar."
}

extension FeatureStrings {
    static func micMute(_ language: AppLanguage) -> MicMuteFeatureStrings {
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

extension MicMuteFeatureStrings {
    static let enUS = MicMuteFeatureStrings()

    static let ptBR = MicMuteFeatureStrings(
        pageTitle: "Silenciar microfone",
        unmuteName: "Reativar microfone",
        caption: "Corta o microfone do Mac com um clique ou atalho, valendo para qualquer app.",
        mutedHUD: "Microfone silenciado",
        unmutedHUD: "Microfone reativado",
        menuBarToggle: "Mostrar na barra de menus enquanto silenciado",
        menuBarCaption: "Um microfone cortado em vermelho aparece ao lado do ícone do app na barra de menus."
    )

    static let tr = MicMuteFeatureStrings(
        pageTitle: "Mikrofonu sessize al",
        unmuteName: "Mikrofonu aç",
        caption: "Mac’in mikrofonunu tek tıkla veya kısayolla keser; tüm uygulamalarda geçerlidir.",
        mutedHUD: "Mikrofon sessize alındı",
        unmutedHUD: "Mikrofon yeniden açıldı",
        menuBarToggle: "Sessizken menü çubuğunda göster",
        menuBarCaption: "Menü çubuğundaki uygulama simgesinin yanında üstü çizili kırmızı bir mikrofon görünür."
    )

    static let ru = MicMuteFeatureStrings(
        pageTitle: "Выключить микрофон",
        unmuteName: "Включить микрофон",
        caption: "Отключает микрофон Mac одним щелчком или сочетанием клавиш во всех приложениях.",
        mutedHUD: "Микрофон выключен",
        unmutedHUD: "Микрофон снова включён",
        menuBarToggle: "Показывать в строке меню, пока микрофон выключен",
        menuBarCaption: "Рядом со значком приложения в строке меню появляется красный перечёркнутый микрофон."
    )

    static let es = MicMuteFeatureStrings(
        pageTitle: "Silenciar micrófono",
        unmuteName: "Reactivar micrófono",
        caption: "Corta el micrófono del Mac con un clic o atajo, en cualquier app.",
        mutedHUD: "Micrófono silenciado",
        unmutedHUD: "Micrófono reactivado",
        menuBarToggle: "Mostrar en la barra de menús mientras está silenciado",
        menuBarCaption: "Un micrófono tachado en rojo aparece junto al icono de la app en la barra de menús."
    )

    static let de = MicMuteFeatureStrings(
        pageTitle: "Mikrofon stummschalten",
        unmuteName: "Mikrofon wieder aktivieren",
        caption: "Schaltet das Mikrofon des Mac per Klick oder Kurzbefehl stumm, in jeder App.",
        mutedHUD: "Mikrofon stumm",
        unmutedHUD: "Mikrofon wieder an",
        menuBarToggle: "In der Menüleiste anzeigen, solange stumm",
        menuBarCaption: "Ein rot durchgestrichenes Mikrofon erscheint neben dem Symbol der App in der Menüleiste."
    )

    static let fr = MicMuteFeatureStrings(
        pageTitle: "Couper le micro",
        unmuteName: "Réactiver le micro",
        caption: "Coupe le micro du Mac d’un clic ou d’un raccourci, dans toutes les apps.",
        mutedHUD: "Micro coupé",
        unmutedHUD: "Micro réactivé",
        menuBarToggle: "Afficher dans la barre des menus quand le micro est coupé",
        menuBarCaption: "Un micro barré en rouge apparaît à côté de l’icône de l’app dans la barre des menus."
    )

    static let it = MicMuteFeatureStrings(
        pageTitle: "Silenzia microfono",
        unmuteName: "Riattiva microfono",
        caption: "Taglia il microfono del Mac con un clic o un’abbreviazione, in qualsiasi app.",
        mutedHUD: "Microfono silenziato",
        unmutedHUD: "Microfono riattivato",
        menuBarToggle: "Mostra nella barra dei menu quando è silenziato",
        menuBarCaption: "Un microfono barrato in rosso appare accanto all’icona dell’app nella barra dei menu."
    )

    static let ja = MicMuteFeatureStrings(
        pageTitle: "マイクを消音",
        unmuteName: "マイクを再開",
        caption: "クリックまたはショートカットでMacのマイクをどのアプリでも消音します。",
        mutedHUD: "マイクを消音しました",
        unmutedHUD: "マイクを再開しました",
        menuBarToggle: "消音中はメニューバーに表示",
        menuBarCaption: "メニューバーのアプリアイコンの横に、赤い斜線入りのマイクが表示されます。"
    )

    static let ko = MicMuteFeatureStrings(
        pageTitle: "마이크 음소거",
        unmuteName: "마이크 음소거 해제",
        caption: "클릭 또는 단축키로 모든 앱에서 Mac의 마이크를 음소거합니다.",
        mutedHUD: "마이크를 음소거했습니다",
        unmutedHUD: "마이크 음소거를 해제했습니다",
        menuBarToggle: "음소거 중 메뉴 막대에 표시",
        menuBarCaption: "메뉴 막대의 앱 아이콘 옆에 빨간 줄이 그어진 마이크가 표시됩니다."
    )

    static let zhHans = MicMuteFeatureStrings(
        pageTitle: "静音麦克风",
        unmuteName: "取消静音麦克风",
        caption: "通过点按或快捷键切断 Mac 的麦克风，对所有 App 生效。",
        mutedHUD: "麦克风已静音",
        unmutedHUD: "麦克风已恢复",
        menuBarToggle: "静音时在菜单栏显示",
        menuBarCaption: "菜单栏中的 App 图标旁会出现一个红色的划线麦克风。"
    )

    static let zhTW = MicMuteFeatureStrings(
        pageTitle: "靜音麥克風",
        unmuteName: "取消靜音麥克風",
        caption: "透過點按或快速鍵切斷 Mac 的麥克風，對所有 App 生效。",
        mutedHUD: "麥克風已靜音",
        unmutedHUD: "麥克風已恢復",
        menuBarToggle: "靜音時在選單列顯示",
        menuBarCaption: "選單列中的 App 圖示旁會出現一個紅色的劃線麥克風。"
    )

    static let zhHK = MicMuteFeatureStrings(
        pageTitle: "靜音麥克風",
        unmuteName: "取消靜音麥克風",
        caption: "透過點按或快速鍵切斷 Mac 的麥克風，對所有 App 生效。",
        mutedHUD: "麥克風已靜音",
        unmutedHUD: "麥克風已恢復",
        menuBarToggle: "靜音時在選單列顯示",
        menuBarCaption: "選單列中的 App 圖示旁會出現一個紅色的劃線麥克風。"
    )
}
