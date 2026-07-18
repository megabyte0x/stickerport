# Sandboxed WhatsApp container home fix

## Behavior

`WhatsAppContainerPicker.canonicalContainerURL` now derives its base from
`NSHomeDirectoryForUser(NSUserName())`, which resolves the macOS login account
home rather than `FileManager.default.homeDirectoryForCurrentUser` inside the
app sandbox. The picker therefore begins at:

`/Users/megabyte0x/Library/Group Containers/group.net.whatsapp.WhatsApp.shared`

Selection still requires an exact standardized, symlink-resolved comparison to
that canonical root. Security-scoped access and the reader's exact-root and
fail-closed checks are unchanged.

## Test evidence

Ran:

```sh
xcodebuild test -project StickerBridge.xcodeproj -scheme StickerBridgeMac \
  -destination 'platform=macOS' \
  -only-testing:StickerBridgeMacTests/WhatsAppStickerReaderTests \
  -derivedDataPath /private/tmp/stickerbridge-sandbox-home-derived \
  -resultBundlePath /private/tmp/stickerbridge-sandbox-home-tests.xcresult
```

Result: `TEST SUCCEEDED`; 13 tests passed. The focused class covers both the
default login-account-home lookup and fixture-only canonical-root construction;
it never reads real WhatsApp data.

## Commit

`ce7824b fix: resolve WhatsApp container from login home`

## Concern / remaining acceptance

The unit test runs in a sandboxed host and verifies the canonical source and
path construction. A parent-owned live GUI re-test is still needed to confirm
that the signed app's open panel starts at the real Group Containers root and
accepts that exact selection. This change does not open the picker or access
WhatsApp files.
