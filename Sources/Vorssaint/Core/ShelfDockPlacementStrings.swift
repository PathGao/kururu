// SPDX-License-Identifier: GPL-3.0-or-later

struct ShelfDockPlacementStrings {
    var topToggle = "Keep the shelf at the top of the screen"
    var position = "Drop area position"
    var menuBar = "Below the menu bar icon"
    var topCenter = "Top center of the screen"
    var topCaption = "Appears below the system menu bar while the shelf has items or Notes is available. The shortcut still opens the shelf near the pointer."

    static func text(_ language: AppLanguage) -> Self {
        switch language {
        case .zhHans:
            return Self(topToggle: "在屏幕顶部保留暂存架", position: "接收区位置", menuBar: "菜单栏图标下方", topCenter: "屏幕顶部居中",
                        topCaption: "显示在系统菜单栏下方，有资料或已添加便条功能时保留。快捷键仍在鼠标旁展开暂存架。")
        case .de:
            return Self(topToggle: "Ablage am oberen Bildschirmrand behalten", position: "Position des Ablagebereichs", menuBar: "Unter dem Menüleistensymbol", topCenter: "Oben in der Bildschirmmitte",
                        topCaption: "Erscheint unter der Systemmenüleiste und bleibt sichtbar, solange die Ablage Inhalte enthält oder Notizen verfügbar sind. Der Kurzbefehl öffnet die Ablage weiterhin neben dem Mauszeiger.")
        case .fr:
            return Self(topToggle: "Garder l’étagère en haut de l’écran", position: "Position de la zone de dépôt", menuBar: "Sous l’icône de la barre des menus", topCenter: "En haut, au centre de l’écran",
                        topCaption: "S’affiche sous la barre des menus du système et reste visible tant que l’étagère contient des éléments ou que Notes est disponible. Le raccourci ouvre toujours l’étagère près du pointeur.")
        case .es:
            return Self(topToggle: "Mantener la bandeja en la parte superior", position: "Posición de la zona de recepción", menuBar: "Debajo del icono de la barra de menús", topCenter: "Centro superior de la pantalla",
                        topCaption: "Aparece debajo de la barra de menús del sistema y permanece mientras haya elementos en la bandeja o Notas esté disponible. El atajo sigue abriendo la bandeja junto al puntero.")
        case .ja:
            return Self(topToggle: "画面上部にシェルフを表示", position: "受け取りエリアの位置", menuBar: "メニューバーアイコンの下", topCenter: "画面上部の中央",
                        topCaption: "システムのメニューバーの下に表示され、シェルフに項目があるか、メモが利用できる間は表示を維持します。ショートカットでは引き続きポインタの近くにシェルフが開きます。")
        default:
            return Self()
        }
    }
}
