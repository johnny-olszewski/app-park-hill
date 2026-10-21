// Compiled only in release builds (src/release).
package app.parkhill.devtools

import android.app.Application
import app.parkhill.app.AppServices
import app.parkhill.navigation.ScreenTracker

typealias AppDevTools = NoDevTools

/** Release builds have no dev tools: no screen tracking and nothing drawn over the app. */
@Suppress("UNUSED_PARAMETER")
class NoDevTools(application: Application, services: AppServices) {
    val screenTracker: ScreenTracker? = null

    fun install() = Unit
}
