import XCTest

/// Mock build: each persona's Community tab from the recorded responses
/// (IOS-010 AC1, AC3, AC5; IOS-011 AC4; IOS-009 AC1, AC2).
@MainActor
final class CommunityUITests: XCTestCase {
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

    private func assertEmpty(_ persona: String) throws {
        let empty = try XCTUnwrap(data(persona, "get_screen.community.home")["empty"] as? [String: Any])
        openCommunity(as: persona)
        XCTAssertEqual(app.staticTexts["emptyState.title"].label, empty["title"] as? String)
        XCTAssertEqual(app.staticTexts["emptyState.message"].label, empty["message"] as? String)
        XCTAssertFalse(app.buttons["groupRow"].exists, "no buttons")
    }

    /// The detail shows the recorded group: title, leaders line and members.
    private func assertDetail(_ group: [String: Any], file: StaticString = #filePath, line: UInt = #line) throws {
        let title = try XCTUnwrap(group["title"] as? String)
        XCTAssertTrue(app.staticTexts["groupDetail.title"].waitForExistence(timeout: 5), file: file, line: line)
        XCTAssertEqual(app.staticTexts["groupDetail.title"].label, title, file: file, line: line)
        XCTAssertTrue(app.staticTexts["groupDetail.leadersLine"].label.contains(try XCTUnwrap(group["leaders_line"] as? String)), file: file, line: line)
        let members = try XCTUnwrap(group["members"] as? [[String: Any]])
        for member in members {
            XCTAssertTrue(app.staticTexts[try XCTUnwrap(member["title"] as? String)].exists, "member \(member)", file: file, line: line)
        }
        XCTAssertEqual(app.images.matching(identifier: "groupDetail.leaderIcon").count, members.filter { $0["is_leader"] as? Bool == true }.count, file: file, line: line)
        if let note = members.compactMap({ $0["note"] as? String }).first {
            XCTAssertEqual(app.staticTexts["groupDetail.note"].label.lowercased(), note.lowercased(), file: file, line: line)
        }
    }

    private func assertOwnGroup(_ persona: String) throws {
        let group = try XCTUnwrap(data(persona, "get_screen.community.home")["group"] as? [String: Any])
        openCommunity(as: persona)
        try assertDetail(group)
    }

    func testAttendeeSeesTheEmptyMessage() throws { try assertEmpty("attendee") }
    func testStaffWithNoGroupSeesTheEmptyMessage() throws { try assertEmpty("staff") }
    func testMemberOneSeesTheirGroup() throws { try assertOwnGroup("member_one") }
    func testLeaderSeesTheirGroup() throws { try assertOwnGroup("leader") }
    func testAdminSeesTheirGroup() throws { try assertOwnGroup("admin") }

    func testMemberTwoListsBothGroupsAndOpensEach() throws {
        let list = try XCTUnwrap(data("member_two", "get_screen.community.home")["my_groups"] as? [String: Any])
        let rows = try XCTUnwrap(list["rows"] as? [[String: Any]])
        openCommunity(as: "member_two")

        XCTAssertEqual(app.staticTexts["groupList.title"].label.lowercased(), (list["title"] as? String)?.lowercased())
        XCTAssertEqual(app.buttons.matching(identifier: "groupRow").count, rows.count)
        for row in rows {
            let title = try XCTUnwrap(row["title"] as? String)
            XCTAssertTrue(app.staticTexts[try XCTUnwrap(row["subtitle"] as? String)].exists)
            if let badge = row["badge"] as? String {
                XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label ==[c] %@", badge)).firstMatch.exists)
            }

            app.buttons.matching(identifier: "groupRow").matching(NSPredicate(format: "label CONTAINS %@", title)).firstMatch.tap()
            XCTAssertTrue(app.navigationBars[title].waitForExistence(timeout: 5), "pushed \(title)")
            let params = try XCTUnwrap((row["action"] as? [String: Any])?["params"] as? [String: Any])
            let detail = try data("member_two", "get_screen.community.group@group_id=\(try XCTUnwrap(params["group_id"] as? String))")
            try assertDetail(detail)

            app.navigationBars[title].buttons.firstMatch.tap()
            XCTAssertTrue(app.navigationBars["Community"].waitForExistence(timeout: 5), "back to the list")
            XCTAssertEqual(app.buttons.matching(identifier: "groupRow").count, rows.count)
        }
    }
}
