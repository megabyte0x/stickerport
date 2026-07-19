import AppKit
import SwiftUI
import XCTest
@testable import StickerBridgeMac

@MainActor
final class SignalTutorialViewTests: XCTestCase {
    func testSignalTutorialVideoCanBeHosted() {
        let hostingView = NSHostingView(
            rootView: SignalTutorialVideo()
        )
        hostingView.frame = NSRect(
            x: 0,
            y: 0,
            width: 640,
            height: 360
        )

        hostingView.layoutSubtreeIfNeeded()

        XCTAssertEqual(hostingView.frame.size.width, 640)
    }
}
