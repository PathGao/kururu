<p align="center">
  <img src="Resources/Brand/logo.png" alt="kururu horn spirit icon" width="128" height="128">
</p>

<h1 align="center">kururu</h1>

<p align="center">
  <strong>Everyday Mac tools, together in your menu bar.</strong><br>
  System monitoring, window controls, clipboard, captures and file tools.<br>
  Free and open source. Built with Swift and native macOS frameworks.
</p>

<p align="center">
  <a href="https://github.com/PathGao/kururu/releases/latest">Download</a> ·
  <a href="#features">Features</a> ·
  <a href=".github/CONTRIBUTING.md">Development</a> ·
  <a href="#build-and-verify">Build</a> ·
  <a href="https://github.com/PathGao/kururu/issues">Feedback</a> ·
  <a href="README.zh-Hans.md">简体中文</a>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/macOS-14%2B-111827" alt="macOS 14 or later">
  <img src="https://img.shields.io/badge/Apple_Silicon-arm64-111827" alt="Apple Silicon, arm64">
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-GPL--3.0--or--later-111827" alt="License: GPL-3.0-or-later"></a>
</p>

kururu brings the small tasks around your work into one place: check what's using memory, adjust an app's volume, find something you copied, capture text from the screen, or collect files for later. Choose the feature pages you need and configure them in a shared settings interface.

