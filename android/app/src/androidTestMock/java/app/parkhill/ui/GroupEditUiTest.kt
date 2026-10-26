package app.parkhill.ui

import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.assertContentDescriptionEquals
import androidx.compose.ui.test.assertCountEquals
import androidx.compose.ui.test.assertIsOff
import androidx.compose.ui.test.assertIsOn
import androidx.compose.ui.test.assertTextContains
import androidx.compose.ui.test.assertTextEquals
import androidx.compose.ui.test.hasAnyAncestor
import androidx.compose.ui.test.hasAnyDescendant
import androidx.compose.ui.test.hasTestTag
import androidx.compose.ui.test.hasText
import androidx.compose.ui.test.junit4.createAndroidComposeRule
import androidx.compose.ui.test.onAllNodesWithTag
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.performScrollToNode
import androidx.compose.ui.test.performTextReplacement
import androidx.test.ext.junit.runners.AndroidJUnit4
import app.parkhill.app.MainActivity
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

/**
 * Mock build: group edit mode per persona (AND-013 AC1 to AC3). Mock
 * responses are static (guide 6), so Done shows an ok save, edit mode
 * closing and the screen as recorded, not a changed group.
 */
@RunWith(AndroidJUnit4::class)
@OptIn(ExperimentalTestApi::class)
class GroupEditUiTest {
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

    private fun editRow(name: String) =
        compose.onNode(hasTestTag("groupDetail.editRow").and(hasAnyDescendant(hasText(name))), useUnmergedTree = true)

    /** The control tagged `tag` in the edit row showing `name`. */
    private fun inRow(name: String, tag: String) = compose.onNode(
        hasTestTag(tag).and(hasAnyAncestor(hasTestTag("groupDetail.editRow").and(hasAnyDescendant(hasText(name))))),
        useUnmergedTree = true,
    )

    private fun scrollTo(name: String) {
        compose.onNodeWithTag("groupDetail").performScrollToNode(hasText(name))
    }

    // AC1 to AC3: the leader edits details and members with no confirmations; Cancel restores the screen; Done saves and leaves edit mode.
    @Test
    fun leaderStagesChangesThenCancelsThenSaves() {
        val group = recorded("leader/get_screen.community.home.json").getValue("group").jsonObject
        val labels = group.getValue("edit").jsonObject
        openCommunity("leader")
        compose.await("groupDetail.edit")
        compose.onNodeWithTag("groupDetail.edit").assertTextEquals(labels.text("edit_label"))
        compose.onNodeWithTag("groupDetail.edit").performClick()

        // Edit mode: Done and Cancel replace Edit and the toolbar; details become fields; Leave and swipe are off.
        compose.await("groupDetail.done")
        compose.onNodeWithTag("groupDetail.done").assertTextEquals(labels.text("done_label"))
        compose.onNodeWithTag("groupDetail.cancel").assertContentDescriptionEquals(labels.text("cancel_label"))
        compose.onAllNodesWithTag("groupDetail.edit").assertCountEquals(0)
        compose.onNodeWithTag("groupDetail.field.name").assertTextContains(group.text("title"))
        compose.onAllNodesWithTag("groupDetail.removableMember", useUnmergedTree = true).assertCountEquals(0)
        compose.onAllNodesWithTag("groupDetail.leave").assertCountEquals(0)
        // A leader cannot change who leads.
        compose.onAllNodesWithTag("groupDetail.leaderToggle", useUnmergedTree = true).assertCountEquals(0)

        compose.onNodeWithTag("groupDetail.field.name").performTextReplacement("Tuesday Supper Club")
        compose.onNodeWithTag("groupDetail.field.day").performClick()
        compose.await("groupDetail.field.day.3")
        compose.onNodeWithTag("groupDetail.field.day.3").performClick()
        compose.onNodeWithTag("groupDetail.field.day").assertTextContains("Wednesdays")

        // One tap stages a removal, with no confirmation; the leader's own row has no minus.
        scrollTo("Ana Ruiz")
        inRow("Ana Ruiz", "groupDetail.removeRow").performClick()
        compose.onAllNodesWithTag("confirm.title").assertCountEquals(0)
        editRow("Ana Ruiz").assertDoesNotExist()
        scrollTo("Leader")
        inRow("Leader", "groupDetail.removeRow").assertDoesNotExist()

        // Cancel restores the screen as it was before Edit.
        compose.onNodeWithTag("groupDetail.cancel").performClick()
        compose.await("groupDetail.edit")
        compose.onAllNodesWithTag("groupDetail.field.name").assertCountEquals(0)
        compose.onNodeWithTag("groupDetail").performScrollToNode(hasTestTag("groupDetail.title"))
        compose.onNodeWithTag("groupDetail.title").assertTextEquals(group.text("title"))
        scrollTo("Ana Ruiz")
        compose.onNode(hasTestTag("groupDetail.removableMember").and(hasAnyDescendant(hasText("Ana Ruiz"))), useUnmergedTree = true).assertExists()

        // Editing again starts with nothing staged; Done saves and leaves edit mode.
        compose.onNodeWithTag("groupDetail.edit").performClick()
        compose.await("groupDetail.field.name")
        compose.onNodeWithTag("groupDetail.field.name").assertTextContains(group.text("title"))
        scrollTo("Ana Ruiz")
        inRow("Ana Ruiz", "groupDetail.removeRow").performClick()
        compose.onNodeWithTag("groupDetail.done").performClick()
        compose.await("groupDetail.edit")
        compose.onAllNodesWithTag("groupDetail.done").assertCountEquals(0)
        compose.onAllNodesWithTag("message").assertCountEquals(0)
    }

