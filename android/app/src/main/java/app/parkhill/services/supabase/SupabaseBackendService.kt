package app.parkhill.services.supabase

import android.content.Context
import app.parkhill.contract.Profile
import app.parkhill.contract.RpcFunction
import app.parkhill.contract.ScreenEnvelope
import app.parkhill.contract.TabsResponse
import app.parkhill.environment.AppEnvironment
import app.parkhill.services.backend.BackendError
import app.parkhill.services.backend.BackendService
import app.parkhill.services.backend.ContractJson
import io.github.jan.supabase.SupabaseClient
import io.github.jan.supabase.exceptions.HttpRequestException
import io.github.jan.supabase.exceptions.RestException
import io.github.jan.supabase.exceptions.UnauthorizedRestException
import io.github.jan.supabase.postgrest.postgrest
import io.github.jan.supabase.postgrest.rpc
import java.io.IOException
import kotlinx.coroutines.CancellationException
import kotlinx.serialization.KSerializer
import kotlinx.serialization.SerializationException
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive

/** Production [BackendService]: calls the backend's RPC functions through the shared client. */
class SupabaseBackendService(private val client: SupabaseClient) : BackendService {
    constructor(context: Context, environment: AppEnvironment) : this(SupabaseClientProvider.shared(context, environment).client)

    override suspend fun getEntry(locale: String): ScreenEnvelope =
        call(RpcFunction.getEntry, JsonObject(mapOf("p_locale" to JsonPrimitive(locale))))

    override suspend fun getScreen(key: String, locale: String, params: JsonObject): ScreenEnvelope =
        call(
            RpcFunction.getScreen,
            JsonObject(mapOf("p_key" to JsonPrimitive(key), "p_locale" to JsonPrimitive(locale), "p_params" to params)),
        )

    override suspend fun getTabs(locale: String): TabsResponse =
        call(RpcFunction.getTabs, JsonObject(mapOf("p_locale" to JsonPrimitive(locale))), TabsResponse.serializer())

    override suspend fun whoami(): Profile = call(RpcFunction.whoami, JsonObject(emptyMap()), Profile.serializer())

    override suspend fun call(function: String, params: JsonObject, locale: String) {
        try {
            client.postgrest.rpc(function, JsonObject(params + ("p_locale" to JsonPrimitive(locale))))
        } catch (error: CancellationException) {
            throw error
        } catch (error: Exception) {
            throw map(error)
        }
    }

    private suspend fun call(function: RpcFunction, params: JsonObject): ScreenEnvelope =
        call(function, params, ScreenEnvelope.serializer())

    private suspend fun <T> call(function: RpcFunction, params: JsonObject, serializer: KSerializer<T>): T {
        val body = try {
            client.postgrest.rpc(function.value, params).data
        } catch (error: CancellationException) {
            throw error
        } catch (error: Exception) {
            throw map(error)
        }
        return try {
            ContractJson.decodeFromString(serializer, body)
        } catch (error: SerializationException) {
            throw BackendError.Decoding
        } catch (error: IllegalArgumentException) {
            throw BackendError.Decoding
        }
    }

    companion object {
        /**
         * Maps SDK and transport errors to [BackendError]. Error identity
         * comes from the PostgREST `message` (contract/README.md, Errors).
         */
        fun map(error: Exception): BackendError = when (error) {
            is BackendError -> error
            is UnauthorizedRestException -> BackendError.Unauthorized
            is RestException -> when {
                error.error == "unknown_screen" -> BackendError.UnknownScreen
                error.error == "session_ended" -> BackendError.Unauthorized
                error.error == "screen_unavailable" -> BackendError.ScreenUnavailable(error.description.orEmpty())
                error.error == "action_refused" -> BackendError.ActionRefused(error.description.orEmpty())
                error.statusCode == 401 -> BackendError.Unauthorized
                else -> BackendError.Server
            }
            is HttpRequestException, is IOException -> BackendError.Network
            is SerializationException -> BackendError.Decoding
            else -> BackendError.Server
        }
    }
}
