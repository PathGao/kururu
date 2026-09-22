#!/bin/zsh
# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Vorssaint

# Builds the product, assembles the .app bundle, signs it and (with --install)
# installs it into /Applications.
#
# The bundle is staged in a temporary directory outside ~/Documents: folders synced
# by File Provider gain xattrs (com.apple.provenance etc.) that invalidate codesign.
set -euo pipefail
cd "$(dirname "$0")"

# The icon catalog and the bundle are staged in temp dirs; sweep both however
# the script ends.
ICON_TMP=""
STAGE_TMP=""
IDENTITY_TMP=""

cleanup() {
    [[ -n "$ICON_TMP" ]] && rm -rf "$ICON_TMP"
    [[ -n "$STAGE_TMP" ]] && rm -rf "$STAGE_TMP"
    [[ -n "$IDENTITY_TMP" ]] && rm -rf "$IDENTITY_TMP"
    return 0
}
trap cleanup EXIT
# zsh runs the EXIT trap when the script is hung up, but not when it is
# interrupted or terminated; route those through exit so a Ctrl-C partway
# into the build sweeps like any other ending.
trap 'exit 1' INT TERM HUP

# Flags: --dev builds the local-only Developer variant (its own
# bundle id, so it coexists with the official app); --install puts it in /Applications.
DEV=0
INSTALL=0
TEST=0
TEST_ARGS=()
for arg in "$@"; do
    case "$arg" in
        --dev)     DEV=1 ;;
        --install) INSTALL=1 ;;
        --test)    TEST=1 ;;
        --test-suite=*) TEST=1; TEST_ARGS+=("--suite=${arg#*=}") ;;
        --list-tests) TEST=1; TEST_ARGS+=(--list) ;;
    esac
done

if (( DEV )); then
    BUILD_VARIANT_FLAGS=(-D VORSSAINT_DEVELOPMENT)
    APP_OPTIMIZATION_FLAGS=(-Onone)
    BUILD_CONFIGURATION="debug"
else
    BUILD_VARIANT_FLAGS=()
    APP_OPTIMIZATION_FLAGS=(-O)
    BUILD_CONFIGURATION="release"
fi
# Compile the same identity source used by the app and helper. Read a plist,
# never shell-evaluate generated configuration.
IDENTITY_TMP="$(mktemp -d)"
swiftc Sources/Vorssaint/Core/ProductIdentity.swift Tools/PrintProductIdentity.swift -o "$IDENTITY_TMP/identity"
"$IDENTITY_TMP/identity" "$DEV" > "$IDENTITY_TMP/config.plist"
APP_NAME="$(/usr/libexec/PlistBuddy -c 'Print :APP_NAME' "$IDENTITY_TMP/config.plist")"
EXECUTABLE="$(/usr/libexec/PlistBuddy -c 'Print :EXECUTABLE' "$IDENTITY_TMP/config.plist")"
APP_BUNDLE_ID="$(/usr/libexec/PlistBuddy -c 'Print :APP_BUNDLE_ID' "$IDENTITY_TMP/config.plist")"
FAN_HELPER_ID="$APP_BUNDLE_ID.fan-control"
# Now Playing is read through /usr/bin/perl loading this library; see
# Sources/NowPlayingAdapter. Staged under Contents/Frameworks, signed on its own.
NOW_PLAYING_ADAPTER_ID="$APP_BUNDLE_ID.now-playing"
NOW_PLAYING_ADAPTER="libVorssaintNowPlaying.dylib"
TARGET="arm64-apple-macosx14.0"
ENTITLEMENTS="Resources/Vorssaint.entitlements"
LEGACY_IDENTITY="Vorssaint Utils Signing"

# Select by fingerprint: the three project certificates share the same Apple name.
PROJECT_SIGNING_IDENTITY="${APPLE_SIGNING_IDENTITY:-E045AE3830A8EF200546AB97B6E020C1B40384CA}"
developer_id_identity() {
    security find-identity -v -p codesigning 2>/dev/null \
        | awk -v identity="$PROJECT_SIGNING_IDENTITY" '$2 == identity && /Developer ID Application/ { print $2; exit }'
}
if [[ "${REQUIRE_SIGNING:-0}" == "1" && -z "$(developer_id_identity)" ]]; then
    echo "The configured kururu Developer ID certificate is unavailable." >&2
    exit 1
fi

# A find-identity listing also names certificates codesign then rejects (an
# expired one fails the build with errSecInternalComponent), and -v excludes
# every self-signed one; ask codesign itself with a throwaway copy of /bin/echo.
legacy_identity_installed() {
    local probe signed=1
    probe="$(mktemp)"
    cp /bin/echo "$probe"
    /usr/bin/codesign --force --strip-disallowed-xattrs --sign "$LEGACY_IDENTITY" "$probe" \
        >/dev/null 2>&1 && signed=0
    rm -f "$probe"
    return $signed
}

# Developer and installed builds need an existing stable signing identity.
# Building must never create certificates or modify the user's keychains.
if (( DEV || INSTALL )) && [[ -z "$(developer_id_identity)" ]] \
    && ! legacy_identity_installed; then
    echo "No usable signing identity is available for this build." >&2
    echo "Reuse an existing signing certificate, or configure and unlock one yourself before rebuilding." >&2
    echo "No signing setup or keychain changes were performed." >&2
    exit 1
fi

codesign_with_timestamp_retry() {
    local attempt
    for attempt in 1 2 3; do
        if /usr/bin/codesign "$@"; then
            return 0
        fi
        if (( attempt < 3 )); then
            echo "  Developer ID signing failed; retrying ($((attempt + 1))/3)"
            sleep "$attempt"
        fi
    done
    return 1
}

write_swift_output_file_map() {
    local output_file="$1"
    local object_dir="$2"
    shift 2
    local source artifact

    {
        print -r -- "{"
        print -r -- "  \"\": {"
        print -r -- "    \"swift-dependencies\": \"$object_dir/master.swiftdeps\""
        print -r -- "  }"
        for source in "$@"; do
            artifact="${source//\//__}"
            artifact="${artifact%.swift}"
            print -r -- ","
            print -r -- "  \"$source\": {"
            print -r -- "    \"object\": \"$object_dir/$artifact.o\","
            print -r -- "    \"swift-dependencies\": \"$object_dir/$artifact.swiftdeps\""
            print -r -- "  }"
        done
        print -r -- "}"
    } > "$output_file"
}

