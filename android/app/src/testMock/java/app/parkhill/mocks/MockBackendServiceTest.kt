package app.parkhill.mocks

import app.parkhill.contract.ScreenEnvelope
import app.parkhill.contract.TabsResponse
import app.parkhill.services.backend.BackendError
import app.parkhill.services.backend.ContractJson
import java.io.File
import java.nio.file.Files
import kotlinx.coroutines.test.runTest
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
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
    fun getScreenWithParamsReadsTheMockResponseForThoseParams() = runTest {
        val persona = MockPersonaState().apply { current = "member_two" }
        val service = MockBackendService(MockResponseStore.directory(bundled), persona)
        val groupId = "d44d5b87-37ce-5db5-9e33-43f477b42f1e"
        val params = JsonObject(mapOf("group_id" to JsonPrimitive(groupId)))
        assertEquals(expected("member_two/get_screen.community.group@group_id=$groupId.json"), service.getScreen("community.group", "en", params))
    }

    @Test
    fun getScreenWithParamsFallsBackToTheScreenAlone() = runTest {
        val service = MockBackendService(MockResponseStore.directory(bundled), MockPersonaState())
        val params = JsonObject(mapOf("unused" to JsonPrimitive("x")))
        assertEquals(expected("get_screen.auth.sign_in.json"), service.getScreen("auth.sign_in", "en", params))
    }

    @Test
    fun mockResponseNamesSortParamsByName() {
        assertEquals("get_screen.a", MockResponseStore.name("get_screen.a", JsonObject(emptyMap())))
        val params = JsonObject(mapOf("z" to JsonPrimitive(2), "b" to JsonPrimitive("x")))
        assertEquals("get_screen.a@b=x&z=2", MockResponseStore.name("get_screen.a", params))
        assertEquals("get_screen.a", MockResponseStore.name("get_screen.a", JsonObject(mapOf("b" to JsonPrimitive(true)))))
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
