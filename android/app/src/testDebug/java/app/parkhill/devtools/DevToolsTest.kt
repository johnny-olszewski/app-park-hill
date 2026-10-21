package app.parkhill.devtools

import app.parkhill.services.backend.ScreenEnvelope
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.jsonObject
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

/** The tool registry, the current screen and the data page's JSON (AND-021 AC4, AC5). */
class DevToolsTest {
    private fun envelope(key: String) = ScreenEnvelope(key, JsonObject(emptyMap()))

    @Test
    fun aScreenToolAppearsOnlyWhileItsScreenIsCurrent() {
        val registry = DevToolRegistry()
        registry.register(DevTool(id = "test", title = "Test") {}, forScreen = "test.screen")

        assertEquals(listOf("test"), registry.tools("test.screen").map { it.id })
        assertTrue(registry.tools("other.screen").isEmpty())
        assertTrue(registry.tools(null).isEmpty())
    }

    @Test
    fun anArmedWarningIsReportedWhateverScreenIsCurrent() {
        var armed: String? = null
        val registry = DevToolRegistry()
        registry.register(DevTool(id = "test", title = "Test", warningText = { armed }) {}, forScreen = "test.screen")
        registry.registerAppTool(DevTool(id = "app", title = "App") {})
        assertTrue(registry.warnings.isEmpty())

        armed = "Next sign-in will fail: Test"

        assertEquals(listOf("Next sign-in will fail: Test"), registry.warnings)
    }

    @Test
    fun theNewestVisibleScreenIsCurrentAndLeavingItRevealsTheOneBelow() {
        val tracker = CurrentScreenTracker()
        assertNull(tracker.current)

        tracker.screenDidAppear(envelope("first"), id = 1)
        tracker.screenDidAppear(envelope("second"), id = 2)
        assertEquals("second", tracker.current?.key)

        tracker.screenDidDisappear(2)
        assertEquals("first", tracker.current?.key)

        tracker.screenDidDisappear(1)
        assertNull(tracker.current)
    }

    @Test
    fun formattedJSONSortsKeysIndentsAndKeepsSlashes() {
        val data = Json.parseToJsonElement("""{"b":{"z":1,"a":[2]},"a":"https://x/y"}""").jsonObject

        assertEquals(
            """
            {
              "a": "https://x/y",
              "b": {
                "a": [
                  2
                ],
                "z": 1
              }
            }
            """.trimIndent(),
            AppTools.formattedJSON(data),
        )
    }
}
