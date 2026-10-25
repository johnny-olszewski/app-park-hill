import XCTest

/// Local build against local Supabase: staff browse all groups (IOS-025 AC4).
/// Start it first: `cd backend && supabase start && supabase db reset`.
final class LocalBrowseUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() {
        continueAfterFailure = false
        app = XCUIApplication()
    }

    override func tearDown() {
        if app.devToolsPill.exists, !app.signInEmailField.exists {
            app.signOutThroughDevTools()
        }
    }

    func testStaffBrowsesAndSearchesEveryGroup() throws {
        app.launchSignedOut(entry: app.signInEmailField)
        app.signInEmailField.tap()
        app.signInEmailField.typeText(try UITestData.email(of: "staff"))
        let password = app.secureTextFields["signIn.password"]
        password.tap()
        password.typeText(try UITestData.localPassword())
        app.buttons["signIn.submit"].tap()
        app.dismissSavePasswordPrompt()
        let tab = app.tabBars.buttons["Community"]
        XCTAssertTrue(tab.waitForExistence(timeout: 10))
        tab.tap()

        let browse = app.buttons["toolbar.browse_all_groups"]
        XCTAssertTrue(browse.waitForExistence(timeout: 5))
        browse.tap()
        let rows = app.buttons.matching(identifier: "groupRow")
        XCTAssertTrue(rows.firstMatch.waitForExistence(timeout: 10))
        XCTAssertGreaterThan(rows.count, 1)

        let search = app.searchFields.firstMatch
        search.tap()
        search.typeText("loma")
        XCTAssertEqual(rows.count, 1)
    }
}
