package app.parkhill.navigation

import app.parkhill.services.backend.BackendService
import app.parkhill.services.backend.ScreenEnvelope
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive

/** A [BackendService] whose entry answer each test sets. */
class StubBackendService(var entry: () -> ScreenEnvelope) : BackendService {
    var entryCalls = 0
        private set

    override suspend fun getEntry(locale: String): ScreenEnvelope {
        entryCalls += 1
        return entry()
    }

    override suspend fun getScreen(key: String, locale: String, params: JsonObject): ScreenEnvelope = entry()

    companion object {
        fun signIn(title: String = "Sign in") =
            ScreenEnvelope("auth.sign_in", JsonObject(mapOf("title" to JsonPrimitive(title))))
    }
}
