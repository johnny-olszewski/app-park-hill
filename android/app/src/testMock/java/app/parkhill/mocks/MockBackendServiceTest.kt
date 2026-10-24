package app.parkhill.mocks

import app.parkhill.services.backend.BackendError
import app.parkhill.services.backend.ContractJson
import app.parkhill.services.backend.ScreenEnvelope
import app.parkhill.services.backend.TabsResponse
import java.io.File
import java.nio.file.Files
import kotlinx.coroutines.test.runTest
import org.junit.Assert.assertEquals
import org.junit.Assert.fail
import org.junit.Test

class MockBackendServiceTest {
    private val bundled = File(checkNotNull(javaClass.classLoader?.getResource("get_entry.json")).toURI()).parentFile!!

    private fun expected(name: String) = ContractJson.decodeFromString(ScreenEnvelope.serializer(), File(bundled, name).readText())

    @Test
    fun theEntryIsTheRecordedGetEntry() = runTest {
        val service = MockBackendService(MockResponseStore.directory(bundled), MockPersonaState())
        assertEquals(expected("get_entry.json"), service.getEntry("en"))
    }

    @Test
    fun getScreenReadsTheScreenMockResponse() = runTest {
        val service = MockBackendService(MockResponseStore.directory(bundled), MockPersonaState())
        assertEquals(expected("get_screen.auth.sign_in.json"), service.getScreen("auth.sign_in", "en"))
    }

    @Test
    fun getTabsReturnsTheSignedInPersonasTabs() = runTest {
        val persona = MockPersonaState()
        val service = MockBackendService(MockResponseStore.directory(bundled), persona)
        try {
            service.getTabs("en")
            fail("expected Unauthorized before signing in")
        } catch (error: BackendError) {
            assertEquals(BackendError.Unauthorized, error)
        }
        persona.current = "attendee"
        val expected = ContractJson.decodeFromString(TabsResponse.serializer(), File(bundled, "attendee/get_tabs.json").readText())
        assertEquals(expected, service.getTabs("en"))
    }

    @Test
    fun anUnknownScreenKeyThrowsUnknownScreen() = runTest {
        val service = MockBackendService(MockResponseStore.directory(bundled), MockPersonaState())
        try {
            service.getScreen("does.not_exist", "en")
            fail("expected UnknownScreen")
        } catch (error: BackendError) {
            assertEquals(BackendError.UnknownScreen, error)
        }
    }

    @Test
    fun aPersonasMockResponseWinsOverTheSharedOne() = runTest {
        val root = Files.createTempDirectory("mock_responses").toFile()
        File(root, "admin").mkdirs()
        File(root, "get_entry.json").writeText("""{"key": "shared", "data": {}}""")
        File(root, "admin/get_entry.json").writeText("""{"key": "admin", "data": {}}""")
        val persona = MockPersonaState()
        val service = MockBackendService(MockResponseStore.directory(root), persona)

        assertEquals("shared", service.getEntry("en").key)
        persona.current = "admin"
        assertEquals("admin", service.getEntry("en").key)
        persona.current = "attendee"
        assertEquals("shared", service.getEntry("en").key)
        root.deleteRecursively()
    }
}