finalize_installed_bundle_after_child() {
    local bundle="$1"
    local helper="$bundle/Contents/Library/LaunchServices/$FAN_HELPER_ID"
    local adapter="$bundle/Contents/Frameworks/$NOW_PLAYING_ADAPTER"
    local devid
    devid="$(developer_id_identity)"

    echo "▸ Finalizing installed signature…"
    sleep 3
    if [[ -n "$devid" ]]; then
        [[ -f "$helper" ]] && codesign_with_timestamp_retry --force --strip-disallowed-xattrs \
            --options runtime --timestamp --identifier "$FAN_HELPER_ID" --sign "$devid" "$helper"
        [[ -f "$adapter" ]] && codesign_with_timestamp_retry --force --strip-disallowed-xattrs \
            --options runtime --timestamp --identifier "$NOW_PLAYING_ADAPTER_ID" --sign "$devid" "$adapter"
        codesign_with_timestamp_retry --force --strip-disallowed-xattrs --options runtime --timestamp \
            --entitlements "$ENTITLEMENTS" --sign "$devid" "$bundle"
    elif legacy_identity_installed; then
        [[ -f "$helper" ]] && /usr/bin/codesign --force --strip-disallowed-xattrs \
            --identifier "$FAN_HELPER_ID" --sign "$LEGACY_IDENTITY" "$helper"
        [[ -f "$adapter" ]] && /usr/bin/codesign --force --strip-disallowed-xattrs \
            --identifier "$NOW_PLAYING_ADAPTER_ID" --sign "$LEGACY_IDENTITY" "$adapter"
        /usr/bin/codesign --force --strip-disallowed-xattrs --sign "$LEGACY_IDENTITY" "$bundle"
    else
        [[ -f "$helper" ]] && /usr/bin/codesign --force --strip-disallowed-xattrs \
            --identifier "$FAN_HELPER_ID" --sign - "$helper"
        [[ -f "$adapter" ]] && /usr/bin/codesign --force --strip-disallowed-xattrs \
            --identifier "$NOW_PLAYING_ADAPTER_ID" --sign - "$adapter"
        /usr/bin/codesign --force --strip-disallowed-xattrs --sign - "$bundle"
    fi
    [[ -f "$helper" ]] && /usr/bin/codesign --verify --strict "$helper"
    [[ -f "$adapter" ]] && /usr/bin/codesign --verify --strict "$adapter"
    /usr/bin/codesign --verify --deep --strict "$bundle"
    echo "✓ Signature ready: $bundle"
}

if (( INSTALL && ! TEST )) && [[ "${VORSSAINT_INSTALL_CHILD:-0}" != "1" ]]; then
    VORSSAINT_INSTALL_CHILD=1 "$0" "$@"
    child_status=$?
    if (( child_status != 0 )); then
        exit "$child_status"
    fi
    finalize_installed_bundle_after_child "/Applications/$APP_NAME.app"
    exit 0
fi

# Prefer the macOS 26 SDK when present: the 27 SDK turns SwiftUI property wrappers
# into macros (SwiftUIMacros plugin) that the Command Line Tools cannot load yet.
PINNED_SDK="/Library/Developer/CommandLineTools/SDKs/MacOSX26.sdk"
if [[ -n "${DEVELOPER_DIR:-}" ]]; then
    SDK="$(xcrun --show-sdk-path)"
elif [[ -d "$PINNED_SDK" ]]; then
    SDK="$PINNED_SDK"
else
    SDK="$(xcrun --show-sdk-path)"
fi
SDK_COMPAT_FLAGS=()
VM_STATISTICS_COMPAT_FLAGS=(-I Sources/VMStatisticsCompat)
HID_EVENT_SYSTEM_FLAGS=(-I Sources/HIDEventSystem)
if [[ "$SDK" == "$PINNED_SDK" ]]; then
    # Swift 6.4 can read the SDK 26 interfaces when given their compiler version.
    SDK_COMPAT_FLAGS=(-Xfrontend -interface-compiler-version -Xfrontend 6.3.2)
fi

# The defaults migrations under test need a real UserDefaults suite, and every
# suite leaves an empty plist in ~/Library/Preferences. The tests already clear
# the domains, but cfprefsd writes the emptied file back out around the time the
# process that owned it exits, so only a caller that outlives the run can remove
# them. `MetricsTests` keeps every suite name inside these two namespaces (a
# check in the test file holds it to that), which is what makes this sweep
# complete rather than a list to keep in step by hand.
discard_test_preferences() {
    local preferences="${1:-$HOME/Library/Preferences}" name attempt
    local survivors=0 quiet_passes=0
    # cfprefsd can recreate an emptied domain after the first removal. Require
    # two quiet checks, but keep a hard limit so persistent failures still fail CI.
    for attempt in {1..10}; do
        for name in "vorss.tests." "com.vorssaint.tests."; do
            rm -f "$preferences"/$name*.plist(N)
        done
        rm -f "$preferences/metrics-tests.plist"
        sleep 0.2
        survivors=$(find "$preferences" -maxdepth 1 \
            \( -name "vorss.tests.*.plist" -o -name "com.vorssaint.tests.*.plist" \
               -o -name "metrics-tests.plist" \) 2>/dev/null | wc -l | tr -d ' ')
        if [[ "$survivors" == "0" ]]; then
            quiet_passes=$((quiet_passes + 1))
            if (( quiet_passes == 2 )); then return 0; fi
        else
            quiet_passes=0
        fi
    done
    echo "✗ test preferences did not settle in $preferences ($survivors remaining)" >&2
    return 1
}

