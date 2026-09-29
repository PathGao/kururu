// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import Foundation

struct WindowPreviewExclusionStrings {
    var sectionTitle: String = "Window thumbnails"
    var listTitle: String = "Pause in these apps"
    var addButton: String = "Add an app…"
    var removeButton: String = "Remove"
    var caption: String = "Window thumbnails stop while one of these apps is in front."
    var previewSizeLabel: String = "Preview size"
    var previewSizeSmall: String = "Small"
    var previewSizeNormal: String = "Normal"
    var previewSizeLarge: String = "Large"
    var previewSizeXLarge: String = "Extra large"
}

extension FeatureStrings {
    static func windowPreviewExclusions(_ language: AppLanguage) -> WindowPreviewExclusionStrings {
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

extension WindowPreviewExclusionStrings {
    static let enUS = WindowPreviewExclusionStrings()

    static let ptBR = WindowPreviewExclusionStrings(
        sectionTitle: "Miniaturas das janelas",
        listTitle: "Pausar nestes apps",
        addButton: "Adicionar app…",
        removeButton: "Remover",
        caption: "As miniaturas das janelas param enquanto um destes apps está na frente.",
        previewSizeLabel: "Tamanho dos previews",
        previewSizeSmall: "Pequeno",
        previewSizeNormal: "Normal",
        previewSizeLarge: "Grande",
        previewSizeXLarge: "Extra grande"
    )

    static let tr = WindowPreviewExclusionStrings(
        sectionTitle: "Pencere küçük resimleri",
        listTitle: "Bu uygulamalarda duraklat",
        addButton: "Uygulama ekle…",
        removeButton: "Kaldır",
        caption: "Bu uygulamalardan biri öndeyken pencere küçük resimleri duraklar.",
        previewSizeLabel: "Önizleme boyutu",
        previewSizeSmall: "Küçük",
        previewSizeNormal: "Normal",
        previewSizeLarge: "Büyük",
        previewSizeXLarge: "Çok büyük"
    )

    static let ru = WindowPreviewExclusionStrings(
        sectionTitle: "Миниатюры окон",
        listTitle: "Приостанавливать в этих приложениях",
        addButton: "Добавить приложение…",
        removeButton: "Удалить",
        caption: "Миниатюры окон не обновляются, пока одно из этих приложений на переднем плане.",
        previewSizeLabel: "Размер превью",
        previewSizeSmall: "Маленький",
        previewSizeNormal: "Обычный",
        previewSizeLarge: "Большой",
        previewSizeXLarge: "Очень большой"
    )

    static let es = WindowPreviewExclusionStrings(
        sectionTitle: "Miniaturas de ventanas",
        listTitle: "Pausar en estas apps",
        addButton: "Añadir app…",
        removeButton: "Quitar",
        caption: "Las miniaturas de las ventanas se detienen mientras una de estas apps está en primer plano.",
        previewSizeLabel: "Tamaño de vistas previas",
        previewSizeSmall: "Pequeño",
        previewSizeNormal: "Normal",
        previewSizeLarge: "Grande",
        previewSizeXLarge: "Extra grande"
    )

    static let de = WindowPreviewExclusionStrings(
        sectionTitle: "Fenstervorschauen",
        listTitle: "In diesen Apps pausieren",
        addButton: "App hinzufügen…",
        removeButton: "Entfernen",
        caption: "Fenstervorschauen pausieren, solange eine dieser Apps im Vordergrund ist.",
        previewSizeLabel: "Vorschaugröße",
        previewSizeSmall: "Klein",
        previewSizeNormal: "Normal",
        previewSizeLarge: "Groß",
        previewSizeXLarge: "Sehr groß"
    )

    static let fr = WindowPreviewExclusionStrings(
        sectionTitle: "Aperçus des fenêtres",
        listTitle: "Mettre en pause dans ces apps",
        addButton: "Ajouter une app…",
        removeButton: "Retirer",
        caption: "Les aperçus des fenêtres s’arrêtent tant que l’une de ces apps est au premier plan.",
        previewSizeLabel: "Taille des aperçus",
        previewSizeSmall: "Petite",
        previewSizeNormal: "Normale",
        previewSizeLarge: "Grande",
        previewSizeXLarge: "Très grande"
    )

    static let it = WindowPreviewExclusionStrings(
        sectionTitle: "Anteprime delle finestre",
        listTitle: "Metti in pausa in queste app",
        addButton: "Aggiungi app…",
        removeButton: "Rimuovi",
        caption: "Le anteprime delle finestre si fermano quando una di queste app è in primo piano.",
        previewSizeLabel: "Dimensione anteprime",
        previewSizeSmall: "Piccola",
        previewSizeNormal: "Normale",
        previewSizeLarge: "Grande",
        previewSizeXLarge: "Molto grande"
    )

    static let ja = WindowPreviewExclusionStrings(
        sectionTitle: "ウインドウのサムネイル",
        listTitle: "これらのAppで一時停止",
        addButton: "Appを追加…",
        removeButton: "削除",
        caption: "これらのAppが前面にある間は、ウインドウのサムネイルを更新しません。",
        previewSizeLabel: "プレビューのサイズ",
        previewSizeSmall: "小",
        previewSizeNormal: "標準",
        previewSizeLarge: "大",
        previewSizeXLarge: "特大"
    )

    static let ko = WindowPreviewExclusionStrings(
        sectionTitle: "창 미리보기",
        listTitle: "이 앱에서 일시 정지",
        addButton: "앱 추가…",
        removeButton: "제거",
        caption: "이 앱 중 하나가 앞에 있는 동안에는 창 미리보기가 멈춥니다.",
        previewSizeLabel: "미리보기 크기",
        previewSizeSmall: "작게",
        previewSizeNormal: "보통",
        previewSizeLarge: "크게",
        previewSizeXLarge: "매우 크게"
    )

    static let zhHans = WindowPreviewExclusionStrings(
        sectionTitle: "窗口缩略图",
        listTitle: "在这些 App 中暂停",
        addButton: "添加 App…",
        removeButton: "移除",
        caption: "当这些 App 之一位于前台时，窗口缩略图会暂停更新。",
        previewSizeLabel: "预览大小",
        previewSizeSmall: "小",
        previewSizeNormal: "正常",
        previewSizeLarge: "大",
        previewSizeXLarge: "特大"
    )

    static let zhTW = WindowPreviewExclusionStrings(
        sectionTitle: "視窗縮圖",
        listTitle: "在這些 App 中暫停",
        addButton: "加入 App…",
        removeButton: "移除",
        caption: "當這些 App 之一位於前景時，視窗縮圖會暫停更新。",
        previewSizeLabel: "預覽大小",
        previewSizeSmall: "小",
        previewSizeNormal: "正常",
        previewSizeLarge: "大型",
        previewSizeXLarge: "超大型"
    )

    static let zhHK = WindowPreviewExclusionStrings(
        sectionTitle: "視窗縮圖",
        listTitle: "在這些 App 中暫停",
        addButton: "加入 App…",
        removeButton: "移除",
        caption: "當其中一個 App 位於前景時，視窗縮圖會暫停更新。",
        previewSizeLabel: "預覽大小",
        previewSizeSmall: "小",
        previewSizeNormal: "正常",
        previewSizeLarge: "大",
        previewSizeXLarge: "特大"
    )
}
