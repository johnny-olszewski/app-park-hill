package app.parkhill.navigation

import app.parkhill.cache.EntryCache
import app.parkhill.services.backend.BackendError
import app.parkhill.services.backend.ScreenEnvelope
import java.nio.file.Files
import kotlinx.coroutines.test.runTest
import kotlinx.serialization.json.JsonObject
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class AppCoordinatorTest {
    private val backend = StubBackendService { StubBackendService.signIn() }
    private val cache = EntryCache(Files.createTempDirectory("entry").toFile())

    private fun coordinator() = AppCoordinator(backend, ScreenRegistry().apply { registerSharedScreens(app.parkhill.services.auth.FakeAuthService()) }, cache, { "en" })

    private fun AppCoordinator.shownTitle(): String? =
        ((entry.value as? EntryState.Screen)?.screen?.envelope?.data?.get("title") as? kotlinx.serialization.json.JsonPrimitive)?.content

    @Test
    fun launchShowsTheBackendEntryAndCachesIt() = runTest {
        val coordinator = coordinator()
        coordinator.start()
        assertEquals("Sign in", coordinator.shownTitle())
        assertEquals(StubBackendService.signIn(), cache.load("en"))
    }

    @Test
    fun aFailedFetchShowsTheCachedEntry() = runTest {
        cache.save(StubBackendService.signIn("Cached"), "en")
        backend.entry = { throw BackendError.Network }
        val coordinator = coordinator()
        coordinator.start()
        assertEquals("Cached", coordinator.shownTitle())
    }

    @Test
    fun aFailedFetchWithNoCacheShowsTheError() = runTest {
        backend.entry = { throw BackendError.Network }
        val coordinator = coordinator()
        coordinator.start()
        assertEquals(EntryState.Error, coordinator.entry.value)
    }

    @Test
    fun anUnregisteredEntryShowsTheErrorEvenWithACache() = runTest {
        cache.save(StubBackendService.signIn("Cached"), "en")
        backend.entry = { ScreenEnvelope("future.entry", JsonObject(emptyMap())) }
        val coordinator = coordinator()
        coordinator.start()
        assertEquals(EntryState.Error, coordinator.entry.value)
    }

    @Test
    fun retryAfterTheErrorShowsTheEntry() = runTest {
        backend.entry = { throw BackendError.Network }
        val coordinator = coordinator()
        coordinator.start()
        backend.entry = { StubBackendService.signIn() }
        coordinator.retry()
        assertEquals("Sign in", coordinator.shownTitle())
    }

    @Test
    fun returningToTheForegroundRefetches() = runTest {
        val coordinator = coordinator()
        coordinator.start()
        backend.entry = { StubBackendService.signIn("Welcome") }
        coordinator.movedToBackground()
        coordinator.movedToForeground()
        assertEquals("Welcome", coordinator.shownTitle())
    }

    @Test
    fun aForegroundWithoutABackgroundDoesNotRefetch() = runTest {
        val coordinator = coordinator()
        coordinator.start()
        coordinator.movedToForeground()
        assertEquals(1, backend.entryCalls)
    }

    @Test
    fun aFailedForegroundRefetchKeepsTheScreenShowing() = runTest {
        val coordinator = coordinator()
        coordinator.start()
        backend.entry = { throw BackendError.Network }
        coordinator.movedToBackground()
        coordinator.movedToForeground()
        assertTrue(coordinator.entry.value is EntryState.Screen)
        assertEquals("Sign in", coordinator.shownTitle())
    }
}
