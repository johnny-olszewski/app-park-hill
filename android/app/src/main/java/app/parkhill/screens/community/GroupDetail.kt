package app.parkhill.screens.community

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Star
import androidx.compose.material.icons.outlined.DateRange
import androidx.compose.material.icons.outlined.LocationOn
import androidx.compose.material.icons.outlined.Person
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.heading
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import app.parkhill.R
import app.parkhill.contract.GroupDetail
import app.parkhill.contract.MemberRow
import app.parkhill.design.ParkHill

/**
 * A group's details and members, read-only (specs/COMMUNITY.md 5.1). A client
 * component shared by `community.group` and Community home's one group;
 * every word comes from the data.
 */
@Composable
fun GroupDetailView(detail: GroupDetail) {
    LazyColumn(
        Modifier.fillMaxSize().background(ParkHill.colors.surface).testTag("groupDetail"),
        verticalArrangement = Arrangement.spacedBy(0.dp),
    ) {
        item {
            Column(Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 12.dp), verticalArrangement = Arrangement.spacedBy(4.dp)) {
                Text(
                    detail.title,
                    style = ParkHill.heading.copy(fontSize = 24.sp),
                    color = ParkHill.colors.ink,
                    modifier = Modifier.semantics { heading() }.testTag("groupDetail.title"),
                )
                if (detail.description.isNotEmpty()) {
                    Text(detail.description, color = ParkHill.colors.inkMuted, modifier = Modifier.testTag("groupDetail.description"))
                }
            }
        }
        if (detail.meeting.isNotEmpty()) item { DetailLine(detail.meeting, Icons.Outlined.DateRange, "groupDetail.meeting") }
        if (detail.location.isNotEmpty()) item { DetailLine(detail.location, Icons.Outlined.LocationOn, "groupDetail.location") }
        item { DetailLine(detail.leadersLine, Icons.Outlined.Person, "groupDetail.leadersLine") }
        item {
            Text(
                detail.membersTitle.uppercase(),
                style = ParkHill.label,
                color = ParkHill.colors.ink,
                modifier = Modifier.padding(start = 16.dp, top = 24.dp, bottom = 6.dp).testTag("groupDetail.membersTitle"),
            )
        }
        items(detail.members, key = { it.userId }) { member ->
            MemberRowView(member)
            HorizontalDivider(color = ParkHill.colors.line, modifier = Modifier.padding(start = 58.dp))
        }
    }
}

/** One backend-formatted line of the details, with an icon for scanning. */
@Composable
private fun DetailLine(text: String, icon: ImageVector, tag: String) {
    Row(
        Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 8.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Icon(icon, contentDescription = null, tint = ParkHill.colors.inkMuted, modifier = Modifier.size(20.dp))
        Spacer(Modifier.width(12.dp))
        Text(text, color = ParkHill.colors.ink, modifier = Modifier.testTag(tag))
    }
}

/** A member: initials, name, the leader icon and the note (such as "You"). */
@Composable
fun MemberRowView(member: MemberRow) {
    Row(
        Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 8.dp).testTag("groupDetail.member"),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Box(Modifier.size(32.dp).background(ParkHill.colors.sky, CircleShape), contentAlignment = Alignment.Center) {
            Text(initials(member.title), color = ParkHill.colors.ink, fontSize = 11.sp, fontWeight = FontWeight.SemiBold)
        }
        Spacer(Modifier.width(10.dp))
        Text(member.title, color = ParkHill.colors.ink, maxLines = 1, overflow = TextOverflow.Ellipsis, modifier = Modifier.weight(1f))
        if (member.isLeader) {
            Icon(
                Icons.Filled.Star,
                contentDescription = stringResource(R.string.group_leader_icon),
                tint = ParkHill.colors.ink,
                modifier = Modifier.padding(start = 8.dp).size(18.dp).testTag("groupDetail.leaderIcon"),
            )
        }
        member.note?.let { note ->
            Badge(note, Modifier.padding(start = 8.dp).testTag("groupDetail.note"))
        }
    }
}

/**
 * A small uppercase label on the brand's sky color, such as "You" or
 * "Leader"; one that needs attention, such as "No leader", on the danger color.
 */
@Composable
fun Badge(text: String, modifier: Modifier = Modifier, attention: Boolean = false) {
    Text(
        text.uppercase(),
        style = ParkHill.label.copy(fontSize = 10.sp),
        color = if (attention) ParkHill.colors.surface else ParkHill.colors.ink,
        modifier = modifier
            .background(if (attention) ParkHill.colors.danger else ParkHill.colors.sky, RoundedCornerShape(4.dp))
            .padding(horizontal = 6.dp, vertical = 1.dp),
    )
}

/** Up to two initials from the display name, for the avatar. */
internal fun initials(name: String): String =
    name.split(" ").filter { it.isNotEmpty() }.take(2).joinToString("") { it.first().uppercase() }
