// SPDX-License-Identifier: GPL-3.0-or-later

struct EnvironmentUpdateStrings {
    let language: AppLanguage

    private func text(_ en: String, _ zh: String, _ de: String, _ fr: String, _ es: String, _ ja: String) -> String {
        switch language {
        case .zhHans: return zh
        case .de: return de
        case .fr: return fr
        case .es: return es
        case .ja: return ja
        default: return en
        }
    }

    var check: String {
        text("Check for updates", "检查更新", "Nach Updates suchen", "Rechercher des mises à jour", "Buscar actualizaciones", "更新を確認")
    }
    var checking: String {
        text("Checking…", "正在检查…", "Wird geprüft…", "Vérification…", "Comprobando…", "確認中…")
    }
    var note: String {
        text("Update checks cover standalone Bun and uv on GitHub and explicitly installed Homebrew tools. Bundled tools, dependencies and pinned versions receive no upgrade prompts. Project compatibility is not checked.",
             "只检查独立安装的 Bun、uv 和主动安装的 Homebrew 工具。系统附带、依赖包和固定版本不提醒升级。不检查项目兼容性。",
             "Prüft eigenständig installiertes Bun und uv auf GitHub sowie ausdrücklich installierte Homebrew-Tools. Mitgelieferte Tools, Abhängigkeiten und fixierte Versionen erhalten keine Updatehinweise. Projektkompatibilität wird nicht geprüft.",
             "Vérifie Bun et uv autonomes sur GitHub et les outils Homebrew installés explicitement. Aucun rappel pour les outils fournis, les dépendances et les versions épinglées. La compatibilité des projets n’est pas vérifiée.",
             "Comprueba Bun y uv independientes en GitHub y herramientas Homebrew instaladas explícitamente. No avisa para herramientas incluidas, dependencias ni versiones fijadas. No comprueba la compatibilidad de los proyectos.",
             "単独でインストールした Bun・uv の GitHub リリースと、明示的にインストールした Homebrew ツールを確認します。付属ツール・依存関係・固定バージョンの更新は案内しません。プロジェクトの互換性は確認しません。")
    }
    var instructions: String {
        text("Upgrade instructions", "升级说明", "Update-Anleitung", "Instructions de mise à jour", "Instrucciones de actualización", "更新手順")
    }
    var packages: String {
        text("View in Packages", "在软件包页查看", "In Pakete ansehen", "Voir dans Paquets", "Ver en Paquetes", "パッケージで表示")
    }
    var checked: String {
        text("Checked", "检查时间", "Geprüft", "Vérifié", "Comprobado", "確認日時")
    }
    var pinned: String {
        text("Version pinned in Homebrew. Review the pin in Homebrew before upgrading.", "Homebrew 已固定版本。升级前请在 Homebrew 中检查固定设置。",
             "Version in Homebrew fixiert. Vor dem Update die Fixierung in Homebrew prüfen.", "Version épinglée dans Homebrew. Vérifiez cet épinglage avant toute mise à jour.",
             "Versión fijada en Homebrew. Revise esta configuración antes de actualizar.", "Homebrew でバージョンが固定されています。更新前に固定設定を確認してください。")
    }
    var dependency: String {
        text("Installed as a dependency. Update through the package that requires it.", "作为依赖安装，随需要它的软件包更新。",
             "Als Abhängigkeit installiert. Über das benötigende Paket aktualisieren.", "Installé comme dépendance. À mettre à jour via le paquet qui en dépend.",
             "Instalado como dependencia. Actualícelo a través del paquete que lo necesita.", "依存関係としてインストールされています。必要とするパッケージから更新してください。")
    }
    var brewNote: String {
        text("Based on local Homebrew metadata. Refresh Homebrew metadata in Packages if needed.", "结果基于本地 Homebrew 元数据，需要时请到软件包页更新元数据。",
             "Basiert auf lokalen Homebrew-Metadaten. Bei Bedarf unter Pakete aktualisieren.", "Selon les métadonnées Homebrew locales. Actualisez-les dans Paquets si nécessaire.",
             "Basado en los metadatos locales de Homebrew. Actualícelos en Paquetes si es necesario.", "ローカルの Homebrew メタデータに基づく結果です。必要に応じてパッケージ画面で更新してください。")
    }

