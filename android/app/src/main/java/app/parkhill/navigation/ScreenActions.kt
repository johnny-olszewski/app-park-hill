package app.parkhill.navigation

import android.util.Log
import androidx.compose.runtime.staticCompositionLocalOf
import app.parkhill.contract.Action
import app.parkhill.contract.CallAction
import app.parkhill.contract.NavigateAction
import app.parkhill.contract.PersonRow
import kotlinx.serialization.json.JsonElement

/** Hands back the people chosen in a screen opened with [ScreenActions.open], such as the people picker. */
typealias PeopleHandler = (List<PersonRow>) -> Unit

/**
 * Makes a form's call with fields added, for the screen it came from; hands
 * its body to `done`, or null when it failed. `on_success` applies only when
 * `succeeded` says the body is a success.
 */
typealias SubmitHandler = (
    call: CallAction,
    fields: Map<String, JsonElement>,
    source: ScreenModel?,
    succeeded: (JsonElement) -> Boolean,
    done: (JsonElement?) -> Unit,
) -> Unit

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
    private val submitter: SubmitHandler? = null,
) {
    fun perform(action: Action) = handler(action, source, null)

    /**
     * Performs `action`, such as opening the people picker as a sheet, and
     * hands the people chosen there to `onPeople`. Nothing is handed back
     * when it is cancelled or dragged away.
     */
    fun open(action: Action, onPeople: PeopleHandler) = handler(action, source, onPeople)

    /**
     * Makes `call`, a form's submit such as edit mode's save, with `fields`
     * added to its params, and hands the body to `done`: null when the call
     * failed, whose refusal shows as any call's does. Its `on_success`
     * applies to the screen these actions come from, before `done`, only when
     * `succeeded` says the body is a success.
     */
    fun submit(call: CallAction, fields: Map<String, JsonElement>, succeeded: (JsonElement) -> Boolean, done: (JsonElement?) -> Unit) {
        val submitter = submitter ?: return done(null)
        submitter(call, fields, source, succeeded, done)
    }

    /** Whether this build knows the action's type. An unknown one makes its item not tappable (contract rule 3). */
    fun canPerform(action: Action): Boolean = isKnown(action)

    /** These actions, performed on behalf of `screen`. */
    fun from(screen: ScreenModel) = ScreenActions(handler, screen, submitter)

    /** These actions, running `before` first each time one is performed. */
    fun onPerform(before: () -> Unit) = ScreenActions({ action, screen, onPeople ->
        before()
        handler(action, screen, onPeople)
    }, source, submitter)

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
