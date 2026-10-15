import XCTest

/// Mock build: the production sign-in, with the persona and result chosen in
/// the mock menu (IOS-022).
final class MockSignInUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchSignedOut(entry: app.signInEmailField)
    }

    /// Opens the menu, taps a row and closes the menu.
    private func choose(_ identifier: String) {
        app.openDevToolsMenu()
        app.tapInDevToolsMenu(identifier)
        app.closeDevToolsMenu()
    }

    func testSignsInAsTheChosenPersonaWhateverIsTyped() {
        choose("mockSignIn.persona.admin")
        app.submitAnyCredentials()
        app.dismissSavePasswordPrompt()
        let user = app.staticTexts["placeholder.user"]
        XCTAssertTrue(user.waitForExistence(timeout: 5))
        XCTAssertEqual(user.label, "admin")
    }

    func testAnArmedRefusalShowsItsRecordedMessage() throws {
        let expected = try XCTUnwrap(UITestData.json("fixtures/sign_in.error.too_many_attempts")["message"] as? String)
        choose("mockSignIn.result.tooManyAttempts")
        XCTAssertEqual(app.devToolsPill.value as? String, "Failure armed")

        app.openDevToolsMenu()
        XCTAssertEqual(app.staticTexts["devTools.warning"].label, "Next sign-in will fail: Too many attempts")
        app.closeDevToolsMenu()

        app.submitAnyCredentials()
        let error = app.staticTexts["signIn.error"]
        XCTAssertTrue(error.waitForExistence(timeout: 5))
        XCTAssertEqual(error.label, expected)
    }

    func testNoConnectionShowsTheCannotConnectMessage() throws {
        let data = try XCTUnwrap(UITestData.json("fixtures/get_entry")["data"] as? [String: Any])
        let expected = try XCTUnwrap(data["cannot_connect_message"] as? String)
        choose("mockSignIn.result.noConnection")

        app.submitAnyCredentials()
        let notice = app.staticTexts["signIn.notice"]
        XCTAssertTrue(notice.waitForExistence(timeout: 5))
        XCTAssertEqual(notice.label, expected)
    }

    func testSwitchesPersonaWhileSignedIn() {
        app.submitAnyCredentials()
        app.dismissSavePasswordPrompt()
        let user = app.staticTexts["placeholder.user"]
        XCTAssertTrue(user.waitForExistence(timeout: 5))
        XCTAssertEqual(user.label, "attendee")

        choose("mockPersona.admin")
        XCTAssertTrue(user.waitForLabel("admin", timeout: 5), "now signed in as admin")
    }
}

private extension XCUIElement {
    func waitForLabel(_ label: String, timeout: TimeInterval) -> Bool {
        let expectation = XCTNSPredicateExpectation(predicate: NSPredicate(format: "label == %@", label), object: self)
        return XCTWaiter.wait(for: [expectation], timeout: timeout) == .completed
    }
}
