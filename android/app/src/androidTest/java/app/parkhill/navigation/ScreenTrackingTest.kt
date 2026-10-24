package app.parkhill.navigation

import androidx.compose.material3.Text
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.test.ext.junit.runners.AndroidJUnit4
import app.parkhill.contract.ScreenEnvelope
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import org.junit.Assert.assertEquals
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

/** The registry reports a resolved screen appearing and disappearing. */
@RunWith(AndroidJUnit4::class)
class ScreenTrackingTest {
    @get:Rule
    val compose = createComposeRule()

    @Serializable
    data class Data(val title: String)

    private class Recording : ScreenTracker {
        val appeared = mutableListOf<Pair<String, Long>>()
        val disappeared = mutableListOf<Long>()
        override fun screenDidAppear(envelope: ScreenEnvelope, id: Long) {
            appeared += envelope.key to id
        }
        override fun screenDidDisappear(id: Long) {
            disappeared += id
        }
    }

    @Test
    fun reportsAResolvedScreenAppearingAndDisappearing() {
        val tracker = Recording()
        val registry = ScreenRegistry(tracker).apply { register("test.screen", Data.serializer()) { Text(it.title) } }
        val screen = checkNotNull(registry.resolve(ScreenEnvelope("test.screen", JsonObject(mapOf("title" to JsonPrimitive("Hi"))))))
        var showing by mutableStateOf(true)

        compose.setContent { if (showing) screen.content() }
        compose.waitForIdle()
        assertEquals(listOf("test.screen"), tracker.appeared.map { it.first })

        showing = false
        compose.waitForIdle()
        assertEquals(tracker.appeared.map { it.second }, tracker.disappeared)
    }
}
