package app.parkhill.services.supabase

import app.parkhill.environment.AppEnvironment
import app.parkhill.environment.BackendTarget
import app.parkhill.services.auth.AuthState
import app.parkhill.services.auth.AuthUser
import app.parkhill.services.auth.LocalUserData
import app.parkhill.services.auth.SessionRenewal
import app.parkhill.services.auth.SignInError
import app.parkhill.services.auth.SignOutReason
import io.github.jan.supabase.auth.MemorySessionManager
import java.io.File
import java.nio.file.Files
import kotlinx.coroutines.runBlocking
import okhttp3.mockwebserver.Dispatcher
import okhttp3.mockwebserver.MockResponse
import okhttp3.mockwebserver.MockWebServer
import okhttp3.mockwebserver.RecordedRequest
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.fail
import org.junit.Before
import org.junit.Test

/** The real supabase-kt client against a local server playing the backend's auth endpoints. */
class SupabaseAuthServiceTest {
    private val server = MockWebServer()
    private val filesDir: File = Files.createTempDirectory("files").toFile()
    private val sessions = MemorySessionManager()
    private lateinit var service: SupabaseAuthService

    /** What the token endpoint answers on renewal; set per test. */
    private var refresh: MockResponse = MockResponse().setBody(SESSION)

    @Before
    fun setUp() {
        server.dispatcher = object : Dispatcher() {
            override fun dispatch(request: RecordedRequest): MockResponse = when (request.requestUrl?.encodedPath) {
                "/functions/v1/sign_in" -> MockResponse().setBody(SIGN_IN_OK)
                "/auth/v1/user" -> MockResponse().setBody(USER)
                "/auth/v1/token" -> refresh
                "/auth/v1/logout" -> MockResponse().setResponseCode(204)
                else -> MockResponse().setResponseCode(404)
            }
        }
        server.start()
        val target = BackendTarget(server.url("/").toString().trimEnd('/'), "anon-key")
        val environment = AppEnvironment("Dev", target)
        val http = SupabaseClientProvider.httpClient(environment)
        service = SupabaseAuthService(
            client = SupabaseClientProvider.make(environment, sessions, http),
            signInClient = SignInClient(target, http),
            sessions = sessions,
            localData = LocalUserData.standard(filesDir),
            locale = { "en" },
        )
    }

    @After
    fun tearDown() {
        server.shutdown()
    }

    private fun populateUserData() {
        File(filesDir, "Cache/entry").mkdirs()
        File(filesDir, "Cache/entry/en.json").writeText("{}")
    }

    @Test
    fun startsSignedOutWithNoStoredSession() = runBlocking {
        assertEquals(AuthState.SignedOut(null), service.restoreSession())
    }

    @Test
    fun signInStoresTheSessionAndEmitsSignedIn() = runBlocking {
        val user = service.signIn("attendee@parkhill.test", "secret")
        assertEquals(AuthUser("u1", "attendee@parkhill.test"), user)
        assertEquals(AuthState.SignedIn(user), service.state.value)
        assertNotNull(sessions.loadSession())
    }

    @Test
    fun aRefusedSignInKeepsTheBackendMessage() = runBlocking {
        server.dispatcher = object : Dispatcher() {
            override fun dispatch(request: RecordedRequest) =
                MockResponse().setResponseCode(401).setBody("""{"status": "error", "code": "invalid_credentials", "message": "No match."}""")
        }
        try {
            service.signIn("attendee@parkhill.test", "wrong")
            fail("expected a refusal")
        } catch (error: SignInError) {
            assertEquals(SignInError.Rejected("invalid_credentials", "No match."), error)
        }
        assertEquals(AuthState.SignedOut(null), service.state.value)
    }

    @Test
    fun aRefusedRenewalEndsTheSessionAndWipesData() = runBlocking {
        service.signIn("attendee@parkhill.test", "secret")
        populateUserData()
        refresh = MockResponse().setResponseCode(400).setBody("""{"error": "invalid_grant", "error_description": "Refresh token revoked"}""")

        assertEquals(SessionRenewal.Refused, service.renewAfterUnauthorized())
        assertEquals(AuthState.SignedOut(SignOutReason.SessionEnded), service.state.value)
        assertNull(sessions.loadSession())
        assertFalse(File(filesDir, "Cache").exists())
    }

    @Test
    fun aRenewalWithNoNetworkKeepsTheSession() = runBlocking {
        service.signIn("attendee@parkhill.test", "secret")
        server.shutdown() // No server at all: the connection is refused.

        assertEquals(SessionRenewal.Network, service.renewAfterUnauthorized())
        assertNotNull(sessions.loadSession())
    }

    @Test
    fun signOutWipesEverythingEvenWhenTheRevokeFails() = runBlocking {
        service.signIn("attendee@parkhill.test", "secret")
        populateUserData()
        server.shutdown() // Offline: the revoke cannot reach the server.

        service.signOut()

        assertEquals(AuthState.SignedOut(SignOutReason.UserRequest), service.state.value)
        assertNull(sessions.loadSession())
        assertFalse(File(filesDir, "Cache").exists())
    }

    @Test
    fun withNothingToRenewItSaysSo() = runBlocking {
        assertEquals(SessionRenewal.NotSignedIn, service.renewAfterUnauthorized())
    }

    private companion object {
        const val USER = """{"id": "u1", "aud": "authenticated", "email": "attendee@parkhill.test"}"""
        const val SESSION = """{"access_token": "access2", "refresh_token": "refresh2", "expires_in": 3600, "token_type": "bearer", "user": $USER}"""
        const val SIGN_IN_OK = """{"status": "ok", "session": {"access_token": "access", "refresh_token": "refresh", "expires_at": 0, "user_id": "u1"}}"""
    }
}