Forked from [Vorssaint](https://github.com/vorssaint/vorssaint-utils), kururu is in **beta** and under rapid, active development. The [roadmap](ROADMAP.md) tracks implemented work and remaining interaction checks.

## Install

**[Download kururu for Apple Silicon](https://github.com/PathGao/kururu/releases/latest)**

Requires **macOS 14 or later** on an **Apple Silicon Mac**. The current release is [0.1.2](https://github.com/PathGao/kururu/releases/tag/v0.1.2).

1. Download the DMG from the release page.
2. Open it and drag kururu to Applications.
3. Launch kururu, choose your features, and grant the permissions they need.


## Features

### Monitor your Mac

CPU, GPU, memory, network, disk and power readings, with history graphs for checking changes over time. Inspect battery health and activity, or look up local TCP listening and UDP bound ports when you need to identify a process.

### Windows, Dock and input

Switch between windows, preview them from the Dock, and configure Dock clicks and window behavior. Adjust mouse scrolling and buttons, use a three-finger middle click, expand text snippets, or configure a Super key for shortcuts.

### Clipboard and everyday files

Search clipboard history, keep frequently used items, and paste plain text. Collect files on the shelf, write quick notes, and use Finder cut-and-paste and rename tools without leaving your workflow.

### Capture and process content

Take screenshots, record the screen, recognize text on screen and pick colors. Convert and edit media locally, merge PDFs in a chosen order, and optimize PDF images. PDF optimization reports when it cannot produce a smaller verified copy.

### Sound, displays and focus

Adjust volume per app, switch audio outputs and mute microphones. Access display controls, keep-awake options, Bluetooth sleep behavior and a cleaning mode for input devices.

### Apps and maintenance

Find cleanup candidates, inspect app leftovers with the uninstaller, and review installed Homebrew packages. Upgrade packages you explicitly installed, and inspect local development tools in the environment page. It distinguishes bundled tools from recognized user installations. Optional update hints cover standalone Bun and uv and explicitly installed Homebrew tools, excluding pinned versions and dependencies. The environment page uses compact source groups and expandable paths, and lists discovered configuration files with their full locations. Eligible Homebrew tools use the existing package upgrade flow directly; standalone tools link to upgrade instructions. Homebrew may also upgrade dependencies as part of a requested package upgrade.

### Your choice of entry point

Use the menu bar for frequent controls, the command bar to find actions, or radial menus for shortcut, mouse and trackpad access. Feature pages can be enabled separately; settings remain available while a page is disabled.

Feature availability depends on your selections, macOS permissions and hardware. Privileged fan control is unavailable until kururu has its own release signing configuration. Temporary upload links are disabled.

## Privacy and permissions

Preferences, clipboard history, notes and shelf data stay in kururu's own local storage. Screen text recognition uses Apple's on-device Vision framework. There is no account, subscription or automatic telemetry.

Network access belongs to specific actions: an internet speed test, Homebrew operations, checking tool releases on GitHub, or websites and scripts you configure in the command bar. Feedback is prepared locally for you to review and copy; opening the issue page does not submit it.

Grant macOS permissions for the features you use and review them in **System Settings → Privacy & Security**. See the [data and privacy documentation](.github/CONTRIBUTING.md#privacy) for storage details and the scope of network access.

## Existing settings and data

kururu has its own application identity. It does not automatically take over another application's data, permissions, login item or privileged helper.

To transfer supported preferences, export a settings file from the existing app and import it in kururu under **General & appearance** (通用与外观). Settings backups do not include clipboard history, notes or shelf files.

<details>
<summary><strong>Import formats and what stays separate</strong></summary>

| Data | Supported import | Behavior |
|---|---|---|
| Preferences | Exported settings file | Excludes login registration and machine restoration records. Enable launch at login separately. |
| Notes | JSON or UTF-8 text | Preview selected records and append copies. |
| Clipboard history | JSON or a legacy preferences plist | Preview selected records and append copies. Images need their source image directory. |
| Shelf | JSON or a legacy preferences plist | Select whole groups, map each source folder, then choose references or copied attachments. Folders support references only. |

These imports do not move or remove the source data. Imported shelf groups retain their stored titles and hierarchy across relaunches. Some import interactions still need live verification; see the [roadmap](ROADMAP.md) for the remaining checks.

</details>

## Build and verify

Requires Apple Silicon, macOS 14 or later, and Xcode Command Line Tools. The app builds with `swiftc` and native macOS frameworks, without external package dependencies or an Xcode project. `Package.swift` supports editor indexing.

```sh
git clone https://github.com/PathGao/kururu.git
cd kururu
./build.sh --test
./build.sh --dev
```

The development app is staged at `build/stage/kururu (Developer).app`. **Development builds require an existing usable signing identity.** The build does not create certificates or change the keychain. See [Contributing](.github/CONTRIBUTING.md#build-identity-and-signing) for signing requirements.

Run the app's self-checks:

```sh
"./build/stage/kururu (Developer).app/Contents/MacOS/kururuDeveloper" --selftest
```

<details>
<summary><strong>Build variants and removal</strong></summary>

`./build.sh` assembles the release variant locally. Neither build command publishes or installs the app. Add `--install` explicitly to install it.

| Variant | Bundle identifier | Executable |
|---|---|---|
| Release | `com.pathgao.kururu` | `kururu` |
| Development | `com.pathgao.kururu.dev` | `kururuDeveloper` |

Both variants derive their metadata from [`ProductIdentity.swift`](Sources/Vorssaint/Core/ProductIdentity.swift). The internal `Sources/Vorssaint/` directory name is retained to keep integration changes reviewable.

Inspect an uninstall plan without changing anything:

```sh
./Tools/uninstall.sh --dev --app "build/stage/kururu (Developer).app" --dry-run
```

Removing `--dry-run` performs the uninstall after identity checks. The script targets only the selected kururu variant.

</details>

## Contributing and feedback

Bug reports, focused improvements and translations are welcome. For a bug report, include your kururu version, macOS version, steps to reproduce and what you expected to happen. In-app feedback can prepare a local draft for you to copy into a [GitHub issue](https://github.com/PathGao/kururu/issues).

Support is provided on a best-effort basis, without a guaranteed response time. For feature requests, describe the problem you want solved. Please keep vulnerability details out of public issues and read the [security policy](.github/SECURITY.md) first.

| Resource | What it covers |
|---|---|
| [Development guide](.github/CONTRIBUTING.md) | Building, contributing, AI collaboration, privacy, permissions and troubleshooting |
| [Roadmap](ROADMAP.md) | Product scope, implemented work and pending verification |
| [Releases](https://github.com/PathGao/kururu/releases) | Downloads and release-specific notes |

## Acknowledgments and license

kururu is derived from **[Vorssaint](https://github.com/vorssaint/vorssaint-utils)**. Thanks to its author and contributors for the foundation this project builds on.

The code is licensed under **[GPL-3.0-or-later](LICENSE)**, with upstream copyright notices retained. kururu has its own product name, application identifiers and octopus mark, and is not an official Vorssaint release.

<details>
<summary><strong>Branding and redistribution</strong></summary>

The GPL license covers copyright in the source code. It does not grant
permission to use the kururu or Vorssaint name, logo, icon, bundle identity,
trade dress, official branding or signing identity controlled by the respective
project maintainer. Vorssaint branding remains associated with the upstream
project.

Official builds are distributed by each project's maintainer. Unofficial forks
and redistributed builds must use a different name, app icon, bundle identifier,
signing identity, update feed and other branding that could imply endorsement
or official status. Do not present a modified build as kururu, Vorssaint or an
official release without explicit permission from the respective maintainer.

</details>
