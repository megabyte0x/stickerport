import Foundation

enum StickerKind: String, Codable, Sendable {
    case staticImage
}

struct SourceSticker: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    var relativePath: String
    var emoji: String
    var accessibilityText: String?
    var kind: StickerKind
}

struct StickerPackDraft: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    var title: String
    var author: String
    var coverStickerID: UUID
    var stickers: [SourceSticker]
    let createdAt: Date
}

struct PreparedSticker: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    let relativePath: String
    let emoji: String
    let kind: StickerKind
    let byteCount: Int
}

struct PreparedPack: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    let title: String
    let author: String
    let coverStickerID: UUID
    let stickers: [PreparedSticker]
}
