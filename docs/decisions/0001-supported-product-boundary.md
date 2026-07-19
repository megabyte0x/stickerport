# ADR 0001: Supported product boundary

## Status

Accepted.

## Decision

On iOS, StickerBridge imports only files the user explicitly provides through
Files or the iOS share sheet. The iOS app does not enumerate WhatsApp's private
sticker library.

The macOS product has a separate, read-only boundary in ADR 0002. It may import
locally backed stickers from a user-authorized WhatsApp Desktop container.

StickerBridge converts media on-device and exports Signal-compatible files for
Signal Desktop. It does not upload to Signal, handle Signal credentials, or use
undocumented Signal endpoints.

Direct iPhone-to-Signal installation remains blocked until Signal publishes a
supported third-party upload flow or gives written approval covering
authentication, rate limits, service-account usage, and App Store distribution.

## Consequences

- The shipping copy says "Prepare for Signal," not "Import directly."
- A computer with linked Signal Desktop is required to finish pack creation.
- Files/share-sheet input availability depends on what the source app exposes.
- A direct-install feature requires a new ADR, threat model, and implementation plan.
