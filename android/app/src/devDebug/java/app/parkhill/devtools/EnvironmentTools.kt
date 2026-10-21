// Compiled only in devDebug (src/devDebug).
package app.parkhill.devtools

import app.parkhill.app.AppServices

/** Dev talks to a real backend, so it adds no tools beyond the app tools. */
@Suppress("UNUSED_PARAMETER")
fun DevTools.registerEnvironmentTools(services: AppServices) = Unit
