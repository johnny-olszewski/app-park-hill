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

    override suspend fun restoreSession() = _state.value
    override suspend fun signIn(email: String, password: String) = AuthUser("u", email).also { _state.value = AuthState.SignedIn(it) }
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
