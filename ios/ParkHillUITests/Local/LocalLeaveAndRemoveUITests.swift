import XCTest

/// Local build against local Supabase: leaving, removing, losing access while
/// viewing, and a stale remove refused (IOS-026 AC2 to AC6). Each test puts
/// back the group rows it changes. Start it first:
/// `cd backend && supabase start && supabase db reset`.
@MainActor
final class LocalLeaveAndRemoveUITests: XCTestCase {
    private var app: XCUIApplication!
    private let database = LocalDatabase()

    override func setUp() {
        continueAfterFailure = false
        app = XCUIApplication()
    }

    override func tearDown() async throws {
        if app.devToolsPill.exists, !app.signInEmailField.exists {
            app.signOutThroughDevTools()
        }
        try await database.restore()
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

    private func tuesday() async throws -> String {
        let group = try await database.groupID(named: "Tuesday Night Group")
        try await database.keep(group)
        return group
    }

    /// Swipes `name`'s row and taps its remove button, which a full swipe
    /// may already have done, then confirms.
    private func remove(_ name: String) {
        let row = app.staticTexts[name]
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        row.swipeLeft()
        let button = app.buttons["groupDetail.remove"]
        if button.waitForExistence(timeout: 2) { button.tap() }
        let alert = app.alerts["Remove \(name)?"]
        XCTAssertTrue(alert.waitForExistence(timeout: 5))
        alert.buttons["Remove"].tap()
    }

    private func pullToRefresh() {
        let title = app.staticTexts["groupDetail.title"]
        XCTAssertTrue(title.waitForExistence(timeout: 5))
        let start = title.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0))
        start.press(forDuration: 0.1, thenDragTo: start.withOffset(CGVector(dx: 0, dy: 400)))
    }

    /// The one-button alert carrying `message`, dismissed.
    private func assertMessage(_ message: String, file: StaticString = #filePath, line: UInt = #line) {
        let alert = app.alerts[message]
        XCTAssertTrue(alert.waitForExistence(timeout: 10), "message \(message)", file: file, line: line)
        XCTAssertEqual(alert.buttons.count, 1, file: file, line: line)
        alert.buttons.firstMatch.tap()
        XCTAssertTrue(alert.waitForNonExistence(timeout: 5), file: file, line: line)
    }

    func testMemberOneLeavesAndCommunityHomeIsEmpty() async throws {
        _ = try await tuesday()
        try openCommunity(as: "member_one")

        let leave = app.buttons["groupDetail.leave"]
        XCTAssertTrue(app.staticTexts["groupDetail.title"].waitForExistence(timeout: 5))
        for _ in 0..<8 where !(leave.exists && leave.isHittable) { app.swipeUp() }
        leave.tap()
        let alert = app.alerts["Leave Tuesday Night Group?"]
        XCTAssertTrue(alert.waitForExistence(timeout: 5))
        alert.buttons["Leave"].tap()

        XCTAssertTrue(app.staticTexts["emptyState.title"].waitForExistence(timeout: 10), "home moved to empty in place")
        XCTAssertTrue(app.navigationBars["Community"].exists)
    }

    func testLeaderRemovesAMember() async throws {
        let group = try await tuesday()
        let maria = try await database.userID(named: "Maria Lopez")
        try openCommunity(as: "leader")

        remove("Maria Lopez")

        for _ in 0..<20 where try await database.isMember(maria, of: group) {
            try await Task.sleep(for: .milliseconds(250))
        }
        let stillMember = try await database.isMember(maria, of: group)
        XCTAssertFalse(stillMember, "the backend removed them")
        XCTAssertFalse(app.alerts.firstMatch.exists, "no message")

        XCTAssertTrue(app.staticTexts["Maria Lopez"].waitForNonExistence(timeout: 10), "the member is gone after the refresh")
        XCTAssertTrue(app.staticTexts["groupDetail.membersTitle"].exists, "still on the group")
    }

    func testMemberRemovedWhileViewingAPushedGroupIsTakenOffIt() async throws {
        let group = try await tuesday()
        let memberTwo = try await database.userID(named: "Member Two")
        try openCommunity(as: "member_two")
        let row = app.buttons.matching(identifier: "groupRow").element(boundBy: 1)
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        row.tap()
        XCTAssertTrue(app.navigationBars["Tuesday Night Group"].waitForExistence(timeout: 10))

        try await database.removeMember(memberTwo, from: group)
        pullToRefresh()

        assertMessage("You're no longer in this group.")
        XCTAssertFalse(app.navigationBars["Tuesday Night Group"].exists, "the group closed")
        XCTAssertEqual(app.staticTexts["groupDetail.title"].label, "Young Families", "home refreshed to their one group")
    }

    func testAStaleRemoveIsRefusedWithTheBackendsMessage() async throws {
        let group = try await tuesday()
        let maria = try await database.userID(named: "Maria Lopez")
        try openCommunity(as: "leader")
        XCTAssertTrue(app.staticTexts["Maria Lopez"].waitForExistence(timeout: 5))

        try await database.makeLeader(maria, of: group)
        remove("Maria Lopez")

        assertMessage("You can't make this change anymore.")
        XCTAssertTrue(app.staticTexts["groupDetail.leadersLine"].label.contains("Maria Lopez"), "the screen refreshed")
        app.staticTexts["Maria Lopez"].swipeLeft()
        XCTAssertFalse(app.buttons["groupDetail.remove"].waitForExistence(timeout: 2), "a leader's row no longer swipes")
    }
}
