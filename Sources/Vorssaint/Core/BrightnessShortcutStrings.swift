// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

struct BrightnessShortcutStrings {
    var title = "Display brightness shortcuts"
    var caption = "Decrease or increase the external display under the pointer by one step. A shortcut never falls back to another display, and it does nothing when the target’s current brightness cannot be determined."
    var toggle = "Use display brightness shortcuts"
    var decrease = "Dim display under pointer"
    var increase = "Brighten display under pointer"
    var notSet = "Not set"

    static func localized(_ language: AppLanguage) -> BrightnessShortcutStrings {
        switch language {
        case .zhHans: return BrightnessShortcutStrings(
            title: "显示器亮度快捷键",
            caption: "将指针所在的外接显示器调暗或调亮一步。快捷键不会改调其它显示器；无法确定当前亮度时不会执行。",
            toggle: "使用显示器亮度快捷键",
            decrease: "调暗指针所在显示器",
            increase: "调亮指针所在显示器",
            notSet: "未设置")
        case .de: return BrightnessShortcutStrings(
            title: "Kurzbefehle für die Displayhelligkeit",
            caption: "Verringert oder erhöht die Helligkeit des externen Displays unter dem Zeiger um eine Stufe. Es wird nie auf ein anderes Display ausgewichen; wenn die aktuelle Helligkeit nicht ermittelt werden kann, geschieht nichts.",
            toggle: "Kurzbefehle für Displayhelligkeit verwenden",
            decrease: "Display unter dem Zeiger abdunkeln",
            increase: "Display unter dem Zeiger aufhellen",
            notSet: "Nicht festgelegt")
        case .fr: return BrightnessShortcutStrings(
            title: "Raccourcis de luminosité de l’écran",
            caption: "Diminue ou augmente d’un cran l’écran externe sous le pointeur. Le raccourci ne cible jamais un autre écran et ne fait rien si la luminosité actuelle ne peut pas être déterminée.",
            toggle: "Utiliser les raccourcis de luminosité",
            decrease: "Assombrir l’écran sous le pointeur",
            increase: "Éclaircir l’écran sous le pointeur",
            notSet: "Non défini")
        case .es: return BrightnessShortcutStrings(
            title: "Atajos de brillo de pantalla",
            caption: "Reduce o aumenta un paso el brillo de la pantalla externa bajo el puntero. Nunca usa otra pantalla y no actúa si no se puede determinar el brillo actual.",
            toggle: "Usar atajos de brillo de pantalla",
            decrease: "Oscurecer pantalla bajo el puntero",
            increase: "Aclarar pantalla bajo el puntero",
            notSet: "Sin configurar")
        case .ja: return BrightnessShortcutStrings(
            title: "ディスプレイ輝度のショートカット",
            caption: "ポインタがある外部ディスプレイを1段階暗く、または明るくします。別のディスプレイには切り替えず、現在の明るさを確認できない場合は何もしません。",
            toggle: "ディスプレイ輝度ショートカットを使用",
            decrease: "ポインタ位置のディスプレイを暗くする",
            increase: "ポインタ位置のディスプレイを明るくする",
            notSet: "未設定")
        default: return BrightnessShortcutStrings()
        }
    }
}

enum BrightnessShortcutPreferenceKey {
    static let enabled = "displayBrightnessShortcutsEnabled"
    static let decrease = "displayBrightnessDecreaseShortcut"
    static let increase = "displayBrightnessIncreaseShortcut"
}
