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
