package app.parkhill.navigation

import android.util.Log
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import app.parkhill.contract.Action
import app.parkhill.contract.CallAction
import app.parkhill.contract.CallActionOnSuccess
import app.parkhill.contract.NavigateAction
import app.parkhill.contract.NavigateActionPresentation
import app.parkhill.contract.ScreenEnvelope
import app.parkhill.contract.TabItem
import app.parkhill.services.backend.BackendError
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.launch

/** A `call` waiting for its confirmation, and the screen it came from. */
class PendingCall(val action: CallAction, val source: ScreenModel?)

/** A brief message for the user, such as the backend's lost-access message, shown once (a `Snackbar`, guide 5.5). */
class TabMessage(val text: String)

/**
 * One tab's navigation (guide 5.1): its root screen, the screens pushed over
 * it, the one presented as a sheet and the full-screen cover presented over
 * the shell, which has its own stack. Kept while the tab is switched away
 * from, so each tab returns to where it was. Applies the lost-access rule
 * (guide 5.3 rule 9) to every screen it shows; refreshes run in `scope`, so
 * they finish even when the screen that started them has closed. Snapshot
 * state, read by the shell.
 */
class TabCoordinator(item: TabItem, private val context: ScreenContext, private val scope: CoroutineScope) {
    val id: String = item.id
    var title: String by mutableStateOf(item.title)
        private set
    var iconKey: String by mutableStateOf(item.iconKey)
        private set

    /** The root and the screens pushed over it. */
    val stack = ScreenStack(ScreenModel.showing(item.screen, context), context, ::lostAccess)
    val root: ScreenModel get() = stack.root

    /** Screens pushed over the root, oldest first. */
    val path: List<Route> get() = stack.path

    /** The screen presented as a sheet, if any. */
    var presented: Route? by mutableStateOf(null)
        private set

    /** The full-screen cover over the shell and the screens pushed inside it, if one is open. */
    var cover: ScreenStack? by mutableStateOf(null)
        private set

    /** The message to show now, if any; the shell calls [messageShown] once it has shown it. */
    var message: TabMessage? by mutableStateOf(null)
        private set

    /** The `call` whose backend confirmation is showing, if any. */
    var pendingCall: PendingCall? by mutableStateOf(null)
        private set

    /** What this tab's screens, and its cover's, call when something is tapped. */
    val actions = ScreenActions(handler = ::perform)

    /** Takes a refreshed title, icon and root screen for the same tab. */
    fun update(item: TabItem) {
        title = item.title
        iconKey = item.iconKey
        root.update(item.screen)
    }

    /**
     * Performs a backend action from `source`, the screen it was tapped on:
     * `navigate` with `push` opens the target screen over a loading state,
     * fetched with its params, on the cover's stack when a cover is open,
     * else on this tab's. `full_screen_cover` opens the target as a cover,
     * fetched fresh each time. `call` asks the backend's confirmation first
     * when it has one, then makes the call ([confirmCall]). An unknown
     * action, or a target this build does not register, does nothing and is
     * logged.
     */
    fun perform(action: Action, source: ScreenModel? = null) {
        when (action) {
            is NavigateAction -> {
                if (!context.registry.isRegistered(action.screenKey)) {
                    Log.e(TAG, "Dropped navigation to unregistered screen key ${action.screenKey}")
                    return
                }
                when (action.presentation) {
                    NavigateActionPresentation.PUSH -> (cover ?: stack).push(action.screenKey, action.params)
                    NavigateActionPresentation.SHEET -> Log.e(TAG, "Ignored sheet to ${action.screenKey}: not presented by this build yet") // TEMPORARY(EP-03): AND-012 presents sheets
                    NavigateActionPresentation.FULL_SCREEN_COVER -> {
                        if (cover != null) {
                            Log.e(TAG, "Ignored full_screen_cover to ${action.screenKey}: a cover is already open")
                            return
                        }
                        cover = ScreenStack(ScreenModel.toFetch(action.screenKey, action.params, context), context, ::lostAccess)
                    }
                }
            }
            is CallAction -> {
                if (action.confirm != null) {
                    pendingCall = PendingCall(action, source)
                } else {
                    scope.launch { call(action, source) }
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
        val screen = ScreenModel.showing(envelope, context)
        screen.onUnavailable = { message -> lostAccess(screen, message) }
        presented = Route(screen)
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

    /** The confirmation's confirm button: makes the pending call. */
    fun confirmCall() {
        val pending = pendingCall ?: return
        pendingCall = null
        scope.launch { call(pending.action, pending.source) }
    }

    /** The confirmation's cancel button, or dismissing it: calls nothing. */
    fun cancelCall() {
        pendingCall = null
    }

    /**
     * Makes a `call` (specs/COMMUNITY.md 3.2), then applies its `on_success`
     * to `source`: `refresh` reloads it, `dismiss` closes it as a lost screen
     * closes but with no message (a tab root refreshes in place), `none` does
     * nothing. A call refused with `action_refused` refreshes `source` and
     * shows the refusal, unless that refresh finds the screen unavailable:
     * then only the lost-access message shows. Other failures are logged.
     */
    internal suspend fun call(action: CallAction, source: ScreenModel?) {
        try {
            context.backend.call(action.function, action.params, context.locale())
        } catch (error: CancellationException) {
            throw error
        } catch (refused: BackendError.ActionRefused) {
            Log.i(TAG, "${action.function} refused")
            if (source == null || source.load()) message = TabMessage(refused.message)
            return
        } catch (error: Exception) {
            Log.e(TAG, "${action.function} failed: $error")
            return
        }
        if (source == null) return
        when (action.onSuccess) {
            CallActionOnSuccess.REFRESH -> source.load()
            CallActionOnSuccess.DISMISS -> close(source, refreshRoot = true)
            CallActionOnSuccess.NONE -> Unit
        }
    }

    fun messageShown(message: TabMessage) {
        if (this.message === message) this.message = null
    }

    /**
     * A screen refused as unavailable (guide 5.3 rule 9): it closes with
     * everything over it and the screen it uncovers refreshes; a tab root
     * keeps showing. Then the backend's message shows.
     */
    private fun lostAccess(screen: ScreenModel, message: String) {
        close(screen, refreshRoot = false)
        this.message = TabMessage(message)
    }

    /**
     * Closes `screen` and everything over it, then refreshes the screen it
     * uncovers: a pushed screen uncovers the one below it, a cover's root or
     * the sheet uncovers the top of the tab. A tab root cannot close; it
     * refreshes in place when `refreshRoot`. A screen no longer shown is left alone.
     */
    private fun close(screen: ScreenModel, refreshRoot: Boolean) {
        val cover = cover
        val uncovered = when {
            presented?.screen === screen -> {
                dismiss()
                (cover ?: stack).top
            }
            cover != null && cover.root === screen -> {
                closeCover()
                stack.top
            }
            cover != null && cover.removeFrom(screen) -> cover.top
            stack.removeFrom(screen) -> stack.top
            screen === stack.root && refreshRoot -> screen
            else -> null
        }
        if (uncovered != null) scope.launch { uncovered.load() }
    }

    private companion object {
        const val TAG = "Navigation"
    }
}
