package app.parkhill.navigation

import app.parkhill.contract.Profile
import app.parkhill.contract.ScreenEnvelope
import app.parkhill.contract.TabItem
import app.parkhill.contract.TabsResponse
import app.parkhill.services.backend.BackendError
import app.parkhill.services.backend.BackendService
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive

/** A [BackendService] whose entry, screen, tabs and call answers each test sets. */
class StubBackendService(var entry: () -> ScreenEnvelope) : BackendService {
    var entryCalls = 0
        private set

    override suspend fun getEntry(locale: String): ScreenEnvelope {
        entryCalls += 1
        return entry()
    }

    /** Answers `getScreen`; by default the entry. */
    var screen: (key: String, params: JsonObject) -> ScreenEnvelope = { _, _ -> entry() }
    val screenCalls = mutableListOf<Pair<String, JsonObject>>()

    override suspend fun getScreen(key: String, locale: String, params: JsonObject): ScreenEnvelope {
        screenCalls += key to params
        return screen(key, params)
    }

    var tabs: () -> TabsResponse = { throw BackendError.Server }
    val tabsCalls = mutableListOf<String>()

    override suspend fun getTabs(locale: String): TabsResponse {
        tabsCalls += locale
        return tabs()
    }

    var profile: () -> Profile = { Profile("u", "User") }
    var whoamiCalls = 0
        private set

    override suspend fun whoami(): Profile {
        whoamiCalls += 1
        return profile()
    }

    /** Answers `call`; by default a success. */
    var callResult: (function: String) -> Unit = {}
    val calls = mutableListOf<Triple<String, JsonObject, String>>()

    override suspend fun call(function: String, params: JsonObject, locale: String) {
        calls += Triple(function, params, locale)
        callResult(function)
    }

    companion object {
        /** Tabs with empty root screens, one per `id to screen key`, in order. */
        fun tabs(vararg tabs: Pair<String, String>) = TabsResponse(
            tabs.map { (id, key) ->
                TabItem(id, id.replaceFirstChar(Char::uppercase), "tab.$id", ScreenEnvelope(key, JsonObject(emptyMap())))
            },
        )

        fun signIn(title: String = "Sign in") = ScreenEnvelope(
            "auth.sign_in",
            JsonObject(
                mapOf(
                    "title" to JsonPrimitive(title),
                    "email_label" to JsonPrimitive("Email"),
                    "password_label" to JsonPrimitive("Password"),
                    "submit_label" to JsonPrimitive("Sign in"),
                    "cannot_connect_message" to JsonPrimitive("Can't connect."),
                    "session_ended_message" to JsonPrimitive("You've been signed out."),
                    "secondary_actions" to JsonArray(emptyList()),
                ),
            ),
        )
    }
}
