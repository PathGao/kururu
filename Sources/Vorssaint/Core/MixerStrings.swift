// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import Foundation

/// Localized strings for the volume mixer.
struct MixerFeatureStrings {
    var pageTitle: String = "Volume mixer"
    var hideInactiveApps: String = "Hide inactive apps"
    var empty: String = "Apps that use audio show up here"
    var unavailable: String = "Available on macOS 14.4 and later"
    var permissionBody: String = "To adjust per-app volume, allow “Screen & System Audio Recording” in System Settings. Audio is never recorded."
    var resetTooltip: String = "Reset to 100%"
    var outputDefault: String = "Default"
    var outputCurrent: String = "current"
    var outputUnavailable: String = "Output unavailable"
    var outputFallback: String = "Using default until this device returns."
    var bypassedCaption: String = "This app manages its own audio."
    var outputTooltip: String = "Choose output"
    var systemOutputTitle: String = "Output"
    var systemOutputNoDevices: String = "No outputs found"
    var systemOutputTooltip: String = "Choose system output"
    var systemOutputErrorFormat: String = "Could not switch: %@"
    var soundEffectsOutputTitle: String = "System sounds"
    var soundEffectsOutputTooltip: String = "Choose where alerts and sound effects play"
    var lowerOnHeadphonesDisconnect: String = "Lower volume when headphones disconnect"
    var lowerOnHeadphonesDisconnectCaption: String = "Adjusts output when wired or Bluetooth headphones disconnect."
    var headphonesDisconnectVolume: String = "Volume after disconnect"
    var inputTitle: String = "Microphone"
    var inputNoDevices: String = "No microphones found"
    var inputUnavailable: String = "Microphone unavailable"
    var inputFallback: String = "Using default until this microphone returns."
    var inputTooltip: String = "Choose microphone"
    var inputErrorFormat: String = "Could not switch: %@"
    var visibleApps: String = "Apps in the list"
    var allShown: String = "All"
    var hiddenCountLabel: String = "Hidden"
    var hideFromList: String = "Hide from the list"
}

