package app.parkhill.mocks

import android.content.Context
import java.io.File
import java.io.FileNotFoundException

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
