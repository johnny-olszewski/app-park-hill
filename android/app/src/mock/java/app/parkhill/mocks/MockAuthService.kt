package app.parkhill.mocks

import android.content.Context
import app.parkhill.environment.AppEnvironment
import app.parkhill.services.auth.AuthService
import app.parkhill.services.auth.AuthState
import app.parkhill.services.auth.AuthUser
import app.parkhill.services.auth.LocalUserData
import app.parkhill.services.auth.SessionRenewal
import app.parkhill.services.auth.SignInError
import app.parkhill.services.auth.SignOutReason
import app.parkhill.services.backend.ContractJson
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive

/**
 * Mock [AuthService]: signs in as a persona with no network. The persona is
 * shared with [MockBackendService], which then returns that persona's
 * fixtures. Any credentials give the result armed in [scenario], chosen in
 * the mock menu. Not persisted: a relaunch starts signed out.
 */
class MockAuthService(
    private val personaState: MockPersonaState,
    private val localData: LocalUserData,
    val scenario: MockSignInScenario,
    private val fixtures: FixtureStore,
) : AuthService {
    constructor(context: Context, @Suppress("UNUSED_PARAMETER") environment: AppEnvironment) : this(
        MockPersonaState.shared,
        LocalUserData.standard(context.filesDir),
        MockSignInScenario(MockPersona.bundled(context)),
        FixtureStore.assets(context),
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

    /** Gives the armed result, whatever was typed: the chosen persona, a recorded refusal, or a client-side failure. */
    override suspend fun signIn(email: String, password: String): AuthUser {
        val result = scenario.result
        result.refusalFixture?.let { throw refusal(it) }
        return when (result) {
            MockSignInResult.NoConnection -> throw SignInError.Network
            MockSignInResult.SomethingWentWrong -> throw SignInError.Unexpected
            else -> signIn(scenario.persona)
        }
    }

    /** The backend's recorded refusal, with its code and message unchanged. */
    private fun refusal(fixture: String): SignInError.Rejected {
        val body = ContractJson.parseToJsonElement(checkNotNull(fixtures.text(fixture, persona = null)) { "$fixture not bundled" }).jsonObject
        return SignInError.Rejected(body.getValue("code").jsonPrimitive.content, body.getValue("message").jsonPrimitive.content)
    }

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
