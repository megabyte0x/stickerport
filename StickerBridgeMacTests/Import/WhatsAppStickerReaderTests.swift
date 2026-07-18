import XCTest
@testable import StickerBridgeMac

final class WhatsAppStickerReaderTests: XCTestCase {
    func testLoadsOnlyInstalledPackRowsWithLocalMedia() throws {
        let fixture = try WhatsAppSQLiteFixture.make()
        defer { try? FileManager.default.removeItem(at: fixture.rootURL) }
        let databaseBefore = try Data(contentsOf: fixture.databaseURL)

        let packs = try WhatsAppStickerReader().load(from: fixture.rootURL)

        XCTAssertEqual(packs.count, 1)
        XCTAssertEqual(packs[0].title, "Fixture Pack")
        XCTAssertEqual(packs[0].author, "Fixture Publisher")
        XCTAssertEqual(packs[0].stickers.map(\.order), [0, 1])
        XCTAssertEqual(packs[0].stickers.map(\.emoji), ["☕", "😂"])
        XCTAssertEqual(packs[0].stickers[0].data, Data("first".utf8))
        XCTAssertEqual(
            try Data(contentsOf: fixture.databaseURL),
            databaseBefore
        )
    }

    func testUnknownSchemaFailsClosed() throws {
        let fixture = try WhatsAppSQLiteFixture.make(
            includeStickerTable: false
        )
        defer { try? FileManager.default.removeItem(at: fixture.rootURL) }

        XCTAssertThrowsError(
            try WhatsAppStickerReader().load(from: fixture.rootURL)
        ) {
            XCTAssertEqual(
                $0 as? WhatsAppMVPError,
                .missingTable("ZWACDSTICKER")
            )
        }
    }

    func testStickerPathCannotEscapeLocalStickerDirectory() throws {
        let fixture = try WhatsAppSQLiteFixture.make(
            firstRelativePath: "../Sticker.sqlite"
        )
        defer { try? FileManager.default.removeItem(at: fixture.rootURL) }

        let packs = try WhatsAppStickerReader().load(from: fixture.rootURL)

        XCTAssertEqual(packs[0].stickers.count, 1)
        XCTAssertEqual(packs[0].stickers[0].emoji, "😂")
    }
}
