package app.parkhill.screens.community

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import app.parkhill.contract.GroupDetail
import app.parkhill.contract.PersonRow
import app.parkhill.contract.SaveResult
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive

/**
 * Group detail's edit mode (specs/COMMUNITY.md 5.3, 5.4): every change is
 * staged here, with no confirmations, until Done sends them all as one save
 * batch; Cancel drops this. Built from the detail as it was when Edit was
 * tapped, so a refresh underneath keeps the staged changes. Snapshot state.
 */
class GroupEditState(val original: GroupDetail) {
    /** Each edit field's value now, by field id. */
    var values: Map<String, String> by mutableStateOf(original.editFields.orEmpty().associate { it.id to it.value })
        private set

    /** People chosen in the picker, shown as pending rows, in the order added. */
    var added: List<PersonRow> by mutableStateOf(emptyList())
        private set

    var removed: Set<String> by mutableStateOf(emptySet())
        private set

    /** Members whose leadership is staged to change, to the state it will have. */
    var leaders: Map<String, Boolean> by mutableStateOf(emptyMap())
        private set

    /** The backend's messages from a failed save, by field id. */
    var fieldErrors: Map<String, String> by mutableStateOf(emptyMap())
        private set

    /** The backend's messages from a failed save, by user id. */
    var rowErrors: Map<String, String> by mutableStateOf(emptyMap())
        private set

    /** A row in edit mode: a member, or a person added and not saved yet. */
    data class Row(
        val id: String,
        val title: String,
        val note: String?,
        val isLeader: Boolean,
        val isPending: Boolean,
        val canRemove: Boolean,
        val canToggleLeader: Boolean,
    )

    /** The members still staged to stay, then the pending people. */
    val rows: List<Row>
        get() = original.members.filter { it.userId !in removed }.map { member ->
            Row(
                id = member.userId,
                title = member.title,
                note = member.note,
                isLeader = leaders[member.userId] ?: member.isLeader,
                isPending = false,
                canRemove = member.remove != null,
                canToggleLeader = member.toggleLeader == true,
            )
        } + added.map { person ->
            Row(person.userId, person.title, note = null, isLeader = false, isPending = true, canRemove = true, canToggleLeader = false)
        }

    fun setValue(fieldId: String, value: String) {
        values = values + (fieldId to value)
    }

    /** Adds people from the picker, once each, leaving out current members. */
    fun add(people: List<PersonRow>) {
        val present = original.members.map { it.userId }.toSet() + added.map { it.userId }
        added = added + people.filter { it.userId !in present }.distinctBy { it.userId }
    }

    /** Stages removing the row: a pending person is just dropped. */
    fun remove(userId: String) {
        if (added.any { it.userId == userId }) {
            added = added.filter { it.userId != userId }
        } else if (original.members.any { it.userId == userId && it.remove != null }) {
            removed = removed + userId
            leaders = leaders - userId
        }
    }

    /** Stages making the member a leader, or removing their leadership; toggling back unstages it. */
    fun toggleLeader(userId: String) {
        val member = original.members.firstOrNull { it.userId == userId && it.toggleLeader == true } ?: return
        val next = !(leaders[userId] ?: member.isLeader)
        leaders = if (next == member.isLeader) leaders - userId else leaders + (userId to next)
    }

    /** The save batch: only fields whose value changed, and every staged change to people (specs/COMMUNITY.md 5.4). */
    val batch: JsonObject
        get() {
            val changed = original.editFields.orEmpty().filter { values[it.id] != it.value }
            fun ids(ids: Collection<String>) = JsonArray(ids.sorted().map(::JsonPrimitive))
            return JsonObject(
                mapOf(
                    "fields" to JsonObject(changed.associate { it.id to JsonPrimitive(values[it.id].orEmpty()) }),
                    "add" to JsonArray(added.map { JsonPrimitive(it.userId) }),
                    "remove" to ids(removed),
                    "make_leader" to ids(leaders.filterValues { it }.keys),
                    "remove_leader" to ids(leaders.filterValues { !it }.keys),
                ),
            )
        }

    /** Keeps the staged changes and shows a failed save's problems in place. */
    fun show(result: SaveResult) {
        fieldErrors = messages(result.fieldErrors)
        rowErrors = messages(result.rowErrors)
    }

    private fun messages(value: JsonObject?): Map<String, String> =
        value.orEmpty().mapNotNull { (key, message) -> (message as? JsonPrimitive)?.takeIf { it.isString }?.let { key to it.content } }.toMap()

    companion object {
        /** True when a save's body says every change was saved. */
        fun succeeded(body: JsonElement): Boolean = (body as? JsonObject)?.get("ok") == JsonPrimitive(true)
    }
}
