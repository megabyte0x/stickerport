import XCTest
@testable import StickerBridge

final class BasicStickerImportServiceTests: XCTestCase {
    private var temporaryDirectory: URL!

    override func setUpWithError() throws {
        temporaryDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: temporaryDirectory, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try FileManager.default.removeItem(at: temporaryDirectory)
    }

    func testImportsSupportedFilesInSelectedOrderWithDefaultMetadata() async throws {
        let first = try makeSourceFile(named: "first.png", contents: staticPNGData)
        let second = try makeSourceFile(named: "second.webp", contents: staticWebPData)
        let workspaceRoot = temporaryDirectory.appendingPathComponent("workspace", isDirectory: true)

        let draft = try await BasicStickerImportService(workspaceRoot: workspaceRoot)
            .importFiles([first, second], defaultAuthor: "Ada")

        XCTAssertEqual(draft.title, "Imported Stickers")
        XCTAssertEqual(draft.author, "Ada")
        XCTAssertEqual(draft.coverStickerID, draft.stickers[0].id)
        XCTAssertEqual(draft.stickers.map(\.kind), [.staticImage, .staticImage])
        XCTAssertEqual(draft.stickers.map(\.emoji), ["🙂", "🙂"])
        XCTAssertTrue(draft.stickers[0].relativePath.hasSuffix("001-first.png"))
        XCTAssertTrue(draft.stickers[1].relativePath.hasSuffix("002-second.webp"))
    }

    func testCopiesSourcesToDistinctWorkspaceOwnedPathsWhenBasenamesCollide() async throws {
        let firstDirectory = temporaryDirectory.appendingPathComponent("first", isDirectory: true)
        let secondDirectory = temporaryDirectory.appendingPathComponent("second", isDirectory: true)
        try FileManager.default.createDirectory(at: firstDirectory, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: secondDirectory, withIntermediateDirectories: true)
        let first = try makeSourceFile(in: firstDirectory, named: "sticker.png", contents: staticPNGData)
        let second = try makeSourceFile(in: secondDirectory, named: "sticker.png", contents: alternateStaticPNGData)
        let workspaceRoot = temporaryDirectory.appendingPathComponent("workspace", isDirectory: true)

        let draft = try await BasicStickerImportService(workspaceRoot: workspaceRoot)
            .importFiles([first, second], defaultAuthor: "Ada")

        XCTAssertEqual(draft.stickers.count, 2)
        XCTAssertNotEqual(draft.stickers[0].relativePath, draft.stickers[1].relativePath)
        XCTAssertFalse(draft.stickers[0].relativePath.hasPrefix("/"))
        XCTAssertFalse(draft.stickers[1].relativePath.hasPrefix("/"))

        let firstCopy = workspaceRoot.appendingPathComponent(draft.stickers[0].relativePath)
        let secondCopy = workspaceRoot.appendingPathComponent(draft.stickers[1].relativePath)
        XCTAssertEqual(try Data(contentsOf: firstCopy), staticPNGData)
        XCTAssertEqual(try Data(contentsOf: secondCopy), alternateStaticPNGData)
    }

    func testRejectsUnsupportedOrEmptySelections() async throws {
        let unsupported = try makeSourceFile(named: "sticker.gif", contents: staticPNGData)
        let service = BasicStickerImportService(
            workspaceRoot: temporaryDirectory.appendingPathComponent("workspace", isDirectory: true)
        )

        for selection in [[], [unsupported]] {
            do {
                _ = try await service.importFiles(selection, defaultAuthor: "Ada")
                XCTFail("Expected no supported files failure")
            } catch let failure as BasicImportFailure {
                XCTAssertEqual(failure, .noSupportedFiles)
            }
        }
    }

    func testRejectsMalformedAndAnimatedPNGOrWebPFiles() async throws {
        let malformed = try makeSourceFile(named: "corrupt.png", contents: Data("not an image".utf8))
        let animatedPNG = try makeSourceFile(named: "animated.png", contents: animatedPNGData)
        let animatedWebP = try makeSourceFile(named: "animated.webp", contents: animatedWebPData)
        let service = BasicStickerImportService(
            workspaceRoot: temporaryDirectory.appendingPathComponent("workspace", isDirectory: true)
        )

        for selection in [[malformed], [animatedPNG], [animatedWebP]] {
            do {
                _ = try await service.importFiles(selection, defaultAuthor: "Ada")
                XCTFail("Expected no supported files failure")
            } catch let failure as BasicImportFailure {
                XCTAssertEqual(failure, .noSupportedFiles)
            }
        }
    }

