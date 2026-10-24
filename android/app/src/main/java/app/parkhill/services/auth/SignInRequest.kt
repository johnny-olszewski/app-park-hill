package app.parkhill.services.auth

import kotlinx.serialization.Serializable

/**
 * The `sign_in` Edge Function request body (contract/README.md, specs/AUTH.md 5.5).
 * Its responses are the generated `SignInSuccess` and `SignInFailure`.
 */
@Serializable
data class SignInRequest(val email: String, val password: String, val locale: String)
