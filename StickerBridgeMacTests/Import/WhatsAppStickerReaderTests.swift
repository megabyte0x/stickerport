import XCTest
@testable import StickerBridgeMac

final class WhatsAppStickerReaderTests: XCTestCase {
    func testLoadsOnlyInstalledPackRowsWithLocalMedia() throws {
        let fixture = try WhatsAppSQLiteFixture.make()
        defer { try? FileManager.default.removeItem(at: fixture.rootURL) }
        let databaseBefore = try Data(contentsOf: fixture.databaseURL)

        let packs = try reader(for: fixture).load(from: fixture.rootURL)

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

    func testLoadLeavesEntireContainerUnchangedWithSQLiteSidecars() throws {
        let fixture = try WhatsAppSQLiteFixture.make(
            includeSQLiteSidecars: true
        )
        defer { try? FileManager.default.removeItem(at: fixture.rootURL) }
        let before = try snapshot(of: fixture.rootURL)

        _ = try reader(for: fixture).load(from: fixture.rootURL)

        XCTAssertEqual(try snapshot(of: fixture.rootURL), before)
        XCTAssertNotNil(
            before.files["Sticker.sqlite-wal"]
        )
        XCTAssertNotNil(
            before.files["Sticker.sqlite-shm"]
        )
    }

    func testWrongContainerFailsBeforeReading() throws {
        let fixture = try WhatsAppSQLiteFixture.make()
        defer { try? FileManager.default.removeItem(at: fixture.rootURL) }
        let expected = fixture.rootURL
            .deletingLastPathComponent()
            .appendingPathComponent(UUID().uuidString, isDirectory: true)

        XCTAssertThrowsError(
            try WhatsAppStickerReader(
                expectedContainerURL: expected
            ).load(from: fixture.rootURL)
        ) {
            XCTAssertEqual(
                $0 as? WhatsAppMVPError,
                .unexpectedContainer(expectedPath: expected.path)
            )
        }
    }

    func testUnknownSchemaFailsClosed() throws {
        let fixture = try WhatsAppSQLiteFixture.make(
            includeStickerTable: false
        )
        defer { try? FileManager.default.removeItem(at: fixture.rootURL) }

        XCTAssertThrowsError(
            try reader(for: fixture).load(from: fixture.rootURL)
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

        let packs = try reader(for: fixture).load(from: fixture.rootURL)

        XCTAssertEqual(packs[0].stickers.count, 1)
        XCTAssertEqual(packs[0].stickers[0].emoji, "😂")
    }

    func testSymlinkedStickerDirectoryOutsideContainerFailsClosed() throws {
        let fixture = try WhatsAppSQLiteFixture.make()
        let externalDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer {
            try? FileManager.default.removeItem(at: fixture.rootURL)
            try? FileManager.default.removeItem(at: externalDirectory)
        }
        try FileManager.default.createDirectory(
            at: externalDirectory,
            withIntermediateDirectories: true
        )
        let stickersURL = fixture.rootURL.appendingPathComponent("stickers")
        try FileManager.default.removeItem(at: stickersURL)
        try FileManager.default.createSymbolicLink(
            at: stickersURL,
            withDestinationURL: externalDirectory
        )

        XCTAssertThrowsError(
            try reader(for: fixture).load(from: fixture.rootURL)
        ) {
            XCTAssertEqual($0 as? WhatsAppMVPError, .missingStickerDirectory)
        }
    }

    func testMismatchedInstalledPackEntityFailsClosed() throws {
        let fixture = try WhatsAppSQLiteFixture.make(
            installedPackEntity: 9
        )
        defer { try? FileManager.default.removeItem(at: fixture.rootURL) }

        XCTAssertThrowsError(
            try reader(for: fixture).load(from: fixture.rootURL)
        ) {
            XCTAssertEqual(
                $0 as? WhatsAppMVPError,
                .unsupportedSchema(
                    "WACDStickerPack must map to Core Data entity 2."
                )
            )
        }
    }

    func testMismatchedColumnAffinityFailsClosed() throws {
        let fixture = try WhatsAppSQLiteFixture.make(
            relativeImagePathDeclaredType: "BLOB"
        )
        defer { try? FileManager.default.removeItem(at: fixture.rootURL) }

        XCTAssertThrowsError(
            try reader(for: fixture).load(from: fixture.rootURL)
        ) {
            XCTAssertEqual(
                $0 as? WhatsAppMVPError,
                .unsupportedSchema(
                    "ZWACDSTICKER.ZRELATIVEIMAGEPATH must have TEXT affinity."
                )
            )
        }
    }

    private func reader(
        for fixture: WhatsAppSQLiteFixture
    ) -> WhatsAppStickerReader {
        WhatsAppStickerReader(expectedContainerURL: fixture.rootURL)
    }

    private func snapshot(of rootURL: URL) throws -> DirectorySnapshot {
        guard let enumerator = FileManager.default.enumerator(
            at: rootURL,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [],
            errorHandler: { _, _ in false }
        ) else {
            throw CocoaError(.fileReadUnknown)
        }
        var directories: Set<String> = ["."]
        var files: [String: Data] = [:]
        for case let url as URL in enumerator {
            let relativePath = String(
                url.path.dropFirst(rootURL.path.count + 1)
            )
            let values = try url.resourceValues(
                forKeys: [.isDirectoryKey]
            )
            if values.isDirectory == true {
                directories.insert(relativePath)
            } else {
                files[relativePath] = try Data(contentsOf: url)
            }
        }
        return DirectorySnapshot(
            directories: directories,
            files: files
        )
    }

    private struct DirectorySnapshot: Equatable {
        let directories: Set<String>
        let files: [String: Data]
    }
}
