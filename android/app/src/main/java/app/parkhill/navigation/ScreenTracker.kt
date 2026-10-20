package app.parkhill.navigation

import app.parkhill.services.backend.ScreenEnvelope

/**
 * Told when a backend-driven screen appears and disappears, so debug tooling
 * can show what the current screen received. [ScreenRegistry] reports every
 * screen it resolves; screens never call this. Release builds supply none.
 */
interface ScreenTracker {
    /** `id` identifies one resolved screen, so the same key shown twice is tracked as two screens. */
    fun screenDidAppear(envelope: ScreenEnvelope, id: Long)
    fun screenDidDisappear(id: Long)
}
