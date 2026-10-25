package app.parkhill.ui

import androidx.compose.ui.semantics.SemanticsProperties
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.SemanticsMatcher
import androidx.compose.ui.test.assert
import androidx.compose.ui.test.assertContentDescriptionEquals
import androidx.compose.ui.test.assertCountEquals
import androidx.compose.ui.test.assertTextEquals
import androidx.compose.ui.test.hasTestTag
import androidx.compose.ui.test.hasText
import androidx.compose.ui.test.junit4.createAndroidComposeRule
import androidx.compose.ui.test.onAllNodesWithTag
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.performScrollToNode
import androidx.compose.ui.test.performTextInput
import androidx.compose.ui.text.AnnotatedString
import androidx.test.ext.junit.runners.AndroidJUnit4
import app.parkhill.R
import app.parkhill.app.MainActivity
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.jsonArray
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import org.junit.Assert.assertTrue
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

/** Mock build: the Community toolbar and Browse all groups per persona (AND-026 AC2, AC4, AC5). */
@RunWith(AndroidJUnit4::class)
@OptIn(ExperimentalTestApi::class)
class BrowseUiTest {
    @get:Rule
    val compose = createAndroidComposeRule<MainActivity>()

    private fun recorded(path: String): JsonObject = Json.parseToJsonElement(
        checkNotNull(javaClass.classLoader?.getResourceAsStream(path)) { "$path not bundled" }.bufferedReader().readText(),
    ).jsonObject

    private fun JsonObject.text(key: String) = getValue(key).jsonPrimitive.content

    /** The recorded toolbar of the persona's Community home, by id to label. */
    private fun homeToolbar(persona: String): List<Pair<String, String>> =
        recorded("$persona/get_screen.community.home.json")["toolbar"]?.jsonArray.orEmpty()
            .map { it.jsonObject.text("id") to it.jsonObject.text("label") }

    private fun openCommunity(persona: String) {
        compose.awaitSignedOut()
        compose.armMockSignIn(persona = persona)
        compose.signIn("anyone@example.com", "anything")
        compose.await("tab.community")
        compose.onNodeWithTag("tab.community").performClick()
        compose.onNodeWithTag("tab.title").assertTextEquals("Community")
    }

    private fun search(text: String) = SemanticsMatcher.expectValue(SemanticsProperties.EditableText, AnnotatedString(text))

    private fun openBrowse() {
        compose.onNodeWithTag("toolbar.$BROWSE").performClick()
        compose.await("cover")
        compose.await("groupRow")
    }

    private fun assertSeesBrowse(persona: String) {
        val toolbar = homeToolbar(persona)
        val label = toolbar.single { it.first == BROWSE }.second
        openCommunity(persona)
        compose.await("toolbar.$BROWSE")
        compose.onNodeWithTag("toolbar.$BROWSE").assertContentDescriptionEquals(label)
    }

    private fun assertNoBrowse(persona: String) {
        assertTrue(homeToolbar(persona).isEmpty())
        openCommunity(persona)
        compose.onAllNodesWithTag("toolbar.$BROWSE").assertCountEquals(0)
    }

    @Test fun adminSeesBrowseOnTheirGroup() = assertSeesBrowse("admin")

    @Test fun memberOneSeesNoBrowse() = assertNoBrowse("member_one")

    @Test fun memberTwoSeesNoBrowse() = assertNoBrowse("member_two")

    @Test fun leaderSeesNoBrowse() = assertNoBrowse("leader")

    @Test fun attendeeSeesNoBrowse() = assertNoBrowse("attendee")

    @Test
    fun staffBrowsesSearchesOpensAGroupAndCloses() {
        val browse = recorded("staff/get_screen.community.browse.json").getValue("data").jsonObject
        val rows = browse.getValue("rows").jsonArray.map { it.jsonObject }
        val leaderless = rows.single { it["badge_tone"]?.jsonPrimitive?.content == "attention" }
        val query = "hill"
        val matching = rows.filter { it.text("title").contains(query, ignoreCase = true) }
        val opened = matching.first()
        assertSeesBrowse("staff")

        // AC4: every group with its badges, then filtered by title as you type.
        openBrowse()
        compose.waitUntilAtLeastOneExists(hasTestTag("screen.title").and(hasText(browse.text("title"))), 10_000)
        assertSeveralRows()
        compose.onNodeWithTag("groupList").performScrollToNode(hasText(leaderless.text("title")))
        compose.onNodeWithTag("groupRow.badge.attention", useUnmergedTree = true).assertTextEquals(leaderless.text("badge").uppercase())
        compose.onNodeWithTag("cover.close").assertContentDescriptionEquals(compose.activity.getString(R.string.navigation_close))
        compose.onNodeWithTag("browse.search").performTextInput(query)
        compose.onAllNodesWithTag("groupRow").assertCountEquals(matching.size)

        // AC5: a row ends the search and pushes its group inside the cover; back returns to every group.
        compose.onNodeWithText(opened.text("title")).performClick()
        compose.waitUntilAtLeastOneExists(hasTestTag("screen.title").and(hasText(opened.text("title"))), 10_000)
        compose.await("groupDetail.title")
        compose.onNodeWithTag("groupDetail.title").assertTextEquals(opened.text("title"))
        compose.onNodeWithTag("screen.back").performClick()
        compose.await("browse.search")
        compose.onNodeWithTag("browse.search").assert(search(""))
        assertSeveralRows()

        // Search again so reopening shows the search was reset.
        compose.onNodeWithTag("browse.search").performTextInput(query)
        compose.onAllNodesWithTag("groupRow").assertCountEquals(matching.size)

        // System back closes the cover; reopening starts with an empty search and every group.
        compose.runOnUiThread { compose.activity.onBackPressedDispatcher.onBackPressed() }
        compose.waitUntilDoesNotExist(hasTestTag("cover"), 10_000)
        compose.onNodeWithTag("tab.title").assertTextEquals("Community")
        openBrowse()
        compose.onNodeWithTag("browse.search").assert(search(""))
        assertSeveralRows()

        // The close button closes it too.
        compose.onNodeWithTag("cover.close").performClick()
        compose.waitUntilDoesNotExist(hasTestTag("cover"), 10_000)
        compose.onNodeWithTag("tab.title").assertTextEquals("Community")
    }

    /** More than one group shows; the list draws only the rows on screen, so it never counts them all. */
    private fun assertSeveralRows() {
        assertTrue(compose.onAllNodesWithTag("groupRow").fetchSemanticsNodes().size > 1)
    }

    private companion object {
        const val BROWSE = "browse_all_groups"
    }
}
