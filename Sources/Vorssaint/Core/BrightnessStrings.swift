// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import Foundation

/// Strings for the display brightness feature. Same contract as the other
/// FeatureStrings structs: memberwise init in declaration order, one static
/// per language, all in this file.
struct BrightnessFeatureStrings {
    var pageTitle: String = "Displays"
    var hubDescription: String = "Display brightness and power controls"
    var enable: String = "Control displays"
    var enableCaption: String = "Adjust built-in and external display brightness together, here and in the menu bar panel. You can also turn displays on or off."
    var externalCaption: String = "Adjusts the external display’s brightness directly when supported. Otherwise, it tries software dimming, which darkens the picture without changing the backlight."
    var noDisplays: String = "No display found."
    var displayOff: String = "Off"
    var turnOffDisplay: String = "Turn off display"
    var turnOnDisplay: String = "Turn on display"
    var lastDisplayCaption: String = "At least one display must stay on."
    var switchUnavailable: String = "Display switching is unavailable on this Mac."
    var switchFailed: String = "Could not change this display."
    var openLidToEnable: String = "Open the lid to turn on the built-in display."
    var brightnessWriteFailed: String = "Could not adjust brightness. Try again."
    var softwareDimmingNote: String = "Software dimming adjusts the picture; the display backlight stays unchanged."
    var brightnessReadbackNote: String = "Current brightness could not be read. Showing the last recorded value; it may be out of date."
    var brightnessUnknownNote: String = "Current brightness is unknown. Choose a level to set it, or reopen this page to retry reading."
    var keysToggle: String = "Brightness keys follow the pointer"
    var keysCaption: String = "The keyboard brightness keys change the display under the pointer."
    var osdToggle: String = "Show brightness percentage when adjusting"
    var osdCaption: String = "Shows the brightness percentage when you use the brightness keys or sliders."
    var keyboardLight: String = "Keyboard light"
    var keyboardLightCaption: String = "Turns the keyboard backlight on or off."
    var keyboardBrightnessShortcuts: String = "Use keyboard brightness shortcuts"
    var keyboardBrightnessDecrease: String = "Decrease keyboard brightness"
    var keyboardBrightnessIncrease: String = "Increase keyboard brightness"
}

