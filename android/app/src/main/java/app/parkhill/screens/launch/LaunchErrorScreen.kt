package app.parkhill.screens.launch

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import app.parkhill.R

/**
 * Shown when nothing usable can be displayed at launch. Client-owned, so its
 * text is bundled: the backend cannot be reached to supply it.
 */
@Composable
fun LaunchErrorScreen(retry: () -> Unit) {
    Column(
        Modifier.fillMaxSize().padding(horizontal = 24.dp),
        verticalArrangement = Arrangement.spacedBy(14.dp, Alignment.CenterVertically),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Text(stringResource(R.string.launch_error_title), style = MaterialTheme.typography.titleLarge, textAlign = TextAlign.Center)
        Text(stringResource(R.string.launch_error_message), textAlign = TextAlign.Center)
        OutlinedButton(onClick = retry, modifier = Modifier.testTag("launchError.retry")) {
            Text(stringResource(R.string.launch_error_retry))
        }
    }
}
