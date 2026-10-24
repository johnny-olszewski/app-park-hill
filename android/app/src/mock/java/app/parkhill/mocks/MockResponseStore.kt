package app.parkhill.mocks

import android.content.Context
import java.io.File
import java.io.FileNotFoundException
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.longOrNull

/**
 * Reads mock responses (`/contract/mock_responses`), bundled as the mock flavor's
 * assets only. A persona's own mock response, in `<persona>/`, wins over the shared
 * one at the root.
 */
class MockResponseStore(private val read: (String) -> String?) {
    /** The mock response text for `name` (without `.json`), or null when none exists. */
    fun text(name: String, persona: String?): String? =
        listOfNotNull(persona?.let { "$it/$name.json" }, "$name.json").firstNotNullOfOrNull(read)

    companion object {
        /**
         * The file name, without `.json`, of a call with params:
         * `get_screen.community.group@group_id=<id>`, params sorted by name
         * (contract/README.md, Mock responses). Only text and whole-number
         * params are named; others give `name` alone.
         */
        fun name(name: String, params: JsonObject): String {
            if (params.isEmpty()) return name
            val parts = params.toSortedMap().map { (key, value) ->
                val primitive = value as? JsonPrimitive ?: return name
                val text = when {
                    primitive.isString -> primitive.content
                    primitive.longOrNull != null -> primitive.longOrNull.toString()
                    else -> return name
                }
                "$key=$text"
            }
            return name + "@" + parts.joinToString("&")
        }

        /** The mock responses bundled with the app. */
        fun assets(context: Context) = MockResponseStore { path ->
            try {
                context.assets.open(path).bufferedReader().use { it.readText() }
            } catch (_: FileNotFoundException) {
                null
            }
        }

        /** Mock responses in a directory, for tests. */
        fun directory(root: File) = MockResponseStore { path -> File(root, path).takeIf { it.isFile }?.readText() }
    }
}
