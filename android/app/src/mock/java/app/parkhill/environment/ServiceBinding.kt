// Compiled only in the mock flavor (src/mock).
package app.parkhill.environment

import app.parkhill.app.AppServices
import app.parkhill.mocks.MockAuthService
import app.parkhill.mocks.MockBackendService
import app.parkhill.navigation.ScreenRegistry
import app.parkhill.navigation.ScreenTracker
import app.parkhill.navigation.registerSharedScreens

typealias AppBackendService = MockBackendService
typealias AppAuthService = MockAuthService

object ServiceBinding {
    /** No backend: services read mock responses and make no network calls. */
    val environment = AppEnvironment(name = "Mock", backend = null)

    /** The screens this flavor registers. */
    fun makeScreenRegistry(services: AppServices, tracker: ScreenTracker?): ScreenRegistry =
        ScreenRegistry(tracker).apply { registerSharedScreens(services.auth) }
}
