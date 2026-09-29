// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import Foundation

struct FeedbackStrings {
    var sectionTitle: String = "Feedback"
    var sectionCaption: String = "Send a bug report or feature idea directly to the person who maintains Vorssaint."
    var openButton: String = "Send feedback"
    var bugTitle: String = "Bug"
    var featureTitle: String = "Feature idea"
    var messageLabel: String = "What would you like to share?"
    var bugPlaceholder: String = "Tell me what happened and what you expected."
    var featurePlaceholder: String = "Describe the idea and how it would help."
    var charactersFormat: String = "%d of 2000 characters"
    var includeDiagnostics: String = "Include technical details"
    var includeDiagnosticsCaption: String = "Adds only the technical details shown below. It does not include logs."
    var previewBasic: String = "Your chosen category and the text above."
    var previewDiagnostics: String = "The technical details listed below."
    var done: String = "Done"
    var commandBug: String = "Report a bug"
    var commandFeature: String = "Suggest a feature"
    var commandSubtitle: String = "Send feedback"
    var diagnosticsChannelLabel: String = "Update channel"
}

extension FeatureStrings {
    static func feedback(_ language: AppLanguage) -> FeedbackStrings {
        let result: FeedbackStrings
        switch language {
        case .enUS: result = .enUS
        case .ptBR: result = .ptBR
        case .tr: result = .tr
        case .ru: result = .ru
        case .es: result = .es
        case .de: result = .de
        case .fr: result = .fr
        case .it: result = .it
        case .ja: result = .ja
        case .ko: result = .ko
        case .zhHans: result = .zhHans
        case .zhTW: result = .zhTW
        case .zhHK: result = .zhHK
        }
        var local = result
        let copy = LocalFeedbackCopy.strings(language: language.rawValue)
        local.sectionCaption = copy.explanation
        local.openButton = copy.title
        local.commandSubtitle = copy.title
        return local
    }
}

extension FeedbackStrings {
    static let enUS = FeedbackStrings()

    static let ptBR = FeedbackStrings(
        sectionTitle: "Feedback",
        sectionCaption: "Envie um relato de bug ou uma ideia de recurso diretamente para quem mantém o Vorssaint.",
        openButton: "Enviar feedback",
        bugTitle: "Bug",
        featureTitle: "Ideia de recurso",
        messageLabel: "O que você gostaria de compartilhar?",
        bugPlaceholder: "Conte o que aconteceu e o que você esperava.",
        featurePlaceholder: "Descreva a ideia e como ela ajudaria.",
        charactersFormat: "%d de 2000 caracteres",
        includeDiagnostics: "Incluir dados técnicos",
        includeDiagnosticsCaption: "Adiciona somente os dados técnicos mostrados abaixo. Não inclui logs.",
        previewBasic: "A categoria escolhida e o texto acima.",
        previewDiagnostics: "Os dados técnicos listados abaixo.",
        done: "Concluído",
        commandBug: "Relatar um bug",
        commandFeature: "Sugerir um recurso",
        commandSubtitle: "Enviar feedback",
        diagnosticsChannelLabel: "Canal de atualização"
    )

    static let tr = FeedbackStrings(
        sectionTitle: "Geri bildirim",
        sectionCaption: "Bir hata bildirimini veya özellik fikrini doğrudan Vorssaint bakımcısına gönderin.",
        openButton: "Geri bildirim gönder",
        bugTitle: "Hata",
        featureTitle: "Özellik fikri",
        messageLabel: "Ne paylaşmak istersiniz?",
        bugPlaceholder: "Ne olduğunu ve ne beklediğinizi anlatın.",
        featurePlaceholder: "Fikri ve nasıl yardımcı olacağını açıklayın.",
        charactersFormat: "2000 karakterden %d",
        includeDiagnostics: "Teknik ayrıntıları ekle",
        includeDiagnosticsCaption: "Yalnızca aşağıda gösterilen teknik ayrıntıları ekler. Günlükler eklenmez.",
        previewBasic: "Seçtiğiniz kategori ve yukarıdaki metin.",
        previewDiagnostics: "Aşağıda listelenen teknik ayrıntılar.",
        done: "Bitti",
        commandBug: "Hata bildir",
        commandFeature: "Özellik öner",
        commandSubtitle: "Geri bildirim gönder",
        diagnosticsChannelLabel: "Güncelleme kanalı"
    )

    static let ru = FeedbackStrings(
        sectionTitle: "Обратная связь",
        sectionCaption: "Отправьте сообщение об ошибке или идею функции напрямую разработчику Vorssaint.",
        openButton: "Отправить отзыв",
        bugTitle: "Ошибка",
        featureTitle: "Идея функции",
        messageLabel: "Чем вы хотите поделиться?",
        bugPlaceholder: "Опишите, что произошло и чего вы ожидали.",
        featurePlaceholder: "Опишите идею и чем она поможет.",
        charactersFormat: "%d из 2000 символов",
        includeDiagnostics: "Добавить технические данные",
        includeDiagnosticsCaption: "Добавляет только технические данные, показанные ниже. Журналы не добавляются.",
        previewBasic: "Выбранная категория и текст выше.",
        previewDiagnostics: "Технические данные, перечисленные ниже.",
        done: "Готово",
        commandBug: "Сообщить об ошибке",
        commandFeature: "Предложить функцию",
        commandSubtitle: "Отправить отзыв",
        diagnosticsChannelLabel: "Канал обновлений"
    )

