# WhatsApp-to-Signal Sticker Bridge iOS Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build an App-Store-safe iOS app that batch-imports sticker assets the user explicitly provides, converts them on-device into Signal-compatible files, and exports one archive for bulk use with Signal's official Desktop Sticker Pack Creator.

**Architecture:** A SwiftUI app and share extension copy user-selected files into an App Group inbox, parse either WhatsApp's published `sticker_packs.wasticker` schema or a generic image collection, and normalize static/animated stickers locally. The app exports a ZIP containing Signal-ready WebP/APNG files, an emoji manifest, and exact Desktop instructions; it does not read either app's private container, handle Signal credentials, or call undocumented Signal services.

**Tech Stack:** Swift 6, SwiftUI, UIKit share extension, iOS 17+, XCTest, ImageIO, UniformTypeIdentifiers, SDWebImage 5.21.7, SDWebImageWebPCoder 0.15.0, ZIPFoundation 0.9.20, XcodeGen 2.46.0.

## Global Constraints

- Minimum deployment target: iOS 17.0.
- Product bundle ID: `com.megabyte0x.stickerbridge`.
- Shared App Group: `group.com.megabyte0x.stickerbridge`.
- All sticker media processing stays on-device; v1 has no backend, analytics SDK, account system, or network request.
- The app only consumes files explicitly selected in Files or supplied through an iOS share extension.
- The app must never attempt to inspect `WhatsApp.app` or `Signal.app` containers, backups, databases, pasteboards owned by another process, or private URL schemes.
- Do not collect, request, derive, store, or proxy Signal account credentials.
- Static Signal output is WebP; animated Signal output is APNG.
- Every Signal output sticker is at most 300 KiB.
- Animated output is at most 3 seconds and loops indefinitely.
- Every sticker has exactly one emoji; when source metadata has none, default to `🙂` and let the user change it.
- Every exported pack contains 1 through 200 stickers, a title, an author, and a cover chosen from the pack.
- Imported content is copied into app-owned storage before the external security scope or share-extension callback ends.
- Exported packs are treated as immutable because Signal cannot edit or delete an uploaded custom pack.
- User-facing copy must say “Prepare for Signal” or “Export for Signal Desktop,” never “Import directly to Signal.”
- Direct on-phone Signal installation is blocked unless Signal publishes a supported upload API or gives written integration approval; that future work requires a separate plan.
- Users must confirm that they own or have permission to transfer the sticker art before export.

---

## Research Result and Product Boundary

### What is possible

1. iOS can import a user-selected directory or multiple files through `UIDocumentPickerViewController`/SwiftUI `fileImporter`, receiving security-scoped access.
2. A share extension can consume image or archive representations that a host app actually exposes through `NSItemProvider`.
3. WhatsApp publishes its third-party pack schema and sticker requirements. A folder or ZIP containing `sticker_packs.wasticker` plus its referenced assets can be parsed deterministically.
4. WhatsApp static PNG/WebP can be normalized to Signal static WebP. WhatsApp animated WebP can be decoded, trimmed to Signal's 3-second limit, and re-encoded as APNG.
5. Signal Desktop can bulk-select up to 200 prepared files in its official creator.
6. Once a pack has been uploaded by a supported Signal client, `https://signal.art/addstickers/#pack_id=…&pack_key=…` opens the install preview in Signal iOS.

### What is not available through supported APIs

1. A third-party iOS app cannot enumerate WhatsApp's installed/favorite sticker library. iOS app containers are private, and App Groups only share data among apps from the same development team.
2. WhatsApp's published iOS integration sends packs *into* WhatsApp using pasteboard plus `whatsapp://stickerPack`; it does not export or list packs. The documented path sends one pack at a time.
3. Signal does not publish a third-party iOS sticker-upload API. Its support documentation requires a registered phone and a linked Signal Desktop client.
4. Signal Desktop's source requests an authenticated `GET v1/sticker/pack/form/{count}` before CDN upload. A shared backend Signal account, credential extraction, or a minimally reimplemented linked client would be an undocumented service use and is excluded.
5. Signal iOS's public pack link only previews/installs an already-uploaded pack and still requires user confirmation.

### Product decision

The supported v1 is a **batch converter and Signal Desktop handoff**, not a literal WhatsApp-library-to-Signal importer. If “one go on the phone” is a hard launch requirement, stop after Task 1 and seek written API/integration approval from both WhatsApp and Signal before engineering the product.

### Primary sources

