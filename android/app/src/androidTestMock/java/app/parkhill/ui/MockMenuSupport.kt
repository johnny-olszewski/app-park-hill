package app.parkhill.ui

import androidx.compose.ui.test.junit4.ComposeTestRule

/**
 * On sign-in, chooses who the next mock sign-in signs in as and its result
 * (`MockSignInResult` name). Choices last for the process, so each test arms
 * what it needs.
 */
fun ComposeTestRule.armMockSignIn(persona: String = "attendee", result: String = "Success") {
    openDevToolsMenu()
    tapInDevToolsMenu("mockSignIn.persona.$persona")
    tapInDevToolsMenu("mockSignIn.result.$result")
    closeDevToolsMenu()
}
