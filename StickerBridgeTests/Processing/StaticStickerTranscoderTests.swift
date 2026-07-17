import SDWebImage
import SDWebImageWebPCoder
import UIKit
import XCTest
@testable import StickerBridge

final class StaticStickerTranscoderTests: XCTestCase {
    func testTranscodesNonSquarePNGToBounded512PixelWebP() async throws {
        let sourceURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("png")
        defer { try? FileManager.default.removeItem(at: sourceURL) }

        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 960, height: 240))
        let sourceImage = renderer.image { context in
            UIColor.systemPurple.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 960, height: 240))
        }
        try XCTUnwrap(sourceImage.pngData()).write(to: sourceURL)

        let output = try await StaticStickerTranscoder().transcode(sourceURL)
        defer { try? FileManager.default.removeItem(at: output.url) }

        XCTAssertEqual(output.url.pathExtension, "webp")
        XCTAssertEqual(output.kind, .staticImage)
        XCTAssertLessThanOrEqual(output.byteCount, SignalStickerRules.maximumStickerBytes)

        let outputData = try Data(contentsOf: output.url)
        let decoded = try XCTUnwrap(SDImageWebPCoder.shared.decodedImage(with: outputData, options: nil))
        XCTAssertEqual(decoded.size.width, CGFloat(SignalStickerRules.canvasSide))
        XCTAssertEqual(decoded.size.height, CGFloat(SignalStickerRules.canvasSide))
    }
}