extension FeatureStrings {
    static func mixer(_ language: AppLanguage) -> MixerFeatureStrings {
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

extension MixerFeatureStrings {
    static let enUS = MixerFeatureStrings()

    static let ptBR = MixerFeatureStrings(
        pageTitle: "Mixer de volume",
        hideInactiveApps: "Ocultar apps inativos",
        empty: "Apps que usam áudio aparecem aqui",
        unavailable: "Disponível a partir do macOS 14.4",
        permissionBody: "Para ajustar o volume por app, permita “Gravação de Tela e Áudio do Sistema” nos Ajustes do Sistema. O áudio nunca é gravado.",
        resetTooltip: "Voltar para 100%",
        outputDefault: "Padrão",
        outputCurrent: "atual",
        outputUnavailable: "Saída indisponível",
        outputFallback: "Usando o padrão até esse dispositivo voltar.",
        bypassedCaption: "Este app controla o próprio áudio.",
        outputTooltip: "Escolher saída",
        systemOutputTitle: "Saída",
        systemOutputNoDevices: "Nenhuma saída encontrada",
        systemOutputTooltip: "Escolher saída do sistema",
        systemOutputErrorFormat: "Não foi possível trocar: %@",
        soundEffectsOutputTitle: "Sons do sistema",
        soundEffectsOutputTooltip: "Escolher onde alertas e efeitos sonoros tocam",
        lowerOnHeadphonesDisconnect: "Baixar volume ao desconectar fones",
        lowerOnHeadphonesDisconnectCaption: "Ajusta a saída quando fones com fio ou Bluetooth desconectam.",
        headphonesDisconnectVolume: "Volume ao desconectar",
        inputTitle: "Microfone",
        inputNoDevices: "Nenhum microfone encontrado",
        inputUnavailable: "Microfone indisponível",
        inputFallback: "Usando o padrão até esse microfone voltar.",
        inputTooltip: "Escolher microfone",
        inputErrorFormat: "Não foi possível trocar: %@",
        visibleApps: "Apps na lista",
        allShown: "Todos",
        hiddenCountLabel: "Escondidos",
        hideFromList: "Esconder da lista"
    )

    static let tr = MixerFeatureStrings(
        pageTitle: "Ses mikseri",
        hideInactiveApps: "Etkin olmayan uygulamaları gizle",
        empty: "Ses kullanan uygulamalar burada görünür",
        unavailable: "macOS 14.4 ve sonrasında kullanılabilir",
        permissionBody: "Uygulama başına ses düzeyini ayarlamak için Sistem Ayarları’nda “Ekran ve Sistem Sesi Kaydı”na izin ver. Ses hiçbir zaman kaydedilmez.",
        resetTooltip: "%100’e sıfırla",
        outputDefault: "Varsayılan",
        outputCurrent: "geçerli",
        outputUnavailable: "Çıkış kullanılamıyor",
        outputFallback: "Bu aygıt geri dönene kadar varsayılan kullanılıyor.",
        bypassedCaption: "Bu uygulama sesini kendisi yönetir.",
        outputTooltip: "Çıkış seç",
        systemOutputTitle: "Çıkış",
        systemOutputNoDevices: "Çıkış bulunamadı",
        systemOutputTooltip: "Sistem çıkışını seç",
        systemOutputErrorFormat: "Geçiş yapılamadı: %@",
        soundEffectsOutputTitle: "Sistem sesleri",
        soundEffectsOutputTooltip: "Uyarıların ve ses efektlerinin çalacağı çıkışı seç",
        lowerOnHeadphonesDisconnect: "Kulaklık bağlantısı kesilince sesi düşür",
        lowerOnHeadphonesDisconnectCaption: "Kablolu veya Bluetooth kulaklık bağlantısı kesildiğinde çıkışı seçilen seviyeye ayarlar.",
        headphonesDisconnectVolume: "Bağlantı kesilince ses",
        inputTitle: "Mikrofon",
        inputNoDevices: "Mikrofon bulunamadı",
        inputUnavailable: "Mikrofon kullanılamıyor",
        inputFallback: "Bu mikrofon geri dönene kadar varsayılan kullanılıyor.",
        inputTooltip: "Mikrofon seç",
        inputErrorFormat: "Geçiş yapılamadı: %@",
        visibleApps: "Listedeki uygulamalar",
        allShown: "Tümü",
        hiddenCountLabel: "Gizli",
        hideFromList: "Listeden gizle"
    )

    static let ru = MixerFeatureStrings(
        pageTitle: "Микшер громкости",
        hideInactiveApps: "Скрывать неактивные приложения",
        empty: "Здесь появятся приложения, которые воспроизводят звук",
        unavailable: "Доступно в macOS 14.4 и новее",
        permissionBody: "Чтобы регулировать громкость по приложениям, разрешите «Запись экрана и системного аудио» в Системных настройках. Аудио никогда не записывается.",
        resetTooltip: "Сбросить на 100%",
        outputDefault: "По умолчанию",
        outputCurrent: "текущий",
        outputUnavailable: "Выход недоступен",
        outputFallback: "Используется выход по умолчанию, пока это устройство не вернётся.",
        bypassedCaption: "Это приложение само управляет своим звуком.",
        outputTooltip: "Выбрать выход",
        systemOutputTitle: "Выход",
        systemOutputNoDevices: "Выходы не найдены",
        systemOutputTooltip: "Выбрать системный выход",
        systemOutputErrorFormat: "Не удалось переключить: %@",
        soundEffectsOutputTitle: "Системные звуки",
        soundEffectsOutputTooltip: "Выбрать устройство для оповещений и звуковых эффектов",
        lowerOnHeadphonesDisconnect: "Снижать громкость при отключении наушников",
        lowerOnHeadphonesDisconnectCaption: "Меняет громкость выхода при отключении проводных или Bluetooth-наушников.",
        headphonesDisconnectVolume: "Громкость после отключения",
        inputTitle: "Микрофон",
        inputNoDevices: "Микрофоны не найдены",
        inputUnavailable: "Микрофон недоступен",
        inputFallback: "Используется значение по умолчанию, пока этот микрофон не вернётся.",
        inputTooltip: "Выбрать микрофон",
        inputErrorFormat: "Не удалось переключить: %@",
        visibleApps: "Приложения в списке",
        allShown: "Все",
        hiddenCountLabel: "Скрыто",
        hideFromList: "Скрыть из списка"
    )

    static let es = MixerFeatureStrings(
        pageTitle: "Mezclador de volumen",
        hideInactiveApps: "Ocultar apps inactivas",
        empty: "Las apps que usan audio aparecen aquí",
        unavailable: "Disponible en macOS 14.4 y posteriores",
        permissionBody: "Para ajustar el volumen por app, permite “Grabación de pantalla y audio del sistema” en Ajustes del Sistema. El audio nunca se graba.",
        resetTooltip: "Restablecer al 100 %",
        outputDefault: "Predeterminado",
        outputCurrent: "actual",
        outputUnavailable: "Salida no disponible",
        outputFallback: "Usando la predeterminada hasta que vuelva este dispositivo.",
        bypassedCaption: "Esta app gestiona su propio audio.",
        outputTooltip: "Elegir salida",
        systemOutputTitle: "Salida",
        systemOutputNoDevices: "No se encontró ninguna salida",
        systemOutputTooltip: "Elegir salida del sistema",
        systemOutputErrorFormat: "No se pudo cambiar: %@",
        soundEffectsOutputTitle: "Sonidos del sistema",
        soundEffectsOutputTooltip: "Elegir dónde se reproducen los avisos y efectos de sonido",
        lowerOnHeadphonesDisconnect: "Bajar volumen al desconectar auriculares",
        lowerOnHeadphonesDisconnectCaption: "Ajusta la salida cuando se desconectan auriculares con cable o Bluetooth.",
        headphonesDisconnectVolume: "Volumen al desconectar",
        inputTitle: "Micrófono",
        inputNoDevices: "No se encontró ningún micrófono",
        inputUnavailable: "Micrófono no disponible",
        inputFallback: "Usando el predeterminado hasta que vuelva este micrófono.",
        inputTooltip: "Elegir micrófono",
        inputErrorFormat: "No se pudo cambiar: %@",
        visibleApps: "Apps en la lista",
        allShown: "Todas",
        hiddenCountLabel: "Ocultas",
        hideFromList: "Ocultar de la lista"
    )

    static let de = MixerFeatureStrings(
        pageTitle: "Lautstärkemixer",
        hideInactiveApps: "Inaktive Apps ausblenden",
        empty: "Apps, die Audio nutzen, erscheinen hier",
        unavailable: "Verfügbar ab macOS 14.4",
        permissionBody: "Um die Lautstärke je App anzupassen, erlaube „Aufnahme von Bildschirm und Systemaudio“ in den Systemeinstellungen. Audio wird nie aufgenommen.",
        resetTooltip: "Auf 100 % zurücksetzen",
        outputDefault: "Standard",
        outputCurrent: "aktuell",
        outputUnavailable: "Ausgabe nicht verfügbar",
        outputFallback: "Standard wird verwendet, bis dieses Gerät zurück ist.",
        bypassedCaption: "Diese App verwaltet ihr Audio selbst.",
        outputTooltip: "Ausgabe wählen",
        systemOutputTitle: "Ausgabe",
        systemOutputNoDevices: "Keine Ausgabe gefunden",
        systemOutputTooltip: "Systemausgabe wählen",
        systemOutputErrorFormat: "Wechsel fehlgeschlagen: %@",
        soundEffectsOutputTitle: "Systemtöne",
        soundEffectsOutputTooltip: "Auswählen, wo Hinweise und Toneffekte wiedergegeben werden",
        lowerOnHeadphonesDisconnect: "Lautstärke senken, wenn Kopfhörer getrennt werden",
        lowerOnHeadphonesDisconnectCaption: "Passt die Ausgabe an, wenn kabelgebundene oder Bluetooth-Kopfhörer getrennt werden.",
        headphonesDisconnectVolume: "Lautstärke nach Trennung",
        inputTitle: "Mikrofon",
        inputNoDevices: "Kein Mikrofon gefunden",
        inputUnavailable: "Mikrofon nicht verfügbar",
        inputFallback: "Standard wird verwendet, bis dieses Mikrofon zurück ist.",
        inputTooltip: "Mikrofon wählen",
        inputErrorFormat: "Wechsel fehlgeschlagen: %@",
        visibleApps: "Apps in der Liste",
        allShown: "Alle",
        hiddenCountLabel: "Ausgeblendet",
        hideFromList: "Aus der Liste ausblenden"
    )

    static let fr = MixerFeatureStrings(
        pageTitle: "Mélangeur de volume",
        hideInactiveApps: "Masquer les apps inactives",
        empty: "Les apps qui utilisent l’audio apparaissent ici",
        unavailable: "Disponible à partir de macOS 14.4",
        permissionBody: "Pour régler le volume par app, autorisez «\u{00A0}Enregistrement de l’écran et de l’audio du système\u{00A0}» dans les Réglages Système. L’audio n’est jamais enregistré.",
        resetTooltip: "Rétablir à 100 %",
        outputDefault: "Par défaut",
        outputCurrent: "actuelle",
        outputUnavailable: "Sortie indisponible",
        outputFallback: "Utilise la sortie par défaut jusqu’au retour de cet appareil.",
        bypassedCaption: "Cette app gère elle-même son audio.",
        outputTooltip: "Choisir la sortie",
        systemOutputTitle: "Sortie",
        systemOutputNoDevices: "Aucune sortie trouvée",
        systemOutputTooltip: "Choisir la sortie système",
        systemOutputErrorFormat: "Impossible de changer\u{00A0}: %@",
        soundEffectsOutputTitle: "Sons du système",
        soundEffectsOutputTooltip: "Choisir où sont diffusés les alertes et effets sonores",
        lowerOnHeadphonesDisconnect: "Baisser le volume quand les écouteurs se déconnectent",
        lowerOnHeadphonesDisconnectCaption: "Ajuste la sortie quand des écouteurs filaires ou Bluetooth se déconnectent.",
        headphonesDisconnectVolume: "Volume après déconnexion",
        inputTitle: "Micro",
        inputNoDevices: "Aucun micro trouvé",
        inputUnavailable: "Micro indisponible",
        inputFallback: "Utilise le micro par défaut jusqu’au retour de celui-ci.",
        inputTooltip: "Choisir le micro",
        inputErrorFormat: "Impossible de changer\u{00A0}: %@",
        visibleApps: "Apps dans la liste",
        allShown: "Toutes",
        hiddenCountLabel: "Masquées",
        hideFromList: "Masquer de la liste"
    )

    static let it = MixerFeatureStrings(
        pageTitle: "Mixer del volume",
        hideInactiveApps: "Nascondi le app inattive",
        empty: "Le app che usano l’audio compaiono qui",
        unavailable: "Disponibile su macOS 14.4 e successivi",
        permissionBody: "Per regolare il volume per ogni app, consenti “Registrazione schermo e audio di sistema” in Impostazioni di Sistema. L’audio non viene mai registrato.",
        resetTooltip: "Ripristina al 100%",
        outputDefault: "Predefinita",
        outputCurrent: "attuale",
        outputUnavailable: "Uscita non disponibile",
        outputFallback: "Uso l’uscita predefinita finché questo dispositivo non torna.",
        bypassedCaption: "Questa app gestisce da sé il proprio audio.",
        outputTooltip: "Scegli uscita",
        systemOutputTitle: "Uscita",
        systemOutputNoDevices: "Nessuna uscita trovata",
        systemOutputTooltip: "Scegli uscita di sistema",
        systemOutputErrorFormat: "Impossibile cambiare: %@",
        soundEffectsOutputTitle: "Suoni di sistema",
        soundEffectsOutputTooltip: "Scegli dove riprodurre avvisi ed effetti sonori",
        lowerOnHeadphonesDisconnect: "Abbassa il volume quando le cuffie si scollegano",
        lowerOnHeadphonesDisconnectCaption: "Regola l’uscita quando cuffie cablate o Bluetooth si scollegano.",
        headphonesDisconnectVolume: "Volume dopo disconnessione",
        inputTitle: "Microfono",
        inputNoDevices: "Nessun microfono trovato",
        inputUnavailable: "Microfono non disponibile",
        inputFallback: "Uso il predefinito finché questo microfono non torna.",
        inputTooltip: "Scegli microfono",
        inputErrorFormat: "Impossibile cambiare: %@",
        visibleApps: "App nell’elenco",
        allShown: "Tutte",
        hiddenCountLabel: "Nascoste",
        hideFromList: "Nascondi dall’elenco"
    )

    static let ja = MixerFeatureStrings(
        pageTitle: "音量ミキサー",
        hideInactiveApps: "非アクティブなアプリを隠す",
        empty: "オーディオを使用するアプリがここに表示されます",
        unavailable: "macOS 14.4 以降で利用できます",
        permissionBody: "アプリごとの音量を調整するには、システム設定で「画面とシステムオーディオ収録」を許可してください。オーディオが記録されることはありません。",
        resetTooltip: "100% にリセット",
        outputDefault: "デフォルト",
        outputCurrent: "現在",
        outputUnavailable: "出力を利用できません",
        outputFallback: "このデバイスが戻るまでデフォルトを使用します。",
        bypassedCaption: "このアプリは自身でオーディオを管理します。",
        outputTooltip: "出力を選択",
        systemOutputTitle: "出力",
        systemOutputNoDevices: "出力が見つかりません",
        systemOutputTooltip: "システム出力を選択",
        systemOutputErrorFormat: "変更できませんでした: %@",
        soundEffectsOutputTitle: "システムサウンド",
        soundEffectsOutputTooltip: "通知音とサウンドエフェクトの出力先を選択",
        lowerOnHeadphonesDisconnect: "ヘッドフォン切断時に音量を下げる",
        lowerOnHeadphonesDisconnectCaption: "有線またはBluetoothヘッドフォンが切断されたら出力を調整します。",
        headphonesDisconnectVolume: "切断後の音量",
        inputTitle: "マイク",
        inputNoDevices: "マイクが見つかりません",
        inputUnavailable: "マイクを利用できません",
        inputFallback: "このマイクが戻るまでデフォルトを使用します。",
        inputTooltip: "マイクを選択",
        inputErrorFormat: "変更できませんでした: %@",
        visibleApps: "リストに表示するアプリ",
        allShown: "すべて",
        hiddenCountLabel: "非表示",
        hideFromList: "リストから隠す"
    )

    static let ko = MixerFeatureStrings(
        pageTitle: "볼륨 믹서",
        hideInactiveApps: "비활성 앱 숨기기",
        empty: "오디오를 사용하는 앱이 여기에 표시됩니다",
        unavailable: "macOS 14.4 이상에서 사용할 수 있습니다",
        permissionBody: "앱별 볼륨을 조절하려면 시스템 설정에서 ‘화면 및 시스템 오디오 녹음’을 허용하세요. 오디오는 기록되지 않습니다.",
        resetTooltip: "100%로 재설정",
        outputDefault: "기본값",
        outputCurrent: "현재",
        outputUnavailable: "출력을 사용할 수 없습니다",
        outputFallback: "이 기기가 돌아올 때까지 기본 출력을 사용합니다.",
        bypassedCaption: "이 앱은 자체적으로 오디오를 관리합니다.",
        outputTooltip: "출력 선택",
        systemOutputTitle: "출력",
        systemOutputNoDevices: "출력을 찾을 수 없습니다",
        systemOutputTooltip: "시스템 출력 선택",
        systemOutputErrorFormat: "변경하지 못했습니다: %@",
        soundEffectsOutputTitle: "시스템 사운드",
        soundEffectsOutputTooltip: "알림 및 사운드 효과를 재생할 출력 선택",
        lowerOnHeadphonesDisconnect: "헤드폰 연결 해제 시 볼륨 낮추기",
        lowerOnHeadphonesDisconnectCaption: "유선 또는 Bluetooth 헤드폰이 연결 해제되면 출력을 조정합니다.",
        headphonesDisconnectVolume: "연결 해제 후 볼륨",
        inputTitle: "마이크",
        inputNoDevices: "마이크를 찾을 수 없습니다",
        inputUnavailable: "마이크를 사용할 수 없습니다",
        inputFallback: "이 마이크가 돌아올 때까지 기본 입력을 사용합니다.",
        inputTooltip: "마이크 선택",
        inputErrorFormat: "변경하지 못했습니다: %@",
        visibleApps: "목록에 표시할 앱",
        allShown: "모두",
        hiddenCountLabel: "숨김",
        hideFromList: "목록에서 숨기기"
    )

    static let zhHans = MixerFeatureStrings(
        pageTitle: "音量混音器",
        hideInactiveApps: "隐藏不活跃的 App",
        empty: "使用音频的 App 会显示在这里",
        unavailable: "需 macOS 14.4 及更高版本",
        permissionBody: "若要调整各 App 的音量，请在“系统设置”中允许“屏幕与系统音频录制”。绝不会录制音频。",
        resetTooltip: "重置为 100%",
        outputDefault: "默认",
        outputCurrent: "当前",
        outputUnavailable: "输出不可用",
        outputFallback: "在此设备恢复前使用默认输出。",
        bypassedCaption: "此 App 自行管理音频。",
        outputTooltip: "选择输出",
        systemOutputTitle: "输出",
        systemOutputNoDevices: "未找到输出设备",
        systemOutputTooltip: "选择系统输出",
        systemOutputErrorFormat: "无法切换：%@",
        soundEffectsOutputTitle: "系统声音",
        soundEffectsOutputTooltip: "选择提醒和音效的播放设备",
        lowerOnHeadphonesDisconnect: "耳机断开时降低音量",
        lowerOnHeadphonesDisconnectCaption: "有线或蓝牙耳机断开时，自动调整输出音量。",
        headphonesDisconnectVolume: "断开后的音量",
        inputTitle: "麦克风",
        inputNoDevices: "未找到麦克风",
        inputUnavailable: "麦克风不可用",
        inputFallback: "在此麦克风恢复前使用默认输入。",
        inputTooltip: "选择麦克风",
        inputErrorFormat: "无法切换：%@",
        visibleApps: "列表中的 App",
        allShown: "全部",
        hiddenCountLabel: "已隐藏",
        hideFromList: "从列表中隐藏"
    )

    static let zhTW = MixerFeatureStrings(
        pageTitle: "音量混音器",
        hideInactiveApps: "隱藏非活躍的 App",
        empty: "正在使用音訊的 App 會顯示在這裡",
        unavailable: "需要 macOS 14.4 及更高版本",
        permissionBody: "若要調整各 App 的音量，請在「系統設定」中允許「螢幕與系統音訊錄製」。絕不會錄製音訊。",
        resetTooltip: "重設為 100%",
        outputDefault: "預設",
        outputCurrent: "目前",
        outputUnavailable: "輸出不可用",
        outputFallback: "此裝置重新可用前，使用預設輸出。",
        bypassedCaption: "此 App 自行管理音訊。",
        outputTooltip: "選擇輸出",
        systemOutputTitle: "輸出",
        systemOutputNoDevices: "找不到輸出裝置",
        systemOutputTooltip: "選擇系統輸出",
        systemOutputErrorFormat: "無法切換：%@",
        soundEffectsOutputTitle: "系統聲音",
        soundEffectsOutputTooltip: "選擇提示音與音效的播放裝置",
        lowerOnHeadphonesDisconnect: "耳機中斷連線時降低音量",
        lowerOnHeadphonesDisconnectCaption: "有線或藍牙耳機中斷連線時，自動調整輸出音量。",
        headphonesDisconnectVolume: "中斷連線後的音量",
        inputTitle: "麥克風",
        inputNoDevices: "找不到麥克風",
        inputUnavailable: "麥克風不可用",
        inputFallback: "此麥克風重新可用前，使用預設輸入。",
        inputTooltip: "選擇麥克風",
        inputErrorFormat: "無法切換：%@",
        visibleApps: "列表中的 App",
        allShown: "全部",
        hiddenCountLabel: "已隱藏",
        hideFromList: "從列表中隱藏"
    )

    static let zhHK = MixerFeatureStrings(
        pageTitle: "音量混音器",
        hideInactiveApps: "隱藏非活躍的 App",
        empty: "正在使用音訊的 App 會顯示在這裡",
        unavailable: "需要 macOS 14.4 及更高版本",
        permissionBody: "若要調整各 App 的音量，請在「系統設定」中允許「螢幕與系統音訊錄製」。絕不會錄製音訊。",
        resetTooltip: "重設為 100%",
        outputDefault: "預設",
        outputCurrent: "目前",
        outputUnavailable: "輸出無法使用",
        outputFallback: "此裝置恢復前，使用預設輸出。",
        bypassedCaption: "此 App 自行管理音訊。",
        outputTooltip: "選取輸出",
        systemOutputTitle: "輸出",
        systemOutputNoDevices: "找不到輸出裝置",
        systemOutputTooltip: "選取系統輸出",
        systemOutputErrorFormat: "無法切換：%@",
        soundEffectsOutputTitle: "系統聲音",
        soundEffectsOutputTooltip: "選擇提示音和音效的播放裝置",
        lowerOnHeadphonesDisconnect: "耳機中斷連接時降低音量",
        lowerOnHeadphonesDisconnectCaption: "有線或藍牙耳機中斷連接時自動調整音量。",
        headphonesDisconnectVolume: "調整至",
        inputTitle: "咪高峰",
        inputNoDevices: "找不到咪高峰",
        inputUnavailable: "咪高峰無法使用",
        inputFallback: "此咪高峰恢復前，使用預設輸入。",
        inputTooltip: "選取咪高峰",
        inputErrorFormat: "無法切換：%@",
        visibleApps: "列表中的 App",
        allShown: "全部",
        hiddenCountLabel: "已隱藏",
        hideFromList: "從列表中隱藏"
    )
}
