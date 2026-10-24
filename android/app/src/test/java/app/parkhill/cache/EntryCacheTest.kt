package app.parkhill.cache

import app.parkhill.contract.ScreenEnvelope
import app.parkhill.contract.TabItem
import app.parkhill.contract.TabsResponse
import app.parkhill.navigation.StubBackendService
import java.nio.file.Files
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class EntryCacheTest {
    private val directory = Files.createTempDirectory("entry").toFile()

    @Test
    fun savesAndLoadsPerLocale() {
        val cache = EntryCache(directory)
        cache.save(StubBackendService.signIn("Sign in"), "en")
        cache.save(StubBackendService.signIn("Iniciar sesión"), "es")
        assertEquals(StubBackendService.signIn("Sign in"), cache.load("en"))
        assertEquals(StubBackendService.signIn("Iniciar sesión"), cache.load("es"))
        assertNull(cache.load("fr"))
    }

    @Test
    fun aLocaleCannotEscapeTheDirectory() {
        val cache = EntryCache(directory)
        cache.save(StubBackendService.signIn(), "../../evil")
        assertEquals(listOf("evil.json"), directory.list()?.toList())
    }

    @Test
    fun anEnvelopeCachedByTheHandWrittenModelStillLoads() {
        directory.resolve("en.json").writeText("""{"key":"auth.sign_in","data":{"title":"Sign in"}}""")
        val expected = ScreenEnvelope("auth.sign_in", JsonObject(mapOf("title" to JsonPrimitive("Sign in"))))
        assertEquals(expected, EntryCache(directory).load("en"))
    }

    @Test
    fun anUnreadableFileIsAMiss() {
        directory.resolve("en.json").writeText("not json")
        assertNull(EntryCache(directory).load("en"))
    }
}

class TabsCacheTest {
    @Test
    fun savesAndLoadsTabsPerLocale() {
        val cache = TabsCache(Files.createTempDirectory("tabs").toFile())
        val tabs = StubBackendService.tabs("home" to "home.root", "community" to "community.home")
        cache.save(tabs, "en")
        assertEquals(tabs, cache.load("en"))
        assertNull(cache.load("es"))
    }

    @Test
    fun tabsCachedByTheHandWrittenModelStillLoad() {
        val directory = Files.createTempDirectory("tabs").toFile()
        val cached = """{"tabs":[{"id":"home","title":"Home","icon_key":"tab.home","screen":{"key":"home.root","data":{}}}]}"""
        directory.resolve("en.json").writeText(cached)
        val tab = TabItem("home", "Home", "tab.home", ScreenEnvelope("home.root", JsonObject(emptyMap())))
        assertEquals(TabsResponse(listOf(tab)), TabsCache(directory).load("en"))
    }

    @Test
    fun theStandardCacheLivesUnderTheDeletableCacheDirectory() {
        val filesDir = Files.createTempDirectory("files").toFile()
        val tabs = StubBackendService.tabs("home" to "home.root")
        TabsCache.standard(filesDir).save(tabs, "en")
        assertEquals(tabs, TabsCache(java.io.File(EntryCache.cacheDirectory(filesDir), "tabs")).load("en"))
    }
}
