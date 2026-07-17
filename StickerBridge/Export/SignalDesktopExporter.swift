import Foundation
import ZIPFoundation

enum SignalDesktopExportError: LocalizedError, Equatable {
    case invalidPackCount(Int)
    case missingTitle
    case missingAuthor
    case invalidEmoji(String)
    case coverStickerNotFound(UUID)
    case unsafeRelativePath(String)
    case sourceFileMissing(String)
    case sourceFileIsNotRegular(String)
    case unsupportedFileType(path: String, expectedExtension: String)
    case oversizedSticker(path: String, byteCount: Int)

    var errorDescription: String? {
        switch self {
        case .invalidPackCount(let count):
            "A Signal sticker pack must contain 1–200 stickers; this pack has \(count)."
        case .missingTitle:
            "Enter a pack title before exporting."
        case .missingAuthor:
            "Enter an author before exporting."
        case .invalidEmoji(let emoji):
            "Choose exactly one emoji for each sticker; “\(emoji)” is not valid."
        case .coverStickerNotFound:
            "Choose a cover sticker that belongs to this pack."
        case .unsafeRelativePath(let path):
            "The sticker path “\(path)” is outside this workspace. Move it into the workspace and try again."
        case .sourceFileMissing(let path):
            "The sticker file “\(path)” no longer exists. Reprocess the pack and try again."
        case .sourceFileIsNotRegular(let path):
            "The sticker path “\(path)” is not a file."
        case .unsupportedFileType(let path, let expectedExtension):
            "The sticker file “\(path)” must use the \(expectedExtension) extension for its sticker type."
        case .oversizedSticker(let path, let byteCount):
            "The sticker file “\(path)” is \(byteCount) bytes; Signal stickers must be at most 300 KiB."
        }
    }
}

struct SignalDesktopExporter {
    private static let maximumStickerBytes = 300 * 1024

    let workspaceRoot: URL
    private let makeArchive: (URL) throws -> Archive

    init(workspaceRoot: URL) {
        self.init(workspaceRoot: workspaceRoot, makeArchive: { url in
            try Archive(url: url, accessMode: .create)
        })
    }

    init(workspaceRoot: URL, makeArchive: @escaping (URL) throws -> Archive) {
        self.workspaceRoot = workspaceRoot.resolvingSymlinksInPath().standardizedFileURL
        self.makeArchive = makeArchive
    }

    func export(_ pack: PreparedPack) throws -> URL {
        let sources = try validate(pack)
        let exportsDirectory = workspaceRoot.appendingPathComponent("Exports", isDirectory: true)
        try FileManager.default.createDirectory(at: exportsDirectory, withIntermediateDirectories: true)

        let archiveDestination = try openNewArchive(in: exportsDirectory, packTitle: pack.title)
        let archiveURL = archiveDestination.url
        let archive = archiveDestination.archive
        let mediaNames = sources.indices.map { String(format: "sticker-%03d.%@", $0 + 1, sources[$0].extension) }

        for (index, source) in sources.enumerated() {
            try archive.addEntry(with: mediaNames[index], data: try Data(contentsOf: source.url))
        }

        let packJSON = try makePackJSON(pack: pack, mediaNames: mediaNames)
        try archive.addEntry(with: "pack.json", data: packJSON)
        try archive.addEntry(with: "emoji-manifest.html", data: makeEmojiManifest(pack: pack, mediaNames: mediaNames))
        try archive.addEntry(with: "README.txt", data: Data(readme.utf8))
        return archiveURL
    }

    private func validate(_ pack: PreparedPack) throws -> [ValidatedSource] {
        let title = pack.title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { throw SignalDesktopExportError.missingTitle }
        let author = pack.author.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !author.isEmpty else { throw SignalDesktopExportError.missingAuthor }
        guard (1...200).contains(pack.stickers.count) else {
            throw SignalDesktopExportError.invalidPackCount(pack.stickers.count)
        }
        guard pack.stickers.contains(where: { $0.id == pack.coverStickerID }) else {
            throw SignalDesktopExportError.coverStickerNotFound(pack.coverStickerID)
        }

        return try pack.stickers.map { sticker in
            try validate(sticker)
        }
    }

    private func validate(_ sticker: PreparedSticker) throws -> ValidatedSource {
        do {
            try SignalStickerRules.validateEmoji(sticker.emoji)
        } catch {
            throw SignalDesktopExportError.invalidEmoji(sticker.emoji)
        }
        let sourceURL = try resolvedWorkspaceFileURL(for: sticker.relativePath)
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: sourceURL.path) else {
            throw SignalDesktopExportError.sourceFileMissing(sticker.relativePath)
        }

        let values = try sourceURL.resourceValues(forKeys: [.isRegularFileKey, .fileSizeKey])
        guard values.isRegularFile == true else {
            throw SignalDesktopExportError.sourceFileIsNotRegular(sticker.relativePath)
        }

