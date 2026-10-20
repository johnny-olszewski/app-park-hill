package app.parkhill.cache

import app.parkhill.services.backend.ContractJson
import app.parkhill.services.backend.ScreenEnvelope
import java.io.File

/**
 * The last good entry envelope, one JSON file per locale (guide 5.3). Lives
 * under the cache directory, which sign-out deletes wholesale (AND-005).
 */
class EntryCache(private val directory: File) {
    fun load(locale: String): ScreenEnvelope? = try {
        file(locale).takeIf { it.isFile }?.let { ContractJson.decodeFromString(ScreenEnvelope.serializer(), it.readText()) }
    } catch (_: Exception) {
        null
    }

    fun save(envelope: ScreenEnvelope, locale: String) {
        directory.mkdirs()
        val target = file(locale)
        val temporary = File(directory, "${target.name}.tmp")
        temporary.writeText(ContractJson.encodeToString(ScreenEnvelope.serializer(), envelope))
        check(temporary.renameTo(target)) { "Could not write ${target.name}" }
    }

    private fun file(locale: String): File {
        val safe = locale.filter { it.isLetterOrDigit() || it == '-' || it == '_' }.ifEmpty { "unknown" }
        return File(directory, "$safe.json")
    }

    companion object {
        /** Root of everything the app caches about the user. Sign-out deletes it. */
        fun cacheDirectory(filesDir: File) = File(filesDir, "Cache")

        fun standard(filesDir: File) = EntryCache(File(cacheDirectory(filesDir), "entry"))
    }
}
