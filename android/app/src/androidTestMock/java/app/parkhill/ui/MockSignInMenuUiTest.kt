package app.parkhill.ui

import androidx.compose.ui.test.assertTextEquals
import androidx.compose.ui.test.junit4.createAndroidComposeRule
import androidx.compose.ui.test.onNodeWithTag
import androidx.test.ext.junit.runners.AndroidJUnit4
import app.parkhill.app.MainActivity
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import org.junit.After
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

/** Mock build: sign-in through the mock menu, as any persona, with any result (AND-022 AC7). */
@RunWith(AndroidJUnit4::class)
class MockSignInMenuUiTest {
    @get:Rule
    val compose = createAndroidComposeRule<MainActivity>()

    @After
    fun disarm() {
        compose.awaitSignedOut()
        compose.armMockSignIn()
    }

    @Test
    fun successSignsInAsTheChosenPersona() {
        compose.awaitSignedOut()
        compose.armMockSignIn(persona = "admin")

        compose.signIn("anyone@example.com", "anything")

        compose.await("placeholder.user")
        compose.onNodeWithTag("placeholder.user").assertTextEquals("admin")
    }

    @Test
    fun anArmedRefusalShowsItsRecordedMessageAndAWarning() {
        compose.awaitSignedOut()
        compose.armMockSignIn(result = "TooManyAttempts")
        compose.await("devTools.pill.armed")
        compose.openDevToolsMenu()
        compose.onNodeWithTag("devTools.warning").assertExists()
        compose.closeDevToolsMenu()

        compose.signIn("anyone@example.com", "anything")

        compose.await("signIn.error")
        compose.onNodeWithTag("signIn.error").assertTextEquals(recordedMessage("sign_in.error.too_many_attempts.json"))
    }

    @Test
    fun noConnectionShowsTheCannotConnectMessage() {
        compose.awaitSignedOut()
        compose.armMockSignIn(result = "NoConnection")

        compose.signIn("anyone@example.com", "anything")

        compose.await("signIn.notice")
        compose.onNodeWithTag("signIn.notice").assertTextEquals(recordedMessage("get_screen.auth.sign_in.json", "cannot_connect_message"))
    }

    @Test
    fun switchPersonaWhileSignedIn() {
        compose.awaitSignedOut()
        compose.armMockSignIn()
        compose.signIn("anyone@example.com", "anything")
        compose.await("placeholder.user")

        compose.openDevToolsMenu()
        compose.tapInDevToolsMenu("mockPersona.admin")
        compose.closeDevToolsMenu()

        compose.onNodeWithTag("placeholder.user").assertTextEquals("admin")
    }

    private fun recordedMessage(fixture: String, field: String = "message"): String {
        val text = checkNotNull(javaClass.classLoader?.getResourceAsStream(fixture)) { "$fixture not bundled" }.bufferedReader().readText()
        val root = Json.parseToJsonElement(text).jsonObject
        return (root["data"]?.jsonObject ?: root).getValue(field).jsonPrimitive.content
    }
}
