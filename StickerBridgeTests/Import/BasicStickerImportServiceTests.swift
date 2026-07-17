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
        let first = try makeSourceFile(named: "first.png", contents: Data([0x01]))
        let second = try makeSourceFile(named: "second.webp", contents: Data([0x02]))
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
        let first = try makeSourceFile(in: firstDirectory, named: "sticker.png", contents: Data([0x01]))
        let second = try makeSourceFile(in: secondDirectory, named: "sticker.png", contents: Data([0x02]))
        let workspaceRoot = temporaryDirectory.appendingPathComponent("workspace", isDirectory: true)

        let draft = try await BasicStickerImportService(workspaceRoot: workspaceRoot)
            .importFiles([first, second], defaultAuthor: "Ada")

        XCTAssertEqual(draft.stickers.count, 2)
        XCTAssertNotEqual(draft.stickers[0].relativePath, draft.stickers[1].relativePath)
        XCTAssertFalse(draft.stickers[0].relativePath.hasPrefix("/"))
        XCTAssertFalse(draft.stickers[1].relativePath.hasPrefix("/"))

        let firstCopy = workspaceRoot.appendingPathComponent(draft.stickers[0].relativePath)
        let secondCopy = workspaceRoot.appendingPathComponent(draft.stickers[1].relativePath)
        XCTAssertEqual(try Data(contentsOf: firstCopy), Data([0x01]))
        XCTAssertEqual(try Data(contentsOf: secondCopy), Data([0x02]))
    }

    func testRejectsUnsupportedOrEmptySelections() async throws {
        let unsupported = try makeSourceFile(named: "sticker.gif", contents: Data())
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

    private func makeSourceFile(named name: String, contents: Data) throws -> URL {
        try makeSourceFile(in: temporaryDirectory, named: name, contents: contents)
    }

    private func makeSourceFile(in directory: URL, named name: String, contents: Data) throws -> URL {
        let url = directory.appendingPathComponent(name)
        try contents.write(to: url)
        return url
    }
}
