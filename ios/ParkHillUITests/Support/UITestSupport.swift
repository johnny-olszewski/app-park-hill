import XCTest

extension XCUIApplication {
    /// Launches and waits for the signed-out entry or the signed-in
    /// placeholder; signs out first when a previous run left a session.
    func launchSignedOut(entry: XCUIElement) {
        launch()
        let signOut = buttons["placeholder.signOut"]
        let deadline = Date().addingTimeInterval(15)
        while Date() < deadline {
            if entry.exists { return }
            if signOut.exists {
                signOut.tap()
                XCTAssertTrue(entry.waitForExistence(timeout: 10), "sign-out did not return to the entry screen")
                return
            }
            RunLoop.current.run(until: Date().addingTimeInterval(0.25))
        }
        XCTFail("neither the entry screen nor the signed-in placeholder appeared")
    }

    /// The dev tools pill at the top of every screen (debug builds).
    var devToolsPill: XCUIElement {
        descendants(matching: .any)["devTools.pill"]
    }

    /// Long-presses the pill and waits for the menu.
    func openDevToolsMenu() {
        XCTAssertTrue(devToolsPill.waitForExistence(timeout: 5), "no dev tools pill")
        devToolsPill.press(forDuration: 1)
        XCTAssertTrue(buttons["devTools.done"].waitForExistence(timeout: 5), "the dev tools menu did not open")
    }

    /// Taps a button in the open dev tools menu, scrolling down to it first.
    func tapInDevToolsMenu(_ identifier: String) {
        let button = buttons[identifier]
        for _ in 0..<4 where !(button.exists && button.isHittable) {
            swipeUp()
        }
        button.tap()
    }

    /// Closes the dev tools menu and waits for it to go.
    func closeDevToolsMenu() {
        buttons["devTools.done"].tap()
        XCTAssertTrue(buttons["devTools.done"].waitForNonExistence(timeout: 5), "the dev tools menu did not close")
    }

    /// The sign-in screen's email field, which every build shows when signed out.
    var signInEmailField: XCUIElement {
        textFields["signIn.email"]
    }

    /// Types any credentials and submits. In Mock the armed result decides
    /// what happens, not the credentials.
    func submitAnyCredentials() {
        signInEmailField.tap()
        signInEmailField.typeText("tester@example.com")
        let password = secureTextFields["signIn.password"]
        password.tap()
        password.typeText("anything")
        buttons["signIn.submit"].tap()
    }

    /// Dismisses the system's offer to save a password, if it appears.
    func dismissSavePasswordPrompt() {
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        for app in [self, springboard] where app.buttons["Not Now"].waitForExistence(timeout: 1) {
            app.buttons["Not Now"].tap()
        }
    }
}

/// Personas and the local password from the bundled
/// `contract/seed/dataset.json`, plus contract fixtures.
enum UITestData {
    private final class BundleToken {}

    private static var bundle: Bundle { Bundle(for: BundleToken.self) }

    static func json(_ path: String) throws -> [String: Any] {
        let url = try XCTUnwrap(bundle.url(forResource: path, withExtension: "json"))
        return try XCTUnwrap(JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [String: Any])
    }

    static func localPassword() throws -> String {
        try XCTUnwrap(json("seed/dataset")["local_password"] as? String)
    }

    static func email(of personaID: String) throws -> String {
        let personas = try XCTUnwrap(json("seed/dataset")["personas"] as? [[String: Any]])
        let persona = try XCTUnwrap(personas.first { $0["id"] as? String == personaID })
        return try XCTUnwrap(persona["email"] as? String)
    }
}
