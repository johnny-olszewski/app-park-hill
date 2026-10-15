import XCTest

/// Mock build: the persona picker signs in with no network (IOS-006 AC8).
final class PersonaPickerUITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    func testPersonaPickerSignsInAndSignsOut() {
        let app = XCUIApplication()
        let attendee = app.buttons["personaPicker.attendee"]
        app.launchSignedOut(entry: attendee)

        XCTAssertFalse(app.buttons["personaPicker.disabled"].exists, "only active personas are listed")
        XCTAssertTrue(app.devToolsPill.exists)

        attendee.tap()
        XCTAssertTrue(app.staticTexts["placeholder.user"].waitForExistence(timeout: 5))

        app.buttons["placeholder.signOut"].tap()
        XCTAssertTrue(attendee.waitForExistence(timeout: 5))
    }
}
