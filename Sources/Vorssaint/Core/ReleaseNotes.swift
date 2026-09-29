// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import Foundation

struct ReleaseNotes {
    let version: String
    let date: String?
    let sections: [ReleaseNoteSection]

    static var current: ReleaseNotes {
        current(changelog: bundledChangelog())
    }

    /// User-facing notes for the current product only. Published history remains verbatim.
    static func current(languageCode: String, changelog: String? = bundledChangelog()) -> ReleaseNotes {
        let parsed = current(changelog: changelog)
        guard parsed.version == "0.1.0", !parsed.sections.isEmpty else { return parsed }
        let items: [String]
        switch languageCode {
        case "zh-Hans": items = [
            "按需启用工具。关闭后保留数据与设置，仍可查看保存的设置概要。重新启用后按原有设置运行，并可继续调整。",
            "先查看剪贴板图片、JSON 原文和图片中的文字，再明确选择复制。清空最近记录前会请你确认。",
            "清理链接时可以暂停整组规则并保留设置，手动清理使用同一组规则；删除规则前会请你确认。",
            "通过主题页面链接或文件预览配色，确认后再应用。可以随时恢复默认配色。",
            "导入暂存内容前可以预览并选择整组项目；文件可明确选择引用原位置或复制到暂存架。",
            "项目链接与反馈草稿集中在关于页。更新仅提供正式版；当前构建不可更新时会明确说明。"
        ]
        case "de": items = [
            "Aktiviere die benötigten Werkzeuge. Beim Deaktivieren bleiben Daten, Einstellungen und eine lesbare Zusammenfassung erhalten. Nach erneutem Aktivieren gelten die gespeicherten Einstellungen und können weiter angepasst werden.",
            "Prüfe Bilder, den JSON-Originaltext und Text aus Bildern in der Zwischenablage, bevor du ausdrücklich kopierst. Das Leeren der letzten Einträge erfordert eine Bestätigung.",
            "Pausiere ganze Regelgruppen zur Linkbereinigung, ohne ihre Einstellungen zu verlieren. Die manuelle Bereinigung verwendet dieselben Regeln; das Löschen einer Regel erfordert eine Bestätigung.",
            "Sieh dir Farben über einen Theme-Seitenlink oder eine Datei an und wende sie erst nach deiner Prüfung an. Die Standardfarben lassen sich jederzeit wiederherstellen.",
            "Prüfe importierte Ablageinhalte und wähle ganze Gruppen aus. Bei Dateien entscheidest du ausdrücklich zwischen einem Verweis auf den Speicherort und einer Kopie in der Ablage.",
            "Projektlinks und Feedback-Entwürfe findest du unter Über. Updates bieten nur stabile Versionen an; wenn dieser Build keine Updates unterstützt, wird dies klar angezeigt."
        ]
        case "fr": items = [
            "Activez les outils nécessaires. Leur désactivation conserve les données, les réglages et un résumé consultable. Réactivez-les pour reprendre leur fonctionnement selon les réglages enregistrés et les modifier.",
            "Examinez les images du presse-papiers, le texte JSON original et le texte des images avant de choisir de copier. L’effacement des éléments récents demande une confirmation.",
            "Mettez en pause des groupes de règles de nettoyage des liens sans perdre leurs réglages. Le nettoyage manuel utilise les mêmes règles ; leur suppression demande une confirmation.",
            "Prévisualisez des couleurs depuis le lien d’une page de thème ou un fichier, puis appliquez-les après vérification. Vous pouvez rétablir les couleurs par défaut à tout moment.",
            "Prévisualisez le contenu à importer dans l’étagère et sélectionnez des groupes entiers. Pour les fichiers, choisissez explicitement une référence à leur emplacement ou une copie dans l’étagère.",
            "Les liens du projet et les brouillons de retour sont réunis dans À propos. Seules les versions stables sont proposées ; l’indisponibilité des mises à jour est clairement indiquée."
        ]
        case "es": items = [
            "Activa las herramientas que necesites. Al desactivarlas se conservan sus datos, ajustes y un resumen consultable. Vuelve a activarlas para utilizarlas según los ajustes guardados y seguir configurándolas.",
            "Revisa las imágenes del portapapeles, el JSON original y el texto de las imágenes antes de elegir copiar. Vaciar los elementos recientes requiere confirmación.",
            "Pausa grupos de reglas de limpieza de enlaces sin perder sus ajustes. La limpieza manual usa las mismas reglas; eliminarlas requiere confirmación.",
            "Previsualiza colores desde el enlace de una página de tema o un archivo y aplícalos cuando los hayas revisado. Puedes restaurar los colores predeterminados en cualquier momento.",
            "Previsualiza el contenido que vas a importar al estante y selecciona grupos completos. Para los archivos, elige expresamente entre referenciar su ubicación o copiarlos al estante.",
            "Los enlaces del proyecto y los borradores de comentarios están en Acerca de. Solo se ofrecen versiones estables; si esta compilación no admite actualizaciones, se indica claramente."
        ]
        case "ja": items = [
            "必要なツールを有効にできます。無効にしてもデータと設定は保持され、保存済み設定の概要を確認できます。再度有効にすると保存済みの設定で動作し、設定の編集を続けられます。",
            "クリップボードの画像、元の JSON、画像内の文字を確認してから、明示的にコピーできます。最近の履歴を消去する前に確認が表示されます。",
            "リンクを整理するルールは、設定を残したままグループ単位で一時停止できます。手動の整理でも同じルールを使い、削除前には確認が表示されます。",
            "テーマページのリンクやファイルから配色をプレビューし、確認してから適用できます。いつでも標準の配色に戻せます。",
            "シェルフへの読み込み前に内容を確認し、グループ単位で選択できます。ファイルは元の場所を参照するか、シェルフにコピーするかを明示的に選べます。",
            "プロジェクトへのリンクとフィードバックの下書きは「このアプリについて」にまとめました。更新は正式版のみを対象とし、このビルドで更新できない場合は明示します。"
        ]
        default: items = [
            "Enable the tools you need. Disabling a tool keeps its data, settings and a readable saved summary. Enable it again to resume with its saved settings and continue configuring it.",
            "Inspect clipboard images, original JSON and text from images before explicitly choosing to copy. Clearing recent history asks for confirmation.",
            "Pause groups of link-cleaning rules without losing their settings. Manual cleaning uses the same rules, and deleting a rule asks for confirmation.",
            "Preview colors from a theme page link or a file, then apply them after checking. Restore the default colors whenever you want.",
            "Preview shelf imports and select whole groups. For files, explicitly choose between referencing their location and copying them into the shelf.",
            "Project links and feedback drafts are together in About. Updates offer stable releases only; builds without updates say so clearly."
        ]
        }
        return ReleaseNotes(version: parsed.version, date: parsed.date,
                            sections: [ReleaseNoteSection(title: "", items: items.map(ReleaseNoteItem.bullet))])
    }

