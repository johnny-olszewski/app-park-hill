package app.parkhill.navigation

import app.parkhill.cache.EntryCache
import app.parkhill.services.auth.AuthState
import app.parkhill.services.auth.AuthUser
import app.parkhill.services.auth.FakeAuthService
import app.parkhill.services.auth.SignOutReason
import app.parkhill.services.backend.BackendError
import app.parkhill.services.backend.ScreenEnvelope
import java.nio.file.Files
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.UnconfinedTestDispatcher
import kotlinx.coroutines.test.runTest
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class AppCoordinatorTest {
    private val backend = StubBackendService { StubBackendService.signIn() }
    private val auth = FakeAuthService()
    private val cache = EntryCache(Files.createTempDirectory("entry").toFile())
    private val user = AuthUser("u", "a@b.c")

    private fun TestScope.coordinator() = AppCoordinator(
        backend, auth, ScreenRegistry().apply { registerSharedScreens(auth) }, cache, backgroundScope, { "en" },
    )

    private fun AppCoordinator.shownTitle(): String? =
        ((state.value.entry as? EntryState.Screen)?.screen?.envelope?.data?.get("title") as? JsonPrimitive)?.content

    @Test
    fun signedOutLaunchShowsTheBackendEntryAndCachesIt() = runTest(UnconfinedTestDispatcher()) {
        val coordinator = coordinator()
        coordinator.start()
        assertFalse(coordinator.state.value.isLaunching)
        assertTrue(coordinator.state.value.isEntryPresented)
        assertEquals("Sign in", coordinator.shownTitle())
        assertEquals(StubBackendService.signIn(), cache.load("en"))
    }

    @Test
    fun aStoredSessionGoesStraightToTheSignedInDestination() = runTest(UnconfinedTestDispatcher()) {
        auth.restored = AuthState.SignedIn(user)
        val coordinator = coordinator()
        coordinator.start()
        assertEquals(user, coordinator.state.value.signedInUser)
        assertFalse(coordinator.state.value.isEntryPresented)
        assertEquals(0, backend.entryCalls)
    }

    @Test
    fun signingInHidesTheEntry() = runTest(UnconfinedTestDispatcher()) {
        val coordinator = coordinator()
        coordinator.start()
        auth.signIn("a@b.c", "secret")
        assertEquals("a@b.c", coordinator.state.value.signedInUser?.email)
        assertFalse(coordinator.state.value.isEntryPresented)
    }

    @Test
    fun signingOutShowsTheEntryAgain() = runTest(UnconfinedTestDispatcher()) {
        auth.restored = AuthState.SignedIn(user)
        val coordinator = coordinator()
        coordinator.start()
        coordinator.signOut()
        assertTrue(coordinator.state.value.isEntryPresented)
        assertNull(coordinator.state.value.signedInUser)
        assertEquals(SignOutReason.UserRequest, coordinator.state.value.signOutReason)
        assertEquals("Sign in", coordinator.shownTitle())
    }

    @Test
    fun accessEndingShowsTheEntryWithTheSessionEndedReason() = runTest(UnconfinedTestDispatcher()) {
        auth.restored = AuthState.SignedIn(user)
        val coordinator = coordinator()
        coordinator.start()
        auth.endSession()
        assertTrue(coordinator.state.value.isEntryPresented)
        assertEquals(SignOutReason.SessionEnded, coordinator.state.value.signOutReason)
    }

    @Test
    fun returningToTheForegroundSignedInChecksTheSession() = runTest(UnconfinedTestDispatcher()) {
        auth.restored = AuthState.SignedIn(user)
        val coordinator = coordinator()
        coordinator.start()
        coordinator.movedToBackground()
        coordinator.movedToForeground()
        assertEquals(1, backend.whoamiCalls)
        assertEquals(0, backend.entryCalls)
    }

    @Test
    fun aFailedFetchShowsTheCachedEntry() = runTest(UnconfinedTestDispatcher()) {
        cache.save(StubBackendService.signIn("Cached"), "en")
        backend.entry = { throw BackendError.Network }
        val coordinator = coordinator()
        coordinator.start()
        assertEquals("Cached", coordinator.shownTitle())
    }

    @Test
    fun aFailedFetchWithNoCacheShowsTheError() = runTest(UnconfinedTestDispatcher()) {
        backend.entry = { throw BackendError.Network }
        val coordinator = coordinator()
        coordinator.start()
        assertEquals(EntryState.Error, coordinator.state.value.entry)
    }

    @Test
    fun anUnregisteredEntryShowsTheErrorEvenWithACache() = runTest(UnconfinedTestDispatcher()) {
        cache.save(StubBackendService.signIn("Cached"), "en")
        backend.entry = { ScreenEnvelope("future.entry", JsonObject(emptyMap())) }
        val coordinator = coordinator()
        coordinator.start()
        assertEquals(EntryState.Error, coordinator.state.value.entry)
    }

    @Test
    fun retryAfterTheErrorShowsTheEntry() = runTest(UnconfinedTestDispatcher()) {
        backend.entry = { throw BackendError.Network }
        val coordinator = coordinator()
        coordinator.start()
        backend.entry = { StubBackendService.signIn() }
        coordinator.retry()
        assertEquals("Sign in", coordinator.shownTitle())
    }

    @Test
    fun returningToTheForegroundSignedOutRefetchesTheEntry() = runTest(UnconfinedTestDispatcher()) {
        val coordinator = coordinator()
        coordinator.start()
        backend.entry = { StubBackendService.signIn("Welcome") }
        coordinator.movedToBackground()
        coordinator.movedToForeground()
        assertEquals("Welcome", coordinator.shownTitle())
    }

    @Test
    fun aForegroundWithoutABackgroundDoesNothing() = runTest(UnconfinedTestDispatcher()) {
        val coordinator = coordinator()
        coordinator.start()
        coordinator.movedToForeground()
        assertEquals(1, backend.entryCalls)
    }

    @Test
    fun aFailedForegroundRefetchKeepsTheScreenShowing() = runTest(UnconfinedTestDispatcher()) {
        val coordinator = coordinator()
        coordinator.start()
        backend.entry = { throw BackendError.Network }
        coordinator.movedToBackground()
        coordinator.movedToForeground()
        assertEquals("Sign in", coordinator.shownTitle())
    }
}
