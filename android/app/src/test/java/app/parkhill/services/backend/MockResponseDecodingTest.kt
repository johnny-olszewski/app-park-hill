package app.parkhill.services.backend

import app.parkhill.contract.CommunityGroupData
import app.parkhill.contract.Profile
import app.parkhill.contract.ScreenEnvelope
import app.parkhill.contract.SignInFailure
import app.parkhill.contract.SignInSuccess
import app.parkhill.contract.TabsResponse
import java.io.File
import kotlinx.serialization.KSerializer
import kotlinx.serialization.builtins.MapSerializer
import kotlinx.serialization.builtins.serializer
import kotlinx.serialization.json.JsonPrimitive
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

/** Android agrees with the contract: every recorded screen response decodes (guide 4.1 rule 6). */
class MockResponseDecodingTest {
    private val root = File(checkNotNull(javaClass.classLoader?.getResource("get_entry.json")).toURI()).parentFile!!

    /** contract/responses.json: each mock response's name (file name without folder, `@` params or `.json`) to its type. */
    private val responseTypes: Map<String, String> = ContractJson.decodeFromString(
        MapSerializer(String.serializer(), String.serializer()),
        File(checkNotNull(System.getProperty("contract.responses"))).readText(),
    )

    /** Every type contract/responses.json names, by name. */
    private val serializers: Map<String, KSerializer<*>> = mapOf(
        "ScreenEnvelope" to ScreenEnvelope.serializer(),
        "TabsResponse" to TabsResponse.serializer(),
        "Profile" to Profile.serializer(),
        "SignInSuccess" to SignInSuccess.serializer(),
        "SignInFailure" to SignInFailure.serializer(),
    )

    @Test
    fun everyMockResponseDecodesWithItsTypeFromResponsesJson() {
        val files = root.walkTopDown().filter { it.isFile && it.extension == "json" && it.name != "dataset.json" }.toList()
        assertTrue("no mock responses found", files.isNotEmpty())
        for (file in files) {
            val name = file.nameWithoutExtension.substringBefore('@')
            val type = checkNotNull(responseTypes[name]) { "${file.name} has no type in contract/responses.json" }
            val serializer = checkNotNull(serializers[type]) { "$type has no serializer in this test" }
            ContractJson.decodeFromString(serializer, file.readText())
        }
    }

    @Test
    fun everyScreenMockResponseDecodes() {
        val screens = root.walkTopDown()
            .filter { it.isFile && (it.name == "get_entry.json" || it.name.startsWith("get_screen.")) }
            .toList()
        assertTrue("no screen mock responses found", screens.isNotEmpty())
        for (file in screens) {
            val envelope = ContractJson.decodeFromString(ScreenEnvelope.serializer(), file.readText())
            assertTrue("${file.name} has no key", envelope.key.isNotEmpty())
        }
    }

    @Test
    fun everyTabsMockResponseDecodes() {
        val files = root.walkTopDown().filter { it.isFile && it.name == "get_tabs.json" }.toList()
        assertTrue("no tabs mock responses found", files.isNotEmpty())
        for (file in files) {
            val response = ContractJson.decodeFromString(TabsResponse.serializer(), file.readText())
            assertTrue("${file.path} has no tabs", response.tabs.isNotEmpty())
            assertTrue(response.tabs.all { it.title.isNotEmpty() && it.iconKey.isNotEmpty() })
        }
    }

    @Test
    fun everyGroupDetailMockResponseDecodes() {
        val files = root.walkTopDown().filter { it.isFile && it.name.startsWith("get_screen.community.group@") }.toList()
        assertTrue("no community.group mock responses found", files.isNotEmpty())
        for (file in files) {
            val envelope = ContractJson.decodeFromString(ScreenEnvelope.serializer(), file.readText())
            val detail = ContractJson.decodeFromJsonElement(CommunityGroupData.serializer(), envelope.data)
            assertTrue(file.name, detail.title.isNotEmpty() && detail.leadersLine.isNotEmpty())
        }
    }

    @Test
    fun theEntryIsSignIn() {
        val envelope = ContractJson.decodeFromString(ScreenEnvelope.serializer(), File(root, "get_entry.json").readText())
        assertEquals("auth.sign_in", envelope.key)
        assertEquals(JsonPrimitive("Sign in"), envelope.data["title"])
    }

    @Test
    fun unknownFieldsAreIgnored() {
        val json = """{"key": "auth.sign_in", "data": {"title": "Sign in"}, "future_field": {"x": 1}}"""
        assertEquals("auth.sign_in", ContractJson.decodeFromString(ScreenEnvelope.serializer(), json).key)
    }
}
