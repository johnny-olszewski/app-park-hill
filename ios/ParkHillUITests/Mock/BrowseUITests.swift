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
        let placeholder = try XCTUnwrap(data["search_placeholder"] as? String)
        openCommunity(as: "staff")

        XCTAssertTrue(browseButton.waitForExistence(timeout: 5))
        browseButton.tap()
        XCTAssertTrue(app.navigationBars[try XCTUnwrap(data["title"] as? String)].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["cover.close"].exists)
        XCTAssertGreaterThan(rows.count, 1, "the list draws the rows on screen, never counted in full")
        XCTAssertTrue(scrollTo(app.staticTexts["groupRow.badge.attention"]), "the leaderless group is flagged")

        let search = app.searchFields.firstMatch
        search.tap()
        search.typeText("hill")
        XCTAssertEqual(rows.count, 1)
        rows.firstMatch.tap()
        XCTAssertTrue(app.navigationBars["Mission Hills Group"].waitForExistence(timeout: 5), "the detail pushes inside the cover")
        app.navigationBars["Mission Hills Group"].buttons.firstMatch.tap()
        XCTAssertTrue(app.navigationBars[try XCTUnwrap(data["title"] as? String)].waitForExistence(timeout: 5), "back returns to browse")
        XCTAssertGreaterThan(rows.count, 1, "opening a group ended the search")
        XCTAssertTrue(isEmpty(app.searchFields.firstMatch, placeholder: placeholder))

        app.buttons["cover.close"].tap()
        XCTAssertTrue(app.navigationBars["Community"].waitForExistence(timeout: 5))
        browseButton.tap()
        XCTAssertTrue(rows.firstMatch.waitForExistence(timeout: 5))
        XCTAssertGreaterThan(rows.count, 1, "reopening starts with an empty search")
        XCTAssertTrue(isEmpty(app.searchFields.firstMatch, placeholder: placeholder))
    }

    /// Swipes up until `element` is on screen, at most a few times.
    private func scrollTo(_ element: XCUIElement) -> Bool {
        for _ in 0..<5 where !element.exists {
            app.swipeUp()
        }
        return element.exists
    }

    /// A search field shows its placeholder (or nothing) when empty. iOS 26
    /// collapses the search bar once the list scrolls, and a collapsed search
    /// holds no query.
    private func isEmpty(_ field: XCUIElement, placeholder: String) -> Bool {
        guard field.waitForExistence(timeout: 2) else { return true }
        let value = field.value as? String ?? ""
        return value.isEmpty || value == placeholder
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
