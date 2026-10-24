package app.parkhill.cache

import app.parkhill.contract.ScreenEnvelope
import app.parkhill.services.backend.ContractJson
import java.io.File
import java.security.MessageDigest
import kotlinx.serialization.json.JsonObject

/**
 * The last good copy of every backend screen, per screen key, params and
 * locale (guide 5.3 rule 10). Lives under the cache directory, so sign-out
 * deletes it with everything else.
 */
class ScreenCache(val directory: File) {
    fun load(key: String, params: JsonObject, locale: String): ScreenEnvelope? = try {
        file(key, params, locale).takeIf { it.isFile }?.let { ContractJson.decodeFromString(ScreenEnvelope.serializer(), it.readText()) }
    } catch (_: Exception) {
        null
    }

    fun save(envelope: ScreenEnvelope, params: JsonObject, locale: String) {
        val target = file(envelope.key, params, locale)
        target.parentFile?.mkdirs()
        val temporary = File(target.parentFile, "${target.name}.tmp")
        temporary.writeText(ContractJson.encodeToString(ScreenEnvelope.serializer(), envelope))
        check(temporary.renameTo(target)) { "Could not write ${target.name}" }
    }

    /** One file per key and params, hashed so any params make a safe name. */
    private fun file(key: String, params: JsonObject, locale: String): File {
        val sorted = JsonObject(params.toSortedMap())
        val identity = "$key\u0000${ContractJson.encodeToString(JsonObject.serializer(), sorted)}"
        val name = MessageDigest.getInstance("SHA-256").digest(identity.toByteArray()).joinToString("") { "%02x".format(it) }
        val safeLocale = locale.filter { it.isLetterOrDigit() || it == '-' || it == '_' }.ifEmpty { "unknown" }
        return File(File(directory, safeLocale), "$name.json")
    }

    companion object {
        fun standard(filesDir: File) = ScreenCache(File(EntryCache.cacheDirectory(filesDir), "screens"))
    }
}