    static func current(changelog: String?) -> ReleaseNotes {
        notes(for: ProductIdentity.currentReleaseNotesVersion, changelog: changelog)
    }

    func versionLabel(languageCode: String) -> String {
        if version == "Unreleased" {
            switch languageCode {
            case "zh-Hans": return "\(ProductIdentity.name) · 未发布的更改"
            case "de": return "\(ProductIdentity.name) · Unveröffentlichte Änderungen"
            case "fr": return "\(ProductIdentity.name) · Modifications non publiées"
            case "es": return "\(ProductIdentity.name) · Cambios sin publicar"
            case "ja": return "\(ProductIdentity.name) · 未リリースの変更"
            default: return "\(ProductIdentity.name) · Unreleased changes"
            }
        }
        return date.map { "v\(version) · \($0)" } ?? "v\(version)"
    }

    static func notes(for version: String, changelog: String? = bundledChangelog()) -> ReleaseNotes {
        guard let changelog,
              let parsed = parse(version: version, changelog: changelog) else {
            return ReleaseNotes(version: version, date: nil, sections: [])
        }
        return parsed
    }

    /// Every version listed in the changelog, in document order (newest first).
    /// Used to surface the releases a user skipped between updates.
    static func allVersions(changelog: String? = bundledChangelog()) -> [String] {
        guard let changelog else { return [] }
        return changelog
            .components(separatedBy: .newlines)
            .compactMap { header(in: $0)?.version }
            .filter { $0 != "Unreleased" }
    }

