#!/bin/zsh
# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Vorssaint

# Notarizes and staples a built artifact (the .app or the .dmg) with Apple's
# notary service, so Gatekeeper opens it without the "unverified developer"
# warning. Run in CI: once on the app (before packaging) and once on the DMG.
#
# Credentials come from the environment (CI secrets):
#   NOTARY_API_KEY_P8   base64 of the App Store Connect API key (.p8)
#   NOTARY_KEY_ID       the key's ID
#   NOTARY_ISSUER_ID    the issuer UUID
#
# Alternatively use NOTARY_KEYCHAIN_PROFILE locally, or APPLE_ID,
# APPLE_APP_SPECIFIC_PASSWORD and APPLE_TEAM_ID.
# When the credentials are absent it skips quietly (exit 0), so a plain build
# without notarization still succeeds.
set -euo pipefail
umask 077
cd "$(dirname "$0")/.."

TARGET="${1:-}"
if [[ -z "$TARGET" ]]; then
    echo "usage: notarize.sh <app-or-dmg>" >&2
    exit 1
fi

AUTH=()
if [[ -n "${NOTARY_KEYCHAIN_PROFILE:-}" ]]; then
    AUTH=(--keychain-profile "$NOTARY_KEYCHAIN_PROFILE")
elif [[ -n "${APPLE_ID:-}" && -n "${APPLE_APP_SPECIFIC_PASSWORD:-}" && -n "${APPLE_TEAM_ID:-}" ]]; then
    AUTH=(--apple-id "$APPLE_ID" --password "$APPLE_APP_SPECIFIC_PASSWORD" --team-id "$APPLE_TEAM_ID")
elif [[ -z "${NOTARY_API_KEY_P8:-}" || -z "${NOTARY_KEY_ID:-}" || -z "${NOTARY_ISSUER_ID:-}" ]]; then
    if [[ "${REQUIRE_NOTARIZATION:-0}" == "1" ]]; then
        echo "Release notarization credentials are incomplete." >&2
        exit 1
    fi
    echo "No notarization credentials — skipping ($TARGET)."
    exit 0
fi
if [[ ! -e "$TARGET" ]]; then
    echo "✗ $TARGET not found" >&2
    exit 1
fi

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

if (( ${#AUTH[@]} == 0 )); then
    P8="$WORK/AuthKey.p8"
    printf '%s' "$NOTARY_API_KEY_P8" | base64 --decode > "$P8"
    AUTH=(--key "$P8" --key-id "$NOTARY_KEY_ID" --issuer "$NOTARY_ISSUER_ID")
fi

# notarytool needs a zip/dmg/pkg. A .app is zipped first; a .dmg is submitted
# as-is. Stapling always targets the original artifact.
case "$TARGET" in
    *.app)
        xattr -cr "$TARGET"
        codesign --verify --deep --strict "$TARGET"
        SUBMIT="$WORK/$(basename "$TARGET").zip"
        /usr/bin/ditto -c -k --keepParent "$TARGET" "$SUBMIT"
        ;;
    *)
        SUBMIT="$TARGET"
        ;;
esac

echo "▸ Submitting $(basename "$TARGET") to the notary service (can take a few minutes)…"
xcrun notarytool submit "$SUBMIT" \
    "${AUTH[@]}" --wait

# Staple the ticket so it is recognized even offline. Fails (and fails the build)
# if notarization did not actually succeed, so a bad result never ships.
echo "▸ Stapling $(basename "$TARGET")…"
xcrun stapler staple "$TARGET"
echo "✓ Notarized and stapled: $(basename "$TARGET")"
