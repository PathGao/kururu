#!/bin/zsh
# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Vorssaint

# Packages the built app into a styled, distributable DMG
# (dist/Vorssaint-<version>.dmg): a window with the app icon, an arrow and
# the Applications folder for drag-and-drop install. Run ./build.sh first.
set -euo pipefail
cd "$(dirname "$0")/.."

APP_NAME="Vorssaint"
APP="build/stage/$APP_NAME.app"
VOLUME="$APP_NAME"
STAGING=""
WORK=""
MOUNT=""

cleanup() {
    if [[ -n "$MOUNT" ]]; then
        hdiutil detach "$MOUNT" -quiet 2>/dev/null \
            || hdiutil detach "$MOUNT" -force -quiet 2>/dev/null \
            || true
    fi
    [[ -n "$STAGING" ]] && rm -rf "$STAGING"
    [[ -n "$WORK" ]] && rm -rf "$WORK"
}
trap cleanup EXIT

if [[ ! -d "$APP" ]]; then
    echo "✗ $APP not found — run ./build.sh first" >&2
    exit 1
fi
xattr -cr "$APP"
codesign --verify --deep --strict "$APP"

VERSION="$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' "$APP/Contents/Info.plist")"
OUT="dist/Vorssaint-$VERSION.dmg"

echo "▸ Rendering installer background…"
swift Tools/MakeDMGBackground.swift build/dmg-background.png

echo "▸ Staging DMG contents…"
STAGING="$(mktemp -d)"
ditto "$APP" "$STAGING/$APP_NAME.app"
xattr -cr "$STAGING/$APP_NAME.app"
codesign --verify --deep --strict "$STAGING/$APP_NAME.app"
ln -s /Applications "$STAGING/Applications"
mkdir "$STAGING/.background"
cp build/dmg-background.png "$STAGING/.background/background.png"

echo "▸ Creating writable image…"
WORK="$(mktemp -d)"
RW="$WORK/rw.dmg"
# Clear any stale mount left by a previous attempt on the same runner.
hdiutil detach "/Volumes/$VOLUME" -force 2>/dev/null || true
# hdiutil can fail transiently on CI runners; retry a few times. No -quiet, so a
# real error is visible in the build log rather than swallowed.
created=0
for attempt in 1 2 3; do
    if hdiutil create -volname "$VOLUME" -srcfolder "$STAGING" -fs HFS+ -format UDRW -ov "$RW"; then
        created=1
        break
    fi
    echo "  hdiutil create failed (attempt $attempt of 3), retrying…" >&2
    rm -f "$RW"
    sleep 3
done
if [[ $created -ne 1 ]]; then
    echo "✗ Could not create the disk image after 3 attempts" >&2
    exit 1
fi
ATTACH_OUTPUT="$(hdiutil attach "$RW" -nobrowse)"
MOUNT="$(printf '%s\n' "$ATTACH_OUTPUT" | awk '/\/Volumes\// {print substr($0, index($0, "/Volumes/")); exit}')"
if [[ -z "$MOUNT" || ! -d "$MOUNT" ]]; then
    echo "✗ Could not find mounted volume in hdiutil output" >&2
    printf '%s\n' "$ATTACH_OUTPUT" >&2
    exit 1
fi

echo "▸ Arranging window (icons, arrow, background)…"
# Finder automation lays out the window; best-effort so a headless hiccup never
# fails the release (the DMG is still valid, just unstyled that once).
osascript <<APPLESCRIPT &
tell application "Finder"
    tell disk "$VOLUME"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set the bounds of container window to {200, 120, 800, 520}
        set theOptions to the icon view options of container window
        set arrangement of theOptions to not arranged
        set icon size of theOptions to 128
        set text size of theOptions to 13
        set background picture of theOptions to file ".background:background.png"
        set position of item "$APP_NAME.app" of container window to {150, 200}
        set position of item "Applications" of container window to {450, 200}
        update without registering applications
        delay 1
        close
    end tell
end tell
APPLESCRIPT
STYLE_PID=$!
STYLE_STATUS=0
STYLE_TIMED_OUT=0
for _ in {1..25}; do
    if ! kill -0 "$STYLE_PID" 2>/dev/null; then
        wait "$STYLE_PID" || STYLE_STATUS=$?
        break
    fi
    sleep 1
done
if kill -0 "$STYLE_PID" 2>/dev/null; then
    STYLE_TIMED_OUT=1
    kill "$STYLE_PID" 2>/dev/null || true
    sleep 1
    kill -9 "$STYLE_PID" 2>/dev/null || true
    wait "$STYLE_PID" 2>/dev/null || true
fi
if (( STYLE_TIMED_OUT )); then
    echo "  (window styling timed out; continuing with a valid unstyled DMG)"
elif (( STYLE_STATUS != 0 )); then
    echo "  (window styling skipped)"
fi

sync
hdiutil detach "$MOUNT" -quiet \
    || hdiutil detach "$MOUNT" -force -quiet
MOUNT=""

echo "▸ Compressing…"
mkdir -p dist
rm -f "$OUT"
hdiutil convert "$RW" -format UDZO -imagekey zlib-level=9 -o "$OUT" -quiet

echo "✓ DMG ready: $OUT"