    /// Raw markdown body of a version's changelog section (everything between its
    /// `## [version]` header and the next one), so the Developer build can feed
    /// the update preview real notes. Empty when the version is absent.
    static func rawNotes(for version: String, changelog: String? = bundledChangelog()) -> String {
        guard let changelog else { return "" }
        let lines = changelog.components(separatedBy: .newlines)
        var targetIndex = lines.firstIndex(where: { header(in: $0)?.version == version })
        if targetIndex == nil && (version == "dev" || version == AppInfo.version) {
            targetIndex = lines.firstIndex(where: { header(in: $0)?.version == "Unreleased" })
        }
        guard let start = targetIndex else { return "" }
        var body: [String] = []
        for line in lines.dropFirst(start + 1) {
            if line.hasPrefix("## [") { break }
            body.append(line)
        }
        return body.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func inAppUpdateNotes(from releaseBody: String?) -> String? {
        guard let releaseBody else { return nil }
        let lines = releaseBody
            .components(separatedBy: .newlines)
            .filter { !isDistributionFooter($0) }
        let cleaned = lines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
        return cleaned.isEmpty ? nil : cleaned
    }

    private static func bundledChangelog() -> String? {
        guard let url = Bundle.main.url(forResource: "CHANGELOG", withExtension: "md") else { return nil }
        return try? String(contentsOf: url, encoding: .utf8)
    }

    private static func parse(version: String, changelog: String) -> ReleaseNotes? {
        let lines = changelog.components(separatedBy: .newlines)
        guard let start = lines.firstIndex(where: { header(in: $0)?.version == version }),
              let header = header(in: lines[start]) else { return nil }

        var sections: [ReleaseNoteSection] = []
        var currentTitle = ""
        var currentItems: [ReleaseNoteItem] = []
        var currentParagraph: [String] = []

        func flushParagraph() {
            guard !currentParagraph.isEmpty else { return }
            let paragraph = clean(currentParagraph.joined(separator: " "))
            if !paragraph.isEmpty {
                currentItems.append(.paragraph(paragraph))
            }
            currentParagraph.removeAll()
        }

        func flushSection() {
            flushParagraph()
            defer { currentItems.removeAll() }
            guard !currentItems.isEmpty, shouldDisplaySection(currentTitle) else { return }
            sections.append(ReleaseNoteSection(title: currentTitle, items: currentItems))
        }

        for rawLine in lines.dropFirst(start + 1) {
            if rawLine.hasPrefix("## [") { break }
            if rawLine.hasPrefix("### ") {
                flushSection()
                currentTitle = String(rawLine.dropFirst(4)).trimmingCharacters(in: .whitespaces)
                continue
            }

            let trimmed = rawLine.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty {
                flushParagraph()
            } else if trimmed.hasPrefix("- ") {
                flushParagraph()
                currentItems.append(.bullet(clean(String(trimmed.dropFirst(2)))))
            } else if let image = image(in: trimmed) {
                flushParagraph()
                currentItems.append(.image(image))
            } else if rawLine.hasPrefix("  "), !currentItems.isEmpty, !trimmed.isEmpty,
                      case let .bullet(text) = currentItems[currentItems.count - 1] {
                currentItems[currentItems.count - 1] = .bullet(text + " " + clean(trimmed))
            } else {
                if currentTitle.isEmpty {
                    currentTitle = "Summary"
                }
                currentParagraph.append(trimmed)
            }
        }
        flushSection()

        return ReleaseNotes(version: header.version, date: header.date, sections: sections)
    }

    private static func header(in line: String) -> (version: String, date: String?)? {
        guard line.hasPrefix("## [") else { return nil }
        let versionStart = line.index(line.startIndex, offsetBy: 4)
        guard let close = line[versionStart...].firstIndex(of: "]") else { return nil }
        let version = String(line[versionStart..<close])
        let suffixStart = line.index(after: close)
        let suffix = line[suffixStart...]
        let date = suffix.range(of: " - ").map { range in
            String(suffix[range.upperBound...]).trimmingCharacters(in: .whitespaces)
        }
        return (version, date)
    }

    private static func clean(_ text: String) -> String {
        var result = text
        while let labelStart = result.range(of: "["),
              let labelEnd = result[labelStart.upperBound...].range(of: "]"),
              let linkStart = result[labelEnd.upperBound...].range(of: "("),
              linkStart.lowerBound == labelEnd.upperBound,
              let linkEnd = result[linkStart.upperBound...].range(of: ")") {
            let label = String(result[labelStart.upperBound..<labelEnd.lowerBound])
            result.replaceSubrange(labelStart.lowerBound..<linkEnd.upperBound, with: label)
        }
        return result.replacingOccurrences(of: "**", with: "")
            .replacingOccurrences(of: "`", with: "")
            .trimmingCharacters(in: .whitespaces)
    }

    private static func image(in line: String) -> ReleaseNoteImage? {
        guard line.hasPrefix("!["),
              let altEnd = line[line.index(line.startIndex, offsetBy: 2)...].firstIndex(of: "]") else {
            return nil
        }
        let linkStartIndex = line.index(after: altEnd)
        guard linkStartIndex < line.endIndex,
              line[linkStartIndex] == "(",
              let linkEnd = line[line.index(after: linkStartIndex)...].firstIndex(of: ")") else {
            return nil
        }
        let alt = String(line[line.index(line.startIndex, offsetBy: 2)..<altEnd])
        let path = String(line[line.index(after: linkStartIndex)..<linkEnd])
        guard !path.isEmpty else { return nil }
        return ReleaseNoteImage(alt: alt, path: path)
    }

    private static func shouldDisplaySection(_ title: String) -> Bool {
        let normalized = title.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return normalized != "website" && normalized != "links"
    }

    private static func isDistributionFooter(_ line: String) -> Bool {
        let normalized = line.trimmingCharacters(in: .whitespacesAndNewlines)
        return normalized == "Signed with an Apple Developer ID and notarized by Apple, so it downloads and opens normally. Requires macOS 14 or later. Open the .dmg below and drag Vorssaint to Applications."
    }
}

struct ReleaseNoteSection {
    let title: String
    let items: [ReleaseNoteItem]

    var bulletItems: [String] {
        items.compactMap {
            if case let .bullet(text) = $0 { return text }
            return nil
        }
    }

    var paragraphItems: [String] {
        items.compactMap {
            if case let .paragraph(text) = $0 { return text }
            return nil
        }
    }
}

enum ReleaseNoteItem: Equatable {
    case paragraph(String)
    case bullet(String)
    case image(ReleaseNoteImage)
}

struct ReleaseNoteImage: Equatable {
    let alt: String
    let path: String
}
