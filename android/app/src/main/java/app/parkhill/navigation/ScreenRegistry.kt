package app.parkhill.navigation

import android.util.Log
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import app.parkhill.contract.ScreenEnvelope
import app.parkhill.services.backend.ContractJson
import java.util.concurrent.atomic.AtomicLong
import kotlinx.serialization.KSerializer
import kotlinx.serialization.SerializationException
import kotlinx.serialization.json.JsonObject

/**
 * Maps screen keys to screen factories (guide 5.1). The only way screens are
 * created: coordinators resolve envelopes here, composables never build
 * screens. Each flavor's binding decides which screen sets are registered.
 */
class ScreenRegistry(private val tracker: ScreenTracker? = null) {
    private val factories = mutableMapOf<String, (JsonObject) -> Pair<String?, @Composable () -> Unit>>()
    private val nextId = AtomicLong()

    /**
     * Registers `key`; its data is decoded with `serializer` when an envelope
     * is resolved. `title`, when given, is the title a pushed screen shows in
     * the top app bar. Data that decodes but that the screen cannot show
     * (`isUsable` false) does not resolve, like data that does not decode.
     */
    fun <Data> register(
        key: String,
        serializer: KSerializer<Data>,
        title: ((Data) -> String)? = null,
        isUsable: (Data) -> Boolean = { true },
        screen: @Composable (Data) -> Unit,
    ) {
        require(key !in factories) { "Screen $key registered twice" }
        factories[key] = { json ->
            val data = ContractJson.decodeFromJsonElement(serializer, json)
            require(isUsable(data)) { "Screen $key cannot show this data" }
            val content: @Composable () -> Unit = { screen(data) }
            title?.invoke(data) to content
        }
    }

    fun isRegistered(key: String): Boolean = key in factories

    /**
     * The screen for an envelope, or null when its key is not registered or
     * its data does not match the screen's model. Both are logged.
     */
    fun resolve(envelope: ScreenEnvelope): ResolvedScreen? {
        val factory = factories[envelope.key] ?: run {
            Log.e(TAG, "Dropped unregistered screen key ${envelope.key}")
            return null
        }
        return try {
            val (title, content) = factory(envelope.data)
            ResolvedScreen(envelope, tracked(content, envelope), title)
        } catch (error: SerializationException) {
            Log.e(TAG, "Dropped screen ${envelope.key}: data does not match its model")
            null
        } catch (error: IllegalArgumentException) {
            Log.e(TAG, "Dropped screen ${envelope.key}: data does not match its model or cannot be shown")
            null
        }
    }

    /** Reports the screen's appearance to the tracker, when there is one. */
    private fun tracked(content: @Composable () -> Unit, envelope: ScreenEnvelope): @Composable () -> Unit {
        val tracker = tracker ?: return content
        val id = nextId.incrementAndGet()
        return {
            DisposableEffect(id) {
                tracker.screenDidAppear(envelope, id)
                onDispose { tracker.screenDidDisappear(id) }
            }
            content()
        }
    }

    private companion object {
        const val TAG = "Navigation"
    }
}

/** A screen ready to show, with the envelope it was built from and its title, if it has one. */
class ResolvedScreen(val envelope: ScreenEnvelope, val content: @Composable () -> Unit, val title: String? = null) {
    val key: String get() = envelope.key
}
