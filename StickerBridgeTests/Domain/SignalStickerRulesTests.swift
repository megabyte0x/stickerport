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
        XCTAssertThrowsError(try SignalStickerRules.validateEmoji("𝄞"))
        XCTAssertThrowsError(try SignalStickerRules.validateEmoji("1"))
        XCTAssertThrowsError(try SignalStickerRules.validateEmoji("🙂😂"))
    }
}