    static let es = FeedbackStrings(
        sectionTitle: "Comentarios",
        sectionCaption: "Envía un informe de error o una idea directamente a quien mantiene Vorssaint.",
        openButton: "Enviar comentarios",
        bugTitle: "Error",
        featureTitle: "Idea de función",
        messageLabel: "¿Qué quieres compartir?",
        bugPlaceholder: "Cuenta qué ocurrió y qué esperabas.",
        featurePlaceholder: "Describe la idea y cómo ayudaría.",
        charactersFormat: "%d de 2000 caracteres",
        includeDiagnostics: "Incluir datos técnicos",
        includeDiagnosticsCaption: "Añade solo los datos técnicos mostrados abajo. No incluye registros.",
        previewBasic: "La categoría elegida y el texto anterior.",
        previewDiagnostics: "Los datos técnicos indicados abajo.",
        done: "Listo",
        commandBug: "Informar de un error",
        commandFeature: "Sugerir una función",
        commandSubtitle: "Enviar comentarios",
        diagnosticsChannelLabel: "Canal de actualización"
    )

    static let de = FeedbackStrings(
        sectionTitle: "Feedback",
        sectionCaption: "Sende einen Fehlerbericht oder eine Funktionsidee direkt an den Vorssaint-Entwickler.",
        openButton: "Feedback senden",
        bugTitle: "Fehler",
        featureTitle: "Funktionsidee",
        messageLabel: "Was möchtest du mitteilen?",
        bugPlaceholder: "Beschreibe, was passiert ist und was du erwartet hast.",
        featurePlaceholder: "Beschreibe die Idee und wie sie helfen würde.",
        charactersFormat: "%d von 2000 Zeichen",
        includeDiagnostics: "Technische Daten mitsenden",
        includeDiagnosticsCaption: "Fügt nur die unten gezeigten technischen Daten hinzu. Keine Protokolle.",
        previewBasic: "Die gewählte Kategorie und der Text oben.",
        previewDiagnostics: "Die unten aufgeführten technischen Daten.",
        done: "Fertig",
        commandBug: "Fehler melden",
        commandFeature: "Funktion vorschlagen",
        commandSubtitle: "Feedback senden",
        diagnosticsChannelLabel: "Update-Kanal"
    )

    static let fr = FeedbackStrings(
        sectionTitle: "Avis",
        sectionCaption: "Envoyez un rapport de bug ou une idée directement à la personne qui maintient Vorssaint.",
        openButton: "Envoyer un avis",
        bugTitle: "Bug",
        featureTitle: "Idée de fonction",
        messageLabel: "Que souhaitez-vous partager\u{00A0}?",
        bugPlaceholder: "Décrivez ce qui s’est passé et ce que vous attendiez.",
        featurePlaceholder: "Décrivez l’idée et son utilité.",
        charactersFormat: "%d caractères sur 2000",
        includeDiagnostics: "Inclure les données techniques",
        includeDiagnosticsCaption: "Ajoute uniquement les données techniques affichées ci-dessous. Aucun journal.",
        previewBasic: "La catégorie choisie et le texte ci-dessus.",
        previewDiagnostics: "Les données techniques listées ci-dessous.",
        done: "Terminé",
        commandBug: "Signaler un bug",
        commandFeature: "Suggérer une fonction",
        commandSubtitle: "Envoyer un avis",
        diagnosticsChannelLabel: "Canal de mise à jour"
    )

    static let it = FeedbackStrings(
        sectionTitle: "Feedback",
        sectionCaption: "Invia una segnalazione o un’idea direttamente a chi mantiene Vorssaint.",
        openButton: "Invia feedback",
        bugTitle: "Bug",
        featureTitle: "Idea per una funzione",
        messageLabel: "Cosa vuoi condividere?",
        bugPlaceholder: "Descrivi cosa è successo e cosa ti aspettavi.",
        featurePlaceholder: "Descrivi l’idea e come potrebbe aiutare.",
        charactersFormat: "%d di 2000 caratteri",
        includeDiagnostics: "Includi dati tecnici",
        includeDiagnosticsCaption: "Aggiunge solo i dati tecnici mostrati sotto. Non include registri.",
        previewBasic: "La categoria scelta e il testo qui sopra.",
        previewDiagnostics: "I dati tecnici elencati qui sotto.",
        done: "Fine",
        commandBug: "Segnala un bug",
        commandFeature: "Suggerisci una funzione",
        commandSubtitle: "Invia feedback",
        diagnosticsChannelLabel: "Canale di aggiornamento"
    )

