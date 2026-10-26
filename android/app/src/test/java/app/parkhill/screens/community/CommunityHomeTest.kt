package app.parkhill.screens.community

import app.parkhill.cache.ScreenCache
import app.parkhill.cache.TabsCache
import app.parkhill.contract.CommunityHomeData
import app.parkhill.contract.EmptyState
import app.parkhill.contract.GroupDetail
import app.parkhill.contract.GroupList
import app.parkhill.contract.ScreenEnvelope
import app.parkhill.navigation.ScreenContext
import app.parkhill.navigation.ScreenModel
import app.parkhill.navigation.ScreenRegistry
import app.parkhill.navigation.ScreenState
import app.parkhill.navigation.ShellCoordinator
import app.parkhill.navigation.StubBackendService
import app.parkhill.navigation.eagerScope
import app.parkhill.navigation.registerSharedScreens
import app.parkhill.services.auth.FakeAuthService
import app.parkhill.services.backend.ContractJson
import java.io.File
import java.nio.file.Files
import kotlinx.coroutines.test.runTest
import kotlinx.serialization.json.JsonObject
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertSame
import org.junit.Assert.assertTrue
import org.junit.Test

/** Community home's state inference and unusable data (AND-010 AC2, AC6). */
class CommunityHomeTest {
    private val empty = EmptyState("None yet", "Ask staff.")
    private val list = GroupList("My groups", emptyList())
    private val group = GroupDetail("g", "Group", "", "", "", "Leaders: none yet", "Members", emptyList())
    private val root = File(checkNotNull(javaClass.classLoader?.getResource("get_entry.json")).toURI()).parentFile!!

    @Test
    fun groupWinsOverMyGroupsAndEmpty() {
        assertEquals(CommunityHomeState.Group(group), CommunityHomeState.of(CommunityHomeData(group, list, empty)))
    }

    @Test
    fun myGroupsWinsOverEmpty() {
        assertEquals(CommunityHomeState.MyGroups(list), CommunityHomeState.of(CommunityHomeData(null, list, empty)))
    }

    @Test
    fun emptyAlone() {
        assertEquals(CommunityHomeState.Empty(empty), CommunityHomeState.of(CommunityHomeData(null, null, empty)))
    }

    @Test
    fun nonePresentIsUnusable() {
        assertNull(CommunityHomeState.of(CommunityHomeData(null, null, null)))
    }

    private fun recordedHome(persona: String): ScreenEnvelope =
        ContractJson.decodeFromString(ScreenEnvelope.serializer(), File(root, "$persona/get_screen.community.home.json").readText())

    @Test
    fun everyPersonasRecordedHomeHasItsState() {
        val expected = mapOf(
            "attendee" to CommunityHomeState.Empty::class, "staff" to CommunityHomeState.Empty::class,
            "member_one" to CommunityHomeState.Group::class, "leader" to CommunityHomeState.Group::class,
            "admin" to CommunityHomeState.Group::class, "member_two" to CommunityHomeState.MyGroups::class,
        )
        for ((persona, kind) in expected) {
            val data = ContractJson.decodeFromJsonElement(CommunityHomeData.serializer(), recordedHome(persona).data)
            assertEquals(persona, kind, CommunityHomeState.of(data)?.let { it::class })
        }
    }

    private val registry = ScreenRegistry().apply { registerSharedScreens(FakeAuthService()) }
    private val unusable = ScreenEnvelope("community.home", JsonObject(emptyMap()))

    @Test
    fun unusableHomeDoesNotResolve() {
        assertNull(registry.resolve(unusable))
    }

    @Test
    fun unusableHomeShowsTheCachedCopyElseTheError() = runTest {
        val backend = StubBackendService { unusable }
        val context = ScreenContext(backend, registry, ScreenCache(Files.createTempDirectory("screens").toFile())) { "en" }

        assertSame(ScreenState.Error, ScreenModel.showing(unusable, context).state)

        val good = recordedHome("attendee")
        ScreenModel.showing(good, context)
        val withCache = ScreenModel.toFetch("community.home", JsonObject(emptyMap()), context)
        withCache.load()
        assertEquals(good, withCache.envelope)
    }

    @Test
    fun aTabWhoseRootCannotBeShownStaysAsATab() = runTest {
        val backend = StubBackendService { unusable }
        backend.tabs = { StubBackendService.tabs("home" to "home.root", "community" to "community.home") }
        val shell = ShellCoordinator(
            backend, registry, TabsCache(Files.createTempDirectory("tabs").toFile()),
            ScreenCache(Files.createTempDirectory("screens").toFile()), eagerScope(),
        ) { "en" }
        shell.load()
        assertEquals(listOf("home", "community"), shell.tabs.map { it.id })
        assertTrue(shell.tabs.last().root.state is ScreenState.Error)
    }
}
