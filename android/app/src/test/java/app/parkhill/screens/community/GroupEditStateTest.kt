package app.parkhill.screens.community

import app.parkhill.contract.CommunityGroupData
import app.parkhill.contract.CommunityHomeData
import app.parkhill.contract.GroupDetail
import app.parkhill.contract.PersonRow
import app.parkhill.contract.SaveResult
import app.parkhill.contract.ScreenEnvelope
import app.parkhill.services.backend.ContractJson
import java.io.File
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * Edit mode's staging and batch (AND-013 AC2 to AC5), with the recorded
 * detail of Tuesday Night Group as `leader` and as `staff` see it.
 */
class GroupEditStateTest {
    private val root = File(checkNotNull(javaClass.classLoader?.getResource("get_entry.json")).toURI()).parentFile!!
    private val tuesday = "d44d5b87-37ce-5db5-9e33-43f477b42f1e"

    private fun envelope(path: String) = ContractJson.decodeFromString(ScreenEnvelope.serializer(), File(root, path).readText())

    private val leader: GroupDetail =
        ContractJson.decodeFromJsonElement(CommunityHomeData.serializer(), envelope("leader/get_screen.community.home.json").data).group!!
    private val staff: GroupDetail =
        ContractJson.decodeFromJsonElement(CommunityGroupData.serializer(), envelope("staff/get_screen.community.group@group_id=$tuesday.json").data)

    private val emptyBatch = JsonObject(
        mapOf(
            "fields" to JsonObject(emptyMap()),
            "add" to JsonArray(emptyList()),
            "remove" to JsonArray(emptyList()),
            "make_leader" to JsonArray(emptyList()),
            "remove_leader" to JsonArray(emptyList()),
        ),
    )

    private fun ids(vararg ids: String) = JsonArray(ids.map(::JsonPrimitive))

    private val newPerson = PersonRow("new", "New Person", selectable = true)

    @Test
    fun nothingStagedSendsAnEmptyBatchAndShowsTheMembersAsTheyWere() {
        val edit = GroupEditState(leader)
        assertEquals(emptyBatch, edit.batch)
        assertEquals(leader.members.map { it.userId }, edit.rows.map { it.id })
        assertEquals(leader.editFields!!.associate { it.id to it.value }, edit.values)
    }

    @Test
    fun theBatchCarriesOnlyChangedFieldsAndEveryStagedChange() {
        val edit = GroupEditState(leader)
        val member = leader.members.first { it.remove != null }

        edit.setValue("location", "Park home")
        edit.setValue("name", leader.title)
        edit.add(listOf(newPerson))
        edit.remove(member.userId)

        assertEquals(
            JsonObject(
                mapOf(
                    "fields" to JsonObject(mapOf("location" to JsonPrimitive("Park home"))),
                    "add" to ids("new"),
                    "remove" to ids(member.userId),
                    "make_leader" to ids(),
                    "remove_leader" to ids(),
                ),
            ),
            edit.batch,
        )
        assertEquals(GroupEditState.Row("new", "New Person", null, isLeader = false, isPending = true, canRemove = true, canToggleLeader = false), edit.rows.last())
        assertFalse(edit.rows.any { it.id == member.userId })
    }

    @Test
    fun aLeaderCannotToggleLeadersOrRemoveRowsWithoutRemove() {
        val edit = GroupEditState(leader)
        val own = leader.members.first { it.remove == null }

        edit.toggleLeader(own.userId)
        edit.remove(own.userId)

        assertEquals(emptyBatch, edit.batch)
        assertTrue(edit.rows.none { it.canToggleLeader })
    }

    @Test
    fun staffToggleLeadersAndTogglingBackUnstages() {
        val edit = GroupEditState(staff)
        val currentLeader = staff.members.first { it.isLeader }
        val member = staff.members.first { !it.isLeader }

        edit.toggleLeader(member.userId)
        edit.toggleLeader(currentLeader.userId)
        assertEquals(ids(member.userId), edit.batch["make_leader"])
        assertEquals(ids(currentLeader.userId), edit.batch["remove_leader"])
        assertTrue(edit.rows.single { it.id == member.userId }.isLeader)
        assertFalse(edit.rows.single { it.id == currentLeader.userId }.isLeader)

        edit.toggleLeader(member.userId)
        assertEquals(ids(), edit.batch["make_leader"])
        assertFalse(edit.rows.single { it.id == member.userId }.isLeader)
    }

    @Test
    fun removingAMemberDropsTheirStagedLeadership() {
        val edit = GroupEditState(staff)
        val member = staff.members.first { !it.isLeader && it.remove != null }
        edit.toggleLeader(member.userId)
        edit.remove(member.userId)

        assertEquals(ids(), edit.batch["make_leader"])
        assertEquals(ids(member.userId), edit.batch["remove"])
    }

    @Test
    fun addingSkipsMembersAndPeopleAlreadyAddedAndRemovingAPendingRowDropsIt() {
        val edit = GroupEditState(leader)
        val member = leader.members.first()

        edit.add(listOf(PersonRow(member.userId, member.title, selectable = true), newPerson))
        edit.add(listOf(newPerson))
        assertEquals(ids("new"), edit.batch["add"])
        assertFalse(edit.rows.single { it.id == "new" }.canToggleLeader)

        edit.remove("new")
        assertEquals(emptyBatch, edit.batch)
    }

    @Test
    fun aFailedSaveKeepsTheChangesAndShowsEachProblemInPlace() {
        val edit = GroupEditState(leader)
        edit.setValue("name", "")
        edit.add(listOf(newPerson))
        val failed = ContractJson.decodeFromString(SaveResult.serializer(), File(root, "save_group_changes.failed.json").readText())

        assertFalse(GroupEditState.succeeded(ContractJson.parseToJsonElement(File(root, "save_group_changes.failed.json").readText())))
        edit.show(failed)

        assertEquals(mapOf("name" to "Enter a name."), edit.fieldErrors)
        assertTrue("Already a member" in edit.rowErrors.values)
        assertEquals("", edit.values["name"])
        assertEquals(ids("new"), edit.batch["add"])
    }

    @Test
    fun theRecordedOkSaveSucceeds() {
        assertTrue(GroupEditState.succeeded(ContractJson.parseToJsonElement(File(root, "save_group_changes.ok.json").readText())))
        assertFalse(GroupEditState.succeeded(JsonObject(emptyMap())))
    }

    // Cancel drops the state; Edit again starts from the data as it is then, with nothing staged.
    @Test
    fun editingAgainAfterCancelStartsFromTheDataWithNothingStaged() {
        val first = GroupEditState(leader)
        first.setValue("name", "Changed")
        first.remove(leader.members.first { it.remove != null }.userId)

        val again = GroupEditState(leader)
        assertEquals(emptyBatch, again.batch)
        assertEquals(leader.members.size, again.rows.size)
    }
}