# --test: compile and run the standalone unit tests (pure helpers only: metrics,
# Homebrew parsing, defaults, localization contracts; no app, no UI, no IOKit),
# then exit. Fast and deterministic; no XCTest needed.
if (( TEST )); then
    echo "▸ Building & running unit tests against $(basename "$SDK")…"
    python3 Tests/generate_upstream_sources.py
    TEST_OBJECT_DIR="build/objects/tests"
    mkdir -p "$TEST_OBJECT_DIR"
    # The full app build below remains optimized and is the optimizer gate.
    # Unit assertions do not need optimization; avoiding it cuts most of the
    # test harness compile time without reducing the code the tests exercise.
    test_sources=(
        Sources/Vorssaint/Services/Media/MediaSupport.swift \
        Sources/Vorssaint/Services/Media/MediaPDFSupport.swift \
        Sources/Vorssaint/Services/Media/MediaInputSelectionSupport.swift \
        Sources/Vorssaint/Services/Media/MediaCancellationToken.swift \
        Sources/Vorssaint/Core/MediaPDFStrings.swift \
        Tests/MediaPDFTests.swift \
        Tests/MediaPDFCompressionTests.swift \
        Tests/MediaPDFCompressionSelectionTests.swift \
        Tests/MediaPDFSelectionTests.swift \
        Tests/MediaCancellationTests.swift \
        Tests/MicMuteBatchTests.swift \
        Tests/BuildCapabilityPolicyTests.swift \
        Tests/ScreenshotSharingBoundaryTests.swift \
        Tests/SettingsBackupIdentityTests.swift \
        Sources/Vorssaint/Services/QuickTools/ScreenshotShareService.swift \
        Tests/ProductIdentityBoundaryTests.swift \
        Sources/Vorssaint/Services/FanControl/FanControlXPC.swift \
        Tests/TrackpadGestureTests.swift \
        Tests/RadialTrackpadBindingTests.swift \
        Tests/RadialTrackpadIntegrationTests.swift \
        Sources/Vorssaint/Core/TrackpadGestureStrings.swift \
        Sources/Vorssaint/Services/MiddleClick/TrackpadGestureSupport.swift \
        Sources/Vorssaint/Core/QuitProtectionSupport.swift \
        Sources/Vorssaint/Core/QuitProtectionStrings.swift \
        Sources/Vorssaint/Core/Defaults.swift \
        Sources/Vorssaint/Core/FeatureCatalog.swift \
        Sources/Vorssaint/Core/FeaturePresets.swift \
        Sources/Vorssaint/Core/FeatureHubStrings.swift \
        Sources/Vorssaint/Core/ShortcutSettingsStrings.swift \
        Sources/Vorssaint/Core/SettingsBackupSupport.swift \
        Sources/Vorssaint/Services/SettingsBackupExport.swift \
        Sources/Vorssaint/Services/PermissionResetSupport.swift \
        Sources/Vorssaint/Services/RadialMenu/RadialMenuProfileDeletion.swift \
        Tests/SettingsActionTests.swift \
        Sources/Vorssaint/Core/JSONPreviewFormatter.swift \
        Sources/Vorssaint/Core/URLAutomaticCleaning.swift \
        Sources/Vorssaint/Core/URLRuleImportSupport.swift \
        Tests/ShelfDockPlacementTests.swift \
        Tests/ShelfDockVisibilityTests.swift \
        Tests/ShelfIndexStoreTests.swift \
        Tests/ShelfImportTests.swift \
        Tests/ShelfImportAssetsTests.swift \
        Tests/ShelfImportTransactionTests.swift \
        Tests/ShelfPayloadCleanupTests.swift \
        Tests/ScratchpadPresentationTests.swift \
        Tests/ScratchpadImportTests.swift \
        Tests/ClipboardImportTests.swift \
        Tests/ClipboardEncodingTests.swift \
        Tests/ClipboardImportTransactionTests.swift \
        Tests/ScratchpadImportStoreTests.swift \
        Tests/ShelfDockBackupTests.swift \
        Tests/ClipboardJSONPreviewTests.swift \
        Tests/URLAutomaticCleaningTests.swift \
        Tests/URLRuleImportTests.swift \
        Tests/URLRuleEditingTests.swift \
        Tests/SettingsNavigationTests.swift \
        Tests/CleanerRunResultTests.swift \
        Tests/WhatsAppOrganizerPolicyTests.swift \
        Tests/SpotifyPhoneProtectionTests.swift \
        Tests/SwitcherRegressionTests.swift \
        Tests/AssistiveKeyboardTests.swift \
        Sources/Vorssaint/Core/SettingsHierarchyStrings.swift \
        Sources/Vorssaint/Core/BackupStrings.swift \
        Sources/Vorssaint/Core/SnippetStrings.swift \
        Sources/Vorssaint/Core/BrightnessStrings.swift \
        Sources/Vorssaint/Core/MediaImageStrings.swift \
        Sources/Vorssaint/Core/SystemActionStrings.swift \
        Sources/Vorssaint/Core/ScreenshotStrings.swift \
        Sources/Vorssaint/Core/RecentCaptureStrings.swift \
        Sources/Vorssaint/Core/RecorderStrings.swift \
            Sources/Vorssaint/Core/DockPreviewStrings.swift \
        Sources/Vorssaint/Core/DockClickStrings.swift \
        Sources/Vorssaint/Core/MicMuteStrings.swift \
        Sources/Vorssaint/Core/MixerStrings.swift \
        Sources/Vorssaint/Core/MusicBlockStrings.swift \
        Sources/Vorssaint/Core/SoundOutputSwitcherStrings.swift \
        Sources/Vorssaint/Core/ScratchpadStrings.swift \
        Sources/Vorssaint/Core/FinderRenameStrings.swift \
        Sources/Vorssaint/Core/FinderArrangementStrings.swift \
        Sources/Vorssaint/Services/Finder/FinderArrangementSupport.swift \
        Tests/FinderArrangementTests.swift \
        Tests/FinderTargetAcquisitionTests.swift \
        Tests/DisplayBrightnessShortcutTests.swift \
        Tests/BrightnessModuleMigrationTests.swift \
        Tests/MixerSwitchMigrationTests.swift \
        Tests/FeatureLifecycleTests.swift \
        Tests/ShelfImportStoreTests.swift \
        Tests/CommandBarExecutorTests.swift \
        Sources/Vorssaint/Services/Shelf/ShelfImportStore.swift \
        Sources/Vorssaint/Services/CommandBar/CommandBarExecutor.swift \
        Sources/Vorssaint/App/FeatureLifecycle.swift \
        Sources/Vorssaint/Core/CommandBarStrings.swift \
        Sources/Vorssaint/Core/FeedbackStrings.swift \
        Sources/Vorssaint/Core/FeedbackDraftSupport.swift \
        Tests/FeedbackDraftTests.swift \
        Tests/ProductSettingsTests.swift \
        Tests/StableUpdateTests.swift \
        Sources/Vorssaint/Core/RadialMenuStrings.swift \
        Sources/Vorssaint/Core/MenuBarAppearanceStrings.swift \
        Sources/Vorssaint/Core/AppAppearance.swift \
        Sources/Vorssaint/Core/AppearanceStrings.swift \
        Sources/Vorssaint/Core/BatteryTimeStrings.swift \
        Sources/Vorssaint/Core/KeepAwakeStrings.swift \
        Sources/Vorssaint/Core/BluetoothSleepStrings.swift \
        Sources/Vorssaint/Core/EnvironmentStrings.swift \
        Sources/Vorssaint/Core/EnvironmentCopyFeedback.swift \
        Tests/EnvironmentCopyTests.swift \
        Sources/Vorssaint/Services/Environment/EnvironmentUpdateSupport.swift \
        Sources/Vorssaint/Core/EnvironmentUpdateStrings.swift \
        Tests/EnvironmentUpdateTests.swift \
        Sources/Vorssaint/Services/Environment/EnvironmentConfiguration.swift \
        Tests/EnvironmentConfigurationTests.swift \
        Sources/Vorssaint/Services/CommandBar/CommandBarActionSupport.swift \
        Tests/CommandBarActionTests.swift \
        Sources/Vorssaint/Services/CommandBar/CommandBarDestinationSupport.swift \
        Tests/CommandBarDestinationTests.swift \
        Sources/Vorssaint/Core/PermissionGuideStrings.swift \
        Sources/Vorssaint/Core/FanControlStrings.swift \
        Sources/Vorssaint/Services/FanControl/FanControlSupport.swift \
        Sources/Vorssaint/Services/Snippets/TextSnippetSupport.swift \
        Sources/Vorssaint/Services/RadialMenu/RadialMenuSupport.swift \
        Sources/Vorssaint/Services/QuickTools/ScratchpadSupport.swift \
        Sources/Vorssaint/Services/QuickTools/ScratchpadStore.swift \
        Sources/Vorssaint/Services/QuickTools/ScratchpadImportSupport.swift \
        Sources/Vorssaint/Services/KillProcess/KillProcessSupport.swift \
        Sources/Vorssaint/Services/DirectorySize.swift \
        Sources/Vorssaint/Services/Environment/EnvironmentInspector.swift \
        Sources/Vorssaint/Services/Recorder/RecorderSupport.swift \
            Sources/Vorssaint/Services/PrivateFileStore.swift \
        Sources/Vorssaint/Services/Recorder/RecorderTakeStore.swift \
        Sources/Vorssaint/Services/Recorder/RecorderPresetImageStore.swift \
        Sources/Vorssaint/Services/Recorder/RecorderMotion.swift \
        Sources/Vorssaint/Services/Recorder/RecorderPointerTrack.swift \
        Sources/Vorssaint/Services/Recorder/RecorderTypingTrack.swift \
        Sources/Vorssaint/Services/Recorder/RecorderTimeline.swift \
        Sources/Vorssaint/Services/Recorder/RecorderTextOverlay.swift \
        Sources/Vorssaint/Services/Recorder/RecorderImageOverlay.swift \
        Sources/Vorssaint/Services/Recorder/RecorderBlurRegion.swift \
        Sources/Vorssaint/Services/Recorder/RecorderEditDocument.swift \
        Sources/Vorssaint/Core/ProductIdentity.swift \
        Sources/Vorssaint/Core/BuildCapabilityPolicy.swift \
        Sources/Vorssaint/Core/ProductIdentityBoundarySupport.swift \
        Sources/Vorssaint/Core/AppInfo.swift \
        Sources/Vorssaint/Core/GlobalShortcut.swift \
        Sources/Vorssaint/Core/BrightnessShortcutStrings.swift \
        Sources/Vorssaint/Core/HomebrewHierarchyStrings.swift \
        Sources/Vorssaint/Core/SymbolicHotKeys.swift \
        Sources/Vorssaint/Services/SystemShortcutTakeoverSupport.swift \
        Sources/Vorssaint/Core/Localization.swift \
        Sources/Vorssaint/Core/Localizations/Strings+*.swift \
        Sources/Vorssaint/Core/FeatureStrings.swift \
        Sources/Vorssaint/Core/KillProcessStrings.swift \
        Sources/Vorssaint/Core/WhatsAppDownloadStrings.swift \
        Sources/Vorssaint/Core/WhatsAppOrganizerStrings.swift \
        Sources/Vorssaint/Core/ReleaseNotes.swift \
        Sources/Vorssaint/Core/URLCleaning.swift \
        Sources/Vorssaint/Core/URLCleanerResultState.swift \
        Sources/Vorssaint/Core/UXTaskFlowStrings.swift \
        Sources/Vorssaint/Services/GeneralPasteboardAccess.swift \
        Sources/Vorssaint/Services/Audio/MixerRoutingSupport.swift \
        Sources/Vorssaint/Services/Audio/MusicLaunchSupport.swift \
        Sources/Vorssaint/Services/Bluetooth/BluetoothSleepSupport.swift \
        Sources/Vorssaint/UI/MenuPanel/MixerPercentNativeTextField.swift \
        Sources/Vorssaint/Services/Audio/BoostLimiter.swift \
        Sources/Vorssaint/Services/Audio/MixerRender.swift \
        Sources/Vorssaint/Services/Audio/PreciseVolumeRollerSupport.swift \
        Sources/Vorssaint/Services/DockPreview/DockPreviewSupport.swift \
        Sources/Vorssaint/Services/Homebrew/HomebrewSupport.swift \
        Sources/Vorssaint/Services/Clipboard/ClipboardHistorySupport.swift \
        Sources/Vorssaint/Services/Clipboard/ClipboardImportSupport.swift \
        Sources/Vorssaint/Services/Clipboard/ClipboardImportTransaction.swift \
        Sources/Vorssaint/Services/Clipboard/ClipboardAutoClearSupport.swift \
        Sources/Vorssaint/Services/AutoQuit/AutoQuitSupport.swift \
        Sources/Vorssaint/Services/Shelf/ShelfDockPlacementSupport.swift \
        Sources/Vorssaint/Services/Shelf/ShelfDockVisibilitySupport.swift \
        Sources/Vorssaint/Services/QuickTools/ScratchpadPresentationSupport.swift \
        Sources/Vorssaint/Services/Shelf/ShelfSupport.swift \
        Sources/Vorssaint/Services/Shelf/ShelfIndexStore.swift \
        Sources/Vorssaint/Services/Shelf/ShelfImportSupport.swift \
        Sources/Vorssaint/Services/Shelf/ShelfImportAssets.swift \
        Sources/Vorssaint/Services/Shelf/ShelfImportTransaction.swift \
        Sources/Vorssaint/Services/Shelf/ShelfPayloadCleanup.swift \
        Sources/Vorssaint/Services/Finder/FinderRenameSupport.swift \
        Sources/Vorssaint/Services/Update/UpdateInstallerSupport.swift \
        Sources/Vorssaint/Services/Update/UpdateServiceSupport.swift \
        Sources/Vorssaint/Services/InstalledApps.swift \
        Sources/Vorssaint/Services/LaunchAtLoginSupport.swift \
        Sources/Vorssaint/UI/Settings/SettingsSearchSupport.swift \
        Sources/Vorssaint/UI/Settings/FeatureVisibilitySupport.swift \
        Sources/Vorssaint/App/MenuBarSpacingSupport.swift \
        Sources/Vorssaint/App/StatusItemAnchorSupport.swift \
        Sources/Vorssaint/Services/DockClick/DockClickSupport.swift \
        Sources/Vorssaint/Services/Finder/CutPasteProgressSupport.swift \
        Sources/Vorssaint/Services/Finder/CutPastePrivilegeSupport.swift \
        Sources/Vorssaint/Services/Finder/FinderPasteImageSupport.swift \
        Sources/Vorssaint/Services/MiddleClick/MiddleClickSupport.swift \
        Sources/Vorssaint/Services/MouseNavigation/MouseNavigationSupport.swift \
        Sources/Vorssaint/Services/MouseButtons/MouseButtonShortcutSupport.swift \
        Sources/Vorssaint/Services/MouseButtons/MouseButtonConfigurationSupport.swift \
        Tests/MouseButtonConfigurationTests.swift \
        Sources/Vorssaint/Services/MouseButtons/MouseSpacesGestureSupport.swift \
        Sources/Vorssaint/Services/MouseClickDebounce/MouseClickDebounceSupport.swift \
        Sources/Vorssaint/Services/MouseExceptions/MouseAppExceptionSupport.swift \
        Sources/Vorssaint/Services/MouseExceptions/MouseAppExceptions.swift \
        Sources/Vorssaint/Services/WindowServerSupport.swift \
        Sources/Vorssaint/Core/MouseButtonStrings.swift \
        Sources/Vorssaint/Core/MouseClickDebounceStrings.swift \
        Sources/Vorssaint/Core/MouseExceptionStrings.swift \
        Sources/Vorssaint/Core/ClipboardIgnoredAppsStrings.swift \
        Sources/Vorssaint/Core/WindowPreviewExclusionStrings.swift \
        Sources/Vorssaint/Core/DiskExclusionStrings.swift \
        Sources/Vorssaint/Core/SwitcherAppRulesStrings.swift \
        Sources/Vorssaint/Services/QuickTools/QuickToolsSupport.swift \
        Sources/Vorssaint/Services/CommandBar/CommandBarSupport.swift \
        Sources/Vorssaint/Services/CommandBar/CommandBarPreferences.swift \
        Sources/Vorssaint/Services/CommandBar/CommandBarMath.swift \
        Sources/Vorssaint/Services/CommandBar/CommandBarUnits.swift \
        Sources/Vorssaint/Services/CommandBar/CommandBarEmoji.swift \
        Sources/Vorssaint/Services/CommandBar/CommandBarLinks.swift \
        Sources/Vorssaint/Services/CommandBar/CommandBarDates.swift \
        Sources/Vorssaint/Services/CommandBar/CommandBarRowShortcuts.swift \
        Sources/Vorssaint/Services/CommandBar/CommandBarSystemSettingsSupport.swift \
        Sources/Vorssaint/Services/CommandBar/CommandBarFileSearchSupport.swift \
        Sources/Vorssaint/Services/CommandBar/CommandBarQueryMemory.swift \
        Sources/Vorssaint/Services/SpotlightNamesSupport.swift \
        Sources/Vorssaint/Services/QuickTools/MicMuteSupport.swift \
        Sources/Vorssaint/Services/QuickTools/MicMuteBatchSupport.swift \
        Sources/Vorssaint/Services/QuickTools/QuickTogglesSupport.swift \
        Sources/Vorssaint/Services/QuickTools/ScreenshotCapturePolicy.swift \
        Sources/Vorssaint/Services/QuickTools/ScreenshotSupport.swift \
        Sources/Vorssaint/Services/QuickTools/RecentCaptureStore.swift \
        Sources/Vorssaint/Services/QuickTools/ScreenshotSharingSupport.swift \
        Sources/Vorssaint/Services/QuickTools/WindowActivationPolicy.swift \
        Sources/Vorssaint/Services/KeyboardDebounce/KeyboardDebounceSupport.swift \
        Sources/Vorssaint/Services/SuperKey/SuperKeySupport.swift \
        Sources/Vorssaint/Services/SuperKey/SuperKeyMappingGuard.swift \
        Sources/Vorssaint/Core/SuperKeyStrings.swift \
        Sources/Vorssaint/Services/SessionActivity.swift \
        Sources/Vorssaint/Services/SessionActivitySupport.swift \
        Sources/Vorssaint/Services/ScrollWheelSupport.swift \
        Sources/Vorssaint/Services/SmoothScrollSupport.swift \
        Sources/Vorssaint/Services/MouseAcceleration/MouseAccelerationSupport.swift \
        Sources/Vorssaint/Services/FocusFollowsMouse/FocusFollowsMouseSupport.swift \
        Sources/Vorssaint/Services/Switcher/SwitcherModels.swift \
        Sources/Vorssaint/Services/Switcher/SwitcherSupport.swift \
        Sources/Vorssaint/Services/Switcher/SpaceHopSupport.swift \
        Sources/Vorssaint/Services/Switcher/WindowUseOrder.swift \
        Sources/Vorssaint/Services/Metrics/MetricFormat.swift \
        Sources/Vorssaint/Services/Metrics/VMStatisticsDecoder.swift \
        Sources/Vorssaint/Services/KeepAwakeAutomationSupport.swift \
        Sources/Vorssaint/Services/SudoersSupport.swift \
        Sources/Vorssaint/Services/Metrics/BatteryTimeSupport.swift \
        Sources/Vorssaint/Services/BoundedProcessRunner.swift \
        Sources/Vorssaint/Services/DetachedProcess.swift \
        Sources/Vorssaint/Services/ShellSupport.swift \
        Sources/Vorssaint/Services/Metrics/NetworkProcessSupport.swift \
        Sources/Vorssaint/Services/Metrics/NetworkSampler.swift \
        Sources/Vorssaint/Services/Metrics/SpeedTest.swift \
        Sources/Vorssaint/Services/Metrics/PeripheralBatterySupport.swift \
        Sources/Vorssaint/Services/Metrics/DiskSupport.swift \
        Sources/Vorssaint/Services/Metrics/MonitorSamplingPolicy.swift \
        Sources/Vorssaint/Services/Metrics/MonitorHistory.swift \
        Tests/MonitorHistoryTests.swift \
        Tests/MusicLaunchBlockerTests.swift \
        Tests/MusicReplacementActionTests.swift \
        Sources/Vorssaint/Services/Ports/LocalPortSupport.swift \
        Sources/Vorssaint/Services/Ports/LocalPortScanner.swift \
        Tests/LocalPortTests.swift \
        Sources/Vorssaint/Services/Cleaner/CleanerPackageCaches.swift \
        Tests/CleanerPackageCacheTests.swift \
        Tests/BrightnessNativeBoundaryTests.swift \
        Tests/BrightnessPipelineTests.swift \
        Sources/Vorssaint/Core/OnboardingFeatureSelection.swift \
        Sources/Vorssaint/Core/OnboardingFeatureStrings.swift \
        Tests/OnboardingFeatureSelectionTests.swift \
        Tests/FeatureSwitchRetirementTests.swift \
        Sources/Vorssaint/Services/Metrics/MaxCapacityProbe.swift \
        Sources/Vorssaint/Services/Metrics/TemperatureSensorSelector.swift \
        Sources/Vorssaint/Services/Metrics/SustainedAlertGate.swift \
        Sources/Vorssaint/Services/CleaningMode/CleaningUnlockCounter.swift \
        Sources/Vorssaint/Services/Display/BrightnessSupport.swift \
        Sources/Vorssaint/Services/Cleaner/CleanerSupport.swift \
        Sources/Vorssaint/Services/Cleaner/CleanerPolicy.swift \
        Sources/Vorssaint/Services/Cleaner/CleanerSchedule.swift \
        Sources/Vorssaint/Core/CleanerRunResult.swift \
        Sources/Vorssaint/Core/CleanerRunStrings.swift \
        Sources/Vorssaint/Core/WhatsAppOrganizerPolicy.swift \
        Sources/Vorssaint/Services/AssistiveKeyboard.swift \
        Sources/Vorssaint/Services/Uninstall/UninstallerSupport.swift \
        Sources/Vorssaint/Core/UninstallerSelectionSupport.swift \
        Tests/UninstallerSelectionTests.swift \
        Sources/Vorssaint/Services/ManagedDownloads/WhatsAppDownloadSupport.swift \
        Sources/Vorssaint/Services/Metrics/CPUCoreUsageSupport.swift \
        Tests/CPUCoreUsageTests.swift \
        Sources/Vorssaint/Services/Metrics/CPUCoreTopologySupport.swift \
        Tests/CPUCoreTopologyTests.swift \
        Tests/MetricsTests.swift \
        Tests/RecentCaptureStoreTests.swift \
        Tests/RecorderPresetImageStoreTests.swift \
        Tests/SpeedTestTests.swift \
        Tests/TestSuite.swift \
        Tests/BoundedProcessCancellationTests.swift \
        Sources/Vorssaint/Services/Homebrew/HomebrewEnvironmentCheckSettlement.swift \
        Tests/HomebrewEnvironmentCheckSettlementTests.swift \
        Sources/Vorssaint/UI/PlainTextEditor.swift \
        Tests/PlainTextEditorLifecycleTests.swift \
        Sources/Vorssaint/Services/Recorder/RecorderComposition.swift \
        Sources/Vorssaint/Services/Recorder/RecorderCaptureEngine.swift \
        Sources/Vorssaint/Services/Recorder/RecorderWriter.swift \
        Sources/Vorssaint/Services/Recorder/RecorderSampleTiming.swift \
        Sources/Vorssaint/Core/ShelfPromiseDeliveryStrings.swift \
        Sources/Vorssaint/Services/Shelf/ShelfFilePromiseTransfer.swift \
        Tests/UpstreamPolicyTests.swift \
        Tests/ShelfPromiseCleanupTests.swift \
        Tests/CleanerEligibilityTests.swift \
        Tests/SwitcherScrollTests.swift \
        Tests/ScreenshotSelectionRefreshTests.swift \
        Tests/RecorderSampleTimingTests.swift \
        Tests/RecorderWriterTests.swift \
        Tests/ShelfFilePromiseTests.swift \
        Tests/ShelfDropRoutingTests.swift \
        build/generated-tests/*.swift \
    )
    TEST_OUTPUT_FILE_MAP="$TEST_OBJECT_DIR/output-file-map.json"
    write_swift_output_file_map "$TEST_OUTPUT_FILE_MAP" "$TEST_OBJECT_DIR" "${test_sources[@]}"
    swiftc -Onone -incremental -enable-batch-mode -j "$(sysctl -n hw.logicalcpu)" \
        -module-name VorssaintTests -output-file-map "$TEST_OUTPUT_FILE_MAP" \
        -target "$TARGET" -sdk "$SDK" "${SDK_COMPAT_FLAGS[@]}" \
        "${VM_STATISTICS_COMPAT_FLAGS[@]}" \
        "${test_sources[@]}" -o build/metrics-tests
    # `set -e` would end the script on a failing run before the sweep below.
    test_status=0
    ./build/metrics-tests "${TEST_ARGS[@]}" || test_status=$?
    # A selected suite or listing runs only the binary above.
    if (( ${#TEST_ARGS} )); then
        discard_test_preferences || test_status=1
        exit $test_status
    fi
    if python3 Tests/BrightnessServiceContract.py \
        Sources/Vorssaint/Services/Display/BrightnessService.swift \
        build/brightness-contract/main.swift && \
        swiftc -target "$TARGET" -sdk "$SDK" \
        Sources/Vorssaint/Services/Display/BrightnessSupport.swift \
        build/brightness-contract/main.swift -o build/brightness-contract-tests; then
        ./build/brightness-contract-tests || test_status=1
    else
        test_status=1
    fi
    ./Tests/PreferenceCleanupTests.sh || test_status=1
    discard_test_preferences || test_status=1
    exit $test_status
fi

echo "▸ Compiling ($BUILD_CONFIGURATION) against $(basename "$SDK")…"
APP_SOURCES=(Sources/Vorssaint/**/*.swift)
if (( DEV )); then
    APP_OBJECT_DIR="build/objects/$EXECUTABLE"
    mkdir -p build "$APP_OBJECT_DIR"
    APP_OUTPUT_FILE_MAP="$APP_OBJECT_DIR/output-file-map.json"
    write_swift_output_file_map "$APP_OUTPUT_FILE_MAP" "$APP_OBJECT_DIR" "${APP_SOURCES[@]}"
    swiftc "${APP_OPTIMIZATION_FLAGS[@]}" -incremental -j "$(sysctl -n hw.logicalcpu)" \
        -output-file-map "$APP_OUTPUT_FILE_MAP" \
        -target "$TARGET" -sdk "$SDK" "${SDK_COMPAT_FLAGS[@]}" "${VM_STATISTICS_COMPAT_FLAGS[@]}" "${HID_EVENT_SYSTEM_FLAGS[@]}" \
        "${BUILD_VARIANT_FLAGS[@]}" \
        "${APP_SOURCES[@]}" -o "build/$EXECUTABLE"