- [Signal sticker requirements and linked-Desktop requirement](https://support.signal.org/hc/en-us/articles/360031836512-Stickers)
- [Signal privacy design for pack IDs and keys](https://signal.org/blog/make-privacy-stick/)
- [Signal iOS pack-link parser at commit `2f10907`](https://github.com/signalapp/Signal-iOS/blob/2f109075a7a3471686fbd4308991746fec7677a5/SignalServiceKit/Messages/Stickers/StickerPackInfo.swift)
- [Signal Desktop upload request at commit `286ac81`](https://github.com/signalapp/Signal-Desktop/blob/286ac81b7d07005757124eebad2cea3d7e26224a/ts/textsecure/WebAPI.preload.ts#L4124)
- [Signal Terms covering unauthorized and automated service access](https://signal.org/legal/)
- [WhatsApp's official iOS sticker README at commit `06144a1`](https://github.com/WhatsApp/stickers/blob/06144a1f6077bbb346e1230032fc4e0bce996d03/iOS/README.md)
- [WhatsApp's published `sticker_packs.wasticker` example](https://github.com/WhatsApp/stickers/blob/06144a1f6077bbb346e1230032fc4e0bce996d03/iOS/WAStickersThirdParty/sticker_packs.wasticker)
- [Apple: apps have private sandboxes; App Groups are for related apps](https://developer.apple.com/documentation/technologyoverviews/shared-data)
- [Apple: user-selected directory access](https://developer.apple.com/documentation/uikit/providing-access-to-directories)
- [Apple: share-extension item transfer through `NSItemProvider`](https://developer.apple.com/documentation/foundation/nsitemprovider)

## User Flow

1. Launch StickerBridge and tap **Import sticker files**.
2. Select one of:
   - a folder containing `sticker_packs.wasticker` and its assets;
   - a ZIP with that same structure;
   - a folder/ZIP of PNG, WebP, or APNG files;
   - multiple PNG, WebP, or APNG files;
   - a compatible image/archive shared by another app.
3. If a manifest contains multiple packs, choose the pack to prepare.
4. Review title, author, cover, order, and one emoji per sticker.
5. Tap **Prepare for Signal**. The app batch-converts every sticker locally and reports exact per-file failures.
6. Confirm rights to the art and export one ZIP to Files, AirDrop, or another user-selected destination.
7. On a linked computer, unzip the archive, open Signal Desktop → File → Create/Upload Sticker Pack, select all numbered sticker files once, and use `emoji-manifest.html` while assigning emoji.
8. Complete Signal's upload and install confirmation.

## File Structure

```text
project.yml
StickerBridge/
  App/
    StickerBridgeApp.swift
    BridgeAppModel.swift
  Domain/
    StickerModels.swift
    SignalStickerRules.swift
  Import/
    ImportSource.swift
    SourceStager.swift
    SafeArchiveExtractor.swift
    WhatsAppManifest.swift
    StickerImportService.swift
  Processing/
    StickerTranscoding.swift
    ImageCanvas.swift
    StaticStickerTranscoder.swift
    AnimatedStickerTranscoder.swift
    PackPreparationService.swift
  Persistence/
    DraftStore.swift
  Export/
    SignalDesktopExporter.swift
  Features/
    ImportView.swift
    PackEditorView.swift
    ConversionView.swift
    ExportView.swift
  Resources/
    PrivacyInfo.xcprivacy
Shared/
  SharedModuleMarker.swift
  ShareBatchManifest.swift
  ShareInbox.swift
StickerBridgeShare/
  ShareViewController.swift
  Info.plist
StickerBridgeTests/
  Domain/
  Import/
  Processing/
  Persistence/
  Export/
StickerBridgeUITests/
  StickerBridgeUITests.swift
scripts/
  verify_supported_integrations.sh
docs/
  decisions/
    0001-supported-product-boundary.md
  app-store/
    privacy-and-review-notes.md
```

---

### Task 1: Lock the supported product contract and scaffold the project

**Files:**
- Create: `docs/decisions/0001-supported-product-boundary.md`
- Create: `project.yml`
- Create: `StickerBridge/App/StickerBridgeApp.swift`
- Create: `StickerBridge/Domain/StickerModels.swift`
- Create: `StickerBridge/Domain/SignalStickerRules.swift`
- Create: `StickerBridge/Features/ImportView.swift`
- Create: `StickerBridge/Info.plist`
- Create: `StickerBridge/StickerBridge.entitlements`
- Create: `Shared/SharedModuleMarker.swift`
- Create: `StickerBridgeTests/Domain/SignalStickerRulesTests.swift`
- Create: `StickerBridgeUITests/StickerBridgeUITests.swift`

**Interfaces:**
- Consumes: None.
- Produces: `StickerKind`, `SourceSticker`, `StickerPackDraft`, `PreparedSticker`, `PreparedPack`, and `SignalStickerRules`.

- [ ] **Step 1: Record the hard product boundary**

Create `docs/decisions/0001-supported-product-boundary.md`:

```markdown
# ADR 0001: Supported product boundary

## Status

Accepted.

## Decision

StickerBridge imports only files the user explicitly provides through Files or
the iOS share sheet. It does not enumerate WhatsApp's private sticker library.

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
```

Run:

```bash
rg -n "does not enumerate|does not upload|new ADR" docs/decisions/0001-supported-product-boundary.md
```

Expected: three matching lines and no ambiguous direct-import promise.

- [ ] **Step 2: Define the reproducible XcodeGen project**

Create `project.yml`:

```yaml
name: StickerBridge
options:
  bundleIdPrefix: com.megabyte0x
  deploymentTarget:
    iOS: "17.0"
  xcodeVersion: "16.0"
settings:
  base:
    SWIFT_VERSION: "6.0"
    SWIFT_STRICT_CONCURRENCY: complete
    IPHONEOS_DEPLOYMENT_TARGET: "17.0"
packages:
  SDWebImage:
    url: https://github.com/SDWebImage/SDWebImage.git
    exactVersion: 5.21.7
  SDWebImageWebPCoder:
    url: https://github.com/SDWebImage/SDWebImageWebPCoder.git
    exactVersion: 0.15.0
  ZIPFoundation:
    url: https://github.com/weichsel/ZIPFoundation.git
    exactVersion: 0.9.20
targets:
  StickerBridge:
    type: application
    platform: iOS
    sources:
      - StickerBridge
      - Shared
    info:
      path: StickerBridge/Info.plist
    entitlements:
      path: StickerBridge/StickerBridge.entitlements
    dependencies:
      - package: SDWebImage
      - package: SDWebImageWebPCoder
      - package: ZIPFoundation
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: com.megabyte0x.stickerbridge
        PRODUCT_NAME: StickerBridge
        CURRENT_PROJECT_VERSION: 1
        MARKETING_VERSION: 1.0.0
  StickerBridgeTests:
    type: bundle.unit-test
    platform: iOS
    sources:
      - StickerBridgeTests
    dependencies:
      - target: StickerBridge
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: com.megabyte0x.stickerbridge.tests
  StickerBridgeUITests:
    type: bundle.ui-testing
    platform: iOS
    sources:
      - StickerBridgeUITests
    dependencies:
      - target: StickerBridge
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: com.megabyte0x.stickerbridge.uitests
schemes:
  StickerBridge:
    build:
      targets:
        StickerBridge: all
        StickerBridgeTests: [test]
        StickerBridgeUITests: [test]
    test:
      gatherCoverageData: true
      targets:
        - StickerBridgeTests
        - StickerBridgeUITests
```

Verify the pinned generator before generating:

```bash
if ! command -v xcodegen >/dev/null 2>&1; then
  brew install xcodegen
fi
xcodegen --version | rg -x '(Version: )?2\.46\.0'
```

Expected: exactly one version line matching XcodeGen 2.46.0.

Create `StickerBridge/Info.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDisplayName</key>
  <string>StickerBridge</string>
  <key>CFBundleExecutable</key>
  <string>$(EXECUTABLE_NAME)</string>
  <key>CFBundleIdentifier</key>
  <string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
  <key>CFBundleInfoDictionaryVersion</key>
  <string>6.0</string>
  <key>CFBundleName</key>
  <string>$(PRODUCT_NAME)</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>$(MARKETING_VERSION)</string>
  <key>CFBundleVersion</key>
  <string>$(CURRENT_PROJECT_VERSION)</string>
  <key>CFBundleURLTypes</key>
  <array>
    <dict>
      <key>CFBundleURLName</key>
      <string>com.megabyte0x.stickerbridge</string>
      <key>CFBundleURLSchemes</key>
      <array><string>stickerbridge</string></array>
    </dict>
  </array>
  <key>UILaunchScreen</key>
  <dict/>
</dict>
</plist>
```

Create `StickerBridge/StickerBridge.entitlements`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>com.apple.security.application-groups</key>
  <array>
    <string>group.com.megabyte0x.stickerbridge</string>
  </array>
</dict>
</plist>
```

- [ ] **Step 3: Write the failing domain-rule tests**

Create `StickerBridgeTests/Domain/SignalStickerRulesTests.swift`:

```swift
import XCTest
@testable import StickerBridge

final class SignalStickerRulesTests: XCTestCase {
    func testAcceptsBoundaryPackCounts() {
        XCTAssertNoThrow(try SignalStickerRules.validatePackCount(1))
        XCTAssertNoThrow(try SignalStickerRules.validatePackCount(200))
    }

    func testRejectsOutOfRangePackCounts() {
        XCTAssertThrowsError(try SignalStickerRules.validatePackCount(0))
        XCTAssertThrowsError(try SignalStickerRules.validatePackCount(201))
    }

    func testRejectsOversizedSticker() {
        XCTAssertNoThrow(try SignalStickerRules.validateByteCount(300 * 1024))
        XCTAssertThrowsError(try SignalStickerRules.validateByteCount(300 * 1024 + 1))
    }

    func testUsesFirstSourceEmojiOrDefault() {
        XCTAssertEqual(SignalStickerRules.preferredEmoji(from: ["", "😂", "🙂"]), "😂")
        XCTAssertEqual(SignalStickerRules.preferredEmoji(from: []), "🙂")
    }

    func testRequiresExactlyOneEmojiGrapheme() {
        XCTAssertNoThrow(try SignalStickerRules.validateEmoji("👨‍👩‍👧‍👦"))
        XCTAssertNoThrow(try SignalStickerRules.validateEmoji("1️⃣"))
        XCTAssertThrowsError(try SignalStickerRules.validateEmoji(""))
        XCTAssertThrowsError(try SignalStickerRules.validateEmoji("hello"))
        XCTAssertThrowsError(try SignalStickerRules.validateEmoji("🙂😂"))
    }
}
```

- [ ] **Step 4: Run the tests to verify they fail**

Run:

```bash
xcodegen generate
xcodebuild -project StickerBridge.xcodeproj -scheme StickerBridge \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:StickerBridgeTests/SignalStickerRulesTests test
```

Expected: build fails because `SignalStickerRules` is undefined.

- [ ] **Step 5: Add domain models and exact Signal limits**

Create `StickerBridge/Domain/StickerModels.swift`:

```swift
import Foundation

enum StickerKind: String, Codable, Sendable {
    case staticImage
    case animated
}

struct SourceSticker: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    var relativePath: String
    var emoji: String
    var accessibilityText: String?
    var kind: StickerKind
}

struct StickerPackDraft: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    var title: String
    var author: String
    var coverStickerID: UUID
    var stickers: [SourceSticker]
    let createdAt: Date
}

struct PreparedSticker: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    let relativePath: String
    let emoji: String
    let kind: StickerKind
    let byteCount: Int
}

struct PreparedPack: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    let title: String
    let author: String
    let coverStickerID: UUID
    let stickers: [PreparedSticker]
}
```

Create `StickerBridge/Domain/SignalStickerRules.swift`:

```swift
import Foundation

enum SignalStickerRuleError: LocalizedError, Equatable {
    case invalidPackCount(Int)
    case oversizedSticker(Int)
    case animationTooLong(TimeInterval)
    case missingTitle
    case missingAuthor
    case invalidEmoji(String)

    var errorDescription: String? {
        switch self {
        case .invalidPackCount(let count):
            "Signal packs must contain 1–200 stickers; this pack has \(count)."
        case .oversizedSticker(let bytes):
            "Signal stickers must be at most 300 KiB; this file is \(bytes) bytes."
        case .animationTooLong(let duration):
            "Signal animations must be at most 3 seconds; this file is \(duration) seconds."
        case .missingTitle:
            "Enter a pack title."
        case .missingAuthor:
            "Enter an author."
        case .invalidEmoji(let value):
            "Choose exactly one emoji; “\(value)” is not valid."
        }
    }
}

enum SignalStickerRules {
    static let canvasSide = 512
    static let recommendedMargin = 16
    static let maximumStickerBytes = 300 * 1024
    static let maximumAnimationDuration: TimeInterval = 3
    static let maximumStickerCount = 200

    static func validatePackCount(_ count: Int) throws {
        guard (1...maximumStickerCount).contains(count) else {
            throw SignalStickerRuleError.invalidPackCount(count)
        }
    }

    static func validateByteCount(_ count: Int) throws {
        guard count <= maximumStickerBytes else {
            throw SignalStickerRuleError.oversizedSticker(count)
        }
    }

    static func preferredEmoji(from values: [String]) -> String {
        values.first(where: { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) ?? "🙂"
    }

    static func validateMetadata(title: String, author: String) throws {
        if title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            throw SignalStickerRuleError.missingTitle
        }
        if author.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            throw SignalStickerRuleError.missingAuthor
        }
    }

    static func validateEmoji(_ value: String) throws {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        let characters = Array(trimmed)
        guard characters.count == 1,
              characters[0].unicodeScalars.contains(where: {
                  $0.properties.isEmojiPresentation || $0.properties.generalCategory == .otherSymbol
              })
        else {
            throw SignalStickerRuleError.invalidEmoji(value)
        }
    }
}
```

Create `StickerBridge/App/StickerBridgeApp.swift`:

```swift
import SwiftUI

@main
struct StickerBridgeApp: App {
    var body: some Scene {
        WindowGroup {
            ImportView()
        }
    }
}
```

Create the first functional `StickerBridge/Features/ImportView.swift`:

```swift
import SwiftUI

struct ImportView: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("Prepare sticker files for Signal")
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)
            Text("StickerBridge cannot read WhatsApp’s private library. Choose or share files you have permission to use.")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Import sticker files") {}
                .buttonStyle(.borderedProminent)
                .disabled(true)
        }
        .padding()
    }
}
```

Create `Shared/SharedModuleMarker.swift` so the shared source root exists from the first generated project:

```swift
enum SharedModuleMarker {}
```

Create `StickerBridgeUITests/StickerBridgeUITests.swift`:

```swift
import XCTest

final class StickerBridgeUITests: XCTestCase {
    func testAppLaunches() {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(
            app.staticTexts["Prepare sticker files for Signal"].waitForExistence(timeout: 5)
        )
    }
}
```

- [ ] **Step 6: Run the domain tests**

Run the Step 4 command again.

Expected: `SignalStickerRulesTests` passes.

- [ ] **Step 7: Commit the contract and scaffold**

```bash
if [ ! -d .git ]; then
  git init
  git branch -M main
fi
git add project.yml StickerBridge Shared StickerBridgeTests docs/decisions
git commit -m "chore: scaffold supported StickerBridge iOS app"
```

---

### Task 2: Stage user-selected sources and parse WhatsApp-compatible packs

**Files:**
- Create: `StickerBridge/Import/ImportSource.swift`
- Create: `StickerBridge/Import/SourceStager.swift`
- Create: `StickerBridge/Import/SafeArchiveExtractor.swift`
- Create: `StickerBridge/Import/WhatsAppManifest.swift`
- Create: `StickerBridge/Import/StickerImportService.swift`
- Create: `StickerBridgeTests/Import/StickerImportServiceTests.swift`

**Interfaces:**
- Consumes: `StickerKind`, `SourceSticker`, `StickerPackDraft`, `SignalStickerRules`.
- Produces: `StagedImport`, `WhatsAppManifest`, and `StickerImportService.importFiles(_:defaultAuthor:) async throws -> [StickerPackDraft]`.

- [ ] **Step 1: Write manifest and path-safety tests**

Create `StickerBridgeTests/Import/StickerImportServiceTests.swift`:

```swift
import XCTest
@testable import StickerBridge

final class StickerImportServiceTests: XCTestCase {
    private var root: URL!

    override func setUpWithError() throws {
        root = FileManager.default.temporaryDirectory
            .appending(path: UUID().uuidString, directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: root)
    }

    func testDecodesWhatsAppManifestAndPreservesFirstEmoji() throws {
        let data = """
        {
          "sticker_packs": [{
            "identifier": "pack-1",
            "name": "Friends",
            "publisher": "Asha",
            "tray_image_file": "tray.png",
            "stickers": [{
              "image_file": "hello.webp",
              "emojis": ["👋", "🙂"],
              "accessibility_text": "A waving hand."
            }]
          }]
        }
        """.data(using: .utf8)!

        let manifest = try JSONDecoder().decode(WhatsAppManifest.self, from: data)
        XCTAssertEqual(manifest.stickerPacks[0].name, "Friends")
        XCTAssertEqual(manifest.stickerPacks[0].stickers[0].emojis[0], "👋")
    }

    func testRejectsArchiveTraversalPath() {
        XCTAssertThrowsError(try SafeRelativePath("../private/secret.webp"))
        XCTAssertThrowsError(try SafeRelativePath("/absolute/sticker.webp"))
        XCTAssertNoThrow(try SafeRelativePath("pack/sticker.webp"))
    }

    func testImportsGenericImagesAsOneDraft() async throws {
        let first = root.appending(path: "one.png")
        let second = root.appending(path: "two.webp")
        try Data([0x89, 0x50, 0x4E, 0x47]).write(to: first)
        try Data("RIFF".utf8).write(to: second)

        let service = StickerImportService(
            workspaceRoot: root.appending(path: "workspace", directoryHint: .isDirectory)
        )
        let drafts = try await service.importFiles([first, second], defaultAuthor: "Me")

        XCTAssertEqual(drafts.count, 1)
        XCTAssertEqual(drafts[0].stickers.count, 2)
        XCTAssertEqual(drafts[0].author, "Me")
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run:

```bash
xcodebuild -project StickerBridge.xcodeproj -scheme StickerBridge \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:StickerBridgeTests/StickerImportServiceTests test
```

Expected: build fails because the importer types are undefined.

- [ ] **Step 3: Add exact WhatsApp manifest models and safe relative paths**

Create `StickerBridge/Import/WhatsAppManifest.swift`:

```swift
import Foundation

struct WhatsAppManifest: Codable, Sendable {
    let stickerPacks: [WhatsAppPack]

    enum CodingKeys: String, CodingKey {
        case stickerPacks = "sticker_packs"
    }
}

struct WhatsAppPack: Codable, Sendable {
    let identifier: String
    let name: String
    let publisher: String
    let trayImageFile: String
    let animatedStickerPack: Bool?
    let stickers: [WhatsAppSticker]

    enum CodingKeys: String, CodingKey {
        case identifier, name, publisher, stickers
        case trayImageFile = "tray_image_file"
        case animatedStickerPack = "animated_sticker_pack"
    }
}

struct WhatsAppSticker: Codable, Sendable {
    let imageFile: String
    let emojis: [String]
    let accessibilityText: String?

    enum CodingKeys: String, CodingKey {
        case imageFile = "image_file"
        case emojis
        case accessibilityText = "accessibility_text"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        imageFile = try container.decode(String.self, forKey: .imageFile)
        emojis = try container.decodeIfPresent([String].self, forKey: .emojis) ?? []
        accessibilityText = try container.decodeIfPresent(
            String.self,
            forKey: .accessibilityText
        )
    }
}

struct SafeRelativePath: Hashable, Sendable {
    let value: String

    init(_ value: String) throws {
        let normalized = value.replacingOccurrences(of: "\\", with: "/")
        let components = normalized.split(separator: "/", omittingEmptySubsequences: false)
        guard !normalized.hasPrefix("/"),
              !components.contains(".."),
              !components.contains("."),
              !components.contains("")
        else {
            throw ImportFailure.unsafePath(value)
        }
        self.value = normalized
    }
}
```

Create `StickerBridge/Import/ImportSource.swift`:

```swift
import Foundation
import UniformTypeIdentifiers

enum ImportFailure: LocalizedError, Equatable {
    case noSupportedFiles
    case unsafePath(String)
    case missingReferencedFile(String)
    case malformedManifest
    case archiveExtractionFailed(String)

    var errorDescription: String? {
        switch self {
        case .noSupportedFiles:
            "No PNG, WebP, APNG, ZIP, or WhatsApp-compatible manifest was found."
        case .unsafePath(let path):
            "The import contains an unsafe path: \(path)"
        case .missingReferencedFile(let path):
            "The WhatsApp manifest references a missing file: \(path)"
        case .malformedManifest:
            "The WhatsApp sticker manifest is not valid JSON."
        case .archiveExtractionFailed(let message):
            "The archive could not be extracted: \(message)"
        }
    }
}

struct StagedImport: Sendable {
    let root: URL
    let files: [URL]
}

extension URL {
    var supportedStickerKind: StickerKind? {
        switch pathExtension.lowercased() {
        case "png", "apng":
            return pathExtension.lowercased() == "apng" ? .animated : .staticImage
        case "webp":
            return nil
        default:
            return nil
        }
    }
}
```

- [ ] **Step 4: Implement user-scoped staging and safe ZIP extraction**

Create `StickerBridge/Import/SourceStager.swift`:

```swift
import Foundation

struct SourceStager: Sendable {
    let workspaceRoot: URL
    private let fileManager = FileManager.default

    func stage(_ urls: [URL], importID: UUID) throws -> StagedImport {
        let destination = workspaceRoot
            .appending(path: importID.uuidString, directoryHint: .isDirectory)
            .appending(path: "input", directoryHint: .isDirectory)
        try fileManager.createDirectory(at: destination, withIntermediateDirectories: true)

        var staged: [URL] = []
        for source in urls {
            let accessed = source.startAccessingSecurityScopedResource()
            defer {
                if accessed { source.stopAccessingSecurityScopedResource() }
            }

            var isDirectory: ObjCBool = false
            guard fileManager.fileExists(atPath: source.path, isDirectory: &isDirectory) else {
                continue
            }

            let target = destination.appending(path: source.lastPathComponent)
            if isDirectory.boolValue {
                try copyDirectoryContents(from: source, to: target)
                staged.append(target)
            } else {
                if fileManager.fileExists(atPath: target.path) {
                    try fileManager.removeItem(at: target)
                }
                try fileManager.copyItem(at: source, to: target)
                staged.append(target)
            }
        }
        return StagedImport(root: destination, files: staged)
    }

    private func copyDirectoryContents(from source: URL, to destination: URL) throws {
        try fileManager.createDirectory(at: destination, withIntermediateDirectories: true)
        let keys: [URLResourceKey] = [.isDirectoryKey, .isSymbolicLinkKey]
        guard let enumerator = fileManager.enumerator(
            at: source,
            includingPropertiesForKeys: keys,
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) else { return }

        for case let item as URL in enumerator {
            let values = try item.resourceValues(forKeys: Set(keys))
            guard values.isSymbolicLink != true else { continue }
            let relative = item.path.replacingOccurrences(of: source.path + "/", with: "")
            _ = try SafeRelativePath(relative)
            let target = destination.appending(path: relative)
            if values.isDirectory == true {
                try fileManager.createDirectory(at: target, withIntermediateDirectories: true)
            } else {
                try fileManager.createDirectory(
                    at: target.deletingLastPathComponent(),
                    withIntermediateDirectories: true
                )
                try fileManager.copyItem(at: item, to: target)
            }
        }
    }
}
```

Create `StickerBridge/Import/SafeArchiveExtractor.swift`:

```swift
import Foundation
import ZIPFoundation

struct SafeArchiveExtractor: Sendable {
    func extract(_ archiveURL: URL, to destination: URL) throws -> URL {
        try FileManager.default.createDirectory(at: destination, withIntermediateDirectories: true)
        guard let archive = Archive(url: archiveURL, accessMode: .read) else {
            throw ImportFailure.archiveExtractionFailed("The ZIP header is invalid.")
        }

        do {
            for entry in archive {
                let safe = try SafeRelativePath(entry.path)
                let output = destination.appending(path: safe.value)
                guard output.standardizedFileURL.path.hasPrefix(destination.standardizedFileURL.path + "/") else {
                    throw ImportFailure.unsafePath(entry.path)
                }
                try FileManager.default.createDirectory(
                    at: output.deletingLastPathComponent(),
                    withIntermediateDirectories: true
                )
                _ = try archive.extract(entry, to: output)
            }
            return destination
        } catch let error as ImportFailure {
            throw error
        } catch {
            throw ImportFailure.archiveExtractionFailed(error.localizedDescription)
        }
    }
}
```

- [ ] **Step 5: Implement manifest and generic-image import**

Create `StickerBridge/Import/StickerImportService.swift`:

```swift
import Foundation
import ImageIO

struct StickerImportService: Sendable {
    let workspaceRoot: URL

    func importFiles(_ urls: [URL], defaultAuthor: String) async throws -> [StickerPackDraft] {
        let importID = UUID()
        let staged = try SourceStager(workspaceRoot: workspaceRoot).stage(urls, importID: importID)
        let expandedRoots = try expandArchives(in: staged)
        let allFiles = expandedRoots.flatMap(recursiveFiles)

        if let manifestURL = allFiles.first(where: { $0.lastPathComponent == "sticker_packs.wasticker" }) {
            return try drafts(from: manifestURL, allFiles: allFiles)
        }

        let images = allFiles.filter(isSupportedImage)
        guard !images.isEmpty else { throw ImportFailure.noSupportedFiles }
        let draftID = importID
        let stickers = images.sorted(by: { $0.lastPathComponent < $1.lastPathComponent }).map { url in
            SourceSticker(
                id: UUID(),
                relativePath: relativePath(for: url, beneath: workspaceRoot),
                emoji: "🙂",
                accessibilityText: nil,
                kind: detectKind(at: url)
            )
        }
        try SignalStickerRules.validatePackCount(stickers.count)
        return [
            StickerPackDraft(
                id: draftID,
                title: "Imported Stickers",
                author: defaultAuthor,
                coverStickerID: stickers[0].id,
                stickers: stickers,
                createdAt: .now
            )
        ]
    }

    private func expandArchives(in staged: StagedImport) throws -> [URL] {
        var roots: [URL] = []
        for url in staged.files {
            if url.pathExtension.lowercased() == "zip" {
                let destination = staged.root
                    .appending(path: "expanded-\(UUID().uuidString)", directoryHint: .isDirectory)
                roots.append(try SafeArchiveExtractor().extract(url, to: destination))
            } else {
                roots.append(url)
            }
        }
        return roots
    }

    private func drafts(from manifestURL: URL, allFiles: [URL]) throws -> [StickerPackDraft] {
        let data = try Data(contentsOf: manifestURL, options: [.mappedIfSafe])
        guard let manifest = try? JSONDecoder().decode(WhatsAppManifest.self, from: data) else {
            throw ImportFailure.malformedManifest
        }
        let root = manifestURL.deletingLastPathComponent()

        return try manifest.stickerPacks.map { pack in
            let draftID = UUID()
            let sources = try pack.stickers.map { sticker -> SourceSticker in
                let safe = try SafeRelativePath(sticker.imageFile)
                let file = root.appending(path: safe.value)
                guard FileManager.default.fileExists(atPath: file.path) else {
                    throw ImportFailure.missingReferencedFile(safe.value)
                }
                return SourceSticker(
                    id: UUID(),
                    relativePath: relativePath(for: file, beneath: workspaceRoot),
                    emoji: SignalStickerRules.preferredEmoji(from: sticker.emojis),
                    accessibilityText: sticker.accessibilityText,
                    kind: pack.animatedStickerPack == true ? .animated : detectKind(at: file)
                )
            }
            try SignalStickerRules.validatePackCount(sources.count)
            return StickerPackDraft(
                id: draftID,
                title: pack.name,
                author: pack.publisher,
                coverStickerID: sources[0].id,
                stickers: sources,
                createdAt: .now
            )
        }
    }

    private func recursiveFiles(at root: URL) -> [URL] {
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: root.path, isDirectory: &isDirectory) else { return [] }
        if !isDirectory.boolValue { return [root] }
        let enumerator = FileManager.default.enumerator(
            at: root,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        )
        return enumerator?.compactMap { $0 as? URL } ?? []
    }

    private func isSupportedImage(_ url: URL) -> Bool {
        ["png", "apng", "webp"].contains(url.pathExtension.lowercased())
    }

    private func detectKind(at url: URL) -> StickerKind {
        if url.pathExtension.lowercased() == "apng" { return .animated }
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { return .staticImage }
        return CGImageSourceGetCount(source) > 1 ? .animated : .staticImage
    }

    private func relativePath(for url: URL, beneath root: URL) -> String {
        url.standardizedFileURL.path.replacingOccurrences(
            of: root.standardizedFileURL.path + "/",
            with: ""
        )
    }
}
```

- [ ] **Step 6: Run importer tests**

Run the Step 2 command again.

Expected: all three importer tests pass.

- [ ] **Step 7: Commit the safe importer**

```bash
git add StickerBridge/Import StickerBridgeTests/Import
git commit -m "feat: import user-selected WhatsApp sticker sources"
```

---

### Task 3: Add a share-extension inbox without claiming WhatsApp bulk access

**Files:**
- Modify: `project.yml`
- Create: `Shared/ShareBatchManifest.swift`
- Create: `Shared/ShareInbox.swift`
- Create: `StickerBridgeShare/ShareViewController.swift`
- Create: `StickerBridgeShare/Info.plist`
- Create: `StickerBridgeShare/StickerBridgeShare.entitlements`
- Create: `StickerBridgeTests/Import/ShareInboxTests.swift`

**Interfaces:**
- Consumes: App Group `group.com.megabyte0x.stickerbridge`.
- Produces: `ShareBatchManifest`, `ShareInbox.writeBatch(files:)`, and `ShareInbox.completedBatches()`.

- [ ] **Step 1: Write the atomic-inbox test**

Create `StickerBridgeTests/Import/ShareInboxTests.swift`:

```swift
import XCTest
@testable import StickerBridge

final class ShareInboxTests: XCTestCase {
    func testOnlyCompleteBatchesAreVisible() throws {
        let root = FileManager.default.temporaryDirectory
            .appending(path: UUID().uuidString, directoryHint: .isDirectory)
        defer { try? FileManager.default.removeItem(at: root) }
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)

        let source = root.appending(path: "source.webp")
        try Data("RIFF-test".utf8).write(to: source)
        let inbox = ShareInbox(root: root.appending(path: "Inbox", directoryHint: .isDirectory))

        let batch = try inbox.writeBatch(files: [source])

        XCTAssertEqual(try inbox.completedBatches().map(\.id), [batch.id])
        XCTAssertTrue(FileManager.default.fileExists(
            atPath: inbox.url(for: batch).appending(path: "batch.json").path
        ))
    }
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run:

```bash
xcodebuild -project StickerBridge.xcodeproj -scheme StickerBridge \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:StickerBridgeTests/ShareInboxTests test
```

Expected: build fails because `ShareInbox` is undefined.

- [ ] **Step 3: Implement the atomic App Group inbox**

Create `Shared/ShareBatchManifest.swift`:

```swift
import Foundation

struct ShareBatchManifest: Codable, Equatable, Sendable, Identifiable {
    let id: UUID
    let createdAt: Date
    let filenames: [String]
}
```

Create `Shared/ShareInbox.swift`:

```swift
import Foundation

struct ShareInbox: Sendable {
    static let appGroup = "group.com.megabyte0x.stickerbridge"
    let root: URL

    static func live() throws -> ShareInbox {
        guard let container = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroup
        ) else {
            throw CocoaError(.fileNoSuchFile)
        }
        return ShareInbox(root: container.appending(path: "Inbox", directoryHint: .isDirectory))
    }

    func writeBatch(files: [URL]) throws -> ShareBatchManifest {
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let id = UUID()
        let temporary = root.appending(path: ".\(id.uuidString)", directoryHint: .isDirectory)
        let complete = root.appending(path: id.uuidString, directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: temporary, withIntermediateDirectories: true)

        var names: [String] = []
        for (index, source) in files.enumerated() {
            let extensionPart = source.pathExtension.lowercased()
            let filename = String(format: "%03d", index + 1)
                + (extensionPart.isEmpty ? "" : ".\(extensionPart)")
            let target = temporary.appending(path: filename)
            try FileManager.default.copyItem(at: source, to: target)
            names.append(filename)
        }

        let manifest = ShareBatchManifest(id: id, createdAt: .now, filenames: names)
        let encoded = try JSONEncoder().encode(manifest)
        try encoded.write(to: temporary.appending(path: "batch.json"), options: .atomic)
        try FileManager.default.moveItem(at: temporary, to: complete)
        return manifest
    }

    func completedBatches() throws -> [ShareBatchManifest] {
        guard FileManager.default.fileExists(atPath: root.path) else { return [] }
        return try FileManager.default.contentsOfDirectory(
            at: root,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        )
        .compactMap { directory in
            let dataURL = directory.appending(path: "batch.json")
            guard let data = try? Data(contentsOf: dataURL) else { return nil }
            return try? JSONDecoder().decode(ShareBatchManifest.self, from: data)
        }
        .sorted(by: { $0.createdAt < $1.createdAt })
    }

    func url(for batch: ShareBatchManifest) -> URL {
        root.appending(path: batch.id.uuidString, directoryHint: .isDirectory)
    }

    func remove(_ batch: ShareBatchManifest) throws {
        try FileManager.default.removeItem(at: url(for: batch))
    }
}
```

- [ ] **Step 4: Add the share-extension target**

Append this target under `targets:` in `project.yml`, and add it as an app dependency:

```yaml
  StickerBridgeShare:
    type: app-extension
    platform: iOS
    sources:
      - StickerBridgeShare
      - Shared
      - StickerBridge/Domain
      - StickerBridge/Import/ImportSource.swift
    info:
      path: StickerBridgeShare/Info.plist
    entitlements:
      path: StickerBridgeShare/StickerBridgeShare.entitlements
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: com.megabyte0x.stickerbridge.share
        PRODUCT_NAME: Prepare for Signal
```

Add under `StickerBridge.dependencies`:

```yaml
      - target: StickerBridgeShare
        embed: true
```

Create `StickerBridgeShare/StickerBridgeShare.entitlements` with the same App Group entitlement as the app.

Create `StickerBridgeShare/Info.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDisplayName</key>
  <string>Prepare for Signal</string>
  <key>CFBundleExecutable</key>
  <string>$(EXECUTABLE_NAME)</string>
  <key>CFBundleIdentifier</key>
  <string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
  <key>CFBundleInfoDictionaryVersion</key>
  <string>6.0</string>
  <key>CFBundlePackageType</key>
  <string>XPC!</string>
  <key>CFBundleShortVersionString</key>
  <string>$(MARKETING_VERSION)</string>
  <key>CFBundleVersion</key>
  <string>$(CURRENT_PROJECT_VERSION)</string>
  <key>NSExtension</key>
  <dict>
    <key>NSExtensionPointIdentifier</key>
    <string>com.apple.share-services</string>
    <key>NSExtensionPrincipalClass</key>
    <string>$(PRODUCT_MODULE_NAME).ShareViewController</string>
    <key>NSExtensionAttributes</key>
    <dict>
      <key>NSExtensionActivationRule</key>
      <dict>
        <key>NSExtensionActivationSupportsImageWithMaxCount</key>
        <integer>200</integer>
        <key>NSExtensionActivationSupportsFileWithMaxCount</key>
        <integer>200</integer>
      </dict>
    </dict>
  </dict>
</dict>
</plist>
```

- [ ] **Step 5: Implement the extension's bounded file copy**

Create `StickerBridgeShare/ShareViewController.swift`:

```swift
import UIKit
import UniformTypeIdentifiers

final class ShareViewController: UIViewController {
    private let statusLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        statusLabel.text = "Preparing shared sticker files…"
        statusLabel.textAlignment = .center
        statusLabel.numberOfLines = 0
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(statusLabel)
        NSLayoutConstraint.activate([
            statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            statusLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])

        Task { await importAttachments() }
    }

    private func importAttachments() async {
        do {
            let providers = extensionContext?.inputItems
                .compactMap { $0 as? NSExtensionItem }
                .flatMap(\.attachments) ?? []
            var files: [URL] = []
            for provider in providers.prefix(SignalStickerRules.maximumStickerCount) {
                if let file = try await Self.loadSupportedFile(from: provider) {
                    files.append(file)
                }
            }
            defer {
                for file in files {
                    try? FileManager.default.removeItem(at: file)
                }
            }
            guard !files.isEmpty else { throw ImportFailure.noSupportedFiles }
            _ = try ShareInbox.live().writeBatch(files: files)
            statusLabel.text = "Saved. Open StickerBridge to continue."
            try? await Task.sleep(for: .seconds(1))
            extensionContext?.completeRequest(returningItems: nil)
        } catch {
            statusLabel.text = error.localizedDescription
            extensionContext?.cancelRequest(withError: error)
        }
    }

    private static func loadSupportedFile(from provider: NSItemProvider) async throws -> URL? {
        let supported: [UTType] = [.webP, .png, .zip, .data]
        guard let type = supported.first(where: { provider.hasItemConformingToTypeIdentifier($0.identifier) }) else {
            return nil
        }
        return try await withCheckedThrowingContinuation { continuation in
            provider.loadFileRepresentation(for: type, openInPlace: false) { url, _, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let url {
                    do {
                        let durable = FileManager.default.temporaryDirectory
                            .appending(path: UUID().uuidString)
                            .appendingPathExtension(url.pathExtension)
                        try FileManager.default.copyItem(at: url, to: durable)
                        continuation.resume(returning: durable)
                    } catch {
                        continuation.resume(throwing: error)
                    }
                } else {
                    continuation.resume(returning: nil)
                }
            }
        }
    }
}
```

The copy inside the completion handler is mandatory because `loadFileRepresentation` removes its temporary URL when that handler returns. The `defer` then removes StickerBridge's durable temporary copy after the App Group inbox has accepted the batch.

- [ ] **Step 6: Regenerate and run the inbox test**

Run:

```bash
xcodegen generate
xcodebuild -project StickerBridge.xcodeproj -scheme StickerBridge \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:StickerBridgeTests/ShareInboxTests test
```

Expected: the test passes and both app and extension targets compile.

- [ ] **Step 7: Commit the share inbox**

```bash
git add project.yml Shared StickerBridgeShare StickerBridgeTests/Import
git commit -m "feat: receive explicitly shared sticker files"
```

---

### Task 4: Normalize static PNG/WebP stickers under Signal's size limit

**Files:**
- Create: `StickerBridge/Processing/StickerTranscoding.swift`
- Create: `StickerBridge/Processing/ImageCanvas.swift`
- Create: `StickerBridge/Processing/StaticStickerTranscoder.swift`
- Create: `StickerBridgeTests/Processing/StaticStickerTranscoderTests.swift`

**Interfaces:**
- Consumes: a staged input `URL`.
- Produces: `TranscodedStickerData` and `StaticStickerTranscoder.transcode(_:) async throws`.

- [ ] **Step 1: Write the static conversion test**

Create `StickerBridgeTests/Processing/StaticStickerTranscoderTests.swift`:

```swift
import XCTest
import UIKit
import SDWebImage
@testable import StickerBridge

final class StaticStickerTranscoderTests: XCTestCase {
    func testOutputs512WebPUnderSignalLimit() async throws {
        let input = FileManager.default.temporaryDirectory
            .appending(path: "\(UUID().uuidString).png")
        defer { try? FileManager.default.removeItem(at: input) }

        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 900, height: 450))
        let image = renderer.image { context in
            UIColor.clear.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 900, height: 450))
            UIColor.systemBlue.setFill()
            context.fill(CGRect(x: 50, y: 50, width: 800, height: 350))
        }
        try XCTUnwrap(image.pngData()).write(to: input)

        let output = try await StaticStickerTranscoder().transcode(input)
        let decoded = try XCTUnwrap(
            SDImageWebPCoder.shared.decodedImage(with: output.data, options: nil)
        )

        XCTAssertEqual(output.fileExtension, "webp")
        XCTAssertLessThanOrEqual(output.data.count, SignalStickerRules.maximumStickerBytes)
        XCTAssertEqual(decoded.size.width, 512, accuracy: 1)
        XCTAssertEqual(decoded.size.height, 512, accuracy: 1)
    }
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run:

