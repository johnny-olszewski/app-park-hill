package app.parkhill.navigation

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.getValue
import androidx.compose.runtime.key
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import app.parkhill.design.ParkHill
import app.parkhill.screens.auth.LocalSessionEndedNotice
import app.parkhill.screens.launch.LaunchErrorScreen
import app.parkhill.services.auth.SignOutReason
import kotlinx.coroutines.launch

/**
 * The app's root: the signed-in shell of tabs, or the signed-out entry while
 * signed out: loading, the backend's entry screen or the launch error.
 */
@Composable
fun AppRoot(coordinator: AppCoordinator) {
    val state by coordinator.state.collectAsStateWithLifecycle()
    val scope = rememberCoroutineScope()
    val shell = state.shell
    Box(Modifier.fillMaxSize().background(ParkHill.colors.surface)) {
        when {
            state.isLaunching -> Loading()
            state.isEntryPresented -> CompositionLocalProvider(LocalSessionEndedNotice provides (state.signOutReason == SignOutReason.SessionEnded)) {
                Entry(state.entry, retry = { scope.launch { coordinator.retry() } })
            }
            shell != null -> SignedInShell(shell) { // TEMPORARY(EP-04): remove with IOS-015/AND-015
                scope.launch { coordinator.signOut() } // TEMPORARY(EP-04): remove with IOS-015/AND-015
            } // TEMPORARY(EP-04): remove with IOS-015/AND-015
        }
    }
}

@Composable
private fun Entry(entry: EntryState, retry: () -> Unit) {
    when (entry) {
        EntryState.Loading -> Loading()
        is EntryState.Screen -> key(entry.screen.key) { entry.screen.content() }
        EntryState.Error -> LaunchErrorScreen(retry)
    }
}

@Composable
private fun Loading() {
    Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) { CircularProgressIndicator(color = ParkHill.colors.ink) }
}
