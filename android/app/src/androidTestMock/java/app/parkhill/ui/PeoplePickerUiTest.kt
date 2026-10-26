package app.parkhill.ui

import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.assertCountEquals
import androidx.compose.ui.test.assertIsEnabled
import androidx.compose.ui.test.assertIsNotEnabled
import androidx.compose.ui.test.assertIsOff
import androidx.compose.ui.test.assertIsOn
import androidx.compose.ui.test.assertTextEquals
import androidx.compose.ui.test.hasAnyDescendant
import androidx.compose.ui.test.hasTestTag
import androidx.compose.ui.test.hasText
import androidx.compose.ui.test.junit4.createAndroidComposeRule
import androidx.compose.ui.test.onAllNodesWithTag
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.performScrollToNode
import androidx.compose.ui.test.performTextInput
import androidx.compose.ui.test.performTouchInput
import androidx.compose.ui.test.swipeDown
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
 * Mock build: the people picker as a sheet from the leader's edit mode
 * (AND-012 AC1 to AC4, AND-013 AC3). Mock responses are static (guide 6), so
 * Done shows an ok save and the screen as recorded.
 */
@RunWith(AndroidJUnit4::class)
@OptIn(ExperimentalTestApi::class)
class PeoplePickerUiTest {
    @get:Rule
    val compose = createAndroidComposeRule<MainActivity>()

    private val tuesdayNight = "d44d5b87-37ce-5db5-9e33-43f477b42f1e"

    private val picker: JsonObject = Json.parseToJsonElement(
        checkNotNull(javaClass.classLoader?.getResourceAsStream("leader/get_screen.people.picker@group_id=$tuesdayNight.json")).bufferedReader().readText(),
    ).jsonObject.getValue("data").jsonObject

    private fun JsonObject.text(key: String) = getValue(key).jsonPrimitive.content

    private fun openLeadersEditMode() {
        compose.awaitSignedOut()
        compose.armMockSignIn(persona = "leader")
        compose.signIn("anyone@example.com", "anything")
        compose.await("tab.community")
        compose.onNodeWithTag("tab.community").performClick()
        compose.await("groupDetail.edit")
        compose.onNodeWithTag("groupDetail.edit").performClick()
        compose.await("groupDetail.done")
    }

    private fun openPicker() {
        compose.onNodeWithTag("groupDetail").performScrollToNode(hasTestTag("groupDetail.addMember"))
        compose.onNodeWithTag("groupDetail.addMember").performClick()
        compose.await("sheet")
        compose.await("picker.title")
    }

    /** A person who can be chosen is one toggleable node holding their name; anyone else keeps their name and note as children. */
    private fun pickerRow(name: String) = compose.onNode(hasTestTag("picker.row").and(hasText(name).or(hasAnyDescendant(hasText(name)))))

    private fun choose(name: String) {
        compose.onNodeWithTag("picker.rows").performScrollToNode(hasText(name))
        pickerRow(name).performClick()
        pickerRow(name).assertIsOn()
    }

    private fun pendingRow(name: String) =
        compose.onNode(hasTestTag("groupDetail.pendingRow").and(hasAnyDescendant(hasText(name))), useUnmergedTree = true)

    // The picker's main path (smoke): leader taps Edit, Add member, picks people, Add, then Done.
    @Test
    fun leaderAddsPeopleFromThePickerAndSaves() {
        openLeadersEditMode()
        openPicker()
        compose.onNodeWithTag("picker.title").assertTextEquals(picker.text("title"))
        compose.onNodeWithTag("picker.add").assertIsNotEnabled()

        // AC2: a current member shows the backend's note and cannot be chosen.
        compose.onNodeWithTag("picker.rows").performScrollToNode(hasText("Ana Ruiz"))
        compose.onNode(
            hasTestTag("picker.row").and(hasAnyDescendant(hasText("Ana Ruiz"))).and(hasAnyDescendant(hasTestTag("personRow.note").and(hasText("Already a member")))),
        ).assertExists()
        pickerRow("Ana Ruiz").performClick()
        compose.onNodeWithTag("picker.add").assertIsNotEnabled()

        // AC4: search filters as you type and keeps chosen people chosen.
        choose("Aaliyah Davis")
        compose.onNodeWithTag("picker.search").performTextInput("zoe")
        compose.waitUntilDoesNotExist(hasText("Aaliyah Davis"), 5_000)
        choose("Zoe Laurent")
        compose.onNodeWithTag("picker.clear").performClick()
        compose.onNodeWithTag("picker.rows").performScrollToNode(hasText("Aaliyah Davis"))
        pickerRow("Aaliyah Davis").assertIsOn()

        // AC3: Add hands the chosen people back as pending rows and closes the sheet.
        compose.onNodeWithTag("picker.add").assertIsEnabled().performClick()
        compose.waitUntilDoesNotExist(hasTestTag("sheet"), 10_000)
        compose.onNodeWithTag("groupDetail").performScrollToNode(hasText("Zoe Laurent"))
        pendingRow("Aaliyah Davis").assertExists()
        pendingRow("Zoe Laurent").assertExists()

        compose.onNodeWithTag("groupDetail.done").performClick()
        compose.await("groupDetail.edit")
        compose.onAllNodesWithTag("groupDetail.pendingRow").assertCountEquals(0)
        compose.onAllNodesWithTag("message").assertCountEquals(0)
    }

    // AC1, AC3: the sheet drags down to close, handing back nothing; Cancel does the same.
    @Test
    fun draggingTheSheetDownOrCancellingAddsNobody() {
        openLeadersEditMode()
        openPicker()
        choose("Aaliyah Davis")
        compose.onNodeWithTag("sheet").performTouchInput { swipeDown() }
        compose.waitUntilDoesNotExist(hasTestTag("sheet"), 10_000)
        compose.onAllNodesWithTag("groupDetail.pendingRow").assertCountEquals(0)
        compose.await("groupDetail.done")

        // Reopening starts afresh, with nobody chosen.
        openPicker()
        compose.onNodeWithTag("picker.add").assertIsNotEnabled()
        compose.onNodeWithTag("picker.rows").performScrollToNode(hasText("Aaliyah Davis"))
        pickerRow("Aaliyah Davis").assertIsOff()
        choose("Aaliyah Davis")
        compose.onNodeWithTag("picker.cancel").assertTextEquals(picker.text("cancel_label")).performClick()
        compose.waitUntilDoesNotExist(hasTestTag("sheet"), 10_000)
        compose.onAllNodesWithTag("groupDetail.pendingRow").assertCountEquals(0)
    }
}
