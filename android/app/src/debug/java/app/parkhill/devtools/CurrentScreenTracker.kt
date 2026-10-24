package app.parkhill.devtools

import androidx.compose.runtime.mutableStateListOf
import app.parkhill.contract.ScreenEnvelope
import app.parkhill.navigation.ScreenTracker

/**
 * The backend-driven screens currently on screen, newest last. The newest is
 * the current screen; leaving it makes the one below current again. Snapshot
 * state, so the menu updates as screens change.
 */
class CurrentScreenTracker : ScreenTracker {
    private data class Visible(val id: Long, val envelope: ScreenEnvelope)

    private val visible = mutableStateListOf<Visible>()

    /** The screen on top, or null before any backend-driven screen appears. */
    val current: ScreenEnvelope? get() = visible.lastOrNull()?.envelope

    override fun screenDidAppear(envelope: ScreenEnvelope, id: Long) {
        visible.removeAll { it.id == id }
        visible += Visible(id, envelope)
    }

    override fun screenDidDisappear(id: Long) {
        visible.removeAll { it.id == id }
    }
}
