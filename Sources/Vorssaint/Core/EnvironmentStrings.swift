// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import Foundation

/// Strings for the global environment page. Same contract as the other
/// FeatureStrings structs: memberwise init with labeled arguments in
/// declaration order, one static per language, all in this file.
struct EnvironmentFeatureStrings {
    var pageTitle: String = "Global environment"
    var hubDescription: String = "Shows which node, python or npx a command actually runs, and why an app started from Finder cannot find them."
    var commandsTitle: String = "Where commands resolve"
    var commandsNote: String = "The first match in PATH wins. A command found in more than one place still runs only the first."
    var shimBadge: String = "Shim"
    var shimFormat: String = "actually runs %@"
    var shadowedFormat: String = "%d more copy shadowed by this one"
    var notFound: String = "Not found"
    var pathTitle: String = "Terminal PATH vs app PATH"
    var pathNote: String = "An app opened from Finder or the Dock never sees the directories below, so write the absolute path in its configuration."
    var pathTerminal: String = "Terminal"
    var pathGui: String = "Apps"
    var pathTerminalOnly: String = "In the terminal only"
    var pathNoDifference: String = "No difference."
    var shellUnavailable: String = "The login shell did not answer, so this is only the system half of PATH."
    var cachesTitle: String = "Caches"
    var cachesNote: String = "Size only. Removing them is the cleaner’s job."
    var cachesEmpty: String = "No cache folders."
    var copyPath: String = "Copy path"
    var copyReport: String = "Copy diagnostic report"
    var refresh: String = "Check again"
}

extension FeatureStrings {
    static func environment(_ language: AppLanguage) -> EnvironmentFeatureStrings {
        switch language {
        case .enUS: return .enUS
        case .ptBR: return .ptBR
        case .tr: return .tr
        case .ru: return .ru
        case .es: return .es
        case .de: return .de
        case .fr: return .fr
        case .it: return .it
        case .ja: return .ja
        case .ko: return .ko
        case .zhHans: return .zhHans
        case .zhTW: return .zhTW
        case .zhHK: return .zhHK
        }
    }
}

extension EnvironmentFeatureStrings {
    static let enUS = EnvironmentFeatureStrings()

    static let ptBR = EnvironmentFeatureStrings(
        pageTitle: "Ambiente global",
        hubDescription: "Mostra qual node, python ou npx um comando realmente executa, e por que um app aberto pelo Finder não os encontra.",
        commandsTitle: "Onde os comandos são resolvidos",
        commandsNote: "A primeira correspondência no PATH vence. Um comando encontrado em vários lugares ainda executa só o primeiro.",
        shimBadge: "Atalho",
        shimFormat: "executa de fato %@",
        shadowedFormat: "Mais %d cópia encoberta por esta",
        notFound: "Não encontrado",
        pathTitle: "PATH do Terminal x PATH dos apps",
        pathNote: "Um app aberto pelo Finder ou pelo Dock nunca vê os diretórios abaixo, então escreva o caminho absoluto na configuração dele.",
        pathTerminal: "Terminal",
        pathGui: "Apps",
        pathTerminalOnly: "Só no Terminal",
        pathNoDifference: "Sem diferença.",
        shellUnavailable: "O shell de login não respondeu, então esta é apenas a metade do PATH vinda do sistema.",
        cachesTitle: "Caches",
        cachesNote: "Só o tamanho. Remover é trabalho do limpador.",
        cachesEmpty: "Nenhuma pasta de cache.",
        copyPath: "Copiar caminho",
        copyReport: "Copiar relatório de diagnóstico",
        refresh: "Verificar de novo"
    )

