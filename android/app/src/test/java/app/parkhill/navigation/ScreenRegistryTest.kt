package app.parkhill.navigation

import app.parkhill.services.backend.ContractJson
import app.parkhill.services.backend.ScreenEnvelope
import java.io.File
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertThrows
import org.junit.Assert.assertTrue
import org.junit.Test

class ScreenRegistryTest {
    private fun registry() = ScreenRegistry().apply { registerSharedScreens() }

    @Test
    fun sharedScreensIncludeSignIn() {
        assertTrue(registry().isRegistered("auth.sign_in"))
    }

    @Test
    fun resolvesARegisteredKeyAndKeepsItsEnvelope() {
        val envelope = StubBackendService.signIn()
        val screen = registry().resolve(envelope)
        assertNotNull(screen)
        assertEquals("auth.sign_in", screen!!.key)
        assertEquals(envelope, screen.envelope)
    }

    @Test
    fun dropsAnUnregisteredKey() {
        assertNull(registry().resolve(ScreenEnvelope("future.screen", JsonObject(emptyMap()))))
    }

    @Test
    fun dropsDataThatDoesNotMatchTheModel() {
        assertNull(registry().resolve(ScreenEnvelope("auth.sign_in", JsonObject(mapOf("title" to JsonObject(emptyMap()))))))
    }

    @Serializable
    data class TestData(val title: String)

    @Test
    fun ignoresUnknownFieldsInScreenData() {
        val registry = ScreenRegistry()
        registry.register("test.screen", TestData.serializer()) {}
        val data = JsonObject(mapOf("title" to JsonPrimitive("Hello"), "extra" to JsonPrimitive(true)))
        assertNotNull(registry.resolve(ScreenEnvelope("test.screen", data)))
    }

    @Test
    fun aKeyCannotBeRegisteredTwice() {
        val registry = registry()
        assertThrows(IllegalArgumentException::class.java) { registry.registerSharedScreens() }
    }

    @Test
    fun theRecordedEntryResolves() {
        val root = File(checkNotNull(javaClass.classLoader?.getResource("get_entry.json")).toURI()).parentFile!!
        val envelope = ContractJson.decodeFromString(ScreenEnvelope.serializer(), File(root, "get_entry.json").readText())
        assertNotNull(registry().resolve(envelope))
    }
}
