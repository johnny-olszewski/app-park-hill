package app.parkhill.screens.people

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import app.parkhill.contract.PersonRow
import app.parkhill.design.ParkHill
import app.parkhill.screens.community.initials

/**
 * One person: initials, name, an optional second line and the backend's
 * note, such as "Already a member", then `trailing` (the picker's checkbox).
 * A shared component: the people picker uses it, and the future directory
 * will. A person who cannot be chosen shows muted.
 */
@Composable
fun PersonRowView(person: PersonRow, modifier: Modifier = Modifier, trailing: @Composable () -> Unit = {}) {
    Row(
        modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 8.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(10.dp),
    ) {
        Box(Modifier.size(32.dp).background(ParkHill.colors.sky, CircleShape), contentAlignment = Alignment.Center) {
            Text(initials(person.title), color = ParkHill.colors.ink, fontSize = 11.sp, fontWeight = FontWeight.SemiBold)
        }
        Column(Modifier.weight(1f)) {
            Text(
                person.title,
                color = if (person.selectable) ParkHill.colors.ink else ParkHill.colors.inkMuted,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
            )
            person.subtitle?.let { subtitle ->
                Text(subtitle, color = ParkHill.colors.inkMuted, fontSize = 12.sp, maxLines = 1, overflow = TextOverflow.Ellipsis)
            }
        }
        person.note?.let { note ->
            Text(note, color = ParkHill.colors.inkMuted, fontSize = 12.sp, modifier = Modifier.testTag("personRow.note"))
        }
        trailing()
    }
}
