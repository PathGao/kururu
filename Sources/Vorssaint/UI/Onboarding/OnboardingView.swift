// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import SwiftUI

/// First-run experience, also reachable later through Settings › About.
/// The person chooses what they want first; only then does the app explain and
/// request the permissions that choice actually needs.
enum OnboardingMode {
    case full

    func title(_ strings: Strings) -> String {
        strings.obStepWelcomeTitle
    }
}

enum OnboardingStep {
    case welcome, purpose, permissions, done
}

struct OnboardingView: View {
    var mode: OnboardingMode = .full
    var onFinish: () -> Void

    @ObservedObject private var l10n = L10n.shared
    /// Persisted so the flow resumes where it stopped — macOS relaunches the
    /// app when Screen Recording is granted mid-onboarding.
    @AppStorage(DefaultsKey.onboardingStep) private var index = 0
    @State private var selectedFeatures: Set<AppFeature>

    init(mode: OnboardingMode = .full, onFinish: @escaping () -> Void) {
        self.mode = mode
        self.onFinish = onFinish
        let defaults = UserDefaults.standard
        _selectedFeatures = State(initialValue: OnboardingFeatureSelection.currentSelection(in: defaults))
    }

    private var setupPermissions: [AppPermission] {
        let permissions = Set(selectedFeatures.flatMap(\.onboardingPermissions))
        return [.accessibility, .screenRecording].filter { permissions.contains($0) }
    }
    private var steps: [OnboardingStep] {
        [.welcome, .purpose, .permissions, .done]
    }
    private var current: OnboardingStep { steps[min(max(0, index), steps.count - 1)] }

    var body: some View {
        VStack(spacing: 0) {
            // Scrollable so a step taller than the window (the menu bar
            // metrics list outgrew it, issue #176) can never push the
            // navigation bar out of the fixed frame — without a scroll, the
            // footer was clipped away and the flow looked stuck.
            ScrollView {
                content
                    .frame(maxWidth: .infinity, alignment: .top)
            }

            Divider()
            navigationBar
        }
        .frame(width: 540, height: 600)
        .onAppear {
            if !steps.indices.contains(index) { index = 0 }
            // Onboarding narrates the permission trip itself; the floating
            // guide card would just double the voice.
            PermissionGuideOverlay.suppressed = true
        }
        .onDisappear {
            PermissionGuideOverlay.suppressed = false
        }
    }

    @ViewBuilder
    private var content: some View {
        switch current {
        case .welcome: WelcomeStep()
        case .purpose: PurposeStep(selectedFeatures: $selectedFeatures)
        case .permissions: SelectedPermissionsStep(features: selectedFeatures,
                                                   permissions: setupPermissions)
        case .done: DoneStep()
        }
    }

    private var navigationBar: some View {
        HStack {
            Button(l10n.s.obBack) {
                withAnimation(.easeInOut(duration: 0.2)) { index = max(0, index - 1) }
            }
            .disabled(index == 0)

            Spacer()

            HStack(spacing: 6) {
                ForEach(steps.indices, id: \.self) { i in
                    Capsule()
                        .fill(i == index ? Color.accentColor : Color.primary.opacity(0.15))
                        .frame(width: i == index ? 18 : 7, height: 7)
                        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: index)
                }
            }

            Spacer()

            Button(primaryButtonTitle) {
                if index >= steps.count - 1 {
                    index = 0
                    onFinish()
                } else {
                    if current == .purpose {
                        FeatureRuntime.shared.applyOnboardingSelection(selectedFeatures)
                    }
                    withAnimation(.easeInOut(duration: 0.2)) { index += 1 }
                }
            }
            .keyboardShortcut(.defaultAction)
            .controlSize(.large)
            .buttonStyle(.borderedProminent)
        }
        .padding(16)
    }

    private var primaryButtonTitle: String {
        if index >= steps.count - 1 { return l10n.s.obStart }
        return l10n.s.obContinue
    }
}

// MARK: - Step 1: welcome & language

