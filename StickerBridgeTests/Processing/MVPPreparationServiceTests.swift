import Foundation
import XCTest
@testable import StickerBridge

final class MVPPreparationServiceTests: XCTestCase {
    func testPreparesOrderedStaticFilesForExport() async throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)

        let first = SourceSticker(
            id: UUID(), relativePath: "input/one.png", emoji: "1️⃣",
            accessibilityText: nil, kind: .staticImage
        )
        let second = SourceSticker(
            id: UUID(), relativePath: "input/two.webp", emoji: "🙂",
            accessibilityText: nil, kind: .staticImage
        )
        let draft = StickerPackDraft(
            id: UUID(), title: "MVP", author: "Me", coverStickerID: first.id,
            stickers: [first, second], createdAt: .now
        )
        let service = MVPPreparationService(workspaceRoot: root, transcoder: StubTranscoder())

        let prepared = try await service.prepare(draft)

        XCTAssertEqual(prepared.stickers.map(\.id), [first.id, second.id])
        XCTAssertEqual(prepared.stickers.map(\.relativePath), [
            "\(draft.id.uuidString)/prepared/001.webp",
            "\(draft.id.uuidString)/prepared/002.webp"
        ])
        XCTAssertTrue(FileManager.default.fileExists(
            atPath: root.appendingPathComponent(prepared.stickers[0].relativePath).path
        ))
    }
}

private struct StubTranscoder: StickerTranscoding {
    func transcode(_ sourceURL: URL) async throws -> TranscodedStickerData {
        let output = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("webp")
        try Data("webp".utf8).write(to: output)
        return TranscodedStickerData(url: output, kind: .staticImage, byteCount: 4)
    }
}
