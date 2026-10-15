import XCTest

/// Mock build: the dev tools pill and menu over the app (IOS-021).
final class DevToolsUITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    func testMenuShowsTheCurrentScreenAndTheAppStillTakesTouches() {
        let app = XCUIApplication()
        app.launchSignedOut(entry: app.signInEmailField)

        app.openDevToolsMenu()
        app.buttons["devTools.currentScreen"].tap()
        let key = app.staticTexts["devTools.currentScreen.key"]
        XCTAssertTrue(key.waitForExistence(timeout: 5))
        XCTAssertEqual(key.label, "auth.sign_in")
        XCTAssertTrue(app.staticTexts["devTools.currentScreen.data"].exists)

        app.navigationBars["Current screen"].buttons.element(boundBy: 0).tap()
        app.buttons["devTools.done"].tap()
        XCTAssertTrue(app.buttons["devTools.done"].waitForNonExistence(timeout: 5))

        app.submitAnyCredentials()
        app.dismissSavePasswordPrompt()
        XCTAssertTrue(app.staticTexts["placeholder.user"].waitForExistence(timeout: 5), "touches reach the app under the pill's window")
        XCTAssertTrue(app.devToolsPill.exists, "the pill stays after signing in")
    }

    func testMenuSignsOut() {
        let app = XCUIApplication()
        app.launchSignedOut(entry: app.signInEmailField)
        app.submitAnyCredentials()
        app.dismissSavePasswordPrompt()
        XCTAssertTrue(app.staticTexts["placeholder.user"].waitForExistence(timeout: 5))

        app.openDevToolsMenu()
        app.buttons["devTools.signOut"].tap()
        XCTAssertTrue(app.signInEmailField.waitForExistence(timeout: 5))
    }
}
