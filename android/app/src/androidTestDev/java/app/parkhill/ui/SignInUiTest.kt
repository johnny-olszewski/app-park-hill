package app.parkhill.ui

import androidx.compose.ui.test.assertTextEquals
import androidx.compose.ui.test.junit4.createAndroidComposeRule
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.performClick
import androidx.test.ext.junit.runners.AndroidJUnit4
import app.parkhill.app.MainActivity
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

/**
 * Dev build against local Supabase, reset recently: each run adds one failed
 * sign-in for `admin`, and 5 within 15 minutes lock it (README).
 */
@RunWith(AndroidJUnit4::class)
class SignInUiTest {
    @get:Rule
    val compose = createAndroidComposeRule<MainActivity>()

    @Test
    fun signInStaysSignedInAcrossARelaunchThenSignsOut() {
        val email = UiTestData.email("attendee")
        compose.awaitSignedOut()
        compose.signIn(email, UiTestData.localPassword)

        compose.await("placeholder.user")
        compose.onNodeWithTag("placeholder.user").assertTextEquals(email)

        compose.activityRule.scenario.recreate()
        compose.await("placeholder.user")

        compose.onNodeWithTag("placeholder.signOut").performClick()
        compose.await("signIn.email")
    }

    @Test
    fun aWrongPasswordShowsTheBackendsMessage() {
        compose.awaitSignedOut()
        compose.signIn(UiTestData.email("admin"), "not-the-password")

        compose.await("signIn.error")
        compose.onNodeWithTag("signIn.error").assertTextEquals(UiTestData.wrongPasswordMessage)
    }
}
