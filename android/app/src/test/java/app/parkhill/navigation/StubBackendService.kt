package app.parkhill.navigation

import app.parkhill.services.backend.BackendError
import app.parkhill.services.backend.BackendService
import app.parkhill.services.backend.Profile
import app.parkhill.services.backend.ScreenEnvelope
import app.parkhill.services.backend.TabItem
import app.parkhill.services.backend.TabsResponse
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive

/** A [BackendService] whose entry and tabs answers each test sets. */
class StubBackendService(var entry: () -> ScreenEnvelope) : BackendService {
    var entryCalls = 0
        private set

    override suspend fun getEntry(locale: String): ScreenEnvelope {
        entryCalls += 1
        return entry()
    }

    override suspend fun getScreen(key: String, locale: String, params: JsonObject): ScreenEnvelope = entry()

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
