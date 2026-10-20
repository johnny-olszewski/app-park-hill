package app.parkhill.environment

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class AppEnvironmentTest {
    @Test
    fun bindingDeclaresANamedEnvironment() {
        assertTrue(ServiceBinding.environment.name.isNotEmpty())
    }

    @Test
    fun backendLabelIsTheUrlOrNone() {
        assertEquals("http://10.0.2.2:54321", AppEnvironment("A", BackendTarget("http://10.0.2.2:54321", "key")).backendLabel)
        assertEquals("none", AppEnvironment("B", null).backendLabel)
    }
}
