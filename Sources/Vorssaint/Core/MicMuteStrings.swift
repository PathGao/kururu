// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import Foundation

/// Localized strings for the microphone mute toggle.
struct MicMuteFeatureStrings {
    var pageTitle: String = "Mute microphone"
    var unmuteName: String = "Unmute microphone"
    var caption: String = "Cuts the Mac’s microphone with a click or shortcut, across every app."
    var mutedHUD: String = "Microphone muted"
    var unmutedHUD: String = "Microphone state restored"
    var menuBarToggle: String = "Show in the menu bar while muted"
    var menuBarCaption: String = "The red crossed-out mic only reflects this feature’s mute, not mutes set in macOS or other apps."
    var applyingStatus = "Updating microphones…"
    var partialMuteFormat = "%d microphones muted; %d could not be muted."
    var partialUnmuteFormat = "%d microphones restored; %d could not be restored."
    var muteFailed = "Could not mute the microphones. They may still be capturing audio."
    var unmuteFailed = "Could not restore the microphones. Some may still be muted."
    var noDevices = "No input devices were found. Connect a microphone and try again."
    var retryMute = "Retry muting"
    var retryUnmute = "Retry restoring"
    var failedDevices = "Devices needing attention: "

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
        unmutedHUD: "Estado do microfone restaurado",
        menuBarToggle: "Mostrar na barra de menus enquanto silenciado",
        menuBarCaption: "O microfone cortado em vermelho só reflete o silenciamento deste recurso, não o do macOS nem de outros apps."
    )

    static let tr = MicMuteFeatureStrings(
        pageTitle: "Mikrofonu sessize al",
        unmuteName: "Mikrofonu aç",
        caption: "Mac’in mikrofonunu tek tıkla veya kısayolla keser; tüm uygulamalarda geçerlidir.",
        mutedHUD: "Mikrofon sessize alındı",
        unmutedHUD: "Mikrofon durumu geri yüklendi",
        menuBarToggle: "Sessizken menü çubuğunda göster",
        menuBarCaption: "Kırmızı üstü çizili mikrofon macOS veya başka uygulamalardaki sessize almayı değil, yalnızca bu özelliğinkini gösterir."
    )

    static let ru = MicMuteFeatureStrings(
        pageTitle: "Выключить микрофон",
        unmuteName: "Включить микрофон",
        caption: "Отключает микрофон Mac одним щелчком или сочетанием клавиш во всех приложениях.",
        mutedHUD: "Микрофон выключен",
        unmutedHUD: "Состояние микрофона восстановлено",
        menuBarToggle: "Показывать в строке меню, пока микрофон выключен",
        menuBarCaption: "Красный перечёркнутый микрофон показывает только отключение этой функцией, а не в macOS или других приложениях."
    )

    static let es = MicMuteFeatureStrings(
        pageTitle: "Silenciar micrófono",
        unmuteName: "Reactivar micrófono",
        caption: "Corta el micrófono del Mac con un clic o atajo, en cualquier app.",
        mutedHUD: "Micrófono silenciado",
        unmutedHUD: "Estado del micrófono restaurado",
        menuBarToggle: "Mostrar en la barra de menús mientras está silenciado",
        menuBarCaption: "El micrófono tachado en rojo solo refleja el silencio de esta función, no el de macOS ni el de otras apps."
    )

    static let de = MicMuteFeatureStrings(
        pageTitle: "Mikrofon stummschalten",
        unmuteName: "Mikrofon wieder aktivieren",
        caption: "Schaltet das Mikrofon des Mac per Klick oder Kurzbefehl stumm, in jeder App.",
        mutedHUD: "Mikrofon stumm",
        unmutedHUD: "Mikrofonzustand wiederhergestellt",
        menuBarToggle: "In der Menüleiste anzeigen, solange stumm",
        menuBarCaption: "Das rot durchgestrichene Mikrofon zeigt nur die Stummschaltung dieser Funktion, nicht die von macOS oder anderen Apps."
    )

    static let fr = MicMuteFeatureStrings(
        pageTitle: "Couper le micro",
        unmuteName: "Réactiver le micro",
        caption: "Coupe le micro du Mac d’un clic ou d’un raccourci, dans toutes les apps.",
        mutedHUD: "Micro coupé",
        unmutedHUD: "État du microphone restauré",
        menuBarToggle: "Afficher dans la barre des menus quand le micro est coupé",
        menuBarCaption: "Le micro barré en rouge ne reflète que la coupure faite par cette fonction, pas celle de macOS ou d’autres apps."
    )

    static let it = MicMuteFeatureStrings(
        pageTitle: "Silenzia microfono",
        unmuteName: "Riattiva microfono",
        caption: "Taglia il microfono del Mac con un clic o un’abbreviazione, in qualsiasi app.",
        mutedHUD: "Microfono silenziato",
        unmutedHUD: "Stato del microfono ripristinato",
        menuBarToggle: "Mostra nella barra dei menu quando è silenziato",
        menuBarCaption: "Il microfono barrato in rosso riflette solo il silenziamento di questa funzione, non quello di macOS o di altre app."
    )

    static let ja = MicMuteFeatureStrings(
        pageTitle: "マイクを消音",
        unmuteName: "マイクを再開",
        caption: "クリックまたはショートカットでMacのマイクをどのアプリでも消音します。",
        mutedHUD: "マイクを消音しました",
        unmutedHUD: "マイクの状態を復元しました",
        menuBarToggle: "消音中はメニューバーに表示",
        menuBarCaption: "赤い斜線入りのマイクはこの機能によるミュートだけを示し、macOS や他のアプリのミュートは表示しません。"
    )

    static let ko = MicMuteFeatureStrings(
        pageTitle: "마이크 음소거",
        unmuteName: "마이크 음소거 해제",
        caption: "클릭 또는 단축키로 모든 앱에서 Mac의 마이크를 음소거합니다.",
        mutedHUD: "마이크를 음소거했습니다",
        unmutedHUD: "마이크 상태를 복원했습니다",
        menuBarToggle: "음소거 중 메뉴 막대에 표시",
        menuBarCaption: "빨간 줄이 그어진 마이크는 이 기능으로 음소거한 경우에만 표시되며, macOS나 다른 앱의 음소거는 표시되지 않습니다."
    )

    static let zhHans = MicMuteFeatureStrings(
        pageTitle: "静音麦克风",
        unmuteName: "取消静音麦克风",
        caption: "通过点按或快捷键切断 Mac 的麦克风，对所有 App 生效。",
        mutedHUD: "麦克风已静音",
        unmutedHUD: "已恢复麦克风状态",
        menuBarToggle: "静音时在菜单栏显示",
        menuBarCaption: "红色划线麦克风只反映此功能的静音，系统或其他 App 的静音不会显示。",
        applyingStatus: "正在更新麦克风状态…",
        partialMuteFormat: "%d 个麦克风已静音，%d 个未能静音。",
        partialUnmuteFormat: "%d 个麦克风已恢复，%d 个未能恢复。",
        muteFailed: "未能静音麦克风，设备可能仍在采集声音。",
        unmuteFailed: "未能恢复麦克风，部分设备可能仍处于静音。",
        noDevices: "未发现输入设备，请连接麦克风后重试。",
        retryMute: "重试静音", retryUnmute: "重试恢复",
        failedDevices: "需要处理的设备："
    )

    static let zhTW = MicMuteFeatureStrings(
        pageTitle: "靜音麥克風",
        unmuteName: "取消靜音麥克風",
        caption: "透過點按或快速鍵切斷 Mac 的麥克風，對所有 App 生效。",
        mutedHUD: "麥克風已靜音",
        unmutedHUD: "已恢復麥克風狀態",
        menuBarToggle: "靜音時在選單列顯示",
        menuBarCaption: "紅色劃線麥克風只反映此功能的靜音，系統或其他 App 的靜音不會顯示。",
        applyingStatus: "正在更新麥克風狀態…",
        partialMuteFormat: "%d 個麥克風已靜音，%d 個未能靜音。",
        partialUnmuteFormat: "%d 個麥克風已恢復，%d 個未能恢復。",
        muteFailed: "未能靜音麥克風，裝置可能仍在擷取聲音。",
        unmuteFailed: "未能恢復麥克風，部分裝置可能仍處於靜音。",
        noDevices: "未發現輸入裝置，請連接麥克風後重試。",
        retryMute: "重試靜音", retryUnmute: "重試恢復",
        failedDevices: "需要處理的裝置："
    )

    static let zhHK = MicMuteFeatureStrings(
        pageTitle: "靜音麥克風",
        unmuteName: "取消靜音麥克風",
        caption: "透過點按或快速鍵切斷 Mac 的麥克風，對所有 App 生效。",
        mutedHUD: "麥克風已靜音",
        unmutedHUD: "已恢復麥克風狀態",
        menuBarToggle: "靜音時在選單列顯示",
        menuBarCaption: "紅色劃線麥克風只反映此功能的靜音，系統或其他 App 的靜音不會顯示。",
        applyingStatus: "正在更新麥克風狀態…",
        partialMuteFormat: "%d 個麥克風已靜音，%d 個未能靜音。",
        partialUnmuteFormat: "%d 個麥克風已恢復，%d 個未能恢復。",
        muteFailed: "未能靜音麥克風，裝置可能仍在擷取聲音。",
        unmuteFailed: "未能恢復麥克風，部分裝置可能仍處於靜音。",
        noDevices: "未發現輸入裝置，請連接麥克風後重試。",
        retryMute: "重試靜音", retryUnmute: "重試恢復",
        failedDevices: "需要處理的裝置："
    )
}

extension MicMuteFeatureStrings {
    func resultMessage(for result: MicMuteResult) -> String {
        switch result {
        case .muted: return mutedHUD
        case .unmuted: return unmutedHUD
        case let .partial(muting, succeeded, failed):
            return String(format: muting ? partialMuteFormat : partialUnmuteFormat, succeeded, failed)
        case let .failed(muting): return muting ? muteFailed : unmuteFailed
        case .noDevices: return noDevices
        }
    }

    func resultSymbol(for result: MicMuteResult) -> String {
        switch result {
        case .muted: return "mic.slash.fill"
        case .unmuted: return "mic.fill"
        case .partial, .failed, .noDevices: return "exclamationmark.triangle.fill"
        }
    }

    func retryTitle(muting: Bool) -> String { muting ? retryMute : retryUnmute }

    func actionTitle(isMuteRequested: Bool, result: MicMuteResult?) -> String {
        if !MicMuteBatchSupport.toggleTarget(isMuteRequested: isMuteRequested, lastResult: result) {
            return isMuteRequested ? unmuteName : retryUnmute
        }
        return pageTitle
    }
}