```bash
xcodebuild -project StickerBridge.xcodeproj -scheme StickerBridge \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:StickerBridgeTests/StaticStickerTranscoderTests test
```

Expected: build fails because `StaticStickerTranscoder` is undefined.

- [ ] **Step 3: Define the transcoding contract and canvas renderer**

Create `StickerBridge/Processing/StickerTranscoding.swift`:

```swift
import Foundation

struct TranscodedStickerData: Sendable {
    let data: Data
    let fileExtension: String
    let kind: StickerKind
}

enum TranscodeFailure: LocalizedError, Equatable {
    case unreadableImage(String)
    case encodingFailed(String)
    case outputTooLarge(Int)
    case animationHasNoFrames

    var errorDescription: String? {
        switch self {
        case .unreadableImage(let name):
            "Could not decode \(name)."
        case .encodingFailed(let name):
            "Could not encode \(name) for Signal."
        case .outputTooLarge(let bytes):
            "The best output is \(bytes) bytes, above Signal's 300 KiB limit."
        case .animationHasNoFrames:
            "The animated sticker contains no decodable frames."
        }
    }
}

protocol StickerTranscoding: Sendable {
    func transcode(_ input: URL, kind: StickerKind) async throws -> TranscodedStickerData
}
```

Create `StickerBridge/Processing/ImageCanvas.swift`:

