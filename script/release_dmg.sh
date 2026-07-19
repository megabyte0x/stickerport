#!/usr/bin/env bash
set -euo pipefail

VERSION="${1:-0.1.0}"
APP_NAME="StickerPort"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DERIVED_DATA="$ROOT_DIR/.build/release"
APP_BUNDLE="$DERIVED_DATA/Build/Products/Release/$APP_NAME.app"
DIST_DIR="$ROOT_DIR/dist"
DMG_NAME="$APP_NAME-$VERSION.dmg"
DMG_PATH="$DIST_DIR/$DMG_NAME"
CHECKSUM_PATH="$DMG_PATH.sha256"
SIGNING_IDENTITY="${RELEASE_SIGNING_IDENTITY:-}"
DEVELOPMENT_TEAM_VALUE="${DEVELOPMENT_TEAM:-}"
ARCHITECTURES="${ARCHS:-arm64 x86_64}"
ALLOW_ADHOC_DMG="${ALLOW_ADHOC_DMG:-0}"
NOTARY_PROFILE_VALUE="${NOTARY_PROFILE:-}"
NOTARY_KEY_PATH_VALUE="${NOTARY_KEY_PATH:-}"
NOTARY_KEY_ID_VALUE="${NOTARY_KEY_ID:-}"
NOTARY_ISSUER_ID_VALUE="${NOTARY_ISSUER_ID:-}"
STAGING_DIR="$(mktemp -d "${TMPDIR:-/tmp}/StickerPort-release.XXXXXX")"

cleanup() {
  rm -rf "$STAGING_DIR"
}
trap cleanup EXIT

