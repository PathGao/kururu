// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import Foundation

/// Onboarding writes the catalog's existing gates; action settings are preserved
/// unless a newly engaged feature needs its first action to do anything.
enum OnboardingFeatureSelection {
    static var options: [AppFeature] {
        AppFeature.allCases.filter {
            (!$0.isSwitchedByPlacement || $0 == .monitorCPU)
                && ($0.unit != .screenshot || $0 == .screenshot)
        }
    }

    static func normalized(_ selected: Set<AppFeature>) -> Set<AppFeature> {
        var selected = selected
        if selected.contains(where: { $0.unit == .screenshot }) {
            selected = selected.filter { $0.unit != .screenshot }
            selected.insert(.screenshot)
        }
        if selected.contains(.fanControl) { selected.insert(.monitorCPU) }
        return selected
    }

    static func toggling(_ feature: AppFeature, in selected: Set<AppFeature>) -> Set<AppFeature> {
        var next = normalized(selected)
        let feature: AppFeature = feature.unit == .screenshot ? .screenshot : feature
        if next.contains(feature) {
            next.remove(feature)
            if feature == .monitorCPU { next.remove(.fanControl) }
        } else {
            next.insert(feature)
        }
        return normalized(next)
    }

    static func currentSelection(in defaults: UserDefaults) -> Set<AppFeature> {
        Set(options.filter { $0.isAvailable(in: defaults) && $0.isEngaged(in: defaults) })
    }

    static func preferenceChanges(for selected: Set<AppFeature>,
                                  isEnabled: (String) -> Bool) -> [String: Bool] {
        let selected = normalized(selected)
        let units = Set(selected.map(\.unit))
        var changes = Dictionary(uniqueKeysWithValues: FeatureUnit.allCases.map {
            ($0.availabilityKey, units.contains($0))
        })
        for feature in AppFeature.allCases where units.contains(feature.unit) {
            if let gate = feature.pageSwitchKey {
                changes[gate] = selected.contains(feature)
            } else if !selected.contains(feature) {
                for key in feature.enabledKeys { changes[key] = false }
            }
            guard selected.contains(feature), !feature.enabledKeys.contains(where: isEnabled),
                  let primary = primaryAction(for: feature) else { continue }
            changes[primary] = true
        }
        return changes
    }

    /// A one-member unit does nothing until its first action is on, so installing
    /// it from the hub turns that action on, as selecting it during onboarding does.
    static func actionOnInstall(_ unit: FeatureUnit, isEnabled: (String) -> Bool) -> String? {
        guard unit.features.count == 1, let feature = unit.features.first,
              !feature.enabledKeys.contains(where: isEnabled) else { return nil }
        return primaryAction(for: feature)
    }

    private static func primaryAction(for feature: AppFeature) -> String? {
        switch feature {
        case .scrollInverter: return DefaultsKey.scrollInverterEnabled
        case .mouseButtonShortcuts: return DefaultsKey.mouseButtonShortcutsEnabled
        case .finderCutPaste: return DefaultsKey.finderCutPasteEnabled
        case .quitWindowProtection: return DefaultsKey.quitProtectionQuitEnabled
        case .textSnippets: return DefaultsKey.snippetLibraryEnabled
        case .dockClick: return DefaultsKey.dockClickMinimize
        case .windowLayout: return DefaultsKey.windowLayoutShortcutsEnabled
        default: return feature.enabledKeys.count == 1 ? feature.enabledKeys[0] : nil
        }
    }
}
