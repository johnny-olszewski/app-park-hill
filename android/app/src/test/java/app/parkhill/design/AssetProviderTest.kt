package app.parkhill.design

import app.parkhill.R
import app.parkhill.contract.ScreenEnvelope
import app.parkhill.contract.TabsResponse
import app.parkhill.services.backend.ContractJson
import java.io.File
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

/** Tab and toolbar icon keys resolve to bundled drawables, with a fallback (AND-008 AC7, AND-026 AC1). */
class AssetProviderTest {
    @Test
    fun everyRecordedTabIconIsBundled() {
        val root = File(checkNotNull(javaClass.classLoader?.getResource("get_entry.json")).toURI()).parentFile!!
        root.walkTopDown().filter { it.isFile && it.name == "get_tabs.json" }.forEach { file ->
            ContractJson.decodeFromString(TabsResponse.serializer(), file.readText()).tabs.forEach { tab ->
                assertTrue("${file.path}: ${tab.iconKey}", AssetProvider.hasTabIcon(tab.iconKey))
            }
        }
    }

    @Test
    fun anUnknownKeyGetsTheFallback() {
        assertFalse(AssetProvider.hasTabIcon("tab.future"))
        assertEquals(R.drawable.ic_tab_fallback, AssetProvider.tabIcon("tab.future"))
    }

    @Test
    fun everyRecordedToolbarIconIsBundled() {
        val root = File(checkNotNull(javaClass.classLoader?.getResource("get_entry.json")).toURI()).parentFile!!
        val envelopes = root.walkTopDown().filter { it.isFile }.flatMap { file ->
            when {
                file.name == "get_tabs.json" -> ContractJson.decodeFromString(TabsResponse.serializer(), file.readText()).tabs.map { file to it.screen }
                file.name.startsWith("get_screen.") -> listOf(file to ContractJson.decodeFromString(ScreenEnvelope.serializer(), file.readText()))
                else -> emptyList()
            }
        }.toList()
        val items = envelopes.flatMap { (file, envelope) -> envelope.toolbar.orEmpty().map { file to it } }
        assertTrue(items.isNotEmpty())
        items.forEach { (file, item) -> assertTrue("${file.path}: ${item.iconKey}", AssetProvider.hasToolbarIcon(item.iconKey)) }
    }

    @Test
    fun anUnknownToolbarKeyGetsTheFallback() {
        assertFalse(AssetProvider.hasToolbarIcon("toolbar.future"))
        assertEquals(R.drawable.ic_toolbar_fallback, AssetProvider.toolbarIcon("toolbar.future"))
    }
}
