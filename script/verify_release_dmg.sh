#!/usr/bin/env bash
set -euo pipefail

DMG_PATH="${1:-}"
EXPECTED_VERSION="${2:-}"
APP_NAME="${APP_NAME:-StickerPort}"
EXPECTED_TEAM_ID="${EXPECTED_TEAM_ID:-9UR77TD484}"
EXPECTED_ARCHITECTURES="${EXPECTED_ARCHITECTURES:-arm64 x86_64}"

if [[ -z "$DMG_PATH" ]]; then
  echo "Usage: $0 <path-to-dmg> [expected-version]" >&2
  exit 2
fi

if [[ ! -f "$DMG_PATH" ]]; then
  echo "DMG was not found: $DMG_PATH" >&2
  exit 2
fi

DMG_PATH="$(
  cd "$(dirname "$DMG_PATH")"
  printf '%s/%s\n' "$PWD" "$(basename "$DMG_PATH")"
)"
TEMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/StickerPort-verify.XXXXXX")"
MOUNT_POINT="$TEMP_DIR/mount"
MOUNTED=0

cleanup() {
  if [[ "$MOUNTED" == "1" ]]; then
    hdiutil detach "$MOUNT_POINT" >/dev/null 2>&1 ||
      hdiutil detach -force "$MOUNT_POINT" >/dev/null 2>&1 ||
      true
  fi
  rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

require_line() {
  local output="$1"
  local pattern="$2"
  local failure_message="$3"

  if ! grep -Eq "$pattern" <<< "$output"; then
    echo "$failure_message" >&2
    echo "$output" >&2
    exit 1
  fi
}

verify_gatekeeper() {
  local assessment_type="$1"
  local artifact_path="$2"
  local output

  if [[ "$assessment_type" == "open" ]]; then
    if ! output="$(
      spctl \
        --assess \
        --type open \
        --context context:primary-signature \
        --verbose=3 \
        "$artifact_path" 2>&1
    )"; then
      echo "Gatekeeper rejected $artifact_path" >&2
      echo "$output" >&2
      exit 1
    fi
  else
    if ! output="$(
      spctl \
        --assess \
        --type execute \
        --verbose=3 \
        "$artifact_path" 2>&1
    )"; then
      echo "Gatekeeper rejected $artifact_path" >&2
      echo "$output" >&2
      exit 1
    fi
  fi

  require_line "$output" '(^|: )accepted$' \
    "Gatekeeper did not report an accepted verdict for $artifact_path."
  require_line "$output" '^source=Notarized Developer ID$' \
    "Gatekeeper did not identify $artifact_path as Notarized Developer ID."
}

CHECKSUM_PATH="$DMG_PATH.sha256"
if [[ -f "$CHECKSUM_PATH" ]]; then
  expected_checksum="$(awk 'NR == 1 { print $1 }' "$CHECKSUM_PATH")"
  actual_checksum="$(shasum -a 256 "$DMG_PATH" | awk '{ print $1 }')"
  if [[ -z "$expected_checksum" || "$actual_checksum" != "$expected_checksum" ]]; then
    echo "SHA-256 checksum verification failed for $DMG_PATH." >&2
    exit 1
  fi
fi

codesign --verify --strict --verbose=2 "$DMG_PATH"
DMG_SIGNING_DETAILS="$(codesign -dvvv "$DMG_PATH" 2>&1)"
require_line "$DMG_SIGNING_DETAILS" '^Authority=Developer ID Application:' \
  "The DMG is not signed with a Developer ID Application certificate."
require_line "$DMG_SIGNING_DETAILS" "^TeamIdentifier=$EXPECTED_TEAM_ID$" \
  "The DMG signature does not belong to team $EXPECTED_TEAM_ID."
require_line "$DMG_SIGNING_DETAILS" '^Timestamp=' \
  "The DMG signature does not include a trusted timestamp."
if grep -Eq 'flags=.*adhoc|^Signature=adhoc$' <<< "$DMG_SIGNING_DETAILS"; then
  echo "The DMG has an ad-hoc signature and must not be distributed." >&2
  exit 1
fi

hdiutil verify "$DMG_PATH"
xcrun stapler validate "$DMG_PATH"
verify_gatekeeper open "$DMG_PATH"

mkdir -p "$MOUNT_POINT"
hdiutil attach \
  -readonly \
  -nobrowse \
  -mountpoint "$MOUNT_POINT" \
  "$DMG_PATH" >/dev/null
MOUNTED=1

APP_BUNDLE="$MOUNT_POINT/$APP_NAME.app"
if [[ ! -d "$APP_BUNDLE" ]]; then
  echo "The DMG does not contain $APP_NAME.app at its top level." >&2
  exit 1
fi

codesign --verify --deep --strict --verbose=2 "$APP_BUNDLE"
APP_SIGNING_DETAILS="$(codesign -dvvv "$APP_BUNDLE" 2>&1)"
require_line "$APP_SIGNING_DETAILS" '^Authority=Developer ID Application:' \
  "The app is not signed with a Developer ID Application certificate."
require_line "$APP_SIGNING_DETAILS" "^TeamIdentifier=$EXPECTED_TEAM_ID$" \
  "The app signature does not belong to team $EXPECTED_TEAM_ID."
require_line "$APP_SIGNING_DETAILS" '^Timestamp=' \
  "The app signature does not include a trusted timestamp."
require_line "$APP_SIGNING_DETAILS" '^CodeDirectory .*flags=.*runtime' \
  "The app does not have the hardened runtime enabled."
if grep -Eq 'flags=.*adhoc|^Signature=adhoc$' <<< "$APP_SIGNING_DETAILS"; then
  echo "The app has an ad-hoc signature and must not be distributed." >&2
  exit 1
fi

BUILT_VERSION="$(
  /usr/libexec/PlistBuddy \
    -c 'Print :CFBundleShortVersionString' \
    "$APP_BUNDLE/Contents/Info.plist"
)"
if [[ -n "$EXPECTED_VERSION" && "$BUILT_VERSION" != "$EXPECTED_VERSION" ]]; then
  echo "Expected app version $EXPECTED_VERSION, found $BUILT_VERSION." >&2
  exit 1
fi

ENTITLEMENTS_PATH="$TEMP_DIR/release-entitlements.plist"
codesign -d --xml --entitlements - "$APP_BUNDLE" > "$ENTITLEMENTS_PATH"
if /usr/libexec/PlistBuddy \
  -c 'Print :com.apple.security.get-task-allow' \
  "$ENTITLEMENTS_PATH" 2>/dev/null | grep -q true; then
  echo "The release app contains com.apple.security.get-task-allow." >&2
  exit 1
fi

ARCHITECTURE_DETAILS="$(
  lipo -info "$APP_BUNDLE/Contents/MacOS/$APP_NAME"
)"
for architecture in $EXPECTED_ARCHITECTURES; do
  require_line "$ARCHITECTURE_DETAILS" "(^| )$architecture( |$)" \
    "The app executable is missing the $architecture architecture."
done

verify_gatekeeper execute "$APP_BUNDLE"

echo "Verified notarized Developer ID DMG: $DMG_PATH"
echo "Version: $BUILT_VERSION"
echo "Team: $EXPECTED_TEAM_ID"
echo "Architectures: $EXPECTED_ARCHITECTURES"