    static let tr = EnvironmentFeatureStrings(
        pageTitle: "Genel ortam",
        hubDescription: "Bir komutun gercekte hangi node, python veya npx dosyasini calistirdigini ve Finder’dan acilan bir uygulamanin bunlari neden bulamadigini gosterir.",
        commandsTitle: "Komutlar nereye cozumleniyor",
        commandsNote: "PATH icindeki ilk eslesme kazanir. Birden fazla yerde bulunan bir komut yine de yalnizca ilkini calistirir.",
        shimBadge: "Sarmalayici",
        shimFormat: "gercekte %@ calistiriyor",
        shadowedFormat: "Bunun golgeledigi %d kopya daha",
        notFound: "Bulunamadi",
        pathTitle: "Terminal PATH’i ve uygulama PATH’i",
        pathNote: "Finder veya Dock’tan acilan bir uygulama asagidaki dizinleri hic gormez; bu yuzden yapilandirmasina mutlak yolu yazin.",
        pathTerminal: "Terminal",
        pathGui: "Uygulamalar",
        pathTerminalOnly: "Yalnizca Terminal’de",
        pathNoDifference: "Fark yok.",
        shellUnavailable: "Oturum acma kabugu yanit vermedi, bu yuzden burada PATH’in yalnizca sistem yarisi var.",
        cachesTitle: "Onbellekler",
        cachesNote: "Yalnizca boyut. Silmek temizleyicinin isi.",
        cachesEmpty: "Onbellek klasoru yok.",
        copyPath: "Yolu kopyala",
        copyReport: "Tani raporunu kopyala",
        refresh: "Yeniden denetle"
    )

    static let ru = EnvironmentFeatureStrings(
        pageTitle: "Глобальное окружение",
        hubDescription: "Показывает, какой именно node, python или npx запускает команда и почему приложение, открытое из Finder, их не находит.",
        commandsTitle: "Где разрешаются команды",
        commandsNote: "Побеждает первое совпадение в PATH. Команда, найденная в нескольких местах, всё равно запускает только первое.",
        shimBadge: "Обёртка",
        shimFormat: "на самом деле запускает %@",
        shadowedFormat: "Ещё %d копия перекрыта этой",
        notFound: "Не найдено",
        pathTitle: "PATH Терминала и PATH приложений",
        pathNote: "Приложение, открытое из Finder или Dock, никогда не видит каталоги ниже, поэтому в его настройках пишите абсолютный путь.",
        pathTerminal: "Терминал",
        pathGui: "Приложения",
        pathTerminalOnly: "Только в Терминале",
        pathNoDifference: "Различий нет.",
        shellUnavailable: "Оболочка входа не ответила, поэтому здесь только системная половина PATH.",
        cachesTitle: "Кэши",
        cachesNote: "Только размер. Удаление — работа очистки.",
        cachesEmpty: "Папок кэша нет.",
        copyPath: "Скопировать путь",
        copyReport: "Скопировать отчёт диагностики",
        refresh: "Проверить снова"
    )

    static let es = EnvironmentFeatureStrings(
        pageTitle: "Entorno global",
        hubDescription: "Muestra qué node, python o npx ejecuta realmente un comando, y por qué una app abierta desde el Finder no los encuentra.",
        commandsTitle: "Dónde se resuelven los comandos",
        commandsNote: "Gana la primera coincidencia del PATH. Un comando presente en varios sitios sigue ejecutando solo el primero.",
        shimBadge: "Envoltorio",
        shimFormat: "en realidad ejecuta %@",
        shadowedFormat: "%d copia más tapada por esta",
        notFound: "No encontrado",
        pathTitle: "PATH del Terminal frente al de las apps",
        pathNote: "Una app abierta desde el Finder o el Dock nunca ve los directorios de abajo, así que escribe la ruta absoluta en su configuración.",
        pathTerminal: "Terminal",
        pathGui: "Apps",
        pathTerminalOnly: "Solo en el Terminal",
        pathNoDifference: "Sin diferencias.",
        shellUnavailable: "El shell de inicio de sesión no respondió, así que aquí solo está la mitad del PATH que viene del sistema.",
        cachesTitle: "Cachés",
        cachesNote: "Solo el tamaño. Borrarlas es tarea del limpiador.",
        cachesEmpty: "No hay carpetas de caché.",
        copyPath: "Copiar ruta",
        copyReport: "Copiar informe de diagnóstico",
        refresh: "Volver a comprobar"
    )

