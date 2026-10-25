package app.parkhill.navigation

import android.util.Log
import androidx.compose.runtime.staticCompositionLocalOf
import app.parkhill.contract.Action
import app.parkhill.contract.CallAction // TEMPORARY(EP-03): AND-027 performs call actions
import app.parkhill.contract.NavigateAction

/**
 * What screens call when something tappable is tapped. Screens never
 * navigate: the tab coordinator supplies these through [LocalScreenActions]
 * and performs the backend's action (guide 5.1).
 */
class ScreenActions(val perform: (Action) -> Unit = {}) {
    /** Whether this build knows the action's type. An unknown one makes its item not tappable (contract rule 3). */
    fun canPerform(action: Action): Boolean = isKnown(action)

    companion object {
        /** True for action types this build performs; an unknown type is logged. */
        fun isKnown(action: Action): Boolean = when (action) {
            is NavigateAction -> true
            is CallAction -> { // TEMPORARY(EP-03): AND-027 performs call actions
                Log.e("Navigation", "Ignored call action: not performed by this build yet") // TEMPORARY(EP-03): AND-027 performs call actions
                false // TEMPORARY(EP-03): AND-027 performs call actions
            } // TEMPORARY(EP-03): AND-027 performs call actions
            is Action.Unknown -> {
                Log.e("Navigation", "Ignored action of unknown type ${action.type ?: "none"}")
                false
            }
        }
    }
}

val LocalScreenActions = staticCompositionLocalOf { ScreenActions() }
