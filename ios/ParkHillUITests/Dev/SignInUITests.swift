import XCTest

/// Dev build against local Supabase (IOS-006 AC10). Start it first:
/// `cd backend && supabase start && supabase db reset`.
final class SignInUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() {
        continueAfterFailure = false
        app = XCUIApplication()
    }

    private var emailField: XCUIElement { app.textFields["signIn.email"] }
    private var passwordField: XCUIElement { app.secureTextFields["signIn.password"] }

    private func signIn(email: String, password: String) {
        emailField.tap()
        emailField.typeText(email)
        passwordField.tap()
        passwordField.typeText(password)
        app.buttons["signIn.submit"].tap()
    }

    func testSignInStaysSignedInAcrossRelaunchThenSignsOut() throws {
        let email = try UITestData.email(of: "attendee")
        app.launchSignedOut(entry: emailField)
        XCTAssertTrue(app.devToolsPill.exists)

        signIn(email: email, password: try UITestData.localPassword())
        app.dismissSavePasswordPrompt()
        XCTAssertEqual(app.signedInUser(), email)

        app.terminate()
        app.launch()
        XCTAssertTrue(app.devToolsPill.waitForExistence(timeout: 10))
        XCTAssertEqual(app.signedInUser(), email, "still signed in after relaunch")

        app.signOutThroughDevTools()

        app.terminate()
        app.launch()
        XCTAssertTrue(emailField.waitForExistence(timeout: 10), "relaunch after sign-out shows sign-in")
    }

    func testWrongPasswordShowsTheBackendMessage() throws {
        let expected = try XCTUnwrap(UITestData.json("mock_responses/sign_in.error")["message"] as? String)
        app.launchSignedOut(entry: emailField)

        signIn(email: try UITestData.email(of: "admin"), password: "not-the-password")

        let error = app.staticTexts["signIn.error"]
        XCTAssertTrue(error.waitForExistence(timeout: 10))
        XCTAssertEqual(error.label, expected)
    }
}
