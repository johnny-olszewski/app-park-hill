import XCTest

/// Mock build: Leave and swipe to remove, with the backend's confirmation
/// (IOS-026 AC1 to AC3). Mock responses are static, so a call succeeds and
/// the refreshed screen looks the same; Local UI tests check the new state.
@MainActor
final class LeaveAndRemoveUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() {
        continueAfterFailure = false
        app = XCUIApplication()
    }

    /// Signs in as `persona` and opens the Community tab.
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

    private func data(_ persona: String, _ name: String) throws -> [String: Any] {
        try XCTUnwrap(UITestData.json("mock_responses/\(persona)/\(name)")["data"] as? [String: Any])
    }

    private func homeGroup(_ persona: String) throws -> [String: Any] {
        try XCTUnwrap(data(persona, "get_screen.community.home")["group"] as? [String: Any])
    }

    private func confirm(of button: [String: Any]?) throws -> [String: String] {
        let action = try XCTUnwrap(button?["action"] as? [String: Any])
        return try XCTUnwrap(action["confirm"] as? [String: String])
    }

    /// Swipes `name`'s row and taps its remove button, which a full swipe
    /// may already have done.
    private func swipeToRemove(_ name: String) {
        let row = app.staticTexts[name]
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        row.swipeLeft()
        let remove = app.buttons["groupDetail.remove"]
        if remove.waitForExistence(timeout: 2) { remove.tap() }
    }

    /// Scrolls until `element`, such as the footer of a long list, which
    /// the list creates only once it is near, is on screen.
    private func scrollTo(_ element: XCUIElement) {
        XCTAssertTrue(app.staticTexts["groupDetail.title"].waitForExistence(timeout: 5))
        for _ in 0..<8 where !(element.exists && element.isHittable) {
            app.swipeUp()
        }
        XCTAssertTrue(element.isHittable)
    }

    func testLeaderSwipesToRemoveAMemberAfterConfirming() throws {
        let members = try XCTUnwrap(homeGroup("leader")["members"] as? [[String: Any]])
        let member = try XCTUnwrap(members.first { $0["remove"] != nil })
        let name = try XCTUnwrap(member["title"] as? String)
        let confirm = try confirm(of: member["remove"] as? [String: Any])
        openCommunity(as: "leader")

        swipeToRemove(name)
        let alert = app.alerts[try XCTUnwrap(confirm["title"])]
        XCTAssertTrue(alert.waitForExistence(timeout: 5))
        XCTAssertTrue(alert.staticTexts[try XCTUnwrap(confirm["message"])].exists)
        alert.buttons[try XCTUnwrap(confirm["confirm_label"])].tap()

        XCTAssertTrue(alert.waitForNonExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["groupDetail.title"].waitForExistence(timeout: 5), "the group refreshed in place")
    }

    func testCancellingARemoveKeepsTheRow() throws {
        let members = try XCTUnwrap(homeGroup("leader")["members"] as? [[String: Any]])
        let member = try XCTUnwrap(members.first { $0["remove"] != nil })
        let name = try XCTUnwrap(member["title"] as? String)
        let confirm = try confirm(of: member["remove"] as? [String: Any])
        openCommunity(as: "leader")

        swipeToRemove(name)
        let alert = app.alerts[try XCTUnwrap(confirm["title"])]
        XCTAssertTrue(alert.waitForExistence(timeout: 5))
        alert.buttons[try XCTUnwrap(confirm["cancel_label"])].tap()

        XCTAssertTrue(alert.waitForNonExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts[name].isHittable, "the row is back in its place")
        XCTAssertFalse(app.buttons["groupDetail.remove"].exists)
    }

    func testRowsWithoutRemoveDoNotSwipe() throws {
        let members = try XCTUnwrap(homeGroup("leader")["members"] as? [[String: Any]])
        let own = try XCTUnwrap(members.first { $0["remove"] == nil })
        openCommunity(as: "leader")

        let row = app.staticTexts[try XCTUnwrap(own["title"] as? String)]
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        row.swipeLeft()
        XCTAssertFalse(app.buttons["groupDetail.remove"].waitForExistence(timeout: 2))
        XCTAssertFalse(app.alerts.firstMatch.exists)
    }

    func testMemberOneLeavesFromCommunityHome() throws {
        let group = try homeGroup("member_one")
        XCTAssertFalse((group["members"] as? [[String: Any]] ?? []).contains { $0["remove"] != nil }, "a member removes nobody")
        let leave = try XCTUnwrap(group["leave"] as? [String: Any])
        let confirm = try confirm(of: leave)
        openCommunity(as: "member_one")

        let button = app.buttons["groupDetail.leave"]
        scrollTo(button)
        XCTAssertEqual(button.label.lowercased(), (leave["label"] as? String)?.lowercased())
        button.tap()
        let alert = app.alerts[try XCTUnwrap(confirm["title"])]
        XCTAssertTrue(alert.waitForExistence(timeout: 5))
        alert.buttons[try XCTUnwrap(confirm["confirm_label"])].tap()

        XCTAssertTrue(alert.waitForNonExistence(timeout: 5))
        XCTAssertTrue(app.navigationBars["Community"].exists, "home refreshed in place")
    }

    func testMemberTwoLeavesAPushedGroupAndLandsOnTheList() throws {
        let rows = try XCTUnwrap((data("member_two", "get_screen.community.home")["my_groups"] as? [String: Any])?["rows"] as? [[String: Any]])
        let first = try XCTUnwrap(rows.first)
        let title = try XCTUnwrap(first["title"] as? String)
        let groupID = try XCTUnwrap(first["group_id"] as? String)
        let group = try data("member_two", "get_screen.community.group@group_id=\(groupID)")
        let confirm = try confirm(of: group["leave"] as? [String: Any])
        openCommunity(as: "member_two")

        let row = app.buttons["groupRow"].firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        row.tap()
        XCTAssertTrue(app.navigationBars[title].waitForExistence(timeout: 5))
        let button = app.buttons["groupDetail.leave"]
        scrollTo(button)
        button.tap()
        let alert = app.alerts[try XCTUnwrap(confirm["title"])]
        XCTAssertTrue(alert.waitForExistence(timeout: 5))
        alert.buttons[try XCTUnwrap(confirm["confirm_label"])].tap()

        XCTAssertTrue(app.navigationBars[title].waitForNonExistence(timeout: 5), "the group closed")
        XCTAssertTrue(app.staticTexts["groupList.title"].waitForExistence(timeout: 5), "back on the refreshed list")
    }
}
