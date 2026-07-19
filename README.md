# StickerPort

StickerPort is a local-only macOS app that prepares your WhatsApp Desktop
stickers for Signal Desktop. It reads the sticker packs and Favorites that are
already on your Mac, lets you choose up to 200 static stickers, and creates a
Signal-ready folder.

StickerPort never changes WhatsApp data, uploads a sticker pack, or writes to
Signal's private storage. You remain in control of the final upload through
Signal Desktop's official sticker creator.

## Download

Download `StickerPort-0.1.0.dmg` and its checksum from the
[v0.1.0 release](https://github.com/megabyte0x/stickerport/releases/tag/v0.1.0).
StickerPort requires macOS 15 or newer.

The v0.1.0 DMG is ad-hoc signed and is not Apple-notarized. On first launch,
macOS may identify it as coming from an unidentified developer. Control-click
StickerPort in Applications, choose **Open**, then confirm. If macOS does not
offer that choice, use **System Settings → Privacy & Security → Open Anyway**.

To verify the download:

```sh
shasum -a 256 -c StickerPort-0.1.0.dmg.sha256
```

## Use StickerPort

1. Open the DMG and drag StickerPort into Applications.
2. Quit WhatsApp completely with **WhatsApp → Quit WhatsApp**.
3. Open StickerPort.
4. At the macOS folder prompt, allow access to
   `group.net.whatsapp.WhatsApp.shared`.
5. Select stickers from installed packs or Favorites.
6. Choose **Export for Signal** and select an output folder.
7. In Signal Desktop, choose **File → Create/Upload Sticker Pack**.
8. Select the generated `Stickers` folder contents and use
   `emoji-reference.txt` while assigning emoji.

The export folder also contains a short handoff guide. StickerPort opens the
folder in Finder and can launch Signal Desktop, but Signal performs the upload
and installation.

## v0.1 limitations

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

Build the v0.1.0 DMG:

```sh
script/release_dmg.sh 0.1.0
```

The DMG and checksum are written to `dist/`. The release script creates a
universal `arm64`/`x86_64` app and uses an ad-hoc signature by default.

For a Developer ID release, install the certificate in the keychain and run:

```sh
RELEASE_SIGNING_IDENTITY='Developer ID Application: Your Name (TEAMID)' \
NOTARY_PROFILE='notarytool-profile' \
script/release_dmg.sh 0.1.0
```

`NOTARY_PROFILE` must name credentials already stored with
`xcrun notarytool store-credentials`.

## Releases and changelog

User-visible changes are recorded in [CHANGELOG.md](CHANGELOG.md). Pushing a
tag such as `v0.1.0` runs the GitHub release workflow, builds the DMG, creates
the GitHub release with generated notes, and attaches the DMG and checksum.
