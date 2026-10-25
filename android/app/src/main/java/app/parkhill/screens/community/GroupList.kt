package app.parkhill.screens.community

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyListScope
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowRight
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import app.parkhill.contract.GroupList
import app.parkhill.contract.GroupRow
import app.parkhill.contract.GroupRowBadgeTone
import app.parkhill.design.ParkHill
import app.parkhill.navigation.LocalScreenActions

/**
 * A titled list of groups: one row per GroupRow, performing its action when
 * tapped. A client component shared by every screen that lists groups.
 */
@Composable
fun GroupListView(list: GroupList) {
    GroupRows(list.rows) {
        item {
            Text(
                list.title.uppercase(),
                style = ParkHill.label,
                color = ParkHill.colors.ink,
                modifier = Modifier.padding(start = 16.dp, top = 8.dp, bottom = 6.dp).testTag("groupList.title"),
            )
        }
    }
}

/** Group rows with dividers in a scrolling list, after `header`. */
@Composable
fun GroupRows(rows: List<GroupRow>, modifier: Modifier = Modifier, header: LazyListScope.() -> Unit = {}) {
    LazyColumn(modifier.fillMaxSize().background(ParkHill.colors.surface).testTag("groupList")) {
        header()
        items(rows, key = { it.groupId }) { row ->
            GroupRowView(row)
            HorizontalDivider(color = ParkHill.colors.line, modifier = Modifier.padding(start = 16.dp))
        }
    }
}

/** One group: title, subtitle and optional badge, in the danger color when it needs attention. Tappable only when this build knows its action. */
@Composable
fun GroupRowView(row: GroupRow) {
    val actions = LocalScreenActions.current
    val tappable = actions.canPerform(row.action)
    Row(
        Modifier
            .fillMaxWidth()
            .then(if (tappable) Modifier.clickable(role = Role.Button) { actions.perform(row.action) }.testTag("groupRow") else Modifier)
            .padding(horizontal = 16.dp, vertical = 10.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(10.dp),
    ) {
        Column(Modifier.weight(1f)) {
            Text(row.title, color = ParkHill.colors.ink, maxLines = 1, overflow = TextOverflow.Ellipsis)
            Text(row.subtitle, color = ParkHill.colors.inkMuted, fontSize = 12.sp, maxLines = 1, overflow = TextOverflow.Ellipsis)
        }
        row.badge?.let { badge ->
            val attention = row.badgeTone == GroupRowBadgeTone.ATTENTION
            Badge(badge, Modifier.testTag(if (attention) "groupRow.badge.attention" else "groupRow.badge"), attention = attention)
        }
        if (tappable) {
            Icon(Icons.AutoMirrored.Filled.KeyboardArrowRight, contentDescription = null, tint = ParkHill.colors.inkMuted)
        }
    }
}
