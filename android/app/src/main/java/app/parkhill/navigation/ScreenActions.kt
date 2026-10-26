package app.parkhill.navigation

import android.util.Log
import androidx.compose.runtime.staticCompositionLocalOf
import app.parkhill.contract.Action
import app.parkhill.contract.CallAction
import app.parkhill.contract.NavigateAction
import app.parkhill.contract.PersonRow

/** Hands back the people chosen in a screen opened with [ScreenActions.open], such as the people picker. */
typealias PeopleHandler = (List<PersonRow>) -> Unit

/**
 * What screens call when something tappable is tapped. Screens never
 * navigate: the tab coordinator supplies these through [LocalScreenActions]
 * and performs the backend's action (guide 5.1). Each shown screen gets a
 * copy bound to it ([from]), so a `call` can refresh or dismiss the screen it
 * came from.
 */
class ScreenActions(
    private val handler: (Action, ScreenModel?, PeopleHandler?) -> Unit = { _, _, _ -> },
    private val source: ScreenModel? = null,
) {
    fun perform(action: Action) = handler(action, source, null)

    /**
     * Performs `action`, such as opening the people picker as a sheet, and
     * hands the people chosen there to `onPeople`. Nothing is handed back
     * when it is cancelled or dragged away.
     */
    fun open(action: Action, onPeople: PeopleHandler) = handler(action, source, onPeople)

    /** Whether this build knows the action's type. An unknown one makes its item not tappable (contract rule 3). */
    fun canPerform(action: Action): Boolean = isKnown(action)

    /** These actions, performed on behalf of `screen`. */
    fun from(screen: ScreenModel) = ScreenActions(handler, screen)

    /** These actions, running `before` first each time one is performed. */
    fun onPerform(before: () -> Unit) = ScreenActions({ action, screen, onPeople ->
        before()
        handler(action, screen, onPeople)
    }, source)

    companion object {
        /** True for action types this build performs; an unknown type is logged. */
        fun isKnown(action: Action): Boolean = when (action) {
            is NavigateAction, is CallAction -> true
            is Action.Unknown -> {
                Log.e("Navigation", "Ignored action of unknown type ${action.type ?: "none"}")
                false
            }
        }
    }
}

val LocalScreenActions = staticCompositionLocalOf { ScreenActions() }

/**
 * What a screen shown as a sheet calls to finish: hand back the chosen
 * people and close, or close with nothing. The coordinator that presented it
 * supplies these through [LocalSheetActions]; outside a sheet they do nothing.
 */
class SheetActions(
    val returnPeople: (List<PersonRow>) -> Unit = {},
    val cancel: () -> Unit = {},
)

val LocalSheetActions = staticCompositionLocalOf { SheetActions() }