    static let de = EnvironmentFeatureStrings(
        pageTitle: "Globale Umgebung",
        hubDescription: "Zeigt, welches node, python oder npx ein Befehl wirklich ausführt, und warum eine aus dem Finder gestartete App sie nicht findet.",
        commandsTitle: "Wohin Befehle aufgelöst werden",
        commandsNote: "Der erste Treffer im PATH gewinnt. Ein Befehl an mehreren Orten führt trotzdem nur den ersten aus.",
        shimBadge: "Wrapper",
        shimFormat: "führt tatsächlich %@ aus",
        shadowedFormat: "%d weitere Kopie wird davon verdeckt",
        notFound: "Nicht gefunden",
        pathTitle: "Terminal-PATH gegenüber App-PATH",
        pathNote: "Eine aus dem Finder oder Dock geöffnete App sieht die Verzeichnisse unten nie, schreib in ihre Konfiguration also den absoluten Pfad.",
        pathTerminal: "Terminal",
        pathGui: "Apps",
        pathTerminalOnly: "Nur im Terminal",
        pathNoDifference: "Kein Unterschied.",
        shellUnavailable: "Die Login-Shell hat nicht geantwortet, hier steht also nur die System-Hälfte des PATH.",
        cachesTitle: "Caches",
        cachesNote: "Nur die Größe. Das Löschen macht die Bereinigung.",
        cachesEmpty: "Keine Cache-Ordner.",
        copyPath: "Pfad kopieren",
        copyReport: "Diagnosebericht kopieren",
        refresh: "Erneut prüfen"
    )

    static let fr = EnvironmentFeatureStrings(
        pageTitle: "Environnement global",
        hubDescription: "Montre quel node, python ou npx une commande exécute vraiment, et pourquoi une app lancée depuis le Finder ne les trouve pas.",
        commandsTitle: "Où les commandes sont résolues",
        commandsNote: "La première correspondance du PATH l’emporte. Une commande présente à plusieurs endroits n’exécute que la première.",
        shimBadge: "Enveloppe",
        shimFormat: "exécute en fait %@",
        shadowedFormat: "%d copie de plus masquée par celle-ci",
        notFound: "Introuvable",
        pathTitle: "PATH du Terminal et PATH des apps",
        pathNote: "Une app ouverte depuis le Finder ou le Dock ne voit jamais les dossiers ci-dessous, alors écris le chemin absolu dans sa configuration.",
        pathTerminal: "Terminal",
        pathGui: "Apps",
        pathTerminalOnly: "Dans le Terminal seulement",
        pathNoDifference: "Aucune différence.",
        shellUnavailable: "Le shell de connexion n’a pas répondu, il ne reste donc ici que la moitié système du PATH.",
        cachesTitle: "Caches",
        cachesNote: "La taille seulement. Les supprimer, c’est le travail du nettoyage.",
        cachesEmpty: "Aucun dossier de cache.",
        copyPath: "Copier le chemin",
        copyReport: "Copier le rapport de diagnostic",
        refresh: "Vérifier à nouveau"
    )

