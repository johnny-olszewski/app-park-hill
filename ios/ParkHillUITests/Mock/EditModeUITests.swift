import XCTest

/// Mock build: edit mode on group detail and the people picker (IOS-012 AC1,
/// AC3; IOS-013 AC1 to AC3). Mock responses are static, so an ok save
/// leaves edit mode and the refreshed group looks as before; Local UI tests
/// check what was saved.
@MainActor
final class EditModeUITests: XCTestCase {
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

    private var edit: XCUIElement { app.buttons["groupDetail.edit"] }
    private var done: XCUIElement { app.buttons["groupDetail.done"] }
    private var cancel: XCUIElement { app.buttons["groupDetail.cancel"] }

    private func startEditing() {
        XCTAssertTrue(edit.waitForExistence(timeout: 5))
        edit.tap()
        XCTAssertTrue(done.waitForExistence(timeout: 5))
    }

    private func scrollTo(_ element: XCUIElement) {
        for _ in 0..<8 where !(element.exists && element.isHittable) {
            app.swipeUp()
        }
        XCTAssertTrue(element.isHittable)
    }

    /// Taps the delete control on `name`'s row, then the Delete it reveals.
    private func delete(_ name: String) {
        let row = app.cells.containing(NSPredicate(format: "label CONTAINS %@", name)).firstMatch
        scrollTo(row)
        row.images["minus.circle.fill"].firstMatch.tap()
        let confirm = app.buttons["Delete"]
        XCTAssertTrue(confirm.waitForExistence(timeout: 2))
        confirm.tap()
    }

    /// The picker row for `name`.
    private func pickerRow(_ name: String) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "identifier == 'peoplePicker.row' AND label CONTAINS %@", name)).firstMatch
    }

    func testLeaderEditsAddsFromThePickerRemovesAndSaves() throws {
        openCommunity(as: "leader")
        startEditing()
        XCTAssertFalse(app.buttons["groupDetail.leaderToggle"].exists, "a leader cannot change who leads")

        let location = app.textFields["Location"]
        XCTAssertTrue(location.waitForExistence(timeout: 5))
        location.tap()
        location.typeText(" (back room)\n")

        let addMember = app.buttons["groupDetail.addMember"]
        scrollTo(addMember)
        addMember.tap()
        XCTAssertTrue(app.navigationBars["Add people"].waitForExistence(timeout: 5), "the picker opens as a sheet")
        let search = app.searchFields.firstMatch
        XCTAssertTrue(search.waitForExistence(timeout: 5))
        search.tap()
        search.typeText("Member One")
        let memberOne = pickerRow("Member One")
        XCTAssertTrue(memberOne.waitForExistence(timeout: 5))
        XCTAssertFalse(memberOne.isEnabled, "a current member cannot be chosen")
        XCTAssertTrue(memberOne.label.contains("Already a member"))
        search.buttons["Clear text"].tap()
        search.typeText("Attendee")
        pickerRow("Attendee").tap()
        // While searching, iOS hides the sheet's bar; closing the search
        // brings Add back, with the choices kept.
        app.buttons.matching(NSPredicate(format: "label == 'close'")).firstMatch.tap()
        app.buttons["peoplePicker.add"].tap()
        XCTAssertTrue(app.navigationBars["Add people"].waitForNonExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["groupDetail.pendingRow"].waitForExistence(timeout: 5), "the chosen person is a pending row")

        delete("Maria Lopez")
        XCTAssertFalse(app.alerts.firstMatch.exists, "nothing staged asks for confirmation")

        done.tap()
        XCTAssertTrue(edit.waitForExistence(timeout: 10), "an ok save leaves edit mode")
        XCTAssertFalse(app.alerts.firstMatch.exists)
    }

    func testCancelUndoesEveryStagedChange() throws {
        openCommunity(as: "leader")
        let title = app.staticTexts["groupDetail.title"].label
        startEditing()

        let name = app.textFields["Name"]
        XCTAssertTrue(name.waitForExistence(timeout: 5))
        name.tap()
        name.typeText(" changed")
        delete("Maria Lopez")
        cancel.tap()

        XCTAssertTrue(edit.waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["groupDetail.title"].label, title)
        scrollTo(app.staticTexts["Maria Lopez"])
    }

    func testThePickerDragsDownToCloseAndAddsNobody() throws {
        openCommunity(as: "leader")
        startEditing()
        let addMember = app.buttons["groupDetail.addMember"]
        scrollTo(addMember)
        addMember.tap()
        let picker = app.navigationBars["Add people"]
        XCTAssertTrue(picker.waitForExistence(timeout: 5))

        let top = picker.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0))
        top.press(forDuration: 0.1, thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.98)))

        XCTAssertTrue(picker.waitForNonExistence(timeout: 5), "dragging down closes the sheet")
        XCTAssertFalse(app.staticTexts["groupDetail.pendingRow"].exists, "nobody was added")
        XCTAssertTrue(done.exists, "still in edit mode")
    }

    func testStaffMakeAndRemoveLeadersInEditMode() throws {
        openCommunity(as: "staff")
        let browse = app.buttons["toolbar.browse_all_groups"]
        XCTAssertTrue(browse.waitForExistence(timeout: 5))
        browse.tap()
        let row = app.buttons.matching(identifier: "groupRow").containing(.staticText, identifier: "Tuesday Night Group").firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        row.tap()
        startEditing()

        let toggles = app.buttons.matching(identifier: "groupDetail.leaderToggle")
        XCTAssertTrue(toggles.firstMatch.waitForExistence(timeout: 5), "staff get a leader toggle on every row")
        let second = toggles.element(boundBy: 1)
        XCTAssertEqual(second.value as? String, "Off")
        second.tap()
        XCTAssertEqual(second.value as? String, "On")
        XCTAssertFalse(app.alerts.firstMatch.exists)

        done.tap()
        XCTAssertTrue(edit.waitForExistence(timeout: 10))
    }

    func testMembersGetNoEditButton() {
        openCommunity(as: "member_one")
        XCTAssertTrue(app.staticTexts["groupDetail.title"].waitForExistence(timeout: 5))
        XCTAssertFalse(edit.exists)
    }
}
