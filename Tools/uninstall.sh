#!/bin/zsh
# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Vorssaint
# Explicitly removes one verified kururu variant. Never adopts upstream data.
set -euo pipefail
DEVELOPMENT=0
DRY_RUN=0
APP=""
while (( $# )); do
    case "$1" in
        --dev) DEVELOPMENT=1 ;;
        --dry-run) DRY_RUN=1 ;;
        --app) shift; (( $# )) || { print -u2 'Missing --app path'; exit 2; }; APP="$1" ;;
        *) print -u2 'Usage: uninstall.sh [--dev] [--dry-run] [--app /path/to/kururu.app]'; exit 2 ;;
    esac
    shift
done
if (( DEVELOPMENT )); then
    BUNDLE="com.pathgao.kururu.dev"
    APP_NAME="kururu (Developer)"
    EXECUTABLE="kururuDeveloper"
    RULE="/etc/sudoers.d/kururu-dev-clamshell"
else
    BUNDLE="com.pathgao.kururu"
    APP_NAME="kururu"
    EXECUTABLE="kururu"
    RULE="/etc/sudoers.d/kururu-clamshell"
fi
[[ -n "$APP" ]] || APP="/Applications/$APP_NAME.app"
# A missing or mismatched bundle must never authorize deleting a preferences domain.
[[ -d "$APP" && ! -L "$APP" && "$APP" == *.app ]] || { print -u2 'No regular application bundle at the selected path; nothing removed.'; exit 1; }
APP="${APP:A}"
actual_id=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$APP/Contents/Info.plist" 2>/dev/null) || { print -u2 'Cannot read application identity; nothing removed.'; exit 1; }
actual_executable=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleExecutable' "$APP/Contents/Info.plist" 2>/dev/null) || exit 1
[[ "$actual_id" == "$BUNDLE" && "$actual_executable" == "$EXECUTABLE" && -x "$APP/Contents/MacOS/$EXECUTABLE" && ! -L "$APP/Contents/MacOS/$EXECUTABLE" ]] || { print -u2 'Application identity or executable does not match the selected kururu variant; nothing removed.'; exit 1; }
if (( DRY_RUN )); then
    print -r -- "BUNDLE=$BUNDLE" "APP=$APP" "EXECUTABLE=$EXECUTABLE" "RULE=$RULE"
    exit 0
fi
# Use the exact bundle identifier, never a process-name pattern.
/usr/bin/osascript -e "if application id \"$BUNDLE\" is running then tell application id \"$BUNDLE\" to quit"
for attempt in {1..20}; do
    running=$(/usr/bin/osascript -e "application id \"$BUNDLE\" is running")
    [[ "$running" == false ]] && break
    /bin/sleep 0.25
done
[[ "$running" == false ]] || { print -u2 'kururu is still running; nothing removed.'; exit 1; }
# Refuse to discard recovery records when system detachment fails.
"$APP/Contents/MacOS/$EXECUTABLE" --uninstall || { print -u2 'System detachment failed; application and recovery records retained.'; exit 1; }
if [[ "$(/usr/bin/defaults read "$BUNDLE" vorssDisabledSleep 2>/dev/null || true)" == 1 ]]; then
    sleep_state=$(/usr/bin/pmset -g | /usr/bin/awk '/SleepDisabled/ { print $2 }')
    [[ "$sleep_state" == 0 ]] || { print -u2 'Normal sleep is not confirmed; application and recovery records retained.'; exit 1; }
fi
if [[ -e "$RULE" ]]; then
    /usr/bin/osascript -e "do shell script \"/bin/rm -f $RULE\" with administrator privileges with prompt \"kururu uninstaller\""
    [[ ! -e "$RULE" ]] || { print -u2 'kururu rule remains; application and data retained.'; exit 1; }
fi
# Recheck the bundle immediately before removing it.
[[ "$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$APP/Contents/Info.plist")" == "$BUNDLE" ]] || exit 1
/usr/bin/tccutil reset All "$BUNDLE" >/dev/null 2>&1 || true
/usr/bin/defaults delete "$BUNDLE" >/dev/null 2>&1 || true
/usr/bin/security delete-generic-password -s "$BUNDLE.command-bar-query-habits" -a "hmac-key" >/dev/null 2>&1 || true
/bin/rm -f "$HOME/Library/Preferences/$BUNDLE.plist" "$HOME/Library/Preferences/ByHost/$BUNDLE".*.plist(N)
/bin/rm -rf "$HOME/Library/Saved Application State/$BUNDLE.savedState" \
    "$HOME/Library/Application Support/$BUNDLE" "$HOME/Library/Caches/$BUNDLE" \
    "$HOME/Library/HTTPStorages/$BUNDLE" "$HOME/Library/HTTPStorages/$BUNDLE.binarycookies"
/bin/rm -rf "$APP"
print 'kururu variant removed.'