```swift
import UIKit

enum ImageCanvas {
    static func render(_ image: UIImage, side: Int = SignalStickerRules.canvasSide) -> UIImage {
        let size = CGSize(width: side, height: side)
        let margin = CGFloat(SignalStickerRules.recommendedMargin) * CGFloat(side) / 512
        let available = CGRect(
            x: margin,
            y: margin,
            width: CGFloat(side) - 2 * margin,
            height: CGFloat(side) - 2 * margin
        )
        let scale = min(
            available.width / max(image.size.width, 1),
            available.height / max(image.size.height, 1)
        )
        let drawSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let drawRect = CGRect(
            x: (CGFloat(side) - drawSize.width) / 2,
            y: (CGFloat(side) - drawSize.height) / 2,
            width: drawSize.width,
            height: drawSize.height
        )
        let format = UIGraphicsImageRendererFormat()
        format.opaque = false
        format.scale = 1
        return UIGraphicsImageRenderer(size: size, format: format).image { _ in
            image.draw(in: drawRect)
        }
    }
}
```

- [ ] **Step 4: Implement bounded static WebP encoding**

Create `StickerBridge/Processing/StaticStickerTranscoder.swift`:

```swift
import Foundation
import SDWebImage
import SDWebImageWebPCoder
import UIKit

struct StaticStickerTranscoder: Sendable {
    init() {
        SDImageCodersManager.shared.addCoder(SDImageWebPCoder.shared)
    }

    func transcode(_ input: URL) async throws -> TranscodedStickerData {
        let data = try Data(contentsOf: input, options: [.mappedIfSafe])
        let decoded = SDImageWebPCoder.shared.decodedImage(
            with: data,
            options: [.decodeFirstFrameOnly: true]
        ) ?? UIImage(data: data)
        guard let decoded else {
            throw TranscodeFailure.unreadableImage(input.lastPathComponent)
        }

        let rendered = ImageCanvas.render(decoded)
        let qualities: [Double] = [0.92, 0.82, 0.72, 0.60, 0.48]
        for quality in qualities {
            let options: [SDImageCoderOption: Any] = [
                .encodeCompressionQuality: quality,
                .encodeMaxFileSize: SignalStickerRules.maximumStickerBytes
            ]
            if let encoded = SDImageWebPCoder.shared.encodedData(
                with: rendered,
                format: .webP,
                options: options
            ), encoded.count <= SignalStickerRules.maximumStickerBytes {
                return TranscodedStickerData(
                    data: encoded,
                    fileExtension: "webp",
                    kind: .staticImage
                )
            }
        }
        throw TranscodeFailure.outputTooLarge(
            SDImageWebPCoder.shared.encodedData(
                with: rendered,
                format: .webP,
                options: [.encodeCompressionQuality: 0.40]
            )?.count ?? Int.max
        )
    }
}
```