        let expectedExtension = "webp"
        guard sourceURL.pathExtension.lowercased() == expectedExtension else {
            throw SignalDesktopExportError.unsupportedFileType(
                path: sticker.relativePath,
                expectedExtension: ".\(expectedExtension)"
            )
        }

        let byteCount = values.fileSize ?? 0
        guard byteCount <= Self.maximumStickerBytes else {
            throw SignalDesktopExportError.oversizedSticker(path: sticker.relativePath, byteCount: byteCount)
        }
        return ValidatedSource(url: sourceURL, extension: expectedExtension)
    }

    private func resolvedWorkspaceFileURL(for relativePath: String) throws -> URL {
        let candidate = workspaceRoot
            .appendingPathComponent(relativePath)
            .resolvingSymlinksInPath()
            .standardizedFileURL
        let rootPath = workspaceRoot.path.hasSuffix("/") ? workspaceRoot.path : workspaceRoot.path + "/"
        guard candidate.path.hasPrefix(rootPath) else {
            throw SignalDesktopExportError.unsafeRelativePath(relativePath)
        }
        return candidate
    }

    private func openNewArchive(in exportsDirectory: URL, packTitle: String) throws -> (url: URL, archive: Archive) {
        let stem = archiveStem(for: packTitle)
        var suffix = 1
        while true {
            let filename = suffix == 1 ? "\(stem).zip" : "\(stem)-\(suffix).zip"
            let candidate = exportsDirectory.appendingPathComponent(filename)
            guard !FileManager.default.fileExists(atPath: candidate.path) else {
                suffix += 1
                continue
            }

            do {
                return (candidate, try makeArchive(candidate))
            } catch {
                guard isExistingDestinationError(error) else { throw error }
                suffix += 1
            }
        }
    }

    private func isExistingDestinationError(_ error: Error) -> Bool {
        let cocoaError = error as NSError
        return cocoaError.domain == NSCocoaErrorDomain &&
            cocoaError.code == CocoaError.Code.fileWriteFileExists.rawValue
    }

    private func archiveStem(for title: String) -> String {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_"))
        let stem = title.unicodeScalars.map { allowed.contains($0) ? String($0) : "-" }.joined()
        let compact = stem.replacingOccurrences(of: "--", with: "-")
            .trimmingCharacters(in: CharacterSet(charactersIn: "-"))
        return compact.isEmpty ? "signal-sticker-pack" : compact
    }

    private func makePackJSON(pack: PreparedPack, mediaNames: [String]) throws -> Data {
        let stickers = zip(pack.stickers, mediaNames).map { sticker, mediaName in
            PackJSON.Sticker(id: sticker.id.uuidString, emoji: sticker.emoji, file: mediaName, kind: sticker.kind.rawValue)
        }
        let coverFile = zip(pack.stickers, mediaNames).first(where: { $0.0.id == pack.coverStickerID })!.1
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(PackJSON(title: pack.title, author: pack.author, coverFile: coverFile, stickers: stickers))
    }

    private func makeEmojiManifest(pack: PreparedPack, mediaNames: [String]) -> Data {
        let rows = zip(pack.stickers, mediaNames).map { sticker, mediaName in
            "<tr><td>\(htmlEscape(mediaName))</td><td>\(htmlEscape(sticker.emoji))</td></tr>"
        }.joined(separator: "\n")
        let html = """
        <!doctype html>
        <html><head><meta charset="utf-8"><title>\(htmlEscape(pack.title))</title></head>
        <body><h1>\(htmlEscape(pack.title))</h1><p>Author: \(htmlEscape(pack.author))</p>
        <table><thead><tr><th>Sticker</th><th>Emoji</th></tr></thead><tbody>
        \(rows)
        </tbody></table></body></html>
        """
        return Data(html.utf8)
    }

    private func htmlEscape(_ value: String) -> String {
        value
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&#39;")
    }

    private let readme = """
    Signal Desktop StickerBridge handoff archive

    This ZIP contains prepared sticker media and metadata for Signal Desktop.
    It does not upload, install, or directly import stickers into Signal.
    """
}

private struct ValidatedSource {
    let url: URL
    let `extension`: String
}

private struct PackJSON: Encodable {
    struct Sticker: Encodable {
        let id: String
        let emoji: String
        let file: String
        let kind: String
    }

    let title: String
    let author: String
    let coverFile: String
    let stickers: [Sticker]
}

private extension Archive {
    func addEntry(with path: String, data: Data) throws {
        try addEntry(
            with: path,
            type: .file,
            uncompressedSize: Int64(data.count),
            compressionMethod: .deflate,
            provider: { position, size in
                data.subdata(in: Int(position)..<(Int(position) + size))
            }
        )
    }
}
