<p align="center">
  <img src="Resources/Brand/logo.png" alt="kururu 章鱼图标" width="128" height="128">
</p>

<h1 align="center">kururu</h1>

<p align="center">
  <strong>日常 Mac 工具，汇集在菜单栏。</strong><br>
  系统监控、窗口控制、剪贴板、屏幕捕获与文件工具。<br>
  免费开源，使用 Swift 和 macOS 原生框架构建。
</p>

<p align="center">
  <a href="https://github.com/PathGao/kururu/releases/latest">下载</a> ·
  <a href="#功能">功能</a> ·
  <a href="docs/PRIVACY.md">隐私</a> ·
  <a href="#构建与验证">构建</a> ·
  <a href="https://github.com/PathGao/kururu/issues">反馈</a> ·
  <a href="README.md">English</a>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/macOS-14%2B-111827" alt="macOS 14 或更新版本">
  <img src="https://img.shields.io/badge/Apple_Silicon-arm64-111827" alt="Apple Silicon，arm64">
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-GPL--3.0--or--later-111827" alt="许可证：GPL-3.0-or-later"></a>
</p>

kururu 把工作中常见的小事集中到一处：查看谁在占用内存、调整某个应用的音量、找回复制过的内容、识别屏幕上的文字，或把文件暂存起来稍后使用。按需启用功能页，在统一的设置界面中配置。

