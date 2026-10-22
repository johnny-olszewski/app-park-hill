import XCTest

/// Mock build: the signed-in tabs from the recorded get_tabs (IOS-008 AC2,
/// AC3, AC8, AC10, AC11, AC13).
@MainActor
final class TabsUITests: XCTestCase {
    func testSignInShowsTheTabsAndSwitchingFollowsInTheMenu() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchSignedOut(entry: app.signInEmailField)
        app.submitAnyCredentials()
        app.dismissSavePasswordPrompt()

        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 10))
        XCTAssertEqual(tabBar.buttons.allElementsBoundByIndex.map { $0.label }, ["Home", "Community"])
        XCTAssertTrue(app.navigationBars["Home"].exists, "the first tab is selected")

        tabBar.buttons["Community"].tap()
        XCTAssertTrue(app.navigationBars["Community"].waitForExistence(timeout: 5))
        app.openDevToolsMenu()
        let current = app.buttons["devTools.currentScreen"].label
        XCTAssertTrue(current.contains("community.home"), "Current screen follows the selected tab: \(current)")
        app.closeDevToolsMenu()

        tabBar.buttons["Home"].tap()
        app.buttons["home.signOut"].tap() // TEMPORARY(EP-04): remove with IOS-015/AND-015
        XCTAssertTrue(app.signInEmailField.waitForExistence(timeout: 10), "Home's Sign out returns to sign-in")
    }
}
