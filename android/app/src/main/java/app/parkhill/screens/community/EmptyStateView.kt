package app.parkhill.screens.community

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Person
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import app.parkhill.contract.EmptyState
import app.parkhill.design.ParkHill

/** A backend message in place of content, with no buttons. Scrollable, so pull to refresh works. */
@Composable
fun EmptyStateView(empty: EmptyState) {
    Column(
        Modifier.fillMaxSize().background(ParkHill.colors.surface).verticalScroll(rememberScrollState()).padding(horizontal = 24.dp, vertical = 48.dp),
        verticalArrangement = Arrangement.spacedBy(10.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Icon(Icons.Outlined.Person, contentDescription = null, tint = ParkHill.colors.inkMuted, modifier = Modifier.size(40.dp))
        Text(empty.title, style = ParkHill.heading.copy(fontSize = 22.sp), color = ParkHill.colors.ink, textAlign = TextAlign.Center, modifier = Modifier.testTag("emptyState.title"))
        Text(empty.message, color = ParkHill.colors.ink, textAlign = TextAlign.Center, modifier = Modifier.testTag("emptyState.message"))
    }
}