kururu 分叉自 [Vorssaint](https://github.com/vorssaint/vorssaint-utils)，目前处于 **Beta 阶段**，正在快速开发中。[路线图](docs/ROADMAP.md) 记录已实现的工作和尚待完成的交互验证。仓库中继承自上游的截图和演示仅供历史参考，不代表当前 kururu 版本的界面。

## 安装

**[下载适用于 Apple Silicon 的 kururu](https://github.com/PathGao/kururu/releases/latest)**

需要搭载 **Apple Silicon 芯片的 Mac**，运行 **macOS 14 或更新版本**。当前发布版本为 [0.1.0](https://github.com/PathGao/kururu/releases/tag/v0.1.0)。

1. 从发布页下载 DMG。
2. 打开 DMG，将 kururu 拖入“应用程序”。
3. 启动 kururu，选择需要的功能，并授予相应权限。

> **早期版本：** 下载的应用使用本地签名，尚未经过 Apple 公证，因此 macOS 可能阻止首次启动。目前不支持自动更新，请从发布页下载新版本。

## 功能

### 监控 Mac 状态

查看 CPU、GPU、内存、网络、磁盘和电源指标，通过历史曲线了解变化。检查电池健康与活动情况，需要定位进程时，还可以查询本机 TCP 监听端口和 UDP 绑定端口。

### 窗口、Dock 与输入设备

切换窗口、从 Dock 预览窗口，并配置 Dock 点击动作和窗口行为。调整鼠标滚动和按键，使用三指中键、文字片段展开，或配置用于快捷键的 Super key。

### 剪贴板与日常文件

搜索剪贴板历史、保留常用项目、粘贴纯文本。把文件收集到暂存架，随手记下便条，并使用访达剪切粘贴和重命名工具，减少工作中的来回切换。

### 捕获与内容处理

截屏、录屏、识别屏幕文字和取色。在本地转换和编辑媒体，按指定顺序合并 PDF，并优化 PDF 中的图片。如果无法生成体积更小且通过验证的副本，PDF 优化会明确告知。

### 声音、显示与专注

分别调整各个应用的音量、切换音频输出、将麦克风静音。使用显示控制、保持唤醒、蓝牙睡眠相关设置，以及输入设备清洁模式。

### 应用与维护

查找可清理的项目，用卸载器检查应用残留，并查看已安装的 Homebrew 软件包。升级自己主动安装的软件包，在环境页检查本地开发工具。升级指定软件包时，Homebrew 也可能连带升级其依赖。

### 选择适合你的入口

通过菜单栏使用常用控制项，通过命令栏查找操作，或通过快捷键、鼠标和触控板调用径向菜单。功能页可以分别启用，停用后仍可查看和调整设置。

功能是否可用取决于你的选择、macOS 权限和硬件。在 kururu 配置自己的发布签名前，需要特权的风扇控制暂不可用。临时上传链接已停用。

## 隐私与权限

偏好设置、剪贴板历史、便条和暂存架数据保存在 kururu 自己的本地存储中。屏幕文字识别使用 Apple 的设备端 Vision 框架。无需账号，没有订阅，也不自动收集遥测数据。

网络访问对应具体操作：网络测速、Homebrew 操作，或你在命令栏中配置的网站和脚本。反馈内容先在本地生成，供你检查和复制；打开 issue 页面不会提交反馈。

按所用功能授予 macOS 权限，并在**系统设置 → 隐私与安全性**中查看和调整。存储细节与网络访问范围见[隐私政策](docs/PRIVACY.md)。

## 现有设置与数据

kururu 使用独立的应用身份，不会自动接管其他应用的数据、权限、登录项或特权辅助程序。

要转移受支持的偏好设置，请先从原应用导出设置文件，再到 kururu 的**通用与外观**（General & appearance）中导入。设置备份不包含剪贴板历史、便条或暂存架文件。

<details>
<summary><strong>导入格式与独立保留的内容</strong></summary>

| 数据 | 支持的导入格式 | 行为 |
|---|---|---|
| 偏好设置 | 导出的设置文件 | 不包含登录项注册和本机系统设置恢复记录。开机启动需要单独启用。 |
| 便条 | JSON 或 UTF-8 文本 | 预览选中的记录，以副本形式追加。 |
| 剪贴板历史 | JSON 或旧版偏好设置 plist | 预览选中的记录，以副本形式追加。图片需要指定原图片目录。 |
| 暂存架 | JSON 或旧版偏好设置 plist | 整组选取，为每个来源文件夹指定当前位置，再选择引用原文件或复制附件。文件夹项目仅支持引用。 |

这些导入操作不会移动或删除源数据。导入的暂存架分组在重新启动后仍保留原有标题和层级。部分导入交互仍需实际验证，剩余检查见[路线图](docs/ROADMAP.md)。

</details>

## 构建与验证

需要 Apple Silicon、macOS 14 或更新版本，以及 Xcode Command Line Tools。应用使用 `swiftc` 和 macOS 原生框架构建，无外部软件包依赖，也无需 Xcode 工程。`Package.swift` 用于支持编辑器索引。

```sh
git clone https://github.com/PathGao/kururu.git
cd kururu
./build.sh --test
./build.sh --dev
```

开发版应用输出到 `build/stage/kururu (Developer).app`。**构建开发版需要已有的可用签名身份。** 构建过程不会创建证书或修改钥匙串。签名要求见[贡献指南](CONTRIBUTING.md#build-identity-and-signing)。

运行应用自检：

```sh
"./build/stage/kururu (Developer).app/Contents/MacOS/kururuDeveloper" --selftest
```

<details>
<summary><strong>构建变体与卸载</strong></summary>

`./build.sh` 在本地组装正式版。上述两种构建命令均不会发布或安装应用。需要安装时，显式添加 `--install`。

| 变体 | Bundle 标识符 | 可执行文件 |
|---|---|---|
| 正式版 | `com.pathgao.kururu` | `kururu` |
| 开发版 | `com.pathgao.kururu.dev` | `kururuDeveloper` |

两种变体的元数据均来自 [`ProductIdentity.swift`](Sources/Vorssaint/Core/ProductIdentity.swift)。保留内部目录名 `Sources/Vorssaint/`，便于审阅集成改动。

仅查看卸载计划，不做任何更改：

```sh
./Tools/uninstall.sh --dev --app "build/stage/kururu (Developer).app" --dry-run
```

移除 `--dry-run` 后，脚本会在身份检查通过后执行卸载。脚本仅处理所选的 kururu 变体。

</details>

## 参与贡献与反馈

欢迎提交问题报告、有明确范围的改进和翻译。报告问题时，请提供 kururu 版本、macOS 版本、复现步骤和预期行为。应用内反馈可以生成本地草稿，供你复制到 [GitHub issue](https://github.com/PathGao/kururu/issues)。

| 资料 | 内容 |
|---|---|
| [贡献指南](CONTRIBUTING.md) | 源码结构、构建约定和贡献流程 |
| [路线图](docs/ROADMAP.md) | 产品范围、已实现的工作和待验证事项 |
| [隐私政策](docs/PRIVACY.md) | 本地存储、导入和网络访问 |
| [发布版本](https://github.com/PathGao/kururu/releases) | 下载与各版本发布说明 |

## 致谢与许可

kururu 衍生自 **[Vorssaint](https://github.com/vorssaint/vorssaint-utils)**。感谢其作者和贡献者，为本项目提供了基础。

代码采用 **[GPL-3.0-or-later](LICENSE)** 许可，保留上游版权声明。kururu 使用自己的产品名称、应用标识符和章鱼标识，并非 Vorssaint 官方版本。上游[商标声明](TRADEMARKS.md) 作为来源记录保留。