private struct WelcomeStep: View {
    @ObservedObject private var l10n = L10n.shared

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Theme.spaceGradient
                VStack(spacing: 10) {
                    BrandMark(width: 130)
                    Text(AppInfo.name)
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(.white)
                    Text(l10n.s.obStepWelcomeBody)
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.85))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .padding(.top, 12)
            }
            .frame(height: 220)

            VStack(alignment: .leading, spacing: 16) {
                Picker(l10n.s.obLanguageLabel, selection: $l10n.language) {
                    ForEach(AppLanguage.allCases) { language in
                        Text(language.displayName).tag(language)
                    }
                }
                // A menu (not segmented): with nine languages a segmented control
                // would overflow, and several names are in their own script.
                .pickerStyle(.menu)

                featureRow(icon: "bolt.fill",
                           title: l10n.s.obWelcomeBullet1Title,
                           text: l10n.s.obWelcomeBullet1Body)
                featureRow(icon: "gauge.with.dots.needle.50percent",
                           title: l10n.s.obWelcomeBullet2Title,
                           text: l10n.s.obWelcomeBullet2Body)
                featureRow(icon: "rectangle.on.rectangle",
                           title: l10n.s.obWelcomeBullet3Title,
                           text: l10n.s.obWelcomeBullet3Body)
            }
            .padding(24)
        }
    }

    private func featureRow(icon: String, title: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Theme.spaceGradient)
                    .frame(width: 30, height: 30)
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                Text(text)
                    .font(.system(size: 11.5))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

// MARK: - Purpose step

private struct PurposeStep: View {
    @ObservedObject private var l10n = L10n.shared
    @Binding var selectedFeatures: Set<AppFeature>

    private var hub: FeatureHubStrings { FeatureStrings.hub(l10n.language) }
    private var text: OnboardingFeatureStrings { OnboardingFeatureStrings.text(l10n.language) }

    var body: some View {
        VStack(spacing: 16) {
            StepHeader(icon: "sparkles.rectangle.stack",
                       title: l10n.s.obPurposeTitle,
                       subtitle: l10n.s.obPurposeBody)

            HStack {
                Text(hub.tabFeatures.uppercased())
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.secondary)
                    .tracking(1)
                Spacer()
                Text(String(format: hub.activeCountFormat, selectedFeatures.count,
                            OnboardingFeatureSelection.options.filter {
                                $0.isHardwareSupported || selectedFeatures.contains($0)
                            }.count))
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 28)

            LazyVStack(spacing: 14) {
                ForEach(FeatureGroup.allCases, id: \.self) { group in
                    VStack(alignment: .leading, spacing: 7) {
                        Text(group.title(hub))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        ForEach(OnboardingFeatureSelection.options.filter { $0.group == group }, id: \.self) { feature in
                            featureCard(feature)
                        }
                    }
                }
            }
            .padding(.horizontal, 28)

            Text(text.onDemand)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 36)
            Text(l10n.s.obPurposeSkip)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 36)
                .padding(.bottom, 12)
        }
    }

    private func featureCard(_ feature: AppFeature) -> some View {
        let selected = selectedFeatures.contains(feature)
        let title = feature == .monitorCPU
            ? FeatureUnit.monitor.title(l10n.s, language: l10n.language)
            : feature == .screenshot
                ? FeatureStrings.screenshot(l10n.language).screenCaptureTitle
                : feature.name(l10n.s, language: l10n.language)
        let description = feature == .monitorCPU ? text.monitor
            : feature == .screenshot ? text.capture : feature.hubDescription(hub)
        let blocked = feature.installBlockedReason
        let card = Button {
            selectedFeatures = OnboardingFeatureSelection.toggling(feature, in: selectedFeatures)
        } label: {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: feature.symbolName)
                    .font(.system(size: 14))
                    .foregroundStyle(selected ? Color.accentColor : .secondary)
                    .frame(width: 28, height: 28)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 12.5, weight: .semibold))
                        .foregroundStyle(.primary)
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    if let note = note(for: feature) {
                        Text(note)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                Spacer(minLength: 8)
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(selected ? Color.accentColor : Color.secondary.opacity(0.45))
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, 11)
            .padding(.vertical, 8)
            .background(RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(selected ? Color.accentColor.opacity(0.09) : Color.primary.opacity(0.035)))
            .contentShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(!selected && blocked != nil)
        .opacity(blocked == nil ? 1 : 0.4)
        .accessibilityLabel("\(title). \(description)" + (note(for: feature).map { ". \($0)" } ?? "")
                            + (blocked.map { ". \($0)" } ?? ""))
        .accessibilityAddTraits(selected ? .isSelected : [])
        return HStack(spacing: 0) { card }.help(blocked ?? "")
    }

    private func note(for feature: AppFeature) -> String? {
        switch feature {
        case .scrollInverter: return text.vertical
        case .mouseButtonShortcuts: return text.mouseButtons
        case .finderCutPaste: return text.finder
        case .quitWindowProtection: return text.quit
        case .textSnippets: return text.snippets
        case .dockClick: return text.dock
        case .fanControl: return text.fan
        case .musicBlock:
            return MusicLaunchBlocker.blockedBundleIDs.isEmpty ? text.appList : nil
        default: return nil
        }
    }
}


