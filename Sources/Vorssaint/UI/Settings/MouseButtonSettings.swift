// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import SwiftUI

/// Settings > Mouse > Mouse button shortcuts: the switch, one row per mapped
/// button with its recorded combination, and a capture flow that asks for a
/// real press instead of making the user guess button numbers. The Spaces and
/// Mission Control drag (issue #1012) lives at the bottom of the same section,
/// because it hands a button a job the same way and borrows the same capture.
struct MouseButtonShortcutsSection: View {
    @ObservedObject private var l10n = L10n.shared
    @ObservedObject private var permissions = Permissions.shared
    @ObservedObject private var service = MouseButtonShortcutService.shared
    @AppStorage(DefaultsKey.mouseButtonShortcutsEnabled) private var enabled = false
    @AppStorage(DefaultsKey.mouseSpacesGestureEnabled) private var spacesEnabled = false
    @AppStorage(DefaultsKey.mouseSpacesGestureButton) private var spacesButton = 0
    @AppStorage(DefaultsKey.mouseSpacesGestureFollowsDrag) private var spacesFollowsDrag = false

    @State private var mappings = MouseButtonShortcutSupport.decode(
        UserDefaults.standard.dictionary(forKey: DefaultsKey.mouseButtonShortcuts) as? [String: String])
    /// A button that was just captured and is waiting for its first key
    /// combination. Nothing persists until the combination lands, so backing
    /// out leaves no half-made row behind.
    @State private var pendingButton: Int64?
    @State private var capturing = false
    @State private var captureFeedback: String?
    @State private var recordingButton: Int64?
    /// The recorder's complaint and the row it belongs to; it stays visible
    /// until that row records again, the same way the shortcut rows behave.
    @State private var recordError: String?
    @State private var recordErrorButton: Int64?
    @State private var spacesCapturing = false
    @State private var spacesFeedback: String?

    private var text: MouseButtonFeatureStrings { FeatureStrings.mouseButtons(l10n.language) }

    private var spacesReservationMessage: String {
        l10n.language == .zhHans
            ? "此按键已分配给 Spaces 手势，暂停时也会保留。请先移除下方的 Spaces 按键，再重新分配。"
            : "This button is assigned to the Spaces gesture, even while paused. Remove the Spaces button below before reassigning it."
    }

    private var captureRequiresEnabled: String {
        l10n.language == .zhHans
            ? "请先启用对应功能，再按下要添加的鼠标按钮。已有配置可在关闭时编辑。"
            : "Enable this behavior before capturing a new mouse button. Existing bindings remain editable while it is off."
    }

    var body: some View {
        SettingsSection(AppFeature.mouseButtonShortcuts.name(l10n.s, language: l10n.language)) {
            SettingsToggleWithCaption(title: text.enableLabel,
                                      caption: text.enableCaption,
                                      isOn: $enabled)
                .onChange(of: enabled) { _, on in
                    if !on { stopCapture() }
                    MouseButtonShortcutService.shared.syncWithPreferences()
                    if on, !permissions.accessibility {
                        permissions.requestAccessibility()
                    }
                }
            Group {
                if mappings.isEmpty, pendingButton == nil {
                    Text(text.emptyCaption)
                        .font(SettingsTypography.caption)
                        .foregroundStyle(.secondary)
                }
                ForEach(MouseButtonShortcutSupport.sortedButtons(mappings), id: \.self) { button in
                    mappingRow(button, shortcut: mappings[button])
                }
                if let pendingButton {
                    mappingRow(pendingButton, shortcut: nil)
                }
                captureRow
                    .disabled(!enabled)
                    .help(enabled ? text.captureHint : captureRequiresEnabled)
            }
            Divider()
            SettingsToggleWithCaption(title: text.spacesEnableLabel,
                                      caption: text.spacesEnableCaption,
                                      isOn: $spacesEnabled)
                .onChange(of: spacesEnabled) { _, on in
                    if !on {
                        stopSpacesCapture()
                    }
                    spacesButton = MouseButtonConfigurationSupport.spacesButtonAfterToggle(
                        enabled: on, savedButton: spacesButton)
                    MouseButtonShortcutService.shared.syncWithPreferences()
                    if on, !permissions.accessibility {
                        permissions.requestAccessibility()
                    }
                }
            Group {
                spacesRow
                SettingsToggleWithCaption(title: text.spacesFollowsDragLabel,
                                          caption: text.spacesFollowsDragCaption,
                                          isOn: $spacesFollowsDrag)
                if spacesEnabled, let warning = spacesShortcutWarning {
                    Text(warning)
                        .font(SettingsTypography.caption)
                        .foregroundStyle(.orange)
                }
            }
            .disabled(!spacesEnabled)
            Divider()
            MouseExceptionsList(scope: .buttonShortcuts)
        }
        .settingsSectionAnchor(.mouseButtonShortcuts)
        .onDisappear {
            stopCapture()
            stopSpacesCapture()
        }
    }