    private func makeSourceFile(named name: String, contents: Data) throws -> URL {
        try makeSourceFile(in: temporaryDirectory, named: name, contents: contents)
    }

    private func makeSourceFile(in directory: URL, named name: String, contents: Data) throws -> URL {
        let url = directory.appendingPathComponent(name)
        try contents.write(to: url)
        return url
    }

    private var staticPNGData: Data {
        fixtureData(
            "iVBORw0KGgoAAAANSUhEUgAAAAIAAAACAQMAAABIeJ9nAAAAIGNIUk0AAHomAACAhAAA+gAAAIDoAAB1MAAA6mAAADqYAAAXcJy6UTwAAAAGUExURf8AAP///0EdNBEAAAABYktHRAH/Ai3eAAAAB3RJTUUH6gcRFQUWssBeIQAAACV0RVh0ZGF0ZTpjcmVhdGUAMjAyNi0wNy0xN1QyMTowNToyMiswMDowMEFnRDcAAAAldEVYdGRhdGU6bW9kaWZ5ADIwMjYtMDctMTdUMjE6MDU6MjIrMDA6MDAwOvyLAAAAKHRFWHRkYXRlOnRpbWVzdGFtcAAyMDI2LTA3LTE3VDIxOjA1OjIyKzAwOjAwZy/dVAAAAAxJREFUCNdjYGBgAAAABAABJzQnCgAAAABJRU5ErkJggg=="
        )
    }

    private var alternateStaticPNGData: Data {
        fixtureData(
            "iVBORw0KGgoAAAANSUhEUgAAAAIAAAACAQMAAABIeJ9nAAAAIGNIUk0AAHomAACAhAAA+gAAAIDoAAB1MAAA6mAAADqYAAAXcJy6UTwAAAAGUExURQAA/////3vcmSwAAAABYktHRAH/Ai3eAAAAB3RJTUUH6gcRFQUbzHEinAAAACV0RVh0ZGF0ZTpjcmVhdGUAMjAyNi0wNy0xN1QyMTowNToyNyswMDowMBNfa5AAAAAldEVYdGRhdGU6bW9kaWZ5ADIwMjYtMDctMTdUMjE6MDU6MjcrMDA6MDBiAtMsAAAAKHRFWHRkYXRlOnRpbWVzdGFtcAAyMDI2LTA3LTE3VDIxOjA1OjI3KzAwOjAwNRfy8wAAAAxJREFUCNdjYGBgAAAABAABJzQnCgAAAABJRU5ErkJggg=="
        )
    }

    private var staticWebPData: Data {
        fixtureData("UklGRjwAAABXRUJQVlA4IDAAAADQAQCdASoCAAIAAgA0JaACdLoB+AADsAD+8MQL/yC5YXXI1/8gP+QH/ID/+PIAAAA=")
    }

    private var animatedPNGData: Data {
        fixtureData(
            "iVBORw0KGgoAAAANSUhEUgAAAAIAAAACCAIAAAD91JpzAAAACXBIWXMAAAAAAAAAAQCEeRdzAAAACGFjVEwAAAACAAAAAPONk3AAAAAaZmNUTAAAAAAAAAACAAAAAgAAAAAAAAAAAAEACgAA6FTcAAAAABJJREFUeJxj/MvAyMDAwMIABgANHAEEhmSuyAAAABpmY1RMAAAAAQAAAAIAAAACAAAAAAAAAAAAAQAKAABzJzbUAAAAFmZkQVQAAAACeJxjZGT4y8DAwMIABgALJAEET/99TwAAAABJRU5ErkJggg=="
        )
    }

    private var animatedWebPData: Data {
        fixtureData(
            "UklGRoQAAABXRUJQVlA4WAoAAAACAAAAAQAAAQAAQU5JTQYAAAD/////AABBTk1GKAAAAAAAAAAAAAEAAAEAAGQAAAJWUDhMDwAAAC8BQAAABxD9j/4HIqL/AQBBTk1GKAAAAAAAAAAAAAEAAAEAAGQAAABWUDhMDwAAAC8BQAAABxDR//4HIqL/AQA="
        )
    }

    private func fixtureData(_ base64: String) -> Data {
        guard let data = Data(base64Encoded: base64) else {
            fatalError("Invalid test fixture")
        }
        return data
    }
}
