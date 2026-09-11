// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

struct HomebrewDependencyStrings {
    let language: AppLanguage

    func action(package: String, count: Int, expanded: Bool) -> String {
        switch language {
        case .zhHans:
            return "\(expanded ? "收起" : "展开") \(package) 的 \(count) 个依赖"
        case .de:
            return "Abhängigkeiten von \(package) (\(count)) \(expanded ? "einklappen" : "ausklappen")"
        case .fr:
            return "\(expanded ? "Masquer" : "Afficher") les dépendances de \(package) (\(count))"
        case .es:
            return "\(expanded ? "Contraer" : "Expandir") las dependencias de \(package) (\(count))"
        case .ja:
            return "\(package) の依存関係 \(count) 件を\(expanded ? "折りたたむ" : "展開")"
        default:
            return "\(expanded ? "Collapse" : "Expand") dependencies of \(package) (\(count))"
        }
    }

    func state(expanded: Bool) -> String {
        switch language {
        case .zhHans: return expanded ? "已展开" : "已收起"
        case .de: return expanded ? "Ausgeklappt" : "Eingeklappt"
        case .fr: return expanded ? "Déplié" : "Replié"
        case .es: return expanded ? "Expandido" : "Contraído"
        case .ja: return expanded ? "展開済み" : "折りたたみ済み"
        default: return expanded ? "Expanded" : "Collapsed"
        }
    }
}
