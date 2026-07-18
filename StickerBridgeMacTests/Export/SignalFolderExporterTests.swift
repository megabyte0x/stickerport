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

    func testRejectsOneFrameAnimatedWebPContainer() throws {
        let destination = try makeDirectory()
        defer { try? FileManager.default.removeItem(at: destination) }
        let twoFrameAnimated = try XCTUnwrap(
            SDImageWebPCoder.shared.encodedData(
                with: [
                    SDImageFrame(
                        image: makeImage(color: .purple, side: 512),
                        duration: 0.2
                    ),
                    SDImageFrame(
                        image: makeImage(color: .orange, side: 512),
                        duration: 0.2
                    )
                ],
                loopCount: 0,
                format: .webP,
                options: [.encodeCompressionQuality: 0.8]
            )
        )
        let animated = try oneFrameAnimatedWebP(
            from: twoFrameAnimated
        )
        XCTAssertTrue(hasRIFFChunk("ANIM", in: animated))
        XCTAssertEqual(riffChunkCount("ANMF", in: animated), 1)
        let sticker = MacWhatsAppSticker(
            id: 100,
            order: 0,
            relativePath: "pack/one-frame-animated.webp",
            emoji: "🙂",
            data: animated
        )
        let pack = MacWhatsAppPack(
            id: 10,
            title: "One Frame Animated",
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
                .animatedUnsupported("pack/one-frame-animated.webp")
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

    private func hasRIFFChunk(_ name: String, in data: Data) -> Bool {
        riffChunkCount(name, in: data) > 0
    }

    private func riffChunkCount(
        _ name: String,
        in data: Data
    ) -> Int {
        let bytes = [UInt8](data)
        guard bytes.count >= 12 else {
            return 0
        }
        var offset = 12
        var count = 0
        while offset <= bytes.count - 8 {
            let chunkName = String(
                bytes: bytes[offset..<(offset + 4)],
                encoding: .ascii
            )
            let size = Int(bytes[offset + 4])
                | Int(bytes[offset + 5]) << 8
                | Int(bytes[offset + 6]) << 16
                | Int(bytes[offset + 7]) << 24
            if chunkName == name {
                count += 1
            }
            let payloadStart = offset + 8
            guard size <= bytes.count - payloadStart else {
                return count
            }
            offset = payloadStart + size + (size & 1)
        }
        return count
    }

    private func oneFrameAnimatedWebP(
        from data: Data
    ) throws -> Data {
        let bytes = [UInt8](data)
        guard bytes.count >= 12,
              String(bytes: bytes[0..<4], encoding: .ascii) == "RIFF",
              String(bytes: bytes[8..<12], encoding: .ascii) == "WEBP" else {
            throw CocoaError(.fileReadCorruptFile)
        }
        var output = Array(bytes[0..<12])
        var offset = 12
        var keptAnimationFrame = false
        while offset <= bytes.count - 8 {
            let chunkName = String(
                bytes: bytes[offset..<(offset + 4)],
                encoding: .ascii
            )
            let size = Int(bytes[offset + 4])
                | Int(bytes[offset + 5]) << 8
                | Int(bytes[offset + 6]) << 16
                | Int(bytes[offset + 7]) << 24
            let payloadStart = offset + 8
            guard size <= bytes.count - payloadStart else {
                throw CocoaError(.fileReadCorruptFile)
            }
            let end = payloadStart + size + (size & 1)
            guard end <= bytes.count else {
                throw CocoaError(.fileReadCorruptFile)
            }
            if chunkName != "ANMF" || !keptAnimationFrame {
                output.append(contentsOf: bytes[offset..<end])
                if chunkName == "ANMF" {
                    keptAnimationFrame = true
                }
            }
            offset = end
        }
        guard keptAnimationFrame else {
            throw CocoaError(.fileReadCorruptFile)
        }
        let riffSize = UInt32(output.count - 8)
        output[4] = UInt8(truncatingIfNeeded: riffSize)
        output[5] = UInt8(truncatingIfNeeded: riffSize >> 8)
        output[6] = UInt8(truncatingIfNeeded: riffSize >> 16)
        output[7] = UInt8(truncatingIfNeeded: riffSize >> 24)
        return Data(output)
    }
}