    func source(_ source: EnvironmentUpdateSource) -> String {
        switch source {
        case .standalone:
            return text("User-installed · standalone", "后装 · 独立安装", "Nachinstalliert · eigenständig", "Ajouté · installation autonome", "Añadido · instalación independiente", "追加インストール · 単独")
        case let .homebrew(prefix, formula, _):
            return text("User-installed", "后装", "Nachinstalliert", "Ajouté", "Añadido", "追加インストール") + " · Homebrew · \(formula) · \(prefix)"
        case let .managed(manager):
            return text("User-installed · managed by \(manager)", "后装 · 由 \(manager) 管理", "Nachinstalliert · von \(manager) verwaltet", "Ajouté · géré par \(manager)", "Añadido · gestionado por \(manager)", "追加インストール · \(manager) で管理")
        case .system:
            return text("macOS built-in", "macOS 自带", "In macOS enthalten", "Fourni avec macOS", "Incluido en macOS", "macOS 標準搭載")
        case .appleDeveloperTools:
            return text("Included with Apple developer tools", "Apple 开发工具附带", "Mit Apple-Entwicklerwerkzeugen geliefert", "Fourni avec les outils de développement Apple", "Incluido en las herramientas de desarrollo de Apple", "Apple 開発ツールに付属")
        case .forwarded:
            return text("Wrapper or alias · see target", "命令转发或别名 · 见转发目标", "Wrapper oder Alias · siehe Ziel", "Relais ou alias · voir la cible", "Intermediario o alias · consulte el destino", "ラッパーまたは別名 · 転送先を参照")
        case .unknown:
            return text("Installation source not confirmed", "安装来源未确认", "Installationsquelle nicht bestätigt", "Source d’installation non confirmée", "Origen de instalación sin confirmar", "インストール元を確認できません")
        }
    }

    func status(_ status: EnvironmentUpdateStatus) -> String {
        switch status {
        case let .available(version):
            return text("Update available: \(version)", "有更新：\(version)", "Update verfügbar: \(version)", "Mise à jour disponible : \(version)", "Actualización disponible: \(version)", "更新あり：\(version)")
        case let .current(version):
            return text("No update found · latest stable: \(version)", "未发现更新 · 查询到的稳定版：\(version)", "Kein Update gefunden · stabile Version: \(version)", "Aucune mise à jour trouvée · version stable : \(version)", "Sin actualizaciones · versión estable: \(version)", "更新なし · 安定版：\(version)")
        case let .ahead(version):
            return text("Installed version is newer than stable \(version)", "当前版本高于查询到的稳定版 \(version)", "Installierte Version ist neuer als die stabile Version \(version)", "Version installée plus récente que la version stable \(version)", "La versión instalada es más reciente que la estable \(version)", "インストール済みのバージョンは安定版 \(version) より新しいです")
        case .unsupported:
            return text("Automatic update check unavailable for this installation or version", "暂不支持检查此安装方式或版本", "Automatische Updateprüfung für diese Installation oder Version nicht verfügbar", "Vérification automatique indisponible pour cette installation ou version", "Comprobación automática no disponible para esta instalación o versión", "このインストール方法またはバージョンの自動確認には未対応です")
        case .failed:
            return text("Check failed. Check the network or Homebrew status and retry.", "检查失败，请检查网络或 Homebrew 状态后重试。", "Prüfung fehlgeschlagen. Netzwerk oder Homebrew-Status prüfen und erneut versuchen.", "Échec de la vérification. Vérifiez le réseau ou l’état de Homebrew, puis réessayez.", "Error al comprobar. Revise la red o el estado de Homebrew e inténtelo de nuevo.", "確認に失敗しました。ネットワークまたは Homebrew の状態を確認して再試行してください。")
        }
    }
}
