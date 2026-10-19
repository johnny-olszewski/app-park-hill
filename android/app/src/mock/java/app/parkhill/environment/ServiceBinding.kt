// Compiled only in the mock flavor (src/mock).
package app.parkhill.environment

import app.parkhill.app.AppServices
import app.parkhill.navigation.ScreenRegistry
import app.parkhill.navigation.registerSharedScreens
import app.parkhill.mocks.MockBackendService

typealias AppBackendService = MockBackendService

object ServiceBinding {
    /** No backend: services read contract fixtures and make no network calls. */
    val environment = AppEnvironment(name = "Mock", backend = null)

    /** The screens this flavor registers. */
    fun makeScreenRegistry(services: AppServices): ScreenRegistry =
        ScreenRegistry().apply { registerSharedScreens() }
}
