package app.parkhill.ui

import androidx.compose.ui.semantics.SemanticsActions
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
import androidx.compose.ui.test.swipeLeft
import androidx.compose.ui.test.swipeRight
import androidx.test.ext.junit.runners.AndroidJUnit4
import app.parkhill.app.MainActivity
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.jsonArray
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

/**
 * Mock build: leave and swipe to remove from the recorded responses (AND-027
 * AC1 to AC3). Mock responses are static (guide 6), so a confirmed call shows
 * its confirmation, the call and the dismiss or refresh, not a changed group.
 */
@RunWith(AndroidJUnit4::class)
@OptIn(ExperimentalTestApi::class)
class LeaveAndRemoveUiTest {
    @get:Rule
    val compose = createAndroidComposeRule<MainActivity>()

    private val tuesdayNight = "d44d5b87-37ce-5db5-9e33-43f477b42f1e"

    private fun recorded(path: String): JsonObject = Json.parseToJsonElement(
        checkNotNull(javaClass.classLoader?.getResourceAsStream(path)) { "$path not bundled" }.bufferedReader().readText(),
    ).jsonObject.getValue("data").jsonObject

    private fun JsonObject.text(key: String) = getValue(key).jsonPrimitive.content

    private fun openCommunity(persona: String) {
        compose.awaitSignedOut()
        compose.armMockSignIn(persona = persona)
        compose.signIn("anyone@example.com", "anything")
        compose.await("tab.community")
        compose.onNodeWithTag("tab.community").performClick()
        compose.onNodeWithTag("tab.title").assertTextEquals("Community")
    }

    /** The confirmation of a recorded `ActionButton`. */
    private fun confirmation(button: JsonObject) = button.getValue("action").jsonObject.getValue("confirm").jsonObject

    private fun assertConfirmation(confirm: JsonObject) {
        compose.await("confirm.title")
        compose.onNodeWithTag("confirm.title").assertTextEquals(confirm.text("title"))
        compose.onNodeWithTag("confirm.message").assertTextEquals(confirm.text("message"))
        compose.onNodeWithTag("confirm.confirm").assertTextEquals(confirm.text("confirm_label"))
        compose.onNodeWithTag("confirm.cancel").assertTextEquals(confirm.text("cancel_label"))
    }

    private fun answer(tag: String) {
        compose.onNodeWithTag(tag).performClick()
        compose.waitUntilDoesNotExist(hasTestTag("confirm.title"), 10_000)
    }

    private fun removableRow(name: String) =
        compose.onNode(hasTestTag("groupDetail.removableMember").and(hasAnyDescendant(hasText(name))), useUnmergedTree = true)

    private fun scrollTo(name: String) {
        compose.onNodeWithTag("groupDetail").performScrollToNode(hasText(name))
    }

    // AC2: a leader swipes a member's row: the backend's confirmation; cancel returns the row; confirm calls and refreshes.

    @Test
    fun leaderSwipesToRemoveAMember() {
        val group = recorded("leader/get_screen.community.home.json").getValue("group").jsonObject
        val ana = group.getValue("members").jsonArray.map { it.jsonObject }.first { it.text("title") == "Ana Ruiz" }
        openCommunity("leader")
        compose.await("groupDetail.title")
        scrollTo("Ana Ruiz")

        // Rows do not swipe the other way.
        removableRow("Ana Ruiz").performTouchInput { swipeRight() }
        compose.onAllNodesWithTag("confirm.title").assertCountEquals(0)

        removableRow("Ana Ruiz").performTouchInput { swipeLeft() }
        assertConfirmation(confirmation(ana.getValue("remove").jsonObject))
        answer("confirm.cancel")
        removableRow("Ana Ruiz").assertExists()

        removableRow("Ana Ruiz").performTouchInput { swipeLeft() }
        assertConfirmation(confirmation(ana.getValue("remove").jsonObject))
        answer("confirm.confirm")
        compose.await("groupDetail")
        compose.onNodeWithTag("tab.title").assertTextEquals("Community")
        compose.onAllNodesWithTag("message").assertCountEquals(0)
    }

