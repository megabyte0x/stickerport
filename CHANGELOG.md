# Changelog

All notable changes to StickerPort are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project uses [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Fixed

- Release publishing now stages assets as a draft, verifies the uploaded DMG,
  and exposes the stable download alias only after Developer ID, notarization,
  Gatekeeper, checksum, version, entitlement, and architecture checks pass.
- Manually published releases are automatically returned to draft if their DMG
  is missing or fails the same distribution checks.
- The website download route no longer depends on GitHub's rate-limited latest
  release API.

## [0.2.1] - 2026-07-19

### Added

- The post-export Signal handoff now includes an autoplaying, silent tutorial
  showing how to select the generated stickers, finish the pack, and install it.

## [0.2.0] - 2026-07-19

### Changed

- Refreshed the macOS interface with a lighter, more lively StickerPort theme
  and a more focused sticker-first catalog.
- Removed redundant emoji labels and sticker filenames from the catalog tiles.

### Fixed

- Release DMGs now require Developer ID signing and Apple notarization before
  GitHub publishes them, preventing Gatekeeper's “Apple could not verify”
  rejection for downloaded builds.

## [0.1.0] - 2026-07-19

### Added

- A sandboxed macOS app for reading locally installed WhatsApp Desktop sticker
  packs and Favorites after explicit folder authorization.
- Selection controls for exporting up to 200 Signal-compatible static WebP
  stickers.
- A Signal-ready export folder containing numbered stickers, an emoji
  reference, and handoff instructions for Signal Desktop.
- Read-only SQLite access with schema validation, write-ahead-log checks,
  source-change detection, and path-containment protections.
- A universal macOS DMG release script with checksum generation and optional
  Developer ID signing and notarization.
- Automated GitHub release notes and tag-triggered DMG publishing.

[Unreleased]: https://github.com/megabyte0x/stickerport/compare/v0.2.1...HEAD
[0.2.1]: https://github.com/megabyte0x/stickerport/compare/v0.2.0...v0.2.1
[0.2.0]: https://github.com/megabyte0x/stickerport/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/megabyte0x/stickerport/releases/tag/v0.1.0
