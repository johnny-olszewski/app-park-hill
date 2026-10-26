import XCTest

/// Local build against local Supabase: edit mode saves for real (IOS-013
/// AC3 to AC5). Each test puts back the group it changes. Start it first:
/// `cd backend && supabase start && supabase db reset`.
@MainActor
final class LocalEditModeUITests: XCTestCase {
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

    private func signIn(as persona: String) throws {
        app.launchSignedOut(entry: app.signInEmailField)
        app.signInEmailField.tap()
        app.signInEmailField.typeText(try UITestData.email(of: persona))
        let password = app.secureTextFields["signIn.password"]
        password.tap()
        password.typeText(try UITestData.localPassword())
        app.buttons["signIn.submit"].tap()
        app.dismissSavePasswordPrompt()
    }

    private func openCommunity() {
        let tab = app.tabBars.buttons["Community"]
        XCTAssertTrue(tab.waitForExistence(timeout: 10))
        tab.tap()
        XCTAssertTrue(app.navigationBars["Community"].waitForExistence(timeout: 5))
    }

    private var edit: XCUIElement { app.buttons["groupDetail.edit"] }
    private var done: XCUIElement { app.buttons["groupDetail.done"] }

    private func keepTuesday() async throws {
        try await database.keep(try await database.groupID(named: "Tuesday Night Group"))
    }

    private func startEditing() {
        XCTAssertTrue(edit.waitForExistence(timeout: 10))
        edit.tap()
        XCTAssertTrue(done.waitForExistence(timeout: 5))
    }

    private func scrollTo(_ element: XCUIElement) {
        for _ in 0..<8 where !(element.exists && element.isHittable) { app.swipeUp() }
        XCTAssertTrue(element.isHittable)
    }

    private func scrollToTop() {
        for _ in 0..<8 where !app.staticTexts["groupDetail.membersTitle"].isHittable { app.swipeDown() }
        for _ in 0..<2 { app.swipeDown() }
    }

    /// Replaces the text in the field labelled `label`.
    private func replace(_ label: String, with text: String) {
        let field = app.textFields[label]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        // The text sits at the trailing edge: tap there so the cursor ends it.
        field.coordinate(withNormalizedOffset: CGVector(dx: 0.99, dy: 0.5)).tap()
        let current = field.value as? String ?? ""
        field.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: current.count + 2) + text)
    }

    private func addFromPicker(_ name: String) {
        let addMember = app.buttons["groupDetail.addMember"]
        scrollTo(addMember)
        addMember.tap()
        let search = app.searchFields.firstMatch
        XCTAssertTrue(search.waitForExistence(timeout: 10))
        search.tap()
        search.typeText(name)
        let row = app.buttons.matching(NSPredicate(format: "identifier == 'peoplePicker.row' AND label CONTAINS %@", name)).firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        row.tap()
        app.buttons.matching(NSPredicate(format: "label == 'close'")).firstMatch.tap()
        app.buttons["peoplePicker.add"].tap()
        XCTAssertTrue(app.staticTexts["groupDetail.pendingRow"].waitForExistence(timeout: 5))
    }

    private func delete(_ name: String) {
        let row = app.cells.containing(NSPredicate(format: "label CONTAINS %@", name)).firstMatch
        scrollTo(row)
        row.images["minus.circle.fill"].firstMatch.tap()
        let confirm = app.buttons["Delete"]
        XCTAssertTrue(confirm.waitForExistence(timeout: 2))
        confirm.tap()
    }

    /// The saved group, as the leader sees it: details, the person added, and
    /// the person removed gone.
    private func assertSaved(file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(app.staticTexts["groupDetail.location"].waitForExistence(timeout: 10), file: file, line: line)
        XCTAssertEqual(app.staticTexts["groupDetail.location"].label, "Park home", file: file, line: line)
        XCTAssertEqual(app.staticTexts["groupDetail.meeting"].label, "Tuesdays · 7:00 PM", file: file, line: line)
        let attendee = app.staticTexts["Attendee"]
        scrollTo(attendee)
        XCTAssertFalse(app.staticTexts["Maria Lopez"].exists, "the removed member is gone", file: file, line: line)
    }

    func testLeaderEditsAddsAndRemovesAndItIsStillThereAfterRelaunch() async throws {
        try await keepTuesday()
        try signIn(as: "leader")
        openCommunity()
        startEditing()

        replace("Location", with: "Park home")
        addFromPicker("Attendee")
        delete("Maria Lopez")
        done.tap()

        XCTAssertTrue(edit.waitForExistence(timeout: 10), "the save leaves edit mode")
        scrollToTop()
        assertSaved()

        app.terminate()
        app.launch()
        openCommunity()
        assertSaved()
    }

    func testAFailedSaveSavesNothingAndShowsTheProblemAtItsField() async throws {
        try await keepTuesday()
        try signIn(as: "leader")
        openCommunity()
        startEditing()

        replace("Location", with: "Park home")
        replace("Name", with: "")
        done.tap()

        let error = app.staticTexts["groupDetail.fieldError.name"]
        XCTAssertTrue(error.waitForExistence(timeout: 10))
        XCTAssertEqual(error.label, "Enter a name.")
        XCTAssertTrue(done.exists, "still in edit mode")
        XCTAssertEqual(app.textFields["Location"].value as? String, "Park home", "the staged change is kept")

        app.buttons["groupDetail.cancel"].tap()
        XCTAssertTrue(app.staticTexts["groupDetail.location"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["groupDetail.location"].label, "Lee home, North Park", "nothing was saved")
    }

    func testStaffMakeSomeoneALeader() async throws {
        try await keepTuesday()
        try signIn(as: "staff")
        openCommunity()
        let browse = app.buttons["toolbar.browse_all_groups"]
        XCTAssertTrue(browse.waitForExistence(timeout: 5))
        browse.tap()
        let group = app.buttons.matching(identifier: "groupRow").containing(NSPredicate(format: "label CONTAINS 'Tuesday Night Group'")).firstMatch
        XCTAssertTrue(group.waitForExistence(timeout: 10))
        group.tap()
        startEditing()

        let maria = app.cells.containing(NSPredicate(format: "label CONTAINS 'Maria Lopez'")).firstMatch
        scrollTo(maria)
        maria.buttons["groupDetail.leaderToggle"].tap()
        done.tap()

        XCTAssertTrue(edit.waitForExistence(timeout: 10))
        scrollToTop()
        XCTAssertTrue(app.staticTexts["groupDetail.leadersLine"].label.contains("Maria Lopez"))
    }
}
