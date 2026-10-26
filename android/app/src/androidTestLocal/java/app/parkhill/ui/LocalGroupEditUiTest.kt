package app.parkhill.ui

import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.assertTextContains
import androidx.compose.ui.test.assertTextEquals
import androidx.compose.ui.test.hasAnyAncestor
import androidx.compose.ui.test.hasAnyDescendant
import androidx.compose.ui.test.hasTestTag
import androidx.compose.ui.test.hasText
import androidx.compose.ui.test.junit4.createAndroidComposeRule
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.performScrollToNode
import androidx.compose.ui.test.performTextReplacement
import androidx.test.ext.junit.runners.AndroidJUnit4
import app.parkhill.app.MainActivity
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.jsonArray
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

/**
 * Local build against local Supabase: group edit mode saved for real
 * (AND-013 AC3, AC5; EP-03.D B1, B4). Every group a test changes gets its
 * members, leaders and details back when it ends. Start it first:
 * `cd backend && supabase start && supabase db reset`.
 */
@RunWith(AndroidJUnit4::class)
@OptIn(ExperimentalTestApi::class)
class LocalGroupEditUiTest {
    @get:Rule(order = 0)
    val groups = LocalGroupRows()

    @get:Rule(order = 1)
    val compose = createAndroidComposeRule<MainActivity>()

    /** Tuesday Night Group from the leader's recorded Community home, and everyone the picker lists: the seed's ids. */
    private fun recorded(path: String): JsonObject = Json.parseToJsonElement(
        checkNotNull(javaClass.classLoader?.getResourceAsStream(path)) { "$path not bundled" }.bufferedReader().readText(),
    ).jsonObject.getValue("data").jsonObject

    private val tuesdayNight = recorded("leader/get_screen.community.home.json").getValue("group").jsonObject
    private val groupId = tuesdayNight.getValue("group_id").jsonPrimitive.content
    private val people = recorded("leader/get_screen.people.picker@group_id=$groupId.json").getValue("rows").jsonArray.map { it.jsonObject }

    private fun userId(name: String) = people.first { it.getValue("title").jsonPrimitive.content == name }.getValue("user_id").jsonPrimitive.content

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

    private fun edit() {
        compose.await("groupDetail.edit")
        compose.onNodeWithTag("groupDetail.edit").performClick()
        compose.await("groupDetail.done")
    }

    private fun done() {
        compose.onNodeWithTag("groupDetail.done").performClick()
        compose.await("groupDetail.edit")
    }

    /** The control tagged `tag` in the edit row showing `name`. */
    private fun inRow(name: String, tag: String) = compose.onNode(
        hasTestTag(tag).and(hasAnyAncestor(hasTestTag("groupDetail.editRow").and(hasAnyDescendant(hasText(name))))),
        useUnmergedTree = true,
    )

    private fun scrollTo(name: String) {
        compose.onNodeWithTag("groupDetail").performScrollToNode(hasText(name))
    }

    // B1, and the picker's main path against local Supabase (smoke).
    @Test
    fun leaderEditsDetailsAddsAndRemovesMembersAndTheyStayAfterRelaunch() {
        groups.keep(groupId)
        openCommunity("leader")
        edit()

        compose.onNodeWithTag("groupDetail.field.name").performTextReplacement("Tuesday Supper Club")
        compose.onNodeWithTag("groupDetail.field.location").performTextReplacement("Park home")
        scrollTo("Ana Ruiz")
        inRow("Ana Ruiz", "groupDetail.removeRow").performClick()

        compose.onNodeWithTag("groupDetail").performScrollToNode(hasTestTag("groupDetail.addMember"))
        compose.onNodeWithTag("groupDetail.addMember").performClick()
        compose.await("picker.title")
        compose.onNodeWithTag("picker.rows").performScrollToNode(hasText("Zoe Laurent"))
        compose.onNode(hasTestTag("picker.row").and(hasText("Zoe Laurent"))).performClick()
        compose.onNodeWithTag("picker.add").performClick()
        compose.waitUntilDoesNotExist(hasTestTag("sheet"), 10_000)
        done()

        compose.onNodeWithTag("groupDetail").performScrollToNode(hasTestTag("groupDetail.title"))
        compose.onNodeWithTag("groupDetail.title").assertTextEquals("Tuesday Supper Club")
        val members = groups.members(groupId)
        assertTrue(userId("Zoe Laurent") in members)
        assertFalse(userId("Ana Ruiz") in members)
        assertEquals("Park home", groups.details(groupId).getValue("location").jsonPrimitive.content)

        compose.activityRule.scenario.recreate()
        compose.await("tab.community")
        compose.onNodeWithTag("tab.community").performClick()
        compose.await("groupDetail.title")
        compose.onNodeWithTag("groupDetail.title").assertTextEquals("Tuesday Supper Club")
        compose.onNodeWithTag("groupDetail.location").assertTextEquals("Park home")
        scrollTo("Zoe Laurent")
    }

    // B4: staff make someone a leader.
    @Test
    fun staffMakeSomeoneALeader() {
        groups.keep(groupId)
        openCommunity("staff")
        compose.await("toolbar.browse_all_groups")
        compose.onNodeWithTag("toolbar.browse_all_groups").performClick()
        compose.await("browse.search")
        val title = tuesdayNight.getValue("title").jsonPrimitive.content
        compose.onNodeWithTag("groupList").performScrollToNode(hasText(title))
        compose.onNodeWithText(title).performClick()
        compose.waitUntilAtLeastOneExists(hasTestTag("screen.title").and(hasText(title)), 10_000)
        edit()

        scrollTo("Ana Ruiz")
        inRow("Ana Ruiz", "groupDetail.leaderToggle").performClick()
        done()

        compose.onNodeWithTag("groupDetail").performScrollToNode(hasTestTag("groupDetail.leadersLine"))
        compose.onNodeWithTag("groupDetail.leadersLine").assertTextContains("Ana Ruiz", substring = true)
        assertTrue(userId("Ana Ruiz") in groups.leaders(groupId))
    }

    // B3: a save with a problem saves nothing, stays in edit mode and shows it at its field.
    @Test
    fun aFailedSaveSavesNothingAndShowsTheProblemAtItsField() {
        groups.keep(groupId)
        openCommunity("leader")
        edit()

        compose.onNodeWithTag("groupDetail.field.location").performTextReplacement("Park home")
        compose.onNodeWithTag("groupDetail.field.name").performTextReplacement("")
        compose.onNodeWithTag("groupDetail.done").performClick()

        compose.waitUntilAtLeastOneExists(hasText("Enter a name."), 10_000)
        compose.await("groupDetail.done")
        compose.onNodeWithTag("groupDetail.field.location").assertTextContains("Park home")
        assertEquals("Lee home, North Park", groups.details(groupId).getValue("location").jsonPrimitive.content)

        compose.onNodeWithTag("groupDetail.cancel").performClick()
        compose.await("groupDetail.edit")
        compose.onNodeWithTag("groupDetail.location").assertTextEquals("Lee home, North Park")
    }
}
