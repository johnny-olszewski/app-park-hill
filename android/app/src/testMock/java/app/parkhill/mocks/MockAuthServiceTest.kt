package app.parkhill.mocks

import app.parkhill.services.auth.AuthState
import app.parkhill.services.auth.AuthUser
import app.parkhill.services.auth.LocalUserData
import app.parkhill.services.auth.SessionRenewal
import app.parkhill.services.auth.SignOutReason
import app.parkhill.services.backend.BackendError
import java.io.File
import java.nio.file.Files
import kotlinx.coroutines.test.runTest
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.fail
import org.junit.Test

class MockAuthServiceTest {
    private val persona = MockPersonaState()
    private val filesDir: File = Files.createTempDirectory("files").toFile()
    private val auth = MockAuthService(persona, LocalUserData.standard(filesDir)) { "attendee" }
    private val bundled = File(checkNotNull(javaClass.classLoader?.getResource("get_entry.json")).toURI()).parentFile!!

    @Test
    fun startsSignedOut() = runTest {
        assertEquals(AuthState.SignedOut(null), auth.restoreSession())
    }

    @Test
    fun anyCredentialsSignInAsTheDefaultPersona() = runTest {
        val user = auth.signIn("anyone@example.com", "anything")
        assertEquals(AuthUser("attendee", null), user)
        assertEquals("attendee", persona.current)
        assertEquals(AuthState.SignedIn(user), auth.state.value)
    }

    @Test
    fun aPersonaSignInSwitchesTheBackendToThatPersonasFixtures() = runTest {
        val backend = MockBackendService(FixtureStore.directory(bundled), persona)
        try {
            backend.whoami()
            fail("expected Unauthorized before signing in")
        } catch (error: BackendError) {
            assertEquals(BackendError.Unauthorized, error)
        }
        auth.signIn("admin")
        assertEquals("Admin", backend.whoami().displayName)
    }

    @Test
    fun signOutClearsThePersonaAndWipesData() = runTest {
        auth.signIn("attendee")
        File(filesDir, "Cache").mkdirs()
        auth.signOut()
        assertEquals(AuthState.SignedOut(SignOutReason.UserRequest), auth.state.value)
        assertNull(persona.current)
        assertFalse(File(filesDir, "Cache").exists())
    }

    @Test
    fun endSessionEmitsSessionEnded() = runTest {
        auth.signIn("attendee")
        auth.endSession()
        assertEquals(AuthState.SignedOut(SignOutReason.SessionEnded), auth.state.value)
        assertEquals(SessionRenewal.NotSignedIn, auth.renewAfterUnauthorized())
    }

    @Test
    fun theDefaultPersonaIsTheFirstActiveOneInTheDataset() {
        val dataset = checkNotNull(javaClass.classLoader?.getResource("dataset.json")).readText()
        assertEquals("attendee", MockPersona.active(dataset).first().id)
        assertFalse(MockPersona.active(dataset).any { it.id == "disabled" })
    }
}
