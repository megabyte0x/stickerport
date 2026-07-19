import XCTest

@MainActor
final class StickerBridgeMacUITests: XCTestCase {
    func testAppLaunchesAndPreparesAutomaticWhatsAppAccess() {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing"]
        app.launch()

        XCTAssertTrue(
            app.staticTexts["Prepare WhatsApp stickers for Signal"]
                .waitForExistence(timeout: 5)
        )
        XCTAssertTrue(
            app.staticTexts["Preparing WhatsApp access"].exists
        )
        XCTAssertFalse(app.buttons["Connect WhatsApp"].exists)
    }
}
