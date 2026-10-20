// TEMPORARY(EP-02): this file and the temporary package are deleted by AND-008.
package app.parkhill.temporary

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import app.parkhill.R
import app.parkhill.design.ParkHill
import app.parkhill.design.SecondaryButton
import app.parkhill.services.auth.AuthUser

/**
 * The only client-owned signed-in screen: shown while signed in until the tab
 * shell exists (specs/AUTH.md 6.2). Not backend driven; its text is bundled.
 */
@Composable
fun SignedInPlaceholder(user: AuthUser, signOut: () -> Unit) {
    Column(
        Modifier.fillMaxSize().background(ParkHill.colors.surface),
        verticalArrangement = Arrangement.spacedBy(16.dp, Alignment.CenterVertically),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Text(stringResource(R.string.placeholder_signed_in_as), color = ParkHill.colors.inkMuted)
        Text(user.email ?: user.id, style = ParkHill.heading.copy(fontSize = 24.sp), color = ParkHill.colors.ink, modifier = Modifier.testTag("placeholder.user"))
        SecondaryButton(stringResource(R.string.placeholder_sign_out), onClick = signOut, destructive = true, modifier = Modifier.testTag("placeholder.signOut"))
    }
}