else
    rm -rf build
    mkdir -p build
    # Whole-module optimization is the SwiftPM/Xcode release default and halves this compile.
    swiftc "${APP_OPTIMIZATION_FLAGS[@]}" -wmo -num-threads "$(sysctl -n hw.logicalcpu)" -target "$TARGET" -sdk "$SDK" \
        "${SDK_COMPAT_FLAGS[@]}" "${VM_STATISTICS_COMPAT_FLAGS[@]}" "${HID_EVENT_SYSTEM_FLAGS[@]}" "${BUILD_VARIANT_FLAGS[@]}" \
        "${APP_SOURCES[@]}" -o "build/$EXECUTABLE"
fi

echo "▸ Compiling protected fan helper…"
swiftc -O -target "$TARGET" -sdk "$SDK" "${SDK_COMPAT_FLAGS[@]}" "${BUILD_VARIANT_FLAGS[@]}" \
    Sources/Vorssaint/Core/ProductIdentity.swift \
    Sources/Vorssaint/Core/BuildCapabilityPolicy.swift \
    Sources/Vorssaint/Services/FanControl/FanControlSupport.swift \
    Sources/Vorssaint/Services/FanControl/FanControlXPC.swift \
    Sources/Vorssaint/Services/SystemMonitor/SMCClient.swift \
    Sources/Vorssaint/Services/Metrics/TemperatureSensorSelector.swift \
    Sources/Vorssaint/Services/FanControl/FanControlHardware.swift \
    Sources/FanControlHelper/main.swift \
    -o "build/$FAN_HELPER_ID"