    static let it = EnvironmentFeatureStrings(
        pageTitle: "Ambiente globale",
        hubDescription: "Mostra quale node, python o npx esegue davvero un comando, e perché un’app avviata dal Finder non li trova.",
        commandsTitle: "Dove vengono risolti i comandi",
        commandsNote: "Vince la prima corrispondenza nel PATH. Un comando presente in più posti esegue comunque solo il primo.",
        shimBadge: "Wrapper",
        shimFormat: "esegue in realtà %@",
        shadowedFormat: "Altra %d copia coperta da questa",
        notFound: "Non trovato",
        pathTitle: "PATH del Terminale e PATH delle app",
        pathNote: "Un’app aperta dal Finder o dal Dock non vede mai le cartelle qui sotto, quindi scrivi il percorso assoluto nella sua configurazione.",
        pathTerminal: "Terminale",
        pathGui: "App",
        pathTerminalOnly: "Solo nel Terminale",
        pathNoDifference: "Nessuna differenza.",
        shellUnavailable: "La shell di login non ha risposto, quindi qui c’è solo la metà di sistema del PATH.",
        cachesTitle: "Cache",
        cachesNote: "Solo la dimensione. Rimuoverle è compito della pulizia.",
        cachesEmpty: "Nessuna cartella di cache.",
        copyPath: "Copia percorso",
        copyReport: "Copia rapporto diagnostico",
        refresh: "Controlla di nuovo"
    )

    static let ja = EnvironmentFeatureStrings(
        pageTitle: "グローバル環境",
        hubDescription: "コマンドが実際にどの node、python、npx を実行するのか、Finder から起動した App がなぜ見つけられないのかを示します。",
        commandsTitle: "コマンドの解決先",
        commandsNote: "PATH で最初に見つかったものが勝ちます。複数の場所にある場合も、実行されるのは最初の 1 つだけです。",
        shimBadge: "ラッパー",
        shimFormat: "実際には %@ を実行",
        shadowedFormat: "これに隠れているコピーがあと %d 個",
        notFound: "見つかりません",
        pathTitle: "ターミナルの PATH と App の PATH",
        pathNote: "Finder や Dock から開いた App は下のディレクトリを一切見ないので、設定には絶対パスを書いてください。",
        pathTerminal: "ターミナル",
        pathGui: "App",
        pathTerminalOnly: "ターミナルだけにある",
        pathNoDifference: "差はありません。",
        shellUnavailable: "ログインシェルが応答しなかったため、ここにはシステム側の PATH しかありません。",
        cachesTitle: "キャッシュ",
        cachesNote: "サイズのみ。削除はクリーンアップの担当です。",
        cachesEmpty: "キャッシュフォルダはありません。",
        copyPath: "パスをコピー",
        copyReport: "診断レポートをコピー",
        refresh: "再確認"
    )

    static let ko = EnvironmentFeatureStrings(
        pageTitle: "전역 환경",
        hubDescription: "명령이 실제로 어떤 node, python, npx를 실행하는지, Finder에서 연 App이 왜 그것들을 찾지 못하는지 보여줍니다.",
        commandsTitle: "명령이 어디로 연결되는지",
        commandsNote: "PATH에서 처음 찾은 것이 이깁니다. 여러 곳에 있어도 실행되는 것은 첫 번째 하나뿐입니다.",
        shimBadge: "래퍼",
        shimFormat: "실제로는 %@ 실행",
        shadowedFormat: "여기에 가려진 사본 %d개 더",
        notFound: "찾을 수 없음",
        pathTitle: "터미널 PATH와 App PATH",
        pathNote: "Finder나 Dock에서 연 App은 아래 디렉터리를 전혀 보지 못하므로 설정에 절대 경로를 적으세요.",
        pathTerminal: "터미널",
        pathGui: "App",
        pathTerminalOnly: "터미널에만 있음",
        pathNoDifference: "차이 없음.",
        shellUnavailable: "로그인 셸이 응답하지 않아 여기에는 시스템 쪽 PATH만 있습니다.",
        cachesTitle: "캐시",
        cachesNote: "크기만 표시합니다. 삭제는 정리의 몫입니다.",
        cachesEmpty: "캐시 폴더가 없습니다.",
        copyPath: "경로 복사",
        copyReport: "진단 보고서 복사",
        refresh: "다시 확인"
    )

