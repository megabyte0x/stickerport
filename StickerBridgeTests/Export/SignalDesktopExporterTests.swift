import Foundation
import XCTest
import ZIPFoundation
@testable import StickerBridge

final class SignalDesktopExporterTests: XCTestCase {
    private var workspaceRoot: URL!

    override func setUpWithError() throws {
        workspaceRoot = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: workspaceRoot, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try FileManager.default.removeItem(at: workspaceRoot)
    }

    func testExportsOrderedZIPEntries() throws {
        let staticURL = try write("static".data(using: .utf8)!, to: "inputs/first.webp")
        let animatedURL = try write("animated".data(using: .utf8)!, to: "inputs/second.apng")
        let pack = makePack(stickers: [
            makeSticker(path: relativePath(for: staticURL), emoji: "🙂", kind: .staticImage),
            makeSticker(path: relativePath(for: animatedURL), emoji: "👋", kind: .animated)
        ])

        let archiveURL = try SignalDesktopExporter(workspaceRoot: workspaceRoot).export(pack)
        let archive = try Archive(url: archiveURL, accessMode: .read)

        XCTAssertEqual(archive.map(\.path), [
            "sticker-001.webp",
            "sticker-002.apng",
            "pack.json",
            "emoji-manifest.html",
            "README.txt"
        ])
    }

    func testRejectsTraversalOutsideWorkspace() throws {
        let pack = makePack(stickers: [makeSticker(path: "../outside.webp", emoji: "🙂", kind: .staticImage)])

        XCTAssertThrowsError(try SignalDesktopExporter(workspaceRoot: workspaceRoot).export(pack)) { error in
            XCTAssertEqual(error as? SignalDesktopExportError, .unsafeRelativePath("../outside.webp"))
        }
    }

    func testRepeatExportPreservesFirstArchiveAndUsesDistinctURL() throws {
        let stickerURL = try write("sticker".data(using: .utf8)!, to: "inputs/sticker.webp")
        let pack = makePack(stickers: [makeSticker(path: relativePath(for: stickerURL), emoji: "🙂", kind: .staticImage)])
        let exporter = SignalDesktopExporter(workspaceRoot: workspaceRoot)

        let first = try exporter.export(pack)
        let originalData = try Data(contentsOf: first)
        let second = try exporter.export(pack)

        XCTAssertNotEqual(first, second)
        XCTAssertTrue(FileManager.default.fileExists(atPath: first.path))
        XCTAssertEqual(try Data(contentsOf: first), originalData)
        XCTAssertTrue(FileManager.default.fileExists(atPath: second.path))
    }

    func testRetriesWithNextSuffixWhenArchiveCreationFindsCompetingDestination() throws {
        let stickerURL = try write("sticker".data(using: .utf8)!, to: "inputs/sticker.webp")
        let pack = makePack(stickers: [makeSticker(path: relativePath(for: stickerURL), emoji: "🙂", kind: .staticImage)])
        let competingData = Data("another export".utf8)
        var archiveCreationAttempts = 0
        let exporter = SignalDesktopExporter(workspaceRoot: workspaceRoot, makeArchive: { url in
            archiveCreationAttempts += 1
            if archiveCreationAttempts == 1 {
                try competingData.write(to: url)
                throw NSError(
                    domain: NSCocoaErrorDomain,
                    code: CocoaError.Code.fileWriteFileExists.rawValue
                )
            }
            return try Archive(url: url, accessMode: .create)
        })

        let archiveURL = try exporter.export(pack)
        let firstCandidate = workspaceRoot.appendingPathComponent("Exports/MVP-Pack.zip")

        XCTAssertEqual(archiveCreationAttempts, 2)
        XCTAssertEqual(archiveURL.lastPathComponent, "MVP-Pack-2.zip")
        XCTAssertEqual(try Data(contentsOf: firstCandidate), competingData)
    }

    private func makePack(stickers: [PreparedSticker]) -> PreparedPack {
        PreparedPack(
            id: UUID(),
            title: "MVP Pack",
            author: "StickerBridge",
            coverStickerID: stickers[0].id,
            stickers: stickers
        )
    }

    private func makeSticker(path: String, emoji: String, kind: StickerKind) -> PreparedSticker {
        PreparedSticker(id: UUID(), relativePath: path, emoji: emoji, kind: kind, byteCount: 1)
    }

    @discardableResult
    private func write(_ data: Data, to path: String) throws -> URL {
        let url = workspaceRoot.appendingPathComponent(path)
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try data.write(to: url)
        return url
    }

    private func relativePath(for url: URL) -> String {
        String(url.path.dropFirst(workspaceRoot.path.count + 1))
    }
}
