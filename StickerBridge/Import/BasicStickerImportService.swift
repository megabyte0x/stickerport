import Foundation

enum BasicImportFailure: LocalizedError, Equatable {
    case noSupportedFiles

    var errorDescription: String? {
        switch self {
        case .noSupportedFiles:
            "Choose at least one PNG or WebP sticker file."
        }
    }
}

struct BasicStickerImportService: Sendable {
    let workspaceRoot: URL

    func importFiles(_ urls: [URL], defaultAuthor: String) async throws -> StickerPackDraft {
        let supportedURLs = urls.filter { url in
            switch url.pathExtension.lowercased() {
            case "png", "webp":
                true
            default:
                false
            }
        }

        guard !supportedURLs.isEmpty else {
            throw BasicImportFailure.noSupportedFiles
        }

        try SignalStickerRules.validatePackCount(supportedURLs.count)

        let importDirectory = workspaceRoot
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
            .appendingPathComponent("input", isDirectory: true)
        try FileManager.default.createDirectory(at: importDirectory, withIntermediateDirectories: true)

        let stickers = try supportedURLs.enumerated().map { index, sourceURL in
            let fileName = String(format: "%03d-%@", index + 1, sourceURL.lastPathComponent)
            let destinationURL = importDirectory.appendingPathComponent(fileName, isDirectory: false)

            let accessedSecurityScope = sourceURL.startAccessingSecurityScopedResource()
            defer {
                if accessedSecurityScope {
                    sourceURL.stopAccessingSecurityScopedResource()
                }
            }

            try FileManager.default.copyItem(at: sourceURL, to: destinationURL)

            return SourceSticker(
                id: UUID(),
                relativePath: destinationURL.path(percentEncoded: false)
                    .replacingOccurrences(of: workspaceRoot.path(percentEncoded: false) + "/", with: ""),
                emoji: "🙂",
                accessibilityText: nil,
                kind: .staticImage
            )
        }

        guard let firstSticker = stickers.first else {
            throw BasicImportFailure.noSupportedFiles
        }

        return StickerPackDraft(
            id: UUID(),
            title: "Imported Stickers",
            author: defaultAuthor,
            coverStickerID: firstSticker.id,
            stickers: stickers,
            createdAt: Date()
        )
    }
}
