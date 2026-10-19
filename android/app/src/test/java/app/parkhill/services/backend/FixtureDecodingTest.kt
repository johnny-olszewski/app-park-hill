package app.parkhill.services.backend

import java.io.File
import kotlinx.serialization.json.JsonPrimitive
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

/** Android agrees with the contract: every recorded screen response decodes (guide 4.1 rule 6). */
class FixtureDecodingTest {
    private val root = File(checkNotNull(javaClass.classLoader?.getResource("get_entry.json")).toURI()).parentFile!!

    @Test
    fun everyScreenFixtureDecodes() {
        val screens = root.walkTopDown()
            .filter { it.isFile && (it.name == "get_entry.json" || it.name.startsWith("get_screen.")) }
            .toList()
        assertTrue("no screen fixtures found", screens.isNotEmpty())
        for (file in screens) {
            val envelope = ContractJson.decodeFromString(ScreenEnvelope.serializer(), file.readText())
            assertTrue("${file.name} has no key", envelope.key.isNotEmpty())
        }
    }

    @Test
    fun theEntryIsSignIn() {
        val envelope = ContractJson.decodeFromString(ScreenEnvelope.serializer(), File(root, "get_entry.json").readText())
        assertEquals("auth.sign_in", envelope.key)
        assertEquals(JsonPrimitive("Sign in"), envelope.data["title"])
    }

    @Test
    fun unknownFieldsAreIgnored() {
        val json = """{"key": "auth.sign_in", "data": {"title": "Sign in"}, "toolbar": [], "future_field": {"x": 1}}"""
        assertEquals("auth.sign_in", ContractJson.decodeFromString(ScreenEnvelope.serializer(), json).key)
    }
}
