package app.parkhill.navigation

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Text
import androidx.compose.material3.pulltorefresh.PullToRefreshBox
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import app.parkhill.R
import app.parkhill.design.ParkHill
import app.parkhill.design.SecondaryButton
import kotlinx.coroutines.launch

/** Shows a [ScreenModel]: loading, the screen with pull to refresh, or the error screen with retry. */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ScreenHost(model: ScreenModel) {
    val scope = rememberCoroutineScope()
    LaunchedEffect(model) {
        if (model.needsLoad) model.load()
    }
    when (val state = model.state) {
        ScreenState.Loading -> Box(
            Modifier.fillMaxSize().background(ParkHill.colors.surface).testTag("screen.loading"),
            contentAlignment = Alignment.Center,
        ) {
            CircularProgressIndicator(color = ParkHill.colors.ink)
        }
        is ScreenState.Showing -> {
            var refreshing by remember { mutableStateOf(false) }
            PullToRefreshBox(
                isRefreshing = refreshing,
                onRefresh = {
                    scope.launch {
                        refreshing = true
                        model.load()
                        refreshing = false
                    }
                },
                modifier = Modifier.fillMaxSize(),
            ) {
                state.screen.content()
            }
        }
        ScreenState.Error -> ScreenError { scope.launch { model.retry() } }
    }
}

/** A backend screen that could not be fetched and has no cached copy. Client-owned, so its text is bundled. */
@Composable
fun ScreenError(retry: () -> Unit) {
    Column(
        Modifier.fillMaxSize().background(ParkHill.colors.surface).padding(horizontal = 24.dp),
        verticalArrangement = Arrangement.spacedBy(14.dp, Alignment.CenterVertically),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Text(stringResource(R.string.screen_error_title), style = ParkHill.heading.copy(fontSize = 24.sp), color = ParkHill.colors.ink, textAlign = TextAlign.Center)
        Text(stringResource(R.string.screen_error_message), color = ParkHill.colors.ink, textAlign = TextAlign.Center)
        SecondaryButton(stringResource(R.string.screen_error_retry), onClick = retry, modifier = Modifier.testTag("screenError.retry"))
    }
}
