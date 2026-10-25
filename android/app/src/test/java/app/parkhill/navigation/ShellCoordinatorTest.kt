package app.parkhill.navigation

import app.parkhill.cache.ScreenCache
import app.parkhill.cache.TabsCache
import app.parkhill.contract.ScreenEnvelope
import app.parkhill.contract.TabsResponse
import app.parkhill.services.auth.FakeAuthService
import app.parkhill.services.backend.BackendError
import java.nio.file.Files
import kotlinx.coroutines.test.runTest
import kotlinx.serialization.json.JsonObject
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertSame
import org.junit.Assert.assertTrue
import org.junit.Test

/** The signed-in shell: tabs from get_tabs, dropping, cache and selection (AND-008 AC1, AC4 to AC6, AC11, AC12). */
class ShellCoordinatorTest {
    private val cache = TabsCache(Files.createTempDirectory("tabs").toFile())
    private val homeAndCommunity = StubBackendService.tabs("home" to "home.root", "community" to "community.home")

    private fun shell(vararg results: () -> TabsResponse): Pair<ShellCoordinator, StubBackendService> {
        val queue = ArrayDeque(results.toList())
        val backend = StubBackendService { StubBackendService.signIn() }
        backend.tabs = { (if (queue.size > 1) queue.removeFirst() else queue.first())() }
        val registry = ScreenRegistry().apply { registerSharedScreens(FakeAuthService()) }
        return ShellCoordinator(backend, registry, cache, ScreenCache(Files.createTempDirectory("screens").toFile())) { "en" } to backend
    }

    private fun empty(key: String) = ScreenEnvelope(key, JsonObject(emptyMap()))

    @Test
    fun showsTheTabsInBackendOrderAndSelectsTheFirst() = runTest {
        val (shell) = shell({ StubBackendService.tabs("community" to "community.home", "home" to "home.root") })
        shell.load()
        assertEquals(ShellState.Tabs, shell.state)
        assertEquals(listOf("community", "home"), shell.tabs.map { it.id })
        assertEquals(listOf("Community", "Home"), shell.tabs.map { it.title })
        assertEquals("community", shell.selectedTabId)
    }

    @Test
    fun aTabWithAnUnregisteredScreenIsDropped() = runTest {
        val (shell) = shell({ StubBackendService.tabs("future" to "future.root", "home" to "home.root") })
        shell.load()
        assertEquals(listOf("home"), shell.tabs.map { it.id })
    }

    @Test
    fun noShowableTabShowsTheErrorEvenWithACache() = runTest {
        cache.save(homeAndCommunity, "en")
        val (shell) = shell({ StubBackendService.tabs("future" to "future.root") })
        shell.load()
        assertEquals(ShellState.Error, shell.state)
    }

    @Test
    fun atMostFiveTabsAreShown() = runTest {
        val six = StubBackendService.tabs(*listOf("a", "b", "c", "d", "e", "f").map { it to "home.root" }.toTypedArray())
        val (shell) = shell({ six })
        shell.load()
        assertEquals(listOf("a", "b", "c", "d", "e"), shell.tabs.map { it.id })
    }

    @Test
    fun aFailureShowsTheCachedTabs() = runTest {
        val (online) = shell({ homeAndCommunity })
        online.load()
        assertEquals(homeAndCommunity, cache.load("en"))

        val (offline) = shell({ throw BackendError.Network })
        offline.load()
        assertEquals(ShellState.Tabs, offline.state)
        assertEquals(listOf("home", "community"), offline.tabs.map { it.id })
    }

    @Test
    fun aFailureWithoutACacheShowsTheErrorAndRetryRecovers() = runTest {
        val (shell) = shell({ throw BackendError.Network }, { homeAndCommunity })
        shell.load()
        assertEquals(ShellState.Error, shell.state)
        shell.retry()
        assertEquals(ShellState.Tabs, shell.state)
    }

    @Test
    fun refreshKeepsTheSelectedTabAndEachTabsStack() = runTest {
        val (shell) = shell({ homeAndCommunity })
        shell.load()
        shell.selectedTabId = "community"
        val community = shell.tabs.last()
        assertTrue(community.push(empty("home.root")))

        shell.load()

        assertEquals("community", shell.selectedTabId)
        assertSame(community, shell.tabs.last())
        assertEquals(1, community.path.size)
    }

    @Test
    fun aFailedRefreshKeepsTheTabsShowing() = runTest {
        val (shell) = shell({ homeAndCommunity }, { throw BackendError.Network })
        shell.load()
        shell.load()
        assertEquals(ShellState.Tabs, shell.state)
    }

    @Test
    fun aRemovedSelectedTabSelectsTheFirst() = runTest {
        val (shell) = shell({ homeAndCommunity }, { StubBackendService.tabs("home" to "home.root") })
        shell.load()
        shell.selectedTabId = "community"
        shell.load()
        assertEquals("home", shell.selectedTabId)
    }

    @Test
    fun eachTabKeepsItsOwnStackWhenSwitching() = runTest {
        val (shell) = shell({ homeAndCommunity })
        shell.load()
        val home = shell.tabs.first()
        val community = shell.tabs.last()

        assertTrue(home.push(empty("home.root")))
        shell.selectedTabId = "community"
        shell.selectedTabId = "home"

        assertEquals(1, home.path.size)
        assertTrue(community.path.isEmpty())
        assertTrue(home.pop())
        assertFalse(home.pop())
    }

    @Test
    fun pushAndPresentRefuseScreensThisBuildCannotShow() = runTest {
        val (shell) = shell({ homeAndCommunity })
        shell.load()
        val home = shell.tabs.first()
        assertFalse(home.push(empty("future.screen")))
        assertFalse(home.present(empty("future.screen")))
        assertTrue(home.present(empty("home.root")))
        home.dismiss()
        assertNull(home.presented)
    }
}
