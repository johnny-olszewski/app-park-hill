import XCTest

/// Mock build: Browse all groups from Community home's toolbar (IOS-025 AC2,
/// AC4, AC5).
@MainActor
final class BrowseUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() {
        continueAfterFailure = false
        app = XCUIApplication()
    }

    private func openCommunity(as persona: String) {
        app.launchSignedOut(entry: app.signInEmailField)
        app.openDevToolsMenu()
        app.tapInDevToolsMenu("mockSignIn.persona.\(persona)")
        app.closeDevToolsMenu()
        app.submitAnyCredentials()
        app.dismissSavePasswordPrompt()
        let tab = app.tabBars.buttons["Community"]
        XCTAssertTrue(tab.waitForExistence(timeout: 10))
        tab.tap()
        XCTAssertTrue(app.navigationBars["Community"].waitForExistence(timeout: 5))
    }

    private var browseButton: XCUIElement { app.buttons["toolbar.browse_all_groups"] }
    private var rows: XCUIElementQuery { app.buttons.matching(identifier: "groupRow") }

    func testStaffBrowseSearchOpenAndCloseResetsTheSearch() throws {
        let data = try XCTUnwrap(UITestData.json("mock_responses/staff/get_screen.community.browse")["data"] as? [String: Any])
        let all = try XCTUnwrap(data["rows"] as? [[String: Any]])
        openCommunity(as: "staff")

        XCTAssertTrue(browseButton.waitForExistence(timeout: 5))
        browseButton.tap()
        XCTAssertTrue(app.navigationBars[try XCTUnwrap(data["title"] as? String)].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["cover.close"].exists)
        XCTAssertEqual(rows.count, all.count)
        XCTAssertTrue(app.staticTexts["groupRow.badge.attention"].exists, "the leaderless group is flagged")

        let search = app.searchFields.firstMatch
        search.tap()
        search.typeText("hill")
        XCTAssertEqual(rows.count, 1)
        rows.firstMatch.tap()
        XCTAssertTrue(app.navigationBars["Mission Hills Group"].waitForExistence(timeout: 5), "the detail pushes inside the cover")
        app.navigationBars["Mission Hills Group"].buttons.firstMatch.tap()
        XCTAssertTrue(app.navigationBars[try XCTUnwrap(data["title"] as? String)].waitForExistence(timeout: 5), "back returns to browse")
        XCTAssertEqual(rows.count, all.count, "opening a group ended the search")

        app.buttons["cover.close"].tap()
        XCTAssertTrue(app.navigationBars["Community"].waitForExistence(timeout: 5))
        browseButton.tap()
        XCTAssertTrue(rows.firstMatch.waitForExistence(timeout: 5))
        XCTAssertEqual(rows.count, all.count, "reopening starts with an empty search")
    }

    func testAdminSeesBrowseOnTheirGroup() {
        openCommunity(as: "admin")
        XCTAssertTrue(app.staticTexts["groupDetail.title"].waitForExistence(timeout: 5))
        XCTAssertTrue(browseButton.exists)
    }

    func testMemberOneHasNoBrowse() {
        openCommunity(as: "member_one")
        XCTAssertTrue(app.staticTexts["groupDetail.title"].waitForExistence(timeout: 5))
        XCTAssertFalse(browseButton.exists)
    }
}
