// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

struct HomebrewHierarchyStrings {
    let language: AppLanguage

    var rereadInstalled: String {
        switch language {
        case .zhHans: return "重新读取已安装列表"
        case .de: return "Installierte Liste neu einlesen"
        case .fr: return "Relire la liste des logiciels installés"
        case .es: return "Volver a leer la lista de instalados"
        case .ja: return "インストール済みリストを再読み込み"
        default: return "Reread installed list"
        }
    }

    var updateDefinitions: String {
        switch language {
        case .zhHans: return "更新 Homebrew 与配方定义"
        case .de: return "Homebrew und Formeldefinitionen aktualisieren"
        case .fr: return "Actualiser Homebrew et les définitions de formules"
        case .es: return "Actualizar Homebrew y las definiciones de fórmulas"
        case .ja: return "Homebrew と formula 定義を更新"
        default: return "Update Homebrew and formula definitions"
        }
    }

    var updateDefinitionsConfirmation: String {
        switch language {
        case .zhHans: return "这会运行 brew update，更新 Homebrew 与配方定义，然后重新读取已安装列表。不会升级已安装的软件包。"
        case .de: return "Führt brew update aus, aktualisiert Homebrew und Formeldefinitionen und liest dann die installierte Liste neu ein. Installierte Pakete werden nicht aktualisiert."
        case .fr: return "Exécute brew update, actualise Homebrew et les définitions de formules, puis relit la liste installée. Les logiciels installés ne sont pas mis à niveau."
        case .es: return "Ejecuta brew update, actualiza Homebrew y las definiciones de fórmulas y después vuelve a leer la lista instalada. No actualiza los paquetes instalados."
        case .ja: return "brew update を実行して Homebrew と formula 定義を更新し、インストール済みリストを再読み込みします。インストール済みパッケージは更新しません。"
        default: return "Runs brew update to update Homebrew and formula definitions, then rereads the installed list. It does not upgrade installed packages."
        }
    }

    var currentVersion: String {
        switch language {
        case .zhHans: return "当前版本"
        case .de: return "Aktuelle Version"
        case .fr: return "Version actuelle"
        case .es: return "Versión actual"
        case .ja: return "現在のバージョン"
        default: return "Current version"
        }
    }

    var targetVersion: String {
        switch language {
        case .zhHans: return "目标版本"
        case .de: return "Zielversion"
        case .fr: return "Version cible"
        case .es: return "Versión de destino"
        case .ja: return "更新先のバージョン"
        default: return "Target version"
        }
    }

    var upgradePackage: String {
        switch language {
        case .zhHans: return "升级此软件包"
        case .de: return "Dieses Paket aktualisieren"
        case .fr: return "Mettre à niveau ce logiciel"
        case .es: return "Actualizar este paquete"
        case .ja: return "このパッケージを更新"
        default: return "Upgrade this package"
        }
    }
}
