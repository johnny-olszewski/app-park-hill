package app.parkhill.ui

import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.assertCountEquals
import androidx.compose.ui.test.assertTextEquals
import androidx.compose.ui.test.hasTestTag
import androidx.compose.ui.test.hasText
import androidx.compose.ui.test.junit4.createAndroidComposeRule
import androidx.compose.ui.test.onAllNodesWithTag
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.performClick
import androidx.test.ext.junit.runners.AndroidJUnit4
import app.parkhill.app.MainActivity
import org.junit.After
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

/**
 * Local build against local Supabase: each persona's Community tab (AND-010 AC1, AC5).
 * Start it first: `cd backend && supabase start && supabase db reset`.
 */
@RunWith(AndroidJUnit4::class)
@OptIn(ExperimentalTestApi::class)
class LocalCommunityUiTest {
    @get:Rule
    val compose = createAndroidComposeRule<MainActivity>()

    private fun openCommunity(persona: String) {
        compose.awaitSignedOut()
        compose.signIn(UiTestData.email(persona), UiTestData.localPassword)
        compose.await("tab.community")
        compose.onNodeWithTag("tab.community").performClick()
        compose.onNodeWithTag("tab.title").assertTextEquals("Community")
    }

    @After
    fun signOut() {
        compose.signOutThroughDevTools()
    }

    private fun assertEmpty(persona: String) {
        openCommunity(persona)
        compose.await("emptyState.title")
        compose.onAllNodesWithTag("groupRow").assertCountEquals(0)
    }

    private fun assertGroup(persona: String, title: String) {
        openCommunity(persona)
        compose.await("groupDetail.title")
        compose.onNodeWithTag("groupDetail.title").assertTextEquals(title)
    }

    @Test fun attendee() = assertEmpty("attendee")

    @Test fun staff() = assertEmpty("staff")

    @Test fun memberOne() = assertGroup("member_one", "Tuesday Night Group")

    @Test fun leader() = assertGroup("leader", "Tuesday Night Group")

    @Test fun admin() = assertGroup("admin", "Mission Hills Group")

    @Test
    fun memberTwo() {
        openCommunity("member_two")
        compose.await("groupRow")
        compose.onAllNodesWithTag("groupRow").assertCountEquals(2)
        compose.onAllNodesWithTag("groupRow")[1].performClick()
        compose.waitUntilAtLeastOneExists(hasTestTag("screen.title").and(hasText("Tuesday Night Group")), 10_000)
    }
}
