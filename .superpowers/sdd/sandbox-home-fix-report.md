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

## POSIX follow-up

The subsequent live GUI re-test disproved the Foundation assumption: the
signed sandboxed app still produced its container `Data` home. The production
source now uses `getpwuid_r(getuid())` from Darwin and takes `pw_dir` from the
login account record. Its buffer starts at `_SC_GETPW_R_SIZE_MAX` (with a safe
minimum), retries boundedly on `ERANGE`, and copies the home path before the
buffer is released.

`resolvedLoginUserHomeDirectory` is an injectable seam that rejects a missing
account record or non-absolute home. The exact canonical container comparison,
security-scoped access, and reader's fail-closed checks remain unchanged.

Test command remained the focused macOS importer command above. Result:
`TEST SUCCEEDED`; 15 tests passed, including the POSIX default-root assertion
and missing/relative-account-home failures. No WhatsApp files or live picker
were accessed.

Source/test commit: `415b7db fix: use POSIX home for WhatsApp container`.
Remaining acceptance is the parent-owned live signed-app picker re-test.

## Review hardening follow-up

The POSIX account-home resolver now accepts only a canonical absolute `pw_dir`:
it rejects control characters and rejects inputs whose Foundation
standardization changes their path. Synthetic coverage includes double-slash,
traversal, and control-character absolute paths; no test invokes `getuid()` or
`getpwuid_r`.

The low-level account lookup is now injectable for tests. Its `ERANGE` retry
clamps the next capacity to 1 MiB and performs that cap attempt before returning
the lookup error. The synthetic retry test verifies capacities `700000` then
`1048576` before the expected `ERANGE` failure.

Focused test command remained the one above. Result: `TEST SUCCEEDED`; 17
tests passed. Source/test commit: `d3e389a fix: validate POSIX WhatsApp home
lookup`.
