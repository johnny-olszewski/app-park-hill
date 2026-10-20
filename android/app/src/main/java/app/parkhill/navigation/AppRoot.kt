package app.parkhill.navigation

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.key
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import app.parkhill.screens.launch.LaunchErrorScreen
import kotlinx.coroutines.launch

/** The app's root: whatever the coordinator's entry state says to show. */
@Composable
fun AppRoot(coordinator: AppCoordinator) {
    val entry by coordinator.entry.collectAsStateWithLifecycle()
    val scope = rememberCoroutineScope()
    when (val state = entry) {
        EntryState.Loading -> Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) { CircularProgressIndicator() }
        is EntryState.Screen -> key(state.screen.key) { state.screen.content() }
        EntryState.Error -> LaunchErrorScreen(retry = { scope.launch { coordinator.retry() } })
    }
}
