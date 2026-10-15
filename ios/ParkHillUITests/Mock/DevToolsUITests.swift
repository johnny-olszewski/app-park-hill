import XCTest

/// Mock build: the dev tools pill and menu over the app (IOS-021).
final class DevToolsUITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    func testMenuShowsTheCurrentScreenAndTheAppStillTakesTouches() {
        let app = XCUIApplication()
        let attendee = app.buttons["personaPicker.attendee"]
        app.launchSignedOut(entry: attendee)

        app.openDevToolsMenu()
        app.buttons["devTools.currentScreen"].tap()
        let key = app.staticTexts["devTools.currentScreen.key"]
        XCTAssertTrue(key.waitForExistence(timeout: 5))
        XCTAssertEqual(key.label, "auth.sign_in.mock")
        XCTAssertTrue(app.staticTexts["devTools.currentScreen.data"].exists)

        app.navigationBars["Current screen"].buttons.element(boundBy: 0).tap()
        app.buttons["devTools.done"].tap()
        XCTAssertTrue(app.buttons["devTools.done"].waitForNonExistence(timeout: 5))

        attendee.tap()
        XCTAssertTrue(app.staticTexts["placeholder.user"].waitForExistence(timeout: 5), "touches reach the app under the pill's window")
        XCTAssertTrue(app.devToolsPill.exists, "the pill stays after signing in")
    }

    func testMenuSignsOut() {
        let app = XCUIApplication()
        let attendee = app.buttons["personaPicker.attendee"]
        app.launchSignedOut(entry: attendee)
        attendee.tap()
        XCTAssertTrue(app.staticTexts["placeholder.user"].waitForExistence(timeout: 5))

        app.openDevToolsMenu()
        let signOut = app.buttons["devTools.signOut"]
        // The menu opens at half height; Session is below the fold.
        for _ in 0..<3 where !signOut.isHittable {
            app.buttons["devTools.currentScreen"].swipeUp()
        }
        signOut.tap()
        XCTAssertTrue(attendee.waitForExistence(timeout: 5))
    }
}
