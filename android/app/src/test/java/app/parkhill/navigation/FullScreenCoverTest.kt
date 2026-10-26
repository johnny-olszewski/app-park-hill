package app.parkhill.navigation

import app.parkhill.cache.ScreenCache
import app.parkhill.contract.NavigateAction
import app.parkhill.contract.NavigateActionPresentation
import app.parkhill.contract.NavigateActionType
import app.parkhill.contract.ScreenEnvelope
import app.parkhill.contract.TabItem
import java.nio.file.Files
import kotlinx.coroutines.test.runTest
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNotSame
import org.junit.Assert.assertNull
import org.junit.Assert.assertSame
import org.junit.Assert.assertTrue
import org.junit.Test

/** `full_screen_cover`: opens fresh over a loading state, has its own stack, back pops then closes (AND-026 AC3 to AC5). */
class FullScreenCoverTest {
    @Serializable
    private data class TestData(val title: String)

    private val backend = StubBackendService { screen("Entry") }
    private val registry = ScreenRegistry().apply {
        register("test.screen", TestData.serializer(), title = { it.title }) {}
        register("test.cover", TestData.serializer(), title = { it.title }) {}
    }
    private val context = ScreenContext(backend, registry, ScreenCache(Files.createTempDirectory("screens").toFile())) { "en" }
    private val params = JsonObject(mapOf("id" to JsonPrimitive("1")))

    private fun screen(title: String, key: String = "test.screen") = ScreenEnvelope(key, JsonObject(mapOf("title" to JsonPrimitive(title))))

    private fun navigate(to: String, presentation: NavigateActionPresentation) =
        NavigateAction(NavigateActionType.NAVIGATE, to, params, presentation)

    private val openCover = navigate("test.cover", NavigateActionPresentation.FULL_SCREEN_COVER)
    private val push = navigate("test.screen", NavigateActionPresentation.PUSH)

    private fun tab() = TabCoordinator(TabItem("t", "T", "tab.t", screen("Root")), context, eagerScope())

    @Test
    fun opensOverALoadingStateAndFetchesItsTarget() = runTest {
        backend.screen = { key, _ -> screen("Cover", key) }
        val tab = tab()
        tab.perform(openCover)

        assertNotNull(tab.cover)
        val cover = tab.cover!!
        assertSame(ScreenState.Loading, cover.root.state)
        assertTrue(cover.root.needsLoad)
        cover.root.load()
        assertEquals("test.cover" to params, backend.screenCalls.last())
        assertEquals("Cover", (cover.root.state as ScreenState.Showing).screen.title)
        assertTrue(tab.path.isEmpty())
    }

    @Test
    fun pushesInsideTheCoverWhileItIsOpen() {
        val tab = tab()
        tab.perform(openCover)
        tab.perform(push)
        assertEquals(1, tab.cover!!.path.size)
        assertTrue(tab.path.isEmpty())

        tab.closeCover()
        tab.perform(push)
        assertEquals(1, tab.path.size)
    }

    @Test
    fun backPopsInsideTheCoverThenClosesIt() {
        val tab = tab()
        tab.push(screen("Under"))
        tab.perform(openCover)
        tab.perform(push)

        assertTrue(tab.back())
        assertNotNull(tab.cover)
        assertTrue(tab.cover!!.path.isEmpty())

        assertTrue(tab.back())
        assertNull(tab.cover)
        assertEquals(1, tab.path.size)

        assertTrue(tab.back())
        assertTrue(tab.path.isEmpty())
        assertFalse(tab.back())
    }

    @Test
    fun reopeningFetchesAFreshCopy() = runTest {
        var fetches = 0
        backend.screen = { key, _ -> fetches += 1; screen("Cover $fetches", key) }
        val tab = tab()
        tab.perform(openCover)
        val first = tab.cover!!
        first.root.load()
        tab.closeCover()

        tab.perform(openCover)
        val second = tab.cover!!
        assertNotSame(first, second)
        assertSame(ScreenState.Loading, second.root.state)
        second.root.load()
        assertEquals("Cover 2", (second.root.state as ScreenState.Showing).screen.title)
        assertEquals(2, backend.screenCalls.count { it.first == "test.cover" })
    }

    @Test
    fun aSecondCoverIsIgnoredWhileOneIsOpen() {
        val tab = tab()
        tab.perform(openCover)
        val first = tab.cover
        tab.perform(openCover)
        assertSame(first, tab.cover)
    }

    @Test
    fun anUnregisteredCoverTargetOpensNothing() {
        val tab = tab()
        tab.perform(navigate("future.screen", NavigateActionPresentation.FULL_SCREEN_COVER))
        assertNull(tab.cover)
    }
}
