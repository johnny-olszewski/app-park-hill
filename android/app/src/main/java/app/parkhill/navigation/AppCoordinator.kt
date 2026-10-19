package app.parkhill.navigation

import android.util.Log
import app.parkhill.cache.EntryCache
import app.parkhill.services.backend.BackendService
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow

/** What the entry shows. */
sealed interface EntryState {
    data object Loading : EntryState
    class Screen(val screen: ResolvedScreen) : EntryState
    data object Error : EntryState
}

/**
 * Owns launch and the signed-out entry (guide 5.1, 5.3). Composables collect
 * [entry]; they never navigate. The signed-in state arrives with AND-006.
 */
class AppCoordinator(
    private val backend: BackendService,
    private val registry: ScreenRegistry,
    private val cache: EntryCache,
    private val locale: () -> String,
) {
    private val _entry = MutableStateFlow<EntryState>(EntryState.Loading)
    val entry: StateFlow<EntryState> = _entry.asStateFlow()

    private var wasInBackground = false

    /** Launch: fetch the entry (guide 5.3 rules 2 and 4). */
    suspend fun start() {
        loadEntry()
    }

    /** Error screen retry. */
    suspend fun retry() {
        _entry.value = EntryState.Loading
        loadEntry()
    }

    fun movedToBackground() {
        wasInBackground = true
    }

    /** Return to the foreground refetches (guide 5.3 rule 6). */
    suspend fun movedToForeground() {
        if (!wasInBackground) return
        wasInBackground = false
        loadEntry()
    }

    private suspend fun loadEntry() {
        val locale = locale()
        val envelope = try {
            backend.getEntry(locale)
        } catch (error: Exception) {
            Log.e(TAG, "get_entry failed: $error")
            showFallback(locale)
            return
        }
        // A response this build cannot show is unusable: the error screen
        // shows even when a cached entry exists (guide 5.3 rule 5).
        val screen = registry.resolve(envelope) ?: run {
            _entry.value = EntryState.Error
            return
        }
        _entry.value = EntryState.Screen(screen)
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
        if (_entry.value is EntryState.Screen) return
        val cached = cache.load(locale)?.let(registry::resolve)
        _entry.value = cached?.let { EntryState.Screen(it) } ?: EntryState.Error
    }

    private companion object {
        const val TAG = "Navigation"
    }
}
