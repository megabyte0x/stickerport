# ADR 0002: macOS static WhatsApp import MVP

## Status

Accepted.

## Decision

The macOS StickerPort MVP supports the verified native WhatsApp 26.28.22
sticker schema. On launch it computes the canonical current-user container and
opens the macOS authorization panel at
`group.net.whatsapp.WhatsApp.shared`. The sandbox still requires the user to
confirm access.

After WhatsApp is fully quit, StickerPort opens `Sticker.sqlite` and optional
`BackedUpKeyValue.sqlite` read-only with SQLite immutable URI mode. It imports
locally backed installed packs and regular `fs.v2` Favorites resolved by exact
file-hash equality. It never changes WhatsApp data.

The screen shows Sticker Packs and Favorites separately. Selection starts
empty. Each category has independent Select All and Clear actions, and every
sticker can be toggled manually. A combined selection contains 1 through 200
unique static WebP stickers.

StickerPort writes compliant bytes to one ordinary Signal-ready folder,
reveals its `Stickers/` directory, and prompts the user to open Signal Desktop.
The user completes File → Create/Upload Sticker Pack, emoji assignment, title,
author, upload, and installation in Signal Desktop.

## Included

- One plain macOS window.
- Launch-time authorization at the automatically resolved WhatsApp container.
- Read-only installed packs and regular Favorites.
- Independent category Select All, Clear, and individual toggles.
- One combined 1-200 sticker export.
- Static 512x512 WebP at or below 300 KiB.
- Image-only `Stickers/` output with an emoji text reference.
- Finder reveal and explicit Signal Desktop prompt.

## Excluded

- Silent first-use cross-container access.
- Persistent WhatsApp authorization.
- Animated WebP to APNG conversion.
- Transcoding or compression.
- Manual file fallback.
- WhatsApp Business, recents, avatar/generated Favorites, and catalog downloads.
- Direct Signal upload, private Signal storage access, or creator automation.
- Website implementation.
- Signing, notarization, DMG packaging, and distribution claims.

Rows without safe local media are not shown. Unknown installed-pack schemas
fail closed. Unsupported Favorite rows are skipped while recognized installed
packs remain available. A nonempty source WAL, a running WhatsApp process, or a
source snapshot change rejects the import.
