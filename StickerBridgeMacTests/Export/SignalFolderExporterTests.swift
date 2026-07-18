import AppKit
import SDWebImage
import SDWebImageWebPCoder
import XCTest
@testable import StickerBridgeMac

@MainActor
final class SignalFolderExporterTests: XCTestCase {
    func testExportsSelectedStaticWebPBytesIntoImageOnlyDirectory() throws {
        let destination = try makeDirectory()
        defer { try? FileManager.default.removeItem(at: destination) }
        let firstData = try makeStaticWebP(color: .red, side: 512)
        let secondData = try makeStaticWebP(color: .blue, side: 512)
        let pack = MacWhatsAppPack(
            id: 10,
            title: "Fixture Pack",
            author: "Fixture Publisher",
            stickers: [
                MacWhatsAppSticker(
                    id: 100,
                    order: 0,
                    relativePath: "pack/one.webp",
                    emoji: "🙂",
                    data: firstData
                ),
                MacWhatsAppSticker(
                    id: 101,
                    order: 1,
                    relativePath: "pack/two.webp",
                    emoji: "😂",
                    data: secondData
                )
            ]
        )

        let result = try SignalFolderExporter().export(
            pack: pack,
            selectedStickerIDs: [101],
            to: destination
        )

        XCTAssertEqual(
            try FileManager.default
                .contentsOfDirectory(atPath: result.stickersURL.path)
                .sorted(),
            ["001.webp"]
        )
        XCTAssertEqual(
            try Data(
                contentsOf: result.stickersURL
                    .appendingPathComponent("001.webp")
            ),
            secondData
        )
        XCTAssertTrue(
            FileManager.default.fileExists(
                atPath: result.rootURL
                    .appendingPathComponent("emoji-reference.txt")
                    .path
            )
        )
    }

    func testRejectsAnimatedWebPInStaticMVP() throws {
        let destination = try makeDirectory()
        defer { try? FileManager.default.removeItem(at: destination) }
        let frames = [
            SDImageFrame(
                image: makeImage(color: .red, side: 512),
                duration: 0.2
            ),
            SDImageFrame(
                image: makeImage(color: .blue, side: 512),
                duration: 0.2
            )
        ]
        let animated = try XCTUnwrap(
            SDImageWebPCoder.shared.encodedData(
                with: frames,
                loopCount: 0,
                format: .webP,
                options: [.encodeCompressionQuality: 0.8]
            )
        )
        let sticker = MacWhatsAppSticker(
            id: 100,
            order: 0,
            relativePath: "pack/animated.webp",
            emoji: "🙂",
            data: animated
        )
        let pack = MacWhatsAppPack(
            id: 10,
            title: "Animated",
            author: "Fixture",
            stickers: [sticker]
        )

        XCTAssertThrowsError(
            try SignalFolderExporter().export(
                pack: pack,
                selectedStickerIDs: [sticker.id],
                to: destination
            )
        ) {
            XCTAssertEqual(
                $0 as? SignalFolderExportError,
                .animatedUnsupported("pack/animated.webp")
            )
        }
    }

    func testRejectsMoreThanSignalByteLimit() throws {
        let destination = try makeDirectory()
        defer { try? FileManager.default.removeItem(at: destination) }
        let sticker = MacWhatsAppSticker(
            id: 100,
            order: 0,
            relativePath: "pack/large.webp",
            emoji: "🙂",
            data: Data(
                repeating: 0,
                count: SignalFolderExporter.maximumStickerBytes + 1
            )
        )
        let pack = MacWhatsAppPack(
            id: 10,
            title: "Large",
            author: "Fixture",
            stickers: [sticker]
        )

        XCTAssertThrowsError(
            try SignalFolderExporter().export(
                pack: pack,
                selectedStickerIDs: [sticker.id],
                to: destination
            )
        ) {
            XCTAssertEqual(
                $0 as? SignalFolderExportError,
                .oversized("pack/large.webp")
            )
        }
    }

    private func makeDirectory() throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(
            at: url,
            withIntermediateDirectories: true
        )
        return url
    }

    private func makeStaticWebP(
        color: NSColor,
        side: CGFloat
    ) throws -> Data {
        try XCTUnwrap(
            SDImageWebPCoder.shared.encodedData(
                with: makeImage(color: color, side: side),
                format: .webP,
                options: [.encodeCompressionQuality: 0.8]
            )
        )
    }

    private func makeImage(
        color: NSColor,
        side: CGFloat
    ) -> NSImage {
        let bitmap = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: Int(side),
            pixelsHigh: Int(side),
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        )!
        let context = NSGraphicsContext(bitmapImageRep: bitmap)!
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = context
        color.setFill()
        NSBezierPath(
            rect: NSRect(x: 0, y: 0, width: side, height: side)
        ).fill()
        NSGraphicsContext.restoreGraphicsState()

        let image = NSImage(size: NSSize(width: side, height: side))
        image.addRepresentation(bitmap)
        return image
    }
}
