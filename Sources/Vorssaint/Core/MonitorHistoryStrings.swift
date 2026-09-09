// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

struct MonitorHistoryStrings {
    let range: String
    let history: String
    let collecting: String
    let now: String
    let intervalHint: String
    let seconds: String
    let minutes: String
    static func text(_ language: AppLanguage) -> Self {
        switch language {
        case .zhHans:
            return Self(range: "时间范围", history: "趋势图", collecting: "正在积累历史，未采集的时段留空", now: "现在",
                        intervalHint: "后台按此间隔采集监视数据，保留最近 5 分钟。隐藏图表不停止记录。", seconds: "秒", minutes: "分钟")
        case .zhTW, .zhHK:
            return Self(range: "時間範圍", history: "趨勢圖", collecting: "正在累積歷史，未採集的時段留空", now: "現在",
                        intervalHint: "背景依此間隔採集監視資料，保留最近 5 分鐘。隱藏圖表不停止記錄。", seconds: "秒", minutes: "分鐘")
        default:
            return Self(range: "Time range", history: "History", collecting: "Collecting history. Unsampled periods stay empty.", now: "Now",
                        intervalHint: "Monitor readings are collected in the background for five minutes. Hiding charts keeps recording.", seconds: "s", minutes: "min")
        }
    }
}
