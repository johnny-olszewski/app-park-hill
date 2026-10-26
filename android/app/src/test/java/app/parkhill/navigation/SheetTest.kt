package app.parkhill.navigation

import app.parkhill.cache.ScreenCache
import app.parkhill.contract.NavigateAction
import app.parkhill.contract.NavigateActionPresentation
import app.parkhill.contract.NavigateActionType
import app.parkhill.contract.PersonRow
import app.parkhill.contract.ScreenEnvelope
import app.parkhill.contract.TabItem
import app.parkhill.services.backend.BackendError
import java.nio.file.Files
import kotlinx.coroutines.test.runTest
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertSame
import org.junit.Assert.assertTrue
import org.junit.Test

/** `sheet`: fetched over a loading state from a tab or a cover; hands the chosen people back to its opener (AND-012 AC1, AC3). */
class SheetTest {
    @Serializable
    private data class TestData(val title: String)

    private val backend = StubBackendService { throw BackendError.Server }
    private val registry = ScreenRegistry().apply {
        register("test.screen", TestData.serializer(), title = { it.title }) {}
        register("test.sheet", TestData.serializer(), title = { it.title }) {}
    }
    private val context = ScreenContext(backend, registry, ScreenCache(Files.createTempDirectory("screens").toFile())) { "en" }

    init {
        backend.screen = { key, _ -> screen(if (key == "test.sheet") "Sheet" else "Fresh", key) }
    }

    private fun screen(title: String, key: String = "test.screen") = ScreenEnvelope(key, JsonObject(mapOf("title" to JsonPrimitive(title))))

    private fun navigate(to: String, presentation: NavigateActionPresentation) =
        NavigateAction(NavigateActionType.NAVIGATE, to, params, presentation)

    private val params = JsonObject(mapOf("group_id" to JsonPrimitive("g")))
    private val openSheet = navigate("test.sheet", NavigateActionPresentation.SHEET)

    private fun tab() = TabCoordinator(TabItem("t", "T", "tab.t", screen("Root")), context, eagerScope())

    private val ana = PersonRow("a", "Ana Ruiz", selectable = true)
    private val ben = PersonRow("b", "Ben Carter", selectable = true)

    @Test
    fun opensOverALoadingStateAndFetchesItsTargetWithItsParams() = runTest {
        val tab = tab()
        tab.actions.perform(openSheet)

        val sheet = tab.presented!!.screen
        assertSame(ScreenState.Loading, sheet.state)
        assertTrue(sheet.needsLoad)
        sheet.load()
        assertEquals("test.sheet" to params, backend.screenCalls.last())
        assertEquals("Sheet", (sheet.state as ScreenState.Showing).screen.title)
        assertTrue(tab.path.isEmpty())
    }

    @Test
    fun opensFromInsideACoverAndLeavesTheCoverOpen() {
        val tab = tab()
        tab.actions.perform(navigate("test.screen", NavigateActionPresentation.FULL_SCREEN_COVER))
        val cover = tab.cover!!
        tab.actions.from(cover.root).perform(openSheet)

        assertNotNull(tab.presented)
        assertSame(cover, tab.cover)
        assertTrue(cover.path.isEmpty())
    }

    @Test
    fun returningPeopleClosesTheSheetAndHandsThemToItsOpener() {
        val tab = tab()
        var returned: List<PersonRow>? = null
        tab.actions.from(tab.root).open(openSheet) { returned = it }

        tab.sheetActions.returnPeople(listOf(ana, ben))

        assertNull(tab.presented)
        assertEquals(listOf(ana, ben), returned)
    }

    @Test
    fun cancellingOrDraggingDownClosesTheSheetAndHandsBackNothing() {
        val tab = tab()
        var returned: List<PersonRow>? = null
        tab.actions.open(openSheet) { returned = it }
        tab.sheetActions.cancel()
        assertNull(tab.presented)

        // Dragging down is the sheet's dismiss request.
        tab.actions.open(openSheet) { returned = it }
        tab.dismiss()
        assertNull(tab.presented)
        assertNull(returned)
    }

    @Test
    fun aSheetOpenedWithoutAnOpenerReturnsToNobody() {
        val tab = tab()
        tab.actions.perform(openSheet)
        tab.sheetActions.returnPeople(listOf(ana))
        assertNull(tab.presented)
    }

    @Test
    fun aSheetRefusedAsUnavailableClosesAndTheScreenBelowRefreshes() = runTest {
        backend.screen = { key, _ ->
            if (key == "test.sheet") throw BackendError.ScreenUnavailable("You're no longer in this group")
            screen("Fresh")
        }
        val tab = tab()
        tab.actions.perform(openSheet)
        tab.presented!!.screen.load()

        assertNull(tab.presented)
        assertEquals("You're no longer in this group", tab.message?.text)
        assertEquals("Fresh", (tab.root.state as ScreenState.Showing).screen.title)
    }

    @Test
    fun anUnregisteredSheetTargetOpensNothing() {
        val tab = tab()
        tab.actions.perform(navigate("future.screen", NavigateActionPresentation.SHEET))
        assertNull(tab.presented)
    }
}
