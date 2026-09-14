# Development and contribution guide

Build, debug and contribute to kururu. This guide also records local data
boundaries, feature permissions and troubleshooting. User-facing installation
and feature information stays in the [README](README.md).

[Build](#getting-started) · [Source layout](#project-layout) ·
[Contributions](#pull-requests) · [AI collaboration](#working-with-an-agent) ·
[Privacy](#privacy) · [Permissions](#permissions) · [Troubleshooting](#troubleshooting)

## License for contributions

Unless it is stated otherwise, contributions to this repository are accepted
under GPL-3.0-or-later.

## Getting started

```sh
git clone https://github.com/PathGao/kururu.git
cd kururu
./build.sh --test
./build.sh --dev
"./build/stage/kururu (Developer).app/Contents/MacOS/kururuDeveloper" --selftest
```

You need macOS 14 or newer, Apple Silicon and the Xcode Command Line Tools. The
build is a plain `swiftc` invocation, see `build.sh`, with no Xcode project and
no external dependencies, reproducible by design. `Package.swift` is there so
SwiftPM aware editors can index the code.

Hitting a build or permission snag while developing? See the
[troubleshooting guide](#troubleshooting).

### Build identity and signing

The [build instructions](README.md#build-and-verify) describe the current release and
development identities. A development build is staged locally; installing
it requires an explicit `--install` action.

Development and installed builds require an existing usable Developer ID or
the existing local `Vorssaint Utils Signing` certificate. If neither can sign,
the build stops. It does not create certificates or change keychains.
The legacy certificate name is a local lookup key, not the app's bundle ID.

`Tools/setup-signing.sh` is an inherited, explicit keychain-changing tool,
not a prerequisite automatically run by the build. Do not run it as a routine
build repair. kururu uses its own application identity and does not inherit
another application's permission grants.

Official signing, notarization and release configuration remain pending in
the [roadmap](ROADMAP.md). An existing local signing certificate or a
successful development build is not evidence that distribution is configured.

## Project layout

| Folder | Role |
|---|---|
| `Sources/Vorssaint/App` | App lifecycle and the menu bar status item |
| `Sources/Vorssaint/Core` | Localization, permissions, UserDefaults keys |
| `Sources/Vorssaint/Services` | All behavior, like energy, monitor, scroll and switcher |
| `Sources/Vorssaint/UI` | SwiftUI views only, no business logic |
| `Sources/Vorssaint/Support` | `--selftest` and `--sensors` diagnostics |
| `Tools` | Icon generator and DMG packaging |

A few conventions to keep in mind.

- **UI observes services, and services never import SwiftUI.** Keep that boundary.
- Singletons are exposed as `Type.shared` and publish state with Combine through
  `ObservableObject`, with no Observation macros, since the project builds with
  the Command Line Tools.
- Comments explain *why*, not *what*. Keep them rare and useful.
- No new dependencies without talking it over first in an issue.

## Strings and translations

User-facing strings live in `Core/Localization.swift` and feature-specific
catalogs under `Core/`. In `Strings`, English text is required as each field's
default value, and `Strings.enUS` uses those defaults. Other languages may
provide partial catalogs: omitted fields keep their English defaults. The
compiler checks field types, not translation completeness. Feature catalogs
that use the same defaults follow this rule; catalogs with explicit language
switches must still handle every `AppLanguage` case.

The current language picker still offers 13 locales: English (US), Português
(Brasil), Türkçe, Русский, Español, Deutsch, Français, Italiano, 日本語, 한국어,
简体中文, 繁體中文（台灣） and 繁體中文（香港）. The roadmap's six official
languages (English, Simplified Chinese, German, French, Spanish and Japanese)
are the planned support scope; the other seven have not been removed from the
current implementation.

Non-base `Strings` translations live in `Core/Localizations/`. To add a
language, add an `AppLanguage` case, wire it into catalog selection, provide
translations or English fallback as each catalog requires, register the locale
in `Resources/Info.plist`, add localized permission prompts under
`Resources/<locale>.lproj/` when needed, and extend the localization coverage
tests. A new field in a catalog with English defaults does not require filling
in every translation.

## Sensors on new chips

Temperature mapping lives in `SystemMonitor.prepareSensorsIfNeeded()`. CPU keys
look like `Tp…` and `Te…`, GPU is `Tg…`, and battery runs from `TB0T` to
`TB2T`. If a new Apple Silicon generation renames the keys, run this

```sh
"./build/stage/kururu (Developer).app/Contents/MacOS/kururuDeveloper" --sensors
```

and open a PR with the dump and the adjusted prefixes.

## Reporting bugs and requesting features

You do not need to write code to help. Use the issue forms on the
[new issue](https://github.com/PathGao/kururu/issues/new/choose) page.

- **Bug report.** Include your kururu version from Settings under About and
  your macOS version, plus clear steps to reproduce. The
  [troubleshooting guide](#troubleshooting) explains what makes a report
  useful.
- **Feature request.** Describe the problem you are trying to solve rather than
  only a specific solution.

For general help and feedback, see the [README](README.md#contributing-and-feedback).
See [the security policy](.github/SECURITY.md) before sharing vulnerability details.

## Pull requests

Participation follows the [Code of Conduct](.github/CODE_OF_CONDUCT.md).

1. Follow the current [roadmap](ROADMAP.md). Reference applications and
   historical upstream decisions do not independently authorize new scope.
2. Keep one reviewable topic per change. Describe the trigger, resulting
   behavior, relevant validation and remaining limitations.
3. Run `./build.sh --test`, build the changed app and run its `--selftest`.
   Record real-window or hardware checks separately from isolated tests.
4. User-facing text follows the catalog defaults and language rules above.
   Verify English fallback and the six official languages affected by a change.
5. Fix the cause and inspect other callers of the same behavior. Preserve
   input, configuration and user data when an operation fails or is cancelled.
6. Use `type(scope): lowercase imperative phrase` for a proposed commit or
   PR title. Reference related issues explicitly, such as `Refs #123`.
7. Leave release notes and version changes to the maintainer unless they are
   part of the requested work.
8. Local work does not authorize committing, pushing, opening a PR or sending
   messages. Obtain the user's explicit instruction for those actions.

## Working with an agent

The same contribution rules apply regardless of the tools used. Review the
change yourself before submitting it; you do not need to declare your tools.

- **Check existing work first.** Search open and closed issues and PRs, then
  read the relevant code path and its callers. The roadmap defines current
  scope; historical upstream decisions are context, not new requirements.
- **Reuse what the app already handles.** Permission prompts, file writes,
  window handling and shortcuts have failure and recovery behavior. Check
  those boundaries before adding a new mechanism or dependency.
- **Check interaction expectations.** For shortcuts, window behavior and file
  operations, compare the platform's intended use and established apps.
  Explain a deliberate difference in the PR. Keep destructive actions away
  from their constructive counterparts.
- **Fix the shared cause.** Inspect sibling callers, persisted settings and
  upgrade behavior. A guard should cover the intended cases without blocking
  unrelated ones. Preserve input, settings and data when an action fails.
- **Verify the claim, not just compilation.** Unit tests compile a selected
  source list and do not prove the whole app builds. Build and run self-checks
  for app changes; verify window, permission and hardware behavior separately.
  A successful system call is not proof that the intended effect occurred.
- **Use meaningful regression checks.** Test behavior where possible. Source
  checks belong to contracts that cannot be exercised at runtime, not private
  names or formatting. Confirm the check fails without the fix and passes
  with it. Before removing a test, demonstrate that another check still
  catches the defect it protected against.
- **Keep handoff concise.** State the change, its reason, verification and
  untested cases. Distinguish observed results from assumptions. Record
  prerequisite PRs and merge order when changes depend on each other.

Existing usable signing is required for development builds. Follow the
[signing requirements](#build-identity-and-signing); do not create certificates
or change the keychain as a routine repair. Do not commit, push, publish or
send messages without the user's authorization.

## Releases (maintainers)

Release readiness is tracked in the [roadmap](ROADMAP.md). Confirm
kururu's own signing, notarization, updater and publishing configuration
before enabling a release workflow. A local build does not authorize tagging,
pushing, publishing or changing repository secrets.

When preparing a release, fill in the template in [CHANGELOG.md](CHANGELOG.md)
with the version, date and user-facing changes. The build bundles this file,
and the release workflow uses the matching section for GitHub release notes.

## Privacy

kururu stores preferences and feature data locally in its own application domain. It has no account or hosted feedback service. This page describes the current fork, including the disabled release capabilities.

### The short version

- **No account.** There is nothing to sign up for and nobody to log in as.
- **No subscription.** The app is free and stays free, with nothing held back behind a paid tier.
- **No automatic telemetry.** kururu sends no usage stats, crash reports or device identifiers to an analytics service. The command bar keeps local ranking data as described below. Feedback includes technical details in a local draft only when you select them after seeing the complete list.
- **No kururu analytics or tracking.** There are no analytics kits, no ad networks and no third party tracking anywhere in the app.
- **No data selling.** kururu never sells personal information or shared screenshots and recordings.
- **Your settings stay put.** Preferences and saved state live in the app's own local storage on your Mac and are never uploaded.

### What it reads, and where that stays

Everything kururu shows you, from the CPU and memory load to the temperatures, the battery details, the network rates, the window list, per app volume and the files on the Shelf, is read locally through native macOS APIs and shown to you right there. None of it is sent anywhere, logged remotely or shared.

Clipboard history, including the images and files you copy, lives in the app's local storage on your Mac and never leaves it. Copy text from screen recognizes the text entirely on device with Apple's Vision framework, and the temporary capture is deleted as soon as the text is read. Automatic clearing, when you switch it on, only empties the system clipboard on this Mac: nothing is sent anywhere, and items already saved to your history are left as they are.

Recent Captures keeps up to 12 screenshots, within a 256 MB limit, in the app's private local cache so you can reopen them. Recordings are not duplicated: only their existing path and a small thumbnail are kept. Clear removes that history and its cached images. When a screenshot is copied as a file, its private local PNG is kept temporarily so other apps can finish reading it, then cleaned on later copies once it is older than 24 hours or earlier when the bounded cache fills. None of these local caches is uploaded automatically.

The command bar learns which durable results you choose to improve local ranking. Preferences retain result identifiers, use counts, last-use times and keyed digests of query prefixes. The installation key is stored separately in Keychain; the ranking store does not save the original query text. Query text and short-term matching memory are held in the running process. You can forget a result's ranking from its action panel or clear learned ranking in command bar settings. These ranking records are not sent to a server.

When a feature needs a macOS permission such as Accessibility, Screen Recording or Microphone, that access is used only for the feature it belongs to. Temporary upload links are unavailable; this app does not upload captures to the former upstream sharing service. The [permissions section](#permissions) lists the feature mapping.

### Network connections

kururu opens only a few kinds of connection, and each one belongs to a visible feature.

1. **kururu self-updates are disabled in this build.** No release check, download or installation runs without this product's own update configuration.

2. **The internet speed test, only when you ask.** The optional speed test in the Network section reaches Cloudflare's public speed endpoints at `speed.cloudflare.com` to measure latency and your download and upload throughput. This happens only when you start a test yourself, and never on its own.

3. **Homebrew package management.** The installed package list and outdated checks run the local `brew` command. Explicit metadata updates, upgrades and uninstaller actions may contact Homebrew, GitHub and package vendor hosts. Upgrade actions are limited to packages marked as explicitly requested, leaving dependency upgrades to Homebrew. kururu does not run `brew` as root or collect its own package analytics.

4. **Temporary capture links are unavailable.** Old settings cannot enable uploads, remote refresh or deletion requests. kururu does not read or take ownership of the former application's stored link records.

5. **Feedback stays local until you submit it yourself.** The feedback window prepares text that you can copy. Optional technical details are shown before inclusion. Opening the project issue page sends no draft text or diagnostics in the URL and does not create an issue. If you paste and submit the draft on GitHub, that submission is governed by GitHub and the visibility of the issue you choose to create.

6. **Command bar destinations and scripts you configure.** Opening a saved website or web search hands its expanded URL to macOS. The destination can include the query, clipboard text or selected text when you put those placeholders in its configuration; the receiving website can receive those values. Saved scripts execute the chosen local file with the matched query argument and can make their own network requests. Scripts produce live results while you type a matching query after a brief pause, so execution does not always wait for Return. Local search and ranking do not make these external destinations private or prevent a configured script from communicating.

### Independent storage

Release and development builds use separate application identities. Existing upstream preferences, clipboard history, notes and shelf files are not read automatically. Explicit settings-file import accepts portable preferences and excludes machine restoration records and login registration. macOS permissions are granted separately to the new identity.

Shelf records are saved in `ShelfItems.json` inside the current identity's private Application Support directory. An older `shelfItems` preference in that same identity is retired only after the new index is successfully written. Pasted images remain in `ShelfFiles`; ordinary file entries retain references to their original locations. An unreadable or partially readable index is preserved, and its assets are not swept. This local storage upgrade does not automatically import another application's shelf. A separate explicit import reads the selected JSON or preferences plist and only the file entries the user selects. Each source directory requires a chosen location and reference/copy mode. Copied attachments receive independent destination files; external references stay at the selected locations. Old application directories are never added to kururu's cleanup roots.

## Permissions

kururu uses macOS permissions for the features that need them. Review grants in
**System Settings → Privacy & Security**. A denied permission can leave the
corresponding feature unavailable or limited; it does not grant access through
another application's identity.

| Permission | Used for |
|---|---|
| Accessibility | Keyboard and pointer actions, window switching, Dock interactions and Finder shortcuts |
| Screen Recording | Window previews, screenshots, screen text recognition and recording |
| System Audio Recording | Per-app volume and output routing |
| Microphone | Microphone audio in a recording, when selected |
| Notifications | Enabled monitor, battery and keep-awake alerts |
| Full Disk Access | Access to protected locations during an uninstaller scan |
| Automation | Finder file operations and Terminal handoff for Homebrew |
| App Management | Homebrew operations that replace or remove installed apps |

### Grant only what you use

Check which feature needs the permission before enabling it. For microphone
recording, screen recording can still work without microphone audio. Without
Full Disk Access, a scan may not find files in protected locations.

macOS may require quitting and reopening kururu after a grant changes. If a
permission appears enabled but a feature cannot use it, see
[troubleshooting](#resetting-permissions).

### Administrator access

Closed-lid keep-awake uses `pmset disablesleep`, which requires administrator
rights. The optional password-free setup installs a narrowly scoped `sudoers`
rule for that command. It is separate from macOS privacy permissions.
Privileged fan control is unavailable pending kururu's own release signing
configuration.

## Troubleshooting

A quick guide to the snags people hit most. If none of it helps, jump to [reporting a useful bug](#reporting-a-useful-bug) at the end.

The permission and uninstall commands below all point at kururu's bundle identifier, `com.pathgao.kururu`.

### The app will not open

The current kururu release is locally signed and has not been notarized by
Apple. macOS may block the first launch. If you trust the downloaded copy,
open **System Settings → Privacy & Security**, find the blocked-app notice
and choose **Open Anyway**, then confirm. See
[Apple's Gatekeeper guide](https://support.apple.com/en-us/102445).

kururu lives in the menu bar, so once it starts, look for its icon up there rather than in the Dock.

### A feature does nothing, or a permission will not stick

When debugging a feature, check its [required permissions](#permissions) first:

1. Open System Settings, Privacy and Security.
2. Find the permission the feature needs and make sure kururu is listed and switched on.
3. If it is listed and still quiet, toggle it off and back on.

kururu keeps an eye on Accessibility and Screen Recording, so features tend to wake up within a second or two of a grant, with no relaunch needed.

#### Accessibility

This one powers the scroll direction inverter, the switcher, Dock Preview, Finder cut and paste and quit on close. If they do nothing, open System Settings, Privacy and Security, Accessibility and confirm kururu is switched on. If you rebuilt the app yourself, its signature can shift and macOS may treat it as a different app, so remove the old kururu entry with the minus button and grant it again. For stable local signing, follow the [signing requirements](#build-identity-and-signing).

#### Screen Recording

This one feeds window titles and thumbnails in the switcher and Dock Preview. If previews fall back to app icons or Dock Preview stays unavailable, switch kururu on in System Settings, Privacy and Security, Screen Recording. macOS may ask you to quit and reopen the app after you grant it.

#### System Audio Recording

This one powers per app volume and output routing in the mixer. If the mixer says it needs permission, open System Settings, Privacy and Security, Screen and System Audio Recording, and switch kururu on. Audio is processed only for the local mixer.

#### Automation

Finder cut and paste, the uninstaller and Homebrew's Terminal handoff may ask for Automation. If a Finder move or Terminal handoff does nothing after a denial, open System Settings, Privacy and Security, Automation, and allow kururu for the app it needs to control.

### Resetting permissions

To wipe kururu's granted permissions and let macOS ask again from scratch, pick one of these.

- **From the app.** Settings under Advanced has a reset that clears every permission you granted, the login item and the closed lid rule, while leaving the app installed.
- **From Terminal.** Reset all of kururu's privacy permissions at once.

  ```sh
  tccutil reset All com.pathgao.kururu
  ```

  Or reset a single kind, for example.

  ```sh
  tccutil reset Accessibility com.pathgao.kururu
  tccutil reset ScreenCapture com.pathgao.kururu
  ```

  A self-built Developer variant has its own grants under
  `com.pathgao.kururu.dev`. Resetting is the way out when System Settings
  shows the permission as granted but the app disagrees — that happens when a
  grant was given to an earlier ad-hoc build whose signature no longer matches.

### Clean uninstall

The bundled script takes out everything kururu added, the app itself, its preferences and saved state, the login item, its privacy grants, and the optional closed lid `sudoers` rule.

```sh
./Tools/uninstall.sh
```

Run it from a clone of the repository. Add `--dry-run` to inspect the plan first, or `--dev` to select the development variant. Would you rather do it by hand? Quit kururu, drag it from Applications to the Trash, then clear its permissions.

```sh
tccutil reset All com.pathgao.kururu
```

### Reporting a useful bug

A clear report gets fixed faster. Try to include the following.

- **What you did**, what you expected, and what actually happened.
- **Your versions**, both the kururu version from Settings under About and your macOS version.
- **Steps to reproduce**, as specific as you can make them.
- **A screenshot or short screen recording**, when the issue is something you can see.

If you have a build from source, the self test prints a quick health summary that is handy to paste in.

```sh
"./build/stage/kururu (Developer).app/Contents/MacOS/kururuDeveloper" --selftest
```

Open a report from the [new issue](https://github.com/PathGao/kururu/issues/new/choose) page, and see [the README](README.md#contributing-and-feedback) for every way to get help.