if [[ ! "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+([+-][0-9A-Za-z.-]+)?$ ]]; then
  echo "Invalid semantic version: $VERSION" >&2
  exit 2
fi

if [[ -z "$SIGNING_IDENTITY" ]]; then
  if [[ "$ALLOW_ADHOC_DMG" == "1" ]]; then
    SIGNING_IDENTITY="-"
  else
    echo "A Developer ID Application identity is required for a distributable DMG." >&2
    echo "Set RELEASE_SIGNING_IDENTITY, or use ALLOW_ADHOC_DMG=1 for a local-only artifact." >&2
    exit 2
  fi
fi

if [[ "$SIGNING_IDENTITY" == "-" && "$ALLOW_ADHOC_DMG" != "1" ]]; then
  echo "Ad-hoc signing is local-only and must be explicitly enabled with ALLOW_ADHOC_DMG=1." >&2
  exit 2
fi

has_notary_profile=0
has_notary_key=0
if [[ -n "$NOTARY_PROFILE_VALUE" ]]; then
  has_notary_profile=1
fi
if [[ -n "$NOTARY_KEY_PATH_VALUE" || -n "$NOTARY_KEY_ID_VALUE" || -n "$NOTARY_ISSUER_ID_VALUE" ]]; then
  if [[ -z "$NOTARY_KEY_PATH_VALUE" || -z "$NOTARY_KEY_ID_VALUE" || -z "$NOTARY_ISSUER_ID_VALUE" ]]; then
    echo "API-key notarization requires a team key: NOTARY_KEY_PATH, NOTARY_KEY_ID, and NOTARY_ISSUER_ID." >&2
    exit 2
  fi
  if [[ ! -f "$NOTARY_KEY_PATH_VALUE" ]]; then
    echo "Notary API key was not found at $NOTARY_KEY_PATH_VALUE" >&2
    exit 2
  fi
  has_notary_key=1
fi
if [[ "$has_notary_profile" == "1" && "$has_notary_key" == "1" ]]; then
  echo "Choose one notarization method: NOTARY_PROFILE or NOTARY_KEY_PATH/NOTARY_KEY_ID." >&2
  exit 2
fi
if [[ "$SIGNING_IDENTITY" != "-" && "$has_notary_profile" == "0" && "$has_notary_key" == "0" ]]; then
  echo "Developer ID builds must be notarized before distribution." >&2
  echo "Set NOTARY_PROFILE or team API-key credentials." >&2
  exit 2
fi

cd "$ROOT_DIR"
xcodegen generate

build_arguments=(
  -project StickerBridge.xcodeproj
  -scheme StickerBridgeMac
  -configuration Release
  -destination "generic/platform=macOS"
  -derivedDataPath "$DERIVED_DATA"
  -quiet
  "ARCHS=$ARCHITECTURES"
  ONLY_ACTIVE_ARCH=NO
  CODE_SIGN_STYLE=Manual
  "CODE_SIGN_IDENTITY=$SIGNING_IDENTITY"
  "DEVELOPMENT_TEAM=$DEVELOPMENT_TEAM_VALUE"
  ENABLE_HARDENED_RUNTIME=YES
  CODE_SIGN_INJECT_BASE_ENTITLEMENTS=NO
)

if [[ "$SIGNING_IDENTITY" != "-" ]]; then
  build_arguments+=("OTHER_CODE_SIGN_FLAGS=--timestamp")
fi

xcodebuild "${build_arguments[@]}" clean build

if [[ ! -d "$APP_BUNDLE" ]]; then
  echo "Release app was not created at $APP_BUNDLE" >&2
  exit 1
fi

BUILT_VERSION="$(
  /usr/libexec/PlistBuddy \
    -c 'Print :CFBundleShortVersionString' \
    "$APP_BUNDLE/Contents/Info.plist"
)"
if [[ "$BUILT_VERSION" != "$VERSION" ]]; then
  echo "Requested version $VERSION does not match app version $BUILT_VERSION" >&2
  exit 1
fi

codesign --verify --deep --strict --verbose=2 "$APP_BUNDLE"
SIGNING_DETAILS="$(codesign -dvvv "$APP_BUNDLE" 2>&1)"
if [[ "$SIGNING_IDENTITY" != "-" ]]; then
  if ! grep -q '^Authority=Developer ID Application:' <<< "$SIGNING_DETAILS"; then
    echo "Release app is not signed with a Developer ID Application certificate." >&2
    echo "$SIGNING_DETAILS" >&2
    exit 1
  fi
  if ! grep -q '^Authority=Developer ID Certification Authority$' <<< "$SIGNING_DETAILS" || \
    ! grep -q '^Authority=Apple Root CA$' <<< "$SIGNING_DETAILS"; then
    echo "Release signature does not chain to Apple's Developer ID trust anchors." >&2
    echo "$SIGNING_DETAILS" >&2
    exit 1
  fi
  if ! grep -Eq '^CodeDirectory .*flags=.*runtime' <<< "$SIGNING_DETAILS"; then
    echo "Release app does not have the hardened runtime enabled." >&2
    echo "$SIGNING_DETAILS" >&2
    exit 1
  fi
  if [[ -n "$DEVELOPMENT_TEAM_VALUE" ]] && \
    ! grep -q "^TeamIdentifier=$DEVELOPMENT_TEAM_VALUE$" <<< "$SIGNING_DETAILS"; then
    echo "Release signature does not match DEVELOPMENT_TEAM=$DEVELOPMENT_TEAM_VALUE." >&2
    echo "$SIGNING_DETAILS" >&2
    exit 1
  fi
fi
ENTITLEMENTS_PATH="$STAGING_DIR/release-entitlements.plist"
codesign -d --xml --entitlements - "$APP_BUNDLE" > "$ENTITLEMENTS_PATH"
if /usr/libexec/PlistBuddy \
  -c 'Print :com.apple.security.get-task-allow' \
  "$ENTITLEMENTS_PATH" 2>/dev/null | grep -q true; then
  echo "Release app must not include com.apple.security.get-task-allow." >&2
  exit 1
fi

mkdir -p "$DIST_DIR"
ditto "$APP_BUNDLE" "$STAGING_DIR/$APP_NAME.app"
ln -s /Applications "$STAGING_DIR/Applications"

hdiutil create \
  -volname "$APP_NAME" \
  -srcfolder "$STAGING_DIR" \
  -format UDZO \
  -ov \
  "$DMG_PATH"

dmg_sign_arguments=(--force --sign "$SIGNING_IDENTITY")
if [[ "$SIGNING_IDENTITY" != "-" ]]; then
  dmg_sign_arguments+=(--timestamp)
fi
codesign "${dmg_sign_arguments[@]}" "$DMG_PATH"
codesign --verify --verbose=2 "$DMG_PATH"
hdiutil verify "$DMG_PATH"

if [[ "$SIGNING_IDENTITY" != "-" ]]; then
  notary_arguments=()
  if [[ "$has_notary_profile" == "1" ]]; then
    notary_arguments+=(--keychain-profile "$NOTARY_PROFILE_VALUE")
  else
    notary_arguments+=(
      --key "$NOTARY_KEY_PATH_VALUE"
      --key-id "$NOTARY_KEY_ID_VALUE"
    )
    if [[ -n "$NOTARY_ISSUER_ID_VALUE" ]]; then
      notary_arguments+=(--issuer "$NOTARY_ISSUER_ID_VALUE")
    fi
  fi
  xcrun notarytool submit "$DMG_PATH" "${notary_arguments[@]}" --wait
  xcrun stapler staple "$DMG_PATH"
  xcrun stapler validate "$DMG_PATH"
  spctl --assess --type execute --verbose=2 "$APP_BUNDLE"
  spctl \
    --assess \
    --type open \
    --context context:primary-signature \
    --verbose=2 \
    "$DMG_PATH"
else
  echo "Created an explicitly allowed ad-hoc DMG for local testing only."
fi

(
  cd "$DIST_DIR"
  shasum -a 256 "$DMG_NAME" > "$DMG_NAME.sha256"
)

echo "Created $DMG_PATH"
echo "Created $CHECKSUM_PATH"
lipo -info "$APP_BUNDLE/Contents/MacOS/$APP_NAME"
