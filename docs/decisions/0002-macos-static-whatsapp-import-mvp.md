# ADR 0002: macOS static WhatsApp import MVP

## Status

Accepted.

## Decision

The first macOS StickerBridge release is a local Debug MVP for the verified
native WhatsApp 26.28.22 sticker schema.

The user explicitly chooses
`group.net.whatsapp.WhatsApp.shared`. StickerBridge opens `Sticker.sqlite`
read-only with SQLite's immutable URI mode, loads locally backed installed
packs, selects all stickers in one pack by default, permits individual
deselection, and writes compliant static WebP bytes to an ordinary Signal-ready
folder. The user must fully quit WhatsApp before connecting. The MVP rejects a
nonempty `Sticker.sqlite-wal` rather than omitting WAL-only installed packs, and
rejects the import if `Sticker.sqlite`, `Sticker.sqlite-wal`, or
`Sticker.sqlite-shm` changes during the read.

StickerBridge reveals that folder. The user completes emoji assignment,
title, author, upload, and installation in Signal Desktop's official creator.

## Included

- One plain macOS window.
- One selected WhatsApp pack per export.
- Select All, Clear, and individual sticker toggles.
- Static 512x512 WebP at or below 300 KiB.
- One through 200 selected stickers.
- Image-only `Stickers/` output with an emoji text reference.
- Finder reveal and Signal Desktop launch.

## Excluded

- Animated WebP to APNG conversion.
- Transcoding or compression.
- Persistent WhatsApp authorization.
- Manual file fallback.
- WhatsApp Business, favorites, recents, and catalog downloads.
- Direct Signal upload or creator automation.
- Website implementation.
- Signing, notarization, DMG packaging, and distribution claims.

Rows without safe local media are not shown. Unknown schemas, animated
stickers, invalid dimensions, and oversized files fail clearly during export.
The import also fails clearly if WhatsApp is running, its sticker WAL has not
been checkpointed after quitting, or its SQLite snapshot changes while being
read. It does not claim that an import from a live WhatsApp database is safe.