    // AC1, AC2: staff make and remove leaders in edit mode, from a group reached through Browse.
    @Test
    fun staffTogglesLeadersAndSaves() {
        val group = recorded("staff/get_screen.community.group@group_id=$tuesdayNight.json")
        openCommunity("staff")
        compose.await("toolbar.browse_all_groups")
        compose.onNodeWithTag("toolbar.browse_all_groups").performClick()
        compose.await("cover")
        compose.await("browse.search")
        compose.onNodeWithTag("groupList").performScrollToNode(hasText(group.text("title")))
        compose.onNodeWithText(group.text("title")).performClick()
        compose.waitUntilAtLeastOneExists(hasTestTag("screen.title").and(hasText(group.text("title"))), 10_000)
        compose.await("groupDetail.edit")
        compose.onNodeWithTag("groupDetail.edit").performClick()
        compose.await("groupDetail.done")
        // Cancel takes the back button's place while editing.
        compose.onAllNodesWithTag("screen.back").assertCountEquals(0)

        scrollTo("Leader")
        inRow("Leader", "groupDetail.leaderToggle").assertIsOn()
        inRow("Leader", "groupDetail.leaderToggle").performClick()
        inRow("Leader", "groupDetail.leaderToggle").assertIsOff()
        scrollTo("Ana Ruiz")
        inRow("Ana Ruiz", "groupDetail.leaderToggle").assertIsOff()
        inRow("Ana Ruiz", "groupDetail.leaderToggle").performClick()
        inRow("Ana Ruiz", "groupDetail.leaderToggle").assertIsOn()
        // Tapping again unstages it.
        inRow("Ana Ruiz", "groupDetail.leaderToggle").performClick()
        inRow("Ana Ruiz", "groupDetail.leaderToggle").assertIsOff()
        inRow("Ana Ruiz", "groupDetail.leaderToggle").performClick()
        compose.onAllNodesWithTag("confirm.title").assertCountEquals(0)

        compose.onNodeWithTag("groupDetail.done").performClick()
        compose.await("groupDetail.edit")
        compose.onNodeWithTag("screen.back").assertExists()
        compose.onAllNodesWithTag("message").assertCountEquals(0)
    }

    // AC1: no edit capability, no Edit.
    @Test
    fun aMemberSeesNoEdit() {
        openCommunity("member_one")
        compose.await("groupDetail.title")
        compose.onAllNodesWithTag("groupDetail.edit").assertCountEquals(0)
    }
}
