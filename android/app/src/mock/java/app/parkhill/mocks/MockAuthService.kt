package app.parkhill.mocks

import android.content.Context
import app.parkhill.environment.AppEnvironment
import app.parkhill.services.auth.AuthService
import app.parkhill.services.auth.AuthState
import app.parkhill.services.auth.AuthUser
import app.parkhill.services.auth.LocalUserData
import app.parkhill.services.auth.SessionRenewal
import app.parkhill.services.auth.SignOutReason
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow

/**
 * Mock [AuthService]: signs in as a persona with no network. The persona is
 * shared with [MockBackendService], which then returns that persona's
 * fixtures. Any credentials sign in as the first active persona; choosing the
 * persona and result comes with the mock menu (AND-022). Not persisted: a
 * relaunch starts signed out.
 */
class MockAuthService(
    private val personaState: MockPersonaState,
    private val localData: LocalUserData,
    private val defaultPersona: () -> String,
) : AuthService {
    constructor(context: Context, environment: AppEnvironment) : this(
        MockPersonaState.shared,
        LocalUserData.standard(context.filesDir),
        { MockPersona.bundled(context).first().id },
    )

    private val _state = MutableStateFlow<AuthState>(
        personaState.current?.let { AuthState.SignedIn(user(it)) } ?: AuthState.SignedOut(null),
    )
    override val state: StateFlow<AuthState> = _state.asStateFlow()

    /** Mock only: signs in as a persona from `contract/seed/dataset.json`. */
    fun signIn(persona: String): AuthUser {
        personaState.current = persona
        return user(persona).also { _state.value = AuthState.SignedIn(it) }
    }

    override suspend fun restoreSession(): AuthState = _state.value

    /** Signs in as the default persona, whatever was typed. */
    override suspend fun signIn(email: String, password: String): AuthUser = signIn(defaultPersona())

    override suspend fun signOut() {
        personaState.current = null
        localData.wipe()
        _state.value = AuthState.SignedOut(SignOutReason.UserRequest)
    }

    override suspend fun renewAfterUnauthorized(): SessionRenewal =
        if (personaState.current == null) SessionRenewal.NotSignedIn else SessionRenewal.Renewed

    override suspend fun endSession() {
        personaState.current = null
        localData.wipe()
        _state.value = AuthState.SignedOut(SignOutReason.SessionEnded)
    }

    private fun user(persona: String) = AuthUser(id = persona, email = null)
}
