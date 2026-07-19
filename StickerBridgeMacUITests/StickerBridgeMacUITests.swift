import XCTest

@MainActor
final class StickerBridgeMacUITests: XCTestCase {
    func testAppLaunchesAndPreparesAutomaticWhatsAppAccess() {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing"]
        app.launch()

        XCTAssertTrue(
            app.staticTexts["StickerPort Header"]
                .waitForExistence(timeout: 5)
        )
        XCTAssertTrue(
            app.staticTexts["Preparing your sticker shelf"].exists
        )
        XCTAssertFalse(app.buttons["Connect WhatsApp"].exists)
    }

    func testReadyDesignUsesEmojiOnlyStickerGrid() {
        let app = XCUIApplication()
        app.launchArguments = [
            "--ui-testing",
            "--design-preview"
        ]
        app.launch()

        XCTAssertTrue(
            app.staticTexts["Sticker packs"]
                .waitForExistence(timeout: 5)
        )
        XCTAssertTrue(app.buttons["🐱 sticker"].exists)
        XCTAssertTrue(app.buttons["❤️ sticker"].exists)
        XCTAssertFalse(app.staticTexts["hidden-file-1.webp"].exists)
        XCTAssertTrue(app.buttons["Export for Signal"].isEnabled)
    }
}
