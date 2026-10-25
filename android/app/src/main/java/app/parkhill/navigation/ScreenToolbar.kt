package app.parkhill.navigation

import androidx.compose.foundation.layout.Box
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.MoreVert
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.res.stringResource
import app.parkhill.R
import app.parkhill.contract.ToolbarItem
import app.parkhill.design.AssetProvider

/** Where a screen's toolbar items go in a Material top app bar: its action icons, then its overflow menu. */
data class ToolbarLayout(val bar: List<ToolbarItem>, val overflow: List<ToolbarItem>) {
    companion object {
        /** Action icons a top app bar shows, the overflow button included (Material: at most three). */
        const val SLOTS = 3

        /** Items in backend order: all of them as icons when they fit, else the first ones and the rest in the overflow menu, in order. */
        fun of(items: List<ToolbarItem>, slots: Int = SLOTS): ToolbarLayout =
            if (items.size <= slots) ToolbarLayout(items, emptyList()) else ToolbarLayout(items.take(slots - 1), items.drop(slots - 1))
    }
}

/**
 * A screen envelope's toolbar as top app bar actions (guide 5.5): each item
 * an icon from [AssetProvider] with the backend's label as its content
 * description, extras in the overflow menu. Tapping performs the item's
 * action through [LocalScreenActions]; an action this build does not know is
 * disabled. No items, no actions.
 */
@Composable
fun ToolbarActions(items: List<ToolbarItem>?) {
    val actions = LocalScreenActions.current
    val layout = ToolbarLayout.of(items.orEmpty())
    layout.bar.forEach { item ->
        IconButton(
            onClick = { actions.perform(item.action) },
            enabled = actions.canPerform(item.action),
            modifier = Modifier.testTag("toolbar.${item.id}"),
        ) {
            Icon(painterResource(AssetProvider.toolbarIcon(item.iconKey)), contentDescription = item.label)
        }
    }
    if (layout.overflow.isEmpty()) return
    var open by remember { mutableStateOf(false) }
    Box {
        IconButton(onClick = { open = true }, modifier = Modifier.testTag("toolbar.overflow")) {
            Icon(Icons.Filled.MoreVert, contentDescription = stringResource(R.string.toolbar_more))
        }
        DropdownMenu(expanded = open, onDismissRequest = { open = false }) {
            layout.overflow.forEach { item ->
                DropdownMenuItem(
                    text = { Text(item.label) },
                    leadingIcon = { Icon(painterResource(AssetProvider.toolbarIcon(item.iconKey)), contentDescription = null) },
                    onClick = {
                        open = false
                        actions.perform(item.action)
                    },
                    enabled = actions.canPerform(item.action),
                    modifier = Modifier.testTag("toolbar.${item.id}"),
                )
            }
        }
    }
}