"build/$FAN_HELPER_ID" --selftest

echo "▸ Compiling Now Playing adapter…"
swiftc -O -target "$TARGET" -sdk "$SDK" "${SDK_COMPAT_FLAGS[@]}" -emit-library \
    -module-name VorssaintNowPlaying \
    Sources/NowPlayingAdapter/NowPlayingAdapter.swift \
    -o "build/$NOW_PLAYING_ADAPTER"

echo "▸ Generating app icon…"
swiftc Sources/Vorssaint/UI/HornSpiritMark.swift Tools/MakeIcon.swift -o build/MakeIcon
build/MakeIcon assets/brand/AppIcon-Default.png build/AppIcon.iconset
xattr -c -r build/AppIcon.iconset build/AppIcon.icns build/MenuBarIcon.png build/MenuBarIcon@2x.png build/BrandMark.png 2>/dev/null || true
ACTOOL_BIN="$(xcrun --find actool 2>/dev/null || true)"
ICON_TMP="$(mktemp -d)"
ADAPTIVE_SKIP=""
if [[ ! -d "assets/brand/kururu.icon" ]]; then
    ADAPTIVE_SKIP="kururu adaptive source is not provided"
elif [[ -z "$ACTOOL_BIN" ]]; then
    ADAPTIVE_SKIP="actool not found (adaptive icons need Xcode 26+)"
