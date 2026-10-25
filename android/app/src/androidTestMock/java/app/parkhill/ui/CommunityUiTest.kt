package app.parkhill.ui

import androidx.compose.ui.test.ExperimentalTestApi
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
import androidx.test.ext.junit.runners.AndroidJUnit4
import app.parkhill.app.MainActivity
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.boolean
import kotlinx.serialization.json.jsonArray
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

/** Mock build: each persona's Community tab from the recorded responses (AND-010 AC1, AC3, AC5; AND-011 AC4; AND-009 AC1, AC2). */
@RunWith(AndroidJUnit4::class)
@OptIn(ExperimentalTestApi::class)
class CommunityUiTest {
    @get:Rule
    val compose = createAndroidComposeRule<MainActivity>()

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

    private fun assertEmpty(persona: String) {
        val empty = recorded("$persona/get_screen.community.home.json").getValue("empty").jsonObject
        openCommunity(persona)
        compose.await("emptyState.title")
        compose.onNodeWithTag("emptyState.title").assertTextEquals(empty.text("title"))
        compose.onNodeWithTag("emptyState.message").assertTextEquals(empty.text("message"))
        compose.onAllNodesWithTag("groupRow").assertCountEquals(0)
    }

    /** The detail shows the recorded group: title, leaders line, members, leader icons and the note. */
    private fun assertDetail(group: JsonObject) {
        compose.await("groupDetail.title")
        compose.onNodeWithTag("groupDetail.title").assertTextEquals(group.text("title"))
        compose.onNodeWithTag("groupDetail.leadersLine").assertTextEquals(group.text("leaders_line"))
        val members = group.getValue("members").jsonArray.map { it.jsonObject }
        for (member in members) {
            compose.onNodeWithTag("groupDetail").performScrollToNode(hasText(member.text("title")))
            compose.onNodeWithText(member.text("title")).assertExists()
        }
        compose.onAllNodesWithTag("groupDetail.leaderIcon").assertCountEquals(members.count { it.getValue("is_leader").jsonPrimitive.boolean })
        members.firstNotNullOfOrNull { it["note"]?.jsonPrimitive?.content }?.let { note ->
            compose.onNodeWithTag("groupDetail.note").assertTextEquals(note.uppercase())
        }
    }

    private fun assertOwnGroup(persona: String) {
        val group = recorded("$persona/get_screen.community.home.json").getValue("group").jsonObject
        openCommunity(persona)
        assertDetail(group)
    }

    @Test fun attendeeSeesTheEmptyMessage() = assertEmpty("attendee")

    @Test fun staffWithNoGroupSeesTheEmptyMessage() = assertEmpty("staff")

    @Test fun memberOneSeesTheirGroup() = assertOwnGroup("member_one")

    @Test fun leaderSeesTheirGroup() = assertOwnGroup("leader")

    @Test fun adminSeesTheirGroup() = assertOwnGroup("admin")

    @Test
    fun memberTwoListsBothGroupsAndOpensEach() {
        val list = recorded("member_two/get_screen.community.home.json").getValue("my_groups").jsonObject
        val rows = list.getValue("rows").jsonArray.map { it.jsonObject }
        openCommunity("member_two")

        compose.await("groupList.title")
        compose.onNodeWithTag("groupList.title").assertTextEquals(list.text("title").uppercase())
        compose.onAllNodesWithTag("groupRow").assertCountEquals(rows.size)
        rows.forEachIndexed { index, row ->
            compose.onNodeWithText(row.text("subtitle")).assertExists()
            row["badge"]?.jsonPrimitive?.content?.let { compose.onNodeWithText(it.uppercase()).assertExists() }

            compose.onAllNodesWithTag("groupRow")[index].performClick()
            compose.waitUntilAtLeastOneExists(hasTestTag("screen.title").and(hasText(row.text("title"))), 10_000)
            val groupId = row.getValue("action").jsonObject.getValue("params").jsonObject.text("group_id")
            assertDetail(recorded("member_two/get_screen.community.group@group_id=$groupId.json"))

            if (index == 0) {
                compose.onNodeWithTag("screen.back").performClick()
            } else {
                compose.runOnUiThread { compose.activity.onBackPressedDispatcher.onBackPressed() }
            }
            compose.await("groupList.title")
            compose.onNodeWithTag("tab.title").assertTextEquals("Community")
            compose.onAllNodesWithTag("groupRow").assertCountEquals(rows.size)
        }
    }
}
