// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import Foundation

/// Localized strings for the Music launch blocker.
struct MusicBlockFeatureStrings {
    let pageTitle: String
    let section: String
    let title: String
    let caption: String
    let replacementLabel: String
    let replacementNone: String
    let chooseApp: String
}

extension FeatureStrings {
    static func musicBlock(_ language: AppLanguage) -> MusicBlockFeatureStrings {
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

extension MusicBlockFeatureStrings {
    static let enUS = MusicBlockFeatureStrings(
        pageTitle: "Music app blocker",
        section: "Media keys",
        title: "Stop Music from opening on its own",
        caption: "The Music app no longer opens when you press the media keys. You can still open it yourself.",
        replacementLabel: "Open instead",
        replacementNone: "None",
        chooseApp: "Choose app…"
    )

    static let ptBR = MusicBlockFeatureStrings(
        pageTitle: "Bloqueio do app Música",
        section: "Teclas de mídia",
        title: "Impedir que o Música abra sozinho",
        caption: "O app Música deixa de abrir ao tocar nas teclas de mídia. Você ainda pode abri-lo quando quiser.",
        replacementLabel: "Abrir no lugar",
        replacementNone: "Nenhum",
        chooseApp: "Escolher app…"
    )

    static let tr = MusicBlockFeatureStrings(
        pageTitle: "Müzik engelleyici",
        section: "Medya tuşları",
        title: "Müzik uygulamasının kendiliğinden açılmasını engelle",
        caption: "Medya tuşlarına basınca Müzik uygulaması artık açılmaz. Yine de kendin açabilirsin.",
        replacementLabel: "Yerine aç",
        replacementNone: "Hiçbiri",
        chooseApp: "Uygulama seç…"
    )

    static let ru = MusicBlockFeatureStrings(
        pageTitle: "Блокировка приложения Музыка",
        section: "Медиаклавиши",
        title: "Не давать Музыке открываться самой",
        caption: "Приложение Музыка больше не открывается при нажатии медиаклавиш. Его по-прежнему можно открыть самому.",
        replacementLabel: "Открывать вместо",
        replacementNone: "Нет",
        chooseApp: "Выбрать приложение…"
    )

    static let es = MusicBlockFeatureStrings(
        pageTitle: "Bloqueo de la app Música",
        section: "Teclas multimedia",
        title: "Evitar que Música se abra sola",
        caption: "La app Música deja de abrirse al pulsar las teclas multimedia. Sigue pudiendo abrirla tú.",
        replacementLabel: "Abrir en su lugar",
        replacementNone: "Ninguna",
        chooseApp: "Elegir app…"
    )

    static let de = MusicBlockFeatureStrings(
        pageTitle: "Musik-App-Blocker",
        section: "Medientasten",
        title: "Musik nicht von selbst öffnen lassen",
        caption: "Die Musik-App öffnet sich beim Drücken der Medientasten nicht mehr. Du kannst sie weiterhin selbst öffnen.",
        replacementLabel: "Stattdessen öffnen",
        replacementNone: "Keine",
        chooseApp: "App wählen…"
    )

    static let fr = MusicBlockFeatureStrings(
        pageTitle: "Blocage de l’app Musique",
        section: "Touches multimédias",
        title: "Empêcher Musique de s’ouvrir toute seule",
        caption: "L’app Musique ne s’ouvre plus quand vous appuyez sur les touches multimédias. Vous pouvez toujours l’ouvrir vous-même.",
        replacementLabel: "Ouvrir à la place",
        replacementNone: "Aucune",
        chooseApp: "Choisir une app…"
    )

    static let it = MusicBlockFeatureStrings(
        pageTitle: "Blocco dell’app Musica",
        section: "Tasti multimediali",
        title: "Impedisci a Musica di aprirsi da sola",
        caption: "L’app Musica non si apre più premendo i tasti multimediali. Puoi comunque aprirla tu.",
        replacementLabel: "Apri al suo posto",
        replacementNone: "Nessuna",
        chooseApp: "Scegli app…"
    )

    static let ja = MusicBlockFeatureStrings(
        pageTitle: "ミュージック起動ブロック",
        section: "メディアキー",
        title: "ミュージックが勝手に開かないようにする",
        caption: "メディアキーを押してもミュージックアプリは開かなくなります。自分で開くことはできます。",
        replacementLabel: "代わりに開く",
        replacementNone: "なし",
        chooseApp: "アプリを選択…"
    )

    static let ko = MusicBlockFeatureStrings(
        pageTitle: "음악 앱 차단기",
        section: "미디어 키",
        title: "음악 앱이 저절로 열리지 않게 하기",
        caption: "미디어 키를 눌러도 음악 앱이 열리지 않습니다. 직접 여는 것은 가능합니다.",
        replacementLabel: "대신 열기",
        replacementNone: "없음",
        chooseApp: "앱 선택…"
    )

    static let zhHans = MusicBlockFeatureStrings(
        pageTitle: "「音乐」App 拦截",
        section: "媒体键",
        title: "阻止音乐 App 自行打开",
        caption: "按下媒体键时音乐 App 不再打开。你仍可以自己打开它。",
        replacementLabel: "改为打开",
        replacementNone: "无",
        chooseApp: "选择 App…"
    )

    static let zhTW = MusicBlockFeatureStrings(
        pageTitle: "音樂 App 攔截",
        section: "媒體鍵",
        title: "阻止音樂 App 自行開啟",
        caption: "按媒體鍵時音樂 App 不再開啟。你仍可以自己打開它。",
        replacementLabel: "改為開啟",
        replacementNone: "無",
        chooseApp: "選擇 App…"
    )

    static let zhHK = MusicBlockFeatureStrings(
        pageTitle: "音樂 App 攔截",
        section: "媒體鍵",
        title: "阻止音樂 App 自行開啟",
        caption: "按媒體鍵時音樂 App 不再開啟。你仍可以自己打開它。",
        replacementLabel: "改為開啟",
        replacementNone: "無",
        chooseApp: "選擇 App…"
    )
}
