package app.parkhill.navigation

import app.parkhill.contract.NavigateAction
import app.parkhill.contract.NavigateActionPresentation
import app.parkhill.contract.NavigateActionType
import app.parkhill.contract.ToolbarItem
import kotlinx.serialization.json.JsonObject
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

/** Toolbar items in backend order, extras in the overflow menu (AND-026 AC1). */
class ToolbarLayoutTest {
    private fun items(count: Int) = (1..count).map { index ->
        ToolbarItem(
            "item$index",
            "Item $index",
            "toolbar.item$index",
            NavigateAction(NavigateActionType.NAVIGATE, "test.screen", JsonObject(emptyMap()), NavigateActionPresentation.PUSH),
        )
    }

    private fun ids(items: List<ToolbarItem>) = items.map { it.id }

    @Test
    fun noItemsShowNothing() {
        val layout = ToolbarLayout.of(emptyList())
        assertTrue(layout.bar.isEmpty())
        assertTrue(layout.overflow.isEmpty())
    }

    @Test
    fun itemsThatFitAreAllIconsInOrder() {
        val layout = ToolbarLayout.of(items(ToolbarLayout.SLOTS))
        assertEquals(listOf("item1", "item2", "item3"), ids(layout.bar))
        assertTrue(layout.overflow.isEmpty())
    }

    @Test
    fun extrasGoToTheOverflowMenuInOrder() {
        val layout = ToolbarLayout.of(items(5))
        assertEquals(listOf("item1", "item2"), ids(layout.bar))
        assertEquals(listOf("item3", "item4", "item5"), ids(layout.overflow))
        assertEquals(ToolbarLayout.SLOTS, layout.bar.size + 1)
    }
}
