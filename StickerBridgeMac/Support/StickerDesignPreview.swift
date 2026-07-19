#if DEBUG
import AppKit
import Foundation

enum StickerDesignPreview {
    static func makeSources() -> [MacWhatsAppPack] {
        [
            makePack(
                id: 10,
                title: "Tiny Joys",
                emojis: ["🐱", "⭐️", "❤️", "🌈", "🌿", "🍞"]
            ),
            makePack(
                id: 20,
                title: "Daily Reactions",
                emojis: ["😂", "🥹", "🫶", "😴", "🎉", "🤝"]
            ),
            makePack(
                id: MacWhatsAppPack.favoritesID,
                category: .favorites,
                title: "Favorites",
                emojis: ["✨", "💛", "🚀", "🌸"]
            )
        ]
    }

    static let selectedStickerIDs: Set<Int64> = [1, 3, 8, 14]

    private static func makePack(
        id: Int64,
        category: MacStickerCategory = .stickerPacks,
        title: String,
        emojis: [String]
    ) -> MacWhatsAppPack {
        MacWhatsAppPack(
            id: id,
            category: category,
            title: title,
            author: "StickerPort",
            stickers: emojis.enumerated().map { offset, emoji in
                let stickerID = id == MacWhatsAppPack.favoritesID
                    ? Int64(13 + offset)
                    : Int64((id / 10 - 1) * 6) + Int64(offset + 1)
                return MacWhatsAppSticker(
                    id: stickerID,
                    order: offset,
                    relativePath: "hidden-file-\(stickerID).webp",
                    emoji: emoji,
                    data: makeStickerImage(emoji: emoji, index: offset)
                )
            }
        )
    }

    private static func makeStickerImage(
        emoji: String,
        index: Int
    ) -> Data {
        let size = NSSize(width: 160, height: 160)
        let image = NSImage(size: size)
        image.lockFocus()

        let palette: [NSColor] = [
            NSColor(
                red: 1.00,
                green: 0.86,
                blue: 0.78,
                alpha: 1
            ),
            NSColor(
                red: 0.80,
                green: 0.94,
                blue: 0.87,
                alpha: 1
            ),
            NSColor(
                red: 0.84,
                green: 0.86,
                blue: 1.00,
                alpha: 1
            )
        ]
        palette[index % palette.count].setFill()
        NSBezierPath(
            roundedRect: NSRect(
                x: 8,
                y: 8,
                width: 144,
                height: 144
            ),
            xRadius: 36,
            yRadius: 36
        )
        .fill()

        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 70)
        ]
        let attributedEmoji = NSAttributedString(
            string: emoji,
            attributes: attributes
        )
        let textSize = attributedEmoji.size()
        attributedEmoji.draw(
            at: NSPoint(
                x: (size.width - textSize.width) / 2,
                y: (size.height - textSize.height) / 2
            )
        )

        image.unlockFocus()

        guard let tiff = image.tiffRepresentation,
              let representation = NSBitmapImageRep(data: tiff),
              let png = representation.representation(
                using: .png,
                properties: [:]
              ) else {
            return Data()
        }
        return png
    }
}
#endif
