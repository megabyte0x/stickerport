import Foundation

enum SignalStickerRuleError: LocalizedError, Equatable {
    case invalidPackCount(Int)
    case oversizedSticker(Int)
    case animationTooLong(TimeInterval)
    case missingTitle
    case missingAuthor
    case invalidEmoji(String)

    var errorDescription: String? {
        switch self {
        case .invalidPackCount(let count):
            "Signal packs must contain 1–200 stickers; this pack has \(count)."
        case .oversizedSticker(let bytes):
            "Signal stickers must be at most 300 KiB; this file is \(bytes) bytes."
        case .animationTooLong(let duration):
            "Signal animations must be at most 3 seconds; this file is \(duration) seconds."
        case .missingTitle:
            "Enter a pack title."
        case .missingAuthor:
            "Enter an author."
        case .invalidEmoji(let value):
            "Choose exactly one emoji; “\(value)” is not valid."
        }
    }
}

enum SignalStickerRules {
    static let canvasSide = 512
    static let recommendedMargin = 16
    static let maximumStickerBytes = 300 * 1024
    static let maximumAnimationDuration: TimeInterval = 3
    static let maximumStickerCount = 200

    static func validatePackCount(_ count: Int) throws {
        guard (1...maximumStickerCount).contains(count) else {
            throw SignalStickerRuleError.invalidPackCount(count)
        }
    }

    static func validateByteCount(_ count: Int) throws {
        guard count <= maximumStickerBytes else {
            throw SignalStickerRuleError.oversizedSticker(count)
        }
    }

    static func preferredEmoji(from values: [String]) -> String {
        values.first(where: { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) ?? "🙂"
    }

    static func validateMetadata(title: String, author: String) throws {
        if title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            throw SignalStickerRuleError.missingTitle
        }
        if author.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            throw SignalStickerRuleError.missingAuthor
        }
    }

    static func validateEmoji(_ value: String) throws {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        let characters = Array(trimmed)
        guard characters.count == 1,
              characters[0].unicodeScalars.contains(where: {
                  $0.properties.isEmojiPresentation || $0.properties.generalCategory == .otherSymbol
              })
        else {
            throw SignalStickerRuleError.invalidEmoji(value)
        }
    }
}