extension FeatureStrings {
    static func brightness(_ language: AppLanguage) -> BrightnessFeatureStrings {
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

extension BrightnessFeatureStrings {
    static let enUS = BrightnessFeatureStrings()

    static let ptBR = BrightnessFeatureStrings(
        pageTitle: "Telas",
        hubDescription: "Brilho e controles de energia das telas",
        enable: "Controlar telas",
        enableCaption: "Ajuste o brilho das telas integrada e externas no mesmo lugar, aqui e no painel da barra de menus. Você também pode ligar ou desligar telas.",
        externalCaption: "Monitores externos são ajustados pelo mesmo protocolo dos botões do próprio monitor. Quando a conexão não transmite esse protocolo, como em adaptadores HDMI, o controle escurece a imagem, então o ajuste funciona de qualquer forma.",
        noDisplays: "Nenhuma tela encontrada.",
        displayOff: "Desligada",
        turnOffDisplay: "Desligar tela",
        turnOnDisplay: "Ligar tela",
        lastDisplayCaption: "Pelo menos uma tela deve continuar ligada.",
        switchUnavailable: "Não é possível ligar ou desligar telas neste Mac.",
        switchFailed: "Não foi possível alterar esta tela.",
        openLidToEnable: "Abra a tampa para ligar a tela integrada.",
        keysToggle: "Teclas de brilho seguem o ponteiro",
        keysCaption: "As teclas de brilho do teclado mudam a tela onde o ponteiro está.",
        osdToggle: "Mostrar brilho ao ajustar",
        osdCaption: "Mostra a porcentagem de brilho ao usar as teclas ou os controles de brilho.",
        keyboardLight: "Luz do teclado",
        keyboardLightCaption: "Liga ou desliga a luz do teclado.",
        keyboardBrightnessShortcuts: "Usar atalhos para o brilho do teclado",
        keyboardBrightnessDecrease: "Diminuir brilho do teclado",
        keyboardBrightnessIncrease: "Aumentar brilho do teclado"
    )

    static let tr = BrightnessFeatureStrings(
        pageTitle: "Ekranlar",
        hubDescription: "Ekran parlaklığı ve güç denetimleri",
        enable: "Ekranları denetle",
        enableCaption: "Yerleşik ve harici ekran parlaklığını buradan ve menü çubuğu panelinden aynı yerde ayarlayın. Ekranları açıp kapatabilirsiniz.",
        externalCaption: "Harici monitörler, kendi düğmelerinin kullandığı protokolle ayarlanır. Bağlantı bu protokolü taşıyamadığında, örneğin HDMI adaptörlerinde, kaydırıcı bunun yerine görüntüyü karartır; parlaklık denetimi her durumda çalışır.",
        noDisplays: "Ekran bulunamadı.",
        displayOff: "Kapalı",
        turnOffDisplay: "Ekranı kapat",
        turnOnDisplay: "Ekranı aç",
        lastDisplayCaption: "En az bir ekran açık kalmalıdır.",
        switchUnavailable: "Bu Mac’te ekran açma ve kapatma kullanılamıyor.",
        switchFailed: "Bu ekran değiştirilemedi.",
        openLidToEnable: "Yerleşik ekranı açmak için kapağı açın.",
        keysToggle: "Parlaklık tuşları imleci izler",
        keysCaption: "Klavyedeki parlaklık tuşları imlecin bulunduğu ekranı değiştirir.",
        osdToggle: "Parlaklık ayarlanırken göster",
        osdCaption: "Parlaklık tuşlarını veya kaydırıcıları kullandığınızda parlaklık yüzdesini gösterir.",
        keyboardLight: "Klavye ışığı",
        keyboardLightCaption: "Klavye ışığını açar veya kapatır.",
        keyboardBrightnessShortcuts: "Klavye parlaklığı kısayollarını kullan",
        keyboardBrightnessDecrease: "Klavye parlaklığını azalt",
        keyboardBrightnessIncrease: "Klavye parlaklığını artır"
    )

    static let ru = BrightnessFeatureStrings(
        pageTitle: "Экраны",
        hubDescription: "Яркость и питание экранов",
        enable: "Управлять экранами",
        enableCaption: "Регулируйте яркость встроенного и внешних экранов в одном месте: здесь и в панели строки меню. Здесь также можно включать и выключать экраны.",
        externalCaption: "Внешние мониторы настраиваются тем же протоколом, что и их собственные кнопки. Если соединение не передаёт этот протокол, например через адаптеры HDMI, ползунок затемняет изображение, так что регулировка работает в любом случае.",
        noDisplays: "Экраны не найдены.",
        displayOff: "Выключен",
        turnOffDisplay: "Выключить экран",
        turnOnDisplay: "Включить экран",
        lastDisplayCaption: "Хотя бы один экран должен оставаться включённым.",
        switchUnavailable: "Управление включением экранов недоступно на этом Mac.",
        switchFailed: "Не удалось изменить состояние экрана.",
        openLidToEnable: "Откройте крышку, чтобы включить встроенный экран.",
        keysToggle: "Клавиши яркости следуют за указателем",
        keysCaption: "Клавиши яркости на клавиатуре меняют экран, на котором находится указатель.",
        osdToggle: "Показывать яркость при регулировке",
        osdCaption: "Показывает яркость в процентах при использовании клавиш или ползунков яркости.",
        keyboardLight: "Подсветка клавиатуры",
        keyboardLightCaption: "Включает или выключает подсветку клавиатуры.",
        keyboardBrightnessShortcuts: "Использовать сочетания клавиш для подсветки клавиатуры",
        keyboardBrightnessDecrease: "Уменьшить яркость клавиатуры",
        keyboardBrightnessIncrease: "Увеличить яркость клавиатуры"
    )

    static let es = BrightnessFeatureStrings(
        pageTitle: "Pantallas",
        hubDescription: "Brillo y encendido de pantallas",
        enable: "Controlar las pantallas",
        enableCaption: "Ajusta el brillo de las pantallas integrada y externas en un mismo lugar, aquí y en el panel de la barra de menús. También puedes encender y apagar pantallas.",
        externalCaption: "Ajusta directamente el brillo del monitor externo cuando es compatible. De lo contrario, intenta oscurecer la imagen por software, sin cambiar la retroiluminación.",
        noDisplays: "No se encontró ninguna pantalla.",
        displayOff: "Apagada",
        turnOffDisplay: "Apagar pantalla",
        turnOnDisplay: "Encender pantalla",
        lastDisplayCaption: "Al menos una pantalla debe permanecer encendida.",
        switchUnavailable: "El encendido de pantallas no está disponible en este Mac.",
        switchFailed: "No se pudo cambiar esta pantalla.",
        openLidToEnable: "Abre la tapa para encender la pantalla integrada.",
        brightnessWriteFailed: "No se pudo ajustar el brillo. Inténtalo de nuevo.",
        softwareDimmingNote: "La atenuación por software ajusta la imagen; la retroiluminación no cambia.",
        brightnessReadbackNote: "No se pudo leer el brillo actual. Se muestra el último valor registrado; puede estar desactualizado.",
        brightnessUnknownNote: "El brillo actual es desconocido. Elige un nivel o vuelve a abrir esta página para intentar leerlo.",
        keysToggle: "Las teclas de brillo siguen al puntero",
        keysCaption: "Las teclas de brillo del teclado cambian la pantalla donde está el puntero.",
        osdToggle: "Mostrar el porcentaje de brillo al ajustar",
        osdCaption: "Muestra el porcentaje de brillo al usar las teclas o los controles de brillo.",
        keyboardLight: "Luz del teclado",
        keyboardLightCaption: "Enciende o apaga la luz del teclado.",
        keyboardBrightnessShortcuts: "Usar atajos para el brillo del teclado",
        keyboardBrightnessDecrease: "Reducir el brillo del teclado",
        keyboardBrightnessIncrease: "Aumentar el brillo del teclado"
    )

    static let de = BrightnessFeatureStrings(
        pageTitle: "Displays",
        hubDescription: "Displayhelligkeit und Stromsteuerung",
        enable: "Displays steuern",
        enableCaption: "Die Helligkeit eingebauter und externer Displays lässt sich hier und im Menüleistenpanel gemeinsam einstellen. Displays können hier auch ein- oder ausgeschaltet werden.",
        externalCaption: "Regelt die Helligkeit externer Displays direkt, wenn dies unterstützt wird. Andernfalls wird versucht, das Bild per Software abzudunkeln; die Hintergrundbeleuchtung bleibt unverändert.",
        noDisplays: "Kein Display gefunden.",
        displayOff: "Aus",
        turnOffDisplay: "Display ausschalten",
        turnOnDisplay: "Display einschalten",
        lastDisplayCaption: "Mindestens ein Display muss eingeschaltet bleiben.",
        switchUnavailable: "Die Displaysteuerung ist auf diesem Mac nicht verfügbar.",
        switchFailed: "Dieses Display konnte nicht geändert werden.",
        openLidToEnable: "Öffne den Deckel, um das integrierte Display einzuschalten.",
        brightnessWriteFailed: "Die Helligkeit konnte nicht geändert werden. Erneut versuchen.",
        softwareDimmingNote: "Software-Dimmen verändert das Bild; die Hintergrundbeleuchtung bleibt unverändert.",
        brightnessReadbackNote: "Die aktuelle Helligkeit konnte nicht gelesen werden. Der letzte erfasste Wert wird angezeigt und kann veraltet sein.",
        brightnessUnknownNote: "Die aktuelle Helligkeit ist unbekannt. Wähle einen Wert oder öffne diese Seite erneut, um das Lesen zu wiederholen.",
        keysToggle: "Helligkeitstasten folgen dem Zeiger",
        keysCaption: "Die Helligkeitstasten der Tastatur ändern das Display, auf dem der Zeiger steht.",
        osdToggle: "Helligkeit beim Ändern in Prozent anzeigen",
        osdCaption: "Zeigt den Helligkeitswert in Prozent bei Verwendung der Helligkeitstasten oder Regler.",
        keyboardLight: "Tastaturbeleuchtung",
        keyboardLightCaption: "Schaltet die Tastaturbeleuchtung ein oder aus.",
        keyboardBrightnessShortcuts: "Kurzbefehle für die Tastaturhelligkeit verwenden",
        keyboardBrightnessDecrease: "Tastaturhelligkeit verringern",
        keyboardBrightnessIncrease: "Tastaturhelligkeit erhöhen"
    )

    static let fr = BrightnessFeatureStrings(
        pageTitle: "Écrans",
        hubDescription: "Luminosité et alimentation des écrans",
        enable: "Contrôler les écrans",
        enableCaption: "Réglez la luminosité de l’écran intégré et des écrans externes au même endroit, ici et dans le panneau de la barre des menus. Vous pouvez aussi allumer ou éteindre les écrans.",
        externalCaption: "Règle directement la luminosité de l’écran externe lorsque cela est possible. Sinon, tente d’assombrir l’image par logiciel, sans modifier le rétroéclairage.",
        noDisplays: "Aucun écran détecté.",
        displayOff: "Éteint",
        turnOffDisplay: "Éteindre l’écran",
        turnOnDisplay: "Allumer l’écran",
        lastDisplayCaption: "Au moins un écran doit rester allumé.",
        switchUnavailable: "Le contrôle d’alimentation des écrans n’est pas disponible sur ce Mac.",
        switchFailed: "Impossible de modifier cet écran.",
        openLidToEnable: "Ouvrez le couvercle pour allumer l’écran intégré.",
        brightnessWriteFailed: "Impossible de régler la luminosité. Réessayez.",
        softwareDimmingNote: "L’atténuation logicielle agit sur l’image ; le rétroéclairage reste inchangé.",
        brightnessReadbackNote: "La luminosité actuelle n’a pas pu être lue. La dernière valeur enregistrée est affichée et peut être périmée.",
        brightnessUnknownNote: "La luminosité actuelle est inconnue. Choisissez un niveau ou rouvrez cette page pour réessayer la lecture.",
        keysToggle: "Les touches de luminosité suivent le pointeur",
        keysCaption: "Les touches de luminosité du clavier règlent l’écran où se trouve le pointeur.",
        osdToggle: "Afficher le pourcentage de luminosité pendant le réglage",
        osdCaption: "Affiche le pourcentage de luminosité avec les touches ou les curseurs de luminosité.",
        keyboardLight: "Éclairage du clavier",
        keyboardLightCaption: "Allume ou éteint l’éclairage du clavier.",
        keyboardBrightnessShortcuts: "Utiliser les raccourcis de luminosité du clavier",
        keyboardBrightnessDecrease: "Réduire la luminosité du clavier",
        keyboardBrightnessIncrease: "Augmenter la luminosité du clavier"
    )

    static let it = BrightnessFeatureStrings(
        pageTitle: "Schermi",
        hubDescription: "Luminosità e accensione degli schermi",
        enable: "Controlla gli schermi",
        enableCaption: "Regola la luminosità degli schermi integrati ed esterni nello stesso posto, qui e nel pannello della barra dei menu. Puoi anche accendere e spegnere gli schermi.",
        externalCaption: "I monitor esterni vengono regolati con lo stesso protocollo dei loro pulsanti. Quando il collegamento non lo trasmette, come con gli adattatori HDMI, il cursore scurisce l’immagine, quindi la regolazione funziona comunque.",
        noDisplays: "Nessuno schermo trovato.",
        displayOff: "Spento",
        turnOffDisplay: "Spegni schermo",
        turnOnDisplay: "Accendi schermo",
        lastDisplayCaption: "Almeno uno schermo deve rimanere acceso.",
        switchUnavailable: "Il controllo di accensione degli schermi non è disponibile su questo Mac.",
        switchFailed: "Non è stato possibile modificare questo schermo.",
        openLidToEnable: "Apri il coperchio per accendere lo schermo integrato.",
        keysToggle: "I tasti di luminosità seguono il puntatore",
        keysCaption: "I tasti di luminosità della tastiera regolano lo schermo dove si trova il puntatore.",
        osdToggle: "Mostra la luminosità durante la regolazione",
        osdCaption: "Mostra la percentuale di luminosità quando usi i tasti o i cursori della luminosità.",
        keyboardLight: "Illuminazione tastiera",
        keyboardLightCaption: "Accende o spegne l’illuminazione della tastiera.",
        keyboardBrightnessShortcuts: "Usa le scorciatoie per la luminosità della tastiera",
        keyboardBrightnessDecrease: "Riduci luminosità tastiera",
        keyboardBrightnessIncrease: "Aumenta luminosità tastiera"
    )

    static let ja = BrightnessFeatureStrings(
        pageTitle: "ディスプレイ",
        hubDescription: "ディスプレイの明るさと電源",
        enable: "ディスプレイを操作",
        enableCaption: "こことメニューバーパネルで、内蔵・外部ディスプレイの明るさをまとめて調整できます。ディスプレイの電源も切り替えられます。",
        externalCaption: "対応している場合は外部ディスプレイの明るさを直接調整します。対応していない場合はソフトウェアで画面を暗くすることを試みます。バックライトは変更しません。",
        noDisplays: "ディスプレイが見つかりません。",
        displayOff: "オフ",
        turnOffDisplay: "ディスプレイの電源を切る",
        turnOnDisplay: "ディスプレイの電源を入れる",
        lastDisplayCaption: "少なくとも1台のディスプレイをオンのままにしてください。",
        switchUnavailable: "このMacではディスプレイの切り替えを利用できません。",
        switchFailed: "このディスプレイを切り替えられませんでした。",
        openLidToEnable: "内蔵ディスプレイをオンにするには、蓋を開いてください。",
        brightnessWriteFailed: "明るさを変更できませんでした。再試行してください。",
        softwareDimmingNote: "ソフトウェアで映像を暗くします。ディスプレイのバックライトは変わりません。",
        brightnessReadbackNote: "現在の明るさを読み取れませんでした。前回の記録値を表示しているため、実際の明るさと異なる場合があります。",
        brightnessUnknownNote: "現在の明るさは不明です。値を指定するか、このページを開き直して再度読み取ってください。",
        keysToggle: "輝度キーはポインタに従う",
        keysCaption: "キーボードの輝度キーが、ポインタのあるディスプレイを調整します。",
        osdToggle: "調整時に明るさの割合を表示",
        osdCaption: "輝度キーまたはスライダを使うと、明るさをパーセントで表示します。",
        keyboardLight: "キーボードのバックライト",
        keyboardLightCaption: "キーボードのバックライトをオンまたはオフにします。",
        keyboardBrightnessShortcuts: "キーボードの明るさのショートカットを使用",
        keyboardBrightnessDecrease: "キーボードの明るさを下げる",
        keyboardBrightnessIncrease: "キーボードの明るさを上げる"
    )

    static let ko = BrightnessFeatureStrings(
        pageTitle: "디스플레이",
        hubDescription: "디스플레이 밝기 및 전원 제어",
        enable: "디스플레이 제어",
        enableCaption: "여기와 메뉴 막대 패널에서 내장 및 외부 디스플레이 밝기를 한곳에서 조절합니다. 디스플레이 전원을 켜거나 끌 수도 있습니다.",
        externalCaption: "외부 모니터는 자체 버튼과 동일한 프로토콜로 조절됩니다. HDMI 어댑터처럼 연결이 이 프로토콜을 지원하지 않으면 슬라이더가 대신 화면을 어둡게 하므로 어느 경우든 밝기를 조절할 수 있습니다.",
        noDisplays: "디스플레이를 찾을 수 없습니다.",
        displayOff: "꺼짐",
        turnOffDisplay: "디스플레이 끄기",
        turnOnDisplay: "디스플레이 켜기",
        lastDisplayCaption: "최소 한 대의 디스플레이는 켜져 있어야 합니다.",
        switchUnavailable: "이 Mac에서는 디스플레이 전원 제어를 사용할 수 없습니다.",
        switchFailed: "이 디스플레이를 변경할 수 없습니다.",
        openLidToEnable: "내장 디스플레이를 켜려면 덮개를 여세요.",
        keysToggle: "밝기 키가 포인터를 따라감",
        keysCaption: "키보드의 밝기 키로 포인터가 있는 디스플레이를 조절합니다.",
        osdToggle: "밝기 조절 시 표시",
        osdCaption: "밝기 키나 슬라이더를 사용할 때 밝기를 백분율로 표시합니다.",
        keyboardLight: "키보드 백라이트",
        keyboardLightCaption: "키보드 백라이트를 켜거나 끕니다.",
        keyboardBrightnessShortcuts: "키보드 밝기 단축키 사용",
        keyboardBrightnessDecrease: "키보드 밝기 낮추기",
        keyboardBrightnessIncrease: "키보드 밝기 높이기"
    )

    static let zhHans = BrightnessFeatureStrings(
        pageTitle: "显示器",
        hubDescription: "显示器亮度与开关",
        enable: "控制显示器",
        enableCaption: "在这里和菜单栏面板中统一调节内置屏与外接屏的亮度，也可控制显示器开关。",
        externalCaption: "优先直接调节外接显示器的亮度。不支持时，尝试通过软件调暗画面，显示器背光不变。",
        noDisplays: "未找到显示器。",
        displayOff: "已关闭",
        turnOffDisplay: "关闭显示器",
        turnOnDisplay: "打开显示器",
        lastDisplayCaption: "至少要保留一台显示器开启。",
        switchUnavailable: "此 Mac 不支持显示器开关。",
        switchFailed: "无法更改这台显示器。",
        openLidToEnable: "请打开 Mac 盖子后再启用内置屏幕。",
        brightnessWriteFailed: "无法调整亮度，请重试。",
        softwareDimmingNote: "软件调暗只调整画面，显示器背光保持不变。",
        brightnessReadbackNote: "本次未能读取当前亮度，显示上次记录值，可能已过时。",
        brightnessUnknownNote: "当前亮度未知。可选择数值设定亮度，或重新打开此页面重试读取。",
        keysToggle: "亮度键跟随指针",
        keysCaption: "键盘上的亮度键调节指针所在的显示器。",
        osdToggle: "调节亮度时显示百分比",
        osdCaption: "使用亮度键或滑块时显示亮度百分比。",
        keyboardLight: "键盘背光",
        keyboardLightCaption: "打开或关闭键盘背光。",
        keyboardBrightnessShortcuts: "使用键盘亮度快捷键",
        keyboardBrightnessDecrease: "降低键盘亮度",
        keyboardBrightnessIncrease: "提高键盘亮度"
    )

    static let zhTW = BrightnessFeatureStrings(
        pageTitle: "顯示器",
        hubDescription: "顯示器亮度與開關",
        enable: "控制顯示器",
        enableCaption: "在這裡和選單列面板中統一調整內建與外接螢幕的亮度，也可控制顯示器開關。",
        externalCaption: "優先直接調整外接顯示器的亮度。不支援時，嘗試透過軟體調暗畫面，顯示器背光不變。",
        noDisplays: "找不到顯示器。",
        displayOff: "已關閉",
        turnOffDisplay: "關閉顯示器",
        turnOnDisplay: "開啟顯示器",
        lastDisplayCaption: "至少要保留一台顯示器開啟。",
        switchUnavailable: "此 Mac 不支援顯示器開關。",
        switchFailed: "無法更改這台顯示器。",
        openLidToEnable: "請打開 Mac 上蓋後再啟用內建螢幕。",
        keysToggle: "亮度鍵跟隨指標",
        keysCaption: "鍵盤上的亮度鍵調整指標所在的顯示器。",
        osdToggle: "調整亮度時顯示百分比",
        osdCaption: "使用亮度鍵或滑桿時顯示亮度百分比。",
        keyboardLight: "鍵盤背光",
        keyboardLightCaption: "開啟或關閉鍵盤背光。",
        keyboardBrightnessShortcuts: "使用鍵盤亮度快捷鍵",
        keyboardBrightnessDecrease: "降低鍵盤亮度",
        keyboardBrightnessIncrease: "提高鍵盤亮度"
    )

    static let zhHK = BrightnessFeatureStrings(
        pageTitle: "顯示器",
        hubDescription: "顯示器亮度與開關",
        enable: "控制顯示器",
        enableCaption: "在這裏和選單列面板中統一調整內置與外接螢幕的亮度，也可控制顯示器開關。",
        externalCaption: "優先直接調整外接顯示器的亮度。不支援時，嘗試透過軟體調暗畫面，顯示器背光不變。",
        noDisplays: "找不到顯示器。",
        displayOff: "已關閉",
        turnOffDisplay: "關閉顯示器",
        turnOnDisplay: "開啟顯示器",
        lastDisplayCaption: "至少要保留一台顯示器開啟。",
        switchUnavailable: "此 Mac 不支援顯示器開關。",
        switchFailed: "無法更改這部顯示器。",
        openLidToEnable: "請打開 Mac 上蓋後再啟用內置顯示器。",
        keysToggle: "亮度鍵跟隨指標",
        keysCaption: "鍵盤上的亮度鍵調整指標所在的顯示器。",
        osdToggle: "調整亮度時顯示百分比",
        osdCaption: "使用亮度鍵或滑桿時顯示亮度百分比。",
        keyboardLight: "鍵盤背光",
        keyboardLightCaption: "開啟或關閉鍵盤背光。",
        keyboardBrightnessShortcuts: "使用鍵盤亮度快捷鍵",
        keyboardBrightnessDecrease: "降低鍵盤亮度",
        keyboardBrightnessIncrease: "提高鍵盤亮度"
    )
}
