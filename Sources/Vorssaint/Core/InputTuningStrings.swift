// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

struct InputTuningStrings {
    let language: AppLanguage
    private func text(_ en: String, _ zh: String, _ de: String, _ fr: String, _ es: String, _ ja: String) -> String {
        switch language {
        case .zhHans: zh
        case .de: de
        case .fr: fr
        case .es: es
        case .ja: ja
        default: en
        }
    }
    var precision: String { text("Precise", "精细", "Präzise", "Précis", "Preciso", "精密") }
    var balanced: String { text("Balanced", "均衡", "Ausgewogen", "Équilibré", "Equilibrado", "バランス") }
    var glide: String { text("Long glide", "长滑行", "Langes Gleiten", "Glissement long", "Deslizamiento largo", "長い滑走") }
    var reset: String { text("Reset", "恢复默认", "Zurücksetzen", "Réinitialiser", "Restablecer", "リセット") }
    var curve: String { text("One wheel tick: distance over time", "单次滚轮输入：距离随时间的变化", "Ein Mausradschritt: Weg über Zeit", "Un cran : distance dans le temps", "Un paso: distancia en el tiempo", "ホイール1刻み：時間と移動距離") }
    var scrollHint: String { text("Distance controls how far each tick travels. Response controls how quickly it arrives. Native trackpad scrolling is preserved.", "步长控制一次滚动的距离，响应控制完成这段距离的快慢。触控板保留原生滚动。", "Distanz bestimmt den Weg pro Schritt, Reaktion dessen Dauer. Trackpad-Scrollen bleibt unverändert.", "La distance règle le déplacement, la réactivité sa durée. Le défilement du trackpad est conservé.", "La distancia controla el recorrido y la respuesta su duración. Se conserva el desplazamiento nativo del trackpad.", "距離は1刻みの移動量、反応は移動の速さを調整します。トラックパッドの標準スクロールは維持されます。") }
    var tracking: String { text("Customize linear tracking speed", "自定义线性跟踪速度", "Lineare Zeigergeschwindigkeit", "Personnaliser la vitesse linéaire", "Personalizar velocidad lineal", "リニア追跡速度を調整") }
    var trackingHint: String { text("Applies to supported mice while acceleration is disabled. Turning this off restores the previous device speed. Trackpads are excluded.", "仅在关闭加速度时调整受支持鼠标的速度。关闭此选项会恢复设备原来的速度，触控板不受影响。", "Gilt für unterstützte Mäuse ohne Beschleunigung. Ausschalten stellt die vorherige Geschwindigkeit wieder her. Trackpads sind ausgenommen.", "Pour les souris compatibles sans accélération. Désactiver restaure la vitesse précédente. Les trackpads sont exclus.", "Para ratones compatibles sin aceleración. Desactivar restaura la velocidad anterior. No afecta al trackpad.", "加速無効時の対応マウスに適用します。オフにすると元の速度に戻ります。トラックパッドは対象外です。") }
    var unsupported: String { text("No connected mouse accepted the custom speed.", "当前没有已连接的鼠标接受自定义速度。", "Keine angeschlossene Maus hat die Geschwindigkeit übernommen.", "Aucune souris connectée n’a accepté la vitesse.", "Ningún ratón conectado aceptó la velocidad.", "設定速度を適用できたマウスがありません。") }
    var spread: String { text("Three-finger spread", "三指外展", "Drei Finger spreizen", "Écarter trois doigts", "Separar tres dedos", "3本指を広げる") }
    var spreadHint: String { text("Spread three fingers to open the selected radial menu. Lift, then point and click to choose. Esc cancels. Disabled while system three-finger dragging is on.", "三指向外展开以打开所选径向菜单。抬手后移动光标并点击选择，Esc 取消。开启系统三指拖移时此手势暂停。", "Drei Finger spreizen öffnet das Radialmenü. Danach zeigen und klicken. Esc bricht ab. Bei Drei-Finger-Ziehen pausiert die Geste.", "Écartez trois doigts pour ouvrir le menu, puis pointez et cliquez. Échap annule. Suspendu si le glissement à trois doigts est activé.", "Separa tres dedos para abrir el menú, luego apunta y haz clic. Esc cancela. Se suspende al activar el arrastre con tres dedos.", "3本指を広げてメニューを開き、指を離してからクリックで選択します。Escで取消。3本指ドラッグ有効時は停止します。") }
    var test: String { text("Scroll here to try the current settings", "在这里滚动，试用当前设置", "Hier scrollen zum Testen", "Faites défiler ici pour tester", "Desplázate aquí para probar", "ここでスクロールして試す") }
}
