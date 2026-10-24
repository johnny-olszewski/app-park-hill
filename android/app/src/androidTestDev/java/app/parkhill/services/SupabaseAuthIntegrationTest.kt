package app.parkhill.services

import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import app.parkhill.environment.ServiceBinding
import app.parkhill.services.auth.AuthState
import app.parkhill.services.auth.LocalUserData
import app.parkhill.services.backend.BackendError
import app.parkhill.services.backend.ContractJson
import app.parkhill.services.backend.TabsResponse
import app.parkhill.services.supabase.EncryptedSessionManager
import app.parkhill.services.supabase.KeystoreSessionCipher
import app.parkhill.services.supabase.SignInClient
import app.parkhill.services.supabase.SupabaseAuthService
import app.parkhill.services.supabase.SupabaseBackendService
import app.parkhill.services.supabase.SupabaseClientProvider
import java.io.File
import kotlinx.coroutines.runBlocking
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.jsonArray
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Assert.fail
import org.junit.Test
import org.junit.runner.RunWith

/**
 * Dev against the configured backend (local Supabase, reset recently): the
 * token reaches the backend, survives a fresh client, and sign-out ends access.
 */
@RunWith(AndroidJUnit4::class)
class SupabaseAuthIntegrationTest {
    private val context = InstrumentationRegistry.getInstrumentation().targetContext
    private val environment = ServiceBinding.environment
    private val dataset = Json.parseToJsonElement(
        checkNotNull(javaClass.classLoader?.getResourceAsStream("dataset.json")).bufferedReader().readText(),
    ).jsonObject
    private val password = dataset.getValue("local_password").jsonPrimitive.content
    private val attendeeEmail = dataset.getValue("personas").jsonArray
        .first { it.jsonObject.getValue("id").jsonPrimitive.content == "attendee" }
        .jsonObject.getValue("email").jsonPrimitive.content

    /** A complete auth and backend stack on its own client, sharing one session file. */
    private class Stack(context: android.content.Context, environment: app.parkhill.environment.AppEnvironment, sessionFile: File) {
        val sessions = EncryptedSessionManager(sessionFile, KeystoreSessionCipher(alias = "park_hill_session_integration"))
        val http = SupabaseClientProvider.httpClient(environment)
        val client = SupabaseClientProvider.make(environment, sessions, http)
        val auth = SupabaseAuthService(client, SignInClient(checkNotNull(environment.backend), http), sessions, LocalUserData.standard(context.cacheDir))
        val backend = SupabaseBackendService(client)
    }

    @Test
    fun signInReachesTheBackendSurvivesAFreshClientAndSignOutEndsAccess() = runBlocking {
        val sessionFile = File(context.cacheDir, "integration/session.bin").apply { delete() }
        val first = Stack(context, environment, sessionFile)

        first.auth.signIn(attendeeEmail, password)
        assertEquals("Attendee", first.backend.whoami().displayName)

        val relaunched = Stack(context, environment, sessionFile)
        assertTrue("stored session restores", relaunched.auth.restoreSession() is AuthState.SignedIn)
        assertEquals("Attendee", relaunched.backend.whoami().displayName)

        relaunched.auth.signOut()
        try {
            relaunched.backend.whoami()
            fail("expected Unauthorized after sign-out")
        } catch (error: BackendError) {
            assertEquals(BackendError.Unauthorized, error)
        }
    }

    @Test
    fun signedInTabsMatchTheMockResponseAndSignedOutIsRefused() = runBlocking {
        val stack = Stack(context, environment, File(context.cacheDir, "integration/tabs-session.bin").apply { delete() })
        try {
            stack.backend.getTabs("en")
            fail("expected Unauthorized before signing in")
        } catch (error: BackendError) {
            assertEquals(BackendError.Unauthorized, error)
        }

        stack.auth.signIn(attendeeEmail, password)
        val mockResponse = checkNotNull(javaClass.classLoader?.getResourceAsStream("attendee/get_tabs.json")).bufferedReader().readText()
        assertEquals(ContractJson.decodeFromString(TabsResponse.serializer(), mockResponse), stack.backend.getTabs("en"))
        stack.auth.signOut()
    }
}