    static let zhHans = EnvironmentFeatureStrings(
        pageTitle: "全局环境",
        hubDescription: "看清一条命令实际跑的是哪个 node、python 或 npx，以及从访达启动的 App 为什么找不到它们。",
        commandsTitle: "命令解析到哪里",
        commandsNote: "PATH 里排在前面的那一份赢。同一个命令有好几份时，跑的始终只有第一份。",
        shimBadge: "壳",
        shimFormat: "实际执行 %@",
        shadowedFormat: "还有 %d 份被它挡住",
        notFound: "没找到",
        pathTitle: "终端的 PATH 和 App 的 PATH",
        pathNote: "从访达或程序坞打开的 App 完全看不到下面这些目录，所以在它的配置里要写绝对路径。",
        pathTerminal: "终端",
        pathGui: "App",
        pathTerminalOnly: "只有终端有",
        pathNoDifference: "没有差异。",
        shellUnavailable: "读不到登录 shell 的 PATH，下面只有系统那一半。",
        cachesTitle: "缓存",
        cachesNote: "只报大小，清理在清理器里做。",
        cachesEmpty: "没有缓存目录。",
        copyPath: "复制路径",
        copyReport: "复制诊断报告",
        refresh: "重新检查"
    )

    static let zhTW = EnvironmentFeatureStrings(
        pageTitle: "全域環境",
        hubDescription: "看清一條命令實際跑的是哪個 node、python 或 npx，以及從 Finder 啟動的 App 為什麼找不到它們。",
        commandsTitle: "命令解析到哪裡",
        commandsNote: "PATH 裡排在前面的那一份贏。同一個命令有好幾份時，跑的始終只有第一份。",
        shimBadge: "外殼",
        shimFormat: "實際執行 %@",
        shadowedFormat: "還有 %d 份被它擋住",
        notFound: "找不到",
        pathTitle: "終端機的 PATH 和 App 的 PATH",
        pathNote: "從 Finder 或 Dock 打開的 App 完全看不到下面這些目錄，所以在它的設定裡要寫絕對路徑。",
        pathTerminal: "終端機",
        pathGui: "App",
        pathTerminalOnly: "只有終端機有",
        pathNoDifference: "沒有差異。",
        shellUnavailable: "讀不到登入 shell 的 PATH，下面只有系統那一半。",
        cachesTitle: "快取",
        cachesNote: "只報大小，清理在清理器裡做。",
        cachesEmpty: "沒有快取目錄。",
        copyPath: "複製路徑",
        copyReport: "複製診斷報告",
        refresh: "重新檢查"
    )

    static let zhHK = EnvironmentFeatureStrings(
        pageTitle: "全域環境",
        hubDescription: "睇清楚一條命令實際跑嘅係邊個 node、python 或 npx，以及由 Finder 啟動嘅 App 點解搵唔到佢哋。",
        commandsTitle: "命令解析去邊",
        commandsNote: "PATH 入面排前嘅嗰份贏。同一個命令有幾份嘅時候，跑嘅始終只有第一份。",
        shimBadge: "外殼",
        shimFormat: "實際執行 %@",
        shadowedFormat: "仲有 %d 份俾佢擋住",
        notFound: "搵唔到",
        pathTitle: "終端機嘅 PATH 同 App 嘅 PATH",
        pathNote: "由 Finder 或 Dock 開嘅 App 完全睇唔到下面呢啲目錄，所以喺佢嘅設定入面要寫絕對路徑。",
        pathTerminal: "終端機",
        pathGui: "App",
        pathTerminalOnly: "只有終端機有",
        pathNoDifference: "冇差異。",
        shellUnavailable: "讀唔到登入 shell 嘅 PATH，下面只有系統嗰一半。",
        cachesTitle: "快取",
        cachesNote: "只報大細，清理喺清理器度做。",
        cachesEmpty: "冇快取目錄。",
        copyPath: "複製路徑",
        copyReport: "複製診斷報告",
        refresh: "重新檢查"
    )
}
