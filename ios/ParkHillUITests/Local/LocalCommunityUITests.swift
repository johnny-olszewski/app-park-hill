import XCTest

/// Local build against local Supabase: each persona's Community tab
/// (IOS-010 AC1, AC5). Start it first: `cd backend && supabase start && supabase db reset`.
final class LocalCommunityUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() {
        continueAfterFailure = false
        app = XCUIApplication()
    }

    private func openCommunity(as persona: String) throws {
        app.launchSignedOut(entry: app.signInEmailField)
        app.signInEmailField.tap()
        app.signInEmailField.typeText(try UITestData.email(of: persona))
        let password = app.secureTextFields["signIn.password"]
        password.tap()
        password.typeText(try UITestData.localPassword())
        app.buttons["signIn.submit"].tap()
        app.dismissSavePasswordPrompt()
        let tab = app.tabBars.buttons["Community"]
        XCTAssertTrue(tab.waitForExistence(timeout: 10))
        tab.tap()
        XCTAssertTrue(app.navigationBars["Community"].waitForExistence(timeout: 5))
    }

    override func tearDown() {
        if app.devToolsPill.exists, !app.signInEmailField.exists {
            app.signOutThroughDevTools()
        }
    }

    private func assertEmpty(_ persona: String) throws {
        try openCommunity(as: persona)
        XCTAssertTrue(app.staticTexts["emptyState.title"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["groupRow"].exists)
    }

    private func assertGroup(_ persona: String, _ title: String) throws {
        try openCommunity(as: persona)
        XCTAssertTrue(app.staticTexts["groupDetail.title"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["groupDetail.title"].label, title)
    }

    func testAttendee() throws { try assertEmpty("attendee") }
    func testStaff() throws { try assertEmpty("staff") }
    func testMemberOne() throws { try assertGroup("member_one", "Tuesday Night Group") }
    func testLeader() throws { try assertGroup("leader", "Tuesday Night Group") }
    func testAdmin() throws { try assertGroup("admin", "Mission Hills Group") }

    func testMemberTwo() throws {
        try openCommunity(as: "member_two")
        XCTAssertTrue(app.buttons["groupRow"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.buttons.matching(identifier: "groupRow").count, 2)
        app.buttons.matching(identifier: "groupRow").element(boundBy: 1).tap()
        XCTAssertTrue(app.navigationBars["Tuesday Night Group"].waitForExistence(timeout: 10))
    }
}
