package app.parkhill.navigation

import android.util.Log
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import app.parkhill.contract.Action
import app.parkhill.contract.NavigateAction
import app.parkhill.contract.NavigateActionPresentation
import app.parkhill.contract.ScreenEnvelope
import app.parkhill.contract.TabItem
import java.util.concurrent.atomic.AtomicLong

/**
 * One tab's navigation (guide 5.1): its root screen, the screens pushed over
 * it and the one presented as a sheet. Kept while the tab is switched away
 * from, so each tab returns to where it was. Snapshot state, read by the shell.
 */
class TabCoordinator(item: TabItem, private val context: ScreenContext) {
    val id: String = item.id
    var title: String by mutableStateOf(item.title)
        private set
    var iconKey: String by mutableStateOf(item.iconKey)
        private set
    val root: ScreenModel = ScreenModel.showing(item.screen, context)

    private val _path = mutableStateListOf<Route>()

    /** Screens pushed over the root, oldest first. */
    val path: List<Route> get() = _path

    /** The screen presented as a sheet, if any. */
    var presented: Route? by mutableStateOf(null)
        private set

    /** What this tab's screens call when something is tapped. */
    val actions = ScreenActions(perform = ::perform)

    /** Takes a refreshed title, icon and root screen for the same tab. */
    fun update(item: TabItem) {
        title = item.title
        iconKey = item.iconKey
        root.update(item.screen)
    }

    /**
     * Performs a backend action: `navigate` with `push` opens the target
     * screen on this tab's stack over a loading state, fetched with its
     * params. An unknown action, or a target this build does not register,
     * does nothing and is logged.
     */
    fun perform(action: Action) {
        when (action) {
            is NavigateAction -> {
                if (!context.registry.isRegistered(action.screenKey)) {
                    Log.e(TAG, "Dropped navigation to unregistered screen key ${action.screenKey}")
                    return
                }
                when (action.presentation) {
                    NavigateActionPresentation.PUSH -> _path += Route(ScreenModel.toFetch(action.screenKey, action.params, context))
                    NavigateActionPresentation.FULL_SCREEN_COVER -> Log.e(TAG, "Ignored full_screen_cover to ${action.screenKey}: not built yet")
                }
            }
            is Action.Unknown -> ScreenActions.isKnown(action)
        }
    }

    /** Pushes the screen for `envelope`. False, and logged by the registry, when this build cannot show it. */
    fun push(envelope: ScreenEnvelope): Boolean {
        if (context.registry.resolve(envelope) == null) return false
        _path += Route(ScreenModel.showing(envelope, context))
        return true
    }

    /** Presents the screen for `envelope` as a sheet. False when this build cannot show it. */
    fun present(envelope: ScreenEnvelope): Boolean {
        if (context.registry.resolve(envelope) == null) return false
        presented = Route(ScreenModel.showing(envelope, context))
        return true
    }

    /** Pops the top pushed screen. False when only the root is showing. */
    fun pop(): Boolean = _path.removeLastOrNull() != null

    fun dismiss() {
        presented = null
    }

    private companion object {
        const val TAG = "Navigation"
    }
}

/** One shown screen in a tab's stack or sheet. Identity is per showing, so the same key can appear twice. */
class Route(val screen: ScreenModel) {
    val id: Long = nextId.incrementAndGet()

    private companion object {
        val nextId = AtomicLong()
    }
}
