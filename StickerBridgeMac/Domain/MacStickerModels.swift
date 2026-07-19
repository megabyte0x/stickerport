import Foundation

struct MacWhatsAppSticker: Identifiable, Equatable, Sendable {
    let id: Int64
    let order: Int
    let relativePath: String
    let emoji: String
    let data: Data
}

enum MacStickerCategory: String, Equatable, Sendable {
    case stickerPacks
    case favorites
}

struct MacWhatsAppPack: Identifiable, Equatable, Sendable {
    static let favoritesID: Int64 = -1
    static let combinedExportID: Int64 = -2

    let id: Int64
    let category: MacStickerCategory
    let title: String
    let author: String
    let stickers: [MacWhatsAppSticker]

    init(
        id: Int64,
        category: MacStickerCategory = .stickerPacks,
        title: String,
        author: String,
        stickers: [MacWhatsAppSticker]
    ) {
        self.id = id
        self.category = category
        self.title = title
        self.author = author
        self.stickers = stickers
    }
}

struct SignalFolderExport: Equatable, Sendable {
    let rootURL: URL
    let stickersURL: URL
}

enum WhatsAppMVPError: LocalizedError, Equatable {
    case unexpectedContainer(expectedPath: String)
    case missingDatabase
    case missingStickerDirectory
    case whatsappIsRunning
    case uncheckpointedWriteAheadLog
    case sourceChangedDuringRead
    case missingTable(String)
    case missingColumn(table: String, column: String)
    case unsupportedSchema(String)
    case noLocalPacks
    case sqlite(String)

    var errorDescription: String? {
        switch self {
        case .unexpectedContainer(let expectedPath):
            "Choose the current user’s WhatsApp shared container exactly: \(expectedPath)"
        case .missingDatabase:
            "The selected WhatsApp folder does not contain Sticker.sqlite."
        case .missingStickerDirectory:
            "The selected WhatsApp folder does not contain a stickers directory."
        case .whatsappIsRunning:
            "Quit WhatsApp completely before importing stickers, then try again."
        case .uncheckpointedWriteAheadLog:
            "WhatsApp still has uncheckpointed sticker changes. Quit WhatsApp completely and wait for it to finish saving, then try again."
        case .sourceChangedDuringRead:
            "WhatsApp sticker data changed while it was being read. Quit WhatsApp completely and try again."
        case .missingTable(let table):
            "This WhatsApp version is not supported by the MVP. Missing table: \(table)."
        case .missingColumn(let table, let column):
            "This WhatsApp version is not supported by the MVP. Missing \(table).\(column)."
        case .unsupportedSchema(let detail):
            "This WhatsApp version is not supported by the MVP. \(detail)"
        case .noLocalPacks:
            "No locally stored WhatsApp sticker packs or Favorites were found."
        case .sqlite(let message):
            "WhatsApp sticker metadata could not be read: \(message)"
        }
    }
}