else
    echo "▸ Compiling adaptive icon catalog…"
    # actool crashes on File Provider-synced paths, so compile a local copy.
    ditto "assets/brand/kururu.icon" "$ICON_TMP/AppIcon.icon"
    # Xcode 27 beta actool requires the --compile target directory to already exist.
    mkdir -p "$ICON_TMP/catalog"
    if "$ACTOOL_BIN" "$ICON_TMP/AppIcon.icon" \
            --compile "$ICON_TMP/catalog" \
            --app-icon AppIcon \
            --platform macosx \
            --target-device mac \
            --minimum-deployment-target 14.0 \
            --enable-on-demand-resources NO \
            --output-partial-info-plist "$ICON_TMP/partial-info.plist" \
            >"$ICON_TMP/actool.log" 2>&1 && [[ -s "$ICON_TMP/catalog/Assets.car" ]]; then
        mv "$ICON_TMP/catalog/Assets.car" build/Assets.car
    else
        ADAPTIVE_SKIP="actool could not compile the catalog"
    fi
fi
if [[ -n "$ADAPTIVE_SKIP" ]]; then
    cp "$ICON_TMP/actool.log" build/actool-failure.log 2>/dev/null || true
    echo "  adaptive icon skipped: $ADAPTIVE_SKIP (Dock falls back to AppIcon.icns)"
