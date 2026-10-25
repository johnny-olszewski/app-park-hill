package app.parkhill.navigation

import android.util.Log
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import app.parkhill.contract.Action
import app.parkhill.contract.NavigateAction
import app.parkhill.contract.NavigateActionPresentation
import app.parkhill.contract.ScreenEnvelope
import app.parkhill.contract.TabItem

/**
 * One tab's navigation (guide 5.1): its root screen, the screens pushed over
 * it, the one presented as a sheet and the full-screen cover presented over
 * the shell, which has its own stack. Kept while the tab is switched away
 * from, so each tab returns to where it was. Snapshot state, read by the shell.
 */
class TabCoordinator(item: TabItem, private val context: ScreenContext) {
    val id: String = item.id
    var title: String by mutableStateOf(item.title)
        private set
    var iconKey: String by mutableStateOf(item.iconKey)
        private set

    /** The root and the screens pushed over it. */
    val stack = ScreenStack(ScreenModel.showing(item.screen, context), context)
    val root: ScreenModel get() = stack.root

    /** Screens pushed over the root, oldest first. */
    val path: List<Route> get() = stack.path

    /** The screen presented as a sheet, if any. */
    var presented: Route? by mutableStateOf(null)
        private set

    /** The full-screen cover over the shell and the screens pushed inside it, if one is open. */
    var cover: ScreenStack? by mutableStateOf(null)
        private set

    /** What this tab's screens, and its cover's, call when something is tapped. */
    val actions = ScreenActions(perform = ::perform)

    /** Takes a refreshed title, icon and root screen for the same tab. */
    fun update(item: TabItem) {
        title = item.title
        iconKey = item.iconKey
        root.update(item.screen)
    }

    /**
     * Performs a backend action: `navigate` with `push` opens the target
     * screen over a loading state, fetched with its params, on the cover's
     * stack when a cover is open, else on this tab's. `full_screen_cover`
     * opens the target as a cover, fetched fresh each time. An unknown
     * action, or a target this build does not register, does nothing and is
     * logged.
     */
    fun perform(action: Action) {
        when (action) {
            is NavigateAction -> {
                if (!context.registry.isRegistered(action.screenKey)) {
                    Log.e(TAG, "Dropped navigation to unregistered screen key ${action.screenKey}")
                    return
                }
                when (action.presentation) {
                    NavigateActionPresentation.PUSH -> (cover ?: stack).push(action.screenKey, action.params)
                    NavigateActionPresentation.FULL_SCREEN_COVER -> {
                        if (cover != null) {
                            Log.e(TAG, "Ignored full_screen_cover to ${action.screenKey}: a cover is already open")
                            return
                        }
                        cover = ScreenStack(ScreenModel.toFetch(action.screenKey, action.params, context), context)
                    }
                }
            }
            is Action.Unknown -> ScreenActions.isKnown(action)
        }
    }

    /** Pushes the screen for `envelope`. False, and logged by the registry, when this build cannot show it. */
    fun push(envelope: ScreenEnvelope): Boolean = stack.push(envelope)

    /** Presents the screen for `envelope` as a sheet. False when this build cannot show it. */
    fun present(envelope: ScreenEnvelope): Boolean {
        if (context.registry.resolve(envelope) == null) return false
        presented = Route(ScreenModel.showing(envelope, context))
        return true
    }

    /** Pops the top pushed screen. False when only the root is showing. */
    fun pop(): Boolean = stack.pop()

    fun dismiss() {
        presented = null
    }

    /** Closes the cover and everything pushed inside it. */
    fun closeCover() {
        cover = null
    }

    /**
     * System back: pops inside the cover, then closes it; with no cover, pops
     * this tab's stack. False when there was nothing to go back from.
     */
    fun back(): Boolean {
        val cover = cover ?: return pop()
        if (!cover.pop()) closeCover()
        return true
    }

    private companion object {
        const val TAG = "Navigation"
    }
}
