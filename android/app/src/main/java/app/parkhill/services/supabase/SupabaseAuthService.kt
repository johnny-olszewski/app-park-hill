package app.parkhill.services.supabase

import android.content.Context
import app.parkhill.app.AppLocale
import app.parkhill.environment.AppEnvironment
import app.parkhill.services.auth.AuthService
import app.parkhill.services.auth.AuthState
import app.parkhill.services.auth.AuthUser
import app.parkhill.services.auth.LocalUserData
import app.parkhill.services.auth.SessionRenewal
import app.parkhill.services.auth.SignInError
import app.parkhill.services.auth.SignInRequest
import app.parkhill.services.auth.SignOutReason
import io.github.jan.supabase.SupabaseClient
import io.github.jan.supabase.auth.SessionManager
import io.github.jan.supabase.auth.auth
import io.github.jan.supabase.auth.status.SessionStatus
import io.github.jan.supabase.auth.user.UserInfo
import io.github.jan.supabase.exceptions.HttpRequestException
import io.github.jan.supabase.exceptions.RestException
import java.io.IOException
import java.util.concurrent.atomic.AtomicBoolean
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

/**
 * Production [AuthService]: signs in through the backend's `sign_in`
 * function, then hands the session to the shared Supabase client, which
 * stores it encrypted and renews it. Renewal and sign-out use the client
 * library directly (specs/AUTH.md 5.5 rule 3).
 */
class SupabaseAuthService(
    private val client: SupabaseClient,
    private val signInClient: SignInClient,
    private val sessions: SessionManager,
    private val localData: LocalUserData,
    private val locale: () -> String = { AppLocale.current() },
) : AuthService {
    constructor(context: Context, environment: AppEnvironment) : this(
        SupabaseClientProvider.shared(context, environment),
        environment,
        LocalUserData.standard(context.filesDir),
    )

    private constructor(shared: SupabaseClientProvider.Shared, environment: AppEnvironment, localData: LocalUserData) : this(
        client = shared.client,
        signInClient = SignInClient(checkNotNull(environment.backend), shared.http),
        sessions = shared.sessions,
        localData = localData,
    )

    private val _state = MutableStateFlow<AuthState>(AuthState.SignedOut(null))
    override val state: StateFlow<AuthState> = _state.asStateFlow()

    /** True while the app itself is signing out, so the client's resulting sign-out is not mistaken for access ending. */
    private val signingOut = AtomicBoolean(false)
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Default)

    init {
        observeClientEvents()
    }

    override suspend fun restoreSession(): AuthState {
        val hadStoredSession = sessions.loadSession() != null
        client.auth.awaitInitialization()
        when (val status = client.auth.sessionStatus.value) {
            is SessionStatus.Authenticated -> _state.value = signedIn(status.session.user)
            // Offline: the stored session still counts (specs/AUTH.md 4.3 rule 5).
            is SessionStatus.RefreshFailure -> _state.value =
                client.auth.currentSessionOrNull()?.let { signedIn(it.user) } ?: AuthState.SignedOut(null)
            else -> if (hadStoredSession) endSession() else _state.value = AuthState.SignedOut(null)
        }
        return _state.value
    }

    override suspend fun signIn(email: String, password: String): AuthUser {
        signingOut.set(false)
        val success = signInClient.signIn(SignInRequest(email, password, locale()))
        try {
            client.auth.importAuthToken(
                success.session.accessToken,
                success.session.refreshToken,
                retrieveUser = true,
                autoRefresh = true,
            )
        } catch (error: CancellationException) {
            throw error
        } catch (error: Exception) {
            throw if (isTransient(error)) SignInError.Network else SignInError.Unexpected
        }
        val user = client.auth.currentSessionOrNull()?.user?.let(::authUser) ?: AuthUser(success.session.userId, null)
        _state.value = AuthState.SignedIn(user)
        return user
    }

    override suspend fun signOut() {
        clearSession()
        _state.value = AuthState.SignedOut(SignOutReason.UserRequest)
    }

    override suspend fun renewAfterUnauthorized(): SessionRenewal {
        if (client.auth.currentSessionOrNull() == null) return SessionRenewal.NotSignedIn
        return try {
            client.auth.refreshCurrentSession()
            client.auth.currentSessionOrNull()?.user?.let { _state.value = signedIn(it) }
            SessionRenewal.Renewed
        } catch (error: CancellationException) {
            throw error
        } catch (error: Exception) {
            if (isTransient(error)) {
                SessionRenewal.Network
            } else {
                endSession()
                SessionRenewal.Refused
            }
        }
    }

    override suspend fun endSession() {
        clearSession()
        _state.value = AuthState.SignedOut(SignOutReason.SessionEnded)
    }

    /** Deletes the session (revoking it when online) and all local user data. */
    private suspend fun clearSession() {
        signingOut.set(true)
        try {
            client.auth.signOut()
        } catch (error: CancellationException) {
            throw error
        } catch (_: Exception) {
            // Offline or refused: the local session is cleared below regardless.
        }
        client.auth.clearSession()
        sessions.deleteSession()
        localData.wipe()
    }

    /** Reacts to sign-outs the client performs itself, for example when renewal is refused in the background. */
    private fun observeClientEvents() {
        scope.launch {
            client.auth.sessionStatus.collect { status ->
                when (status) {
                    is SessionStatus.Authenticated -> if (_state.value is AuthState.SignedIn) _state.value = signedIn(status.session.user)
                    is SessionStatus.NotAuthenticated -> if (!signingOut.get() && _state.value is AuthState.SignedIn) {
                        localData.wipe()
                        _state.value = AuthState.SignedOut(SignOutReason.SessionEnded)
                    }
                    else -> Unit
                }
            }
        }
    }

    private fun signedIn(user: UserInfo?): AuthState =
        user?.let { AuthState.SignedIn(authUser(it)) } ?: _state.value

    private fun authUser(user: UserInfo) = AuthUser(user.id, user.email)

    /** Failures that say nothing about the session's validity: no response, or a server-side outage. */
    private fun isTransient(error: Exception): Boolean = when (error) {
        is HttpRequestException, is IOException -> true
        is RestException -> error.statusCode >= 500
        else -> false
    }
}
