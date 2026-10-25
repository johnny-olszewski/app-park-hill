package app.parkhill.navigation

import android.util.Log
import app.parkhill.cache.EntryCache
import app.parkhill.cache.ScreenCache
import app.parkhill.cache.TabsCache
import app.parkhill.contract.RpcFunction
import app.parkhill.services.auth.AuthService
import app.parkhill.services.auth.AuthState
import app.parkhill.services.auth.AuthUser
import app.parkhill.services.auth.SignOutReason
import app.parkhill.services.backend.BackendService
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

/** What the entry shows. */
sealed interface EntryState {
    data object Loading : EntryState
    class Screen(val screen: ResolvedScreen) : EntryState
    data object Error : EntryState
}

/** Everything the app root draws from. */
data class AppState(
    /** True until the stored session has been checked at launch. */
    val isLaunching: Boolean = true,
    /** The signed-in user, or null when there is none. */
    val signedInUser: AuthUser? = null,
    /** The signed-in user's tabs, created at sign-in and dropped with the user. */
    val shell: ShellCoordinator? = null,
    /** Whether the signed-out entry is showing. */
    val isEntryPresented: Boolean = false,
    val entry: EntryState = EntryState.Loading,
    /** Why the user was last signed out, for the sign-in screen's notice. */
    val signOutReason: SignOutReason? = null,
)

/**
 * Owns launch and the app's root (guide 5.1, 5.3): the signed-in shell of
 * tabs, or the signed-out entry, followed from the auth state. Composables collect
 * [state]; they never navigate.
 */
class AppCoordinator(
    private val backend: BackendService,
    private val auth: AuthService,
    private val registry: ScreenRegistry,
    private val cache: EntryCache,
    private val scope: CoroutineScope,
    private val locale: () -> String,
    private val tabsCache: TabsCache,
    private val screenCache: ScreenCache,
) {
    private val _state = MutableStateFlow(AppState())
    val state: StateFlow<AppState> = _state.asStateFlow()

    private var wasInBackground = false
    private var authObservation: Job? = null

    /** Launch: restore the session (specs/AUTH.md 4.1), then follow the auth state. */
    suspend fun start() {
        when (val restored = auth.restoreSession()) {
            is AuthState.SignedIn -> {
                val shell = makeShell()
                _state.update { it.copy(isLaunching = false, signedInUser = restored.user, shell = shell) }
                shell.load()
            }
            is AuthState.SignedOut -> {
                _state.update { it.copy(isLaunching = false, isEntryPresented = true, signOutReason = restored.reason) }
                loadEntry()
            }
        }
        observeAuth()
    }

    /** Error screen retry. */
    suspend fun retry() {
        _state.update { it.copy(entry = EntryState.Loading) }
        loadEntry()
    }

    suspend fun signOut() {
        auth.signOut()
    }

    fun movedToBackground() {
        wasInBackground = true
    }

    /**
     * Return to the foreground refetches (guide 5.3 rule 6). Signed in, the
     * tabs request also checks the session is still active, so a disabled
     * account is signed out on its next foreground (specs/AUTH.md 4.3).
     */
    suspend fun movedToForeground() {
        if (!wasInBackground) return
        wasInBackground = false
        val current = _state.value
        when {
            current.isEntryPresented -> loadEntry()
            current.shell != null -> current.shell.load()
        }
    }

    suspend fun handle(authState: AuthState) {
        when (authState) {
            is AuthState.SignedIn -> {
                // A new user (such as a mock persona switch) gets a new shell.
                val current = _state.value
                val isNewUser = authState.user != current.signedInUser || current.shell == null
                val shell = if (isNewUser) makeShell() else current.shell
                _state.update {
                    it.copy(signOutReason = null, signedInUser = authState.user, shell = shell, isEntryPresented = false)
                }
                if (isNewUser) shell?.load()
            }
            is AuthState.SignedOut -> {
                val current = _state.value
                if (current.isEntryPresented || current.isLaunching) return
                _state.update {
                    it.copy(
                        signedInUser = null,
                        shell = null,
                        isEntryPresented = true,
                        entry = EntryState.Loading,
                        signOutReason = authState.reason,
                    )
                }
                loadEntry()
            }
        }
    }

    private fun makeShell() = ShellCoordinator(backend, registry, tabsCache, screenCache, locale)

    private fun observeAuth() {
        authObservation?.cancel()
        authObservation = scope.launch { auth.state.collect { handle(it) } }
    }

    private suspend fun loadEntry() {
        val locale = locale()
        val envelope = try {
            backend.getEntry(locale)
        } catch (error: CancellationException) {
            throw error
        } catch (error: Exception) {
            Log.e(TAG, "${RpcFunction.getEntry.value} failed: $error")
            showFallback(locale)
            return
        }
        // A response this build cannot show is unusable: the error screen
        // shows even when a cached entry exists (guide 5.3 rule 5).
        val screen = registry.resolve(envelope) ?: run {
            _state.update { it.copy(entry = EntryState.Error) }
            return
        }
        _state.update { it.copy(entry = EntryState.Screen(screen)) }
        try {
            cache.save(envelope, locale)
        } catch (error: Exception) {
            Log.e(TAG, "Could not cache the entry screen: $error")
        }
    }

    /**
     * After a failed fetch: keep a screen already showing, else the last good
     * cached entry, else the error screen (guide 5.3 rule 4).
     */
    private fun showFallback(locale: String) {
        if (_state.value.entry is EntryState.Screen) return
        val cached = cache.load(locale)?.let(registry::resolve)
        _state.update { it.copy(entry = cached?.let { screen -> EntryState.Screen(screen) } ?: EntryState.Error) }
    }

    private companion object {
        const val TAG = "Navigation"
    }
}
