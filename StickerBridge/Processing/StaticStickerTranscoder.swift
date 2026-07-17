import Foundation
import SDWebImage
import SDWebImageWebPCoder
import UIKit

struct StaticStickerTranscoder: StickerTranscoding {
    private static let qualityAttempts: [Double] = [0.90, 0.80, 0.70, 0.60, 0.50, 0.40]

    func transcode(_ sourceURL: URL) async throws -> TranscodedStickerData {
        let sourceData: Data
        do {
            sourceData = try Data(contentsOf: sourceURL)
        } catch {
            throw TranscodeFailure.unreadableInput(sourceURL)
        }

        let decodingOptions: [SDImageCoderOption: Any] = [.decodeFirstFrameOnly: true]
        let sourceImage = SDImageWebPCoder.shared.decodedImage(
            with: sourceData,
            options: decodingOptions
        ) ?? SDImageIOCoder.shared.decodedImage(
            with: sourceData,
            options: decodingOptions
        )
        guard let sourceImage else {
            throw TranscodeFailure.unreadableInput(sourceURL)
        }

        let canvas = ImageCanvas.staticStickerCanvas(from: sourceImage)
        for quality in Self.qualityAttempts {
            guard let webPData = SDImageWebPCoder.shared.encodedData(
                with: canvas,
                format: .webP,
                options: [.encodeCompressionQuality: quality]
            ) else {
                continue
            }

            guard webPData.count <= SignalStickerRules.maximumStickerBytes else {
                continue
            }

            let destinationURL = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension("webp")
            do {
                try webPData.write(to: destinationURL, options: Data.WritingOptions.atomic)
            } catch {
                throw TranscodeFailure.unreadableInput(destinationURL)
            }
            return TranscodedStickerData(
                url: destinationURL,
                kind: .staticImage,
                byteCount: webPData.count
            )
        }

        throw TranscodeFailure.unableToMeetByteLimit
    }
}
