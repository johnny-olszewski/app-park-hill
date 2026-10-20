package app.parkhill.mocks

import android.content.Context
import app.parkhill.environment.AppEnvironment
import app.parkhill.services.backend.BackendError
import app.parkhill.services.backend.BackendService
import app.parkhill.services.backend.ContractJson
import app.parkhill.services.backend.Profile
import app.parkhill.services.backend.ScreenEnvelope
import kotlinx.serialization.KSerializer
import kotlinx.serialization.SerializationException
import kotlinx.serialization.json.JsonObject

/**
 * Mock [BackendService]: answers from contract fixtures and makes no network
 * calls. The entry is the recorded `get_entry.json`; `getScreen` reads
 * `get_screen.<key>.json`, preferring the current persona's copy; `whoami` reads the
 * signed-in persona's `whoami.json`.
 */
class MockBackendService(
    private val fixtures: FixtureStore,
    private val personaState: MockPersonaState,
) : BackendService {
    constructor(context: Context, environment: AppEnvironment) : this(FixtureStore.assets(context), MockPersonaState.shared)

    override suspend fun getEntry(locale: String): ScreenEnvelope =
        decode("get_entry", missing = BackendError.Server)

    override suspend fun getScreen(key: String, locale: String, params: JsonObject): ScreenEnvelope =
        decode("get_screen.$key", missing = BackendError.UnknownScreen)

    override suspend fun whoami(): Profile {
        if (personaState.current == null) throw BackendError.Unauthorized
        return decode("whoami", missing = BackendError.Server, Profile.serializer())
    }

    private fun decode(name: String, missing: BackendError): ScreenEnvelope =
        decode(name, missing, ScreenEnvelope.serializer())

    private fun <T> decode(name: String, missing: BackendError, serializer: KSerializer<T>): T {
        val text = fixtures.text(name, personaState.current) ?: throw missing
        return try {
            ContractJson.decodeFromString(serializer, text)
        } catch (_: SerializationException) {
            throw BackendError.Decoding
        } catch (_: IllegalArgumentException) {
            throw BackendError.Decoding
        }
    }
}
