package app.parkhill.services.auth

import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow

/** An [AuthService] whose renewal outcome each test sets. */
class FakeAuthService(var renewal: SessionRenewal = SessionRenewal.Renewed) : AuthService {
    private val _state = MutableStateFlow<AuthState>(AuthState.SignedOut(null))
    override val state: StateFlow<AuthState> = _state
    var renewals = 0
        private set
    var endedSessions = 0
        private set

    fun send(state: AuthState) {
        _state.value = state
    }

    /** What `restoreSession` reports; defaults to the current state. */
    var restored: AuthState? = null

    /** Thrown by `signIn` instead of succeeding, when set. */
    var signInFailure: SignInError? = null
    var signIns = 0
        private set

    override suspend fun restoreSession() = (restored ?: _state.value).also { _state.value = it }

    override suspend fun signIn(email: String, password: String): AuthUser {
        signIns += 1
        signInFailure?.let { throw it }
        return AuthUser("u", email).also { _state.value = AuthState.SignedIn(it) }
    }
    override suspend fun signOut() {
        _state.value = AuthState.SignedOut(SignOutReason.UserRequest)
    }

    override suspend fun renewAfterUnauthorized(): SessionRenewal {
        renewals += 1
        return renewal
    }

    override suspend fun endSession() {
        endedSessions += 1
        _state.value = AuthState.SignedOut(SignOutReason.SessionEnded)
    }
}
