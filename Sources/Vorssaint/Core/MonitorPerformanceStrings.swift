// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

struct MonitorPerformanceStrings {
    let title: String
    let nominal: String
    let fair: String
    let serious: String
    let critical: String
    let lowPower: String
    let hint: String


    static func text(_ language: AppLanguage) -> Self {
        switch language {
        case .enUS:
            return Self(title: "System thermal state",
                        nominal: "Normal",
                        fair: "Elevated",
                        serious: "High thermal pressure",
                        critical: "Critical thermal pressure",
                        lowPower: "Low Power Mode",
                        hint: "Reported by macOS. This state does not quantify performance loss.")
        case .ptBR:
            return Self(title: "Estado térmico do sistema",
                        nominal: "Normal",
                        fair: "Elevado",
                        serious: "Pressão térmica alta",
                        critical: "Pressão térmica crítica",
                        lowPower: "Modo de Pouca Energia",
                        hint: "Informado pelo macOS. Este estado não quantifica a perda de desempenho.")
        case .tr:
            return Self(title: "Sistem termal durumu",
                        nominal: "Normal",
                        fair: "Yükselmiş",
                        serious: "Yüksek termal baskı",
                        critical: "Kritik termal baskı",
                        lowPower: "Düşük Güç Modu",
                        hint: "macOS tarafından bildirilir. Bu durum performans kaybını ölçmez.")
        case .ru:
            return Self(title: "Тепловое состояние системы",
                        nominal: "Нормальное",
                        fair: "Повышенное",
                        serious: "Высокая тепловая нагрузка",
                        critical: "Критическая тепловая нагрузка",
                        lowPower: "Режим энергосбережения",
                        hint: "Данные macOS. Состояние не показывает величину потери производительности.")
        case .es:
            return Self(title: "Estado térmico del sistema",
                        nominal: "Normal",
                        fair: "Elevado",
                        serious: "Presión térmica alta",
                        critical: "Presión térmica crítica",
                        lowPower: "Modo de bajo consumo",
                        hint: "Información de macOS. Este estado no cuantifica la pérdida de rendimiento.")
        case .de:
            return Self(title: "Thermischer Systemzustand",
                        nominal: "Normal",
                        fair: "Erhöht",
                        serious: "Hohe thermische Belastung",
                        critical: "Kritische thermische Belastung",
                        lowPower: "Stromsparmodus",
                        hint: "Von macOS gemeldet. Dieser Zustand beziffert keinen Leistungsverlust.")
        case .fr:
            return Self(title: "État thermique du système",
                        nominal: "Normal",
                        fair: "Élevé",
                        serious: "Forte pression thermique",
                        critical: "Pression thermique critique",
                        lowPower: "Mode économie d’énergie",
                        hint: "Indiqué par macOS. Cet état ne quantifie pas la perte de performances.")
        case .it:
            return Self(title: "Stato termico del sistema",
                        nominal: "Normale",
                        fair: "Elevato",
                        serious: "Pressione termica alta",
                        critical: "Pressione termica critica",
                        lowPower: "Risparmio energetico",
                        hint: "Segnalato da macOS. Questo stato non quantifica la perdita di prestazioni.")
        case .ja:
            return Self(title: "システムの熱状態",
                        nominal: "正常",
                        fair: "上昇",
                        serious: "高い熱負荷",
                        critical: "危険な熱負荷",
                        lowPower: "低電力モード",
                        hint: "macOS が報告する状態です。性能の低下率を示すものではありません。")
        case .ko:
            return Self(title: "시스템 열 상태",
                        nominal: "정상",
                        fair: "상승",
                        serious: "높은 열 부하",
                        critical: "심각한 열 부하",
                        lowPower: "저전력 모드",
                        hint: "macOS가 보고한 상태입니다. 성능 저하 비율을 나타내지는 않습니다.")
        case .zhHans:
            return Self(title: "系统热状态",
                        nominal: "正常",
                        fair: "热压力升高",
                        serious: "严重热压力",
                        critical: "危急热压力",
                        lowPower: "低电量模式",
                        hint: "由 macOS 报告的系统热状态，不代表精确的性能下降比例。")
        case .zhTW:
            return Self(title: "系統熱狀態",
                        nominal: "正常",
                        fair: "熱壓力升高",
                        serious: "嚴重熱壓力",
                        critical: "危急熱壓力",
                        lowPower: "低耗電模式",
                        hint: "由 macOS 回報的系統熱狀態，不代表精確的效能下降比例。")
        case .zhHK:
            return Self(title: "系統熱狀態",
                        nominal: "正常",
                        fair: "熱壓力升高",
                        serious: "嚴重熱壓力",
                        critical: "危急熱壓力",
                        lowPower: "低耗電模式",
                        hint: "由 macOS 回報的系統熱狀態，不代表精確的效能下降比例。")
        }
    }
}
