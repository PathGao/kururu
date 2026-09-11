// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

struct MonitorHistoryStrings {
    let range: String
    let history: String
    let collecting: String
    let now: String
    let intervalHint: String
    let visibilityHint: String
    let seconds: String
    let minutes: String
    static func text(_ language: AppLanguage) -> Self {
        switch language {
        case .zhHans:
            return Self(range: "时间范围", history: "趋势图", collecting: "正在积累历史，未采集的时段留空", now: "现在",
                        intervalHint: "后台按此间隔采集监控数据，保留最近 5 分钟。",
                        visibilityHint: "下方开关只控制趋势图显示。隐藏图表后仍继续采集并保留历史。", seconds: "秒", minutes: "分钟")
        case .zhTW, .zhHK:
            return Self(range: "時間範圍", history: "趨勢圖", collecting: "正在累積歷史，未採集的時段留空", now: "現在",
                        intervalHint: "背景依此間隔採集監視資料，保留最近 5 分鐘。",
                        visibilityHint: "下方開關只控制趨勢圖顯示。隱藏圖表後仍繼續採集並保留歷史。", seconds: "秒", minutes: "分鐘")
        default:
            return Self(range: "Time range", history: "History", collecting: "Collecting history. Unsampled periods stay empty.", now: "Now",
                        intervalHint: "Readings are collected at this interval and retained for the last five minutes.",
                        visibilityHint: "These switches only show or hide history charts. Collection and history continue while charts are hidden.", seconds: "s", minutes: "min")
        }
    }
}
