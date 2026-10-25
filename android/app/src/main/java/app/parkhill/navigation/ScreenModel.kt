package app.parkhill.navigation

import android.util.Log
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import app.parkhill.cache.ScreenCache
import app.parkhill.contract.RpcFunction
import app.parkhill.contract.ScreenEnvelope
import app.parkhill.services.backend.BackendService
import kotlinx.coroutines.CancellationException
import kotlinx.serialization.json.JsonObject

/** What a backend screen needs to fetch, show and cache itself. */
class ScreenContext(
    val backend: BackendService,
    val registry: ScreenRegistry,
    val cache: ScreenCache,
    val locale: () -> String,
)

/** What a [ScreenModel] shows. */
sealed interface ScreenState {
    data object Loading : ScreenState
    class Showing(val screen: ResolvedScreen) : ScreenState
    data object Error : ScreenState
}

/**
 * One shown backend screen: its key and params, and what it shows now.
 * Fetches with `get_screen`, refreshes on demand, and falls back to the last
 * good copy for its key and params, else the error screen (guide 5.3 rules 4
 * and 10). Snapshot state, read by [ScreenHost].
 */
class ScreenModel private constructor(
    val key: String,
    val params: JsonObject,
    private val context: ScreenContext,
) {
    var state: ScreenState by mutableStateOf(ScreenState.Loading)
        private set

    /** True until the first fetch of a screen still to fetch has started. */
    internal var needsLoad = false
        private set

    /** The envelope showing now, if any. */
    val envelope: ScreenEnvelope? get() = (state as? ScreenState.Showing)?.screen?.envelope

    /** Fetches the screen. Also pull to refresh: a failure keeps a screen already showing. */
    suspend fun load() {
        needsLoad = false
        val locale = context.locale()
        val envelope = try {
            context.backend.getScreen(key, locale, params)
        } catch (error: CancellationException) {
            throw error
        } catch (error: Exception) {
            Log.e(TAG, "${RpcFunction.getScreen.value} $key failed: $error")
            showFallback(locale)
            return
        }
        show(envelope, locale)
    }

    /** Error screen retry. */
    suspend fun retry() {
        state = ScreenState.Loading
        load()
    }

    /** Shows a newer copy of the same screen, such as a refreshed tab root. */
    fun update(envelope: ScreenEnvelope) {
        if (envelope != this.envelope) show(envelope, context.locale())
    }

    /** Shows `envelope` and keeps it as the last good copy; a screen this build cannot show falls back. */
    private fun show(envelope: ScreenEnvelope, locale: String) {
        val screen = context.registry.resolve(envelope) ?: return showFallback(locale)
        state = ScreenState.Showing(screen)
        try {
            context.cache.save(envelope, params, locale)
        } catch (error: Exception) {
            Log.e(TAG, "Could not cache ${envelope.key}: $error")
        }
    }

    /** Keeps a screen already showing, else shows the cached copy, else the error screen. */
    private fun showFallback(locale: String) {
        if (state is ScreenState.Showing) return
        val cached = context.cache.load(key, params, locale)?.let(context.registry::resolve)
        state = if (cached != null) ScreenState.Showing(cached) else ScreenState.Error
    }

    companion object {
        private const val TAG = "Navigation"

        /** A screen whose content is already here, such as a tab root embedded in `get_tabs`. */
        fun showing(envelope: ScreenEnvelope, context: ScreenContext, params: JsonObject = JsonObject(emptyMap())) =
            ScreenModel(envelope.key, params, context).also { it.show(envelope, context.locale()) }

        /** A screen still to fetch, such as the target of a `navigate` action; loading until [load] finishes. */
        fun toFetch(key: String, params: JsonObject, context: ScreenContext) =
            ScreenModel(key, params, context).also { it.needsLoad = true }
    }
}
