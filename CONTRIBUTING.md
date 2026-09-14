# Contributing to kururu

Thanks for the interest. This project aims to stay small, native and readable.

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
[troubleshooting guide](docs/TROUBLESHOOTING.md).

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
- Working with an agent? [Contributing with an
  agent](AI-CONTRIBUTIONS.md) is the process that gets that work merged
  here, and it is written to be read by the agent as much as by you.

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
  [troubleshooting guide](docs/TROUBLESHOOTING.md) explains what makes a report
  useful.
- **Feature request.** Describe the problem you are trying to solve rather than
  only a specific solution.

For general help and every support channel, see [support](SUPPORT.md).

## Pull requests

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

## Releases (maintainers)

Release readiness is tracked in the [roadmap](ROADMAP.md). Confirm
kururu's own signing, notarization, updater and publishing configuration
before enabling a release workflow. A local build does not authorize tagging,
pushing, publishing or changing repository secrets.

When preparing a release, fill in the template in [CHANGELOG.md](CHANGELOG.md)
with the version, date and user-facing changes. The build bundles this file,
and the release workflow uses the matching section for GitHub release notes.
