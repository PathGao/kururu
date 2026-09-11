// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import Foundation

/// Localized strings for the media-key app launch blocker.
struct MusicBlockFeatureStrings {
    var pageTitle: String = "App launch blocker"
    var section: String = "Media keys"
    var title: String = "Block selected apps after media keys"
    var caption: String = "Only launches within two seconds of a media key are blocked. Manual launches in that window may also be blocked; other automatic launches and already-running apps are untouched."
    var listTitle: String = "Blocked apps"
    var listCaption: String = "Music is the default. Add or remove apps to choose which launches this feature checks."
    var removeApp: String = "Remove app"
    var replacementLabel: String = "Open instead"
    var replacementNone: String = "None"
    var chooseApp: String = "Choose app…"
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
    static let enUS = MusicBlockFeatureStrings()

    static let ptBR = MusicBlockFeatureStrings(
        section: "Teclas de mídia",
        replacementLabel: "Abrir no lugar",
        replacementNone: "Nenhum",
        chooseApp: "Escolher app…"
    )

    static let tr = MusicBlockFeatureStrings(
        section: "Medya tuşları",
        replacementLabel: "Yerine aç",
        replacementNone: "Hiçbiri",
        chooseApp: "Uygulama seç…"
    )

    static let ru = MusicBlockFeatureStrings(
        section: "Медиаклавиши",
        replacementLabel: "Открывать вместо",
        replacementNone: "Нет",
        chooseApp: "Выбрать приложение…"
    )

    static let es = MusicBlockFeatureStrings(
        pageTitle: "Bloqueo de inicio de apps",
        section: "Teclas multimedia",
        title: "Bloquear apps seleccionadas tras teclas multimedia",
        caption: "Solo se bloquean los inicios durante los dos segundos posteriores a una tecla multimedia, incluidos los manuales en ese intervalo. Los demás inicios automáticos y las apps ya abiertas no se ven afectados.",
        listTitle: "Apps bloqueadas",
        listCaption: "Solo Música por defecto. Añade o elimina apps para elegir qué inicios comprobar.",
        removeApp: "Eliminar app",
        replacementLabel: "Abrir en su lugar",
        replacementNone: "Ninguna",
        chooseApp: "Elegir app…"
    )

    static let de = MusicBlockFeatureStrings(
        pageTitle: "App-Startblocker",
        section: "Medientasten",
        title: "Ausgewählte Apps nach Medientasten blockieren",
        caption: "Nur Starts innerhalb von zwei Sekunden nach einer Medientaste werden blockiert, auch manuelle Starts in diesem Zeitraum. Andere automatische Starts und laufende Apps bleiben unberührt.",
        listTitle: "Blockierte Apps",
        listCaption: "Standardmäßig nur Musik. Füge Apps hinzu oder entferne sie, um ihre Starts prüfen zu lassen.",
        removeApp: "App entfernen",
        replacementLabel: "Stattdessen öffnen",
        replacementNone: "Keine",
        chooseApp: "App wählen…"
    )

    static let fr = MusicBlockFeatureStrings(
        pageTitle: "Blocage du lancement des apps",
        section: "Touches multimédias",
        title: "Bloquer les apps choisies après les touches multimédias",
        caption: "Seuls les lancements dans les deux secondes suivant une touche multimédia sont bloqués, y compris les lancements manuels dans ce délai. Les autres lancements automatiques et les apps déjà ouvertes restent inchangés.",
        listTitle: "Apps bloquées",
        listCaption: "Musique uniquement par défaut. Ajoutez ou retirez des apps pour choisir les lancements à vérifier.",
        removeApp: "Retirer l’app",
        replacementLabel: "Ouvrir à la place",
        replacementNone: "Aucune",
        chooseApp: "Choisir une app…"
    )

    static let it = MusicBlockFeatureStrings(
        section: "Tasti multimediali",
        replacementLabel: "Apri al suo posto",
        replacementNone: "Nessuna",
        chooseApp: "Scegli app…"
    )

    static let ja = MusicBlockFeatureStrings(
        pageTitle: "App 起動ブロック",
        section: "メディアキー",
        title: "メディアキー操作後に選択した App の起動をブロック",
        caption: "メディアキーを押してから2秒以内の起動のみをブロックします。その間の手動起動も対象です。その他の自動起動や実行中の App には影響しません。",
        listTitle: "ブロックする App",
        listCaption: "初期設定はミュージックのみです。App を追加・削除して対象を選択します。",
        removeApp: "App を削除",
        replacementLabel: "代わりに開く",
        replacementNone: "なし",
        chooseApp: "アプリを選択…"
    )

    static let ko = MusicBlockFeatureStrings(
        section: "미디어 키",
        replacementLabel: "대신 열기",
        replacementNone: "없음",
        chooseApp: "앱 선택…"
    )

    static let zhHans = MusicBlockFeatureStrings(
        pageTitle: "App 启动拦截",
        section: "媒体键",
        title: "拦截媒体键后启动的所选 App",
        caption: "仅拦截按下媒体键后两秒内的启动。这两秒内手动打开也可能被拦截；其它自动启动和已运行的 App 不受影响。",
        listTitle: "拦截名单",
        listCaption: "默认仅音乐 App。添加或移除 App，选择要检查的启动。",
        removeApp: "移除 App",
        replacementLabel: "改为打开",
        replacementNone: "无",
        chooseApp: "选择 App…"
    )

    static let zhTW = MusicBlockFeatureStrings(
        section: "媒體鍵",
        replacementLabel: "改為開啟",
        replacementNone: "無",
        chooseApp: "選擇 App…"
    )

    static let zhHK = MusicBlockFeatureStrings(
        section: "媒體鍵",
        replacementLabel: "改為開啟",
        replacementNone: "無",
        chooseApp: "選擇 App…"
    )
}
