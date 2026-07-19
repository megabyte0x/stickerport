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
SIGNING_IDENTITY="${RELEASE_SIGNING_IDENTITY:--}"
DEVELOPMENT_TEAM_VALUE="${DEVELOPMENT_TEAM:-}"
ARCHITECTURES="${ARCHS:-arm64 x86_64}"
STAGING_DIR="$(mktemp -d "${TMPDIR:-/tmp}/StickerPort-release.XXXXXX")"

cleanup() {
  rm -rf "$STAGING_DIR"
}
trap cleanup EXIT

if [[ ! "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+([+-][0-9A-Za-z.-]+)?$ ]]; then
  echo "Invalid semantic version: $VERSION" >&2
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
ENTITLEMENTS_PATH="$STAGING_DIR/release-entitlements.plist"
codesign -d --entitlements :- "$APP_BUNDLE" > "$ENTITLEMENTS_PATH"
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

codesign --force --sign "$SIGNING_IDENTITY" "$DMG_PATH"
codesign --verify --verbose=2 "$DMG_PATH"
hdiutil verify "$DMG_PATH"

if [[ -n "${NOTARY_PROFILE:-}" ]]; then
  if [[ "$SIGNING_IDENTITY" == "-" ]]; then
    echo "NOTARY_PROFILE requires a Developer ID signing identity." >&2
    exit 1
  fi
  xcrun notarytool submit \
    "$DMG_PATH" \
    --keychain-profile "$NOTARY_PROFILE" \
    --wait
  xcrun stapler staple "$DMG_PATH"
  xcrun stapler validate "$DMG_PATH"
  spctl \
    --assess \
    --type open \
    --context context:primary-signature \
    --verbose=2 \
    "$DMG_PATH"
else
  echo "Created an ad-hoc signed DMG; Apple notarization was not requested."
fi

(
  cd "$DIST_DIR"
  shasum -a 256 "$DMG_NAME" > "$DMG_NAME.sha256"
)

echo "Created $DMG_PATH"
echo "Created $CHECKSUM_PATH"
lipo -info "$APP_BUNDLE/Contents/MacOS/$APP_NAME"
