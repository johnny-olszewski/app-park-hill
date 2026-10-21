package app.parkhill.mocks

import app.parkhill.services.auth.AuthState
import app.parkhill.services.auth.AuthUser
import app.parkhill.services.auth.LocalUserData
import app.parkhill.services.auth.SessionRenewal
import app.parkhill.services.auth.SignInError
import app.parkhill.services.auth.SignOutReason
import app.parkhill.services.backend.ContractJson
import app.parkhill.services.backend.BackendError
import java.io.File
import java.nio.file.Files
import kotlinx.coroutines.test.runTest
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.fail
import org.junit.Test

class MockAuthServiceTest {
    private val persona = MockPersonaState()
    private val filesDir: File = Files.createTempDirectory("files").toFile()
    private val bundled = File(checkNotNull(javaClass.classLoader?.getResource("get_entry.json")).toURI()).parentFile!!
    private val dataset = checkNotNull(javaClass.classLoader?.getResource("dataset.json")).readText()
    private val scenario = MockSignInScenario(MockPersona.active(dataset))
    private val auth = MockAuthService(persona, LocalUserData.standard(filesDir), scenario, FixtureStore.directory(bundled))

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
    fun successSignsInAsTheChosenPersona() = runTest {
        scenario.persona = "admin"
        assertEquals(AuthUser("admin", null), auth.signIn("anyone@example.com", "anything"))
        assertEquals("admin", persona.current)
    }

    @Test
    fun eachArmedRefusalReturnsItsRecordedCodeAndMessage() = runTest {
        val refusals = MockSignInResult.entries.filter { it.refusalFixture != null }
        assertEquals(5, refusals.size)
        for (result in refusals) {
            scenario.result = result
            val recorded = ContractJson.parseToJsonElement(File(bundled, "${result.refusalFixture}.json").readText()).jsonObject
            try {
                auth.signIn("anyone@example.com", "anything")
                fail("expected ${result.name} to refuse")
            } catch (error: SignInError.Rejected) {
                assertEquals(recorded.getValue("code").jsonPrimitive.content, error.code)
                assertEquals(recorded.getValue("message").jsonPrimitive.content, error.message)
            }
        }
        assertNull(persona.current)
        assertEquals(AuthState.SignedOut(null), auth.state.value)
    }

    @Test
    fun armedClientFailuresThrowNetworkAndUnexpected() = runTest {
        for ((result, expected) in listOf(MockSignInResult.NoConnection to SignInError.Network, MockSignInResult.SomethingWentWrong to SignInError.Unexpected)) {
            scenario.result = result
            try {
                auth.signIn("anyone@example.com", "anything")
                fail("expected ${result.name} to fail")
            } catch (error: SignInError) {
                assertEquals(expected, error)
            }
        }
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
    fun theDefaultPersonaIsTheFirstActiveOneAndSuccessIsArmed() {
        assertEquals("attendee", scenario.persona)
        assertEquals(MockSignInResult.Success, scenario.result)
        assertFalse(scenario.personas.any { it.id == "disabled" })
    }
}
