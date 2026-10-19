package app.parkhill.cache

import app.parkhill.navigation.StubBackendService
import java.nio.file.Files
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
    fun anUnreadableFileIsAMiss() {
        directory.resolve("en.json").writeText("not json")
        assertNull(EntryCache(directory).load("en"))
    }
}
