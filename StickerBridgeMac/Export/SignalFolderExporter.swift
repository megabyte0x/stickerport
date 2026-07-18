import Foundation
import SDWebImage
import SDWebImageWebPCoder

enum SignalFolderExportError: LocalizedError, Equatable {
    case noSelection
    case tooManyStickers(Int)
    case invalidWebP(String)
    case animatedUnsupported(String)
    case wrongSize(String)
    case oversized(String)

    var errorDescription: String? {
        switch self {
        case .noSelection:
            "Select at least one sticker."
        case .tooManyStickers(let count):
            "Signal packs support at most 200 stickers; \(count) are selected."
        case .invalidWebP(let path):
            "The sticker is not a valid WebP file: \(path)"
        case .animatedUnsupported(let path):
            "Animated stickers are not supported in the basic MVP: \(path)"
        case .wrongSize(let path):
            "The sticker is not 512 by 512 pixels: \(path)"
        case .oversized(let path):
            "The sticker is larger than Signal’s 300 KiB limit: \(path)"
        }
    }
}

protocol SignalFolderExporting: Sendable {
    func export(
        pack: MacWhatsAppPack,
        selectedStickerIDs: Set<Int64>,
        to parentURL: URL
    ) throws -> SignalFolderExport
}

struct SignalFolderExporter: SignalFolderExporting {
    static let maximumStickerBytes = SignalStickerRules.maximumStickerBytes

    func export(
        pack: MacWhatsAppPack,
        selectedStickerIDs: Set<Int64>,
        to parentURL: URL
    ) throws -> SignalFolderExport {
        let selected = pack.stickers.filter {
            selectedStickerIDs.contains($0.id)
        }
        guard !selected.isEmpty else {
            throw SignalFolderExportError.noSelection
        }
        guard selected.count <= SignalStickerRules.maximumStickerCount else {
            throw SignalFolderExportError.tooManyStickers(selected.count)
        }

        let validated = try selected.map {
            ($0, try validatedStaticWebP($0))
        }
        let started = parentURL.startAccessingSecurityScopedResource()
        defer {
            if started {
                parentURL.stopAccessingSecurityScopedResource()
            }
        }

        let finalURL = uniqueOutputURL(parent: parentURL, title: pack.title)
        let temporaryURL = parentURL.appendingPathComponent(
            ".StickerBridge-\(UUID().uuidString)",
            isDirectory: true
        )
        let temporaryStickers = temporaryURL.appendingPathComponent(
            "Stickers",
            isDirectory: true
        )
        try FileManager.default.createDirectory(
            at: temporaryStickers,
            withIntermediateDirectories: true
        )

        do {
            var emojiLines: [String] = []
            for (index, item) in validated.enumerated() {
                let filename = String(format: "%03d.webp", index + 1)
                try item.1.write(
                    to: temporaryStickers.appendingPathComponent(filename),
                    options: .atomic
                )
                emojiLines.append("\(filename)\t\(item.0.emoji)")
            }
            try Data((emojiLines.joined(separator: "\n") + "\n").utf8).write(
                to: temporaryURL.appendingPathComponent("emoji-reference.txt"),
                options: .atomic
            )
            try Data(readme.utf8).write(
                to: temporaryURL.appendingPathComponent("README.txt"),
                options: .atomic
            )
            try FileManager.default.moveItem(at: temporaryURL, to: finalURL)
        } catch {
            try? FileManager.default.removeItem(at: temporaryURL)
            throw error
        }

        return SignalFolderExport(
            rootURL: finalURL,
            stickersURL: finalURL.appendingPathComponent(
                "Stickers",
                isDirectory: true
            )
        )
    }

    private func validatedStaticWebP(
        _ sticker: MacWhatsAppSticker
    ) throws -> Data {
        guard sticker.data.count <= Self.maximumStickerBytes else {
            throw SignalFolderExportError.oversized(sticker.relativePath)
        }
        if let animated = SDImageWebPCoder(
            animatedImageData: sticker.data,
            options: nil
        ), animated.animatedImageFrameCount > 1 {
            throw SignalFolderExportError.animatedUnsupported(
                sticker.relativePath
            )
        }
        guard let image = SDImageWebPCoder.shared.decodedImage(
            with: sticker.data,
            options: [.decodeFirstFrameOnly: true]
        ) else {
            throw SignalFolderExportError.invalidWebP(sticker.relativePath)
        }
        guard Int(image.size.width) == SignalStickerRules.canvasSide,
              Int(image.size.height) == SignalStickerRules.canvasSide else {
            throw SignalFolderExportError.wrongSize(sticker.relativePath)
        }
        return sticker.data
    }

    private func uniqueOutputURL(parent: URL, title: String) -> URL {
        let stem = "StickerBridge - \(safeName(title))"
        var suffix = 1
        while true {
            let name = suffix == 1 ? stem : "\(stem) \(suffix)"
            let candidate = parent.appendingPathComponent(
                name,
                isDirectory: true
            )
            if !FileManager.default.fileExists(atPath: candidate.path) {
                return candidate
            }
            suffix += 1
        }
    }

    private func safeName(_ value: String) -> String {
        let invalid = CharacterSet(charactersIn: "/:\\")
            .union(.controlCharacters)
        let cleaned = value.components(separatedBy: invalid)
            .joined(separator: "-")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return cleaned.isEmpty ? "WhatsApp Stickers" : cleaned
    }

    private var readme: String {
        """
        Signal Desktop steps

        1. Open linked Signal Desktop.
        2. Choose File > Create/Upload Sticker Pack.
        3. Open the Stickers folder and press Command-A.
        4. Assign the emoji from emoji-reference.txt.
        5. Enter title and author, upload, and install.

        StickerBridge does not upload or install the pack.
        """
    }
}
