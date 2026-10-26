package app.parkhill.services.backend

import app.parkhill.contract.Profile
import app.parkhill.contract.ScreenEnvelope
import app.parkhill.contract.TabsResponse
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonObject

/**
 * The only path to backend data (guide 5.1). Each flavor's binding declares
 * the implementation as `AppBackendService`. Failures are thrown as
 * [BackendError].
 */
interface BackendService {
    /** The signed-out entry screen. */
    suspend fun getEntry(locale: String): ScreenEnvelope

    /** One screen, for refresh and for screens reached by navigation. */
    suspend fun getScreen(key: String, locale: String, params: JsonObject = JsonObject(emptyMap())): ScreenEnvelope

    /** The signed-in app's tabs; refused when not signed in or no longer active. */
    suspend fun getTabs(locale: String): TabsResponse

    /** The signed-in caller's profile; refused when not signed in or no longer active. */
    suspend fun whoami(): Profile

    /**
     * A `call` action's backend function, with the action's `params` and
     * `p_locale` added. Returns the response body: `{}` for most calls,
     * which callers ignore, and a `SaveResult` for `save_group_changes`.
     */
    suspend fun call(function: String, params: JsonObject, locale: String): JsonElement
}

/** The small set of failures callers react to, never SDK errors. */
sealed class BackendError : Exception() {
    /** No response arrived. */
    data object Network : BackendError() { private fun readResolve(): Any = Network }

    /** The backend does not know the screen key. */
    data object UnknownScreen : BackendError() { private fun readResolve(): Any = UnknownScreen }

    /** Refused as unauthorized: no valid session, or access ended. */
    data object Unauthorized : BackendError() { private fun readResolve(): Any = Unauthorized }

    /** The caller may no longer see the screen (`screen_unavailable`), with the backend's message (guide 5.3 rule 9). */
    data class ScreenUnavailable(override val message: String) : BackendError()

    /** The caller may no longer make the call (`action_refused`), with the backend's message. */
    data class ActionRefused(override val message: String) : BackendError()

    /** A response arrived that does not match the contract. */
    data object Decoding : BackendError() { private fun readResolve(): Any = Decoding }

    /** Any other backend failure. */
    data object Server : BackendError() { private fun readResolve(): Any = Server }
}
