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

/** Mock build: the production sign-in signs in with any credentials, with no network (AND-006 AC8). */
@RunWith(AndroidJUnit4::class)
class MockSignInUiTest {
    @get:Rule
    val compose = createAndroidComposeRule<MainActivity>()

    @Test
    fun anyCredentialsSignInAsTheFirstPersonaThenSignOut() {
        compose.awaitSignedOut()
        compose.armMockSignIn()
        compose.signIn("anyone@example.com", "anything")

        compose.await("placeholder.user")
        compose.onNodeWithTag("placeholder.user").assertTextEquals("attendee")

        compose.onNodeWithTag("placeholder.signOut").performClick()
        compose.await("signIn.email")
    }
}
