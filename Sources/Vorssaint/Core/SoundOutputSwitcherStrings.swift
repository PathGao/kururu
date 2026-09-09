// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import Foundation

/// Localized strings for the sound output switcher.
struct SoundOutputSwitcherFeatureStrings {
    var pageTitle: String = "Output switcher"
    var enable: String = "Switch outputs with shortcut"
    var caption: String = "Choose outputs and use the shortcut to move to the next available one."
    var devices: String = "Outputs in cycle"
    var noAvailableSelection: String = "Select at least one available output."
}

extension FeatureStrings {
    static func soundOutputSwitcher(_ language: AppLanguage) -> SoundOutputSwitcherFeatureStrings {
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

extension SoundOutputSwitcherFeatureStrings {
    static let enUS = SoundOutputSwitcherFeatureStrings()

    static let ptBR = SoundOutputSwitcherFeatureStrings(
        pageTitle: "Alternador de saída",
        enable: "Alternar saídas por atalho",
        caption: "Escolha as saídas e use o atalho para passar para a próxima disponível.",
        devices: "Saídas no ciclo",
        noAvailableSelection: "Selecione pelo menos uma saída disponível."
    )

    static let tr = SoundOutputSwitcherFeatureStrings(
        pageTitle: "Çıkış değiştirici",
        enable: "Çıkışları kısayolla değiştir",
        caption: "Çıkışları seç ve kısayolla bir sonraki kullanılabilir çıkışa geç.",
        devices: "Döngüdeki çıkışlar",
        noAvailableSelection: "En az bir kullanılabilir çıkış seç."
    )

    static let ru = SoundOutputSwitcherFeatureStrings(
        pageTitle: "Переключатель выхода",
        enable: "Переключать выходы горячей клавишей",
        caption: "Выберите выходы и используйте сочетание клавиш, чтобы перейти к следующему доступному.",
        devices: "Выходы в цикле",
        noAvailableSelection: "Выберите хотя бы один доступный выход."
    )

    static let es = SoundOutputSwitcherFeatureStrings(
        pageTitle: "Selector de salida",
        enable: "Cambiar salidas con atajo",
        caption: "Elige salidas y usa el atajo para pasar a la siguiente disponible.",
        devices: "Salidas en el ciclo",
        noAvailableSelection: "Selecciona al menos una salida disponible."
    )

    static let de = SoundOutputSwitcherFeatureStrings(
        pageTitle: "Ausgabeumschalter",
        enable: "Ausgaben per Kurzbefehl wechseln",
        caption: "Wähle Ausgaben und nutze den Kurzbefehl für die nächste verfügbare.",
        devices: "Ausgaben im Wechsel",
        noAvailableSelection: "Wähle mindestens eine verfügbare Ausgabe."
    )

    static let fr = SoundOutputSwitcherFeatureStrings(
        pageTitle: "Sélecteur de sortie",
        enable: "Changer de sortie avec un raccourci",
        caption: "Choisissez les sorties et utilisez le raccourci pour passer à la suivante disponible.",
        devices: "Sorties du cycle",
        noAvailableSelection: "Sélectionnez au moins une sortie disponible."
    )

    static let it = SoundOutputSwitcherFeatureStrings(
        pageTitle: "Selettore uscita",
        enable: "Cambia uscite con scorciatoia",
        caption: "Scegli le uscite e usa la scorciatoia per passare alla prossima disponibile.",
        devices: "Uscite nel ciclo",
        noAvailableSelection: "Seleziona almeno un’uscita disponibile."
    )

    static let ja = SoundOutputSwitcherFeatureStrings(
        pageTitle: "出力切り替え",
        enable: "ショートカットで出力を切り替える",
        caption: "出力を選び、ショートカットで次に利用可能な出力へ切り替えます。",
        devices: "切り替える出力",
        noAvailableSelection: "利用可能な出力を1つ以上選択してください。"
    )

    static let ko = SoundOutputSwitcherFeatureStrings(
        pageTitle: "출력 전환",
        enable: "단축키로 출력 전환",
        caption: "출력을 선택하고 단축키로 다음 사용 가능한 출력으로 전환합니다.",
        devices: "전환할 출력",
        noAvailableSelection: "사용 가능한 출력을 하나 이상 선택하세요."
    )

    static let zhHans = SoundOutputSwitcherFeatureStrings(
        pageTitle: "输出切换器",
        enable: "用快捷键切换输出",
        caption: "选择输出设备，然后用快捷键切到下一个可用输出。",
        devices: "循环中的输出",
        noAvailableSelection: "请至少选择一个可用输出。"
    )

    static let zhTW = SoundOutputSwitcherFeatureStrings(
        pageTitle: "輸出切換器",
        enable: "使用快速鍵切換輸出",
        caption: "選擇輸出裝置，然後用快速鍵切換到下一個可用輸出。",
        devices: "循環中的輸出",
        noAvailableSelection: "請至少選擇一個可用輸出。"
    )

    static let zhHK = SoundOutputSwitcherFeatureStrings(
        pageTitle: "輸出切換器",
        enable: "用快捷鍵切換輸出",
        caption: "選取輸出裝置，然後用快捷鍵切到下一個可用輸出。",
        devices: "循環中的輸出",
        noAvailableSelection: "請至少選取一個可用輸出。"
    )
}
