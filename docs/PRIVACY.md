# Privacy

kururu stores preferences and feature data locally in its own application domain. It has no account or hosted feedback service. This page describes the current fork, including the disabled release capabilities.

## The short version

- **No account.** There is nothing to sign up for and nobody to log in as.
- **No subscription.** The app is free and stays free, with nothing held back behind a paid tier.
- **No automatic telemetry.** kururu sends no usage stats, crash reports or device identifiers to an analytics service. The command bar keeps local ranking data as described below. Feedback includes technical details in a local draft only when you select them after seeing the complete list.
- **No kururu analytics or tracking.** There are no analytics kits, no ad networks and no third party tracking anywhere in the app.
- **No data selling.** kururu never sells personal information or shared screenshots and recordings.
- **Your settings stay put.** Preferences and saved state live in the app's own local storage on your Mac and are never uploaded.

## What it reads, and where that stays

Everything kururu shows you, from the CPU and memory load to the temperatures, the battery details, the network rates, the window list, per app volume and the files on the Shelf, is read locally through native macOS APIs and shown to you right there. None of it is sent anywhere, logged remotely or shared.

Clipboard history, including the images and files you copy, lives in the app's local storage on your Mac and never leaves it. Copy text from screen recognizes the text entirely on device with Apple's Vision framework, and the temporary capture is deleted as soon as the text is read. Automatic clearing, when you switch it on, only empties the system clipboard on this Mac: nothing is sent anywhere, and items already saved to your history are left as they are.

Recent Captures keeps up to 12 screenshots, within a 256 MB limit, in the app's private local cache so you can reopen them. Recordings are not duplicated: only their existing path and a small thumbnail are kept. Clear removes that history and its cached images. When a screenshot is copied as a file, its private local PNG is kept temporarily so other apps can finish reading it, then cleaned on later copies once it is older than 24 hours or earlier when the bounded cache fills. None of these local caches is uploaded automatically.

The command bar learns which durable results you choose to improve local ranking. Preferences retain result identifiers, use counts, last-use times and keyed digests of query prefixes. The installation key is stored separately in Keychain; the ranking store does not save the original query text. Query text and short-term matching memory are held in the running process. You can forget a result's ranking from its action panel or clear learned ranking in command bar settings. These ranking records are not sent to a server.

When a feature needs a macOS permission such as Accessibility, Screen Recording or Microphone, that access is used only for the feature it belongs to. Temporary upload links are unavailable; this app does not upload captures to the former upstream sharing service. The [permissions guide](PERMISSIONS.md) breaks down each permission.

## Network connections

kururu opens only a few kinds of connection, and each one belongs to a visible feature.

1. **kururu self-updates are disabled in this build.** No release check, download or installation runs without this product's own update configuration.

2. **The internet speed test, only when you ask.** The optional speed test in the Network section reaches Cloudflare's public speed endpoints at `speed.cloudflare.com` to measure latency and your download and upload throughput. This happens only when you start a test yourself, and never on its own.

3. **Homebrew package management.** The installed package list and outdated checks run the local `brew` command. Explicit metadata updates, upgrades and uninstaller actions may contact Homebrew, GitHub and package vendor hosts. Upgrade actions are limited to packages marked as explicitly requested, leaving dependency upgrades to Homebrew. kururu does not run `brew` as root or collect its own package analytics.

4. **Temporary capture links are unavailable.** Old settings cannot enable uploads, remote refresh or deletion requests. kururu does not read or take ownership of the former application's stored link records.

5. **Feedback stays local until you submit it yourself.** The feedback window prepares text that you can copy. Optional technical details are shown before inclusion. Opening the project issue page sends no draft text or diagnostics in the URL and does not create an issue. If you paste and submit the draft on GitHub, that submission is governed by GitHub and the visibility of the issue you choose to create.

6. **Command bar destinations and scripts you configure.** Opening a saved website or web search hands its expanded URL to macOS. The destination can include the query, clipboard text or selected text when you put those placeholders in its configuration; the receiving website can receive those values. Saved scripts execute the chosen local file with the matched query argument and can make their own network requests. Scripts produce live results while you type a matching query after a brief pause, so execution does not always wait for Return. Local search and ranking do not make these external destinations private or prevent a configured script from communicating.

## Independent storage

Release and development builds use separate application identities. Existing upstream preferences, clipboard history, notes and shelf files are not read automatically. Explicit settings-file import accepts portable preferences and excludes machine restoration records and login registration. macOS permissions are granted separately to the new identity.

Shelf records are saved in `ShelfItems.json` inside the current identity's private Application Support directory. An older `shelfItems` preference in that same identity is retired only after the new index is successfully written. Pasted images remain in `ShelfFiles`; ordinary file entries retain references to their original locations. An unreadable or partially readable index is preserved, and its assets are not swept. This local storage upgrade does not automatically import another application's shelf. A separate explicit import reads the selected JSON or preferences plist and only the file entries the user selects. Each source directory requires a chosen location and reference/copy mode. Copied attachments receive independent destination files; external references stay at the selected locations. Old application directories are never added to kururu's cleanup roots.

## Changes to this document

This page describes how the current version of kururu behaves. If the app's behavior around privacy ever changes, this page changes with it.

## Questions

If anything here is unclear, open a question in [GitHub issues](https://github.com/PathGao/kururu/issues).
