package app.parkhill.services.supabase

import app.parkhill.environment.AppEnvironment
import app.parkhill.environment.BackendTarget
import app.parkhill.services.auth.SignInError
import app.parkhill.services.auth.SignInRequest
import kotlinx.coroutines.test.runTest
import kotlinx.serialization.json.Json
import okhttp3.mockwebserver.MockResponse
import okhttp3.mockwebserver.MockWebServer
import okhttp3.mockwebserver.SocketPolicy
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.fail
import org.junit.Before
import org.junit.Test

class SignInClientTest {
    private val server = MockWebServer()
    private lateinit var client: SignInClient
    private val request = SignInRequest("attendee@parkhill.test", "secret", "en")

    @Before
    fun setUp() {
        server.start()
        val target = BackendTarget(server.url("/").toString().trimEnd('/'), "anon-key")
        client = SignInClient(target, SupabaseClientProvider.httpClient(AppEnvironment("Local", target)))
    }

    @After
    fun tearDown() {
        server.shutdown()
    }

    private suspend fun expect(expected: SignInError) {
        try {
            client.signIn(request)
            fail("expected $expected")
        } catch (error: SignInError) {
            assertEquals(expected, error)
        }
    }

    @Test
    fun postsTheCredentialsToSignInWithTheStandardHeaders() = runTest {
        server.enqueue(MockResponse().setBody(OK))
        val success = client.signIn(request)
        assertEquals("access", success.session.accessToken)
        val sent = server.takeRequest()
        assertEquals("/functions/v1/sign_in", sent.requestUrl?.encodedPath)
        assertEquals("POST", sent.method)
        assertEquals(Json.parseToJsonElement("""{"email": "attendee@parkhill.test", "password": "secret", "locale": "en"}"""), Json.parseToJsonElement(sent.body.readUtf8()))
        assertEquals("anon-key", sent.getHeader("apikey"))
        assertEquals("local", sent.getHeader("X-App-Config"))
        assertEquals("android", sent.getHeader("X-App-Platform"))
    }

    @Test
    fun aRefusalCarriesTheBackendsCodeAndMessage() = runTest {
        server.enqueue(MockResponse().setResponseCode(401).setBody("""{"status": "error", "code": "invalid_credentials", "message": "That email and password don't match."}"""))
        expect(SignInError.Rejected("invalid_credentials", "That email and password don't match."))
    }

    @Test
    fun noResponseIsANetworkError() = runTest {
        server.enqueue(MockResponse().setSocketPolicy(SocketPolicy.DISCONNECT_AT_START))
        expect(SignInError.Network)
    }

    @Test
    fun aResponseOutsideTheContractIsUnexpected() = runTest {
        server.enqueue(MockResponse().setResponseCode(502).setBody("<html>Bad gateway</html>"))
        expect(SignInError.Unexpected)
    }

    private companion object {
        const val OK = """{"status": "ok", "session": {"access_token": "access", "refresh_token": "refresh", "expires_at": 0, "user_id": "u1"}}"""
    }
}
