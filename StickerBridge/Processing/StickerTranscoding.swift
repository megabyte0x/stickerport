import Foundation

struct TranscodedStickerData: Sendable {
    let url: URL
    let kind: StickerKind
    let byteCount: Int
}

enum TranscodeFailure: LocalizedError, Equatable {
    case unreadableInput(URL)
    case unableToMeetByteLimit

    var errorDescription: String? {
        switch self {
        case .unreadableInput(let url):
            "StickerBridge could not read the image at \(url.lastPathComponent)."
        case .unableToMeetByteLimit:
            "StickerBridge could not make this image fit Signal’s 300 KiB sticker limit."
        }
    }
}

protocol StickerTranscoding: Sendable {
    func transcode(_ sourceURL: URL) async throws -> TranscodedStickerData
}
