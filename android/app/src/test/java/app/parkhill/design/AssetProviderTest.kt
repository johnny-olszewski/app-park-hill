package app.parkhill.design

import app.parkhill.R
import app.parkhill.contract.TabsResponse
import app.parkhill.services.backend.ContractJson
import java.io.File
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

/** Tab icon keys resolve to bundled drawables, with a fallback (AND-008 AC7). */
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
}
