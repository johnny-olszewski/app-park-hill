package app.parkhill.ui

import androidx.compose.ui.test.assertTextEquals
import androidx.compose.ui.test.junit4.createAndroidComposeRule
import androidx.compose.ui.test.longClick
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.performTouchInput
import androidx.test.ext.junit.runners.AndroidJUnit4
import app.parkhill.app.MainActivity
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

/** Mock build: the dev tools pill and menu over the app (AND-021). */
@RunWith(AndroidJUnit4::class)
class DevToolsUiTest {
    @get:Rule
    val compose = createAndroidComposeRule<MainActivity>()

    @Test
    fun menuShowsTheCurrentScreenAndTheAppStillTakesTouches() {
        compose.awaitSignedOut()

        compose.openDevToolsMenu()
        compose.tapInDevToolsMenu("devTools.currentScreen")
        compose.await("devTools.currentScreen.key")
        compose.onNodeWithTag("devTools.currentScreen.key").assertTextEquals("auth.sign_in")
        compose.onNodeWithTag("devTools.currentScreen.data").assertExists()
        compose.closeDevToolsMenu()

        compose.armMockSignIn()
        compose.signIn("anyone@example.com", "anything")
        compose.await("placeholder.user")
        compose.onNodeWithTag("devTools.pill").assertExists()
    }

    @Test
    fun menuSignsOut() {
        compose.awaitSignedOut()
        compose.armMockSignIn()
        compose.signIn("anyone@example.com", "anything")
        compose.await("placeholder.user")

        compose.openDevToolsMenu()
        compose.tapInDevToolsMenu("devTools.signOut")
        compose.await("signIn.email")
    }
}
