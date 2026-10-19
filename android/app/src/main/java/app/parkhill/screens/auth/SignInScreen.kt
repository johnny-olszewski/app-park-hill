package app.parkhill.screens.auth

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.unit.dp
import androidx.compose.runtime.Composable
import kotlinx.serialization.Serializable

/** `auth.sign_in` data (specs/AUTH.md 5.3). Only the title so far; AND-006 completes it. */
@Serializable
data class SignInScreenData(val title: String)

/** `auth.sign_in`: the title only, until the sign-in flow (AND-006). */
@Composable
fun SignInScreen(data: SignInScreenData) {
    Column(Modifier.fillMaxSize().padding(horizontal = 16.dp, vertical = 24.dp)) {
        Text(data.title, style = MaterialTheme.typography.headlineMedium, modifier = Modifier.testTag("signIn.title"))
    }
}
