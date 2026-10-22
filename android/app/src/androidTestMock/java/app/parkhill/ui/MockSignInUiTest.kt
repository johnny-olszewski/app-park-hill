package app.parkhill.ui

import androidx.compose.ui.test.junit4.createAndroidComposeRule
import androidx.test.ext.junit.runners.AndroidJUnit4
import app.parkhill.app.MainActivity
import org.junit.Assert.assertEquals
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

        assertEquals("attendee", compose.signedInUser())

        compose.signOutThroughDevTools()
    }
}
