// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

struct EnvironmentDetailStrings {
    let language: AppLanguage

    func otherCopies(_ count: Int) -> String {
        switch language {
        case .zhHans: return "另有 \(count) 个同名程序（按查找顺序）"
        case .de: return "Weitere gleichnamige Programme: \(count) (in Suchreihenfolge)"
        case .fr: return "Autres programmes du même nom : \(count) (dans l’ordre de recherche)"
        case .es: return "Otros programas con el mismo nombre: \(count) (en orden de búsqueda)"
        case .ja: return "同名のプログラムがほかに \(count) 件（検索順）"
        default: return "Other programs with the same name: \(count) (in search order)"
        }
    }

    func version(reportedByForwarder: Bool) -> String {
        switch language {
        case .zhHans: return reportedByForwarder ? "转发程序报告的版本" : "版本"
        case .de: return reportedByForwarder ? "Vom Wrapper gemeldete Version" : "Version"
        case .fr: return reportedByForwarder ? "Version signalée par le relais" : "Version"
        case .es: return reportedByForwarder ? "Versión indicada por el intermediario" : "Versión"
        case .ja: return reportedByForwarder ? "転送プログラムが報告したバージョン" : "バージョン"
        default: return reportedByForwarder ? "Version reported by forwarder" : "Version"
        }
    }

    var resolvedPath: String {
        switch language {
        case .zhHans: return "当前命中的路径"
        case .de: return "Aktuell verwendeter Pfad"
        case .fr: return "Chemin actuellement utilisé"
        case .es: return "Ruta utilizada actualmente"
        case .ja: return "現在使われるパス"
        default: return "Current resolved path"
        }
    }

    var forwardTarget: String {
        switch language {
        case .zhHans: return "已确认的转发目标"
        case .de: return "Bestätigtes Weiterleitungsziel"
        case .fr: return "Cible de relais confirmée"
        case .es: return "Destino de reenvío confirmado"
        case .ja: return "確認済みの転送先"
        default: return "Confirmed forward target"
        }
    }

    var pathDifference: String {
        switch language {
        case .zhHans: return "未包含在检测到的图形应用默认 PATH 中"
        case .de: return "Nicht im ermittelten Standard-PATH für grafische Apps"
        case .fr: return "Absent du PATH par défaut détecté pour les apps graphiques"
        case .es: return "No incluido en el PATH predeterminado detectado para apps gráficas"
        case .ja: return "検出した GUI アプリの既定 PATH に含まれない項目"
        default: return "Absent from the detected default PATH for graphical apps"
        }
    }

    var pathNote: String {
        switch language {
        case .zhHans:
            return "对比终端 PATH 与检测到的图形应用默认 PATH。下面列出的差异目录不在后者中，但具体应用的环境可能不同；找不到命令时，可在其配置中使用命令的绝对路径。"
        case .de:
            return "Vergleicht den Terminal-PATH mit dem ermittelten Standard-PATH für grafische Apps. Die abweichenden Ordner fehlen im zweiten Pfad; einzelne Apps können eine andere Umgebung haben. Wird ein Befehl nicht gefunden, kann sein absoluter Pfad in der App-Konfiguration helfen."
        case .fr:
            return "Compare le PATH du Terminal au PATH par défaut détecté pour les apps graphiques. Les dossiers différents sont absents du second, mais l’environnement peut varier selon l’app. Si une commande est introuvable, utilisez son chemin absolu dans la configuration de l’app."
        case .es:
            return "Compara el PATH del Terminal con el PATH predeterminado detectado para las apps gráficas. Las carpetas diferentes no están en el segundo, pero cada app puede tener otro entorno. Si no se encuentra un comando, utilice su ruta absoluta en la configuración de la app."
        case .ja:
            return "ターミナルの PATH と、検出した GUI アプリの既定の PATH を比較します。差分のフォルダは後者に含まれませんが、実際の環境はアプリごとに異なる場合があります。コマンドが見つからない場合は、アプリの設定にコマンドの絶対パスを指定してください。"
        default:
            return "Compares the terminal PATH with the detected default PATH for graphical apps. The differing folders are absent from the latter, but individual apps may use another environment. If a command cannot be found, use its absolute path in the app’s configuration."
        }
    }
}