- [ ] **Step 5: Run the static conversion test**

Run the Step 2 command again.

Expected: the test passes with a 512×512 WebP at or below 307,200 bytes.

- [ ] **Step 6: Commit the static transcoder**

```bash
git add StickerBridge/Processing StickerBridgeTests/Processing
git commit -m "feat: normalize static stickers for Signal"
```

---

### Task 5: Convert animated WhatsApp WebP into bounded Signal APNG

**Files:**
- Create: `StickerBridge/Processing/AnimatedStickerTranscoder.swift`
- Create: `StickerBridgeTests/Processing/AnimatedStickerTranscoderTests.swift`

**Interfaces:**
- Consumes: animated WebP/APNG input.
- Produces: `AnimatedStickerTranscoder.transcode(_:) async throws -> TranscodedStickerData`.

- [ ] **Step 1: Write an animated conversion test with generated frames**

Create `StickerBridgeTests/Processing/AnimatedStickerTranscoderTests.swift`:

```swift
import XCTest
import UIKit
import SDWebImage
import SDWebImageWebPCoder
@testable import StickerBridge

final class AnimatedStickerTranscoderTests: XCTestCase {
    func testTrimsAndEncodesAnimatedWebPAsAPNG() async throws {
        let colors: [UIColor] = [.red, .green, .blue, .yellow]
        let frames = colors.map { color -> SDImageFrame in
            let image = UIGraphicsImageRenderer(size: CGSize(width: 128, height: 128)).image { context in
                color.setFill()
                context.fill(CGRect(x: 16, y: 16, width: 96, height: 96))
            }
            return SDImageFrame(image: image, duration: 1.0)
        }
        let webP = try XCTUnwrap(
            SDImageWebPCoder.shared.encodedData(
                with: frames,
                loopCount: 0,
                format: .webP,
                options: [.encodeCompressionQuality: 0.8]
            )
        )
        let input = FileManager.default.temporaryDirectory
            .appending(path: "\(UUID().uuidString).webp")
        defer { try? FileManager.default.removeItem(at: input) }
        try webP.write(to: input)

        let output = try await AnimatedStickerTranscoder().transcode(input)
        let decoder = try XCTUnwrap(
            SDImageAPNGCoder(animatedImageData: output.data, options: nil)
        )
        let duration = (0..<decoder.animatedImageFrameCount)
            .reduce(0.0) { $0 + decoder.animatedImageDuration(at: $1) }

        XCTAssertEqual(output.fileExtension, "apng")
        XCTAssertGreaterThan(decoder.animatedImageFrameCount, 1)
        XCTAssertLessThanOrEqual(duration, 3.05)
        XCTAssertLessThanOrEqual(output.data.count, SignalStickerRules.maximumStickerBytes)
    }
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run:

```bash
xcodebuild -project StickerBridge.xcodeproj -scheme StickerBridge \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:StickerBridgeTests/AnimatedStickerTranscoderTests test
```

Expected: build fails because `AnimatedStickerTranscoder` is undefined.

- [ ] **Step 3: Implement deterministic trim, resample, resize, and APNG encoding**

Create `StickerBridge/Processing/AnimatedStickerTranscoder.swift`:

```swift
import Foundation
import SDWebImage
import SDWebImageWebPCoder
import UIKit

struct AnimatedStickerTranscoder: Sendable {
    private let targetFramesPerSecond = 30
    private let candidateSides = [512, 448, 384, 320, 256]

    func transcode(_ input: URL) async throws -> TranscodedStickerData {
        let data = try Data(contentsOf: input, options: [.mappedIfSafe])
        guard let decoder = SDImageWebPCoder(animatedImageData: data, options: nil)
                ?? SDImageAPNGCoder(animatedImageData: data, options: nil)
        else {
            throw TranscodeFailure.unreadableImage(input.lastPathComponent)
        }
        guard decoder.animatedImageFrameCount > 1 else {
            throw TranscodeFailure.animationHasNoFrames
        }

        let timeline = sourceTimeline(decoder)
        let duration = min(timeline.last?.end ?? 0, SignalStickerRules.maximumAnimationDuration)
        guard duration > 0 else { throw TranscodeFailure.animationHasNoFrames }

        for side in candidateSides {
            let frames = try sampledFrames(
                decoder: decoder,
                timeline: timeline,
                duration: duration,
                side: side
            )
            if let data = SDImageAPNGCoder.shared.encodedData(
                with: frames,
                loopCount: 0,
                format: .PNG,
                options: [.encodeCompressionQuality: 1.0]
            ), data.count <= SignalStickerRules.maximumStickerBytes {
                return TranscodedStickerData(data: data, fileExtension: "apng", kind: .animated)
            }
        }

        let smallest = try sampledFrames(
            decoder: decoder,
            timeline: timeline,
            duration: duration,
            side: candidateSides.last!
        )
        let bytes = SDImageAPNGCoder.shared.encodedData(
            with: smallest,
            loopCount: 0,
            format: .PNG,
            options: [.encodeCompressionQuality: 1.0]
        )?.count ?? Int.max
        throw TranscodeFailure.outputTooLarge(bytes)
    }

    private struct TimelineFrame {
        let index: Int
        let start: TimeInterval
        let end: TimeInterval
    }

    private func sourceTimeline(_ decoder: any SDAnimatedImageCoder) -> [TimelineFrame] {
        var cursor: TimeInterval = 0
        return (0..<decoder.animatedImageFrameCount).map { index in
            let raw = decoder.animatedImageDuration(at: index)
            let duration = max(raw, 1.0 / 60.0)
            defer { cursor += duration }
            return TimelineFrame(index: index, start: cursor, end: cursor + duration)
        }
    }

    private func sampledFrames(
        decoder: any SDAnimatedImageCoder,
        timeline: [TimelineFrame],
        duration: TimeInterval,
        side: Int
    ) throws -> [SDImageFrame] {
        let interval = 1.0 / Double(targetFramesPerSecond)
        let frameCount = max(2, Int(ceil(duration / interval)))
        return try (0..<frameCount).map { outputIndex in
            let time = min(Double(outputIndex) * interval, max(duration - 0.000_001, 0))
            let source = timeline.first(where: { time >= $0.start && time < $0.end })
                ?? timeline[timeline.count - 1]
            guard let image = decoder.animatedImageFrame(at: source.index) else {
                throw TranscodeFailure.animationHasNoFrames
            }
            return SDImageFrame(image: ImageCanvas.render(image, side: side), duration: interval)
        }
    }
}
```

- [ ] **Step 4: Run the animated test**

Run the Step 2 command again.

Expected: the generated four-second WebP becomes an APNG of no more than 3.05 seconds and 307,200 bytes.

- [ ] **Step 5: Add a device-memory regression command**

Run:

```bash
xcodebuild -project StickerBridge.xcodeproj -scheme StickerBridge \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:StickerBridgeTests/AnimatedStickerTranscoderTests \
  -enableAddressSanitizer YES test
```

Expected: pass with no Address Sanitizer issue. Keep processing sequential in Task 6 so a 200-sticker pack does not decode multiple animations at once.

- [ ] **Step 6: Commit animated conversion**

```bash
git add StickerBridge/Processing/AnimatedStickerTranscoder.swift \
  StickerBridgeTests/Processing/AnimatedStickerTranscoderTests.swift
git commit -m "feat: convert animated WebP stickers to Signal APNG"
```

---

### Task 6: Persist drafts and prepare packs with progress and per-file failures

**Files:**
- Create: `StickerBridge/Persistence/DraftStore.swift`
- Create: `StickerBridge/Processing/PackPreparationService.swift`
- Create: `StickerBridgeTests/Persistence/DraftStoreTests.swift`
- Create: `StickerBridgeTests/Processing/PackPreparationServiceTests.swift`

**Interfaces:**
- Consumes: `StickerPackDraft` and staged inputs under `workspaceRoot`.
- Produces: `DraftStore`, `PreparationEvent`, and `PackPreparationService.prepare(_:) -> AsyncThrowingStream<PreparationEvent, Error>`.

- [ ] **Step 1: Write persistence and ordering tests**

Create `StickerBridgeTests/Persistence/DraftStoreTests.swift`:

```swift
import XCTest
@testable import StickerBridge

final class DraftStoreTests: XCTestCase {
    func testRoundTripsDraft() async throws {
        let root = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let sticker = SourceSticker(
            id: UUID(),
            relativePath: "input/one.webp",
            emoji: "👋",
            accessibilityText: "Waving.",
            kind: .staticImage
        )
        let draft = StickerPackDraft(
            id: UUID(),
            title: "Hello",
            author: "Me",
            coverStickerID: sticker.id,
            stickers: [sticker],
            createdAt: .now
        )
        let store = DraftStore(root: root)

        try await store.save(draft)
        XCTAssertEqual(try await store.load(draft.id), draft)
    }
}
```

Create `StickerBridgeTests/Processing/PackPreparationServiceTests.swift`:

```swift
import XCTest
@testable import StickerBridge

