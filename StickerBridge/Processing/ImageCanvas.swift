import UIKit

enum ImageCanvas {
    static func staticStickerCanvas(from image: UIImage) -> UIImage {
        let side = CGFloat(SignalStickerRules.canvasSide)
        let margin = CGFloat(SignalStickerRules.recommendedMargin)
        let availableSide = side - (margin * 2)
        let sourceSize = image.size

        guard sourceSize.width > 0, sourceSize.height > 0 else {
            return image
        }

        let scale = min(availableSide / sourceSize.width, availableSide / sourceSize.height)
        let drawSize = CGSize(width: sourceSize.width * scale, height: sourceSize.height * scale)
        let drawRect = CGRect(
            x: (side - drawSize.width) / 2,
            y: (side - drawSize.height) / 2,
            width: drawSize.width,
            height: drawSize.height
        )
        let format = UIGraphicsImageRendererFormat()
        format.opaque = false
        format.scale = 1

        return UIGraphicsImageRenderer(size: CGSize(width: side, height: side), format: format).image { _ in
            image.draw(in: drawRect)
        }
    }
}
