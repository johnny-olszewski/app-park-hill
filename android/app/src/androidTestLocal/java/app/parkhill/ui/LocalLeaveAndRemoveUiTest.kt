package app.parkhill.ui

import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.assertCountEquals
import androidx.compose.ui.test.assertTextEquals
import androidx.compose.ui.test.hasAnyDescendant
import androidx.compose.ui.test.hasTestTag
import androidx.compose.ui.test.hasText
import androidx.compose.ui.test.junit4.createAndroidComposeRule
import androidx.compose.ui.test.onAllNodesWithTag
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.performScrollToNode
import androidx.compose.ui.test.performTouchInput
import androidx.compose.ui.test.swipeDown
import androidx.compose.ui.test.swipeLeft
import androidx.test.ext.junit.runners.AndroidJUnit4
import app.parkhill.app.MainActivity
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.jsonArray
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import org.junit.After
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

/**
 * Local build against local Supabase: leaving, removing and losing access
 * (AND-027 AC2 to AC5). Every group a test changes gets its rows back when it
 * ends. Start it first: `cd backend && supabase start && supabase db reset`.
 */
@RunWith(AndroidJUnit4::class)
@OptIn(ExperimentalTestApi::class)
class LocalLeaveAndRemoveUiTest {
    @get:Rule(order = 0)
    val groups = LocalGroupRows()

    @get:Rule(order = 1)
    val compose = createAndroidComposeRule<MainActivity>()

    /** Tuesday Night Group's members, by name, from the leader's recorded Community home: the seed's ids. */
    private val tuesdayNight = Json.parseToJsonElement(
        checkNotNull(javaClass.classLoader?.getResourceAsStream("leader/get_screen.community.home.json")).bufferedReader().readText(),
    ).jsonObject.getValue("data").jsonObject.getValue("group").jsonObject
    private val groupId = tuesdayNight.getValue("group_id").jsonPrimitive.content
    private fun userId(name: String) = tuesdayNight.getValue("members").jsonArray.map { it.jsonObject }
        .first { it.getValue("title").jsonPrimitive.content == name }.getValue("user_id").jsonPrimitive.content

    // The backend's wording (migrations: community.group.unavailable, community.call_refused).
    private val noLongerInGroup = "You're no longer in this group."
    private val refused = "You can't make this change anymore."

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

    private fun removableRow(name: String) =
        compose.onNode(hasTestTag("groupDetail.removableMember").and(hasAnyDescendant(hasText(name))), useUnmergedTree = true)

    private fun confirm() {
        compose.await("confirm.confirm")
        compose.onNodeWithTag("confirm.confirm").performClick()
        compose.waitUntilDoesNotExist(hasTestTag("confirm.title"), 10_000)
    }

    private fun swipeToRemove(name: String) {
        compose.onNodeWithTag("groupDetail").performScrollToNode(hasText(name))
        removableRow(name).performTouchInput { swipeLeft() }
        confirm()
    }

    private fun awaitMessage(text: String) {
        compose.waitUntilAtLeastOneExists(hasText(text), 10_000)
    }

    @Test
    fun memberOneLeavesAndCommunityHomeUpdates() {
        groups.keep(groupId)
        openCommunity("member_one")
        compose.await("groupDetail.title")
        compose.onNodeWithTag("groupDetail").performScrollToNode(hasTestTag("groupDetail.leave"))
        compose.onNodeWithTag("groupDetail.leave").performClick()
        confirm()

        // Their only group: home moves to its empty state, with no message.
        compose.await("emptyState.title")
        compose.onAllNodesWithTag("message").assertCountEquals(0)
        assertFalse(userId("Member One") in groups.members(groupId))
    }

    @Test
    fun leaderRemovesAMember() {
        groups.keep(groupId)
        openCommunity("leader")
        compose.await("groupDetail.title")
        swipeToRemove("Ana Ruiz")

        compose.waitUntilDoesNotExist(hasText("Ana Ruiz"), 10_000)
        assertFalse(userId("Ana Ruiz") in groups.members(groupId))
        assertTrue(userId("Ben Carter") in groups.members(groupId))
    }

    @Test
    fun aMemberRemovedWhileViewingAPushedGroupIsTakenOffItOnPullToRefresh() {
        groups.keep(groupId)
        openCommunity("member_two")
        compose.await("groupRow")
        compose.onNode(hasTestTag("groupRow").and(hasText("Tuesday Night Group"))).performClick()
        compose.waitUntilAtLeastOneExists(hasTestTag("screen.title").and(hasText("Tuesday Night Group")), 10_000)
        compose.await("groupDetail.title")

        groups.removeMember(groupId, userId("Member Two"))
        compose.onNodeWithTag("groupDetail").performTouchInput { swipeDown() }

        awaitMessage(noLongerInGroup)
        compose.waitUntilDoesNotExist(hasTestTag("screen.back"), 10_000)
        compose.onNodeWithTag("tab.title").assertTextEquals("Community")
    }

    @Test
    fun aRemoveMadeStaleIsRefusedAndTheScreenRefreshes() {
        groups.keep(groupId)
        openCommunity("leader")
        compose.await("groupDetail.title")
        compose.onNodeWithTag("groupDetail").performScrollToNode(hasText("Ana Ruiz"))
        removableRow("Ana Ruiz").assertExists()

        // Leaders cannot remove leaders: making Ana one makes the shown remove stale.
        groups.makeLeader(groupId, userId("Ana Ruiz"))
        swipeToRemove("Ana Ruiz")

        awaitMessage(refused)
        compose.waitUntilDoesNotExist(hasTestTag("groupDetail.removableMember").and(hasAnyDescendant(hasText("Ana Ruiz"))), 10_000)
        assertTrue(userId("Ana Ruiz") in groups.members(groupId))
    }
}
