# kururu

Forked from vorssaint-utils and currently under rapid, active development. Still in BETA.  

A macOS utility workspace for controls, monitoring, input, captures and everyday file work. Features can be selected independently. The current direction is one consistent interface: explain what runs in the background, keep configuration visible while paused, and show the result of each action where it happens.

Current release: [kururu 0.1.0](https://github.com/PathGao/kururu/releases/tag/v0.1.0), for Apple Silicon on macOS 14 or later. The downloadable app is locally signed and has not been notarized by Apple.

This repository is under active integration. The [roadmap](docs/ROADMAP.md) distinguishes implemented work from remaining interaction checks. Existing screenshots and release notes inherited from upstream are historical references, not previews of the current kururu build.

## Current capabilities

- System and battery monitoring, display controls, local TCP/UDP port inspection, per-app audio and microphone controls.
- Window, Dock, keyboard and mouse utilities, a command bar, and radial menus with shortcut, mouse and trackpad entry points.
- Clipboard history, snippets, notes, a file shelf, screen capture, recording, text recognition and color picking.
- Local media conversion and editing, ordered PDF merging, and PDF image optimization with a no-savings result when a smaller verified copy cannot be produced.
- Cleaner, uninstaller and an installed Homebrew package list, with upgrades for explicitly requested packages.

Availability depends on the selected features, macOS permissions and hardware. Privileged fan control and kururu self-updates are unavailable until this product has its own release signing configuration. Temporary upload links have been removed. Feedback can be prepared and copied locally; opening the project issue page does not submit it.

## Build and verify

Requires Apple Silicon, macOS 14 or newer, and Xcode Command Line Tools.

```sh
git clone https://github.com/PathGao/kururu.git
cd kururu
./build.sh --test
./build.sh --dev
```

The development app is staged at `build/stage/kururu (Developer).app`. Development builds require an already configured local signing identity; the build does not create a certificate or change the keychain. `./build.sh` assembles the release variant locally. Neither command publishes a release or installs the app. Installation is a separate explicit `--install` action.

| Variant | Bundle identifier | Executable |
|---|---|---|
| Release | `com.pathgao.kururu` | `kururu` |
| Development | `com.pathgao.kururu.dev` | `kururuDeveloper` |

Both variants derive their metadata from `Sources/Vorssaint/Core/ProductIdentity.swift`. The internal source directory name remains stable to keep integration changes reviewable.

## Existing settings and data

kururu starts with its own preferences and storage. It does not automatically take over another application's data, permissions, login item or privileged helper. To transfer supported preferences, export a settings file from the existing app and import it through General & appearance settings (通用与外观) in kururu. Login registration and machine restoration records are excluded. Select login at startup explicitly in the new app if needed.

Clipboard history, notes and shelf files are separate from settings backups and remain with their original application. Notes can be explicitly imported from JSON or UTF-8 text, and clipboard history from JSON or a legacy preferences plist. Clipboard images require their source image directory. These imports preview selected records and append copies; they do not move or remove the source data. Shelf settings also provide explicit JSON or legacy-plist import with whole-group selection. For each source folder, choose its current location and whether to reference originals or copy attachments. Folder items support references only. Imported groups keep their stored titles and hierarchy across relaunches. These import flows still need live window interaction verification.

To inspect an uninstall plan without changing anything:

```sh
./Tools/uninstall.sh --dev --app "build/stage/kururu (Developer).app" --dry-run
```

Removing `--dry-run` performs the uninstall after identity checks. The script targets only the selected kururu variant.

## Documentation and provenance

- [Roadmap](docs/ROADMAP.md): current product scope and remaining work.
- [Privacy](docs/PRIVACY.md): local storage and feature-specific network access.
- [Contributing](CONTRIBUTING.md): source layout and development conventions.
- [Project repository](https://github.com/PathGao/kururu): source and issue tracking.

kururu is derived from [Vorssaint](https://github.com/vorssaint/vorssaint-utils). Upstream copyright notices and the [GPL-3.0-or-later license](LICENSE) are retained. The upstream [trademark notice](TRADEMARKS.md) remains available as provenance. This fork has its own product name, identifiers and octopus mark; it is not an official Vorssaint release.
