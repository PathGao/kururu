import Foundation

struct FeatureBehaviorStrings {
    var triggers = "Enable triggers"
    var setLevel = "Set brightness"
    var level = "Target brightness (%)"
    var pending = "Confirming display brightness…"
    var unconfirmed = "Target sent. The display has not returned a reliable reading."
    var invalidRead = "Brightness could not be read reliably. Enter a target to set it, or retry later."
    var shortcut = "Enable shortcut"
    var identityUnavailable = "This display cannot be identified reliably. Reconnect it before using display controls."
    var shelfInteraction = "Shelf interaction and triggers"
    var shelfInteractionHelp = "Pauses opening, shortcuts, automatic triggers and incoming drops. Existing items and backup import remain available."

    init(language: AppLanguage) {
        switch language {
        case .zhHans:
            triggers = "启用触发方式"; setLevel = "设置亮度"; level = "目标亮度 (%)"
            pending = "正在确认显示器亮度…"
            unconfirmed = "已发送目标值，显示器尚未返回可靠读数。"
            invalidRead = "无法可靠读取亮度。可输入目标值设置，或稍后重试。"
            shortcut = "启用快捷键"
            identityUnavailable = "无法可靠识别这台显示器，请重新连接后再使用显示器控制。"
            shelfInteraction = "暂存架交互与触发"
            shelfInteractionHelp = "关闭后暂停打开、快捷键、自动唤出和接收拖入，保留已有内容与备份导入。"
        case .zhTW, .zhHK:
            triggers = "啟用觸發方式"; setLevel = "設定亮度"; level = "目標亮度 (%)"
            pending = "正在確認顯示器亮度…"
            unconfirmed = "已傳送目標值，顯示器尚未傳回可靠讀數。"
            invalidRead = "無法可靠讀取亮度。可輸入目標值設定，或稍後重試。"
            shortcut = "啟用快捷鍵"
            identityUnavailable = "無法可靠識別這台顯示器，請重新連接後再使用顯示器控制。"
            shelfInteraction = "暫存架互動與觸發"
            shelfInteractionHelp = "關閉後暫停開啟、快捷鍵、自動喚出與接收拖入，保留已有內容與備份匯入。"
        case .de:
            triggers = "Auslöser aktivieren"; setLevel = "Helligkeit einstellen"; level = "Zielhelligkeit (%)"
            pending = "Displayhelligkeit wird bestätigt…"
            unconfirmed = "Zielwert gesendet. Das Display hat noch keinen zuverlässigen Messwert geliefert."
            invalidRead = "Helligkeit konnte nicht zuverlässig gelesen werden. Zielwert eingeben oder später erneut versuchen."
            shortcut = "Kurzbefehl aktivieren"
            identityUnavailable = "Das Display kann nicht zuverlässig identifiziert werden. Verbinde es erneut."
            shelfInteraction = "Ablageinteraktion und Auslöser"
            shelfInteractionHelp = "Pausiert Öffnen, Kurzbefehle, automatische Auslöser und Ablegen. Vorhandene Inhalte und Sicherungsimport bleiben verfügbar."
        case .fr:
            triggers = "Activer les déclencheurs"; setLevel = "Régler la luminosité"; level = "Luminosité cible (%)"
            pending = "Confirmation de la luminosité…"
            unconfirmed = "Valeur envoyée. L’écran n’a pas encore renvoyé de mesure fiable."
            invalidRead = "Lecture de luminosité non fiable. Saisissez une valeur cible ou réessayez plus tard."
            shortcut = "Activer le raccourci"
            identityUnavailable = "Impossible d’identifier cet écran de manière fiable. Reconnectez-le."
            shelfInteraction = "Interactions et déclencheurs de l’étagère"
            shelfInteractionHelp = "Suspend l’ouverture, les raccourcis, les déclencheurs et les dépôts. Les éléments existants et l’import de sauvegardes restent disponibles."
        case .es:
            triggers = "Activar los disparadores"; setLevel = "Ajustar brillo"; level = "Brillo objetivo (%)"
            pending = "Confirmando el brillo de la pantalla…"
            unconfirmed = "Valor enviado. La pantalla aún no ha devuelto una lectura fiable."
            invalidRead = "No se pudo leer el brillo de forma fiable. Introduce un valor o inténtalo más tarde."
            shortcut = "Activar atajo"
            identityUnavailable = "No se puede identificar esta pantalla de forma fiable. Vuelve a conectarla."
            shelfInteraction = "Interacción y activación del estante"
            shelfInteractionHelp = "Pausa la apertura, los atajos, la activación automática y la recepción de archivos. Se conservan los elementos y la importación de copias."
        case .ja:
            triggers = "起動方法を有効にする"; setLevel = "明るさを設定"; level = "目標の明るさ (%)"
            pending = "ディスプレイの明るさを確認中…"
            unconfirmed = "目標値を送信しました。信頼できる測定値はまだ返されていません。"
            invalidRead = "明るさを正しく読み取れません。目標値を入力するか、後で再試行してください。"
            shortcut = "ショートカットを有効にする"
            identityUnavailable = "ディスプレイを正しく識別できません。接続し直してください。"
            shelfInteraction = "シェルフの操作と起動"
            shelfInteractionHelp = "表示、ショートカット、自動起動、ドロップの受け取りを停止します。既存の項目とバックアップの読み込みは保持されます。"
        default: break
        }
    }
}
