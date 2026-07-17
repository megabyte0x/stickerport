import XCTest

@MainActor
final class StickerBridgeUITests: XCTestCase {
    func testAppLaunches() {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(
            app.staticTexts["Prepare sticker files for Signal"].waitForExistence(timeout: 5)
        )
    }
}
