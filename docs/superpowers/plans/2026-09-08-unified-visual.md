# Unified visual implementation plan

Goal: Deliver a native candidate matching the approved desktop visual standard.
Architecture: Extend the existing Theme with a small shared typography and metric icon vocabulary. Reuse current monitoring, preferences, navigation and controls.
Tech stack: SwiftUI and AppKit, no new dependencies.
Spec: /Users/gaoyanbo/Desktop/Cairn-统一视觉标准-20260908.md

## Constraints
- Work only in visual-compact; no commits, installation over the release, or preference resets.
- CPU/GPU have no utilization bars. Real CPU dots use fixed spacing and neutral shades.
- Common values 16 pt, content cards 12 pt inset / 16 pt radius, capacity bars 4 pt, eye buttons 28 pt.
- Retain localized formatting and accessibility. No new sampling or animation timers.

## Execution
- [x] Theme.swift: shared fonts, metric symbols, neutral data color and card styling.
- [x] SystemSection/CPUCoreMatrix/PowerSection/DiskSection/NetworkSection/MetricDetailView: adopt shared styles, one capacity component, preserve independent visibility and process expansion.
- [x] MenuPanelView/PanelLayout/SettingsView/FeatureHubSettings/MenuBarMetricsPreview: align navigation, headings, action sizes and neutral surfaces.
- [x] Audit clipboard, mixer and shared floating surfaces. Adjust visual properties only, preserving text editing and control behavior.
- [x] Build unit tests (expect existing 10594 checks), then debug app. Inspect native monitor pages, settings, CPU/GPU hide/restore, theme and matrix accessibility.
- [x] Read-only review of this round's diff; resolve verified regressions.
- [x] Desktop signed app and matching test guide with first section 先测没被弄坏. Verify signature and selftest; mark scope honestly.

Runtime scope: Monitoring and settings verified on this Mac. Clipboard and mixer remain uninstalled, with style/source review only. No full regression of uninstalled features is claimed.
