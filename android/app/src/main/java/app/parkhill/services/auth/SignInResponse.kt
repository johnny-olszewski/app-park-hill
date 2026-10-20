package app.parkhill.services.auth

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

/** `sign_in` Edge Function responses (contract/README.md, specs/AUTH.md 5.5). */
@Serializable
data class SignInSuccess(val status: String, val session: Session) {
    @Serializable
    data class Session(
        @SerialName("access_token") val accessToken: String,
        @SerialName("refresh_token") val refreshToken: String,
        @SerialName("expires_at") val expiresAt: Double,
        @SerialName("user_id") val userId: String,
    )
}

@Serializable
data class SignInFailure(val status: String, val code: String, val message: String)

/** The request body. */
@Serializable
data class SignInRequest(val email: String, val password: String, val locale: String)
