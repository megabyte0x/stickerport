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

    func testReadyDesignUsesStickerOnlyGrid() {
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
        XCTAssertTrue(app.buttons["Sticker 1"].exists)
        XCTAssertTrue(app.buttons["Sticker 3"].exists)
        XCTAssertFalse(app.staticTexts["🐱"].exists)
        XCTAssertFalse(app.staticTexts["❤️"].exists)
        XCTAssertFalse(app.staticTexts["hidden-file-1.webp"].exists)
        XCTAssertTrue(app.buttons["Export for Signal"].isEnabled)
    }

    func testSignalHandoffShowsAutoplayTutorialAndOpenAction() {
        let app = XCUIApplication()
        app.launchArguments = [
            "--ui-testing",
            "--design-preview",
            "--signal-tutorial-preview"
        ]
        app.launch()

        XCTAssertTrue(
            app.staticTexts["Your stickers are ready"]
                .waitForExistence(timeout: 5)
        )
        XCTAssertTrue(
            app.images["Signal Tutorial Video"].exists
        )
        XCTAssertTrue(app.buttons["Replay Signal Tutorial"].exists)
        XCTAssertTrue(app.buttons["Open Signal Desktop"].exists)
        XCTAssertTrue(app.buttons["Reveal Stickers Again"].exists)
    }
}
