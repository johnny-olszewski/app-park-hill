package app.parkhill.services.supabase

import app.parkhill.environment.BackendTarget
import app.parkhill.services.auth.SignInError
import app.parkhill.services.auth.SignInFailure
import app.parkhill.services.auth.SignInRequest
import app.parkhill.services.auth.SignInSuccess
import app.parkhill.services.backend.ContractJson
import java.io.IOException
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody

/**
 * Calls the `sign_in` Edge Function (specs/AUTH.md 5.5) with the standard
 * headers. A direct call, so a refusal's `code` and `message` reach the
 * caller unchanged.
 */
class SignInClient(private val backend: BackendTarget, private val http: OkHttpClient) {
    suspend fun signIn(request: SignInRequest): SignInSuccess = withContext(Dispatchers.IO) {
        val call = Request.Builder()
            .url("${backend.url}/functions/v1/sign_in")
            .header("apikey", backend.anonKey)
            .header("Authorization", "Bearer ${backend.anonKey}")
            .post(ContractJson.encodeToString(SignInRequest.serializer(), request).toRequestBody(JSON))
            .build()
        val (status, body) = try {
            http.newCall(call).execute().use { it.code to it.body?.string().orEmpty() }
        } catch (_: IOException) {
            throw SignInError.Network
        }
        try {
            if (status in 200..299) {
                ContractJson.decodeFromString(SignInSuccess.serializer(), body).takeIf { it.status == "ok" }
                    ?: throw SignInError.Unexpected
            } else {
                val failure = ContractJson.decodeFromString(SignInFailure.serializer(), body)
                throw SignInError.Rejected(failure.code, failure.message)
            }
        } catch (error: SignInError) {
            throw error
        } catch (_: Exception) {
            throw SignInError.Unexpected
        }
    }

    private companion object {
        val JSON = "application/json".toMediaType()
    }
}