    @Test
    fun aLeadersOwnRowDoesNotSwipe() {
        openCommunity("leader")
        compose.await("groupDetail.title")
        scrollTo("Leader")
        compose.onNode(hasTestTag("groupDetail.removableMember").and(hasAnyDescendant(hasText("Leader"))), useUnmergedTree = true)
            .assertDoesNotExist()
        compose.onNode(hasTestTag("groupDetail.member").and(hasAnyDescendant(hasText("Leader"))), useUnmergedTree = true)
            .performTouchInput { swipeLeft() }
        compose.onAllNodesWithTag("confirm.title").assertCountEquals(0)
    }

    @Test
    fun removeIsAnAccessibilityActionNamedWithItsLabel() {
        val group = recorded("leader/get_screen.community.home.json").getValue("group").jsonObject
        val ben = group.getValue("members").jsonArray.map { it.jsonObject }.first { it.text("title") == "Ben Carter" }
        val label = ben.getValue("remove").jsonObject.text("label")
        openCommunity("leader")
        compose.await("groupDetail.title")
        scrollTo("Ben Carter")

        val actions = removableRow("Ben Carter").fetchSemanticsNode().config[SemanticsActions.CustomActions]
        val remove = actions.single { it.label == label }
        compose.runOnUiThread { remove.action() }
        assertConfirmation(confirmation(ben.getValue("remove").jsonObject))
        answer("confirm.cancel")
    }

    // AC3: Leave appears only when sent; on Community home a confirmed leave refreshes home.

    @Test
    fun memberOneLeavesFromCommunityHome() {
        val group = recorded("member_one/get_screen.community.home.json").getValue("group").jsonObject
        val leave = group.getValue("leave").jsonObject
        openCommunity("member_one")
        compose.await("groupDetail.title")
        // A member cannot remove anyone.
        compose.onAllNodesWithTag("groupDetail.removableMember", useUnmergedTree = true).assertCountEquals(0)

        compose.onNodeWithTag("groupDetail").performScrollToNode(hasTestTag("groupDetail.leave"))
        compose.onNodeWithTag("groupDetail.leave").assertTextEquals(leave.text("label").uppercase())
        compose.onNodeWithTag("groupDetail.leave").performClick()
        assertConfirmation(confirmation(leave))
        answer("confirm.confirm")
        compose.await("groupDetail")
        compose.onNodeWithTag("tab.title").assertTextEquals("Community")
        compose.onAllNodesWithTag("message").assertCountEquals(0)
    }

    @Test
    fun memberTwoLeavesAPushedGroup() {
        val leave = recorded("member_two/get_screen.community.group@group_id=$tuesdayNight.json").getValue("leave").jsonObject
        openCommunity("member_two")
        compose.await("groupRow")
        compose.onNode(hasTestTag("groupRow").and(hasText("Tuesday Night Group"))).performClick()
        compose.waitUntilAtLeastOneExists(hasTestTag("screen.title").and(hasText("Tuesday Night Group")), 10_000)
        compose.await("groupDetail.title")

        compose.onNodeWithTag("groupDetail").performScrollToNode(hasTestTag("groupDetail.leave"))
        compose.onNodeWithTag("groupDetail.leave").performClick()
        assertConfirmation(confirmation(leave))
        answer("confirm.cancel")
        compose.onNodeWithTag("screen.title").assertTextEquals("Tuesday Night Group")

        compose.onNodeWithTag("groupDetail.leave").performClick()
        assertConfirmation(confirmation(leave))
        answer("confirm.confirm")
        compose.await("groupList.title")
        compose.onNodeWithTag("tab.title").assertTextEquals("Community")
        compose.onAllNodesWithTag("screen.back").assertCountEquals(0)
        compose.onAllNodesWithTag("message").assertCountEquals(0)
    }
}
