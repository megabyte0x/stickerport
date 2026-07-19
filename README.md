# StickerPort

StickerPort is a local-only macOS app that prepares your WhatsApp Desktop
stickers for Signal Desktop. It reads the sticker packs and Favorites that are
already on your Mac, lets you choose up to 200 static stickers, and creates a
Signal-ready folder.

StickerPort never changes WhatsApp data, uploads a sticker pack, or writes to
Signal's private storage. You remain in control of the final upload through
Signal Desktop's official sticker creator.

## Download

Download `StickerPort-0.2.1.dmg` and its checksum from the
[v0.2.1 release](https://github.com/megabyte0x/stickerport/releases/tag/v0.2.1).
StickerPort requires macOS 15 or newer.

Release DMGs are signed with a Developer ID Application certificate and
notarized by Apple. If Gatekeeper reports that Apple cannot verify the DMG,
do not bypass the warning: verify the checksum and report the affected release
asset so it can be replaced.

To verify the download:

```sh
shasum -a 256 -c StickerPort-0.2.1.dmg.sha256
```

## Use StickerPort

1. Open the DMG and drag StickerPort into Applications.
2. Quit WhatsApp completely with **WhatsApp → Quit WhatsApp**.
3. Open StickerPort.
4. At the macOS folder prompt, allow access to
   `group.net.whatsapp.WhatsApp.shared`.
5. Select stickers from installed packs or Favorites.
6. Choose **Export for Signal** and select an output folder.
7. Follow StickerPort's autoplaying handoff tutorial, or in Signal Desktop
   choose **File → Create/Upload Sticker Pack**.
8. Select the generated `Stickers` folder contents and use
   `emoji-reference.txt` while assigning emoji.

The export folder also contains a short handoff guide. StickerPort opens the
folder in Finder, shows the four-step video, and can launch Signal Desktop, but
Signal performs the upload and installation.

## Current limitations

- WhatsApp must be fully quit before StickerPort reads its databases.
- The importer currently targets the schema observed in WhatsApp Desktop
  26.28.22. A WhatsApp update may require a StickerPort update.
- Only static, valid 512 × 512 WebP stickers at or below Signal's 300 KiB limit
  are exported.
- Signal sticker packs support at most 200 stickers.
- Animated stickers are not supported yet.
- Direct or automatic Signal upload is intentionally out of scope.

## Privacy and safety

StickerPort is sandboxed and asks you to select WhatsApp's shared container.
The importer opens the known SQLite databases read-only, rejects active
write-ahead logs, validates the expected schema, blocks unsafe paths and
symlinks, and verifies that the source did not change while it was being read.
All exported files stay in the folder you select.

## Build from source

Requirements:

- macOS 15 or newer
- Xcode 26
- [XcodeGen](https://github.com/yonaskolb/XcodeGen)

Generate the Xcode project and run the macOS tests:

```sh
xcodegen generate
xcodebuild \
  -project StickerBridge.xcodeproj \
  -scheme StickerBridgeMac \
  -destination 'platform=macOS' \
  test
```

Build an ad-hoc DMG for local testing only:

```sh
ALLOW_ADHOC_DMG=1 script/release_dmg.sh 0.2.1
```

The DMG and checksum are written to `dist/`. The release script creates a
universal `arm64`/`x86_64` app. It refuses to create a publishable release
without Developer ID signing and Apple notarization.

For a Developer ID release, install the certificate in the keychain and run:

```sh
RELEASE_SIGNING_IDENTITY='Developer ID Application: Your Name (TEAMID)' \
NOTARY_PROFILE='notarytool-profile' \
script/release_dmg.sh 0.2.1
```

`NOTARY_PROFILE` must name credentials already stored with
`xcrun notarytool store-credentials`.

API-key notarization is also supported with `NOTARY_KEY_PATH`,
`NOTARY_KEY_ID`, and `NOTARY_ISSUER_ID`. Apple requires a team API key for
`notarytool`; individual API keys are not supported.

The GitHub release workflow requires these Actions secrets:

- `MACOS_DEVELOPER_ID_CERTIFICATE_BASE64`: base64-encoded Developer ID
  Application `.p12` certificate
- `MACOS_DEVELOPER_ID_CERTIFICATE_PASSWORD`: password for the `.p12`
- `APPLE_TEAM_ID`: Apple Developer team identifier
- `APPLE_NOTARY_KEY_BASE64`: base64-encoded App Store Connect API `.p8` key
- `APPLE_NOTARY_KEY_ID`: App Store Connect API key identifier
- `APPLE_NOTARY_ISSUER_ID`: issuer UUID for the team API key

The workflow imports the certificate into a temporary keychain, submits the
DMG with `notarytool`, staples the ticket, runs Gatekeeper assessments, and
only then uploads the release assets. A manual workflow run can replace an
existing tag's assets using the fixed workflow from the selected branch.

## Releases and changelog

User-visible changes are recorded in [CHANGELOG.md](CHANGELOG.md). Pushing a
tag such as `v0.2.1` runs the GitHub release workflow, builds the DMG, creates
the GitHub release with generated notes, and attaches the DMG and checksum.
