package app.parkhill.ui

import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.hasTestTag
import androidx.compose.ui.test.junit4.ComposeTestRule
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.longClick
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.performScrollToNode
import androidx.compose.ui.test.performTextInput
import androidx.compose.ui.test.performTouchInput
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.jsonArray
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive

private const val TIMEOUT = 15_000L

/** Waits for the signed-out entry; signs out first when a previous test left a session. */
@OptIn(ExperimentalTestApi::class)
fun ComposeTestRule.awaitSignedOut() {
    waitUntilAtLeastOneExists(hasTestTag("signIn.email") or hasTestTag("placeholder.signOut"), TIMEOUT)
    if (onAllNodes(hasTestTag("placeholder.signOut")).fetchSemanticsNodes().isNotEmpty()) {
        onNodeWithTag("placeholder.signOut").performClick()
    }
    waitUntilAtLeastOneExists(hasTestTag("signIn.email"), TIMEOUT)
}

@OptIn(ExperimentalTestApi::class)
fun ComposeTestRule.await(tag: String) {
    waitUntilAtLeastOneExists(hasTestTag(tag), TIMEOUT)
}

/** Long-presses the dev tools pill and waits for the menu (debug builds). */
fun ComposeTestRule.openDevToolsMenu() {
    onNodeWithTag("devTools.pill").performTouchInput { longClick() }
    await("devTools.done")
}

/** Taps the menu row tagged `tag`, scrolling the menu to it first. */
fun ComposeTestRule.tapInDevToolsMenu(tag: String) {
    onNodeWithTag("devTools.menu").performScrollToNode(hasTestTag(tag))
    onNodeWithTag(tag).performClick()
}

/** Closes the dev tools menu with Done and waits for it to go. */
@OptIn(ExperimentalTestApi::class)
fun ComposeTestRule.closeDevToolsMenu() {
    onNodeWithTag("devTools.done").performClick()
    waitUntilDoesNotExist(hasTestTag("devTools.done"), TIMEOUT)
}

fun ComposeTestRule.signIn(email: String, password: String) {
    onNodeWithTag("signIn.email").performTextInput(email)
    onNodeWithTag("signIn.password").performTextInput(password)
    onNodeWithTag("signIn.submit").performClick()
}

/** Personas, the local password and recorded responses, from `/contract`. */
object UiTestData {
    private fun json(name: String): JsonObject = Json.parseToJsonElement(
        checkNotNull(UiTestData::class.java.classLoader?.getResourceAsStream(name)) { "$name not bundled" }.bufferedReader().readText(),
    ).jsonObject

    val localPassword: String get() = json("dataset.json").getValue("local_password").jsonPrimitive.content

    fun email(persona: String): String = json("dataset.json").getValue("personas").jsonArray
        .first { it.jsonObject.getValue("id").jsonPrimitive.content == persona }
        .jsonObject.getValue("email").jsonPrimitive.content

    val wrongPasswordMessage: String get() = json("sign_in.error.json").getValue("message").jsonPrimitive.content
}
