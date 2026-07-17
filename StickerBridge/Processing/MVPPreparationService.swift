import Foundation

enum MVPPreparationFailure: LocalizedError, Equatable {
    case unsupportedStickerKind(String)
    case unsafeSourcePath(String)
    case invalidCover

    var errorDescription: String? {
        switch self {
        case .unsupportedStickerKind(let path):
            "The MVP can prepare static PNG or WebP stickers only: \(path)."
        case .unsafeSourcePath(let path):
            "The sticker path is outside the local workspace: \(path)."
        case .invalidCover:
            "Choose a cover sticker that belongs to this pack."
        }
    }
}

struct MVPPreparationService: Sendable {
    let workspaceRoot: URL
    let transcoder: any StickerTranscoding

    init(
        workspaceRoot: URL,
        transcoder: any StickerTranscoding = StaticStickerTranscoder()
    ) {
        self.workspaceRoot = workspaceRoot.standardizedFileURL
        self.transcoder = transcoder
    }

    func prepare(_ draft: StickerPackDraft) async throws -> PreparedPack {
        try SignalStickerRules.validateMetadata(title: draft.title, author: draft.author)
        try SignalStickerRules.validatePackCount(draft.stickers.count)
        guard draft.stickers.contains(where: { $0.id == draft.coverStickerID }) else {
            throw MVPPreparationFailure.invalidCover
        }

        let preparedDirectory = workspaceRoot
            .appendingPathComponent(draft.id.uuidString, isDirectory: true)
            .appendingPathComponent("prepared", isDirectory: true)
        try FileManager.default.createDirectory(at: preparedDirectory, withIntermediateDirectories: true)

        var preparedStickers: [PreparedSticker] = []
        for (index, sticker) in draft.stickers.enumerated() {
            guard sticker.kind == .staticImage else {
                throw MVPPreparationFailure.unsupportedStickerKind(sticker.relativePath)
            }
            try SignalStickerRules.validateEmoji(sticker.emoji)

            let sourceURL = try workspaceURL(for: sticker.relativePath)
            let transcoded = try await transcoder.transcode(sourceURL)
            defer { try? FileManager.default.removeItem(at: transcoded.url) }

            let filename = String(format: "%03d.webp", index + 1)
            let outputURL = preparedDirectory.appendingPathComponent(filename, isDirectory: false)
            if FileManager.default.fileExists(atPath: outputURL.path) {
                try FileManager.default.removeItem(at: outputURL)
            }
            try FileManager.default.copyItem(at: transcoded.url, to: outputURL)

            preparedStickers.append(
                PreparedSticker(
                    id: sticker.id,
                    relativePath: relativePath(for: outputURL),
                    emoji: sticker.emoji,
                    kind: .staticImage,
                    byteCount: transcoded.byteCount
                )
            )
        }

        return PreparedPack(
            id: draft.id,
            title: draft.title,
            author: draft.author,
            coverStickerID: draft.coverStickerID,
            stickers: preparedStickers
        )
    }

    private func workspaceURL(for relativePath: String) throws -> URL {
        let candidate = workspaceRoot
            .appendingPathComponent(relativePath)
            .standardizedFileURL
        let rootPath = workspaceRoot.path.hasSuffix("/") ? workspaceRoot.path : workspaceRoot.path + "/"
        guard candidate.path.hasPrefix(rootPath) else {
            throw MVPPreparationFailure.unsafeSourcePath(relativePath)
        }
        return candidate
    }

    private func relativePath(for url: URL) -> String {
        url.standardizedFileURL.path.replacingOccurrences(
            of: workspaceRoot.path + "/",
            with: ""
        )
    }
}