final class PackPreparationServiceTests: XCTestCase {
    func testPreservesOrderAndReportsCompletion() async throws {
        let root = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)

        let first = SourceSticker(
            id: UUID(), relativePath: "one.png", emoji: "1️⃣",
            accessibilityText: nil, kind: .staticImage
        )
        let second = SourceSticker(
            id: UUID(), relativePath: "two.png", emoji: "2️⃣",
            accessibilityText: nil, kind: .staticImage
        )
        let draft = StickerPackDraft(
            id: UUID(), title: "Numbers", author: "Me",
            coverStickerID: first.id, stickers: [first, second], createdAt: .now
        )
        let transcoder = StubTranscoder()
        let service = PackPreparationService(workspaceRoot: root, transcoder: transcoder)

        var completed: PreparedPack?
        for try await event in service.prepare(draft) {
            if case .completed(let pack) = event { completed = pack }
        }

        XCTAssertEqual(completed?.stickers.map(\.id), [first.id, second.id])
    }

    func testFailureNamesTheSourceSticker() async throws {
        let root = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let source = SourceSticker(
            id: UUID(), relativePath: "broken.webp", emoji: "🙂",
            accessibilityText: nil, kind: .staticImage
        )
        let draft = StickerPackDraft(
            id: UUID(), title: "Broken", author: "Me",
            coverStickerID: source.id, stickers: [source], createdAt: .now
        )
        let service = PackPreparationService(
            workspaceRoot: root,
            transcoder: FailingTranscoder()
        )

        do {
            for try await _ in service.prepare(draft) {}
            XCTFail("Expected conversion to fail")
        } catch {
            XCTAssertTrue(error.localizedDescription.contains("broken.webp"))
        }
    }
}

private struct StubTranscoder: StickerTranscoding {
    func transcode(_ input: URL, kind: StickerKind) async throws -> TranscodedStickerData {
        TranscodedStickerData(data: Data("ok".utf8), fileExtension: "webp", kind: kind)
    }
}

private struct FailingTranscoder: StickerTranscoding {
    func transcode(_ input: URL, kind: StickerKind) async throws -> TranscodedStickerData {
        throw TranscodeFailure.unreadableImage(input.lastPathComponent)
    }
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run:

```bash
xcodebuild -project StickerBridge.xcodeproj -scheme StickerBridge \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:StickerBridgeTests/DraftStoreTests \
  -only-testing:StickerBridgeTests/PackPreparationServiceTests test
```

Expected: build fails because `DraftStore` and `PackPreparationService` are undefined.

- [ ] **Step 3: Implement atomic JSON draft persistence**

Create `StickerBridge/Persistence/DraftStore.swift`:

```swift
import Foundation

actor DraftStore {
    private let root: URL

    init(root: URL) {
        self.root = root
    }

    func save(_ draft: StickerPackDraft) throws {
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let data = try JSONEncoder().encode(draft)
        try data.write(to: url(for: draft.id), options: .atomic)
    }

    func load(_ id: UUID) throws -> StickerPackDraft {
        let data = try Data(contentsOf: url(for: id))
        return try JSONDecoder().decode(StickerPackDraft.self, from: data)
    }

    func list() throws -> [StickerPackDraft] {
        guard FileManager.default.fileExists(atPath: root.path) else { return [] }
        return try FileManager.default.contentsOfDirectory(
            at: root,
            includingPropertiesForKeys: nil
        )
        .filter { $0.pathExtension == "json" }
        .compactMap { try? JSONDecoder().decode(StickerPackDraft.self, from: Data(contentsOf: $0)) }
        .sorted(by: { $0.createdAt > $1.createdAt })
    }

    func remove(_ id: UUID) throws {
        try FileManager.default.removeItem(at: url(for: id))
    }

    private func url(for id: UUID) -> URL {
        root.appending(path: "\(id.uuidString).json")
    }
}
```

- [ ] **Step 4: Implement sequential preparation with typed progress**

Create `StickerBridge/Processing/PackPreparationService.swift`:

```swift
import Foundation

enum PreparationEvent: Sendable {
    case started(total: Int)
    case converted(index: Int, total: Int, stickerID: UUID)
    case completed(PreparedPack)
}

struct PackPreparationFailure: LocalizedError, Sendable {
    let sourcePath: String
    let causeDescription: String

    var errorDescription: String? {
        "Could not prepare \(URL(fileURLWithPath: sourcePath).lastPathComponent): \(causeDescription)"
    }
}

struct DefaultStickerTranscoder: StickerTranscoding {
    func transcode(_ input: URL, kind: StickerKind) async throws -> TranscodedStickerData {
        switch kind {
        case .staticImage:
            return try await StaticStickerTranscoder().transcode(input)
        case .animated:
            return try await AnimatedStickerTranscoder().transcode(input)
        }
    }
}

struct PackPreparationService<T: StickerTranscoding>: Sendable {
    let workspaceRoot: URL
    let transcoder: T

    init(workspaceRoot: URL, transcoder: T) {
        self.workspaceRoot = workspaceRoot
        self.transcoder = transcoder
    }

    func prepare(
        _ draft: StickerPackDraft
    ) -> AsyncThrowingStream<PreparationEvent, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    try SignalStickerRules.validateMetadata(title: draft.title, author: draft.author)
                    try SignalStickerRules.validatePackCount(draft.stickers.count)
                    for sticker in draft.stickers {
                        try SignalStickerRules.validateEmoji(sticker.emoji)
                    }
                    continuation.yield(.started(total: draft.stickers.count))

                    let outputDirectory = workspaceRoot
                        .appending(path: draft.id.uuidString, directoryHint: .isDirectory)
                        .appending(path: "prepared", directoryHint: .isDirectory)
                    try FileManager.default.createDirectory(
                        at: outputDirectory,
                        withIntermediateDirectories: true
                    )

                    var prepared: [PreparedSticker] = []
                    for (index, sticker) in draft.stickers.enumerated() {
                        try Task.checkCancellation()
                        let input = workspaceRoot.appending(path: sticker.relativePath)
                        let result: TranscodedStickerData
                        do {
                            result = try await transcoder.transcode(input, kind: sticker.kind)
                            try SignalStickerRules.validateByteCount(result.data.count)
                        } catch {
                            throw PackPreparationFailure(
                                sourcePath: sticker.relativePath,
                                causeDescription: error.localizedDescription
                            )
                        }
                        let filename = String(format: "%03d", index + 1) + ".\(result.fileExtension)"
                        let output = outputDirectory.appending(path: filename)
                        try result.data.write(to: output, options: .atomic)
                        prepared.append(
                            PreparedSticker(
                                id: sticker.id,
                                relativePath: output.path.replacingOccurrences(
                                    of: workspaceRoot.path + "/", with: ""
                                ),
                                emoji: sticker.emoji,
                                kind: result.kind,
                                byteCount: result.data.count
                            )
                        )
                        continuation.yield(
                            .converted(index: index + 1, total: draft.stickers.count, stickerID: sticker.id)
                        )
                    }

                    continuation.yield(
                        .completed(
                            PreparedPack(
                                id: draft.id,
                                title: draft.title,
                                author: draft.author,
                                coverStickerID: draft.coverStickerID,
                                stickers: prepared
                            )
                        )
                    )
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }
}
```

- [ ] **Step 5: Run persistence and preparation tests**

Run the Step 2 command again.

Expected: both tests pass.

- [ ] **Step 6: Commit persistence and preparation**

```bash
git add StickerBridge/Persistence StickerBridge/Processing/PackPreparationService.swift \
  StickerBridgeTests/Persistence StickerBridgeTests/Processing
git commit -m "feat: persist drafts and prepare sticker packs"
```

---

### Task 7: Build the truthful import, pack-editing, and conversion UI

**Files:**
- Modify: `StickerBridge/App/StickerBridgeApp.swift`
- Create: `StickerBridge/App/BridgeAppModel.swift`
- Modify: `StickerBridge/Features/ImportView.swift`
- Create: `StickerBridge/Features/PackEditorView.swift`
- Create: `StickerBridge/Features/ConversionView.swift`
- Modify: `StickerBridgeUITests/StickerBridgeUITests.swift`

**Interfaces:**
- Consumes: `StickerImportService`, `DraftStore`, `ShareInbox`, `PackPreparationService`.
- Produces: `BridgeAppModel` with `importURLs`, `consumeSharedInbox`, `saveDraft`, and `prepare`.

- [ ] **Step 1: Write the launch-copy UI test**

Replace `StickerBridgeUITests/StickerBridgeUITests.swift` with:

```swift
import XCTest

final class StickerBridgeUITests: XCTestCase {
    func testLaunchExplainsSupportedFlow() {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.staticTexts["Prepare sticker files for Signal"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Import sticker files"].exists)
        XCTAssertTrue(
            app.staticTexts[
                "StickerBridge cannot read WhatsApp’s private library. Choose or share files you have permission to use."
            ].exists
        )
    }
}
```

- [ ] **Step 2: Implement the observable app model**

Create `StickerBridge/App/BridgeAppModel.swift`:

```swift
import Foundation
import Observation

@MainActor
@Observable
final class BridgeAppModel {
    enum Phase: Equatable {
        case idle
        case importing
        case editing
        case preparing(current: Int, total: Int)
        case ready
        case failed(String)
    }

    var phase: Phase = .idle
    var drafts: [StickerPackDraft] = []
    var selectedDraft: StickerPackDraft?
    var preparedPack: PreparedPack?

    let workspaceRoot: URL
    private let draftStore: DraftStore

    init(baseURL: URL? = nil) {
        let base = baseURL ?? FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        )[0].appending(path: "StickerBridge", directoryHint: .isDirectory)
        workspaceRoot = base.appending(path: "Workspace", directoryHint: .isDirectory)
        draftStore = DraftStore(root: base.appending(path: "Drafts", directoryHint: .isDirectory))
    }

    func load() async {
        do {
            drafts = try await draftStore.list()
            try await consumeSharedInbox()
        } catch {
            phase = .failed(error.localizedDescription)
        }
    }

    func importURLs(_ urls: [URL]) async {
        phase = .importing
        do {
            let imported = try await StickerImportService(
                workspaceRoot: workspaceRoot
            ).importFiles(urls, defaultAuthor: "Me")
            for draft in imported { try await draftStore.save(draft) }
            drafts = imported + drafts
            selectedDraft = imported.first
            phase = .editing
        } catch {
            phase = .failed(error.localizedDescription)
        }
    }

    func consumeSharedInbox() async throws {
        let inbox = try ShareInbox.live()
        for batch in try inbox.completedBatches() {
            let directory = inbox.url(for: batch)
            let urls = batch.filenames.map { directory.appending(path: $0) }
            let imported = try await StickerImportService(
                workspaceRoot: workspaceRoot
            ).importFiles(urls, defaultAuthor: "Me")
            for draft in imported { try await draftStore.save(draft) }
            drafts.insert(contentsOf: imported, at: 0)
            try inbox.remove(batch)
        }
    }

    func saveDraft(_ draft: StickerPackDraft) async {
        selectedDraft = draft
        do {
            try await draftStore.save(draft)
            if let index = drafts.firstIndex(where: { $0.id == draft.id }) {
                drafts[index] = draft
            }
        } catch {
            phase = .failed(error.localizedDescription)
        }
    }

    func prepare(_ draft: StickerPackDraft) async {
        phase = .preparing(current: 0, total: draft.stickers.count)
        let service = PackPreparationService(
            workspaceRoot: workspaceRoot,
            transcoder: DefaultStickerTranscoder()
        )
        do {
            for try await event in service.prepare(draft) {
                switch event {
                case .started(let total):
                    phase = .preparing(current: 0, total: total)
                case .converted(let index, let total, _):
                    phase = .preparing(current: index, total: total)
                case .completed(let pack):
                    preparedPack = pack
                    phase = .ready
                }
            }
        } catch {
            phase = .failed(error.localizedDescription)
        }
    }
}
```

- [ ] **Step 3: Build import and draft selection**

Replace `StickerBridge/Features/ImportView.swift` with:

```swift
import SwiftUI
import UniformTypeIdentifiers

struct ImportView: View {
    @State private var model = BridgeAppModel()
    @State private var showsImporter = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Prepare sticker files for Signal")
                    .font(.largeTitle.bold())
                    .multilineTextAlignment(.center)
                Text("StickerBridge cannot read WhatsApp’s private library. Choose or share files you have permission to use.")
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                Button("Import sticker files") { showsImporter = true }
                    .buttonStyle(.borderedProminent)
                    .accessibilityHint("Choose a folder, ZIP, PNG, WebP, or APNG files.")

                if !model.drafts.isEmpty {
                    List(model.drafts) { draft in
                        NavigationLink(draft.title) {
                            PackEditorView(model: model, draft: draft)
                        }
                    }
                }
                if case .failed(let message) = model.phase {
                    Text(message).foregroundStyle(.red)
                }
            }
            .padding()
            .navigationTitle("StickerBridge")
        }
        .fileImporter(
            isPresented: $showsImporter,
            allowedContentTypes: [.folder, .zip, .png, .webP, .data],
            allowsMultipleSelection: true
        ) { result in
            switch result {
            case .success(let urls):
                Task { await model.importURLs(urls) }
            case .failure(let error):
                model.phase = .failed(error.localizedDescription)
            }
        }
        .task { await model.load() }
    }
}
```

- [ ] **Step 4: Build metadata, emoji, cover, order, and conversion UI**

Create `StickerBridge/Features/PackEditorView.swift`:

```swift
import SwiftUI

struct PackEditorView: View {
    let model: BridgeAppModel
    @State var draft: StickerPackDraft

    var body: some View {
        Form {
            Section("Pack") {
                TextField("Title", text: $draft.title)
                TextField("Author", text: $draft.author)
            }
            Section("Stickers") {
                ForEach($draft.stickers) { $sticker in
                    HStack {
                        TextField("Emoji", text: Binding(
                            get: { sticker.emoji },
                            set: { sticker.emoji = String($0.prefix(1)) }
                        ))
                        .frame(width: 56)
                        .accessibilityLabel("Emoji for \(sticker.relativePath)")
                        VStack(alignment: .leading) {
                            Text(URL(fileURLWithPath: sticker.relativePath).lastPathComponent)
                            Text(sticker.kind == .animated ? "Animated" : "Static")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button {
                            draft.coverStickerID = sticker.id
                        } label: {
                            Image(systemName: draft.coverStickerID == sticker.id ? "star.fill" : "star")
                        }
                        .accessibilityLabel(
                            draft.coverStickerID == sticker.id ? "Current cover" : "Use as cover"
                        )
                    }
                }
                .onDelete { offsets in
                    draft.stickers.remove(atOffsets: offsets)
                    if !draft.stickers.contains(where: { $0.id == draft.coverStickerID }),
                       let first = draft.stickers.first {
                        draft.coverStickerID = first.id
                    }
                }
                .onMove { source, destination in
                    draft.stickers.move(fromOffsets: source, toOffset: destination)
                }
            }
            Section {
                Button("Prepare for Signal") {
                    Task {
                        await model.saveDraft(draft)
                        await model.prepare(draft)
                    }
                }
                .disabled(draft.stickers.isEmpty || draft.stickers.count > 200)
            } footer: {
                Text("Conversion stays on this device. Signal Desktop is required to upload the finished pack.")
            }
            ConversionView(model: model)
        }
        .navigationTitle(draft.title)
        .toolbar { EditButton() }
        .onDisappear { Task { await model.saveDraft(draft) } }
    }
}
```

Create `StickerBridge/Features/ConversionView.swift`:

```swift
import SwiftUI

struct ConversionView: View {
    let model: BridgeAppModel

    var body: some View {
        switch model.phase {
        case .preparing(let current, let total):
            Section("Preparing") {
                ProgressView(value: Double(current), total: Double(max(total, 1)))
                Text("\(current) of \(total)")
            }
        case .ready:
            if let pack = model.preparedPack {
                Section {
                    NavigationLink("Review export") {
                        ExportView(model: model, pack: pack)
                    }
                }
            }
        case .failed(let message):
            Section {
                Text(message).foregroundStyle(.red)
            }
        default:
            EmptyView()
        }
    }
}
```

Modify `StickerBridge/App/StickerBridgeApp.swift` only if needed to keep `ImportView()` as the root.

- [ ] **Step 5: Regenerate and run UI plus unit tests**

Run:

```bash
xcodegen generate
xcodebuild -project StickerBridge.xcodeproj -scheme StickerBridge \
  -destination 'platform=iOS Simulator,name=iPhone 16' test
```

Expected: launch-copy UI test and all unit tests pass.

- [ ] **Step 6: Commit the product UI**

```bash
git add StickerBridge/App StickerBridge/Features StickerBridgeUITests
git commit -m "feat: add honest batch preparation workflow"
```

---

### Task 8: Export one Signal Desktop handoff archive

**Files:**
- Create: `StickerBridge/Export/SignalDesktopExporter.swift`
- Create: `StickerBridge/Features/ExportView.swift`
- Create: `StickerBridgeTests/Export/SignalDesktopExporterTests.swift`

**Interfaces:**
- Consumes: `PreparedPack` and prepared files beneath `workspaceRoot`.
- Produces: `SignalDesktopExporter.export(_:) throws -> URL`.

- [ ] **Step 1: Write the archive-content test**

Create `StickerBridgeTests/Export/SignalDesktopExporterTests.swift`:

```swift
import XCTest
import ZIPFoundation
@testable import StickerBridge

final class SignalDesktopExporterTests: XCTestCase {
    func testArchiveContainsOrderedAssetsAndGuides() throws {
        let root = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let prepared = root.appending(path: "pack/prepared", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: prepared, withIntermediateDirectories: true)
        try Data("one".utf8).write(to: prepared.appending(path: "001.webp"))
        try Data("two".utf8).write(to: prepared.appending(path: "002.apng"))

        let firstID = UUID()
        let pack = PreparedPack(
            id: UUID(),
            title: "Hello / Friends",
            author: "Asha",
            coverStickerID: firstID,
            stickers: [
                PreparedSticker(
                    id: firstID, relativePath: "pack/prepared/001.webp",
                    emoji: "👋", kind: .staticImage, byteCount: 3
                ),
                PreparedSticker(
                    id: UUID(), relativePath: "pack/prepared/002.apng",
                    emoji: "😂", kind: .animated, byteCount: 3
                )
            ]
        )

        let zip = try SignalDesktopExporter(workspaceRoot: root).export(pack)
        let archive = try XCTUnwrap(Archive(url: zip, accessMode: .read))
        XCTAssertEqual(
            archive.map(\.path).sorted(),
            ["001.webp", "002.apng", "README.txt", "emoji-manifest.html", "pack.json"]
        )
    }
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run:

```bash
xcodebuild -project StickerBridge.xcodeproj -scheme StickerBridge \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:StickerBridgeTests/SignalDesktopExporterTests test
```

Expected: build fails because `SignalDesktopExporter` is undefined.

- [ ] **Step 3: Implement deterministic, sanitized ZIP export**

Create `StickerBridge/Export/SignalDesktopExporter.swift`:

```swift
import Foundation
import ZIPFoundation

struct SignalDesktopExporter: Sendable {
    let workspaceRoot: URL

