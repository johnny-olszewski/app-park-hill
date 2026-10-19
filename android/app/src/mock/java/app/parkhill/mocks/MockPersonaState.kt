package app.parkhill.mocks

import java.util.concurrent.atomic.AtomicReference

/**
 * The persona the mock build is signed in as, shared by the mock services.
 * Set by the mock auth service (AND-005); null means signed out.
 */
class MockPersonaState {
    private val persona = AtomicReference<String?>(null)

    var current: String?
        get() = persona.get()
        set(value) = persona.set(value)

    companion object {
        /** The one instance the mock services share in the running app. */
        val shared = MockPersonaState()
    }
}
