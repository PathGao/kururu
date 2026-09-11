// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

struct TrackpadGestureStrings {
    var trigger = "Trackpad tap"
    var hint = "A light tap opens this menu and leaves it open. Tap again to close. Holding fingers does not select an action."
    var conflict = "This tap is assigned elsewhere. It will not run until only one target uses it. Choose Off or an unused tap."
    var reservation = "Pausing a feature keeps its tap assignment. Clear the assignment before using that tap elsewhere."
    var bindings = "Radial menu tap assignments"
    var configuration = "Configure these assignments in Radial menu settings."
    var systemDragConflict = "macOS three-finger drag is enabled. Turn it off in Accessibility → Pointer Control → Trackpad Options to use three-finger actions here."
    var unavailable = "Trackpad touch input is unavailable. Connect a supported trackpad to use this tap."

    static func localized(_ language: AppLanguage) -> Self {
        if language == .zhHans {
            return Self(trigger: "触控板轻点",
                hint: "轻点后打开菜单并保持显示，再次轻点关闭。按住手指不会选择动作。",
                conflict: "此轻点已分配给其他目标。冲突解除前不会触发，请选择关闭或未占用的轻点。",
                reservation: "暂停功能会保留轻点绑定。如需分配给其他功能，请先清除原绑定。",
                bindings: "径向菜单轻点绑定", configuration: "在径向菜单设置中修改这些绑定。",
                systemDragConflict: "macOS 三指拖移已开启。请在辅助功能 → 指针控制 → 触控板选项中关闭它，再使用这里的三指动作。",
                unavailable: "无法读取触控板触摸输入，请连接支持的触控板后使用此轻点。")
        }
        if language == .zhTW || language == .zhHK {
            return Self(trigger: "觸控板輕點",
                hint: "輕點後開啟選單並保持顯示，再次輕點關閉。按住手指不會選擇動作。",
                conflict: "此輕點已分配給其他目標。衝突解除前不會觸發，請選擇關閉或未佔用的輕點。",
                reservation: "暫停功能會保留輕點綁定。如需分配給其他功能，請先清除原綁定。",
                bindings: "徑向選單輕點綁定", configuration: "在徑向選單設定中修改這些綁定。",
                unavailable: "無法讀取觸控板觸摸輸入，請連接支援的觸控板後使用此輕點。")
        }
        switch language {
        case .de:
            return Self(systemDragConflict: "macOS verwendet Ziehen mit drei Fingern. Deaktiviere es unter Bedienungshilfen → Zeigersteuerung → Trackpad-Optionen, um hier Drei-Finger-Aktionen zu nutzen.")
        case .fr:
            return Self(systemDragConflict: "Le glissement à trois doigts de macOS est activé. Désactivez-le dans Accessibilité → Contrôle du pointeur → Options du trackpad pour utiliser les actions à trois doigts ici.")
        case .es:
            return Self(systemDragConflict: "El arrastre con tres dedos de macOS está activado. Desactívalo en Accesibilidad → Control del puntero → Opciones del trackpad para usar aquí las acciones con tres dedos.")
        case .ja:
            return Self(systemDragConflict: "macOSの3本指ドラッグが有効です。ここの3本指操作を使うには、アクセシビリティ → ポインタコントロール → トラックパッドオプションで無効にしてください。")
        default: break
        }
        return Self()
    }
}
