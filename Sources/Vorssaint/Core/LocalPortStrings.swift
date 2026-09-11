// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

struct LocalPortStrings {
    var title = "Local ports"
    var scope = "TCP listeners and bound UDP sockets on this Mac. This does not mean they are reachable from the internet. Results may be limited by system permissions."
    var search = "Search port or process"
    var refresh = "Refresh"
    var loading = "Checking local ports…"
    var empty = "No matching ports visible."
    var failed = "The query failed or returned partial results. Refresh to try again."
    var restricted = "Process information restricted"
    var copy = "Copy information"
    var terminate = "End process…"
    var confirm = "End %@ (PID %d)?"
    var consequence = "This ends the whole process and all its connections. Unsaved work may be lost."
    var cancel = "Cancel"
    var changed = "The process or port changed, or access was denied. No administrator access was requested. Refresh and try again."
    var sent = "Termination requested. Refresh to check whether the port has been released."
    var copied = "Port information copied"
    var copyFailed = "Could not copy port information. Try again."

    static func text(_ language: AppLanguage) -> Self {
        if language == .zhHans {
            return Self(title: "本机端口", scope: "本机监听的 TCP 端口与已绑定的 UDP 端口，不代表公网可达。系统权限可能限制可见结果。",
                        search: "搜索端口或进程", refresh: "刷新", loading: "正在查询本机端口…",
                        empty: "没有可见的匹配端口。", failed: "查询失败或结果不完整，请刷新重试。",
                        restricted: "进程信息受限", copy: "复制信息", terminate: "结束进程…",
                        confirm: "结束 %@（PID %d）？", consequence: "这会结束整个进程及其全部连接，未保存的工作可能丢失。",
                        cancel: "取消", changed: "进程或端口已变化，或权限不足。未请求管理员权限，请刷新后重试。",
                        sent: "已请求结束进程，请刷新确认端口是否已释放。",
                        copied: "已复制端口信息", copyFailed: "无法复制端口信息，请重试。")
        }
        switch language {
        case .de: return Self(copied: "Portinformationen kopiert", copyFailed: "Portinformationen konnten nicht kopiert werden. Erneut versuchen.")
        case .fr: return Self(copied: "Informations du port copiées", copyFailed: "Impossible de copier les informations du port. Réessayez.")
        case .es: return Self(copied: "Información del puerto copiada", copyFailed: "No se pudo copiar la información del puerto. Inténtalo de nuevo.")
        case .ja: return Self(copied: "ポート情報をコピーしました", copyFailed: "ポート情報をコピーできませんでした。再試行してください。")
        default: return Self()
        }
    }
}
