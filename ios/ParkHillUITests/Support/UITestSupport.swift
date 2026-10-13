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