    static let ja = FeedbackStrings(
        sectionTitle: "フィードバック",
        sectionCaption: "不具合の報告や機能のアイデアを Vorssaint の開発者へ直接送信します。",
        openButton: "フィードバックを送信",
        bugTitle: "不具合",
        featureTitle: "機能のアイデア",
        messageLabel: "共有したい内容を入力してください",
        bugPlaceholder: "何が起き、どうなることを期待していたかを説明してください。",
        featurePlaceholder: "アイデアと、どのように役立つかを説明してください。",
        charactersFormat: "2000文字中%d文字",
        includeDiagnostics: "技術情報を含める",
        includeDiagnosticsCaption: "下に表示される技術情報だけを追加します。ログは含みません。",
        previewBasic: "選択した種類と上の文章。",
        previewDiagnostics: "下に表示される技術情報。",
        done: "完了",
        commandBug: "不具合を報告",
        commandFeature: "機能を提案",
        commandSubtitle: "フィードバックを送信",
        diagnosticsChannelLabel: "アップデートチャンネル"
    )

    static let ko = FeedbackStrings(
        sectionTitle: "피드백",
        sectionCaption: "버그 신고나 기능 아이디어를 Vorssaint 관리자에게 직접 보냅니다.",
        openButton: "피드백 보내기",
        bugTitle: "버그",
        featureTitle: "기능 아이디어",
        messageLabel: "무엇을 공유하시겠습니까?",
        bugPlaceholder: "무슨 일이 있었고 무엇을 기대했는지 알려 주세요.",
        featurePlaceholder: "아이디어와 도움이 되는 이유를 설명해 주세요.",
        charactersFormat: "2000자 중 %d자",
        includeDiagnostics: "기술 정보 포함",
        includeDiagnosticsCaption: "아래에 표시된 기술 정보만 추가합니다. 로그는 포함하지 않습니다.",
        previewBasic: "선택한 종류와 위의 글.",
        previewDiagnostics: "아래에 표시된 기술 정보.",
        done: "완료",
        commandBug: "버그 신고",
        commandFeature: "기능 제안",
        commandSubtitle: "피드백 보내기",
        diagnosticsChannelLabel: "업데이트 채널"
    )

    static let zhHans = FeedbackStrings(
        sectionTitle: "反馈",
        sectionCaption: "将错误报告或功能建议直接发送给 Vorssaint 的维护者。",
        openButton: "发送反馈",
        bugTitle: "错误",
        featureTitle: "功能建议",
        messageLabel: "你想分享什么？",
        bugPlaceholder: "说明发生了什么以及你原本的预期。",
        featurePlaceholder: "说明你的想法以及它能带来什么帮助。",
        charactersFormat: "已输入 %d/2000 个字符",
        includeDiagnostics: "包含技术信息",
        includeDiagnosticsCaption: "仅添加下方显示的技术信息。不包含日志。",
        previewBasic: "所选类别和上方文字。",
        previewDiagnostics: "下方列出的技术信息。",
        done: "完成",
        commandBug: "报告错误",
        commandFeature: "建议功能",
        commandSubtitle: "发送反馈",
        diagnosticsChannelLabel: "更新渠道"
    )

    static let zhTW = FeedbackStrings(
        sectionTitle: "意見回饋",
        sectionCaption: "將錯誤回報或功能建議直接傳送給 Vorssaint 的維護者。",
        openButton: "傳送意見",
        bugTitle: "錯誤",
        featureTitle: "功能建議",
        messageLabel: "你想分享什麼？",
        bugPlaceholder: "說明發生了什麼以及你原本的預期。",
        featurePlaceholder: "說明你的想法以及它能帶來什麼幫助。",
        charactersFormat: "已輸入 %d/2000 個字元",
        includeDiagnostics: "包含技術資訊",
        includeDiagnosticsCaption: "只加入下方顯示的技術資料。不包含記錄。",
        previewBasic: "所選類別與上方文字。",
        previewDiagnostics: "下方列出的技術資訊。",
        done: "完成",
        commandBug: "回報錯誤",
        commandFeature: "建議功能",
        commandSubtitle: "傳送意見",
        diagnosticsChannelLabel: "更新頻道"
    )

    static let zhHK = FeedbackStrings(
        sectionTitle: "意見回饋",
        sectionCaption: "將錯誤報告或功能建議直接傳送給 Vorssaint 的維護者。",
        openButton: "傳送意見",
        bugTitle: "錯誤",
        featureTitle: "功能建議",
        messageLabel: "你想分享甚麼？",
        bugPlaceholder: "說明發生了甚麼以及你原本的預期。",
        featurePlaceholder: "說明你的想法以及它能帶來甚麼幫助。",
        charactersFormat: "已輸入 %d/2000 個字元",
        includeDiagnostics: "包含技術資料",
        includeDiagnosticsCaption: "只加入下方顯示的技術資料。不包含記錄。",
        previewBasic: "所選類別與上方文字。",
        previewDiagnostics: "下方列出的技術資料。",
        done: "完成",
        commandBug: "報告錯誤",
        commandFeature: "建議功能",
        commandSubtitle: "傳送意見",
        diagnosticsChannelLabel: "更新頻道"
    )
}
