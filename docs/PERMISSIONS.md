# Permissions

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

## Grant only what you use

Check which feature needs the permission before enabling it. For microphone
recording, screen recording can still work without microphone audio. Without
Full Disk Access, a scan may not find files in protected locations.

macOS may require quitting and reopening kururu after a grant changes. If a
permission appears enabled but a feature cannot use it, see
[troubleshooting](TROUBLESHOOTING.md#resetting-permissions).

## Administrator access

Closed-lid keep-awake uses `pmset disablesleep`, which requires administrator
rights. The optional password-free setup installs a narrowly scoped `sudoers`
rule for that command. It is separate from macOS privacy permissions.
Privileged fan control is unavailable pending kururu's own release signing
configuration.

## Storage and network access

Screen text recognition runs on-device through Apple's Vision framework.
Captures and recordings are stored locally. Temporary upload links are
unavailable, and self-updates are disabled in the current build.
See [Privacy](PRIVACY.md) for feature-specific network access and data storage.

## Separate application identities

The release uses `com.pathgao.kururu`; the development variant uses
`com.pathgao.kururu.dev`. Grant permissions to the variant you actually run.
Importing settings does not transfer permission grants or login registration.
