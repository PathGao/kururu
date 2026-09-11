// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

struct SettingsHierarchyStrings {
    var pageTitle = "General & appearance"
    var general = "General"
    var maintenance = "Data & maintenance"
    var mixerScope = "This filters the panel’s app list without changing volume. All apps includes apps with an audio connection, even while silent; Playing includes those with active audio output. Adjust live volume and devices in the panel."

    init(language: AppLanguage) {
        let labels = FeatureStrings.mixer(language)
        switch language {
        case .zhHans:
            pageTitle = "通用与外观"
            general = "通用"
            maintenance = "数据与维护"
            mixerScope = "此选项只筛选面板中的应用列表，不改变音量。“\(labels.allApps)”包含保持音频连接的应用，即使当前没有声音；“\(labels.playingApps)”仅显示正在输出音频的应用。实时音量与设备在面板中调整。"
        case .de:
            pageTitle = "Allgemein & Darstellung"
            general = "Allgemein"
            maintenance = "Daten & Wartung"
            mixerScope = "Dieser Filter ändert nur die App-Liste im Panel, nicht die Lautstärke. „\(labels.allApps)“ umfasst Apps mit Audioverbindung, auch wenn sie gerade stumm sind; „\(labels.playingApps)“ nur Apps mit aktiver Audioausgabe. Lautstärke und Geräte lassen sich im Panel einstellen."
        case .fr:
            pageTitle = "Général et apparence"
            general = "Général"
            maintenance = "Données et maintenance"
            mixerScope = "Ce filtre modifie la liste des apps du panneau sans changer le volume. « \(labels.allApps) » inclut les apps connectées à l’audio, même silencieuses ; « \(labels.playingApps) » celles dont la sortie audio est active. Réglez le volume et les appareils dans le panneau."
        case .es:
            pageTitle = "General y apariencia"
            general = "General"
            maintenance = "Datos y mantenimiento"
            mixerScope = "Este filtro cambia la lista de apps del panel sin modificar el volumen. «\(labels.allApps)» incluye las apps con conexión de audio, aunque estén en silencio; «\(labels.playingApps)» solo las que tienen una salida de audio activa. Ajusta el volumen y los dispositivos en el panel."
        case .ja:
            pageTitle = "一般と外観"
            general = "一般"
            maintenance = "データとメンテナンス"
            mixerScope = "この設定はパネルのアプリ一覧だけを絞り込み、音量は変更しません。「\(labels.allApps)」は無音でもオーディオ接続を持つアプリを含み、「\(labels.playingApps)」は音声を出力しているアプリだけを表示します。音量とデバイスはパネルで調整できます。"
        default:
            break
        }
    }
}
