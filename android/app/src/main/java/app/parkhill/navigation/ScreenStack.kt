package app.parkhill.navigation

import androidx.compose.runtime.mutableStateListOf
import app.parkhill.contract.ScreenEnvelope
import java.util.concurrent.atomic.AtomicLong
import kotlinx.serialization.json.JsonObject

/**
 * A root screen and the screens pushed over it: a tab's stack, or a
 * full-screen cover's own. Snapshot state, read by the shell.
 */
class ScreenStack(val root: ScreenModel, private val context: ScreenContext) {
    private val _path = mutableStateListOf<Route>()

    /** Screens pushed over the root, oldest first. */
    val path: List<Route> get() = _path

    /** Pushes `key` with `params`, over a loading state until it is fetched. */
    fun push(key: String, params: JsonObject) {
        _path += Route(ScreenModel.toFetch(key, params, context))
    }

    /** Pushes the screen for `envelope`. False, and logged by the registry, when this build cannot show it. */
    fun push(envelope: ScreenEnvelope): Boolean {
        if (context.registry.resolve(envelope) == null) return false
        _path += Route(ScreenModel.showing(envelope, context))
        return true
    }

    /** Pops the top pushed screen. False when only the root is showing. */
    fun pop(): Boolean = _path.removeLastOrNull() != null
}

/** One shown screen in a stack or sheet. Identity is per showing, so the same key can appear twice. */
class Route(val screen: ScreenModel) {
    val id: Long = nextId.incrementAndGet()

    private companion object {
        val nextId = AtomicLong()
    }
}
