import Foundation
import ImageIO
import UniformTypeIdentifiers

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
        let supportedSources = urls.compactMap { Self.openValidatedSource(at: $0) }
        defer {
            supportedSources.forEach { source in
                if source.accessedSecurityScope {
                    source.url.stopAccessingSecurityScopedResource()
                }
            }
        }

        guard !supportedSources.isEmpty else {
            throw BasicImportFailure.noSupportedFiles
        }

        try SignalStickerRules.validatePackCount(supportedSources.count)

        let importDirectory = workspaceRoot
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
            .appendingPathComponent("input", isDirectory: true)
        try FileManager.default.createDirectory(at: importDirectory, withIntermediateDirectories: true)

        let stickers = try supportedSources.enumerated().map { index, source in
            let fileName = String(format: "%03d-%@", index + 1, source.url.lastPathComponent)
            let destinationURL = importDirectory.appendingPathComponent(fileName, isDirectory: false)

            try FileManager.default.copyItem(at: source.url, to: destinationURL)

            return SourceSticker(
                id: UUID(),
                relativePath: Self.relativePath(for: destinationURL, beneath: workspaceRoot),
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

    private static func openValidatedSource(at url: URL) -> ValidatedSource? {
        guard url.isFileURL, expectedType(for: url) != nil else {
            return nil
        }

        let accessedSecurityScope = url.startAccessingSecurityScopedResource()
        guard isRegularStaticImage(at: url) else {
            if accessedSecurityScope {
                url.stopAccessingSecurityScopedResource()
            }
            return nil
        }

        return ValidatedSource(url: url, accessedSecurityScope: accessedSecurityScope)
    }

    private static func isRegularStaticImage(at url: URL) -> Bool {
        guard
            let values = try? url.resourceValues(forKeys: [.isRegularFileKey]),
            values.isRegularFile == true,
            let expectedType = expectedType(for: url),
            let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil),
            let sourceType = CGImageSourceGetType(imageSource) as String?,
            sourceType == expectedType.identifier,
            CGImageSourceGetCount(imageSource) == 1,
            CGImageSourceCreateImageAtIndex(imageSource, 0, nil) != nil
        else {
            return false
        }

        return true
    }

    private static func expectedType(for url: URL) -> UTType? {
        switch url.pathExtension.lowercased() {
        case "png":
            .png
        case "webp":
            .webP
        default:
            nil
        }
    }

    private static func relativePath(for url: URL, beneath root: URL) -> String {
        url.standardizedFileURL.path.replacingOccurrences(
            of: root.standardizedFileURL.path + "/",
            with: ""
        )
    }

    private struct ValidatedSource {
        let url: URL
        let accessedSecurityScope: Bool
    }
}
