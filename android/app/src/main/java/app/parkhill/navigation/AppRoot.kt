package app.parkhill.navigation

import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.AnimatedContentTransitionScope
import androidx.compose.animation.ContentTransform
import androidx.compose.animation.Crossfade
import androidx.compose.animation.EnterTransition
import androidx.compose.animation.ExitTransition
import androidx.compose.animation.core.FastOutSlowInEasing
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.slideInVertically
import androidx.compose.animation.slideOutVertically
import androidx.compose.animation.togetherWith
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
import androidx.compose.ui.unit.IntOffset
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import app.parkhill.design.ParkHill
import app.parkhill.screens.auth.LocalSessionEndedNotice
import app.parkhill.screens.launch.LaunchErrorScreen
import app.parkhill.services.auth.SignOutReason
import kotlinx.coroutines.launch

/** What the root shows; each kind animates in and out as a whole. */
private sealed interface RootContent {
    data object Launching : RootContent
    data class Entry(val entry: EntryState, val sessionEnded: Boolean) : RootContent
    data class SignedIn(val shell: ShellCoordinator) : RootContent
}

/**
 * The app's root: the signed-in shell of tabs, or the signed-out entry while
 * signed out: loading, the backend's entry screen or the launch error. The
 * entry moves like the iOS full-screen cover (AND-023): it slides down to
 * reveal the tabs after sign-in and slides back up over them on sign-out.
 * Everything else cross-fades.
 */
@Composable
fun AppRoot(coordinator: AppCoordinator) {
    val state by coordinator.state.collectAsStateWithLifecycle()
    val scope = rememberCoroutineScope()
    val shell = state.shell
    val content = when {
        state.isLaunching -> RootContent.Launching
        state.isEntryPresented -> RootContent.Entry(state.entry, state.signOutReason == SignOutReason.SessionEnded)
        shell != null -> RootContent.SignedIn(shell)
        else -> RootContent.Launching
    }
    AnimatedContent(
        targetState = content,
        contentKey = { it::class },
        transitionSpec = { rootTransition() },
        modifier = Modifier.fillMaxSize().background(ParkHill.colors.surface),
        label = "root",
    ) { shown ->
        when (shown) {
            RootContent.Launching -> Loading()
            is RootContent.Entry -> CompositionLocalProvider(LocalSessionEndedNotice provides shown.sessionEnded) {
                Entry(shown.entry, retry = { scope.launch { coordinator.retry() } })
            }
            is RootContent.SignedIn -> SignedInShell(shown.shell) { // TEMPORARY(EP-04): remove with IOS-015/AND-015
                scope.launch { coordinator.signOut() } // TEMPORARY(EP-04): remove with IOS-015/AND-015
            } // TEMPORARY(EP-04): remove with IOS-015/AND-015
        }
    }
}

/** The entry slides over the tabs like a cover; anything else cross-fades. */
private fun AnimatedContentTransitionScope<RootContent>.rootTransition(): ContentTransform {
    val slide = tween<IntOffset>(COVER_MILLIS, easing = FastOutSlowInEasing)
    return when {
        // Sign-in: the tabs are already in place under the entry, which slides away.
        initialState is RootContent.Entry && targetState is RootContent.SignedIn ->
            (EnterTransition.None togetherWith slideOutVertically(slide) { it }).apply { targetContentZIndex = -1f }
        // Sign-out or access ending: the entry slides up over the tabs.
        initialState is RootContent.SignedIn && targetState is RootContent.Entry ->
            (slideInVertically(slide) { it } togetherWith ExitTransition.KeepUntilTransitionsFinished).apply { targetContentZIndex = 1f }
        else -> fadeIn(tween(FADE_MILLIS)) togetherWith fadeOut(tween(FADE_MILLIS))
    }
}

/** The entry's own changes (loading, its screen, the launch error) cross-fade. */
@Composable
private fun Entry(entry: EntryState, retry: () -> Unit) {
    Box(Modifier.fillMaxSize().background(ParkHill.colors.surface)) {
        Crossfade(targetState = entry, animationSpec = tween(FADE_MILLIS), label = "entry") { shown ->
            when (shown) {
                EntryState.Loading -> Loading()
                is EntryState.Screen -> key(shown.screen.key) { shown.screen.content() }
                EntryState.Error -> LaunchErrorScreen(retry)
            }
        }
    }
}

@Composable
private fun Loading() {
    Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) { CircularProgressIndicator(color = ParkHill.colors.ink) }
}

/** About the iOS cover's duration; also the full-screen cover's (AND-026). */
internal const val COVER_MILLIS = 400
private const val FADE_MILLIS = 250
