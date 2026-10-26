package app.parkhill.navigation

import android.util.Log
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import app.parkhill.cache.ScreenCache
import app.parkhill.cache.TabsCache
import app.parkhill.contract.RpcFunction
import app.parkhill.contract.TabsResponse
import app.parkhill.services.backend.BackendService
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineScope

/** What the signed-in shell shows. */
enum class ShellState { Loading, Tabs, Error }

/**
 * The signed-in shell (EP-02): the backend's tabs, each with its own
 * [TabCoordinator]. Fetched with `get_tabs`, cached per locale, refreshed on
 * return to the foreground (guide 5.3). Tabs run their refreshes in `scope`.
 * Snapshot state, read by the shell.
 */
class ShellCoordinator(
    private val backend: BackendService,
    private val registry: ScreenRegistry,
    private val cache: TabsCache,
    screenCache: ScreenCache,
    private val scope: CoroutineScope,
    private val locale: () -> String,
) {
    private val screens = ScreenContext(backend, registry, screenCache, locale)

    var state: ShellState by mutableStateOf(ShellState.Loading)
        private set
    var tabs: List<TabCoordinator> by mutableStateOf(emptyList())
        private set

    /** The selected tab's id. A fresh shell selects the first tab. */
    var selectedTabId: String? by mutableStateOf(null)

    /**
     * Fetches the tabs. Also the foreground refresh: a failure keeps the tabs
     * showing; a refusal of the session signs out through the auth service.
     */
    suspend fun load() {
        val locale = locale()
        val response = try {
            backend.getTabs(locale)
        } catch (error: CancellationException) {
            throw error
        } catch (error: Exception) {
            Log.e(TAG, "${RpcFunction.getTabs.value} failed: $error")
            showFallback(locale)
            return
        }
        // A response this build cannot show is unusable: the error screen
        // shows even when cached tabs exist (guide 5.3 rule 5).
        if (!show(response)) {
            state = ShellState.Error
            return
        }
        try {
            cache.save(response, locale)
        } catch (error: Exception) {
            Log.e(TAG, "Could not cache the tabs: $error")
        }
    }

    /** Error screen retry. */
    suspend fun retry() {
        state = ShellState.Loading
        load()
    }

    /**
     * After a failed fetch: keep tabs already showing, else the cached tabs,
     * else the error screen (guide 5.3 rule 4).
     */
    private fun showFallback(locale: String) {
        if (state == ShellState.Tabs) return
        val cached = cache.load(locale)
        if (cached != null && show(cached)) return
        state = ShellState.Error
    }

    /**
     * Shows the first five tabs whose root screens this build registers,
     * keeping each tab's coordinator and stack while its root screen key stays
     * the same, and the selected tab. False when no tab can be shown.
     */
    private fun show(response: TabsResponse): Boolean {
        if (response.tabs.size > MAXIMUM_TABS) {
            Log.e(TAG, "Dropped tabs beyond $MAXIMUM_TABS: ${response.tabs.drop(MAXIMUM_TABS).joinToString { it.id }}")
        }
        val shown = response.tabs.take(MAXIMUM_TABS).mapNotNull { item ->
            val existing = tabs.firstOrNull { it.id == item.id && it.root.key == item.screen.key }
            when {
                existing != null -> existing.also { it.update(item) }
                // A root whose data cannot be shown falls back in its tab, to its cached copy or the error screen.
                registry.isRegistered(item.screen.key) -> TabCoordinator(item, screens, scope)
                else -> null.also { Log.e(TAG, "Dropped tab ${item.id}: its screen is not registered") }
            }
        }
        if (shown.isEmpty()) return false
        tabs = shown
        if (shown.none { it.id == selectedTabId }) selectedTabId = shown.first().id
        state = ShellState.Tabs
        return true
    }

    companion object {
        /** The tab bar's limit; the backend enforces it too (SUP-008). */
        const val MAXIMUM_TABS = 5
        private const val TAG = "Navigation"
    }
}
