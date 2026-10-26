package app.parkhill.navigation

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.core.FastOutSlowInEasing
import androidx.compose.animation.core.tween
import androidx.compose.animation.slideInVertically
import androidx.compose.animation.slideOutVertically
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.consumeWindowInsets
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.imePadding
import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Close
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SnackbarHostState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.key
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.IntOffset
import app.parkhill.R
import app.parkhill.design.ParkHill

/**
 * The tab's full-screen cover (guide 5.5): a layer over the whole shell,
 * drawn inside the activity rather than as a dialog so the dev tools pill
 * stays above it. It slides up from the bottom when it opens and back down
 * when it closes, like the entry (AND-023) and the iOS cover. The tab's
 * messages show over it while it is open. Its root has a
 * close button; screens pushed inside it have a back button. Everything in
 * it, such as a search field's text, starts afresh each time it opens.
 */
@Composable
fun FullScreenCover(tab: TabCoordinator, snackbar: SnackbarHostState) {
    val cover = tab.cover
    // The closing cover stays drawn while it slides away.
    val shown = remember { object { var stack: ScreenStack? = null } }
    if (cover != null) shown.stack = cover
    val slide = tween<IntOffset>(COVER_MILLIS, easing = FastOutSlowInEasing)
    AnimatedVisibility(
        visible = cover != null,
        enter = slideInVertically(slide) { it },
        exit = slideOutVertically(slide) { it },
    ) {
        val stack = shown.stack ?: return@AnimatedVisibility
        key(stack) {
            CompositionLocalProvider(LocalScreenActions provides tab.actions) {
                CoverContent(stack, snackbar, close = tab::closeCover)
            }
        }
    }
}

@Composable
private fun CoverContent(stack: ScreenStack, snackbar: SnackbarHostState, close: () -> Unit) {
    val top = stack.path.lastOrNull()
    Scaffold(
        containerColor = ParkHill.colors.surface,
        snackbarHost = { MessageHost(snackbar) },
        topBar = {
            if (top == null) {
                ScreenTopBar(stack.root) {
                    IconButton(onClick = close, modifier = Modifier.testTag("cover.close")) {
                        Icon(Icons.Filled.Close, contentDescription = stringResource(R.string.navigation_close))
                    }
                }
            } else {
                ScreenTopBar(top.screen) { BackButton { stack.pop() } }
            }
        },
        modifier = Modifier.fillMaxSize().testTag("cover"),
    ) { padding ->
        Box(Modifier.padding(padding).consumeWindowInsets(padding).imePadding()) {
            ScreenStackContent(stack, Modifier.fillMaxSize())
        }
    }
}
