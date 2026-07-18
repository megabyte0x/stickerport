# StickerBridge macOS static MVP acceptance

Never attach or commit the real WhatsApp database or sticker media.

Record these values in the local test notes:

- macOS version
- WhatsApp version
- Signal Desktop version
- StickerBridge commit
- WhatsApp `Sticker.sqlite` SHA-256 before and after
- number of local packs shown
- number of stickers selected
- generated folder path

## Acceptance

- [ ] The app opens to one plain screen with Connect WhatsApp.
- [ ] Connect WhatsApp opens a visible macOS folder authorization panel.
- [ ] The selected folder is `group.net.whatsapp.WhatsApp.shared`.
- [ ] WhatsApp is fully quit before connecting (not merely closed to the Dock).
- [ ] A nonempty `Sticker.sqlite-wal` is rejected with instructions to quit
      WhatsApp and wait for it to checkpoint; WAL-only packs are never silently
      omitted.
- [ ] An import is rejected if `Sticker.sqlite`, `Sticker.sqlite-wal`, or
      `Sticker.sqlite-shm` changes during the read.
- [ ] Only locally backed installed sticker packs appear.
- [ ] The verified local pack count and sticker count match WhatsApp storage.
- [ ] Every sticker in the chosen pack is selected initially.
- [ ] Clear removes every selection.
- [ ] Select All restores every selection.
- [ ] Deselecting two stickers updates the selected count by exactly two.
- [ ] Create Signal-ready Folder asks for an output parent directory.
- [ ] The output contains one `Stickers/` directory with image files only.
- [ ] Exported WebP bytes match their WhatsApp source bytes.
- [ ] `emoji-reference.txt` matches the exported filenames and order.
- [ ] Finder reveals the exact generated `Stickers/` directory.
- [ ] Signal Desktop opens without private URLs or credentials.
- [ ] Signal Desktop accepts Command-A selection from `Stickers/`.
- [ ] Emoji, title, author, upload, and installation remain visible Signal steps.
- [ ] `Sticker.sqlite` SHA-256 is identical before and after the run.
- [ ] An animated WebP produces the named unsupported-MVP error.
- [ ] A synthetic unknown schema fails without showing partial results.
- [ ] Existing iOS unit tests still pass.
