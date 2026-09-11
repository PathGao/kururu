// SPDX-License-Identifier: GPL-3.0-or-later
enum UninstallerSelectionError: Equatable, CaseIterable {
    case systemApplication, protectedApplication, invalidApplication, linkedPath, changedApplication
}
enum UninstallerSelectionSupport {
    static func rejection(system: Bool, protected: Bool, actualPath: Bool, valid: Bool) -> UninstallerSelectionError? {
        if system { return .systemApplication }
        if protected { return .protectedApplication }
        if !actualPath { return .linkedPath }
        if !valid { return .invalidApplication }
        return nil
    }
}

extension UninstallerSelectionError {
    func message(language: String) -> String {
        let messages: [String]
        switch language {
        case "zh-Hans": messages = ["系统应用受保护，不能在此卸载。请选择其他应用。", "此应用或组件受保护，不能在此卸载。请选择其他应用。", "无法验证这个应用。请选择完整、可读取的 .app 文件。", "请选择应用的实际位置，不要选择链接或别名路径。", "应用在扫描期间发生变化。请重新选择后扫描。"]
        case "de": messages = ["System-Apps sind geschützt und können hier nicht deinstalliert werden. Wähle eine andere App.", "Diese App oder Komponente ist geschützt und kann hier nicht deinstalliert werden. Wähle eine andere App.", "Diese App konnte nicht überprüft werden. Wähle eine vollständige, lesbare .app-Datei.", "Wähle den tatsächlichen Speicherort der App, keinen Link oder Alias.", "Die App wurde während des Scans verändert. Wähle sie erneut aus und starte den Scan."]
        case "fr": messages = ["Les apps système sont protégées et ne peuvent pas être désinstallées ici. Choisissez une autre app.", "Cette app ou ce composant est protégé et ne peut pas être désinstallé ici. Choisissez une autre app.", "Impossible de vérifier cette app. Choisissez un fichier .app complet et lisible.", "Choisissez l’emplacement réel de l’app, pas un lien ni un alias.", "L’app a changé pendant l’analyse. Sélectionnez-la à nouveau pour relancer l’analyse."]
        case "es": messages = ["Las apps del sistema están protegidas y no se pueden desinstalar aquí. Elige otra app.", "Esta app o componente está protegido y no se puede desinstalar aquí. Elige otra app.", "No se pudo verificar esta app. Elige un archivo .app completo y legible.", "Elige la ubicación real de la app, no un enlace ni un alias.", "La app cambió durante el análisis. Vuelve a seleccionarla para analizarla."]
        case "ja": messages = ["システムアプリは保護されているため、ここではアンインストールできません。別のアプリを選んでください。", "このアプリまたはコンポーネントは保護されているため、ここではアンインストールできません。別のアプリを選んでください。", "このアプリを確認できませんでした。完全で読み取り可能な .app ファイルを選んでください。", "リンクやエイリアスではなく、アプリの実際の場所を選んでください。", "スキャン中にアプリが変更されました。選び直して再スキャンしてください。"]
        default: messages = ["System apps are protected and cannot be uninstalled here. Choose another app.", "This app or component is protected and cannot be uninstalled here. Choose another app.", "This app could not be verified. Choose a complete, readable .app file.", "Choose the app’s actual location, not a link or alias path.", "The app changed during the scan. Choose it again to scan it."]
        }
        switch self {
        case .systemApplication: return messages[0]
        case .protectedApplication: return messages[1]
        case .invalidApplication: return messages[2]
        case .linkedPath: return messages[3]
        case .changedApplication: return messages[4]
        }
    }
}
