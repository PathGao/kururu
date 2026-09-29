// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

struct BrightnessShortcutStrings {
    var title = "Display brightness shortcuts"
    var caption = "Shortcuts adjust the primary display, or the display under the pointer when pointer following is on."
    var toggle = "Use display brightness shortcuts"
    var decrease = "Decrease display brightness"
    var increase = "Increase display brightness"
    var notSet = "Not set"

    static func localized(_ language: AppLanguage) -> BrightnessShortcutStrings {
        switch language {
        case .zhHans: return BrightnessShortcutStrings(
            title: "显示器亮度快捷键",
            caption: "快捷键调整主显示器；开启跟随指针后，则调整指针所在的显示器。",
            toggle: "使用显示器亮度快捷键",
            decrease: "降低显示器亮度",
            increase: "提高显示器亮度",
            notSet: "未设置")
        case .de: return BrightnessShortcutStrings(
            title: "Kurzbefehle für die Displayhelligkeit",
            caption: "Kurzbefehle steuern den Hauptbildschirm oder bei aktivierter Zeigerverfolgung den Bildschirm unter dem Zeiger.",
            toggle: "Kurzbefehle für Displayhelligkeit verwenden",
            decrease: "Bildschirmhelligkeit verringern",
            increase: "Bildschirmhelligkeit erhöhen",
            notSet: "Nicht festgelegt")
        case .fr: return BrightnessShortcutStrings(
            title: "Raccourcis de luminosité de l’écran",
            caption: "Les raccourcis règlent l’écran principal ou celui sous le pointeur lorsque le suivi du pointeur est activé.",
            toggle: "Utiliser les raccourcis de luminosité",
            decrease: "Réduire la luminosité de l’écran",
            increase: "Augmenter la luminosité de l’écran",
            notSet: "Non défini")
        case .es: return BrightnessShortcutStrings(
            title: "Atajos de brillo de pantalla",
            caption: "Los atajos ajustan la pantalla principal o la pantalla bajo el puntero cuando está activado el seguimiento del puntero.",
            toggle: "Usar atajos de brillo de pantalla",
            decrease: "Reducir el brillo de la pantalla",
            increase: "Aumentar el brillo de la pantalla",
            notSet: "Sin configurar")
        case .ja: return BrightnessShortcutStrings(
            title: "ディスプレイ輝度のショートカット",
            caption: "ショートカットでメインディスプレイを調整します。ポインタ追従がオンの場合は、ポインタのあるディスプレイを調整します。",
            toggle: "ディスプレイ輝度ショートカットを使用",
            decrease: "ディスプレイの明るさを下げる",
            increase: "ディスプレイの明るさを上げる",
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
