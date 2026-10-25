package app.parkhill.ui

import app.parkhill.environment.ServiceBinding
import java.net.HttpURLConnection
import java.net.URL
import java.net.URLEncoder
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.jsonArray
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import org.junit.rules.ExternalResource

/**
 * Changes `group_members` and `group_leaders` rows in local Supabase, through
 * its REST API with the local service-role key, as someone else would while a
 * test looks on. A rule: when the test ends, pass or fail, every group it
 * kept ([keep], and every change here keeps its group first) gets back exactly
 * the members and leaders it had, including changes the test made through the
 * app. Test sources only; the key never reaches the app.
 */
class LocalGroupRows : ExternalResource() {
    private class Snapshot(val members: Set<String>, val leaders: Set<String>)

    private val kept = mutableMapOf<String, Snapshot>()

    /** Remembers the group's rows now, to put them back when the test ends. Call before the test changes the group. */
    fun keep(groupId: String) {
        if (groupId !in kept) kept[groupId] = Snapshot(members(groupId), leaders(groupId))
    }

    /** The group's member ids now. */
    fun members(groupId: String): Set<String> = userIds(MEMBERS, groupId)

    /** Ends `userId`'s membership, and with it any leadership. */
    fun removeMember(groupId: String, userId: String) {
        keep(groupId)
        delete(MEMBERS, groupId, userId)
    }

    /** Makes the member `userId` a leader of the group. */
    fun makeLeader(groupId: String, userId: String) {
        keep(groupId)
        insert(LEADERS, groupId, userId)
    }

    override fun after() {
        kept.forEach { (groupId, snapshot) ->
            (leaders(groupId) - snapshot.leaders).forEach { delete(LEADERS, groupId, it) }
            (members(groupId) - snapshot.members).forEach { delete(MEMBERS, groupId, it) }
            (snapshot.members - members(groupId)).forEach { insert(MEMBERS, groupId, it) }
            (snapshot.leaders - leaders(groupId)).forEach { insert(LEADERS, groupId, it) }
        }
        kept.clear()
    }

    private fun leaders(groupId: String): Set<String> = userIds(LEADERS, groupId)

    private fun userIds(table: String, groupId: String): Set<String> =
        Json.parseToJsonElement(request("GET", "$table?select=user_id&group_id=eq.${encode(groupId)}")).jsonArray
            .map { it.jsonObject.getValue("user_id").jsonPrimitive.content }
            .toSet()

    private fun insert(table: String, groupId: String, userId: String) {
        val row = JsonObject(mapOf("group_id" to JsonPrimitive(groupId), "user_id" to JsonPrimitive(userId)))
        request("POST", table, body = row.toString())
    }

    private fun delete(table: String, groupId: String, userId: String) {
        request("DELETE", "$table?group_id=eq.${encode(groupId)}&user_id=eq.${encode(userId)}")
    }

    /** One REST request as the service role; fails the test on any status but 2xx. */
    private fun request(method: String, path: String, body: String? = null): String {
        val connection = URL("${checkNotNull(ServiceBinding.environment.backend).url}/rest/v1/$path").openConnection() as HttpURLConnection
        try {
            connection.requestMethod = method
            connection.setRequestProperty("apikey", SERVICE_ROLE_KEY)
            connection.setRequestProperty("Authorization", "Bearer $SERVICE_ROLE_KEY")
            connection.setRequestProperty("Prefer", "return=minimal")
            if (body != null) {
                connection.doOutput = true
                connection.setRequestProperty("Content-Type", "application/json")
                connection.outputStream.use { it.write(body.toByteArray()) }
            }
            val status = connection.responseCode
            val text = (if (status in 200..299) connection.inputStream else connection.errorStream)?.bufferedReader()?.readText().orEmpty()
            check(status in 200..299) { "$method $path: $status $text" }
            return text
        } finally {
            connection.disconnect()
        }
    }

    private fun encode(value: String) = URLEncoder.encode(value, "UTF-8")

    private companion object {
        const val MEMBERS = "group_members"
        const val LEADERS = "group_leaders"

        /**
         * Local Supabase's well-known service-role key (the CLI's fixed
         * default, like the anon key in build.gradle.kts), not a secret. A
         * backend other than local Supabase needs its own.
         */
        const val SERVICE_ROLE_KEY =
            "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImV4cCI6MTk4MzgxMjk5Nn0.EGIM96RAZx35lJzdJsyH-qQwv8Hdp7fsn3W0YpN81IU"
    }
}
