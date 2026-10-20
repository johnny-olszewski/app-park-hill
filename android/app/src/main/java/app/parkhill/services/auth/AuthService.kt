package app.parkhill.services.auth

import kotlinx.coroutines.flow.StateFlow

/**
 * Sign-in, session and sign-out (specs/AUTH.md 6.1). Each flavor's binding
 * declares the implementation as `AppAuthService`.
 */
interface AuthService {
    /** The current state; every change, including sign-outs the app did not ask for. */
    val state: StateFlow<AuthState>

    /**
     * Launch: whether a usable session exists. A stored session counts as
     * signed in even when it cannot be renewed because the device is offline.
     */
    suspend fun restoreSession(): AuthState

    /** Signs in through the backend. Throws [SignInError], carrying the backend's message unchanged. */
    suspend fun signIn(email: String, password: String): AuthUser

    /** Revokes the session when online and always deletes everything about the user on the device. */
    suspend fun signOut()

    /** After a request was refused as unauthorized: renews once. A refused renewal ends the session. */
    suspend fun renewAfterUnauthorized(): SessionRenewal

    /** Signs out because access ended: wipes local data and emits signed out with [SignOutReason.SessionEnded]. */
    suspend fun endSession()
}

data class AuthUser(val id: String, val email: String?)

sealed interface AuthState {
    data class SignedIn(val user: AuthUser) : AuthState

    /** `reason` is null when nobody has signed in on this launch. */
    data class SignedOut(val reason: SignOutReason?) : AuthState
}

enum class SignOutReason {
    /** The user signed out. */
    UserRequest,

    /** Access ended: renewal refused, account disabled or session revoked. */
    SessionEnded,
}

sealed class SignInError : Exception() {
    /** The backend refused; show `message` as given. */
    data class Rejected(val code: String, override val message: String) : SignInError()

    /** No response arrived. */
    data object Network : SignInError() { private fun readResolve(): Any = Network }

    /** A response arrived that does not match the contract. */
    data object Unexpected : SignInError() { private fun readResolve(): Any = Unexpected }
}

enum class SessionRenewal {
    Renewed,

    /** Renewal was refused; the session has been ended. */
    Refused,

    /** Renewal could not reach the backend; the session is kept. */
    Network,

    /** There was no session to renew. */
    NotSignedIn,
}
