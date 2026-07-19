import AVFoundation
import XCTest

final class SignalTutorialResourceTests: XCTestCase {
    func testSignalTutorialVideoIsBundledAndPlayable() async throws {
        let url = try XCTUnwrap(
            Bundle.main.url(
                forResource: "SignalStickerTutorial",
                withExtension: "mp4"
            )
        )
        let asset = AVURLAsset(url: url)

        let duration = try await asset.load(.duration)
        let tracks = try await asset.loadTracks(withMediaType: .video)

        XCTAssertGreaterThan(duration.seconds, 10)
        XCTAssertFalse(tracks.isEmpty)
    }
}
