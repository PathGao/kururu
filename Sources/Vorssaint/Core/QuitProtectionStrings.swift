// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import Foundation

struct QuitProtectionStrings {
    var name: String = "Quit & close protection"
    var description: String = "Protects ⌘Q and ⌘W from accidental presses"
    var intro: String = "Configure each shortcut independently. The original action passes only after the selected confirmation."
    var enabled: String = "Protect this shortcut"
    var enabledCaption: String = "Other Command shortcuts continue to work normally."
    var mode: String = "Confirmation mode"
    var hold: String = "Hold to confirm"
    var doublePress: String = "Double press"
    var extraModifier: String = "Require extra modifier"
    var holdDuration: String = "Hold duration"
    var doublePressInterval: String = "Double press interval"
    var modifier: String = "Extra modifier"
    var appScope: String = "Applications"
    var allApps: String = "All applications"
    var selectedOnly: String = "Selected applications only"
    var allExceptSelected: String = "All except selected applications"
    var protectedApps: String = "Protected applications"
    var unprotectedApps: String = "Unprotected applications"
    var noProtectedApps: String = "No applications selected. When enabled, this shortcut is not protected in any application."
    var noUnprotectedApps: String = "No applications selected. When enabled, this shortcut is protected in all applications."
    var addApp: String = "Add application…"
    var feedback: String = "Show visual feedback"
    var accessibilityCaption: String = "Protection uses Accessibility to observe only ⌘Q and ⌘W globally."
    var holdQuitHUDFormat: String = "Hold %@ to quit"
    var holdCloseHUDFormat: String = "Hold %@ to close"
    var doubleQuitHUDFormat: String = "Press %@ again to quit"
    var doubleCloseHUDFormat: String = "Press %@ again to close"
    var extraQuitHUDFormat: String = "Use %@ to quit"
    var extraCloseHUDFormat: String = "Use %@ to close"
    var cancelHint: String = "Esc cancels"
    var releaseHint: String = "Release to confirm"
    var shiftKey: String = "Shift"
    var optionKey: String = "Option"
    var controlKey: String = "Control"

    func holdHUDFormat(for shortcut: QuitProtectionShortcut) -> String {
        shortcut == .quit ? holdQuitHUDFormat : holdCloseHUDFormat
    }

    func doubleHUDFormat(for shortcut: QuitProtectionShortcut) -> String {
        shortcut == .quit ? doubleQuitHUDFormat : doubleCloseHUDFormat
    }

    func extraHUDFormat(for shortcut: QuitProtectionShortcut) -> String {
        shortcut == .quit ? extraQuitHUDFormat : extraCloseHUDFormat
    }

    static func make(_ language: AppLanguage) -> QuitProtectionStrings {
        FeatureStrings.quitProtection(language)
    }
}

