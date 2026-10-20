package app.parkhill.services.backend

import app.parkhill.environment.AppEnvironment
import org.junit.Assert.assertEquals
import org.junit.Test

class StandardHeadersTest {
    @Test
    fun labelsTheConfigPlatformVersionAndLanguage() {
        val headers = StandardHeaders.make(AppEnvironment("Dev", null), versionName = "0.1.0", versionCode = 7, language = "es")
        assertEquals(
            mapOf(
                "X-App-Config" to "dev",
                "X-App-Platform" to "android",
                "X-App-Version" to "0.1.0 (7)",
                "Accept-Language" to "es",
            ),
            headers,
        )
    }
}
