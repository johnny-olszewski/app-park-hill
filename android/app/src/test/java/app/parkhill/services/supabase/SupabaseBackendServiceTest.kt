package app.parkhill.services.supabase

import app.parkhill.BuildConfig
import app.parkhill.environment.AppEnvironment
import app.parkhill.environment.BackendTarget
import app.parkhill.services.backend.BackendError
import kotlinx.coroutines.test.runTest
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import okhttp3.mockwebserver.MockResponse
import okhttp3.mockwebserver.MockWebServer
import okhttp3.mockwebserver.SocketPolicy
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.fail
import org.junit.Before
import org.junit.Test

/** The real client against a local HTTP server: requests, headers and error mapping. */
class SupabaseBackendServiceTest {
    private val server = MockWebServer()
    private lateinit var service: SupabaseBackendService

    @Before
    fun setUp() {
        server.start()
        val environment = AppEnvironment("Dev", BackendTarget(server.url("/").toString().trimEnd('/'), "anon-key"))
        service = SupabaseBackendService(SupabaseClientProvider.make(environment))
    }

    @After
    fun tearDown() {
        server.shutdown()
    }

    private fun respond(status: Int, body: String) {
        server.enqueue(MockResponse().setResponseCode(status).setHeader("Content-Type", "application/json").setBody(body))
    }

    private suspend fun expectError(expected: BackendError, call: suspend () -> Unit) {
        try {
            call()
            fail("expected $expected")
        } catch (error: BackendError) {
            assertEquals(expected, error)
        }
    }

    @Test
    fun getEntryCallsTheRpcWithTheLocaleAndStandardHeaders() = runTest {
        respond(200, """{"key": "auth.sign_in", "data": {"title": "Sign in"}}""")

        val envelope = service.getEntry("es")

        assertEquals("auth.sign_in", envelope.key)
        val request = server.takeRequest()
        assertEquals("/rest/v1/rpc/get_entry", request.requestUrl?.encodedPath)
        assertEquals(JsonObject(mapOf("p_locale" to JsonPrimitive("es"))), Json.parseToJsonElement(request.body.readUtf8()))
        assertEquals("dev", request.getHeader("X-App-Config"))
        assertEquals("android", request.getHeader("X-App-Platform"))
        assertEquals("${BuildConfig.VERSION_NAME} (${BuildConfig.VERSION_CODE})", request.getHeader("X-App-Version"))
        assertEquals(java.util.Locale.getDefault().language.ifEmpty { "en" }, request.getHeader("Accept-Language"))
        assertEquals("anon-key", request.getHeader("apikey"))
    }

    @Test
    fun getScreenSendsKeyLocaleAndParams() = runTest {
        respond(200, """{"key": "auth.sign_in", "data": {}}""")
        service.getScreen("auth.sign_in", "en", JsonObject(mapOf("id" to JsonPrimitive("7"))))
        val request = server.takeRequest()
        assertEquals("/rest/v1/rpc/get_screen", request.requestUrl?.encodedPath)
        assertEquals(
            Json.parseToJsonElement("""{"p_key": "auth.sign_in", "p_locale": "en", "p_params": {"id": "7"}}"""),
            Json.parseToJsonElement(request.body.readUtf8()),
        )
    }

    @Test
    fun unknownScreenMapsToUnknownScreen() = runTest {
        respond(400, """{"code": "P0001", "message": "unknown_screen", "details": null, "hint": null}""")
        expectError(BackendError.UnknownScreen) { service.getScreen("nope", "en") }
    }

    @Test
    fun sessionEndedMapsToUnauthorized() = runTest {
        respond(400, """{"code": "P0001", "message": "session_ended", "details": null, "hint": null}""")
        expectError(BackendError.Unauthorized) { service.getEntry("en") }
    }

    @Test
    fun http401MapsToUnauthorized() = runTest {
        respond(401, """{"code": "PGRST301", "message": "JWT expired", "details": null, "hint": null}""")
        expectError(BackendError.Unauthorized) { service.getEntry("en") }
    }

    @Test
    fun otherFailuresMapToServer() = runTest {
        respond(500, """{"code": "XX000", "message": "boom", "details": null, "hint": null}""")
        expectError(BackendError.Server) { service.getEntry("en") }
    }

    @Test
    fun aDroppedConnectionMapsToNetwork() = runTest {
        server.enqueue(MockResponse().setSocketPolicy(SocketPolicy.DISCONNECT_AT_START))
        expectError(BackendError.Network) { service.getEntry("en") }
    }

    @Test
    fun aBodyThatIsNotAnEnvelopeMapsToDecoding() = runTest {
        respond(200, """{"unexpected": true}""")
        expectError(BackendError.Decoding) { service.getEntry("en") }
    }
}
