package app.parkhill.cache

import app.parkhill.contract.ScreenEnvelope
import app.parkhill.contract.TabsResponse
import app.parkhill.services.backend.ContractJson
import java.io.File
import kotlinx.serialization.KSerializer

/**
 * The last good response of one kind, one JSON file per locale (guide 5.3).
 * Every cache lives under the cache directory, which sign-out deletes
 * wholesale (AND-005).
 */
open class LocaleCache<T>(private val directory: File, private val serializer: KSerializer<T>) {
    fun load(locale: String): T? = try {
        file(locale).takeIf { it.isFile }?.let { ContractJson.decodeFromString(serializer, it.readText()) }
    } catch (_: Exception) {
        null
    }

    fun save(value: T, locale: String) {
        directory.mkdirs()
        val target = file(locale)
        val temporary = File(directory, "${target.name}.tmp")
        temporary.writeText(ContractJson.encodeToString(serializer, value))
        check(temporary.renameTo(target)) { "Could not write ${target.name}" }
    }

    private fun file(locale: String): File {
        val safe = locale.filter { it.isLetterOrDigit() || it == '-' || it == '_' }.ifEmpty { "unknown" }
        return File(directory, "$safe.json")
    }
}

/** The last good signed-out entry screen. */
class EntryCache(directory: File) : LocaleCache<ScreenEnvelope>(directory, ScreenEnvelope.serializer()) {
    companion object {
        /** Root of everything the app caches about the user. Sign-out deletes it. */
        fun cacheDirectory(filesDir: File) = File(filesDir, "Cache")

        fun standard(filesDir: File) = EntryCache(File(cacheDirectory(filesDir), "entry"))
    }
}

/** The last good signed-in tabs, with their root screens. */
class TabsCache(directory: File) : LocaleCache<TabsResponse>(directory, TabsResponse.serializer()) {
    companion object {
        fun standard(filesDir: File) = TabsCache(File(EntryCache.cacheDirectory(filesDir), "tabs"))
    }
}
