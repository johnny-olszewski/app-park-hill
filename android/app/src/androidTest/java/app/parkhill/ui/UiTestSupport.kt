package app.parkhill.ui

import androidx.compose.ui.semantics.SemanticsProperties
import androidx.compose.ui.test.ComposeTimeoutException
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

/** A signed-out launch shows sign-in well within this; longer means a session was restored. */
private const val SIGNED_OUT_TIMEOUT = 8_000L

/**
 * Waits for the signed-out entry; signs out through the dev tools menu first
 * when a previous test left a session.
 */
@OptIn(ExperimentalTestApi::class)
fun ComposeTestRule.awaitSignedOut() {
    try {
        waitUntilAtLeastOneExists(hasTestTag("signIn.email"), SIGNED_OUT_TIMEOUT)
    } catch (_: ComposeTimeoutException) {
        signOutThroughDevTools()
    }
}

/**
 * Waits for sign-in to finish, then reads who is signed in from the dev tools
 * menu's Session tool: the email, or the mock persona's id. UI tests read
 * identity there, never from production screens.
 */
@OptIn(ExperimentalTestApi::class)
fun ComposeTestRule.signedInUser(): String {
    waitUntilDoesNotExist(hasTestTag("signIn.email"), TIMEOUT)
    openDevToolsMenu()
    onNodeWithTag("devTools.menu").performScrollToNode(hasTestTag("devTools.session.user"))
    val user = onNodeWithTag("devTools.session.user").fetchSemanticsNode().config[SemanticsProperties.Text].joinToString { it.text }
    closeDevToolsMenu()
    return user
}

/** Signs out through the dev tools menu and waits for sign-in. */
fun ComposeTestRule.signOutThroughDevTools() {
    openDevToolsMenu()
    tapInDevToolsMenu("devTools.signOut")
    await("signIn.email")
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
