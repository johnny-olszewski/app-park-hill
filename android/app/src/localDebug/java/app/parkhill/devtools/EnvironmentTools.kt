// Compiled only in localDebug (src/localDebug).
package app.parkhill.devtools

import app.parkhill.app.AppServices

/** Local talks to a real backend, so it adds no tools beyond the app tools. */
@Suppress("UNUSED_PARAMETER")
fun DevTools.registerEnvironmentTools(services: AppServices) = Unit
