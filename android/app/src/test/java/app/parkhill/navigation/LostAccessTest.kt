package app.parkhill.navigation

import app.parkhill.cache.ScreenCache
import app.parkhill.contract.NavigateAction
import app.parkhill.contract.NavigateActionPresentation
import app.parkhill.contract.NavigateActionType
import app.parkhill.contract.ScreenEnvelope
import app.parkhill.contract.TabItem
import app.parkhill.services.backend.BackendError
import java.nio.file.Files
import kotlinx.coroutines.test.runTest
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.jsonPrimitive
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

/** The lost-access rule on every screen (guide 5.3 rule 9, AND-027 AC4). */
class LostAccessTest {
    @Serializable
    private data class TestData(val title: String)

    private val backend = StubBackendService { throw BackendError.Server }
    private val registry = ScreenRegistry().apply {
        register("test.screen", TestData.serializer(), title = { it.title }) {}
    }
    private val context = ScreenContext(backend, registry, ScreenCache(Files.createTempDirectory("screens").toFile())) { "en" }

    /** Screens whose `id` is in this set are refused as unavailable; every other screen answers "Fresh <id>". */
    private val unavailable = mutableSetOf<String>()

    init {
        backend.screen = { key, params ->
            val id = params["id"]?.jsonPrimitive?.content ?: "root"
            if (id in unavailable) throw BackendError.ScreenUnavailable("You're no longer in this group")
            screen("Fresh $id", key)
        }
    }

    private fun screen(title: String, key: String = "test.screen") = ScreenEnvelope(key, JsonObject(mapOf("title" to JsonPrimitive(title))))

    private fun navigate(id: String, presentation: NavigateActionPresentation = NavigateActionPresentation.PUSH) =
        NavigateAction(NavigateActionType.NAVIGATE, "test.screen", JsonObject(mapOf("id" to JsonPrimitive(id))), presentation)

    private fun tab() = TabCoordinator(TabItem("t", "T", "tab.t", screen("Root")), context, eagerScope())

    private fun title(model: ScreenModel) = (model.state as ScreenState.Showing).screen.title

    @Test
    fun aPushedScreenRefusedOnRefreshClosesWithWhatIsOverItAndTheOneBelowRefreshes() = runTest {
        val tab = tab()
        tab.perform(navigate("a"))
        tab.perform(navigate("b"))
        tab.perform(navigate("c"))
        tab.path.forEach { it.screen.load() }
        backend.screenCalls.clear()

        unavailable += "b"
        assertFalse(tab.path[1].screen.load())

        assertEquals(listOf("Fresh a"), tab.path.map { title(it.screen) })
        assertEquals("You're no longer in this group", tab.message?.text)
        // The screen below refreshed: a fetch of "a" after the refused one.
        assertEquals(listOf("b", "a"), backend.screenCalls.map { it.second["id"]?.jsonPrimitive?.content })
    }

    @Test
    fun aPushedScreenRefusedOnItsFirstLoadClosesAndTheRootRefreshes() = runTest {
        val tab = tab()
        unavailable += "a"
        tab.perform(navigate("a"))
        tab.path.single().screen.load()

        assertTrue(tab.path.isEmpty())
        assertEquals("Fresh root", title(tab.root))
        assertEquals("You're no longer in this group", tab.message?.text)
    }

    @Test
    fun aTabRootRefusedKeepsShowingWithTheMessage() = runTest {
        val tab = tab()
        unavailable += "root"
        assertFalse(tab.root.load())

        assertEquals("Root", title(tab.root))
        assertEquals("You're no longer in this group", tab.message?.text)
    }

    @Test
    fun aCoverRootRefusedClosesTheCoverAndTheTabsTopRefreshes() = runTest {
        val tab = tab()
        tab.perform(navigate("a"))
        tab.path.single().screen.load()
        unavailable += "cover"
        tab.perform(navigate("cover", NavigateActionPresentation.FULL_SCREEN_COVER))
        tab.cover!!.root.load()

        assertNull(tab.cover)
        assertEquals(listOf("Fresh a"), tab.path.map { title(it.screen) })
        assertEquals("a", backend.screenCalls.last().second["id"]?.jsonPrimitive?.content)
        assertEquals("You're no longer in this group", tab.message?.text)
    }

    @Test
    fun aScreenPushedInACoverRefusedClosesInsideTheCover() = runTest {
        val tab = tab()
        tab.perform(navigate("cover", NavigateActionPresentation.FULL_SCREEN_COVER))
        val cover = tab.cover!!
        cover.root.load()
        unavailable += "inside"
        tab.perform(navigate("inside"))
        cover.path.single().screen.load()

        assertTrue(cover.path.isEmpty())
        assertEquals(cover, tab.cover)
        assertEquals("cover", backend.screenCalls.last().second["id"]?.jsonPrimitive?.content)
        assertEquals("You're no longer in this group", tab.message?.text)
    }

    @Test
    fun aShownMessageIsCleared() = runTest {
        val tab = tab()
        unavailable += "root"
        tab.root.load()
        val message = tab.message!!
        tab.messageShown(message)
        assertNull(tab.message)
    }
}
