package app.parkhill.screens.community

import app.parkhill.contract.CommunityBrowseData
import app.parkhill.contract.GroupRowBadgeTone
import app.parkhill.contract.ScreenEnvelope
import app.parkhill.navigation.ScreenRegistry
import app.parkhill.navigation.registerSharedScreens
import app.parkhill.services.auth.FakeAuthService
import app.parkhill.services.backend.ContractJson
import java.io.File
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Test

/** Browse all groups: the recorded screen and search by title (AND-026 AC4). */
class CommunityBrowseTest {
    private val root = File(checkNotNull(javaClass.classLoader?.getResource("get_entry.json")).toURI()).parentFile!!

    private fun recorded(persona: String): ScreenEnvelope =
        ContractJson.decodeFromString(ScreenEnvelope.serializer(), File(root, "$persona/get_screen.community.browse.json").readText())

    private val rows = ContractJson.decodeFromJsonElement(CommunityBrowseData.serializer(), recorded("staff").data).rows

    private fun titles(query: String) = filterGroupRows(rows, query).map { it.title }

    @Test
    fun staffAndAdminsRecordedBrowseResolvesWithItsTitle() {
        val registry = ScreenRegistry().apply { registerSharedScreens(FakeAuthService()) }
        for (persona in listOf("staff", "admin")) {
            val screen = registry.resolve(recorded(persona))
            assertNotNull(persona, screen)
            assertEquals("All groups", screen!!.title)
        }
    }

    @Test
    fun theLeaderlessGroupNeedsAttention() {
        val pointLoma = rows.single { it.title == "Point Loma Group" }
        assertEquals("No leader", pointLoma.badge)
        assertEquals(GroupRowBadgeTone.ATTENTION, pointLoma.badgeTone)
    }

    @Test
    fun aBlankQueryShowsEveryRowInOrder() {
        assertEquals(rows.map { it.title }, titles(""))
        assertEquals(rows.map { it.title }, titles("   "))
    }

    @Test
    fun filtersByTitleIgnoringCaseAndSurroundingSpaces() {
        assertEquals(rows.map { it.title }.filter { it.contains("group", ignoreCase = true) }, titles("GROUP"))
        assertEquals(listOf("Mission Hills Group"), titles(" hill "))
        assertEquals(listOf("Point Loma Group"), titles(" LOMA "))
        assertEquals(listOf("Young Families"), titles("fam"))
    }

    @Test
    fun matchesTheTitleOnly() {
        assertTrue(titles("Vesper").isEmpty())
        assertTrue(titles("zzz").isEmpty())
    }
}
