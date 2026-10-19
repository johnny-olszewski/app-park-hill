// Compiled only in the mock flavor (src/mock).
package app.parkhill.environment

import app.parkhill.mocks.MockBackendService

typealias AppBackendService = MockBackendService

object ServiceBinding {
    /** No backend: services read contract fixtures and make no network calls. */
    val environment = AppEnvironment(name = "Mock", backend = null)
}