    func export(_ pack: PreparedPack) throws -> URL {
        try SignalStickerRules.validateMetadata(title: pack.title, author: pack.author)
        try SignalStickerRules.validatePackCount(pack.stickers.count)

        let exportRoot = workspaceRoot.appending(path: "Exports", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: exportRoot, withIntermediateDirectories: true)
        let safeTitle = pack.title
            .replacingOccurrences(of: "[^A-Za-z0-9._-]+", with: "-", options: .regularExpression)
            .trimmingCharacters(in: CharacterSet(charactersIn: "-"))
        let zipURL = exportRoot.appending(path: "\(safeTitle.isEmpty ? "Sticker-Pack" : safeTitle)-Signal.zip")
        try? FileManager.default.removeItem(at: zipURL)
        guard let archive = Archive(url: zipURL, accessMode: .create) else {
            throw CocoaError(.fileWriteUnknown)
        }

        for (index, sticker) in pack.stickers.enumerated() {
            let source = workspaceRoot.appending(path: sticker.relativePath)
            let name = String(format: "%03d", index + 1) + "." + source.pathExtension.lowercased()
            try archive.addEntry(with: name, fileURL: source)
        }

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try addData(try encoder.encode(pack), named: "pack.json", to: archive)
        try addData(Data(readme(for: pack).utf8), named: "README.txt", to: archive)
        try addData(Data(emojiManifest(for: pack).utf8), named: "emoji-manifest.html", to: archive)
        return zipURL
    }

    private func addData(_ data: Data, named name: String, to archive: Archive) throws {
        try archive.addEntry(
            with: name,
            type: .file,
            uncompressedSize: Int64(data.count),
            provider: { position, size in
                let start = Int(position)
                return data.subdata(in: start..<(start + size))
            }
        )
    }

    private func readme(for pack: PreparedPack) -> String {
        """
        \(pack.title)
        Author: \(pack.author)

        1. Copy this ZIP to the computer where Signal Desktop is linked.
        2. Unzip it.
        3. In Signal Desktop choose File > Create/Upload Sticker Pack.
        4. Select all numbered .webp and .apng files in one selection.
        5. Open emoji-manifest.html and assign the listed emoji in Signal's creator.
        6. Confirm title, author, cover, upload, and install in Signal.

        Signal custom packs cannot be edited or deleted after upload. Review everything first.
        """
    }

    private func emojiManifest(for pack: PreparedPack) -> String {
        let rows = pack.stickers.enumerated().map { index, sticker in
            let source = URL(fileURLWithPath: sticker.relativePath)
            let filename = String(format: "%03d", index + 1) + "." + source.pathExtension
            return "<tr><td>\(filename)</td><td class=\"emoji\">\(escape(sticker.emoji))</td></tr>"
        }.joined(separator: "\n")
        return """
        <!doctype html>
        <html><head><meta charset="utf-8"><title>\(escape(pack.title)) emoji map</title>
        <style>body{font:16px -apple-system,sans-serif;max-width:720px;margin:40px auto}
        table{border-collapse:collapse;width:100%}td,th{padding:10px;border:1px solid #ccc}
        .emoji{font-size:28px}</style></head>
        <body><h1>\(escape(pack.title))</h1>
        <p>Use this map while assigning one emoji per sticker in Signal Desktop.</p>
        <table><thead><tr><th>File</th><th>Emoji</th></tr></thead><tbody>
        \(rows)
        </tbody></table></body></html>
        """
    }

    private func escape(_ value: String) -> String {
        value
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
    }
}
```

- [ ] **Step 4: Build rights confirmation and system share export**

Create `StickerBridge/Features/ExportView.swift`:

```swift
import SwiftUI

struct ExportView: View {
    let model: BridgeAppModel
    let pack: PreparedPack
    @State private var confirmsRights = false
    @State private var exportURL: URL?
    @State private var errorMessage: String?

