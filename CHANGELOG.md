# Changelog

Release notes for kururu. Update this file when preparing a release; there is
no need to record each development commit. Copy the template below, replace
the version and date, and remove empty categories before publishing. Keep the
newest release first. The app and release workflow read these version headings.

<!-- Release template — copy outside this comment and fill in before tagging.
    ## [X.Y.Z] - YYYY-MM-DD

    ### Added
    - New user-facing capabilities.

    ### Changed
    - Changes to existing behavior.

    ### Fixed
    - Corrected problems.

    ### Removed
    - Removed capabilities or compatibility.
-->

## [0.1.5] - 2026-09-23

This is the final kururu release. The project has ended and will not receive further updates. Please use [Vorssaint](https://github.com/vorssaintapp/vorssaint-utils) instead.

### Added
- Window Layout, Kill Process, Port Manager and camera preview pages.
- Sideways scrolling while holding a modifier key.
- Offer to take over a macOS shortcut while its feature runs.
- The window switcher can show only windows on the current display.
- Dock Preview keeps the Dock visible while a preview is open.
- Screenshot watermarks, arrow styles and faster export.
- Local IP address, Keep Awake end time and mixer ordering in the menu bar panel.
- Remove apps from the command bar.

### Changed
- Kill Process is uninstalled by default.
- Several defaults now match Vorssaint, including the sideways scrolling key and brightness keys.

### Fixed
- Upstream fixes for the window switcher, Dock Preview, menu bar icon, display restoration, clipboard, capture and Keep Awake.
- The camera permission prompt is localized.

## [0.1.4] - 2026-09-19

### Changed
- Menu Bar Icon settings group metrics into one row per source. Monitor metrics are ordered in a draggable strip above a checkbox grid, and Mic mute has its own row.
- Collapsed Menu Bar Panel rows show how many of their options are on. The trend chart toggle has its border back and the chart range section has a title.

### Fixed
- The menu bar preview in settings hides the app icon when "Hide the app icon while metrics are shown" is on.

## [0.1.3] - 2026-09-17

### Changed
- A new app, menu bar and installer icon: the gray Dianlian horn spirit.
- Settings pages use native grouped forms with switches, regular-size switches for section toggles, and system text styles. The menu bar panel shows the system material behind its cards.
- The settings sidebar starts with search and the page list. The version stays on the About page.
- Menu bar metrics appear as tokens in menu bar order. Drag to reorder, click for options, and add hidden metrics from a menu.
- Menu Bar Panel settings list each section once, with its visibility, order and per-item options together. The Monitor page links to these settings instead of repeating them.
- Dock click settings are one choice (default, minimize or hide) plus a switch to cycle windows first.
- The three-finger spread trigger moved from the Trackpad page to each Radial Menu profile.
- Enabling a feature with a single behavior, such as Bluetooth Sleep, also turns that behavior on.
- The Sound Mixer no longer has its own switch. A saved off state becomes an uninstalled mixer.
- Peripheral batteries are read, and Bluetooth access requested, only while a peripheral battery is shown.
- Keyboard backlight shortcuts have a section on the Keyboard page.

### Fixed
- PDF image compression now shrinks existing images and keeps the original when the result is not smaller.
- Settings that depend on a switch are disabled while it is off, including Dock Preview options, ⌘Q / ⌘W protection options and display brightness shortcut recorders.
- Window maximizing shows the Accessibility permission row when access is missing.
- Removed blank rows, duplicate permission rows and a search result pointing to a page without the setting.
- The Environment page is translated into all six languages.

## [0.1.2] - 2026-09-16

### Changed
- Sign releases with kururu's Apple Developer ID and notarize them through GitHub Actions.
- Enable in-app updates from PathGao/kururu with Apple team and application identity verification.

### Fixed
- Place the disk trend toggle beside live activity and hide the trend when live activity is hidden.
- Keep display and keyboard backlight shortcut groups independently expandable.

## [0.1.1] - 2026-09-15

### Added
- Custom linear tracking speed for supported mice, with restoration of the previous device settings when disabled.
- Precise, Balanced, and Long Glide scrolling presets, finer adjustments, a response curve preview, and a scrolling test area.
- An optional three-finger spread gesture to open a selected radial menu. The gesture pauses while macOS three-finger dragging is enabled.
- Native file-promise delivery to the Shelf, with cancellation, independent stored filenames, and preserved order for mixed drops.

### Changed
- Moved graph visibility and history duration controls to Menu Bar Panel settings. Graph buttons sit beside the display switches and show a persistent selected state.
- Graph controls become unavailable when their item or section is hidden, while preserving the saved graph preference.
- Refreshed the project documentation and added a Simplified Chinese README.

### Fixed
- Improved menu bar icon recovery while macOS is still placing a recreated status item.
- Aligned recording video and audio timelines, preserved per-sample timing, and finalized recording duration when capture stops.
- Kept the app switcher icon row stable and brought selected previews into view after resizing, searching, or closing windows.
- Made screenshot content windows follow visibility preferences and prevented tool changes from accepting stale frames or selections.
- Distinguished confirmed app removal from inaccessible paths and dangling links when reporting uninstall results.
- Protected localized folders throughout cleaner scanning and removal.
- Preserved mouse recovery records across disconnections and custom-speed changes.
- Reclaimed orphaned Shelf attachments without removing active deliveries or files referenced by the saved index.

## [0.1.0] - 2026-09-11

### kururu
- First kururu release, with grouped settings, consistent controls and revised action descriptions.
- One large-headed octopus across the menu bar, settings, app icon and installer; the sidebar displays the product name and version.
- Selected fixes from upstream after 3.3.5 protect Spotify customizations and Phone calls, improve window focus and cycling, and handle the macOS Accessibility Keyboard.
- Independent release and development identities, an octopus icon shared with the interface, and project links to PathGao/kururu.
- Workspace membership is separate from runtime controls. Removed tools retain a reachable read-only summary of saved runtime settings and key combinations; adding a tool restores full settings access.
- Clipboard selection previews content without copying it. Explicit original-text and OCR copy actions report failures, and clearing recent history requires confirmation.
- URL rule groups can be paused without deleting definitions; manual cleaning shares enabled rules, with confirmation before rule deletion.
- Local theme import, port inspection, radial trackpad gestures, PDF merging and image optimization, and more accurate microphone restoration ownership.
- Explicit portable-settings import without transferring machine restoration records or login registration. Existing application data is not moved automatically.
- Temporary uploads, upstream feedback delivery, the Beta update channel, and the separate Support page removed. About retains project links and local feedback drafts. Updates accept stable releases only and remain unavailable, along with privileged fan control, until kururu release signing is configured.
