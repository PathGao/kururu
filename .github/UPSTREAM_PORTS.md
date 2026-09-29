# Upstream ports — 2026-09-15

Reviewed Vorssaint changes from September 12 through September 15 (Asia/Shanghai),
ending at `e462b6c25aa75ccb4c52dde3124e1f3e4f36054e`. These are adapted source
changes, not a merge of the upstream product. No version, updater, signing or
application identity changes were imported.

| Source commit | Adopted behavior | Fork adaptation |
|---|---|---|
| [31864e7](https://github.com/vorssaint/vorssaint-utils/commit/31864e730f1ea17b852fcc5abcd01d94e70af8da) | Menu bar recovery waits for a newly created item to settle and bounds retries. | Preserves kururu's application and metric identities. |
| [39f0e50](https://github.com/vorssaint/vorssaint-utils/commit/39f0e50c4e9586dc675164598d4bbbaefe1b4ec6) | Video, system audio and microphone keep their shared recording timeline and per-sample timing. | Omits upstream product metadata changes. |
| [280fe16](https://github.com/vorssaint/vorssaint-utils/commit/280fe16e7af322ce38c2a6b7d1333dbae0d0f775) | Switching apps keeps the icon row steady and reveals the selected preview after resizing, searching or closing. | Preserves existing focus and window-exclusion behavior. |
| [2c09155](https://github.com/vorssaint/vorssaint-utils/commit/2c09155f95ea124ac584d24ca548acc957e6de68) | Uninstall reports confirmed absence separately from inaccessible paths or dangling links and counts the app once. | Retains the fork's Homebrew confirmation snapshot checks. |
| [e757fe5](https://github.com/vorssaint/vorssaint-utils/commit/e757fe514e27ec1aa49d39ddea9bdfae984f1723) | Screenshot content windows follow visibility preferences; tool switches reject stale pixels, selections and delayed replies. | Uses kururu's capture surfaces without the upstream Notch subsystem. Recording exclusions remain separate. |
| [e38688e](https://github.com/vorssaint/vorssaint-utils/commit/e38688eea08fee0679fdd890f9779fad446c76e1) | Localized folders stay protected across leftover, cache, log and stale-selection removal paths. | Retains own-app protection, cancellation and development-tool cache scanning. |
| [b473ebf](https://github.com/vorssaint/vorssaint-utils/commit/b473ebf64dd5ea21ee810af6be908edcd089d149) | File promises are retained only after the native coordinated delivery callback, with cancellation, independent filenames and mixed-drop companions. | Uses the atomic shelf index, guarded payload cleanup and badge-only top entrance. Preserves mixed item order. Promise folders are rejected; ordinary Finder folder references still work. |

## Deliberately excluded

- The full Dynamic Island and its follow-up layouts introduce a separate subsystem;
  kururu already owns a different top entrance and scope.
- App update catalog fallback concerns the updater that kururu deliberately removed.
- The compact power sparkline patch targets an inline graph absent from kururu's
  current PowerSection. Importing it would replace the fork's monitor design.
- The large upstream test-runner rewrite was not imported wholesale. Selected
  native contracts and the source-generation helper were adapted to the existing
  test source list.

## Verification

`./build.sh --test` runs the existing unit/editor checks followed by the isolated
upstream integration binary. The latter tests actual scan and chooser methods,
native SwiftUI scrolling, decoded MOV tracks, native-delivery callback boundaries,
file integrity, cancellation, permissions and startup cleanup. Fixture clocks,
images, windows and home directories prevent real capture or cleaning.

The shelf cleanup regression was observed failing before its fix. The cleaner
policy regression likewise rejected the old implementation. Native source
contracts compile selected current production bodies rather than maintained copies.

Latest local validation: 12,510 existing checks and 393 integration checks passed;
the editor baseline passed 14 checks. Reverting the cleaner protections failed
12 of its 26 checks, and the shelf cleanup baseline failed two checks.

Live checks remain necessary for Mail/browser drag transport, screenshots across
real displays, menu bar placement and recording device behavior. Automated MOV
checks do not establish microphone hardware synchronization on every device.
