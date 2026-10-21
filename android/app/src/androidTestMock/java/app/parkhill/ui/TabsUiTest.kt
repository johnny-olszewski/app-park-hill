package app.parkhill.ui

import androidx.compose.ui.test.assertIsSelected
import androidx.compose.ui.test.assertTextEquals
import androidx.compose.ui.test.junit4.createAndroidComposeRule
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.performClick
import androidx.test.ext.junit.runners.AndroidJUnit4
import app.parkhill.app.MainActivity
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

/** Mock build: the signed-in tabs from the recorded get_tabs (AND-008 AC2, AC3, AC8, AC10, AC11, AC13). */
@RunWith(AndroidJUnit4::class)
class TabsUiTest {
    @get:Rule
    val compose = createAndroidComposeRule<MainActivity>()

    @Test
    fun signInShowsTheTabsAndSwitchingFollowsInTheMenu() {
        compose.awaitSignedOut()
        compose.armMockSignIn()
        compose.signIn("anyone@example.com", "anything")

        compose.await("tab.home")
        compose.onNodeWithTag("tab.home").assertIsSelected()
        compose.onNodeWithTag("tab.community").assertExists()
        compose.onNodeWithTag("tab.title").assertTextEquals("Home")

        compose.onNodeWithTag("tab.community").performClick()
        compose.onNodeWithTag("tab.title").assertTextEquals("Community")
        compose.openDevToolsMenu()
        compose.tapInDevToolsMenu("devTools.currentScreen")
        compose.await("devTools.currentScreen.key")
        compose.onNodeWithTag("devTools.currentScreen.key").assertTextEquals("community.home")
        compose.closeDevToolsMenu()

        compose.onNodeWithTag("tab.home").performClick()
        compose.onNodeWithTag("home.signOut").performClick() // TEMPORARY(EP-04): remove with IOS-015/AND-015
        compose.await("signIn.email")
    }
}
