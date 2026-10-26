package app.parkhill.screens.people

import app.parkhill.contract.CommunityHomeData
import app.parkhill.contract.NavigateAction
import app.parkhill.contract.PeoplePickerData
import app.parkhill.contract.ScreenEnvelope
import app.parkhill.navigation.ScreenRegistry
import app.parkhill.navigation.registerSharedScreens
import app.parkhill.services.auth.FakeAuthService
import app.parkhill.services.backend.ContractJson
import java.io.File
import kotlinx.serialization.json.jsonPrimitive
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Test

/** The people picker from the recorded responses: who can be chosen, search and what Add returns (AND-012 AC2 to AC4). */
class PeoplePickerTest {
    private val root = File(checkNotNull(javaClass.classLoader?.getResource("get_entry.json")).toURI()).parentFile!!

    private fun envelope(path: String): ScreenEnvelope =
        ContractJson.decodeFromString(ScreenEnvelope.serializer(), File(root, path).readText())

    /** The picker the leader's Add member opens, recorded under the action's params. */
    private val picker: ScreenEnvelope = run {
        val home = ContractJson.decodeFromJsonElement(CommunityHomeData.serializer(), envelope("leader/get_screen.community.home.json").data)
        val open = home.group!!.addMember!!.action as NavigateAction
        envelope("leader/get_screen.${open.screenKey}@group_id=${open.params.getValue("group_id").jsonPrimitive.content}.json")
    }
    private val data = ContractJson.decodeFromJsonElement(PeoplePickerData.serializer(), picker.data)

    private fun row(title: String) = data.rows.single { it.title == title }

    @Test
    fun everyPersonasRecordedPickerResolves() {
        val registry = ScreenRegistry().apply { registerSharedScreens(FakeAuthService()) }
        val pickers = root.walk().filter { it.name.startsWith("get_screen.people.picker") }.toList()
        assertTrue(pickers.isNotEmpty())
        pickers.forEach { file -> assertNotNull(file.path, registry.resolve(envelope(file.relativeTo(root).path))) }
    }

    // AC2: rows that are not selectable show their note and cannot be chosen.

    @Test
    fun aCurrentMemberShowsTheirNoteAndCannotBeChosen() {
        val state = PeoplePickerState(data.rows)
        val ana = row("Ana Ruiz")
        assertFalse(ana.selectable)
        assertEquals("Already a member", ana.note)

        state.toggle(ana)
        assertFalse(state.isChosen(ana))
        assertTrue(state.chosenRows.isEmpty())
    }

    // AC3: Add returns every chosen person, in list order; choosing again unchooses.

    @Test
    fun theChosenPeopleAreEveryoneTickedInListOrder() {
        val state = PeoplePickerState(data.rows)
        state.toggle(row("Zoe Laurent"))
        state.toggle(row("Aaliyah Davis"))
        state.toggle(row("Mei Chen"))
        state.toggle(row("Mei Chen"))

        assertEquals(listOf("Aaliyah Davis", "Zoe Laurent"), state.chosenRows.map { it.title })
        assertEquals(listOf(row("Aaliyah Davis").userId, row("Zoe Laurent").userId), state.chosenRows.map { it.userId })
    }

    // AC4: search filters by name as you type, keeping chosen people chosen.

    @Test
    fun searchFiltersByNameAsYouTypeIgnoringCaseAndSpaces() {
        val state = PeoplePickerState(data.rows)
        assertEquals(data.rows, state.visibleRows)
        state.query = "  BROOKS "
        assertEquals(listOf("Hannah Brooks", "Nathan Brooks"), state.visibleRows.map { it.title })
        state.query = "zzz"
        assertTrue(state.visibleRows.isEmpty())
    }

    @Test
    fun searchKeepsChosenPeopleChosen() {
        val state = PeoplePickerState(data.rows)
        state.toggle(row("Hannah Brooks"))
        state.query = "Zoe"
        state.toggle(row("Zoe Laurent"))
        assertEquals(listOf("Zoe Laurent"), state.visibleRows.map { it.title })

        state.query = ""
        assertTrue(state.isChosen(row("Hannah Brooks")))
        assertEquals(listOf("Hannah Brooks", "Zoe Laurent"), state.chosenRows.map { it.title })
    }
}