extension FeatureStrings {
    static func quitProtection(_ language: AppLanguage) -> QuitProtectionStrings {
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

extension QuitProtectionStrings {
    static let enUS = QuitProtectionStrings()

    static let ptBR = QuitProtectionStrings(
        name: "Proteção de encerramento",
        description: "Protege ⌘Q e ⌘W contra toques acidentais",
        intro: "Configure cada atalho separadamente. A ação original só passa depois da confirmação escolhida.",
        enabled: "Proteger este atalho",
        enabledCaption: "Outros atalhos com Command continuam funcionando normalmente.",
        mode: "Modo de confirmação",
        hold: "Segurar para confirmar",
        doublePress: "Pressionar duas vezes",
        extraModifier: "Exigir modificador extra",
        holdDuration: "Tempo pressionado",
        doublePressInterval: "Intervalo entre pressões",
        modifier: "Modificador extra",
        appScope: "Aplicativos",
        allApps: "Todos os aplicativos",
        selectedOnly: "Somente aplicativos selecionados",
        allExceptSelected: "Todos, exceto os selecionados",
        protectedApps: "Aplicativos protegidos",
        unprotectedApps: "Aplicativos sem proteção",
        noProtectedApps: "Nenhum aplicativo selecionado. Quando ativado, este atalho não é protegido em nenhum aplicativo.",
        noUnprotectedApps: "Nenhum aplicativo selecionado. Quando ativado, este atalho é protegido em todos os aplicativos.",
        addApp: "Adicionar aplicativo…",
        feedback: "Mostrar feedback visual",
        accessibilityCaption: "A proteção usa Acessibilidade para observar apenas ⌘Q e ⌘W globalmente.",
        holdQuitHUDFormat: "Segure %@ para encerrar",
        holdCloseHUDFormat: "Segure %@ para fechar",
        doubleQuitHUDFormat: "Pressione %@ novamente para encerrar",
        doubleCloseHUDFormat: "Pressione %@ novamente para fechar",
        extraQuitHUDFormat: "Use %@ para encerrar",
        extraCloseHUDFormat: "Use %@ para fechar",
        cancelHint: "Esc cancela",
        releaseHint: "Solte para confirmar",
        shiftKey: "Shift",
        optionKey: "Option",
        controlKey: "Control"
    )

    static let es = QuitProtectionStrings(
        name: "Protección de cierre",
        description: "Protege ⌘Q y ⌘W contra pulsaciones accidentales",
        intro: "Configura cada atajo de forma independiente. La acción original solo se ejecuta tras la confirmación elegida.",
        enabled: "Proteger este atajo",
        enabledCaption: "Otros atajos con Command siguen funcionando con normalidad.",
        mode: "Modo de confirmación",
        hold: "Mantener para confirmar",
        doublePress: "Pulsar dos veces",
        extraModifier: "Requerir modificador adicional",
        holdDuration: "Tiempo de pulsación",
        doublePressInterval: "Intervalo entre pulsaciones",
        modifier: "Modificador adicional",
        appScope: "Aplicaciones",
        allApps: "Todas las aplicaciones",
        selectedOnly: "Solo aplicaciones seleccionadas",
        allExceptSelected: "Todas excepto las seleccionadas",
        protectedApps: "Aplicaciones protegidas",
        unprotectedApps: "Aplicaciones sin protección",
        noProtectedApps: "Ninguna aplicación seleccionada. Al activarse, este atajo no se protege en ninguna aplicación.",
        noUnprotectedApps: "Ninguna aplicación seleccionada. Al activarse, este atajo se protege en todas las aplicaciones.",
        addApp: "Añadir aplicación…",
        feedback: "Mostrar respuesta visual",
        accessibilityCaption: "La protección utiliza Accesibilidad para supervisar solo ⌘Q y ⌘W de forma global.",
        holdQuitHUDFormat: "Mantén %@ para salir",
        holdCloseHUDFormat: "Mantén %@ para cerrar",
        doubleQuitHUDFormat: "Pulsa %@ de nuevo para salir",
        doubleCloseHUDFormat: "Pulsa %@ de nuevo para cerrar",
        extraQuitHUDFormat: "Usa %@ para salir",
        extraCloseHUDFormat: "Usa %@ para cerrar",
        cancelHint: "Esc cancela",
        releaseHint: "Suelta para confirmar",
        shiftKey: "Mayúsculas",
        optionKey: "Opción",
        controlKey: "Control"
    )

    static let de = QuitProtectionStrings(
        name: "Beenden- & Schließen-Schutz",
        description: "Schützt ⌘Q und ⌘W vor versehentlichem Drücken",
        intro: "Konfigurieren Sie jeden Kurzbefehl unabhängig. Die ursprüngliche Aktion wird erst nach der Bestätigung ausgeführt.",
        enabled: "Diesen Kurzbefehl schützen",
        enabledCaption: "Andere Befehle mit der Command-Taste funktionieren weiterhin normal.",
        mode: "Bestätigungsmodus",
        hold: "Halten zum Bestätigen",
        doublePress: "Zweimal drücken",
        extraModifier: "Zusätzliche Sondertaste erfordern",
        holdDuration: "Haltedauer",
        doublePressInterval: "Intervall zwischen Betätigungen",
        modifier: "Zusätzliche Sondertaste",
        appScope: "Programme",
        allApps: "Alle Programme",
        selectedOnly: "Nur ausgewählte Programme",
        allExceptSelected: "Alle außer ausgewählten Programmen",
        protectedApps: "Geschützte Programme",
        unprotectedApps: "Ungeschützte Programme",
        noProtectedApps: "Keine Programme ausgewählt. Wenn aktiviert, ist dieser Kurzbefehl in keinem Programm geschützt.",
        noUnprotectedApps: "Keine Programme ausgewählt. Wenn aktiviert, ist dieser Kurzbefehl in allen Programmen geschützt.",
        addApp: "Programm hinzufügen…",
        feedback: "Visuelles Feedback anzeigen",
        accessibilityCaption: "Der Schutz nutzt Bedienungshilfen, um nur ⌘Q und ⌘W global zu überwachen.",
        holdQuitHUDFormat: "%@ halten zum Beenden",
        holdCloseHUDFormat: "%@ halten zum Schließen",
        doubleQuitHUDFormat: "%@ erneut drücken zum Beenden",
        doubleCloseHUDFormat: "%@ erneut drücken zum Schließen",
        extraQuitHUDFormat: "%@ verwenden zum Beenden",
        extraCloseHUDFormat: "%@ verwenden zum Schließen",
        cancelHint: "Esc bricht ab",
        releaseHint: "Loslassen zum Bestätigen",
        shiftKey: "Umschalttaste",
        optionKey: "Wahltaste",
        controlKey: "Control"
    )

    static let fr = QuitProtectionStrings(
        name: "Protection fermeture et quitter",
        description: "Protège ⌘Q et ⌘W contre les frappes accidentelles",
        intro: "Configurez chaque raccourci indépendamment. L’action originale ne passe qu’après la confirmation choisie.",
        enabled: "Protéger ce raccourci",
        enabledCaption: "Les autres raccourcis avec Command continuent de fonctionner normalement.",
        mode: "Mode de confirmation",
        hold: "Maintenir pour confirmer",
        doublePress: "Appuyer deux fois",
        extraModifier: "Exiger une touche de modification",
        holdDuration: "Durée de maintien",
        doublePressInterval: "Intervalle entre les frappes",
        modifier: "Touche de modification",
        appScope: "Applications",
        allApps: "Toutes les applications",
        selectedOnly: "Applications sélectionnées uniquement",
        allExceptSelected: "Toutes sauf les applications sélectionnées",
        protectedApps: "Applications protégées",
        unprotectedApps: "Applications non protégées",
        noProtectedApps: "Aucune application sélectionnée. Une fois activé, ce raccourci ne sera protégé dans aucune application.",
        noUnprotectedApps: "Aucune application sélectionnée. Une fois activé, ce raccourci sera protégé dans toutes les applications.",
        addApp: "Ajouter une application…",
        feedback: "Afficher le retour visuel",
        accessibilityCaption: "La protection utilise Accessibilité pour observer uniquement ⌘Q et ⌘W globalement.",
        holdQuitHUDFormat: "Maintenez %@ pour quitter",
        holdCloseHUDFormat: "Maintenez %@ pour fermer",
        doubleQuitHUDFormat: "Appuyez à nouveau sur %@ pour quitter",
        doubleCloseHUDFormat: "Appuyez à nouveau sur %@ pour fermer",
        extraQuitHUDFormat: "Utilisez %@ pour quitter",
        extraCloseHUDFormat: "Utilisez %@ pour fermer",
        cancelHint: "Échap pour annuler",
        releaseHint: "Relâchez pour confirmer",
        shiftKey: "Maj",
        optionKey: "Option",
        controlKey: "Contrôle"
    )

    static let it = QuitProtectionStrings(
        name: "Protezione chiusura e uscita",
        description: "Protegge ⌘Q e ⌘W da pressioni accidentali",
        intro: "Configura ogni abbreviazione in modo indipendente. L’azione originale viene eseguita solo dopo la conferma.",
        enabled: "Proteggi questa abbreviazione",
        enabledCaption: "Le altre abbreviazioni con Command continuano a funzionare normalmente.",
        mode: "Modalità di conferma",
        hold: "Tieni premuto per confermare",
        doublePress: "Premi due volte",
        extraModifier: "Richiedi modificatore aggiuntivo",
        holdDuration: "Durata della pressione",
        doublePressInterval: "Intervallo tra le pressioni",
        modifier: "Modificatore aggiuntivo",
        appScope: "Applicazioni",
        allApps: "Tutte le applicazioni",
        selectedOnly: "Solo applicazioni selezionate",
        allExceptSelected: "Tutte tranne quelle selezionate",
        protectedApps: "Applicazioni protette",
        unprotectedApps: "Applicazioni non protette",
        noProtectedApps: "Nessuna applicazione selezionata. Quando attiva, la protezione non si applica a questa scorciatoia in nessuna applicazione.",
        noUnprotectedApps: "Nessuna applicazione selezionata. Quando attiva, la protezione si applica a questa scorciatoia in tutte le applicazioni.",
        addApp: "Aggiungi applicazione…",
        feedback: "Mostra feedback visivo",
        accessibilityCaption: "La protezione usa Accessibilità per osservare solo ⌘Q e ⌘W a livello globale.",
        holdQuitHUDFormat: "Tieni premuto %@ per uscire",
        holdCloseHUDFormat: "Tieni premuto %@ per chiudere",
        doubleQuitHUDFormat: "Premi di nuovo %@ per uscire",
        doubleCloseHUDFormat: "Premi di nuovo %@ per chiudere",
        extraQuitHUDFormat: "Usa %@ per uscire",
        extraCloseHUDFormat: "Usa %@ per chiudere",
        cancelHint: "Esc annulla",
        releaseHint: "Rilascia per confermare",
        shiftKey: "Maiuscole",
        optionKey: "Opzione",
        controlKey: "Controllo"
    )

    static let tr = QuitProtectionStrings(
        name: "Kapatma ve çıkış koruması",
        description: "⌘Q ve ⌘W kısayollarını yanlışlıkla basılmaya karşı korur",
        intro: "Her kısayolu bağımsız yapılandırın. Asıl eylem yalnızca seçilen onaydan sonra iletilir.",
        enabled: "Bu kısayolu koru",
        enabledCaption: "Diğer Command kısayolları normal şekilde çalışmaya devam eder.",
        mode: "Onay modu",
        hold: "Onaylamak için basılı tutun",
        doublePress: "İki kez basın",
        extraModifier: "Ek niteleyici tuş iste",
        holdDuration: "Basılı tutma süresi",
        doublePressInterval: "Basma aralığı",
        modifier: "Ek niteleyici",
        appScope: "Uygulamalar",
        allApps: "Tüm uygulamalar",
        selectedOnly: "Yalnızca seçilen uygulamalar",
        allExceptSelected: "Seçilenler dışındaki tümü",
        protectedApps: "Korunan uygulamalar",
        unprotectedApps: "Korunmayan uygulamalar",
        noProtectedApps: "Hiçbir uygulama seçilmedi. Etkinleştirildiğinde bu kısayol hiçbir uygulamada korunmaz.",
        noUnprotectedApps: "Hiçbir uygulama seçilmedi. Etkinleştirildiğinde bu kısayol tüm uygulamalarda korunur.",
        addApp: "Uygulama ekle…",
        feedback: "Görsel geri bildirim göster",
        accessibilityCaption: "Koruma, yalnızca ⌘Q ve ⌘W tuşlarını izlemek için Erişilebilirlik kullanır.",
        holdQuitHUDFormat: "Çıkmak için %@ basılı tutun",
        holdCloseHUDFormat: "Kapatmak için %@ basılı tutun",
        doubleQuitHUDFormat: "Çıkmak için tekrar %@ basın",
        doubleCloseHUDFormat: "Kapatmak için tekrar %@ basın",
        extraQuitHUDFormat: "Çıkmak için %@ kullanın",
        extraCloseHUDFormat: "Kapatmak için %@ kullanın",
        cancelHint: "Esc iptal eder",
        releaseHint: "Onaylamak için bırakın",
        shiftKey: "Shift",
        optionKey: "Option",
        controlKey: "Control"
    )

    static let ru = QuitProtectionStrings(
        name: "Защита от закрытия",
        description: "Защищает ⌘Q и ⌘W от случайного нажатия",
        intro: "Настройте каждое сочетание отдельно. Исходное действие выполняется только после подтверждения.",
        enabled: "Защитить это сочетание",
        enabledCaption: "Остальные сочетания с Command продолжают работать как обычно.",
        mode: "Режим подтверждения",
        hold: "Удержание для подтверждения",
        doublePress: "Двойное нажатие",
        extraModifier: "Требовать доп. клавишу",
        holdDuration: "Время удержания",
        doublePressInterval: "Интервал между нажатиями",
        modifier: "Дополнительная клавиша",
        appScope: "Приложения",
        allApps: "Все приложения",
        selectedOnly: "Только выбранные приложения",
        allExceptSelected: "Все, кроме выбранных",
        protectedApps: "Защищённые приложения",
        unprotectedApps: "Незащищённые приложения",
        noProtectedApps: "Приложения не выбраны. При включении это сочетание клавиш не защищено ни в одном приложении.",
        noUnprotectedApps: "Приложения не выбраны. При включении это сочетание клавиш защищено во всех приложениях.",
        addApp: "Добавить приложение…",
        feedback: "Показывать подсказку",
        accessibilityCaption: "Защита использует Универсальный доступ только для отслеживания ⌘Q и ⌘W.",
        holdQuitHUDFormat: "Удерживайте %@ для выхода",
        holdCloseHUDFormat: "Удерживайте %@ для закрытия",
        doubleQuitHUDFormat: "Нажмите %@ ещё раз для выхода",
        doubleCloseHUDFormat: "Нажмите %@ ещё раз для закрытия",
        extraQuitHUDFormat: "Используйте %@ для выхода",
        extraCloseHUDFormat: "Используйте %@ для закрытия",
        cancelHint: "Esc отменяет",
        releaseHint: "Отпустите для подтверждения",
        shiftKey: "Shift",
        optionKey: "Option",
        controlKey: "Control"
    )

    static let ja = QuitProtectionStrings(
        name: "終了・閉じるの誤操作防止",
        description: "⌘Q と ⌘W の誤入力を防止します",
        intro: "ショートカットごとに個別に設定できます。確認操作を行ってから元の操作が実行されます。",
        enabled: "このショートカットを保護",
        enabledCaption: "その他の Command ショートカットは通常どおり動作します。",
        mode: "確認モード",
        hold: "長押しで確認",
        doublePress: "2回押して確認",
        extraModifier: "追加の修飾キーを要求",
        holdDuration: "長押し時間",
        doublePressInterval: "連続入力の間隔",
        modifier: "追加の修飾キー",
        appScope: "対象アプリケーション",
        allApps: "すべてのアプリケーション",
        selectedOnly: "選択したアプリケーションのみ",
        allExceptSelected: "選択したアプリケーション以外すべて",
        protectedApps: "保護するアプリ",
        unprotectedApps: "保護しないアプリ",
        noProtectedApps: "アプリが選択されていません。有効にしても、このショートカットはどのアプリでも保護されません。",
        noUnprotectedApps: "アプリが選択されていません。有効にすると、このショートカットはすべてのアプリで保護されます。",
        addApp: "アプリケーションを追加…",
        feedback: "視覚的フィードバックを表示",
        accessibilityCaption: "この機能はアクセシビリティを使用して ⌘Q と ⌘W のみをグローバルに監視します。",
        holdQuitHUDFormat: "終了するには %@ を長押し",
        holdCloseHUDFormat: "閉じるには %@ を長押し",
        doubleQuitHUDFormat: "終了するにはもう一度 %@ を入力",
        doubleCloseHUDFormat: "閉じるにはもう一度 %@ を入力",
        extraQuitHUDFormat: "終了するには %@ を使用",
        extraCloseHUDFormat: "閉じるには %@ を使用",
        cancelHint: "Esc でキャンセル",
        releaseHint: "離して確認",
        shiftKey: "Shift",
        optionKey: "Option",
        controlKey: "Control"
    )

    static let ko = QuitProtectionStrings(
        name: "종료 및 닫기 보호",
        description: "⌘Q 및 ⌘W의 실수 입력을 방지합니다",
        intro: "각 단축키를 개별적으로 설정합니다. 선택한 확인 동작을 완료해야 원래 동작이 실행됩니다.",
        enabled: "이 단축키 보호",
        enabledCaption: "다른 Command 단축키는 정상적으로 작동합니다.",
        mode: "확인 방식",
        hold: "길게 눌러 확인",
        doublePress: "두 번 눌러 확인",
        extraModifier: "추가 보조 키 필요",
        holdDuration: "길게 누르는 시간",
        doublePressInterval: "입력 간격",
        modifier: "추가 보조 키",
        appScope: "응용 프로그램",
        allApps: "모든 응용 프로그램",
        selectedOnly: "선택한 응용 프로그램만",
        allExceptSelected: "선택한 응용 프로그램 제외 전체",
        protectedApps: "보호할 앱",
        unprotectedApps: "보호하지 않을 앱",
        noProtectedApps: "선택한 앱이 없습니다. 활성화해도 이 단축키는 어떤 앱에서도 보호되지 않습니다.",
        noUnprotectedApps: "선택한 앱이 없습니다. 활성화하면 이 단축키는 모든 앱에서 보호됩니다.",
        addApp: "응용 프로그램 추가…",
        feedback: "시각적 피드백 표시",
        accessibilityCaption: "이 기능은 손쉬운 사용을 사용하여 ⌘Q 및 ⌘W만 전역적으로 감지합니다.",
        holdQuitHUDFormat: "종료하려면 %@ 길게 누르기",
        holdCloseHUDFormat: "닫으려면 %@ 길게 누르기",
        doubleQuitHUDFormat: "종료하려면 %@ 다시 누르기",
        doubleCloseHUDFormat: "닫으려면 %@ 다시 누르기",
        extraQuitHUDFormat: "종료하려면 %@ 사용",
        extraCloseHUDFormat: "닫으려면 %@ 사용",
        cancelHint: "Esc 취소",
        releaseHint: "손을 떼어 확인",
        shiftKey: "Shift",
        optionKey: "Option",
        controlKey: "Control"
    )

    static let zhHans = QuitProtectionStrings(
        name: "退出与关闭保护",
        description: "防止误按 ⌘Q 和 ⌘W",
        intro: "可单独配置每个快捷键。仅在完成选定的确认操作后才执行原操作。",
        enabled: "保护此快捷键",
        enabledCaption: "其他 Command 快捷键仍可正常使用。",
        mode: "确认模式",
        hold: "按住以确认",
        doublePress: "连按两次",
        extraModifier: "需要额外修饰键",
        holdDuration: "按住时长",
        doublePressInterval: "连按间隔",
        modifier: "额外修饰键",
        appScope: "应用程序",
        allApps: "所有应用程序",
        selectedOnly: "仅所选应用程序",
        allExceptSelected: "除所选外的所有应用程序",
        protectedApps: "受保护的应用",
        unprotectedApps: "不受保护的应用",
        noProtectedApps: "尚未添加应用。启用后，此快捷键在所有应用中都不受保护。",
        noUnprotectedApps: "尚未添加应用。启用后，此快捷键在所有应用中都受保护。",
        addApp: "添加应用程序…",
        feedback: "显示视觉反馈",
        accessibilityCaption: "该保护功能使用辅助功能仅全局监听 ⌘Q 和 ⌘W。",
        holdQuitHUDFormat: "按住 %@ 以退出",
        holdCloseHUDFormat: "按住 %@ 以关闭",
        doubleQuitHUDFormat: "再次按 %@ 以退出",
        doubleCloseHUDFormat: "再次按 %@ 以关闭",
        extraQuitHUDFormat: "使用 %@ 以退出",
        extraCloseHUDFormat: "使用 %@ 以关闭",
        cancelHint: "Esc 取消",
        releaseHint: "松开以确认",
        shiftKey: "Shift",
        optionKey: "Option",
        controlKey: "Control"
    )

    static let zhTW = QuitProtectionStrings(
        name: "結束與關閉保護",
        description: "防止誤按 ⌘Q 和 ⌘W",
        intro: "可單獨設定每個快速鍵。僅在完成選定的確認動作後才執行原動作。",
        enabled: "保護此快速鍵",
        enabledCaption: "其他 Command 快速鍵仍可正常使用。",
        mode: "確認模式",
        hold: "按住以確認",
        doublePress: "連按兩次",
        extraModifier: "需要額外變更鍵",
        holdDuration: "按住時間",
        doublePressInterval: "連按間隔",
        modifier: "額外變更鍵",
        appScope: "應用程式",
        allApps: "所有應用程式",
        selectedOnly: "僅所選應用程式",
        allExceptSelected: "除所選外的所有應用程式",
        protectedApps: "受保護的應用程式",
        unprotectedApps: "不受保護的應用程式",
        noProtectedApps: "尚未加入應用程式。啟用後，此快速鍵在所有應用程式中都不受保護。",
        noUnprotectedApps: "尚未加入應用程式。啟用後，此快速鍵在所有應用程式中都受保護。",
        addApp: "加入應用程式…",
        feedback: "顯示視覺回饋",
        accessibilityCaption: "該保護功能使用輔助使用僅全域監聽 ⌘Q 和 ⌘W。",
        holdQuitHUDFormat: "按住 %@ 以結束",
        holdCloseHUDFormat: "按住 %@ 以關閉",
        doubleQuitHUDFormat: "再次按 %@ 以結束",
        doubleCloseHUDFormat: "再次按 %@ 以關閉",
        extraQuitHUDFormat: "使用 %@ 以結束",
        extraCloseHUDFormat: "使用 %@ 以關閉",
        cancelHint: "Esc 取消",
        releaseHint: "放開以確認",
        shiftKey: "Shift",
        optionKey: "Option",
        controlKey: "Control"
    )

    static let zhHK = QuitProtectionStrings(
        name: "結束與關閉保護",
        description: "防止誤按 ⌘Q 和 ⌘W",
        intro: "可單獨設定每個快捷鍵。僅在完成選定的確認動作後才執行原動作。",
        enabled: "保護此快捷鍵",
        enabledCaption: "其他 Command 快捷鍵仍可正常使用。",
        mode: "確認模式",
        hold: "按住以確認",
        doublePress: "連按兩次",
        extraModifier: "需要額外修飾鍵",
        holdDuration: "按住時間",
        doublePressInterval: "連按間隔",
        modifier: "額外修飾鍵",
        appScope: "應用程式",
        allApps: "所有應用程式",
        selectedOnly: "僅所選應用程式",
        allExceptSelected: "除所選外的所有應用程式",
        protectedApps: "受保護的應用程式",
        unprotectedApps: "不受保護的應用程式",
        noProtectedApps: "尚未加入應用程式。啟用後，此快捷鍵在所有應用程式中都不受保護。",
        noUnprotectedApps: "尚未加入應用程式。啟用後，此快捷鍵在所有應用程式中都受保護。",
        addApp: "加入應用程式…",
        feedback: "顯示視覺回饋",
        accessibilityCaption: "該保護功能使用輔助使用僅全域監聽 ⌘Q 和 ⌘W。",
        holdQuitHUDFormat: "按住 %@ 以結束",
        holdCloseHUDFormat: "按住 %@ 以關閉",
        doubleQuitHUDFormat: "再次按 %@ 以結束",
        doubleCloseHUDFormat: "再次按 %@ 以關閉",
        extraQuitHUDFormat: "使用 %@ 以結束",
        extraCloseHUDFormat: "使用 %@ 以關閉",
        cancelHint: "Esc 取消",
        releaseHint: "放開以確認",
        shiftKey: "Shift",
        optionKey: "Option",
        controlKey: "Control"
    )
}
