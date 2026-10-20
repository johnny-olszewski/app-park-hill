package app.parkhill.navigation

import android.util.Log
import androidx.compose.runtime.Composable
import app.parkhill.services.backend.ContractJson
import app.parkhill.services.backend.ScreenEnvelope
import kotlinx.serialization.KSerializer
import kotlinx.serialization.SerializationException
import kotlinx.serialization.json.JsonObject

/**
 * Maps screen keys to screen factories (guide 5.1). The only way screens are
 * created: coordinators resolve envelopes here, composables never build
 * screens. Each flavor's binding decides which screen sets are registered.
 */
class ScreenRegistry {
    private val factories = mutableMapOf<String, (JsonObject) -> (@Composable () -> Unit)>()

    /** Registers `key`; its data is decoded with `serializer` when an envelope is resolved. */
    fun <Data> register(key: String, serializer: KSerializer<Data>, screen: @Composable (Data) -> Unit) {
        require(key !in factories) { "Screen $key registered twice" }
        factories[key] = { json ->
            val data = ContractJson.decodeFromJsonElement(serializer, json)
            val content: @Composable () -> Unit = { screen(data) }
            content
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
            ResolvedScreen(envelope, factory(envelope.data))
        } catch (error: SerializationException) {
            Log.e(TAG, "Dropped screen ${envelope.key}: data does not match its model")
            null
        } catch (error: IllegalArgumentException) {
            Log.e(TAG, "Dropped screen ${envelope.key}: data does not match its model")
            null
        }
    }

    private companion object {
        const val TAG = "Navigation"
    }
}

/** A screen ready to show, with the envelope it was built from. */
class ResolvedScreen(val envelope: ScreenEnvelope, val content: @Composable () -> Unit) {
    val key: String get() = envelope.key
}
