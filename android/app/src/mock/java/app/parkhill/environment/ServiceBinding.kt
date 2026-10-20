// Compiled only in the mock flavor (src/mock).
package app.parkhill.environment

import app.parkhill.app.AppServices
import app.parkhill.mocks.MockAuthService
import app.parkhill.mocks.MockBackendService
import app.parkhill.navigation.ScreenRegistry
import app.parkhill.navigation.registerSharedScreens

typealias AppBackendService = MockBackendService
typealias AppAuthService = MockAuthService

object ServiceBinding {
    /** No backend: services read contract fixtures and make no network calls. */
    val environment = AppEnvironment(name = "Mock", backend = null)

    /** The screens this flavor registers. */
    fun makeScreenRegistry(services: AppServices): ScreenRegistry =
        ScreenRegistry().apply { registerSharedScreens(services.auth) }
}
