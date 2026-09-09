// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

struct CPUCoreStrings {
    let title: String
    let coreFormat: String
    let hint: String

    static func groupName(_ name: String, language: AppLanguage) -> String {
        let labels: [String]
        switch language {
        case .enUS: labels = ["Super", "Performance", "Efficiency"]
        case .ptBR: labels = ["Super", "Desempenho", "Eficiência"]
        case .tr: labels = ["Süper", "Performans", "Verimlilik"]
        case .ru: labels = ["Супер", "Производительность", "Эффективность"]
        case .es: labels = ["Súper", "Rendimiento", "Eficiencia"]
        case .de: labels = ["Super", "Leistung", "Effizienz"]
        case .fr: labels = ["Super", "Performance", "Efficacité"]
        case .it: labels = ["Super", "Prestazioni", "Efficienza"]
        case .ja: labels = ["スーパー", "高性能", "高効率"]
        case .ko: labels = ["슈퍼", "성능", "효율"]
        case .zhHans: labels = ["超级核心", "性能核心", "能效核心"]
        case .zhTW, .zhHK: labels = ["超級核心", "效能核心", "節能核心"]
        }
        guard let index = ["super", "performance", "efficiency"].firstIndex(of: name.lowercased()) else { return name }
        return labels[index]
    }

    static func text(_ language: AppLanguage) -> Self {
        switch language {
        case .enUS:
            return Self(title: "Logical CPU cores", coreFormat: "Core %d",
                        hint: "Each bar is one logical core. Its fill height shows utilization, not remaining performance.")
        case .ptBR:
            return Self(title: "Núcleos lógicos da CPU", coreFormat: "Núcleo %d",
                        hint: "Cada barra representa um núcleo lógico. A altura preenchida mostra a utilização.")
        case .tr:
            return Self(title: "Mantıksal CPU çekirdekleri", coreFormat: "Çekirdek %d",
                        hint: "Her çubuk bir mantıksal çekirdektir. Dolgu yüksekliği kullanımı gösterir.")
        case .ru:
            return Self(title: "Логические ядра CPU", coreFormat: "Ядро %d",
                        hint: "Каждая полоса — логическое ядро. Высота заполнения показывает загрузку.")
        case .es:
            return Self(title: "Núcleos lógicos de CPU", coreFormat: "Núcleo %d",
                        hint: "Cada barra es un núcleo lógico. La altura del relleno indica su uso.")
        case .de:
            return Self(title: "Logische CPU-Kerne", coreFormat: "Kern %d",
                        hint: "Jeder Balken ist ein logischer Kern. Die Füllhöhe zeigt die Auslastung.")
        case .fr:
            return Self(title: "Cœurs logiques du CPU", coreFormat: "Cœur %d",
                        hint: "Chaque barre représente un cœur logique. La hauteur du remplissage indique son utilisation.")
        case .it:
            return Self(title: "Core logici CPU", coreFormat: "Core %d",
                        hint: "Ogni barra rappresenta un core logico. L’altezza del riempimento indica l’utilizzo.")
        case .ja:
            return Self(title: "CPU 論理コア", coreFormat: "コア %d",
                        hint: "各バーは論理コアです。塗りつぶしの高さは使用率を表します。")
        case .ko:
            return Self(title: "CPU 논리 코어", coreFormat: "코어 %d",
                        hint: "막대 하나가 논리 코어 하나입니다. 채움 높이가 사용률을 나타냅니다.")
        case .zhHans:
            return Self(title: "CPU 逻辑核心", coreFormat: "核心 %d",
                        hint: "每条代表一个逻辑核心，填充高度表示占用率，不表示剩余性能。")
        case .zhTW:
            return Self(title: "CPU 邏輯核心", coreFormat: "核心 %d",
                        hint: "每條代表一個邏輯核心，填充高度表示使用率，不表示剩餘效能。")
        case .zhHK:
            return Self(title: "CPU 邏輯核心", coreFormat: "核心 %d",
                        hint: "每條代表一個邏輯核心，填充高度表示使用率，不表示剩餘效能。")
        }
    }
}
