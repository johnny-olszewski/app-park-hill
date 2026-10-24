package app.parkhill.navigation

import app.parkhill.cache.EntryCache
import app.parkhill.cache.ScreenCache
import app.parkhill.contract.ScreenEnvelope
import app.parkhill.contract.TabItem
import app.parkhill.services.auth.LocalUserData
import app.parkhill.services.backend.BackendError
import java.io.File
import java.nio.file.Files
import kotlinx.coroutines.test.runTest
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertSame
import org.junit.Assert.assertTrue
import org.junit.Test

/** Backend screens: refresh and the per-screen cache (AND-009 AC4, AC5). */
class ScreenModelTest {
    @Serializable
    private data class TestData(val title: String)

    private val cache = ScreenCache(Files.createTempDirectory("screens").toFile())
    private val backend = StubBackendService { throw BackendError.Server }
    private val registry = ScreenRegistry().apply {
        register("test.screen", TestData.serializer(), title = { it.title }) {}
    }
    private val context = ScreenContext(backend, registry, cache) { "en" }
    private val params = JsonObject(mapOf("id" to JsonPrimitive("1")))

    private fun screen(title: String) = ScreenEnvelope("test.screen", JsonObject(mapOf("title" to JsonPrimitive(title))))

    private fun answers(vararg results: () -> ScreenEnvelope) {
        val queue = ArrayDeque(results.toList())
        backend.screen = { _, _ -> (if (queue.size > 1) queue.removeFirst() else queue.first())() }
    }

    private fun tab() = TabCoordinator(TabItem("t", "T", "tab.t", screen("Root")), context)

    // AC4: pull to refresh shows the new data.

    @Test
    fun refreshShowsTheNewData() = runTest {
        answers({ screen("Fresh") })
        val model = ScreenModel.showing(screen("Stale"), context)
        model.load()
        assertEquals(screen("Fresh"), model.envelope)
        assertEquals(listOf("test.screen" to JsonObject(emptyMap())), backend.screenCalls)
    }

    @Test
    fun aFailedRefreshKeepsTheScreenShowing() = runTest {
        answers({ throw BackendError.Network })
        val model = ScreenModel.showing(screen("Shown"), context)
        model.load()
        assertEquals(screen("Shown"), model.envelope)
    }

    // AC5: a failed fetch shows the cached copy for that key and params, else the error screen.

    @Test
    fun aFailedFetchShowsTheCachedCopyForThatKeyAndParams() = runTest {
        answers({ screen("Online") }, { throw BackendError.Network })
        ScreenModel.toFetch("test.screen", params, context).load()

        val offline = ScreenModel.toFetch("test.screen", params, context)
        offline.load()
        assertEquals(screen("Online"), offline.envelope)

        val otherParams = ScreenModel.toFetch("test.screen", JsonObject(mapOf("id" to JsonPrimitive("2"))), context)
        otherParams.load()
        assertSame(ScreenState.Error, otherParams.state)
    }

    @Test
    fun aFailedFetchWithoutACacheShowsTheErrorAndRetryRecovers() = runTest {
        answers({ throw BackendError.Network }, { screen("Back") })
        val model = ScreenModel.toFetch("test.screen", params, context)
        model.load()
        assertSame(ScreenState.Error, model.state)
        model.retry()
        assertEquals(screen("Back"), model.envelope)
    }

    @Test
    fun aScreenThisBuildCannotShowFallsBackToTheCache() = runTest {
        answers({ screen("Good") }, { ScreenEnvelope("test.screen", JsonObject(emptyMap())) })
        ScreenModel.toFetch("test.screen", JsonObject(emptyMap()), context).load()
        val second = ScreenModel.toFetch("test.screen", JsonObject(emptyMap()), context)
        second.load()
        assertEquals(screen("Good"), second.envelope)
    }

    @Test
    fun theScreenCacheIsWipedWithTheUsersData() {
        val filesDir = Files.createTempDirectory("files").toFile()
        val cache = ScreenCache.standard(filesDir)
        cache.save(screen("Saved"), params, "en")
        assertTrue(cache.directory.startsWith(EntryCache.cacheDirectory(filesDir)))
        LocalUserData.standard(filesDir).wipe()
        assertEquals(null, cache.load("test.screen", params, "en"))
        assertFalse(File(filesDir, "Cache").exists())
    }

    @Test
    fun aTabRootKeepsItsStackWhenItsDataChanges() {
        val tab = tab()
        assertTrue(tab.push(screen("Pushed")))
        tab.update(TabItem("t", "T2", "tab.t", screen("Root 2")))
        assertEquals(screen("Root 2"), tab.root.envelope)
        assertEquals(1, tab.path.size)
        assertEquals("T2", tab.title)
    }
}