private struct SelectedPermissionsStep: View {
    @ObservedObject private var l10n = L10n.shared
    @State private var showingOtherPermissions = false
    let features: Set<AppFeature>
    let permissions: [AppPermission]

    private var hub: FeatureHubStrings { FeatureStrings.hub(l10n.language) }
    private var otherPermissions: [AppPermission] {
        AppPermission.allCases.filter { !permissions.contains($0) }
    }

    var body: some View {
        VStack(spacing: 18) {
            StepHeader(icon: "key.horizontal.fill",
                       title: hub.tabPermissions,
                       subtitle: hub.permissionsIntro)

            VStack(alignment: .leading, spacing: 12) {
                Text(hub.onboardingSelectedPermissionsTitle)
                    .font(.headline)

                if permissions.isEmpty {
                    Label(hub.onboardingNoSelectedPermissions,
                          systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.secondary)
                } else {
                    VStack(spacing: 0) {
                        ForEach(Array(permissions.enumerated()), id: \.offset) { index, permission in
                            if index > 0 { Divider().padding(.vertical, 12) }
                            VStack(alignment: .leading, spacing: 8) {
                                PermissionRow(kind: permission == .accessibility
                                              ? .accessibility : .screenRecording)
                                Text(permission.explainer(hub))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(String(format: hub.usedByFormat,
                                            featureNames(for: permission)))
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.primary.opacity(0.05))
            )
            .padding(.horizontal, 28)

            DisclosureGroup(isExpanded: $showingOtherPermissions) {
                VStack(alignment: .leading, spacing: 14) {
                    PermissionsPortalSections(hub: hub,
                                              visiblePermissions: otherPermissions)
                }
                .padding(.top, 12)
            } label: {
                VStack(alignment: .leading, spacing: 3) {
                    Text(hub.onboardingOtherPermissionsTitle)
                        .font(.headline)
                    Text(hub.onboardingOtherPermissionsCaption)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.primary.opacity(0.05))
            )
            .padding(.horizontal, 28)

            Text(l10n.s.permissionRestartNote)
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 36)

            Spacer()
        }
    }

    private func featureNames(for permission: AppPermission) -> String {
        features
            .filter { $0.onboardingPermissions.contains(permission) }
            .map { $0.name(l10n.s, language: l10n.language) }
            // Localized: a plain sort orders by Unicode scalar, which throws
            // every accented name past Z. On the first screen someone sees,
            // in a language with accents, that reads as a list in no order.
            .sorted { $0.localizedStandardCompare($1) == .orderedAscending }
            .joined(separator: ", ")
    }
}

// MARK: - Done

private struct DoneStep: View {
    @ObservedObject private var l10n = L10n.shared

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Theme.spaceGradient
                VStack(spacing: 14) {
                    BrandMark(width: 150)
                    Text(l10n.s.obStepDoneTitle)
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(.white)
                    Text(l10n.s.obStepDoneBody)
                        .font(.system(size: 12.5))
                        .foregroundStyle(.white.opacity(0.85))
                }
            }
            .frame(height: 300)

            VStack(spacing: 10) {
                Image(systemName: "menubar.arrow.up.rectangle")
                    .font(.system(size: 26))
                    .foregroundStyle(.secondary)
                Text(l10n.s.obDoneHint)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 60)
            }
            .padding(.top, 36)

            Spacer()
        }
    }
}

// MARK: - Shared header

private struct StepHeader: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Theme.spaceGradient)
                    .frame(width: 56, height: 56)
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(.white)
            }
            Text(title)
                .font(.system(size: 19, weight: .bold))
            Text(subtitle)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 48)
        }
        .padding(.top, 30)
    }
}
