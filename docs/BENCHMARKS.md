# 历史对标索引

> 核查：2026-09-09。当前采用与排除项以 [ROADMAP.md](ROADMAP.md#对标软件) 为准。

## 来源与适用范围

主要来源是 PathGao 发布的 [Related Apps Summary #880](https://github.com/vorssaint/vorssaint-utils/issues/880)。它汇总了社区提出的参考软件，不能把每个名字都解释成作者亲自选定的产品目标。此次同时检索了该账号在上游的 12 条自建 issue 和 1,342 条 issue / PR 会话评论。

原汇总以 Vorssaint 3.3.3、提交 `006ce953` 为基线。本索引只保留名字、比较领域与出处，旧文档中的缺失功能和优劣判断不能直接套到当前 kururu。涉及已放弃的窗口布局、应用更新器等领域，仅留历史记录。

本轮确认已将上一轮列出的模块参考纳入 roadmap，并明确加入 **Mac Mouse Fix**。Mac Mouse Fix 也出现在 #880 的次级名单中；本文件继续保留历史分组，当前对标状态统一查 roadmap。

## 主要历史参考

下表来自 #880 的 23 个主要条目，按领域合并。除明确标注外，均是原汇总收录的社区引用。

| 领域 | 软件 | 当时比较的内容 |
|---|---|---|
| 命令栏 | Raycast | 搜索、入口与命令交互 |
| 截图与录屏 | CleanShot X、Shottr | 截图预览、编辑和捕获体验 |
| 系统监控 | Stats、iStat Menus | 指标呈现、菜单栏排布 |
| 鼠标 | Mos、LinearMouse | 滚动、排除列表和按键行为 |
| 访达与系统操作 | Supercharge | 访达快捷键与系统开关 |
| 菜单栏管理 | Ice、Bartender、Thaw / iBar Pro | 隐藏分层、展开和排序 |
| 窗口切换 | AltTab | 切换交互和响应速度 |
| 声音 | SoundSource | 音频路由与设备操作 |
| Dock | DockDoor | 悬停预览、拖放和卡片呈现 |
| 窗口布局 | Rectangle / Rectangle Pro | 布局与快捷键，仅作历史记录 |
| 键盘 | Hyperkey | Caps Lock 组合修饰键 |
| 显示器 | BetterDisplay | 显示控制 |
| 剪贴板 | Maccy | 历史与粘贴体验，现已退出当前对标 |
| 触控板 | MiddleClick | 三指中键 |
| 卸载与清理 | AppCleaner、Pearcleaner | 卸载入口与残留扫描 |
| 更新检测 | Latest | 汇总作者主动补充，社区相关引用是 Mole / Updatest；不恢复更新器计划 |
| URL 清理 | ClearURLs | 汇总作者主动补充的规则模型参考 |

**名称区别：** 本轮用户停用的是「Superpower」，历史汇总写的是「Supercharge」。两者不擅自视为同一个名称，Supercharge 也不因此加入当前目标。

## 有进一步出处的参考

- **H1 · 手势：Swish。** [自定义手势 #967](https://github.com/vorssaint/vorssaint-utils/issues/967) 中出现，AltTab 同时作为触摸事件实现参考。
- **H2 · 多设备音频：PairPods、Tutti。** [多输出与独立延迟 #966](https://github.com/vorssaint/vorssaint-utils/issues/966) 分别涉及同时输出和每设备延迟。
- **H3 · 端口：PortKiller。** [范围取舍评论](https://github.com/vorssaint/vorssaint-utils/issues/880#issuecomment-5392800870) 区分端口查询与端口转发 / SSH 隧道；[命令栏覆盖 #977](https://github.com/vorssaint/vorssaint-utils/issues/977) 提过端口查询入口。当前入口以 roadmap 的网络页计划为准。
- **H4 · 截图翻译：MoePeek。** [翻译讨论中的归并记录](https://github.com/vorssaint/vorssaint-utils/issues/489#issuecomment-5404742486) 收录了报告者的参考，尚不表示采用。

现有 roadmap 另有 **TextSniper**（快捷 OCR）和 **Screen Studio**（录屏体验）。这是路线图已有内容，不冒充本次从 #880 新发现的条目。**Atoll、Notchy、Deck、Frest** 来自本轮明确指定，在上述历史检索中未发现同名记录。

## 其余历史名称

以下是 #880 的次级参考原名单，只作检索入口。动到相应领域时再读原 issue，不能仅凭软件名字推导功能需求。

<details>
<summary>展开次级参考名单</summary>

easy-move-resize, Swift Shift, Swish, AeroSpace, BetterTile, Tangrid, Better Stage, Glide, FloatyTool, AlwaysOnTop, PowerToys Always on Top, Space Rabbit, Blink, WhichSpace, Spaceman, InstantSpaceSwitcher, Wins, DockView 2, MarqueeText, Docky, Sol, Karabiner-Elements, Hammerspoon, KeyCue, KeyClu, Klack, KeyboardCleanTool, debounce-mac, Vimium, Mac Mouse Fix, BetterMouse, Logi Options+ / OpenLogi, Tutti, PairPods, AirPodsSanity, podsmute, AudioControlBar, eqMac, Boom, SoundSwitch (Windows), LightsOut, MonitorControl, AlDente, batt, Amphetamine, KeepingYouAwake, MacShot, PixPin, Snipaste, Snapzy, Yoink, Dropzone, Clop, Fasa, OpenInTerminal, RightMenu Master, Android File Transfer, Mole, Updatest, only-switch, Hand Mirror, Camera Preview, Antinote, ScreenScribe, LocalSend, Blip, Mouseless, Textream, SelfControl, PanicLock, TimeMachineEditor, Bluesnooze, WidgetScreen, PortKiller, Hidden File Cleaner, PDF Squeezer, PDFsam, BentoPDF, Onigiri, QuickConvert, noTunes, mactop, PeakHour, Tencent Lemon

</details>

## 不应转换成对标待办的提及

- **N1 · 替代软件建议。** 拒绝集成 MTP 时推荐的 [OpenMTP、LocalSend、calibre、MacDroid、Commander One](https://github.com/vorssaint/vorssaint-utils/issues/531#issuecomment-5409262178)，拒绝 Touch Bar 支持时推荐的 [Pock、MTMR](https://github.com/vorssaint/vorssaint-utils/issues/333#issuecomment-5409516268)，以及拒绝设备协议支持时推荐的 [OpenLogi](https://github.com/vorssaint/vorssaint-utils/issues/575#issuecomment-5409548641)，都不意味着计划重做这些功能。
- **N2 · 明确未采用的依赖。** [SoulverCore 讨论](https://github.com/vorssaint/vorssaint-utils/issues/947#issuecomment-5417052907) 是不采用的记录。
- **N3 · 兼容性报告。** #880 将 GeForce NOW、Parallels、Ghostty / iTerm2 / Warp、Deskflow / Barrier、Chromium 浏览器、BeyondTrust EPM、OBS、DaVinci Resolve 等另列为冲突对象，不是产品对标。Ice、Thaw、AppCleaner 等同时在其他上下文作为功能参考，需按具体引用区分。
