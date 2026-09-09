# Monitor history implementation plan

Goal: Open enabled metrics with current readings and five minutes of history, retaining the existing visual design.
Architecture: One serial monitor sampler, timestamped in-memory history, reusable Swift Charts surface. Display toggles do not control collection.
Tech stack: Swift, AppKit, SwiftUI Charts, existing standalone test harness.
Spec: User-approved conversation on 2026-09-09: selectable 1–5 second sampling; selectable 1–5 minute viewport; collect enabled monitor families in the background; preserve missing intervals.

- [x] Test and implement timestamped history: retain 300 seconds, reject nonfinite values, bound sample count, split gaps, preserve timestamps when cadence changes.
- [x] Test and implement uniform 1–5 second cadence. Enable background plans through existing feature gates. Keep per-core deltas warm; reset across long gaps.
- [x] Integrate real samples for CPU/GPU/memory/network/disk/power/battery/temperatures/fans. Publish histories only to visible surfaces. Do not record cached sensor fallbacks as fresh history.
- [x] Add shared compact trend UI with axes to monitor sections and metric details. Keep graph visibility and the 1–5 minute selection in Monitor settings. Preserve core diagram and capacity bars.
- [x] Run focused tests, full build.sh --test, dev build, native light/dark rendering and actual app checks. Deliver separate desktop app and acceptance document. Do not commit or replace installed app.

Expected tests: old policy fails foreground/background cadence equality; timestamp windows remain correct after 1→5 second changes; missing reads and sleep produce separate segments; toggling charts retains history. Verify all enabled families populate while panels stay closed, and disabled features do not acquire new samples.

Visual refinement: separate CPU/GPU/memory histories within their own blocks, adaptive percentage ceilings, no panel picker or folding control. Network histories sit under their respective rates; power histories follow their readings. Existing per-metric graph preferences govern overview and details together.