    var body: some View {
        Form {
            Section("Ready") {
                LabeledContent("Pack", value: pack.title)
                LabeledContent("Author", value: pack.author)
                LabeledContent("Stickers", value: "\(pack.stickers.count)")
            }
            Section {
                Toggle(
                    "I own this sticker art or have permission to transfer and share it.",
                    isOn: $confirmsRights
                )
            }
            Section {
                Button("Create Signal Desktop ZIP") {
                    do {
                        exportURL = try SignalDesktopExporter(
                            workspaceRoot: model.workspaceRoot
                        ).export(pack)
                    } catch {
                        errorMessage = error.localizedDescription
                    }
                }
                .disabled(!confirmsRights)

                if let exportURL {
                    ShareLink(item: exportURL) {
                        Label("Share or Save ZIP", systemImage: "square.and.arrow.up")
                    }
                    Text("Next: unzip on a computer and use Signal Desktop → File → Create/Upload Sticker Pack.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                if let errorMessage {
                    Text(errorMessage).foregroundStyle(.red)
                }
            }
        }
        .navigationTitle("Export for Signal Desktop")
    }
}
```

- [ ] **Step 5: Run exporter and full test suites**

Run:

```bash
xcodebuild -project StickerBridge.xcodeproj -scheme StickerBridge \
  -destination 'platform=iOS Simulator,name=iPhone 16' test
```

Expected: exporter test and all prior tests pass.

- [ ] **Step 6: Commit the Desktop handoff**

```bash
git add StickerBridge/Export StickerBridge/Features/ExportView.swift StickerBridgeTests/Export
git commit -m "feat: export Signal Desktop sticker archives"
```

---

### Task 9: Add privacy declarations and forbid unsupported integrations

**Files:**
- Create: `StickerBridge/Resources/PrivacyInfo.xcprivacy`
- Create: `scripts/verify_supported_integrations.sh`
- Create: `docs/app-store/privacy-and-review-notes.md`
- Modify: `project.yml`

**Interfaces:**
- Consumes: the complete app source.
- Produces: an enforceable no-network/no-credential boundary and App Review notes.

- [ ] **Step 1: Add the privacy manifest**

Create `StickerBridge/Resources/PrivacyInfo.xcprivacy`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>NSPrivacyTracking</key>
  <false/>
  <key>NSPrivacyTrackingDomains</key>
  <array/>
  <key>NSPrivacyCollectedDataTypes</key>
  <array/>
  <key>NSPrivacyAccessedAPITypes</key>
  <array/>
</dict>
</plist>
```

Ensure `StickerBridge/Resources` remains included by the existing `StickerBridge` sources entry in `project.yml`.

- [ ] **Step 2: Add a static policy check**

Create `scripts/verify_supported_integrations.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

forbidden='chat\.signal\.org|v1/sticker/pack/form|Authorization: Basic|whatsapp://stickerPack|group\.org\.whispersystems|Application Support/WhatsApp|net\.whatsapp\.WhatsApp'

if rg -n "$forbidden" StickerBridge StickerBridgeShare Shared \
  --glob '*.swift' --glob '*.plist' --glob '*.entitlements'; then
  echo "Unsupported private-app or Signal-service integration found." >&2
  exit 1
fi

if rg -n 'URLSession|NWConnection|Network\.framework|CFNetwork' \
  StickerBridge StickerBridgeShare Shared --glob '*.swift'; then
  echo "Unexpected network client found in the local-only v1." >&2
  exit 1
fi

echo "Supported integration boundary verified."
```

Run:

```bash
chmod +x scripts/verify_supported_integrations.sh
scripts/verify_supported_integrations.sh
```

Expected: `Supported integration boundary verified.`

- [ ] **Step 3: Write exact App Review and privacy copy**

Create `docs/app-store/privacy-and-review-notes.md`:

```markdown
# StickerBridge privacy and App Review notes

## Privacy label

- Data collected: None.
- Data linked to the user: None.
- Tracking: No.

## Review notes

StickerBridge is a local media conversion utility. It does not access WhatsApp
or Signal app containers, accounts, databases, backups, or credentials.

The main app imports files selected by the reviewer through the system document
picker. The share extension receives only representations explicitly supplied
by a host app through the standard iOS share sheet. All processing happens on
device.

The exported ZIP contains numbered WebP/APNG files, a local JSON manifest, a
local HTML emoji map, and instructions for Signal Desktop. StickerBridge does
not upload to Signal or call Signal services.

Suggested review:

1. Create or select two PNG files in Files.
2. Open StickerBridge and tap "Import sticker files."
3. Select both files, edit title/author/emoji, and tap "Prepare for Signal."
4. Confirm art rights and export the ZIP to Files.
5. Inspect the ZIP contents.
```

- [ ] **Step 4: Run policy check, tests, and clean build**

Run:

```bash
scripts/verify_supported_integrations.sh
xcodebuild -project StickerBridge.xcodeproj -scheme StickerBridge \
  -destination 'platform=iOS Simulator,name=iPhone 16' clean test
```

Expected: policy check succeeds; build and all tests pass.

- [ ] **Step 5: Commit privacy and policy enforcement**

```bash
git add StickerBridge/Resources scripts docs/app-store project.yml
git commit -m "chore: enforce local-only privacy boundary"
```

---

### Task 10: Verify the real handoff and document the direct-install stop condition

**Files:**
- Create: `.github/workflows/ios.yml`
- Create: `docs/acceptance/real-device-matrix.md`
- Modify: `docs/decisions/0001-supported-product-boundary.md`

**Interfaces:**
- Consumes: the complete iOS app, current WhatsApp iOS, current Signal iOS, and a linked Signal Desktop installation.
- Produces: repeatable CI and a signed-off real-device acceptance record.

- [ ] **Step 1: Add CI for policy, generation, and tests**

Create `.github/workflows/ios.yml`:

```yaml
name: iOS
on:
  pull_request:
  push:
    branches: [main]
jobs:
  test:
    runs-on: macos-15
    steps:
      - uses: actions/checkout@v4
      - name: Install XcodeGen
        run: brew install xcodegen
      - name: Verify supported integrations
        run: scripts/verify_supported_integrations.sh
      - name: Generate project
        run: xcodegen generate
      - name: Test
        run: |
          xcodebuild -project StickerBridge.xcodeproj -scheme StickerBridge \
            -destination 'platform=iOS Simulator,name=iPhone 16' \
            CODE_SIGNING_ALLOWED=NO test
```

- [ ] **Step 2: Create the real-device acceptance matrix**

Create `docs/acceptance/real-device-matrix.md`:

```markdown
# Real-device acceptance matrix

Record device, OS, app versions, date, tester, and pass/fail evidence for every row.

| Case | Input | Expected |
|---|---|---|
| Files static | 30 mixed PNG/WebP files | One draft; order stable; all outputs WebP <= 300 KiB |
| Files animated | 10 animated WebP files, including one > 3 s | All outputs APNG <= 3 s and <= 300 KiB, or a named actionable failure |
| WhatsApp schema folder | `sticker_packs.wasticker` plus static assets | Title, publisher, order, first emoji, and accessibility text preserved |
| WhatsApp schema ZIP | Same folder zipped | Same result; no file escapes extraction root |
| Malicious ZIP | Entry named `../escape.webp` | Import rejected; no outside file written |
| Share extension | 1, 30, and 200 image item providers | Complete App Group batches imported once, then removed |
| WhatsApp share surface | Every sticker/pack share action exposed by current WhatsApp | Import only actual image/archive providers; reject bare links without scraping |
| Memory | 200 static stickers and 20 animated stickers | No termination; animations processed sequentially |
| Signal static handoff | Export ZIP opened on linked Signal Desktop | All static files accepted in one bulk selection |
| Signal animated handoff | Export ZIP opened on linked Signal Desktop | All APNG files preview and loop correctly |
| Light/dark | Every prepared sticker previewed on both backgrounds | Transparent art remains legible |
| Accessibility | VoiceOver through import, editor, progress, export | Every control has a useful name and progress is announced |
| Privacy | Device proxy enabled during all flows | No StickerBridge network request |

## Direct-install stop condition

Do not add a Signal upload client, backend upload broker, service account,
credential import, linked-device implementation, or automatic `signal.art`
handoff. Open a new design only after written Signal approval or a published
third-party upload API documents authentication, abuse controls, rate limits,
and allowed distribution.
```

- [ ] **Step 3: Perform the acceptance run on physical hardware**

Run the app from Xcode on an iPhone with current WhatsApp and Signal installed. Complete every matrix row. For the Signal handoff, use the official linked Signal Desktop creator and retain:

```text
- the exported ZIP;
- `pack.json`;
- screenshots of the Desktop preview for static and animated packs;
- the final `signal.art/addstickers` URL created by Signal Desktop;
- a screenshot of Signal iOS showing the install preview.
```

Expected: every supported row passes. WhatsApp may expose no bulk pack representation; record that as an external capability observation, not an app defect or a reason to add scraping.

- [ ] **Step 4: Re-evaluate the direct-install gate**

Append one of these exact outcomes to `docs/decisions/0001-supported-product-boundary.md`:

```markdown
## Direct-install review outcome

No supported Signal third-party upload API or written integration approval was
available at release review. The direct-install feature remains blocked.
```

If written approval exists, append:

```markdown
## Direct-install review outcome

Signal supplied written integration approval and a documented upload contract.
Direct installation remains absent from v1. A separate threat model and
implementation plan are required before code is added.
```

Do not continue directly from this plan into upload implementation.

- [ ] **Step 5: Run the final local acceptance commands**

```bash
scripts/verify_supported_integrations.sh
xcodegen generate
xcodebuild -project StickerBridge.xcodeproj -scheme StickerBridge \
  -destination 'platform=iOS Simulator,name=iPhone 16' clean test
git status --short
```

Expected: policy check succeeds; test suite passes; `git status --short` only lists the acceptance evidence/ADR update not yet committed.

- [ ] **Step 6: Commit verified release readiness**

```bash
git add .github docs/acceptance docs/decisions
git commit -m "test: verify StickerBridge supported handoff"
```

---

## Plan Self-Review

### Spec coverage

- Research of WhatsApp, iOS, and Signal constraints: covered in “Research Result and Product Boundary.”
- iOS batch import: Tasks 2 and 3.
- WhatsApp-compatible pack parsing: Task 2.
- Static and animated conversion: Tasks 4 and 5.
- Signal format/size/duration/emoji rules: Tasks 1, 4, 5, and 6.
- One archive export and official Signal Desktop handoff: Task 8.
- Privacy, sandbox, and unsupported-integration enforcement: Tasks 1, 3, and 9.
- Real WhatsApp/Signal verification: Task 10.
- Literal direct WhatsApp-library-to-Signal transfer: explicitly identified as unsupported and blocked; the plan does not misrepresent it as implementable.

### Completeness scan

Every code-changing step contains concrete file content, commands, expected results, and named interfaces. The future direct-install path is deliberately excluded and requires a new plan after an external authorization event.

### Type consistency

- `StickerPackDraft.stickers` is `[SourceSticker]` in import, persistence, UI, and preparation.
- `PreparedPack.stickers` is `[PreparedSticker]` in preparation and export.
- Both transcoders produce `TranscodedStickerData`.
- `PackPreparationService` consumes a `StickerTranscoding` implementation and emits `PreparationEvent`.
- `ShareInbox` writes and reads `ShareBatchManifest` through one App Group.

## Explicitly Excluded From This Plan

- Reading WhatsApp's installed stickers, favorites, chat database, backup, or app container.
- Downloading a WhatsApp sticker pack from a WhatsApp share URL.
- Automating Signal registration or linked-device provisioning.
- Reusing Signal Desktop credentials.
- A backend authenticated as one shared Signal account.
- Calling `v1/sticker/pack/form`.
- Generating or opening a `signal.art/addstickers` URL before Signal has created a real pack.
- App Store marketing that promises a direct or one-tap transfer.