    // MARK: - Rows

    private func mappingRow(_ button: Int64, shortcut: GlobalShortcut?) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 8) {
                Text(MouseButtonShortcutSupport.buttonName(for: button, strings: text))
                Spacer()
                ShortcutRecorderButton(shortcut: shortcut ?? GlobalShortcut.keepAwakeDefault,
                                       isEnabled: true,
                                       waitingTitle: l10n.s.shortcutPressKeys,
                                       emptyTitle: shortcut == nil ? text.setShortcutButton : nil,
                                       notCapturedAction: { setRecordError(l10n.s.shortcutNotCaptured, button) },
                                       recordingChanged: { recording in
                                           recordingButton = recording ? button : nil
                                           if recording { setRecordError(nil, button) }
                                       },
                                       invalidAction: { setRecordError(l10n.s.shortcutInvalid, button) },
                                       captureAction: { save(button: button, shortcut: $0) })
                    .frame(width: 108)
                Button {
                    remove(button)
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                        .frame(width: 22, height: 22)
                }
                .buttonStyle(.plain)
                .help(text.removeButton)
                .accessibilityLabel(text.removeButton)
            }
            if let recordError, recordErrorButton == button {
                Text(recordError)
                    .font(SettingsTypography.caption)
                    .foregroundStyle(.orange)
            } else if recordingButton == button {
                Text(ShortcutRecordingCaption.text(l10n.s, canClear: false))
                    .font(SettingsTypography.caption)
                    .foregroundStyle(.secondary)
            }
            if shortcut != nil, RadialMenuSupport.claimsMouseButton(button) {
                Text(text.rowWheelNote)
                    .font(SettingsTypography.caption)
                    .foregroundStyle(.orange)
            }
        }
    }

    @ViewBuilder
    private var captureRow: some View {
        if capturing {
            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 8) {
                    if service.isRunning {
                        Image(systemName: "circle.dashed")
                            .foregroundStyle(.secondary)
                        Text(text.captureWaiting)
                    } else {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundStyle(.orange)
                        Text(text.captureBlind)
                    }
                    Spacer()
                    Button(text.captureCancel) { stopCapture() }
                }
                if let captureFeedback {
                    Text(captureFeedback)
                        .font(SettingsTypography.caption)
                        .foregroundStyle(.orange)
                }
                Text(text.captureHint)
                    .font(SettingsTypography.caption)
                    .foregroundStyle(.secondary)
            }
            .onReceive(service.$lastInputSeen) { seen in
                handleCapture(seen)
            }
        } else {
            Button {
                startCapture()
            } label: {
                Label(text.addButton, systemImage: "plus")
            }
        }
    }

    /// The bound button, the capture in progress, or the invitation to pick
    /// one. The same capture the shortcut rows use, so the button is named by
    /// pressing it rather than by counting.
    @ViewBuilder
    private var spacesRow: some View {
        if spacesCapturing {
            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 8) {
                    if service.isRunning {
                        Image(systemName: "circle.dashed")
                            .foregroundStyle(.secondary)
                        Text(text.spacesCaptureWaiting)
                    } else {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundStyle(.orange)
                        Text(text.captureBlind)
                    }
                    Spacer()
                    Button(text.captureCancel) { stopSpacesCapture() }
                }
                if let spacesFeedback {
                    Text(spacesFeedback)
                        .font(SettingsTypography.caption)
                        .foregroundStyle(.orange)
                }
            }
            .onReceive(service.$lastInputSeen) { seen in
                handleSpacesCapture(seen)
            }
        } else if spacesButton != 0 {
            HStack(spacing: 8) {
                Text(MouseButtonShortcutSupport.buttonName(for: Int64(spacesButton), strings: text))
                Spacer()
                Button {
                    spacesButton = 0
                    MouseButtonShortcutService.shared.syncWithPreferences()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                        .frame(width: 22, height: 22)
                }
                .buttonStyle(.plain)
                .help(text.removeButton)
                .accessibilityLabel(text.removeButton)
            }
        } else {
            Button {
                startSpacesCapture()
            } label: {
                Label(text.spacesPickButton, systemImage: "plus")
            }
            .disabled(!spacesEnabled)
            .help(spacesEnabled ? text.captureHint : captureRequiresEnabled)
        }
    }

    /// Report the directions whose actual system command has no shortcut.
    /// The horizontal arrows follow the same preference as the drag resolver.
    private var spacesShortcutWarning: String? {
        var missing: [String] = []
        if SpaceWindowBridge.spaceShortcut(.left) == nil {
            missing.append("\(spacesFollowsDrag ? "→" : "←") \(text.spacesMoveLeft)")
        }
        if SpaceWindowBridge.spaceShortcut(.right) == nil {
            missing.append("\(spacesFollowsDrag ? "←" : "→") \(text.spacesMoveRight)")
        }
        if SpaceWindowBridge.overviewShortcut(.missionControl) == nil {
            missing.append("↑ \(text.spacesMissionControl)")
        }
        if SpaceWindowBridge.overviewShortcut(.appExpose) == nil {
            missing.append("↓ \(text.spacesAppExpose)")
        }
        guard !missing.isEmpty else { return nil }
        let actions = missing.joined(separator: "; ")
        if missing.count == 4 { return text.spacesShortcutsOffNote + "\n" + actions }
        return String(format: text.spacesShortcutsPartialFormat, actions)
    }

    // MARK: - Capture

    private func startCapture() {
        guard enabled, AppFeature.mouseButtonShortcuts.isAvailable else { return }
        stopSpacesCapture()
        captureFeedback = nil
        capturing = true
        MouseButtonShortcutService.shared.setCapturing(true)
        if !permissions.accessibility {
            permissions.requestAccessibility()
        }
    }

    private func stopCapture() {
        guard capturing else { return }
        capturing = false
        captureFeedback = nil
        MouseButtonShortcutService.shared.setCapturing(false)
    }

    private func handleCapture(_ seen: Int64?) {
        guard capturing, let seen else { return }
        if !MouseButtonShortcutSupport.canMap(seen) {
            captureFeedback = text.captureUnsupported
        } else if RadialMenuSupport.claimsMouseButton(seen) {
            captureFeedback = text.captureWheel
        } else if MouseButtonConfigurationSupport.conflictsWithSpaces(seen, savedButton: spacesButton) {
            captureFeedback = spacesReservationMessage
        } else if mappings[seen] != nil || pendingButton == seen {
            captureFeedback = text.captureExists
        } else {
            pendingButton = seen
            recordError = nil
            stopCapture()
        }
    }

    private func startSpacesCapture() {
        guard spacesEnabled, AppFeature.mouseButtonShortcuts.isAvailable else { return }
        stopCapture()
        spacesFeedback = nil
        spacesCapturing = true
        MouseButtonShortcutService.shared.setCapturing(true)
        if !permissions.accessibility {
            permissions.requestAccessibility()
        }
    }

    private func stopSpacesCapture() {
        guard spacesCapturing else { return }
        spacesCapturing = false
        spacesFeedback = nil
        MouseButtonShortcutService.shared.setCapturing(false)
    }

    /// The drag needs a button that can be held and moved, and one no other
    /// mouse feature is already answering for. A refusal explains itself
    /// instead of leaving the press looking ignored.
    private func handleSpacesCapture(_ seen: Int64?) {
        guard spacesCapturing, let seen else { return }
        if !MouseSpacesGestureSupport.canBind(seen) {
            spacesFeedback = text.spacesCaptureUnsupported
        } else if RadialMenuSupport.claimsMouseButton(seen) {
            spacesFeedback = text.captureWheel
        } else if mappings[seen] != nil || pendingButton == seen {
            spacesFeedback = text.spacesCaptureExists
        } else {
            // Set before the capture ends, so the sync that ends it already
            // sees the new button.
            spacesButton = Int(seen)
            stopSpacesCapture()
        }
    }

    // MARK: - Persistence

    private func setRecordError(_ message: String?, _ button: Int64) {
        recordError = message
        recordErrorButton = message == nil ? nil : button
    }

    private func save(button: Int64, shortcut: GlobalShortcut) {
        guard !MouseButtonConfigurationSupport.conflictsWithSpaces(button, savedButton: spacesButton) else {
            setRecordError(spacesReservationMessage, button)
            return
        }
        mappings[button] = shortcut
        if pendingButton == button { pendingButton = nil }
        setRecordError(nil, button)
        persist()
    }

    private func remove(_ button: Int64) {
        if recordErrorButton == button { setRecordError(nil, button) }
        if pendingButton == button {
            pendingButton = nil
            return
        }
        mappings.removeValue(forKey: button)
        persist()
    }

    private func persist() {
        UserDefaults.standard.set(MouseButtonShortcutSupport.encode(mappings),
                                  forKey: DefaultsKey.mouseButtonShortcuts)
        MouseButtonShortcutService.shared.syncWithPreferences()
    }
}
