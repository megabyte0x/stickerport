# StickerBridge macOS static MVP acceptance

Never attach or commit the real WhatsApp databases or sticker media.

Record these values in private local test notes:

- macOS version
- WhatsApp version
- Signal Desktop version
- StickerBridge commit
- SHA-256 before and after for `Sticker.sqlite`
- SHA-256 before and after for `BackedUpKeyValue.sqlite`
- installed pack count
- supported regular Favorites count
- selected unique sticker count
- generated folder path

## Acceptance

- [ ] WhatsApp is fully quit before launch.
- [ ] The app opens one plain screen and automatically presents the macOS
      authorization panel at `group.net.whatsapp.WhatsApp.shared`.
- [ ] Cancelling access shows Try Again without reading another folder.
- [ ] The screen shows Sticker Packs first and Favorites second.
- [ ] Installed pack counts match the locally backed WhatsApp rows.
- [ ] Favorites match supported `fs.v2`/`0x01` rows resolved exactly through
      `ZWACDSTICKER.ZFILEHASH`.
- [ ] Favorite order matches `ZSORT DESC`.
- [ ] Selection starts empty.
- [ ] Select All and Clear affect Sticker Packs without clearing Favorites.
- [ ] Select All and Clear affect Favorites without clearing Sticker Packs.
- [ ] Manual toggles work in both categories.
- [ ] A sticker present in both categories counts and exports once.
- [ ] An action that would exceed 200 stickers leaves selection unchanged and
      shows the Signal limit.
- [ ] Export asks for a parent outside WhatsApp's container.
- [ ] Export creates one collision-safe `StickerBridge - WhatsApp Selection`
      folder.
- [ ] `Stickers/` contains image files only.
- [ ] Exported WebP bytes match their WhatsApp source bytes.
- [ ] `emoji-reference.txt` matches exported filenames and order.
- [ ] Finder reveals the generated `Stickers/` directory.
- [ ] The app prompts to open Signal Desktop after export.
- [ ] Choosing Open Signal Desktop launches the installed Signal app or shows
      the existing not-installed error.
- [ ] Signal Desktop accepts Command-A selection from `Stickers/`.
- [ ] Emoji, title, author, upload, and installation remain visible Signal
      Desktop steps.
- [ ] Both WhatsApp database hashes are unchanged after the run.
- [ ] A nonempty WAL, source change, unsafe path, or running WhatsApp process
      rejects import.
- [ ] A missing Favorites database still permits installed-pack import.
- [ ] Existing iOS unit tests still pass.