fi
echo "▸ Assembling and signing bundle…"
STAGE_TMP="$(mktemp -d)"
STAGE="$STAGE_TMP/$APP_NAME.app"
mkdir -p "$STAGE/Contents/MacOS" "$STAGE/Contents/Resources" \
    "$STAGE/Contents/Library/LaunchDaemons" "$STAGE/Contents/Library/LaunchServices"
cp "build/$EXECUTABLE" "$STAGE/Contents/MacOS/$EXECUTABLE"
cp "build/$FAN_HELPER_ID" "$STAGE/Contents/Library/LaunchServices/$FAN_HELPER_ID"
mkdir -p "$STAGE/Contents/Frameworks"
cp "build/$NOW_PLAYING_ADAPTER" "$STAGE/Contents/Frameworks/$NOW_PLAYING_ADAPTER"
cp Resources/now-playing.pl "$STAGE/Contents/Resources/now-playing.pl"
cp Resources/com.vorssaint.utils.fan-control.plist \
    "$STAGE/Contents/Library/LaunchDaemons/$FAN_HELPER_ID.plist"
cp Resources/Info.plist "$STAGE/Contents/Info.plist"
cp CHANGELOG.md "$STAGE/Contents/Resources/CHANGELOG.md"
for lproj in Resources/*.lproj(N); do
    cp -R "$lproj" "$STAGE/Contents/Resources/"
done
"$IDENTITY_TMP/identity" "$DEV" --render-bundle "$STAGE"
FAN_PLIST="$STAGE/Contents/Library/LaunchDaemons/$FAN_HELPER_ID.plist"
/usr/libexec/PlistBuddy -c "Set :Label $FAN_HELPER_ID" "$FAN_PLIST"
/usr/libexec/PlistBuddy -c "Set :BundleProgram Contents/Library/LaunchServices/$FAN_HELPER_ID" "$FAN_PLIST"
/usr/libexec/PlistBuddy -c "Delete :MachServices" "$FAN_PLIST"
/usr/libexec/PlistBuddy -c "Add :MachServices dict" "$FAN_PLIST"
/usr/libexec/PlistBuddy -c "Add :MachServices:$FAN_HELPER_ID bool true" "$FAN_PLIST"
if (( DEV )); then
    # Stamp the source commit + build time so the running dev app shows (in About)
    # exactly which code it was compiled from. Lets you verify it matches HEAD before
    # testing, instead of unknowingly running a stale build. Dev-only; never shipped.
    SHA="$(git rev-parse --short HEAD 2>/dev/null || echo unknown)"
    [[ -n "$(git status --porcelain 2>/dev/null)" ]] && SHA="$SHA-dirty"
    /usr/libexec/PlistBuddy -c "Add :VorssaintBuildCommit string '$SHA · $(date '+%Y-%m-%d %H:%M')'" "$STAGE/Contents/Info.plist"
    echo "  stamped dev build: $SHA"
fi
FAN_HELPER_VERSION="$(
    export LC_ALL=C
    /usr/bin/shasum -a 256 \
        "$STAGE/Contents/Library/LaunchServices/$FAN_HELPER_ID" \
        "$STAGE/Contents/Library/LaunchDaemons/$FAN_HELPER_ID.plist" \
        | /usr/bin/awk '{print $1}' | /usr/bin/shasum -a 256 \
        | /usr/bin/awk '{print $1}'
)"
/usr/libexec/PlistBuddy -c "Add :VorssaintFanControlHelperVersion string '$FAN_HELPER_VERSION'" \
    "$STAGE/Contents/Info.plist"
printf 'APPL????' > "$STAGE/Contents/PkgInfo"
cp build/AppIcon.icns "$STAGE/Contents/Resources/AppIcon.icns"
cp build/MenuBarIcon.png build/MenuBarIcon@2x.png build/BrandMark.png "$STAGE/Contents/Resources/"
if [[ -f build/Assets.car ]]; then
    cp build/Assets.car "$STAGE/Contents/Resources/Assets.car"
fi
if [[ -d Resources/Gifs ]]; then
    mkdir -p "$STAGE/Contents/Resources/Gifs"
    cp Resources/Gifs/*.gif "$STAGE/Contents/Resources/Gifs/"
fi
if [[ -d Resources/Images ]]; then
    mkdir -p "$STAGE/Contents/Resources/Images"
    cp Resources/Images/* "$STAGE/Contents/Resources/Images/"
fi
xattr -c -r "$STAGE" 2>/dev/null || true

# Signing, in order of preference:
#   1. Developer ID Application — the real, Apple-issued identity used for
#      notarized releases. Signed with the hardened runtime (required for
#      notarization), the app's entitlements and a secure timestamp. Gives a
#      stable, team-based designated requirement, so permissions persist across
#      updates AND Gatekeeper shows no "unverified developer" warning.
#   2. "Vorssaint Utils Signing" — the legacy stable self-signed identity, kept
#      as a fallback so contributors without a Developer ID still get a constant
#      designated requirement across their local builds.
#   3. Ad-hoc — fresh clone with no identity at all.
DEVID="$(developer_id_identity)"
codesign_app() {
    local target="$1"
    if [[ -n "$DEVID" ]]; then
        codesign_with_timestamp_retry --force --strip-disallowed-xattrs --options runtime --timestamp \
            --entitlements "$ENTITLEMENTS" --sign "$DEVID" "$target"
    elif legacy_identity_installed; then
        codesign --force --strip-disallowed-xattrs --sign "$LEGACY_IDENTITY" "$target"
    else
        codesign --force --strip-disallowed-xattrs --sign - "$target"
    fi
}

codesign_fan_helper() {
    local target="$1"
    if [[ -n "$DEVID" ]]; then
        codesign_with_timestamp_retry --force --strip-disallowed-xattrs --options runtime --timestamp \
            --identifier "$FAN_HELPER_ID" --sign "$DEVID" "$target"
    elif legacy_identity_installed; then
        codesign --force --strip-disallowed-xattrs --identifier "$FAN_HELPER_ID" \
            --sign "$LEGACY_IDENTITY" "$target"
    else
        codesign --force --strip-disallowed-xattrs --identifier "$FAN_HELPER_ID" --sign - "$target"
    fi
}

codesign_now_playing_adapter() {
    local target="$1"
    if [[ -n "$DEVID" ]]; then
        codesign_with_timestamp_retry --force --strip-disallowed-xattrs --options runtime --timestamp \
            --identifier "$NOW_PLAYING_ADAPTER_ID" --sign "$DEVID" "$target"
    elif legacy_identity_installed; then
        codesign --force --strip-disallowed-xattrs --identifier "$NOW_PLAYING_ADAPTER_ID" \
            --sign "$LEGACY_IDENTITY" "$target"
    else
        codesign --force --strip-disallowed-xattrs --identifier "$NOW_PLAYING_ADAPTER_ID" --sign - "$target"
    fi
}

sign_bundle() {
    local bundle="$1"
    local executable="$bundle/Contents/MacOS/$EXECUTABLE"
    local helper="$bundle/Contents/Library/LaunchServices/$FAN_HELPER_ID"
    local adapter="$bundle/Contents/Frameworks/$NOW_PLAYING_ADAPTER"

    if [[ -n "$DEVID" ]]; then
        echo "  signing with Developer ID (hardened runtime): $DEVID"
    elif legacy_identity_installed; then
        echo "  signing with legacy self-signed identity: $LEGACY_IDENTITY"
    else
        echo "  signing ad-hoc (no identity installed — run Tools/setup-signing.sh)"
    fi
    [[ -f "$helper" ]] && codesign_fan_helper "$helper"
    [[ -f "$adapter" ]] && codesign_now_playing_adapter "$adapter"
    codesign_app "$bundle"

    # If local filesystem metadata invalidates the first signature, sign once
    # more. The installed Developer bundle is signed again after the final copy.
    if ! codesign --verify --deep --strict "$bundle" >/dev/null 2>&1; then
        echo "  re-signing after filesystem metadata settled"
        xattr -c -r "$bundle" 2>/dev/null || true
        [[ -f "$helper" ]] && codesign_fan_helper "$helper"
        [[ -f "$adapter" ]] && codesign_now_playing_adapter "$adapter"
        codesign_app "$bundle"
    fi
    [[ -f "$executable" ]] && codesign --verify --strict "$executable"
    [[ -f "$helper" ]] && codesign --verify --strict "$helper"
    [[ -f "$adapter" ]] && codesign --verify --strict "$adapter"
    codesign --verify --deep --strict "$bundle"
}

sign_installed_bundle() {
    local bundle="$1"
    wait_for_install_metadata "$bundle"
    sign_bundle "$bundle"
}

sign_bundle "$STAGE"

process_is_running() {
    local proc="$1"
    if (( ${#proc} > 15 )); then
        pgrep -f "/Contents/MacOS/$proc" >/dev/null 2>&1
    else
        pgrep -x "$proc" >/dev/null 2>&1
    fi
}

stop_process() {
    local proc="$1"
    if (( ${#proc} > 15 )); then
        pkill -f "/Contents/MacOS/$proc" 2>/dev/null || true
    else
        pkill -x "$proc" 2>/dev/null || true
    fi
    for _ in {1..50}; do
        if ! process_is_running "$proc"; then
            return 0
        fi
        sleep 0.1
    done
    echo "✗ $proc is still running — quit it and retry" >&2
    return 1
}

wait_for_install_metadata() {
    local bundle="$1"
    local missing
    for _ in {1..50}; do
        missing=0
        while IFS= read -r file; do
            if ! xattr -p com.apple.provenance "$file" >/dev/null 2>&1; then
                missing=1
                break
            fi
        done < <(find "$bundle/Contents" -type f ! -path "*/_CodeSignature/*")
        if (( missing == 0 )); then
            return 0
        fi
        sleep 0.1
    done
}

mkdir -p "build/stage"
BUILD_STAGE="build/stage/$APP_NAME.app"
rm -rf "$BUILD_STAGE"
ditto --noextattr --noqtn "$STAGE" "$BUILD_STAGE"
xattr -c -r "$BUILD_STAGE" 2>/dev/null || true
if ! codesign --verify --deep --strict "$BUILD_STAGE" >/dev/null 2>&1; then
    if xattr -lr "$BUILD_STAGE" 2>/dev/null | grep -Eq 'com\.apple\.(FinderInfo|ResourceFork|provenance|fileprovider)'; then
        echo "  build/stage copy has local filesystem metadata; temp bundle was verified"
    else
        codesign --verify --deep --strict "$BUILD_STAGE"
    fi
fi
echo "✓ Bundle ready: $BUILD_STAGE"

if (( INSTALL )); then
    echo "▸ Installing into /Applications…"
    stop_process "$EXECUTABLE"
    INSTALL_DEST="/Applications/$APP_NAME.app"
    rm -rf "$INSTALL_DEST"
    ditto --noextattr --noqtn "$STAGE" "$INSTALL_DEST"
    sign_installed_bundle "$INSTALL_DEST"
    echo "✓ Installed: $INSTALL_DEST"
fi
